class SubscriptionStateMachine < ApplicationStateMachine
  state :invited, initial: true do
    event :accept, to: :active
    event :deactivate, to: :deactivated
  end

  state :active do
    event :deactivate, to: :deactivated
  end

  state :deactivated
end
