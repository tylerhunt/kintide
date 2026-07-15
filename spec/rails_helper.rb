require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'

if Rails.env.production?
  abort 'The Rails environment is running in production mode!'
end

require 'rspec/rails'

Rails.root.glob('spec/support/**/*.rb').sort.each do |file|
  require file
end

# ensure the test database schema matches the current schema file
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => error
  abort error.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include ActiveSupport::Testing::TimeHelpers
end
