# frozen_string_literal: true

module PennMARC
  # Do Database-y stuff
  class Database < Helper
    class << self
      def type(record); end

      def db_category(record); end

      def db_subcategory(record); end
    end
  end
end
