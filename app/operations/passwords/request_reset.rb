module Passwords
  class RequestReset < ApplicationOperation
    include Kintide::Deps['passwords_mailer']

    contract do
      params do
        required(:email_address).filled(:string)
      end
    end

    def call(**input)
      output = step validate(**input)

      step deliver_instructions(**output)
    end

  private

    # Succeeds whether or not the email address is known, so callers can't
    # be used to enumerate accounts.
    def deliver_instructions(email_address:)
      account = Account.find_by(email_address:)
      return Success(nil) unless account

      job = passwords_mailer.reset(account).deliver_later

      Success(job)
    end
  end
end
