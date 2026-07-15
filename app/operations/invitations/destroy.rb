module Invitations
  class Destroy < ApplicationOperation
    contract do
      params do
        required(:invitation).filled(Types::Invitation)
      end
    end

    def call(**input)
      output = step validate(**input)

      invitation = step ensure_pending(**output)

      step destroy_invitation(invitation:)
    end

  private

    # Deleting an accepted invitation would cascade to its subscription;
    # removing a subscriber is a separate concern.
    def ensure_pending(invitation:)
      if invitation.accepted?
        Failure[:accepted, invitation]
      else
        Success(invitation)
      end
    end

    def destroy_invitation(invitation:)
      Success(invitation.destroy!)
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
