class Post < ApplicationRecord
  belongs_to :circle

  has_many :shares, dependent: :destroy

  has_many_attached :photos do |attachable|
    attachable.variant :feed, resize_to_limit: [800, 800]
  end

  validates :body, presence: true

  scope :reverse_chronological, -> { order(created_at: :desc) }
end
