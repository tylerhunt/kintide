module Passwords
  class Update < ApplicationOperation
    contract do
      params do
        required(:account).filled(Types::Account)
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
      end

      rule(:password_confirmation) do
        key.failure(:password_mismatch) if value != values[:password]
      end
    end

    def call(**input)
      output = step validate(**input)

      transaction do
        account = step update_account(**output)
        step destroy_sessions(account:)

        account
      end
    end

  private

    # The contract has already verified the confirmation matches, so only
    # the password itself is written.
    def update_account(account:, password:, **)
      if account.update(password:)
        Success(account)
      else
        Failure[__method__, account]
      end
    end

    def destroy_sessions(account:)
      Success(account.sessions.destroy_all)
    end
  end
end
