class ApplicationRecord < ActiveRecord::Base
  include DatabaseEnum

  primary_abstract_class
end
