require 'rails_helper'

RSpec.describe Posts::Publish do
  subject(:operation) { described_class.new }

  let(:circle) { create(:circle) }

  let(:input) do
    {
      circle:,
      body: 'We went to the beach this weekend.',
      photos: [
        Rack::Test::UploadedFile.new(
          Rails.root.join('spec/fixtures/files/first-photo.png'),
          'image/png',
        ),
      ],
    }
  end

  it 'publishes the post to the circle' do
    result = operation.call(**input)

    expect(result.value!).to have_attributes(
      circle:,
      body: 'We went to the beach this weekend.',
    )
  end

  it 'attaches the photos' do
    result = operation.call(**input)

    expect(result.value!.photos.count).to eq(1)
  end

  it 'publishes without photos' do
    result = operation.call(**input.except(:photos))

    expect(result).to be_success
  end

  it 'shares the post with active subscribers only' do
    active = create(:subscription, :active, circle:)
    create(:subscription, circle:)
    create(:subscription, :deactivated, circle:)

    result = operation.call(**input)

    expect(result.value!.shares.collect(&:subscription)).to eq([active])
  end

  it 'enqueues a delivery job for each share' do
    create(:subscription, :active, circle:)

    expect { operation.call(**input) }
      .to have_enqueued_job(Shares::DeliveryJob).once
  end

  it 'rejects a blank body' do
    result = operation.call(**input, body: '')

    expect(result.failure).to match([:invalid, hash_including(:body)])
  end
end
