require 'rails_helper'

RSpec.describe Invitations::Accept do
  subject(:operation) { described_class.new }

  let(:invitation) { create(:invitation) }

  it 'creates a subscription from the invitation' do
    result = operation.call(invitation:)

    expect(result.value!).to have_attributes(
      circle: invitation.circle,
      name: invitation.name,
      phone_number: invitation.phone_number,
    )
  end

  it 'marks the invitation accepted' do
    operation.call(invitation:)

    expect(invitation.reload).to be_accepted
  end

  it 'returns the existing subscription for a reused link' do
    subscription = operation.call(invitation:).value!

    result = operation.call(invitation: invitation.reload)

    expect(result.value!).to eq(subscription)
  end
end
