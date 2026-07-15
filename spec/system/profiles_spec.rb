require 'rails_helper'
require 'pages/current_page'
require 'pages/home_page'
require 'pages/profile_page'

RSpec.describe 'Profile editing' do
  let(:current_page) { CurrentPage.new }
  let(:home_page) { HomePage.new }
  let(:profile_page) { ProfilePage.new }

  let!(:account) { create(:account) }

  it 'updates the name and avatar' do
    current_page.sign_in account
    home_page.edit_profile

    expect(current_page).to have_heading 'Edit profile'

    profile_page.within_form do |form|
      form.name = 'Pat Hunt'
      form.avatar = Rails.root.join('spec/fixtures/files/first-photo.png')
      form.submit
    end

    expect(current_page).to have_flash 'Profile updated.'
    expect(home_page).to have_welcome 'Pat Hunt'

    home_page.edit_profile

    expect(profile_page).to have_avatar
  end
end
