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
    # Invited subscriptions can deactivate too: a STOP reply must always
    # work, accepted or not.
    def deactivate_subscription(subscription:)
      return Success(subscription) if subscription.deactivated?

      subscription.deactivated_at = clock.call
      subscription.deactivate!

      Success(subscription)
    end
  end
end
