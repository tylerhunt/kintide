# Operations Pattern for Rails (dry-rb)

This document describes an architecture for Rails applications where business
logic lives in **operation classes** built on the dry-rb stack, controllers
stay thin, and results flow through `Success`/`Failure` monads. Drop this file
into a Rails application (for example as `.claude/operations.md`) and link it
from `CLAUDE.md` so Claude follows these patterns.

## The Big Picture

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Controllers | `app/controllers` | Request/response only: validate params with a schema, load scoped records, call an operation, pattern match the result |
| Operations | `app/operations` | Multi-step business processes with side effects (writes, state transitions, emails, jobs, API calls) |
| Query objects | `app/queries` | Read-only data retrieval; no side effects, no monads |
| Models | `app/models` | Persistence, associations, scopes, state transitions |
| Serializers / views | `app/serializers`, views | All formatting |

Rules of thumb:

  - Every write goes through an operation. Reads use a query object or scope.
  - Operations return domain objects wrapped in `Success`/`Failure` — never
    formatted data.
  - Controllers never contain business logic, never format data, and never
    rescue `StandardError`.

## Dependencies

```ruby
# Gemfile
gem 'dry-monads', '~> 1.9'
gem 'dry-operation', '~> 1.0'
gem 'dry-rails', '~> 0.7.0'
gem 'dry-schema', '~> 1.14'
gem 'dry-validation', '~> 1.11'
```

`dry-types`, `dry-system`, and `dry-auto_inject` come in transitively.

## Container Setup

dry-rails creates an application container. Registered components are resolved
by string key; directories added as component dirs are **auto-registered** so
every operation is available without manual wiring.

```ruby
# config/initializers/system.rb
require 'dry/rails'

# Custom loader that registers the class itself instead of an instance.
# Used for jobs and mailers, which are invoked via class methods.
class ClassLoader < Dry::System::Loader::Autoloading
  def self.call(component, *)
    require! component
    constant(component)
  end
end

Dry::Rails.container do
  # Skip :application_contract; we define our own base contract below.
  config.features = %i[safe_params controller_helpers]

  # Avoid memoizing in development (the Rails autoloader invalidates
  # constants) and in test (values can vary per test).
  memoize = !env.local?

  register 'clock', memoize: true do
    -> { Time.current }
  end

  # Register external service clients here, wrapping their configuration:
  #
  #   namespace 'payments' do
  #     register 'client', memoize: do
  #       Payments::Client.new(api_key: Rails.application.credentials.payments_api_key)
  #     end
  #   end
  #
  # In development/test, register fake adapters so operations never need
  # environment checks:
  #
  #   register 'sms', memoize: true do
  #     env == 'test' ? SMS::TestAdapter.new : SMS::TwilioAdapter.new(...)
  #   end

  config.component_dirs.add 'app/operations' do |dir|
    dir.auto_register = true
    dir.memoize = memoize
    dir.loader = Dry::System::Loader::Autoloading
  end

  config.component_dirs.add 'app/jobs' do |dir|
    dir.auto_register = true
    dir.loader = ClassLoader
  end

  config.component_dirs.add 'app/mailers' do |dir|
    dir.auto_register = true
    dir.loader = ClassLoader
  end

  config.component_dirs.add 'app/queries' do |dir|
    dir.auto_register = ->(component) {
      component.identifier.key != 'application_query'
    }
    dir.memoize = memoize
    dir.namespaces.add nil, key: 'queries'
    dir.loader = Dry::System::Loader::Autoloading
  end
end
```

What this gives you (assuming the Rails application module is `MyApp`):

  - `MyApp::Container` — the container. `MyApp::Container['loans.approve']`
    resolves an operation **instance**.
  - `MyApp::Deps` — an auto-injection mixin for declaring dependencies
    (see below).
  - Registration keys mirror file paths: `app/operations/loans/approve.rb`
    (class `Loans::Approve`) registers as `'loans.approve'`.
  - In controllers: `resolve(key)` and the `schema`/`safe_params` helpers.

## Base Contract

Contracts validate and coerce operation input using dry-validation. Define one
base class with shared configuration and macros:

```ruby
# lib/my_app/contract.rb (or app/operations/application_contract.rb)
require 'dry/validation'

Dry::Validation.load_extensions :monads

module MyApp
  class Contract < Dry::Validation::Contract
    config.messages.backend = :i18n

    # Shared validation macros usable as `rule(:phone).validate(:phone_number)`
    register_macro :phone_number do
      if key? && !Phonelib.parse(value, 'US').valid_for_country?('US')
        key.failure :invalid_phone_number
      end
    end
  end
end
```

## Types

Define a shared dry-types module for domain types used by contracts and
controller schemas:

```ruby
# lib/my_app/types.rb
require 'dry/types'

module MyApp
  module Types
    include Dry.Types

    Email = String.constrained(format: URI::MailTo::EMAIL_REGEXP)
    UUID = String.constrained(format: :uuid)
    ZIPCode = String.constrained(format: /\A\d{5}(-\d{4})?\z/)
  end
end
```

`ApplicationOperation` extends these with model-instance types and enum types
derived from model enumerations, so contracts can type-check actual records:

```ruby
module Types
  include MyApp::Types

  # Model instances — contracts receive loaded records, not IDs
  Loan = Instance(::Loan)
  User = Instance(::User)

  # Enumerations derived from the model, never duplicated by hand
  ServiceTypes = String.enum(*::Loan.service_types.values)
end
```

## Base Operation

Operations extend [`Dry::Operation`](https://dry-rb.org/gems/dry-operation/).
Its `step` method unwraps a `Success` value or short-circuits `call`,
returning the `Failure` immediately (railway-oriented programming).

```ruby
# app/operations/application_operation.rb
require 'dry/operation'
require 'dry/operation/extensions/active_record'

class ApplicationOperation < Dry::Operation
  # Provides `transaction do ... end` inside `call` for atomic multi-write steps
  include Dry::Operation::Extensions::ActiveRecord[requires_new: true]

  class << self
    # Per-operation contract DSL:
    #
    #   contract do
    #     params { required(:loan).filled(Types::Loan) }
    #   end
    def contract(&)
      return @contract if defined?(@contract)

      @contract = Class.new(MyApp::Contract, &)
    end
  end

  # Contract is injectable for testing
  def initialize(contract: self.class.contract.new, **)
    @contract = contract
    super(**)
  end

  module Types
    include MyApp::Types

    # Model instance and enum types shared across operations (see above)
  end

private

  attr_reader :contract

  def Invalid(*) = Failure[:invalid, *] # rubocop:disable Naming/MethodName

  # First step of most operations: validate and coerce input.
  # Returns Success(hash of coerced params) or Failure[:invalid, errors].
  def validate(**input)
    contract
      .call(input)
      .to_monad
      .fmap(&:to_h)
      .or { |result| Invalid(result.errors.to_h) }
  end

  # dry-operation invokes this hook whenever a step fails. Reporting here
  # means controllers and callers never need to log failures themselves.
  def on_failure(failure)
    Rails.error.report(
      RuntimeError.new("#{self.class.name} failed: #{failure.inspect}"),
    )
  end
end
```

Notes:

  - Expected failures (for example user validation errors) should not be
    reported as errors. Either filter them in `on_failure` (skip `:invalid`
    failures) or tag them with a marker module when they are anticipated.
  - Swap `Rails.error.report` for your error tracker (Sentry etc.). Register
    a reporter in the container with per-environment adapters (raise in
    development, no-op in test, Sentry in production) so failures are loud
    where you develop and silent where you test.

## Writing an Operation

One file per business action, namespaced by resource, named with a verb:
`Loans::Approve`, `BankAccounts::Create`, `Transfers::Settle`.

```ruby
# app/operations/loans/approve.rb
module Loans
  class Approve < ApplicationOperation
    # Dependencies are injected by container key and become instance methods.
    # Keyword arguments to `new` override them in tests.
    include MyApp::Deps['features', 'loans_mailer']

    contract do
      params do
        required(:loan).filled(Types::Loan)
        optional(:current_user).filled(Types::User)
      end
    end

    def call(**input)
      output = step validate(**input)

      loan = step transition_loan(**output)
      step notify_firm(**output)

      loan
    end

  private

    def transition_loan(loan:, **)
      loan.approve!

      Success(loan)
    end

    def notify_firm(loan:, **)
      return Success([]) unless features.enabled?(:approval_notification)

      jobs = loan.firm.employees.active.collect { |employee|
        loans_mailer.approved(loan, employee).deliver_later
      }

      Success(jobs)
    end
  end
end
```

Conventions:

  - `call` reads as a table of contents: `step validate`, then one `step` per
    business action, then the return value (a domain object, wrapped in
    `Success` automatically by dry-operation).
  - Each step is a private method that returns `Success(value)` or
    `Failure[...]`. Steps take keyword arguments and accept `**` for the rest,
    so `step do_thing(**output)` works without threading every key.
  - Failures are tuples: `Failure[:reason, details]`. For model validation
    failures, use the method name and the record:

    ```ruby
    def create_bank_account(firm:, **attributes)
      bank_account = firm.bank_accounts.create(**attributes)

      if bank_account.persisted?
        Success(bank_account)
      else
        Failure[__method__, bank_account]
      end
    end
    ```

  - Wrap multiple dependent writes in `transaction do ... end` (provided by
    the ActiveRecord extension); a failing step inside rolls back.
  - `deliver_later` and `perform_later` return jobs, not results — name the
    variable `job`, not `result`.
  - Rescue **specific** exceptions and convert them to failures. Never rescue
    `StandardError`, and never add error handling for scenarios that cannot
    happen:

    ```ruby
    def create_transfer(loan)
      Success(loan.transfers.create!(amount: loan.fee_amount))
    rescue ActiveRecord::RecordNotUnique
      Failure[:duplicate, 'Transfer already exists']
    end
    ```

Operations must **not**:

  - Format data (no currency strings, no date formatting, no display
    prefixes) — return domain objects and let serializers/views format.
  - Generate presentation output (CSV, JSON structures for a UI).
  - Take raw IDs when the caller can load the record — controllers load
    records through authorization scopes and pass instances; contracts
    type-check them with `Instance` types.

## Controllers

Controllers use two dry-rails features: `safe_params` (per-action schemas)
and `controller_helpers` (`resolve`).

```ruby
class LoansController < ApplicationController
  include Dry::Monads[:result]

  # Declare a schema for every action, even parameterless ones
  schema :index

  def index
    render :index, locals: { loans: firm.loans.active }
  end

  schema :approve do
    required(:id).filled(Types::UUID)
  end

  def approve
    case resolve('loans.approve').call(
      loan: firm.loans.pending.find(safe_params[:id]),
      current_user:,
    )
    in Success(loan)
      redirect_to loan_path(loan), success: t('flash.loan_approved')
    in Failure[:invalid, errors]
      redirect_back fallback_location: loans_path,
        alert: errors.to_h.values.flatten.first
    end
  end
end
```

Conventions:

  - **Schemas over strong parameters.** `schema :action do ... end` defines a
    dry-schema; `safe_params` holds the coerced result. Use type defaults
    instead of manual fallbacks:

    ```ruby
    schema :index do
      optional(:year).filled(Types::Integer.default { Date.current.year })
    end
    ```

  - **Load records through authorization scopes**, then hand instances to the
    operation: `firm.loans.pending.find(...)`, never `Loan.find(...)`.
  - **Pattern match results.** Handle the `Success` and the `Failure` cases
    you expect; let anything else raise (`NoMatchingPatternError` surfaces
    bugs instead of hiding them).
  - **Array gotcha:** when a `Success` wraps an array, you must destructure
    with a splat — `in Success[*items]` — not `in Success(items)`.
  - **No logging on failure.** `ApplicationOperation#on_failure` already
    reports; the controller only shapes the response.
  - **No `rescue StandardError`.** Let unexpected errors propagate with their
    backtraces.
  - **Few private methods.** A controller sprouting many private helpers is a
    sign business logic is leaking in; move it to an operation or query.

## Query Objects

Reads do not need monads or steps. Use a plain object with chainable methods
returning ActiveRecord relations:

```ruby
# app/queries/revenue_query.rb
class RevenueQuery
  def initialize(relation = Transfer.all)
    @relation = relation
  end

  def by_period(start_date:, end_date:)
    @relation = @relation.where(settles_at: start_date..end_date)
    self
  end

  def completed
    @relation = @relation.where(state: 'completed')
    self
  end

  def all = @relation
end
```

Do not force a read into an operation. If there are no side effects and no
steps that can fail independently, it is a query.

## Testing

  - **Operations get unit specs.** Inject fakes through the keywords that
    `Deps` adds to the initializer:

    ```ruby
    RSpec.describe Loans::Approve do
      subject(:operation) { described_class.new(loans_mailer:, features:) }

      let(:loans_mailer) { instance_double(LoansMailer) }
      let(:features) { instance_double(Features, enabled?: true) }

      it 'approves the loan' do
        expect(operation.call(loan:)).to be_success
      end
    end
    ```

  - Assert on failures by matching the tuple:
    `expect(result.failure).to match([:invalid, hash_including(:loan)])`.
  - Contract validation is covered by the operation specs — invalid input
    returns `Failure[:invalid, errors]`; no separate contract specs needed.
  - Controllers are covered by system/feature specs, not controller specs;
    they contain no logic worth unit testing.

## Checklist

Do:

  - Route every write through an operation resolved from the container.
  - Give every operation a contract; make `step validate(**input)` the first
    step.
  - Return domain objects from operations.
  - Declare dependencies with `Deps[...]`; register external clients and
    per-environment adapters in the container.
  - Keep controllers to: schema, scope-loaded records, `resolve(...).call`,
    pattern match, respond.

Don't:

  - Put business logic, formatting, or aggregation in controllers.
  - Format or serialize inside operations.
  - Rescue `StandardError` anywhere in this stack.
  - Log operation failures in controllers (the `on_failure` hook reports).
  - Use an operation for a side-effect-free read.
  - Match array-wrapped successes without the splat (`in Success[*items]`).
