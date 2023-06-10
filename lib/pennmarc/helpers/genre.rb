# frozen_string_literal: true

module PennMARC
  # Genre field values come from the {https://www.oclc.org/bibformats/en/6xx/655.html 655}, but for some
  # contexts we are only interested in a subset of the declared terms in a record. Some configuration/values
  # in this helper will be shared with the Subject helper.
  class Genre < Helper
    class << self
      # Genre values for searching
      #
      # @todo port get_genre_search_values
      # @param [MARC::Record] record
      # @return [Array]
      def search(record); end

      # Genre values for display
      #
      # @todo port get_genre_display, use allowlist
      # @note legacy method returns a link object
      # @param [MARC::Record] record
      # @return [Array]
      def show(record); end

      # Genre values for faceting
      #
      # @todo port get_genre_values
      # @param [MARC::Record] record
      # @return [Array]
      def facet(record); end
    end
  end
end
