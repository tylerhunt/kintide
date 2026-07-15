require 'webmock/rspec'

# The Capybara server and Playwright control channel are local traffic.
WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.around :each, :integration do |example|
    WebMock.allow_net_connect!
    example.run
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
