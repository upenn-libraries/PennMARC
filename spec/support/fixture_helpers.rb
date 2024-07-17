# frozen_string_literal: true

module FixtureHelpers
  # Get the path for a test MARC XML file
  # @param [String] filename of MARCXML fixture
  # @return [String] full path of MARCXML fixture
  def marc_xml_path(filename)
    File.join File.dirname(__FILE__), '..', 'fixtures', 'marcxml', filename
  end
end
