module Kintide
  module StateMachine
    Event = Data.define(:next_state, :guard)
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
