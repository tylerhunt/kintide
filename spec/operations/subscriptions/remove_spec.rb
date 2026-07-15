require 'rails_helper'

RSpec.describe Subscriptions::Remove do
  subject(:operation) { described_class.new }

  it 'removes an invited subscription' do
    subscription = create(:subscription)

    operation.call(subscription:)

    expect(Subscription.exists?(subscription.id)).to be(false)
  end

  it 'rejects an active subscription' do
    subscription = create(:subscription, :active)

    result = operation.call(subscription:)

    expect(result.failure).to match([:accepted, subscription])
  end

  it 'keeps an active subscription' do
    subscription = create(:subscription, :active)

    operation.call(subscription:)

    expect(Subscription.exists?(subscription.id)).to be(true)
  end

  it 'does not report the accepted failure' do
    allow(Rails.error).to receive(:report)
    subscription = create(:subscription, :active)

    operation.call(subscription:)

    expect(Rails.error).to_not have_received(:report)
  end
end
