require 'pages/test_form'
require 'pages/test_page'

class ProfilePage < TestPage
  class Form < TestForm
    field :name, 'Name'
    field :avatar, 'Avatar', type: :file
    submit 'Save'
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end

  def has_avatar?
    has_css? 'form img'
  end
end
