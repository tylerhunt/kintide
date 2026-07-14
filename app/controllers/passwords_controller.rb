require 'dry/monads'

class PasswordsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access

  before_action :set_account_by_token, only: %i[edit update]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_password_path, alert: t('flash.passwords.throttled')
  }

  schema :new

  def new; end

  schema :create do
    required(:email_address).filled(:string)
  end

  # Invalid input gets the same response as success so that the form can't
  # be used to enumerate accounts.
  def create
    case resolve('passwords.request_reset').call(**safe_params.to_h)
    in Success(*) | Failure[:invalid, *]
      redirect_to new_session_path, notice: t('flash.passwords.sent')
    end
  end

  schema :edit

  def edit; end

  schema :update do
    required(:password).filled(:string)
    required(:password_confirmation).filled(:string)
  end

  def update
    case resolve('passwords.update').call(
      account: @account,
      **safe_params.to_h,
    )
    in Success(*)
      redirect_to new_session_path, notice: t('flash.passwords.reset')
    in Failure[:invalid, errors]
      render :edit, status: :unprocessable_content, locals: { errors: }
    in Failure[:update_account, account]
      render :edit, status: :unprocessable_content,
        locals: { errors: account.errors.to_hash }
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
