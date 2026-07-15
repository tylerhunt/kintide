module Invitations
  class Create < ApplicationOperation
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

      invitation = step create_invitation(**output)
      step deliver_invitation(invitation:)

      invitation
    end

  private

    def create_invitation(circle:, name:, phone_number:)
      invitation = circle.invitations.create(name:, phone_number:)

      if invitation.persisted?
        Success(invitation)
      else
        Failure[__method__, invitation]
      end
    end

    def deliver_invitation(invitation:)
      body = I18n.t(
        'sms.invitations.invite',
        inviter: invitation.circle.account.name,
        circle: invitation.circle.name,
        url: invitation_url(invitation),
      )

      Success(sms.deliver(to: invitation.phone_number, body:))
    end

    def invitation_url(invitation)
      Rails.application.routes.url_helpers.invitation_url(invitation.token)
    end
  end
end
