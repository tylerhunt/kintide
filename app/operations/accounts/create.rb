module Accounts
  class Create < ApplicationOperation
    contract do
      params do
        required(:name).filled(:string)
        required(:email_address).filled(Types::Email)
        required(:password).filled(:string, min_size?: 8)
        required(:password_confirmation).filled(:string)
      end

      rule(:password_confirmation) do
        key.failure(:password_mismatch) if value != values[:password]
      end
    end

    def call(**input)
      output = step validate(**input)

      step create_account(**output)
    end

  private

    def create_account(**attributes)
      account = Account.create(**attributes)

      if account.persisted?
        Success(account)
      else
        Failure[__method__, account]
      end
    end
  end
end
