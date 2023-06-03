# frozen_string_literal: true

require 'nokogiri'
require 'marc'

module MarcSpecHelpers
  # @param [String] filename of MARCXML fixture
  # @return [MARC::Record, NilClass]
  def record_from(filename)
    MARC::XMLReader.new(marc_xml_path(filename)).first
  end

  # @param [String] filename of MARCXML fixture
  # @return [String] full path of MARCXML fixture
  def marc_xml_path(filename)
    File.join File.dirname(__FILE__), '..', 'fixtures', 'marcxml', filename
  end

  # @param [String] code
  # @param [String] value
  # @return [MARC::Subfield]
  def marc_subfield(code, value)
    MARC::Subfield.new code, value
  end

  # @param [String (frozen)] tag
  # @param [String (frozen)] indicator1
  # @param [String (frozen)] indicator2
  # @param [Array] subfields
  # @return [MARC::DataField]
  def marc_field(tag: 'TST', indicator1: ' ', indicator2: ' ', subfields: [])
    build_subfields = subfields.map { |code, value| marc_subfield code, value }
    MARC::DataField.new tag, indicator1, indicator2, *build_subfields
  end
end
