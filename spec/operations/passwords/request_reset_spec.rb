require 'rails_helper'

RSpec.describe Passwords::RequestReset do
  subject(:operation) { described_class.new(passwords_mailer:) }

  let(:passwords_mailer) { class_double(PasswordsMailer) }
  let(:delivery) do
    instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
  end

  before do
    allow(passwords_mailer).to receive(:reset).and_return(delivery)
  end

  it 'delivers reset instructions to a known email address' do
    account = Account.create!(
      name: 'Tyler',
      email_address: 'tyler@example.com',
      password: 'sekret-password',
    )

    operation.call(email_address: 'tyler@example.com')

    expect(passwords_mailer).to have_received(:reset).with(account)
  end

  it 'succeeds for an unknown email address' do
    result = operation.call(email_address: 'unknown@example.com')

    expect(result).to be_success
  end

  it 'does not deliver to an unknown email address' do
    operation.call(email_address: 'unknown@example.com')

    expect(passwords_mailer).to_not have_received(:reset)
  end
end
