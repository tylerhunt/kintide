module Kintide
  module SMS
    # Records deliveries in memory for specs to inspect.
    class TestAdapter
      Delivery = Data.define(:to, :body)

      def initialize
        @deliveries = []
      end

      attr_reader :deliveries

      def deliver(to:, body:)
        deliveries << Delivery.new(to:, body:)
      end
    end
  end
end
