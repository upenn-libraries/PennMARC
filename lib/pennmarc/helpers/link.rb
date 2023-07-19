# frozen_string_literal: true

module PennMARC
  # Do Link-y stuff
  class Link < Helper
    class << self
      # @todo the legacy code here is a hot mess for a number of reasons, what do we need this field to do?
      # @note port the needed parts from get_offsite_display, don't return HTML
      # @param [MARC::Record] record
      # @return [Object]
      def offsite(record); end

      def full_text(record:); end

      def web(record:); end
    end
  end
end
