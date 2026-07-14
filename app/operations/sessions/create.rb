module Sessions
  class Create < ApplicationOperation
    EXPECTED_FAILURES = [*EXPECTED_FAILURES, :invalid_credentials].freeze

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

      if account
        Success(account)
      else
        Failure[:invalid_credentials]
      end
    end

    def create_session(account:, user_agent: nil, ip_address: nil, **)
      Success(account.sessions.create!(user_agent:, ip_address:))
    end
  end
end
