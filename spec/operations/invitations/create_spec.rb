require 'rails_helper'

RSpec.describe Invitations::Create do
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

  it 'creates the invitation with a normalized phone number' do
    result = operation.call(**input)

    expect(result.value!).to have_attributes(
      circle:,
      name: 'Grandma June',
      phone_number: '+12125550123',
    )
  end

  it 'delivers an SMS with the accept link' do
    result = operation.call(**input)

    expect(sms.deliveries.last).to have_attributes(
      to: '+12125550123',
      body: include(result.value!.token),
    )
  end

  it 'rejects an invalid phone number' do
    result = operation.call(**input, phone_number: '555')

    expect(result.failure).to match(
      [:invalid, hash_including(:phone_number)],
    )
  end

  it 'rejects a phone number already invited to the circle' do
    operation.call(**input)

    result = operation.call(**input, name: 'Also June')

    expect(result.failure).to match(
      [:create_invitation, an_instance_of(Invitation)],
    )
  end
end
