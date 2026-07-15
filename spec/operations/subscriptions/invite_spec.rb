require 'rails_helper'

RSpec.describe Subscriptions::Invite do
  subject(:operation) { described_class.new(sms:) }

  let(:sms) { Kintide::SMS::TestAdapter.new }

  let(:circle) { create(:circle) }

  let(:input) do
    {
      circle:,
      name: 'Grandma June',
      phone_number: '(212) 555-0123',
    }
  end

  it 'creates an invited subscription with a normalized phone number' do
    result = operation.call(**input)

    expect(result.value!).to have_attributes(
      circle:,
      name: 'Grandma June',
      phone_number: '+12125550123',
    )
  end

  it 'starts in the invited state' do
    result = operation.call(**input)

    expect(result.value!).to be_invited
  end

  it 'delivers an SMS with the subscription link' do
    result = operation.call(**input)

    expect(sms.deliveries.last).to have_attributes(
      to: '+12125550123',
      body: include("/s/#{result.value!.token}"),
    )
  end

  it 'rejects an invalid phone number' do
    result = operation.call(**input, phone_number: '555')

    expect(result.failure).to match(
      [:invalid, hash_including(:phone_number)],
    )
  end

  it 'rejects a phone number already in the circle' do
    operation.call(**input)

    result = operation.call(**input, name: 'Also June')

    expect(result.failure).to match(
      [:create_subscription, an_instance_of(Subscription)],
    )
  end
end
