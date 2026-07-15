class Share < ApplicationRecord
  belongs_to :post
  belongs_to :subscription

  has_secure_token

  def delivered? = delivered_at.present?
end
