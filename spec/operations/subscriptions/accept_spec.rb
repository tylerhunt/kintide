require 'rails_helper'

RSpec.describe Subscriptions::Accept do
  subject(:operation) { described_class.new }

  let(:subscription) { create(:subscription) }

  it 'activates the subscription' do
    result = operation.call(subscription:)

    expect(result.value!).to be_active
  end

  it 'stamps the acceptance time' do
    operation.call(subscription:)

    expect(subscription.reload.accepted_at).to be_present
  end

  it 'leaves an active subscription untouched by a reused link' do
    accepted_at = operation.call(subscription:).value!.accepted_at

    result = operation.call(subscription: subscription.reload)

    expect(result.value!.accepted_at).to eq(accepted_at)
  end

  it 'does not revive a deactivated subscription' do
    deactivated = create(:subscription, :deactivated)

    result = operation.call(subscription: deactivated)

    expect(result.value!).to be_deactivated
  end
end
