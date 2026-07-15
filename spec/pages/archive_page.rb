require 'pages/test_page'

class ArchivePage < TestPage
  def visit(token)
    super subscription_path(token)
  end

  def unsubscribe
    click_on 'Unsubscribe'
  end

  def has_post?(body, **)
    has_css?('#posts article', text: body, **)
  end

  def has_no_post?(body, **)
    has_no_css?('#posts article', text: body, **)
  end
end
