module Posts
  class Publish < ApplicationOperation
    contract do
      params do
        required(:circle).filled(Types::Circle)
        required(:body).filled(:string)
        optional(:photos).array(Types::UploadedFile)
      end
    end

    def call(**input)
      output = step validate(**input)

      step create_post(**output)
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
  end
end
