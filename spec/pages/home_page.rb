require 'pages/test_page'

class HomePage < TestPage
  def new_post
    click_on 'New post'
  end

  def has_post?(body, **)
    has_css?('#posts article', text: body, **)
  end

  def has_photos?(count)
    has_css?('#posts article img', count:)
  end
end
