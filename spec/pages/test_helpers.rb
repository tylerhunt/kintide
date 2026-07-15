module TestHelpers
  extend ActiveSupport::Concern

  included do
    include Capybara::DSL
    include RSpec::Matchers
    include Rails.application.routes.url_helpers
  end
end
