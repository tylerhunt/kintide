module Subscriptions
  class Deactivate < ApplicationOperation
    include Kintide::Deps['clock']

    contract do
      params do
        required(:subscription).filled(Types::Subscription)
      end
    end

    def call(**input)
      output = step validate(**input)

      step deactivate_subscription(**output)
    end

  private

    # Deactivating twice is harmless and keeps the original timestamp.
    def deactivate_subscription(subscription:)
      unless subscription.deactivated?
        subscription.update!(deactivated_at: clock.call)
      end

      Success(subscription)
    end
  end
end
