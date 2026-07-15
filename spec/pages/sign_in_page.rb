require 'pages/test_form'
require 'pages/test_page'

class SignInPage < TestPage
  class Form < TestForm
    field :email_address, 'email_address'
    field :password, 'password'
    submit 'Sign in'
  end

  def visit
    super new_session_path
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
