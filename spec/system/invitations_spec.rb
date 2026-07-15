require 'rails_helper'
require 'pages/current_page'
require 'pages/home_page'
require 'pages/invitation_page'
require 'pages/invite_page'

RSpec.describe 'Invitations' do
  let(:current_page) { CurrentPage.new }
  let(:home_page) { HomePage.new }
  let(:invitation_page) { InvitationPage.new }
  let(:invite_page) { InvitePage.new }

  let!(:account) { create(:account) }

  let(:sms) { Kintide::Container['sms'] }

  it 'invites a subscriber who accepts by text' do
    current_page.sign_in account
    home_page.invite

    expect(current_page).to have_heading 'Invite a subscriber'

    invite_page.within_form do |form|
      form.name = 'Grandma June'
      form.phone_number = '(212) 555-0123'
      form.submit
    end

    expect(current_page).to have_flash 'Invitation sent.'
    expect(home_page).to have_subscriber 'Grandma June', status: 'Invited'

    delivery = sms.deliveries.last
    expect(delivery.to).to eq('+12125550123')

    visit delivery.body[%r{https?://\S+}]
    invitation_page.accept

    expect(current_page).to have_current_path %r{/s/\w+}
    expect(current_page).to have_flash 'You’re in!'
    expect(current_page).to have_heading account.circle.name

    visit root_path

    expect(home_page)
      .to have_subscriber 'Grandma June', status: 'Subscribed'
  end

  it 'removes a pending invitation' do
    create(:subscription, circle: account.circle, name: 'Uncle Ray')

    current_page.sign_in account
    home_page.remove_subscriber 'Uncle Ray'

    expect(current_page).to have_flash 'Invitation removed.'
    expect(home_page).to have_no_subscriber 'Uncle Ray'
  end
end
