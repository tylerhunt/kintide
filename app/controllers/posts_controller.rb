require 'dry/monads'

class PostsController < ApplicationController
  include Dry::Monads[:result]

  schema :new

  def new; end

  schema :create do
    required(:body).filled(:string)
    optional(:photos).value(:array)
  end

  def create
    case resolve('posts.publish').call(
      circle: Current.account.circle,
      **safe_params.to_h,
    )
    in Success(*)
      redirect_to root_path, notice: t('flash.posts.published')
    in Failure[:invalid, errors]
      render :new, status: :unprocessable_content, locals: { errors: }
    in Failure[:create_post, post]
      render :new, status: :unprocessable_content,
        locals: { errors: post.errors.to_hash }
    end
  end
end
