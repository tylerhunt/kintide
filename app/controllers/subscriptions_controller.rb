require 'dry/monads'

class SubscriptionsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access

  schema :show do
    required(:token).filled(:string)
  end

  def show
    if subscription.deactivated?
      render :deactivated, locals: { subscription: }
    else
      render :show, locals: {
        subscription:,
        posts: subscription.circle.posts
          .reverse_chronological
          .with_attached_photos,
      }
    end
  end

  schema :create do
    required(:token).filled(:string)
  end

  def create
    case resolve('invitations.accept').call(invitation:)
    in Success(subscription)
      redirect_to subscription_path(subscription.token),
        notice: t('flash.subscriptions.created')
    end
  end

  schema :destroy do
    required(:token).filled(:string)
  end

  def destroy
    case resolve('subscriptions.deactivate').call(subscription:)
    in Success(subscription)
      redirect_to subscription_path(subscription.token),
        notice: t('flash.subscriptions.deactivated')
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
