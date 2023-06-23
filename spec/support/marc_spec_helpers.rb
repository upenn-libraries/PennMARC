# frozen_string_literal: true

require 'nokogiri'
require 'marc'

module MarcSpecHelpers
  # Return a MARC::XMLReader that will parse a given file and return MARC::Record objects
  # @param [String] filename of MARCXML fixture
  # @return [MARC::Record, NilClass]
  def record_from(filename)
    MARC::XMLReader.new(marc_xml_path(filename)).first
  end

  # Get the path for a test MARC XML file
  # @param [String] filename of MARCXML fixture
  # @return [String] full path of MARCXML fixture
  def marc_xml_path(filename)
    File.join File.dirname(__FILE__), '..', 'fixtures', 'marcxml', filename
  end

  # Create an isolated MARC::Subfield object for use in specs or as part of a MARC::Field
  # @param [String] code
  # @param [String] value
  # @return [MARC::Subfield]
  def marc_subfield(code, value)
    MARC::Subfield.new code.to_s, value
  end

  # Return a new ControlField (000-009)
  # @param [String] tag
  # @param [String] value
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
  # @param [String (frozen)] tag MARC tag, e.g., 001, 665
  # @param [String (frozen)] indicator1 MARC indicator, e.g., 0
  # @param [String (frozen)] indicator2
  # @param [Hash] subfields hash of subfield values as code => value or code => [value, value]
  # @return [MARC::DataField]
  def marc_field(tag: 'TST', indicator1: ' ', indicator2: ' ', subfields: {})
    subfield_objects = subfields.each_with_object([]) do |(code, value), array|
      Array.wrap(value).map { |v| array << marc_subfield(code, v) }
    end
    MARC::DataField.new tag, indicator1, indicator2, *subfield_objects
  end

  # Return a MARC::Record containing passed in DataFields
  # @param [Array<MARC::DataField>] fields
  # @param [String, nil] leader
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
    {
      dent: {  specific_location: 'Levy Dental Medicine Library - Stacks',
               library: ['Health Sciences Libraries', 'Levy Dental Medicine Library'],
               display: 'Levy Dental Medicine Library - Stacks' },
      stor: { specific_location: 'LIBRA',
              library: 'LIBRA',
              display: 'LIBRA' }.freeze
    }
  end
end
