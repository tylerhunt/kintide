RSpec.configure do |config|
  # The container's SMS adapter is memoized; start each example clean.
  config.before do
    Kintide::Container['sms'].deliveries.clear
  end
end
