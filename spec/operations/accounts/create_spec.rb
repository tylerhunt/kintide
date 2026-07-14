require 'rails_helper'

RSpec.describe Accounts::Create do
  subject(:operation) { described_class.new }

  let(:input) do
    {
      name: 'Tyler',
      email_address: 'tyler@example.com',
      password: 'sekret-password',
      password_confirmation: 'sekret-password',
    }
  end

  it 'creates an account' do
    result = operation.call(**input)

    expect(result.value!).to have_attributes(
      name: 'Tyler',
      email_address: 'tyler@example.com',
    )
  end

  it 'rejects an invalid email address' do
    result = operation.call(**input, email_address: 'not-an-email')

    expect(result.failure).to match(
      [:invalid, hash_including(:email_address)],
    )
  end

  it 'rejects a short password' do
    result = operation.call(
      **input,
      password: 'short',
      password_confirmation: 'short',
    )

    expect(result.failure).to match([:invalid, hash_including(:password)])
  end

  it 'rejects a mismatched password confirmation' do
    result = operation.call(**input, password_confirmation: 'different')

    expect(result.failure).to match(
      [:invalid, hash_including(:password_confirmation)],
    )
  end

  it 'rejects a taken email address' do
    Account.create!(**input)

    result = operation.call(**input)

    expect(result.failure).to match(
      [:create_account, an_instance_of(Account)],
    )
  end

  it 'does not report validation failures' do
    allow(Rails.error).to receive(:report)

    operation.call(**input, email_address: 'not-an-email')

    expect(Rails.error).to_not have_received(:report)
  end

  it 'reports unexpected failures' do
    allow(Rails.error).to receive(:report)
    Account.create!(**input)

    operation.call(**input)

    expect(Rails.error).to have_received(:report)
  end
end
