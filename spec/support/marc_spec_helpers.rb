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
    MARC::Subfield.new code, value
  end

  # Create an isolated MARC::Field object for use in specs
  # Can pass in tag, indicators and subfields (using simple hash structure). E.g.,
  # marc_field(tag: '650', indicator2: '7'),
  #            subfields: [
  #              { a: 'Tax planning'}, z: 'United States.', '0': http://id.loc.gov/authorities/subjects/sh2008112546 }
  #            ])
  # @param [String (frozen)] tag MARC tag, e.g., 001, 665
  # @param [String (frozen)] indicator1 MARC indicator, e.g., 0
  # @param [String (frozen)] indicator2
  # @param [Array<Hash>] subfields array of subfield values as { code: value }
  # @return [MARC::DataField]
  def marc_field(tag: 'TST', indicator1: ' ', indicator2: ' ', subfields: [])
    build_subfields = subfields.map { |code, value| marc_subfield code, value }
    MARC::DataField.new tag, indicator1, indicator2, *build_subfields
  end
end
