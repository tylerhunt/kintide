require 'rails_helper'
require 'pages/current_page'
require 'pages/sign_in_page'

RSpec.describe 'Login' do
  let(:current_page) { CurrentPage.new }
  let(:sign_in_page) { SignInPage.new }

  let!(:account) { create(:account) }

  it 'signs in with valid credentials' do
    sign_in_page.visit

    sign_in_page.within_form do |form|
      form.email_address = account.email_address
      form.password = account.password
      form.submit
    end

    expect(current_page).to have_heading account.circle.name
  end

  it 'rejects invalid credentials' do
    sign_in_page.visit

    sign_in_page.within_form do |form|
      form.email_address = account.email_address
      form.password = 'wrong-password'
      form.submit
    end

    expect(current_page)
      .to have_flash 'Try another email address or password.'
  end
end
