module Subscriptions
  class Invite < ApplicationOperation
    include Kintide::Deps['sms']

    contract do
      params do
        required(:circle).filled(Types::Circle)
        required(:name).filled(:string)
        required(:phone_number).filled(:string)
      end

      rule(:phone_number).validate(:phone_number)
    end

    def call(**input)
      output = step validate(**input)

      subscription = step create_subscription(**output)
      step deliver_invitation(subscription:)

      subscription
    end

  private

    def create_subscription(circle:, name:, phone_number:)
      subscription = circle.subscriptions.create(name:, phone_number:)

      if subscription.persisted?
        Success(subscription)
      else
        Failure[__method__, subscription]
      end
    end

    def deliver_invitation(subscription:)
      body = I18n.t(
        'sms.subscriptions.invite',
        inviter: subscription.circle.account.name,
        circle: subscription.circle.name,
        url: subscription_url(subscription),
      )

      Success(sms.deliver(to: subscription.phone_number, body:))
    end

    def subscription_url(subscription)
      Rails.application.routes.url_helpers
        .subscription_url(subscription.token)
    end
  end
end
