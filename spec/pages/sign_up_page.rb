require 'pages/test_form'
require 'pages/test_page'

class SignUpPage < TestPage
  class Form < TestForm
    field :name, 'name'
    field :email_address, 'email_address'
    field :password, 'password'
    field :password_confirmation, 'password_confirmation'
    submit 'Sign up'
  end

  def visit
    super signup_path
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
