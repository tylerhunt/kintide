require 'pages/test_form'
require 'pages/test_page'

class SignUpPage < TestPage
  class Form < TestForm
    field :name, 'Name'
    field :email_address, 'Email address'
    field :password, 'Password'
    field :password_confirmation, 'Confirm password'
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
