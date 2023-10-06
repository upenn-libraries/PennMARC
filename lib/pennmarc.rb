# frozen_string_literal: true

$LOAD_PATH.unshift(__dir__) unless $LOAD_PATH.include?(__dir__)

require_relative 'pennmarc/parser'
require 'library_stdnums'

module PennMARC
  VERSION = '1.0.2'
end
