require 'rails_helper'
require 'pages/current_page'
require 'pages/forgot_password_page'
require 'pages/reset_password_page'

RSpec.describe 'Password reset' do
  include ActiveJob::TestHelper

  let(:current_page) { CurrentPage.new }
  let(:forgot_password_page) { ForgotPasswordPage.new }
  let(:reset_password_page) { ResetPasswordPage.new }

  let!(:account) { create(:account) }

  before do
    clear_emails
  end

  it 'resets the password from an emailed link' do
    forgot_password_page.visit

    forgot_password_page.within_form do |form|
      form.email_address = account.email_address
      form.submit
    end

    expect(current_page).to have_flash 'Password reset instructions sent'

    perform_enqueued_jobs

    open_email account.email_address
    current_email.click_link 'this password reset page'

    reset_password_page.within_form do |form|
      form.password = 'new-sekret-password'
      form.password_confirmation = 'new-sekret-password'
      form.submit
    end

    current_page.sign_in account, password: 'new-sekret-password'

    expect(current_page).to have_heading account.circle.name
  end

  it 'rejects an invalid reset token' do
    reset_password_page.visit token: 'bogus-token'

    expect(current_page).to have_flash 'invalid or has expired'
  end
end
