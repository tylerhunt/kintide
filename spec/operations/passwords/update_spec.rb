require 'rails_helper'

RSpec.describe Passwords::Update do
  subject(:operation) { described_class.new }

  let(:account) { create(:account) }

  let(:input) do
    {
      account:,
      password: 'new-sekret-password',
      password_confirmation: 'new-sekret-password',
    }
  end

  it 'updates the password' do
    operation.call(**input)

    authenticated = Account.authenticate_by(
      email_address: 'tyler@example.com',
      password: 'new-sekret-password',
    )

    expect(authenticated).to eq(account)
  end

  it 'destroys existing sessions' do
    session = account.sessions.create!

    operation.call(**input)

    expect(Session.exists?(session.id)).to be(false)
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
end
