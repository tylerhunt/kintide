require 'pages/test_form'
require 'pages/test_page'

class NewPostPage < TestPage
  class Form < TestForm
    field :body, 'Text'
    field :photos, 'Photos', type: :file
    submit 'Publish'
  end

  def within_form
    within 'form' do
      yield Form.new
    end
  end
end
