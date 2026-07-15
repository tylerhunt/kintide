require 'active_support/concern'
require 'active_record'

# Inspired by https://github.com/keygen-sh/temporary_tables/
module TemporaryModel
  extend ActiveSupport::Concern

  class_methods do
    def temporary_model(
      class_name,
      table_name: class_name.tableize,
      super_class: ActiveRecord::Base,
      &
    )
      before do
        model = Class.new(*super_class) do
          self.table_name = table_name if respond_to?(:table_name=)

          define_singleton_method :name do
            class_name
          end

          class_exec(&)
        end

        stub_const class_name, model
      end
    end
  end
end

RSpec.configure do |config|
  config.include TemporaryModel
end
