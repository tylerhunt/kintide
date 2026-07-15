module Subscriptions
  class Remove < ApplicationOperation
    contract do
      params do
        required(:subscription).filled(Types::Subscription)
      end
    end

    def call(**input)
      output = step validate(**input)

      subscription = step ensure_invited(**output)

      step destroy_subscription(subscription:)
    end

  private

    # Removing someone who already accepted is a separate concern.
    def ensure_invited(subscription:)
      if subscription.invited?
        Success(subscription)
      else
        Failure[:accepted, subscription]
      end
    end

    def destroy_subscription(subscription:)
      Success(subscription.destroy!)
    end

    # The invitee can accept between the owner loading the page and
    # clicking remove; that race is not an error.
    def on_failure(failure)
      case failure
      in [:accepted, *]
        super ignore(failure)
      else
        super
      end
    end
  end
end
