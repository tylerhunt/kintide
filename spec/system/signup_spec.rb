require 'rails_helper'

RSpec.describe 'Signup' do
  it 'creates an account and signs in' do
    visit signup_path

    fill_in 'name', with: 'Tyler'
    fill_in 'email_address', with: 'tyler@example.com'
    fill_in 'password', with: 'sekret-password'
    fill_in 'password_confirmation', with: 'sekret-password'
    click_on 'Sign up'

    expect(page).to have_content('Welcome, Tyler')
    expect(page).to have_content("Tyler's Circle")
  end

  it 'shows errors for a mismatched password confirmation' do
    visit signup_path

    fill_in 'name', with: 'Tyler'
    fill_in 'email_address', with: 'tyler@example.com'
    fill_in 'password', with: 'sekret-password'
    fill_in 'password_confirmation', with: 'different-password'
    click_on 'Sign up'

    expect(page).to have_content('does not match password')
  end

  it 'shows errors for a taken email address' do
    account = create(:account)

    visit signup_path

    fill_in 'name', with: 'Also Tyler'
    fill_in 'email_address', with: account.email_address
    fill_in 'password', with: 'sekret-password'
    fill_in 'password_confirmation', with: 'sekret-password'
    click_on 'Sign up'

    expect(page).to have_content('has already been taken')
  end
end
