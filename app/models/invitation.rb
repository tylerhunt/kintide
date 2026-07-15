require 'phonelib'

class Invitation < ApplicationRecord
  belongs_to :circle

  has_one :subscription, dependent: :destroy

  has_secure_token

  normalizes :phone_number,
    with: ->(number) { Phonelib.parse(number, 'US').e164 }

  validates :name, presence: true
  validates :phone_number, presence: true, uniqueness: { scope: :circle_id }

  def accepted? = accepted_at.present?
end
