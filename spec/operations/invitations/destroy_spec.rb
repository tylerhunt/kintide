require 'rails_helper'

RSpec.describe Invitations::Destroy do
  subject(:operation) { described_class.new }

  it 'destroys a pending invitation' do
    invitation = create(:invitation)

    operation.call(invitation:)

    expect(Invitation.exists?(invitation.id)).to be(false)
  end

  it 'rejects an accepted invitation' do
    invitation = create(:invitation, :accepted)

    result = operation.call(invitation:)

    expect(result.failure).to match([:accepted, invitation])
  end

  it 'keeps an accepted invitation' do
    invitation = create(:invitation, :accepted)

    operation.call(invitation:)

    expect(Invitation.exists?(invitation.id)).to be(true)
  end

  it 'does not report the accepted failure' do
    allow(Rails.error).to receive(:report)
    invitation = create(:invitation, :accepted)

    operation.call(invitation:)

    expect(Rails.error).to_not have_received(:report)
  end
end
