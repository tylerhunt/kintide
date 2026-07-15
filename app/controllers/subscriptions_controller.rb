require 'dry/monads'

class SubscriptionsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access

  schema :create do
    required(:token).filled(:string)
  end

  def create
    case resolve('invitations.accept').call(invitation:)
    in Success(subscription)
      render :create, locals: { subscription: }
    end
  end

private

  def invitation
    Invitation.find_by!(token: safe_params[:token])
  end
end
