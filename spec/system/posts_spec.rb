require 'rails_helper'
require 'pages/current_page'
require 'pages/home_page'
require 'pages/new_post_page'

RSpec.describe 'Posts' do
  let(:current_page) { CurrentPage.new }
  let(:home_page) { HomePage.new }
  let(:new_post_page) { NewPostPage.new }

  let!(:account) { create(:account) }

  before do
    current_page.sign_in account
  end

  it 'publishes a post with photos' do
    home_page.new_post

    expect(current_page).to have_heading 'New post'

    new_post_page.within_form do |form|
      form.body = 'We went to the beach this weekend.'
      form.photos = [
        file_fixture('first-photo.png'),
        file_fixture('second-photo.png'),
      ]
      form.submit
    end

    expect(current_page).to have_flash 'Post published.'
    expect(home_page).to have_post 'We went to the beach this weekend.'
    expect(home_page).to have_photos 2
  end
end
