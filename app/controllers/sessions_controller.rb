require 'dry/monads'

class SessionsController < ApplicationController
  include Dry::Monads[:result]

  allow_unauthenticated_access only: %i[new create]

  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_path, alert: t('flash.sessions.throttled')
  }

  schema :new

  def new; end

  schema :create do
    required(:email_address).filled(:string)
    required(:password).filled(:string)
  end

  def create
    case resolve('sessions.create').call(
      **safe_params.to_h,
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
    )
    in Success(session)
      adopt_session session
      redirect_to after_authentication_url
    in Failure[:invalid, *] | Failure[:invalid_credentials]
      redirect_to new_session_path,
        alert: t('flash.sessions.invalid_credentials')
    end
  end

  schema :destroy

  def destroy
    case resolve('sessions.destroy').call(session: Current.session)
    in Success(*)
      forget_session
      redirect_to new_session_path, status: :see_other
    end
  end
end
