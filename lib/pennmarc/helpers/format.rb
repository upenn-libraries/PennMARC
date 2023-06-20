# frozen_string_literal: true

module PennMARC
  # Do Format-y stuff
  class Format < Helper
    class << self
      # @todo port get_format_display
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record); end

      # @todo port from get_format
      # @param [MARC::Record] record
      # @return [Array<String>]
      def facet(record); end

      # @todo port get_other_format_display
      # @param [MARC::Record] record
      # @return [Array<String>]
      def other_format(record); end
    end
  end
end
