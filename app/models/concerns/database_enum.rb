module DatabaseEnum
  extend ActiveSupport::Concern

  module ClassMethods
    # Overrides Rails' `enum` to provide default options and support for
    # loading values from the database.
    def enum(name, enum_type, **)
      super name, enum_values(enum_type), validate: true, **
    end

  private

    def enum_values(enum)
      @enum_values ||= ApplicationRecord.connection.enum_types.to_h
      @enum_values.fetch(enum.to_s).index_by(&:itself)
    end
  end
end
