module Sessions
  class Destroy < ApplicationOperation
    contract do
      params do
        required(:session).filled(Types::Session)
      end
    end

    def call(**input)
      output = step validate(**input)

      step destroy_session(**output)
    end

  private

    def destroy_session(session:)
      Success(session.destroy!)
    end
  end
end
