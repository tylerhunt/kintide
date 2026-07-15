require 'pages/test_form'
require 'pages/test_page'

class ResetPasswordPage < TestPage
  class Form < TestForm
    field :password, 'New password'
    field :password_confirmation, 'Confirm new password'
    submit 'Save'
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
