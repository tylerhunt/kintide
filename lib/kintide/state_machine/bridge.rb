module Kintide
  module StateMachine
    class Bridge < Module
      def self.[](machine_class, **) = new(machine_class, **)

      def initialize(machine_class, prefix: nil)
        super()

        method_name = ->(part) { [*prefix, part].join('_').to_sym }

        define_machine_method machine_class, method_name
        define_invoke_method method_name
        define_event_methods machine_class, method_name
        define_state_predicate_methods machine_class, method_name
      end

    private

      def define_machine_method(machine_class, method_name)
        state_attribute = method_name[:state]

        define_method method_name[:machine] do
          machine_class.new(state: send(state_attribute))
        end
      end

      def define_invoke_method(method_name)
        machine_method = method_name[:machine]
        state_attribute = method_name[:state]

        define_method method_name[:invoke] do |name, context: self|
          machine = send(machine_method)
          machine.invoke(name, context:)
          send :"#{state_attribute}=", machine.state
        end
      end

      def define_event_methods(machine_class, method_name)
        machine_method = method_name[:machine]
        invoke_method = method_name[:invoke]

        machine_class.events.each do |event|
          define_method :"can_#{method_name[event]}?" do |context: self|
            send(machine_method).can_invoke?(event, context:)
          end

          define_method :"#{method_name[event]}!" do |context: self|
            send(invoke_method, event, context:)
            save!
          end
        end
      end

      def define_state_predicate_methods(machine_class, method_name)
        state_attribute = method_name[:state]

        machine_class.states.each_key do |state|
          define_method :"#{method_name[state]}?" do
            send(state_attribute) == state
          end
        end
      end
    end
  end
end
