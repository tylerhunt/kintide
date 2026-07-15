class HomeController < ApplicationController
  schema :show

  def show
    circle = Current.account.circle

    render :show, locals: {
      posts: circle.posts.reverse_chronological.with_attached_photos,
      subscriptions: circle.subscriptions.order(:created_at),
    }
  end
end
