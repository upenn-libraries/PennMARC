# frozen_string_literal: true

module PennMARC
  # Do Genre-y stuff
  class Genre < Helper
    class << self
      def search(record); end

      def show(record); end

      def facet(record); end
    end
  end
end
