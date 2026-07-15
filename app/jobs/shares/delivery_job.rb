module Shares
  class DeliveryJob < ApplicationJob
    def perform(share)
      Kintide::Container['shares.deliver'].call(share:)
    end
  end
end
