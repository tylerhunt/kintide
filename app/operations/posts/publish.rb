module Posts
  class Publish < ApplicationOperation
    include Kintide::Deps['shares.delivery_job']

    contract do
      params do
        required(:circle).filled(Types::Circle)
        required(:body).filled(:string)
        optional(:photos).array(Types::UploadedFile)
      end
    end

    def call(**input)
      output = step validate(**input)

      post, shares = transaction do
        post = step create_post(**output)
        shares = step create_shares(post:)

        [post, shares]
      end

      step deliver_shares(shares:)

      post
    end

  private

    def create_post(circle:, body:, photos: [])
      post = circle.posts.create(body:, photos:)

      if post.persisted?
        Success(post)
      else
        Failure[__method__, post]
      end
    end

    def create_shares(post:)
      shares = post.circle.subscriptions.active.collect { |subscription|
        post.shares.create!(subscription:)
      }

      Success(shares)
    end

    def deliver_shares(shares:)
      jobs = shares.collect { |share| delivery_job.perform_later(share) }

      Success(jobs)
    end
  end
end
