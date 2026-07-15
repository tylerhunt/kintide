require 'rails_helper'
require 'pages/archive_page'
require 'pages/current_page'
require 'pages/home_page'
require 'pages/new_post_page'
require 'pages/share_page'

RSpec.describe 'Post sharing' do
  include ActiveJob::TestHelper

  let(:archive_page) { ArchivePage.new }
  let(:current_page) { CurrentPage.new }
  let(:home_page) { HomePage.new }
  let(:new_post_page) { NewPostPage.new }
  let(:share_page) { SharePage.new }

  let!(:account) { create(:account) }
  let!(:subscription) do
    create(:subscription, :active, circle: account.circle)
  end

  let(:sms) { Kintide::Container['sms'] }

  it 'texts each subscriber a link to the shared post' do
    current_page.sign_in account
    home_page.new_post

    expect(current_page).to have_heading 'New post'

    new_post_page.within_form do |form|
      form.body = 'We went to the beach this weekend.'
      form.submit
    end

    expect(current_page).to have_flash 'Post published.'

    perform_enqueued_jobs

    delivery = sms.deliveries.last
    expect(delivery.to).to eq(subscription.phone_number)

    visit delivery.body[%r{https?://\S+}]

    expect(current_page).to have_heading account.circle.name
    expect(share_page).to have_post 'We went to the beach this weekend.'

    share_page.see_all_updates

    expect(archive_page).to have_post 'We went to the beach this weekend.'

    archive_page.unsubscribe

    expect(current_page).to have_heading 'You’re unsubscribed'

    visit delivery.body[%r{https?://\S+}]

    expect(current_page).to have_heading 'You’re unsubscribed'
  end
end
