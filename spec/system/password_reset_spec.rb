require 'rails_helper'

RSpec.describe 'Password reset' do
  include ActiveJob::TestHelper

  let!(:account) { create(:account) }

  before do
    ActionMailer::Base.deliveries.clear
  end

  it 'resets the password from an emailed link' do
    visit new_session_path
    click_on 'Forgot password?'

    expect(page).to have_content('Forgot your password?')

    fill_in 'email_address', with: account.email_address
    click_on 'Email reset instructions'

    expect(page).to have_content('Password reset instructions sent')

    perform_enqueued_jobs

    mail = ActionMailer::Base.deliveries.last
    path = mail.text_part.decoded[%r{://[^/]+(/passwords/\S+/edit)}, 1]
    visit path

    fill_in 'password', with: 'new-sekret-password'
    fill_in 'password_confirmation', with: 'new-sekret-password'
    click_on 'Save'

    fill_in 'email_address', with: account.email_address
    fill_in 'password', with: 'new-sekret-password'
    click_on 'Sign in'

    expect(page).to have_content("Welcome, #{account.name}")
  end

  it 'rejects an invalid reset token' do
    visit edit_password_path('bogus-token')

    expect(page).to have_content('invalid or has expired')
  end
end
