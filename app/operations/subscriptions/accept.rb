module Subscriptions
  class Accept < ApplicationOperation
    include Kintide::Deps['clock']

    contract do
      params do
        required(:subscription).filled(Types::Subscription)
      end
    end

    def call(**input)
      output = step validate(**input)

      step accept_subscription(**output)
    end

  private

    # Accepting is idempotent: a reused link lands on the current state.
    def accept_subscription(subscription:)
      return Success(subscription) unless subscription.invited?

      subscription.accepted_at = clock.call
      subscription.accept!

      Success(subscription)
    end
  end
end
