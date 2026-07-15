require 'twilio-ruby'

module Kintide
  module SMS
    # Sends messages through the Twilio API (production).
    class TwilioAdapter
      def initialize(account_sid:, auth_token:, from:)
        @client = Twilio::REST::Client.new(account_sid, auth_token)
        @from = from
      end

      def deliver(to:, body:)
        @client.messages.create(from: @from, to:, body:)
      end
    end
  end
end
