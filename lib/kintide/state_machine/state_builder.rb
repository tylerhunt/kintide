module Kintide
  module StateMachine
    Event = Data.define(:next_state, :guard) {
      def permitted?(context) = guard.nil? || guard.call(context)

      def resolve_next_state(context)
        next_state.respond_to?(:call) ? next_state.call(context) : next_state
      end
    }

    State = Data.define(:events, :initial)

    class StateBuilder
      def self.build(initial:, &)
        builder = new
        builder.instance_eval(&) if block_given?

        State.new(events: builder.events, initial:)
      end

      def event(name, to:, **options)
        events[name.to_s] = Event.new(guard: options[:if], next_state: to)
      end

      def events
        @events ||= {}
      end
    end
  end
end
