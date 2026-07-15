require 'phonelib'

class Subscription < ApplicationRecord
  include StateMachine[SubscriptionStateMachine]

  belongs_to :circle

  has_secure_token

  normalizes :phone_number,
    with: ->(number) { Phonelib.parse(number, 'US').e164 }

  enum :state, :subscription_states, instance_methods: false

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { scope: :circle_id }
end
