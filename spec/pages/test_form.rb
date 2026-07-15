require 'pages/test_helpers'

class TestForm
  include TestHelpers

  class << self
    # Defines `#name` (read the value), `#name=` (fill in, or attach
    # files for `type: :file`), and `#name_field` (the Capybara node)
    # for a form field.
    def field(name, locator, type: :text)
      define_method name do
        find_field(locator).value
      end

      define_method :"#{name}=" do |value|
        if type == :file
          attach_file locator, value
        else
          fill_in locator, with: value
        end
      end

      define_method :"#{name}_field" do
        find_field(locator)
      end
    end

    def submit(locator)
      define_method :submit do
        click_on locator
      end
    end
  end
end
