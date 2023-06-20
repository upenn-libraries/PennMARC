# frozen_string_literal: true

module PennMARC
  # Methods that return Library and Location values from Alma enhanced MARC fields
  class Location < Helper
    class << self
      # @todo port logic from get_library_values
      # @param [MARC::Record] record
      # @param [Hash] location_map
      # @return [Array<String>]
      def library(record, location_map); end

      # @todo port logic from get_specific_location_values
      # @param [MARC::Record] record
      # @param [Hash] location_map
      # @return [Array<String>]
      def specific_location(record, location_map); end
    end
  end
end
