require 'rails_helper'

RSpec.describe Shares::Deliver do
  subject(:operation) { described_class.new(sms:) }

  let(:sms) { Kintide::SMS::TestAdapter.new }

  let(:share) { create(:share) }

  it 'texts the subscriber a link to the share' do
    operation.call(share:)

    expect(sms.deliveries.last).to have_attributes(
      to: share.subscription.phone_number,
      body: include("/p/#{share.token}"),
    )
  end

  it 'stamps the delivery time' do
    operation.call(share:)

    expect(share.reload).to be_delivered
  end

  it 'refuses to deliver twice' do
    delivered = create(:share, :delivered)

    result = operation.call(share: delivered)

    expect(result.failure).to match([:delivered, delivered])
  end

  it 'does not text on a repeated delivery' do
    delivered = create(:share, :delivered)

    operation.call(share: delivered)

    expect(sms.deliveries).to be_empty
  end

  it 'does not report a repeated delivery' do
    allow(Rails.error).to receive(:report)
    delivered = create(:share, :delivered)

    operation.call(share: delivered)

    expect(Rails.error).to_not have_received(:report)
  end
end
