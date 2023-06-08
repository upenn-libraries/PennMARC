# frozen_string_literal: true

module PennMARC
  # Parser methods for extracting identifier values.
  class Identifier < Helper
    class << self
      # Alma MMS ID value
      #
      # @param [MARC::Record] record
      # @return [String]
      def mmsid(record)
        record.fields('001').first.value
      end

      # Aggregate ISXN field intended for search
      #
      # @todo port FranklinIndexer isbn_isxn_stored
      # @param [MARC::Record] record
      # @return [Array<String>]
      def isxn_search(record); end

      # ISBN values
      #
      # @todo port Marc#get_isbn_display
      # @param [MARC::Record] record
      # @return [Array]
      def isbn_show(record); end

      # ISSN values
      #
      # @ todo port Marc#get_issn_display
      # @param [MARC::Record] record
      # @return [Array]
      def issn_show(record); end

      # OCLC ID values
      #
      # @todo port Marc#get_oclc_id_values
      # @param [MARC::Record] record
      # @return [Array]
      def oclc_id(record); end

      # Publisher Number Display
      #
      # @todo port Marc::get_publisher_number_display
      # @param [MARC::Record] record
      # @return [Array]
      def publisher_number_show(record); end
      
      # Publisher Number Search
      # @todo port FranklinIndexer pubnum_search
      # 
      # @param [MARC::Record] record
      # @return [Array]
      def publisher_number_search(record); end
    end
  end
end
