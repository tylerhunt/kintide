module Kintide
  module SMS
    # Logs messages instead of sending them (development).
    class LogAdapter
      def deliver(to:, body:)
        Rails.logger.info "SMS to #{to}: #{body}"
      end
    end
  end
end
