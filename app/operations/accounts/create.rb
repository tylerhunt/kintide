module Accounts
  class Create < ApplicationOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:email_address).filled(Types::Email)
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
        optional(:user_agent).maybe(:string)
        optional(:ip_address).maybe(:string)
      end

      rule(:password_confirmation) do
        key.failure(:password_mismatch) if value != values[:password]
      end
    end

    def call(**input)
      output = step validate(**input)

      transaction do
        account = step create_account(**output)
        step create_circle(account:)

        step create_session(account:, **output)
      end
    end

  private

    # The contract has already verified the confirmation matches, so the
    # account is created from the password alone.
    def create_account(name:, email_address:, password:, **)
      account = Account.create(name:, email_address:, password:)

      if account.persisted?
        Success(account)
      else
        Failure[__method__, account]
      end
    end

    # Every account owns exactly one circle, named after the account until
    # renaming arrives in settings.
    def create_circle(account:)
      Success(account.create_circle!(name: "#{account.name}’s Circle"))
    end

    def create_session(account:, user_agent: nil, ip_address: nil, **)
      Success(account.sessions.create!(user_agent:, ip_address:))
    end
  end
end
