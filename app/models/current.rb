class Current < ActiveSupport::CurrentAttributes
  attribute :session

  delegate :account, to: :session, allow_nil: true
end
