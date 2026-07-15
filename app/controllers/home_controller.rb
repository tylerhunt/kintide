class HomeController < ApplicationController
  schema :show

  def show
    render :show, locals: {
      posts: Current.account.circle.posts
        .reverse_chronological
        .with_attached_photos,
    }
  end
end
