require 'pages/test_form'
require 'pages/test_page'

class ForgotPasswordPage < TestPage
  class Form < TestForm
    field :email_address, 'email_address'
    submit 'Email reset instructions'
  end

  def visit
    super new_password_path
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
