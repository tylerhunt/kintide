require 'rails_helper'

RSpec.describe Subscriptions::Deactivate do
  subject(:operation) { described_class.new }

  let(:subscription) { create(:subscription) }

  it 'deactivates the subscription' do
    operation.call(subscription:)

    expect(Subscription.active).to_not include(subscription)
  end

  it 'keeps the original timestamp when deactivated again' do
    operation.call(subscription:)
    deactivated_at = subscription.reload.deactivated_at

    operation.call(subscription:)

    expect(subscription.reload.deactivated_at).to eq(deactivated_at)
  end
end
