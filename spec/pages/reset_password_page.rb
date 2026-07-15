require 'pages/test_form'
require 'pages/test_page'

class ResetPasswordPage < TestPage
  class Form < TestForm
    field :password, 'password'
    field :password_confirmation, 'password_confirmation'
    submit 'Save'
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
