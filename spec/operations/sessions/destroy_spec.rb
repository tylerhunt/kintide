require 'rails_helper'

RSpec.describe Sessions::Destroy do
  subject(:operation) { described_class.new }

  let(:account) { create(:account) }

  let(:session) { account.sessions.create! }

  it 'destroys the session' do
    operation.call(session:)

    expect(session).to be_destroyed
  end

  it 'rejects a missing session' do
    result = operation.call(session: nil)

    expect(result.failure).to match([:invalid, hash_including(:session)])
  end
end
