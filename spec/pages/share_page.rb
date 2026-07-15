require 'pages/test_page'

class SharePage < TestPage
  def see_all_updates
    click_on 'See all updates'
  end

  def has_post?(body, **)
    has_css?('#post article', text: body, **)
  end
end
