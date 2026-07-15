require 'rails_helper'

RSpec.describe Kintide::SMS::TwilioAdapter, :vcr do
  subject(:adapter) do
    described_class.new(account_sid:, auth_token:, from: '+15005550006')
  end

  # The fallbacks match the VCR filter placeholders so replayed requests
  # line up with the recorded cassette. Recording (VCR=1) requires real
  # Twilio test credentials in the environment.
  let(:account_sid) do
    ENV.fetch('TWILIO_ACCOUNT_SID', 'AC00000000000000000000000000000000')
  end
  let(:auth_token) { ENV.fetch('TWILIO_AUTH_TOKEN', '<CREDENTIALS>') }

  it 'delivers the message through Twilio' do
    message = adapter.deliver(
      to: '+12125550100',
      body: 'Pat posted an update to The Hunts.',
    )

    expect(message.status).to eq('queued')
  end
end
