class PasswordsMailer < ApplicationMailer
  def reset(account)
    @account = account
    mail to: account.email_address
  end
end
