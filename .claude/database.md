# Database Patterns for Rails (PostgreSQL)

This document describes PostgreSQL schema conventions for Rails applications:
UUIDv7 primary keys, `text` over `varchar`, `citext` for case-insensitive
values, native database enums as the single source of truth, and `jsonb` and
array columns where they earn their keep. Drop this file into a Rails
application (for example as `.claude/database.md`) and link it from
`CLAUDE.md` so Claude follows these patterns. It pairs with
`OPERATIONS_PATTERN.md`, which covers the application architecture built on
this schema.

## Principles

  - **Let the database enforce invariants.** `null: false` with a sensible
    default, enum types, case-insensitive uniqueness, and check constraints
    beat application-level validation alone — they hold even for writes that
    bypass ActiveRecord.
  - **The schema is the source of truth for enumerations.** Ruby reads enum
    values from the database type; it never duplicates the list.
  - **Structure by default.** Real domain attributes get real columns. `jsonb`
    is for payloads whose shape the application does not own.

## UUIDv7 Primary Keys

Every table uses a UUIDv7 primary key. Unlike random UUIDv4, UUIDv7 is
time-ordered: inserts append to the primary key index instead of fragmenting
it, and IDs sort by creation time. Unlike serial integers, IDs are globally
unique and reveal nothing about row counts.

Enable the extension (PostgreSQL 18+ ships a native `uuidv7()` function; on
earlier versions use the [`pg_uuidv7`](https://github.com/fboulnois/pg_uuidv7)
extension, which provides `uuid_generate_v7()`):

```ruby
# in a migration
enable_extension 'pg_uuidv7'
```

Tell the generators every primary key is a UUID:

```ruby
# config/application.rb
config.generators do |generate|
  generate.orm :active_record, primary_key_type: :uuid
end
```

Rails' default UUID function is `gen_random_uuid()` (v4), so each
`create_table` overrides the default explicitly:

```ruby
create_table :offices, id: :uuid, default: 'uuid_generate_v7()' do |t|
  t.references :firm, type: :uuid, null: false, foreign_key: true
  ...
end
```

Foreign keys are `t.uuid` / `t.references type: :uuid` (the generator config
handles this for generated migrations).

Validate UUID params with a dry-types type (dry-logic ships a `uuid_v7?`
predicate):

```ruby
UUID = Types::String.constrained(uuid_v7: true)
```

## `text` Over `varchar`

Use `t.text` for every character column. In PostgreSQL, `text` and
`varchar(n)` have identical storage and performance; the length limit is the
only difference, and length rules belong in validations and contracts where
they can change without a migration.

```ruby
# ✅ GOOD
t.text :name, null: false

# ❌ BAD - Rails generators default to this; change it
t.string :name, null: false
```

## `citext` for Email

Case-insensitive values — emails above all — use the `citext` extension so
comparisons and unique indexes ignore case at the database level.
`User@example.com` and `user@example.com` cannot both register, no matter what
code path inserts them.

```ruby
enable_extension 'citext'

create_table :users, id: :uuid, default: 'uuid_generate_v7()' do |t|
  t.citext :email, null: false
  t.index :email, unique: true
end
```

Keep a format validation in the contract/model; `citext` only handles casing.

## Native PostgreSQL Enums

Enumerated values are PostgreSQL enum types, not integer columns or
unconstrained strings. The database rejects invalid values, the values are
readable in any SQL client, and there is exactly one place they are defined.

```ruby
# in a migration
create_enum :loan_states, %w[pending approved declined funded cancelled]

create_table :loans, id: :uuid, default: 'uuid_generate_v7()' do |t|
  t.enum :state, enum_type: :loan_states, default: 'pending', null: false
end

# adding a value later
add_enum_value :loan_states, 'abandoned'
```

On the Ruby side, a concern overrides Rails' `enum` macro to **load the
values from the database type**, so the model never repeats the list:

```ruby
# app/models/concerns/database_enum.rb
module DatabaseEnum
  extend ActiveSupport::Concern

  module ClassMethods
    # Overrides Rails' `enum` to provide default options and support for
    # loading values from the database.
    def enum(name, enum_type, **)
      super name, enum_values(enum_type), validate: true, **
    end

  private

    def enum_values(enum)
      @enum_values ||= ApplicationRecord.connection.enum_types.to_h
      @enum_values.fetch(enum.to_s).index_by(&:itself)
    end
  end
end
```

```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  include DatabaseEnum

  primary_abstract_class
end

# app/models/loan.rb
class Loan < ApplicationRecord
  enum :state, :loan_states, instance_methods: false
end
```

Notes:

  - `validate: true` (the concern's default) makes invalid values a
    validation error instead of an `ArgumentError` on assignment.
  - `instance_methods: false` skips generating `pending?`/`approved?` style
    predicates; drop it if you want them.
  - Because values come from the database, contracts can derive types from
    the model instead of hardcoding: `String.enum(*::Loan.states.values)`.

## Enum Arrays

Enum types compose with array columns for multi-select attributes:

```ruby
create_enum :practice_areas, %w[bankruptcy family_law real_estate tax_law ...]

add_column :firms, :practice_areas, :enum,
  enum_type: :practice_areas, array: true, default: [], null: false

# Default to "all values" using the enum's own range:
add_column :firms, :service_types, :enum,
  enum_type: :loan_service_types, array: true, null: false,
  default: -> { 'enum_range(NULL::loan_service_types)' }
```

PostgreSQL validates each element against the enum type. Rails' `enum` macro
does not understand array columns, so pair the column with a small helper and
validator:

```ruby
# app/models/application_record.rb
private_class_method def self.array_enum(name, values, validate: false)
  define_singleton_method name do
    values
  end

  validates name, array_enum: true if validate
end

# app/validators/array_enum_validator.rb
class ArrayEnumValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, values)
    enum_values = record.class.send(attribute).keys

    invalid_values = Array(values).reject { |value|
      enum_values.include?(value)
    }

    return if invalid_values.empty?

    record.errors.add attribute, :invalid, value: invalid_values
  end
end

# app/models/firm.rb
class Firm < ApplicationRecord
  array_enum :practice_areas, enum_values(:practice_areas), validate: true
end
```

## `jsonb`

Use `jsonb` for data whose shape the application does not own: external API
payloads, per-provider metadata, webhook bodies, flexible configuration.
Always give it a default and `null: false` so readers never handle `nil`:

```ruby
t.jsonb :data, default: {}, null: false
t.jsonb :config, default: {}, null: false
```

Namespace provider data inside a single `data` column with `store_accessor`
instead of adding a column per provider:

```ruby
class BankAccount < ApplicationRecord
  store_accessor :data, :plaid, suffix: true   # #plaid_data / #plaid_data=
  store_accessor :data, :stripe, suffix: true
end
```

Boundaries:

  - An attribute the application validates, queries, or joins on individually
    deserves a real column, not a `jsonb` key.
  - Promote a `jsonb` key to a column when it grows those needs — that is a
    routine migration, not a failure of the original design.
  - Index with GIN only when you actually query into the document.

## Array Columns

Prefer a native array over a join table when the elements are values, not
entities — nothing references them and they carry no attributes of their own:

```ruby
t.text :backup_codes, array: true, default: [], null: false
t.enum :practice_areas, enum_type: :practice_areas, array: true,
  default: [], null: false
```

Add a GIN index when querying by containment (`WHERE tags @> ARRAY['ruby']`).
If elements need attributes or referential integrity, use a join table.

## Checklist

Do:

  - Use UUIDv7 primary keys (`id: :uuid, default: 'uuid_generate_v7()'`) and
    `t.uuid` foreign keys everywhere.
  - Use `t.text`, never `t.string`.
  - Use `citext` plus a unique index for emails and other case-insensitive
    unique values.
  - Define enumerations as PostgreSQL enum types and load their values from
    the database in models.
  - Declare `null: false` with a default wherever a value is always present —
    especially `jsonb` (`default: {}`) and arrays (`default: []`).

Don't:

  - Use integer/serial primary keys, or UUIDv4 defaults
    (`gen_random_uuid()`).
  - Duplicate enum values in Ruby constants, model code, or contracts.
  - Store real domain attributes in `jsonb` to avoid a migration.
  - Use a join table for plain value lists, or an array column for entities.
