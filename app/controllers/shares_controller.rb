class SharesController < ApplicationController
  allow_unauthenticated_access

  schema :show do
    required(:token).filled(:string)
  end

  def show
    if share.subscription.deactivated?
      redirect_to subscription_path(share.subscription.token)
    else
      render :show, locals: { share: }
    end
  end

private

  def share
    Share.find_by!(token: safe_params[:token])
  end
end
