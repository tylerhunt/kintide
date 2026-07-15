require 'rails_helper'
require 'pages/current_page'
require 'pages/sign_up_page'

RSpec.describe 'Signup' do
  let(:current_page) { CurrentPage.new }
  let(:sign_up_page) { SignUpPage.new }

  it 'creates an account and signs in' do
    sign_up_page.visit

    sign_up_page.within_form do |form|
      form.name = 'Tyler'
      form.email_address = 'tyler@example.com'
      form.password = 'sekret-password'
      form.password_confirmation = 'sekret-password'
      form.submit
    end

    expect(current_page)
      .to have_flash('Welcome to Kintide!')
      .and have_heading('Tyler’s Circle')
  end

  it 'shows errors for a mismatched password confirmation' do
    sign_up_page.visit

    sign_up_page.within_form do |form|
      form.name = 'Tyler'
      form.email_address = 'tyler@example.com'
      form.password = 'sekret-password'
      form.password_confirmation = 'different-password'
      form.submit
    end

    expect(current_page).to have_errors 'does not match password'
  end

  it 'shows errors for a taken email address' do
    account = create(:account)

    sign_up_page.visit

    sign_up_page.within_form do |form|
      form.name = 'Also Tyler'
      form.email_address = account.email_address
      form.password = 'sekret-password'
      form.password_confirmation = 'sekret-password'
      form.submit
    end

    expect(current_page).to have_errors 'has already been taken'
  end
end
