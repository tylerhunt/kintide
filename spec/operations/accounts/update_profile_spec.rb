require 'rails_helper'

RSpec.describe Accounts::UpdateProfile do
  subject(:operation) { described_class.new }

  let(:account) { create(:account) }

  let(:avatar) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('spec/fixtures/files/first-photo.png'),
      'image/png',
    )
  end

  it 'updates the name' do
    result = operation.call(account:, name: 'Pat Hunt')

    expect(result.value!.name).to eq('Pat Hunt')
  end

  it 'attaches the avatar' do
    result = operation.call(account:, name: account.name, avatar:)

    expect(result.value!.avatar).to be_attached
  end

  it 'keeps the avatar when none is uploaded' do
    account.avatar.attach(avatar)

    operation.call(account:, name: 'Pat Hunt')

    expect(account.reload.avatar).to be_attached
  end

  it 'rejects a blank name' do
    result = operation.call(account:, name: '')

    expect(result.failure).to match([:invalid, hash_including(:name)])
  end
end
