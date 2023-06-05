# frozen_string_literal: true

module PennMARC
  # Do Subject-y stuff
  class Subject < Helper
    # TODO: what about classified subject headings (MeSH, LCSH, etc.)
    #       that are set in the context clipboard? recreate something similar?
    class << self
      def search(record); end

      def show(record); end

      def facet(record); end
    end
  end
end
