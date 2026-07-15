require 'faker'

RSpec.configure do |config|
  # `Faker::*.unique` tracks values for the process; reset per example so
  # long runs can't exhaust the pool.
  config.before do
    Faker::UniqueGenerator.clear
  end
end
