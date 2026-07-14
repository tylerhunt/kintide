require 'dry/monads'

class RegistrationsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access

  schema :new

  def new; end

  schema :create do
    required(:name).filled(:string)
    required(:email_address).filled(:string)
    required(:password).filled(:string)
    required(:password_confirmation).filled(:string)
  end

  def create
    case resolve('accounts.create').call(
      **safe_params.to_h,
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
    )
    in Success(session)
      adopt_session session
      redirect_to root_path, notice: t('flash.registrations.created')
    in Failure[:invalid, errors]
      render :new, status: :unprocessable_content, locals: { errors: }
    in Failure[:create_account, account]
      render :new, status: :unprocessable_content,
        locals: { errors: account.errors.to_hash }
    end
  end
end
