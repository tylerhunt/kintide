module Shares
  class Deliver < ApplicationOperation
    include Kintide::Deps['clock', 'sms']

    contract do
      params do
        required(:share).filled(Types::Share)
      end
    end

    def call(**input)
      output = step validate(**input)

      share = step ensure_undelivered(**output)

      step deliver_share(share:)
    end

  private

    # Retried jobs must not text the subscriber twice.
    def ensure_undelivered(share:)
      if share.delivered?
        Failure[:delivered, share]
      else
        Success(share)
      end
    end

    def deliver_share(share:)
      body = I18n.t(
        'sms.shares.deliver',
        author: share.post.circle.account.name,
        circle: share.post.circle.name,
        url: share_url(share),
      )

      sms.deliver(to: share.subscription.phone_number, body:)
      share.update!(delivered_at: clock.call)

      Success(share)
    end

    def share_url(share)
      Rails.application.routes.url_helpers.share_url(share.token)
    end

    # An already-delivered share is the retry working as intended.
    def on_failure(failure)
      case failure
      in [:delivered, *]
        super ignore(failure)
      else
        super
      end
    end
  end
end
