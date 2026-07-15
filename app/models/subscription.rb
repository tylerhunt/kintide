require 'phonelib'

class Subscription < ApplicationRecord
  class StateMachine < Kintide::StateMachine::Machine
    state :invited, initial: true do
      event :accept, to: :active
      event :deactivate, to: :deactivated
    end

    state :active do
      event :deactivate, to: :deactivated
    end

    state :deactivated
  end

  include Kintide::StateMachine::Bridge[StateMachine]

  belongs_to :circle

  has_secure_token

  normalizes :phone_number,
    with: ->(number) { Phonelib.parse(number, 'US').e164 }

  enum :state, :subscription_states, instance_methods: false

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { scope: :circle_id }
end
