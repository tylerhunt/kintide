require 'rails_helper'
require 'pages/archive_page'
require 'pages/current_page'

RSpec.describe 'Subscriber archive' do
  let(:archive_page) { ArchivePage.new }
  let(:current_page) { CurrentPage.new }

  let(:subscription) { create(:subscription) }

  before do
    create(
      :post,
      circle: subscription.circle,
      body: 'We went to the beach this weekend.',
    )
  end

  it 'shows the archive until unsubscribed' do
    archive_page.visit subscription.token

    expect(current_page).to have_heading subscription.circle.name
    expect(archive_page).to have_post 'We went to the beach this weekend.'

    archive_page.unsubscribe

    expect(current_page).to have_flash 'You’ve unsubscribed.'
    expect(current_page).to have_heading 'You’re unsubscribed'

    archive_page.visit subscription.token

    expect(archive_page)
      .to have_no_post 'We went to the beach this weekend.'
  end
end
