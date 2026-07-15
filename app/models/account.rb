class Account < ApplicationRecord
  has_secure_password

  has_one :circle, dependent: :destroy
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
end
