module Sessions
  class Create < ApplicationOperation
    contract do
      params do
        required(:email_address).filled(:string)
        required(:password).filled(:string)
        optional(:user_agent).maybe(:string)
        optional(:ip_address).maybe(:string)
      end
    end

    def call(**input)
      output = step validate(**input)

      account = step authenticate(**output)

      step create_session(account:, **output)
    end

  private

    def authenticate(email_address:, password:, **)
      account = Account.authenticate_by(email_address:, password:)

      account ? Success(account) : Failure(:invalid_credentials)
    end

    def create_session(account:, user_agent: nil, ip_address: nil, **)
      Success(account.sessions.create!(user_agent:, ip_address:))
    end

    # Wrong credentials are an expected outcome, not an error; anything
    # else still reports through `super`.
    def on_failure(failure)
      case failure
      in :invalid_credentials
        super ignore(failure)
      else
        super
      end
    end
  end
end
