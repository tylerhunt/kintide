module Kintide
  module StateMachine
    module Errors
      Error = Class.new(StandardError)
      UndefinedInitialState = Class.new(Error)

      class InvalidEvent < Error
        def initialize(event, state)
          super "no event #{event} exists in state #{state}"
        end
      end

      class TransitionHalted < Error
        def initialize(event, state)
          super "failed to invoke #{event} from #{state}"
        end
      end
    end
  end
end
