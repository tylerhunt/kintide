class Account < ApplicationRecord
  has_secure_password

  has_one :circle, dependent: :destroy
  has_many :sessions, dependent: :destroy

  has_one_attached :avatar do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [96, 96]
  end

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :name, presence: true
end
