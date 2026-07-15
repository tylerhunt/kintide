require 'pages/test_form'
require 'pages/test_page'

class InvitePage < TestPage
  class Form < TestForm
    field :name, 'Name'
    field :phone_number, 'Phone number'
    submit 'Send invitation'
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
