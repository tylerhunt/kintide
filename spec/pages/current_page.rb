require 'pages/sign_in_page'
require 'pages/test_page'

class CurrentPage < TestPage
  def has_errors?(message, **)
    has_css?('#errors', text: message, **)
  end

  def has_flash?(message, **)
    has_css?('#notice, #alert', text: message, **)
  end

  # Headings match exactly: substring matching let "You’re in" match a
  # page headed "You’re invited".
  def has_heading?(text, element: 'h1', **)
    has_css?(element, text:, exact_text: true, **)
  end

  def sign_in(
    account,
    password: account.password,
    sign_in_page: SignInPage.new
  )
    sign_in_page.visit

    sign_in_page.within_form do |form|
      form.email_address = account.email_address
      form.password = password
      form.submit
    end
  end
end
