require 'dry/monads'

class SubscriptionsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access only: %i[show accept deactivate]

  schema :show do
    required(:token).filled(:string)
  end

  def show
    if subscription.invited?
      render :invited, locals: { subscription: }
    elsif subscription.deactivated?
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

  schema :new

  def new; end

  schema :create do
    required(:name).filled(:string)
    required(:phone_number).filled(:string)
  end

  def create
    case resolve('subscriptions.invite').call(
      circle: Current.account.circle,
      **safe_params.to_h,
    )
    in Success(*)
      redirect_to root_path, notice: t('flash.subscriptions.invited')
    in Failure[:invalid, errors]
      render :new, status: :unprocessable_content, locals: { errors: }
    in Failure[:create_subscription, subscription]
      render :new, status: :unprocessable_content,
        locals: { errors: subscription.errors.to_hash }
    end
  end

  schema :destroy do
    required(:token).filled(:string)
  end

  def destroy
    case resolve('subscriptions.remove').call(
      subscription: owned_subscription,
    )
    in Success(*)
      redirect_to root_path, notice: t('flash.subscriptions.removed')
    in Failure[:accepted, *]
      redirect_to root_path, alert: t('flash.subscriptions.accepted')
    end
  end

  schema :accept do
    required(:token).filled(:string)
  end

  def accept
    case resolve('subscriptions.accept').call(subscription:)
    in Success(subscription)
      redirect_to subscription_path(subscription.token),
        notice: t('flash.subscriptions.created')
    end
  end

  schema :deactivate do
    required(:token).filled(:string)
  end

  def deactivate
    case resolve('subscriptions.deactivate').call(subscription:)
    in Success(subscription)
      redirect_to subscription_path(subscription.token),
        notice: t('flash.subscriptions.deactivated')
    end
  end

private

  def subscription
    Subscription.find_by!(token: safe_params[:token])
  end

  # Owners may only remove subscriptions from their own circle.
  def owned_subscription
    Current.account.circle.subscriptions
      .find_by!(token: safe_params[:token])
  end
end
