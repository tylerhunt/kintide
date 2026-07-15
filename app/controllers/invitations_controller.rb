require 'dry/monads'

class InvitationsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access only: :show

  schema :show do
    required(:token).filled(:string)
  end

  def show
    render :show, locals: { invitation: }
  end

  schema :new

  def new; end

  schema :create do
    required(:name).filled(:string)
    required(:phone_number).filled(:string)
  end

  def create
    case resolve('invitations.create').call(
      circle: Current.account.circle,
      **safe_params.to_h,
    )
    in Success(*)
      redirect_to root_path, notice: t('flash.invitations.created')
    in Failure[:invalid, errors]
      render :new, status: :unprocessable_content, locals: { errors: }
    in Failure[:create_invitation, invitation]
      render :new, status: :unprocessable_content,
        locals: { errors: invitation.errors.to_hash }
    end
  end

private

  def invitation
    Invitation.find_by!(token: safe_params[:token])
  end
end
