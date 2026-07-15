require 'pages/test_helpers'

class TestForm
  include TestHelpers

  class << self
    # Defines `#name` (read the value), `#name=` (fill in), and
    # `#name_field` (the Capybara node) for a form field.
    def field(name, locator)
      define_method(name) do
        find_field(locator).value
      end
      define_method(:"#{name}=") do |value|
        fill_in locator, with: value
      end
      define_method(:"#{name}_field") { find_field(locator) }
    end

    def submit(locator)
      define_method(:submit) { click_on locator }
    end
  end
end
