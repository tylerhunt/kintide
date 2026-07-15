require 'dry/types'

module Kintide
  module Types
    include Dry.Types

    Email = String.constrained(format: URI::MailTo::EMAIL_REGEXP)
    UUID = String.constrained(uuid_v7: true)
  end
end
