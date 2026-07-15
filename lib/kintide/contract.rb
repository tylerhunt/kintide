require 'dry/validation'
require 'phonelib'

Dry::Validation.load_extensions :monads

module Kintide
  class Contract < Dry::Validation::Contract
    config.messages.backend = :i18n

    # Shared validation macro: `rule(:phone_number).validate(:phone_number)`
    register_macro :phone_number do
      if key? && !Phonelib.parse(value, 'US').valid_for_country?('US')
        key.failure :invalid_phone_number
      end
    end
  end
end
