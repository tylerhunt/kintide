require 'dry/rails'

# Custom loader that registers the class itself instead of an instance.
# Used for jobs and mailers, which are invoked via class methods.
class ClassLoader < Dry::System::Loader::Autoloading
  def self.call(component, *)
    require! component
    constant(component)
  end
end

Dry::Rails.container do
  # Skip :application_contract; Kintide::Contract is the base contract.
  config.features = %i[safe_params controller_helpers]

  # Avoid memoizing in development (the Rails autoloader invalidates
  # constants) and in test (values can vary per test).
  memoize = !env.local?

  register 'clock', memoize: true do
    -> { Time.current }
  end

  config.component_dirs.add 'app/operations' do |dir|
    dir.auto_register = true
    dir.memoize = memoize
    dir.loader = Dry::System::Loader::Autoloading
  end

  config.component_dirs.add 'app/jobs' do |dir|
    dir.auto_register = true
    dir.loader = ClassLoader
  end

  config.component_dirs.add 'app/mailers' do |dir|
    dir.auto_register = true
    dir.loader = ClassLoader
  end
end
