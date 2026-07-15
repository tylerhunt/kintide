# Test Patterns for Rails (RSpec, FactoryBot, Capybara/Playwright, VCR)

This document describes a testing architecture for Rails applications:
system specs driven by Playwright through page objects as the primary test
layer, FactoryBot factories with composable state traits, VCR cassettes for
external HTTP, and a thin layer of unit specs for business logic. Drop this
file into a Rails application (for example as `.claude/testing.md`) and link
it from `CLAUDE.md` so Claude follows these patterns.

## The Big Picture

| Layer | Location | Purpose |
|-------|----------|---------|
| System specs | `spec/system` | Primary tests: full user workflows through a real browser |
| Unit specs | `spec/models`, `spec/operations`, `spec/queries` | Business logic in isolation |
| Integration specs | `spec/integration` | End-to-end against real external services; excluded from the default run |
| Page objects | `spec/pages` | Encapsulate UI structure for system specs |
| Request specs | `spec/requests` | API endpoints only (webhooks, JSON APIs) |
| Controller specs | — | Never. System specs cover controller behavior |

Rules of thumb:

  - One comprehensive happy-path journey per flow beats many granular specs;
    system specs are expensive.
  - Specs are self-documenting: no comments, no private methods — `let`
    blocks and page objects carry the vocabulary.
  - Don't assert what you're about to use (`have_button` then
    `click_button` — just click).

## Dependencies

```ruby
# Gemfile
group :development, :test do
  gem 'launchy'                # opens pages/emails during debugging
  gem 'prosopite'              # N+1 query detection
  gem 'rspec-rails'
end

group :test do
  gem 'capybara'
  gem 'capybara-email'
  gem 'capybara-playwright-driver'
  gem 'factory_bot'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'playwright-ruby-client'
  gem 'vcr'
  gem 'webmock'
end
```

## RSpec Configuration

```ruby
# spec/spec_helper.rb — no Rails; keep it loadable in isolation
RSpec.configure do |config|
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }

  config.disable_monkey_patching!
  config.filter_run_excluding :integration   # real-service specs are opt-in
  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random

  Kernel.srand config.seed
end
```

```ruby
# spec/rails_helper.rb
require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

abort 'Rails is running in production mode!' if Rails.env.production?

require 'rspec/rails'

Rails.root.glob('spec/support/**/*.rb').sort.each { |file| require file }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => error
  abort error.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include ActiveSupport::Testing::TimeHelpers
end
```

Everything else lives in one-topic files under `spec/support/`.

## Factories (FactoryBot)

```ruby
# spec/support/factory_bot.rb
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods   # create/build without FactoryBot.
end
```

Factories generate realistic data with Faker and model state progression as
**composable traits**, where each lifecycle trait builds on the previous one:

```ruby
FactoryBot.define do
  factory :loan do
    firm { association(:firm, :with_operating_account) }

    amount { Faker::Commerce.price(range: 1_000..50_000) }
    fee_amount { amount * firm.fee_percentage }
    service_type { Loan.service_types.values.sample }

    trait :verified do
      borrower { association(:borrower) }
      state { Loan.states.fetch(:identity_review) }
    end

    trait :approved do
      verified                                  # traits compose
      state { Loan.states.fetch(:approved) }
    end

    trait :assigned do
      approved
      bank_account { association(:bank_account, :verified, firm:) }
    end

    trait :funded do
      assigned

      # Drive real state machine transitions instead of faking column values
      after :create do |loan|
        loan.process!
        loan.fund!
      end
    end

    # One trait per enum value: create(:loan, :approved), create(:loan, :declined)
    traits_for_enum :state
  end
end
```

Conventions:

  - **Traits over helper methods.** `create(:loan, :assigned)` in the spec;
    never a `create_assigned_loan` helper.
  - **`traits_for_enum`** generates a trait per enum value so specs read
    `create(:loan, :declined)`. With several enums on one model, prefix them
    (`fund_completed`, `fee_pending`) — stock FactoryBot lacks prefixes, so
    add a small extension:

    ```ruby
    # spec/support/factory_bot.rb
    module FactoryBotPrefixedEnum
      def initialize(attribute_name, values = nil)
        if values.is_a?(Hash) && values.key?(:prefix)
          self.prefix = values.fetch(:prefix)
          values = nil
        end

        super
      end

      def build_traits(klass)
        enum_values(klass).collect { |name, value|
          trait_name = [prefix, name].compact.join('_')
          build_trait(trait_name, @attribute_name, value || name)
        }
      end

    protected

      attr_accessor :prefix
    end

    FactoryBot::Enum.prepend FactoryBotPrefixedEnum
    FactoryBot.automatically_define_enum_traits = false

    # in a factory:
    #   traits_for_enum :fund_state, prefix: :fund   # => :fund_completed, ...
    ```

  - **Transient attributes** parameterize traits
    (`transient { settles_at { Faker::Time.backward } }`).
  - **Shared sequences** live in `spec/factories/sequences.rb` (phone
    numbers, account numbers) and are `generate(:us_phone_number)`-d from any
    factory.
  - A `has_many` list helper keeps association lists terse:

    ```ruby
    module FactoryBotAssociationList
      def association_list(factory_name, amount, *traits_and_overrides, &)
        Array.new(amount) { association(factory_name, *traits_and_overrides, &) }
      end
    end

    FactoryBot::Evaluator.include FactoryBotAssociationList

    # in a factory:
    #   transfers { association_list(:transfer, 2, :completed, firm:) }
    ```

## System Specs (Capybara + Playwright)

Playwright drives a real Chromium through the `capybara-playwright-driver`
gem — Capybara's API, Playwright's reliability:

```ruby
# spec/support/capybara.rb
require 'capybara/rspec'
require 'capybara/playwright'

Capybara.register_driver :playwright_chromium do |app|
  Capybara::Playwright::Driver.new app,
    browser_type: :chromium,
    headless: !ENV.key?('HEAD'),   # HEAD=1 bundle exec rspec → watch the browser
    reducedMotion: 'reduce'
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.disable_animation = true
end

RSpec.configure do |config|
  config.before(type: :system) { driven_by :playwright_chromium }
end
```

```ruby
# spec/support/devise.rb — fast request-level sign-in for setup
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :system
end
```

A representative spec — note the page objects, the fluent matchers, and the
single long journey through the flow:

```ruby
require 'rails_helper'
require 'pages/bank_accounts_page'
require 'pages/current_page'

RSpec.describe 'Bank Accounts Management', :js do
  let(:bank_accounts_page) { BankAccountsPage.new(firm) }
  let(:current_page) { CurrentPage.new }

  let(:firm) { create(:firm) }
  let(:user) { create(:user, firms: [firm]) }

  before do
    sign_in user
  end

  context 'with existing bank accounts' do
    let!(:first_account) { create(:bank_account, :verified, :primary, firm:) }
    let!(:second_account) { create(:bank_account, :verified, firm:) }

    it 'manages bank accounts' do
      visit firm_bank_accounts_path(firm)

      expect(current_page).to have_heading 'Bank Accounts'

      bank_accounts_page.within_row second_account do |row|
        expect(row).to be_secondary

        row.options.set_primary
      end

      current_page.within_dialog 'Confirm' do
        click_on 'Confirm'
      end

      expect(current_page).to have_flash('Bank account updated successfully')

      bank_accounts_page.within_row first_account do |row|
        expect(row).to be_secondary
      end
    end
  end
end
```

Conventions:

  - Use Devise's `sign_in` for setup speed; drive the real sign-in UI (via a
    page object) only in specs that test authentication itself.
  - Chain related assertions fluently:
    `expect(current_page).to have_heading('X').and have_button('Y')`.
  - Assert flash messages through `have_flash`, not `have_content` — content
    matching can pass on the wrong element.
  - Debugging: server errors are in `log/test.log`; Capybara saves failure
    screenshots under `tmp/capybara/`.

## Page Objects

Page objects live in `spec/pages`, are `require`d explicitly by each spec,
and encapsulate selectors, component-library quirks, and flows. The shared
mixin gives them Capybara, matchers, and route helpers:

```ruby
# spec/pages/test_helpers.rb
module TestHelpers
  extend ActiveSupport::Concern

  included do
    include Capybara::DSL
    include RSpec::Matchers
    include Rails.application.routes.url_helpers
    include Rails.application.routes.mounted_helpers
  end
end

# spec/pages/test_page.rb
class TestPage
  include TestHelpers

  def within_dialog(title, &)
    within '[role="dialog"]', text: title, &
  end

  def within_row(text, row: TestRow.new)
    within 'tr', text: do
      yield row
    end
  end
end
```

`CurrentPage` holds cross-page queries and flows; every system spec declares
`let(:current_page) { CurrentPage.new }`:

```ruby
# spec/pages/current_page.rb
class CurrentPage < TestPage
  def has_flash?(message, **)
    has_css?('[aria-label~="Notifications"] li', text: message, **)
  end

  def has_heading?(text, element: 'h1', **)
    has_css?(element, text:, **)
  end

  def sign_in(user, sign_in_page: SignInPage.new)
    sign_in_page.visit

    sign_in_page.within_form do |form|
      form.email = user.email
      form.password = user.password
      form.submit
    end

    expect(self).to have_flash('Signed in successfully')
  end
end
```

**The predicate trick:** because page objects include `RSpec::Matchers` and
define boolean `has_x?` methods, RSpec's predicate matchers give specs
`expect(current_page).to have_flash(...)` for free — every `has_x?` you add
is automatically an expressive matcher.

Forms get a small declarative DSL so specs assign fields instead of
scripting Capybara. Component-library quirks (custom selects, date pickers)
are handled once, inside the form class:

```ruby
# spec/pages/test_form.rb (skeleton)
class TestForm
  include TestHelpers

  class << self
    def field(name, locator, type: :text)
      # defines #name, #name= (fill_in), and #name_field (find_field)
    end

    def select(name, ...)  # defines #name= that drives the custom select widget
    def submit(locator)    # defines #submit that clicks the button
  end
end

# spec/pages/sign_in_page.rb
class SignInPage < TestPage
  class Form < TestForm
    field :email, 'Email'
    field :password, 'Password'
    submit 'Sign in'
  end

  def visit
    super new_user_session_path
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
```

Table rows follow the same idea — a `TestRow` with declaratively-defined
dropdown menu options (`row.options.set_primary`,
`expect(row.options).to have_remove(disabled: true)`), so menu-opening
mechanics live in one class.

## Email (capybara-email)

Assert delivered mail through `capybara-email`, never
`ActionMailer::Base.deliveries`:

```ruby
open_email 'support@example.com'

expect(current_email.subject).to eq('Support Request: Help needed')
expect(current_email).to have_content('Message content')
current_email.click_link 'Confirm your account'   # continues the browser flow
```

## External HTTP: VCR + WebMock

WebMock blocks all real HTTP in tests; VCR replays recorded cassettes.
Recording only happens when explicitly requested, so CI can never silently
hit a live service:

```ruby
# spec/support/vcr.rb
VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.ignore_localhost = true

  config.default_cassette_options = {
    allow_unused_http_interactions: false,       # cassette drift fails loudly
    record: ENV['VCR'] ? :once : :none,          # record only when VCR=1
  }

  # Scrub every credential that could appear in a cassette
  %w[PAYMENTS_CLIENT_ID PAYMENTS_CLIENT_SECRET]
    .select { |name| ENV.key?(name) }
    .each do |name|
      config.filter_sensitive_data("<#{name}>") { ENV.fetch(name) }
    end

  config.filter_sensitive_data('<CREDENTIALS>') do |interaction|
    if (authorization = interaction.request.headers['Authorization'])
      _schema, credentials = authorization.first.split
      credentials
    end
  end

  config.before_record do |interaction|
    Array(interaction.response.headers['Set-Cookie']).each do |cookie|
      interaction.filter! cookie, '<COOKIE>'
    end
  end
end
```

Specs opt in with `vcr:` metadata; support hooks insert/eject the named
cassettes around each example:

```ruby
context 'when linking an account', vcr: { cassette_name: 'payments/create_link_token' } do
  ...
end
```

Filter secrets **before** the first recording — a cassette with a live token
in git history is an incident. Recording workflow: set real credentials,
run the spec with `VCR=1`, review the new cassette for leaked secrets,
commit.

## Integration Specs (Real Services)

A small `spec/integration` suite runs true end-to-end against sandbox
external services. It is excluded from the default run
(`filter_run_excluding :integration`) and support hooks flip VCR/WebMock
off for it:

```ruby
# spec/support/webmock.rb
require 'webmock/rspec'

RSpec.configure do |config|
  config.around :each, :integration do |example|
    WebMock.allow_net_connect!
    example.run
    WebMock.disable_net_connect!
  end
end

# and in spec/support/vcr.rb
config.around :each, :integration do |example|
  VCR.turned_off { example.run }
end
```

Run explicitly with `bundle exec rspec --tag integration` when credentials
are available. When to use what:

| Approach | Use when |
|----------|----------|
| VCR cassette | Responses are stable; offline, deterministic tests |
| Mock/stub | Error paths and edge cases the sandbox can't produce |
| `:integration` | Verifying the real contract, run on demand |

## Unit Specs

Operations, models, and query objects get focused unit specs. Two supporting
pieces:

```ruby
# spec/support/dry_monads.rb — Success()/Failure() and result matchers in specs
Dry::Monads.load_extensions :rspec

# spec/support/system.rb — container stubbing (if using a dry-system container)
require 'dry/system/stubs'

MyApp::Container.enable_stubs!

RSpec.configure do |config|
  config.after { MyApp::Container.unstub }
end
```

Prefer constructor injection (pass fakes as keyword arguments); stub the
container only where the object under test resolves dependencies at runtime,
or in system specs where you don't construct the object:

```ruby
RSpec.describe Transfers::Process do
  subject(:operation) { described_class.new(settle:) }

  let(:settle) { ->(**) { Success() } }

  it 'settles the transfer' do
    expect(operation.call(transfer:)).to be_success
  end
end

# runtime resolution — stub the container key instead
before do
  MyApp::Container.stub 'sms.client', sms
end
```

Spec style:

  - Mirror the code's namespace in the describe block; `subject` is the
    object under test; inputs and records are `let` blocks named after the
    domain (`user`, `firm`, `loan` — not `test_user`).
  - Reference a `let` record in the example (or `let!`) to create it; no
    `before { ... }` data-builder methods.
  - Happy path first, edge cases after.
  - Assert real behavior (parse the CSV, match the tuple), not string
    presence.

## Custom Matchers

Recurring assertions get a matcher in `spec/support/matchers/`, one per file
(`be_a_uuid`, `have_http_header`, `have_downloaded_file`, `send_sms`). If an
assertion needs a comment to explain, it wants a matcher name instead.

## N+1 Detection (Prosopite)

Prosopite raises on N+1 queries during tests. Factories legitimately trigger
repeated inserts, so pause scanning around factory work:

```ruby
# spec/support/factory_bot.rb
FactoryBot.define do
  before :build do
    Thread.current[:factory_bot_prosopite_paused] = Prosopite.scan?
    Prosopite.pause
  end

  after :build do
    Prosopite.resume if Thread.current[:factory_bot_prosopite_paused]
  end
end
```

## Checklist

Do:

  - Cover every user-facing flow with one comprehensive system spec journey.
  - Put selectors and widget mechanics in page objects; give them `has_x?`
    predicates and get `have_x` matchers for free.
  - Compose factory traits for lifecycle states; drive real state machine
    transitions in `after :create`.
  - Record VCR cassettes deliberately (`VCR=1`), filter secrets, and fail on
    unused interactions.
  - Tag real-service specs `:integration` and exclude them by default.

Don't:

  - Write controller specs, or request specs for anything a system spec
    covers.
  - Script raw Capybara against selectors in specs — that's the page
    object's job.
  - Use `ActionMailer::Base.deliveries` directly; use capybara-email.
  - Assert an element exists and then interact with it.
  - Let factories fake state a state machine should produce.
