# frozen_string_literal: true

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

module PennMARC
  # Autoload MARC helpers
  module Test
    autoload :MarcHelpers, 'test/marc_helpers'
  end
end

require_relative 'pennmarc/parser'
require 'library_stdnums'
