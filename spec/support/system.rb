require 'dry/system/stubs'

Kintide::Container.enable_stubs!

RSpec.configure do |config|
  config.after do
    Kintide::Container.unstub
  end
end
