require 'dry/monads'

class SubscriptionsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access

  schema :show do
    required(:token).filled(:string)
  end

  def show
    render :show, locals: { subscription: }
  end

  schema :create do
    required(:token).filled(:string)
  end

  def create
    case resolve('invitations.accept').call(invitation:)
    in Success(subscription)
      redirect_to subscription_path(subscription.token)
    end
  end

private

  def invitation
    Invitation.find_by!(token: safe_params[:token])
  end

  def subscription
    Subscription.find_by!(token: safe_params[:token])
  end
end
