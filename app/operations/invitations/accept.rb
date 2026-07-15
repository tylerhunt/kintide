module Invitations
  class Accept < ApplicationOperation
    include Kintide::Deps['clock']

    contract do
      params do
        required(:invitation).filled(Types::Invitation)
      end
    end

    def call(**input)
      output = step validate(**input)

      step accept_invitation(**output)
    end

  private

    # Accepting an already-accepted invitation returns the existing
    # subscription, so a reused link is harmless.
    def accept_invitation(invitation:)
      return Success(invitation.subscription) if invitation.accepted?

      transaction do
        invitation.update!(accepted_at: clock.call)

        Success(
          invitation.create_subscription!(
            circle: invitation.circle,
            name: invitation.name,
            phone_number: invitation.phone_number,
          ),
        )
      end
    end
  end
end
