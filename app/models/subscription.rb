class Subscription < ApplicationRecord
  belongs_to :circle
  belongs_to :invitation

  has_secure_token

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { scope: :circle_id }

  scope :active, -> { where(deactivated_at: nil) }
end
