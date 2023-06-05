# frozen_string_literal: true

module PennMARC
  # Do Format-y stuff
  class Format < Helper
    class << self
      def search(record); end

      def show(record); end

      def facet(record); end
    end
  end
end
