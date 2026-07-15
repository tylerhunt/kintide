class Circle < ApplicationRecord
  belongs_to :account

  has_many :invitations, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :subscriptions, dependent: :destroy

  validates :name, presence: true
end
