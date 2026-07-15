module Kintide
  module StateMachine
    class Bridge < Data.define(:machine_class, :prefix)
      def self.[](machine_class, prefix: nil)
        new(machine_class:, prefix:).module
      end

      def module
        Module.new.tap { |methods_module|
          define_machine_accessor methods_module
          define_event_predicate_methods methods_module
          define_state_predicate_methods methods_module
          define_bang_methods methods_module
          define_invoke_method methods_module
        }
      end

    private

      def build_method(name) = [*prefix, name].join('_').to_sym
      def machine_accessor = build_method(:machine)
      def state_attribute = build_method(:state)
      def invoke_method = build_method(:invoke)

      def define_machine_accessor(object)
        variable = :"@#{machine_accessor}"
        machine_class = self.machine_class
        state_attribute = self.state_attribute

        object.define_method machine_accessor do
          instance_variable_get(variable) or
            instance_variable_set(
              variable,
              machine_class.new(state: send(state_attribute)),
            )
        end
      end

      def define_event_predicate_methods(object)
        machine_accessor = self.machine_accessor

        machine_class.events.each do |event|
          object.define_method "can_#{build_method(event)}?" do |context: self|
            machine = send(machine_accessor)
            machine.can_invoke?(event, context:)
          end
        end
      end

      def define_state_predicate_methods(object)
        state_attribute = self.state_attribute

        machine_class.states.each_key do |state|
          object.define_method "#{build_method(state)}?" do
            send(state_attribute) == state
          end
        end
      end

      def define_bang_methods(object)
        invoke_method = self.invoke_method

        machine_class.events.each do |event|
          object.define_method "#{build_method(event)}!" do |context: self|
            send(invoke_method, event, context:)
            save!
          end
        end
      end

      def define_invoke_method(object)
        machine_accessor = self.machine_accessor
        state_attribute = self.state_attribute

        object.define_method invoke_method do |name, context: self|
          machine = send(machine_accessor)
          machine.invoke(name, context:)
          send :"#{state_attribute}=", machine.state
        end
      end
    end
  end
end
