class HomeController < ApplicationController
  schema :show

  def show
    circle = Current.account.circle

    render :show, locals: {
      posts: circle.posts.reverse_chronological.with_attached_photos,
      invitations: circle.invitations.order(:created_at),
    }
  end
end
