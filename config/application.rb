require_relative 'boot'

require 'rails'

# frameworks
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'

# engines/plugins
require 'importmap-rails'
require 'propshaft'
require 'solid_queue'
require 'stimulus-rails'
require 'tailwindcss-rails'
require 'turbo-rails'

# development/debugging
require 'rspec-rails' if Rails.env.development?
require 'web_console' if Rails.env.development?

module Kintide
  class Application < Rails::Application
    # initialize configuration defaults for originally generated Rails version
    config.load_defaults 8.1

    # ignore `lib` subdirectories that should not be reloaded or eager loaded
    config.autoload_lib ignore: %w[assets tasks]

    # configure generators
    config.generators do |generate|
      # hooks
      generate.orm :active_record, primary_key_type: :uuid
      generate.system_tests :rspec

      # options
      generate.helper false
      generate.request_specs false
      generate.view_specs false
    end
  end
end
