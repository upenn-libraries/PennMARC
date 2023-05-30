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
end
