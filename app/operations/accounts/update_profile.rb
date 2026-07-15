module Accounts
  class UpdateProfile < ApplicationOperation
    contract do
      params do
        required(:account).filled(Types::Account)
        required(:name).filled(:string)
        optional(:avatar).value(Types::UploadedFile)
      end
    end

    def call(**input)
      output = step validate(**input)

      step update_account(**output)
    end

  private

    # A missing avatar means "keep the current one", so it only lands in
    # the update when uploaded.
    def update_account(account:, name:, avatar: nil)
      attributes = { name: }
      attributes[:avatar] = avatar if avatar

      if account.update(attributes)
        Success(account)
      else
        Failure[__method__, account]
      end
    end
  end
end
