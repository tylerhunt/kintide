require 'rails_helper'

RSpec.describe 'Login', type: :system do
  let!(:account) { create(:account) }

  it 'signs in with valid credentials' do
    visit new_session_path

    fill_in 'email_address', with: account.email_address
    fill_in 'password', with: account.password
    click_on 'Sign in'

    expect(page).to_not have_current_path(new_session_path)
  end

  it 'rejects invalid credentials' do
    visit new_session_path

    fill_in 'email_address', with: account.email_address
    fill_in 'password', with: 'wrong-password'
    click_on 'Sign in'

    expect(page).to have_content('Try another email address or password.')
  end
end
