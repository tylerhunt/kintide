class Account < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(email) { email.strip.downcase }
end
