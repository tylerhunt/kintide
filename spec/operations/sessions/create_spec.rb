require 'rails_helper'

RSpec.describe Sessions::Create do
  subject(:operation) { described_class.new }

  let(:account) { create(:account) }

  let(:input) do
    {
      email_address: account.email_address,
      password: account.password,
      user_agent: 'RSpec',
      ip_address: '127.0.0.1',
    }
  end

  it 'creates a session for valid credentials' do
    result = operation.call(**input)

    expect(result.value!).to have_attributes(
      account:,
      user_agent: 'RSpec',
      ip_address: '127.0.0.1',
    )
  end

  it 'rejects invalid credentials' do
    result = operation.call(**input, password: 'wrong-password')

    expect(result.failure).to eq(:invalid_credentials)
  end

  it 'does not report invalid credentials' do
    allow(Rails.error).to receive(:report)

    operation.call(**input, password: 'wrong-password')

    expect(Rails.error).to_not have_received(:report)
  end

  it 'rejects missing credentials' do
    result = operation.call(**input, password: '')

    expect(result.failure).to match([:invalid, hash_including(:password)])
  end
end
