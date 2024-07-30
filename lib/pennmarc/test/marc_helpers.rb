# frozen_string_literal: true

require 'nokogiri'
require 'marc'

module PennMARC
  module Test
    # Helper methods for use in constructing MARC objects for testing
    module MarcHelpers
      # Return a MARC::XMLReader that will parse a given file and return MARC::Record objects
      # @param filename [String] filename of MARCXML fixture
      # @return [MARC::Record, NilClass]
      def record_from(filename)
        MARC::XMLReader.new(marc_xml_path(filename)).first
      end

      # Create an isolated MARC::Subfield object for use in specs or as part of a MARC::Field
      # @param code [String]
      # @param value [String]
      # @return [MARC::Subfield]
      def marc_subfield(code, value)
        MARC::Subfield.new code.to_s, value
      end

      # Return a new ControlField (000-009)
      # @param tag [String]
      # @param value [String]
      # @return [MARC::ControlField]
      def marc_control_field(tag:, value:)
        MARC::ControlField.new tag, value
      end

      # Create an isolated MARC::DataField object for use in specs
      # Can pass in tag, indicators and subfields (using simple hash structure). E.g.,
      # marc_field(tag: '650', indicator2: '7'),
      #            subfields: { a: 'Tax planning',
      #                         m: ['Multiple', 'Subfields']
      #                         z: 'United States.',
      #                         '0': http://id.loc.gov/authorities/subjects/sh2008112546 }
      #            )
      # @param tag [String (frozen)] MARC tag, e.g., 001, 665
      # @param indicator1 [String (frozen)]  MARC indicator 1, e.g., 0
      # @param indicator2 [String (frozen)]
      # @param subfields [Hash] hash of subfield values as code => value or code => [value, value]
      # @return [MARC::DataField]
      def marc_field(tag: 'TST', indicator1: ' ', indicator2: ' ', subfields: {})
        subfield_objects = subfields.each_with_object([]) do |(code, value), array|
          Array.wrap(value).map { |v| array << marc_subfield(code, v) }
        end
        MARC::DataField.new tag, indicator1, indicator2, *subfield_objects
      end

      # Return a MARC::Record containing passed in DataFields
      # @param fields [Array<MARC::DataField>]
      # @param leader [String, nil]
      # @return [MARC::Record]
      def marc_record(fields: [], leader: nil)
        record = MARC::Record.new
        fields.each { |field| record << field }
        record.leader = leader if leader
        record
      end

      # Mock map for location lookup using Location helper
      # The location codes :dent and :stor are the two outermost keys
      # :specific_location, :library, :display are the inner keys that store location values
      # @example
      #   location_map[:stor][:library] #=> 'LIBRA'
      # @return [Hash]
      def location_map
        { dent: {  specific_location: 'Levy Dental Medicine Library - Stacks',
                   library: ['Health Sciences Libraries', 'Levy Dental Medicine Library'],
                   display: 'Levy Dental Medicine Library - Stacks' },
          stor: { specific_location: 'LIBRA',
                  library: 'LIBRA',
                  display: 'LIBRA' },
          vanp: { specific_location: 'Van Pelt - Stacks',
                  library: 'Van Pelt-Dietrich Library Center',
                  display: 'Van Pelt Library' } }
      end
    end
  end
end
