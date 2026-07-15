require 'capybara/rspec'
require 'capybara/playwright'

Capybara.register_driver :playwright_chromium do |app|
  Capybara::Playwright::Driver.new app,
    browser_type: :chromium,
    headless: !ENV.key?('HEAD'), # HEAD=1 bundle exec rspec → watch it run
    reducedMotion: 'reduce'
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.disable_animation = true
end

RSpec.configure do |config|
  config.before(type: :system) do
    driven_by :playwright_chromium
  end
end
