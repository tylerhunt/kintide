require 'vcr'

VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  config.default_cassette_options = {
    allow_unused_http_interactions: false, # cassette drift fails loudly
    record: ENV['VCR'] ? :once : :none, # record only when VCR=1
  }

  # The placeholder is a well-formed SID so replayed requests (built with
  # the same placeholder when the environment variable is absent) match
  # the recorded URIs.
  config.filter_sensitive_data('AC00000000000000000000000000000000') do
    ENV.fetch('TWILIO_ACCOUNT_SID', nil)
  end

  config.filter_sensitive_data('<CREDENTIALS>') do |interaction|
    if (authorization = interaction.request.headers['Authorization'])
      _schema, credentials = authorization.first.split
      credentials
    end
  end
end

RSpec.configure do |config|
  config.around :each, :integration do |example|
    VCR.turned_off do
      example.run
    end
  end
end
