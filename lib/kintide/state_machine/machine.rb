module Kintide
  module StateMachine
    include Errors

    class Machine
      class << self
        def events = states.flat_map { |_, state| state.events.keys }.uniq

        def initial
          name, _ = states.detect { |_, state| state.initial }
          name or raise Errors::UndefinedInitialState
        end

        def state(name, initial: false, &)
          states[name.to_s] = StateBuilder.build(initial:, &)
        end

        def states
          @states ||= {}
        end
      end

      attr_reader :state

      def initialize(state: self.class.initial)
        self.state = state.to_s
      end

      def can_invoke?(name, context: nil)
        current_state.events[name.to_s]&.permitted?(context)
      end

      def invoke(name, context: nil)
        event = current_state.events[name.to_s]

        verify_event! name, event
        verify_guard! name, event, context

        self.state = event.resolve_next_state(context)
      end

    protected

      def state=(state)
        @state = state.to_s
      end

    private

      def current_state = self.class.states.fetch(state)

      def verify_event!(event_name, event)
        raise Errors::InvalidEvent.new(event_name, state) unless event
      end

      def verify_guard!(event_name, event, context)
        return if event.permitted?(context)

        raise Errors::TransitionHalted.new(event_name, state)
      end
    end
  end
end
