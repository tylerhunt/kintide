require 'pages/test_page'

class InvitationPage < TestPage
  def accept
    click_on 'Accept invitation'
  end
end
