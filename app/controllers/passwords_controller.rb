class PasswordsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_account_by_token, only: %i[edit update]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_password_path, alert: t('flash.passwords.throttled')
  }

  def new; end

  def create
    account = Account.find_by(email_address: params[:email_address])
    PasswordsMailer.reset(account).deliver_later if account

    redirect_to new_session_path, notice: t('flash.passwords.sent')
  end

  def edit; end

  def update
    if @account.update(params.permit(:password, :password_confirmation))
      @account.sessions.destroy_all
      redirect_to new_session_path, notice: t('flash.passwords.reset')
    else
      redirect_to edit_password_path(params[:token]),
        alert: t('flash.passwords.not_matching')
    end
  end

private

  def set_account_by_token
    @account = Account.find_by_token_for!(
      :password_reset,
      params[:token],
    )
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path,
      alert: t('flash.passwords.invalid_token')
  end
end
