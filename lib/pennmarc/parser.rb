# frozen_string_literal: true

require 'active_support/all'
require_relative 'helpers/helper'
require_relative 'helpers/creator'
require_relative 'helpers/database'
require_relative 'helpers/date'
require_relative 'helpers/format'
require_relative 'helpers/genre'
require_relative 'helpers/identifier'
require_relative 'helpers/language'
require_relative 'helpers/link'
require_relative 'helpers/location'
require_relative 'helpers/subject'
require_relative 'helpers/title'
require_relative 'helpers/citation'
require_relative 'helpers/relation'
require_relative 'helpers/production'
require_relative 'helpers/edition'
require_relative 'helpers/note'
require_relative 'helpers/series'

# Top level gem namespace
module PennMARC
  attr_accessor :mappings

  DEFINED_HELPERS = %w[Creator Database Date Format Genre Language Link Location Subject Title Relation].freeze

  # Methods here should return values used in the indexer. The parsing logic should
  # NOT return values specific to any particular site/interface, but just general
  # MARC parsing logic for "title", "subject", "author", etc., as much as reasonably
  # possible. We'll see how it goes.
  #
  # Methods should, by default, take in a MARC::Record
  class Parser
    def initialize(helpers: DEFINED_HELPERS)
      @mappings = {}
      @helpers = Array.wrap(helpers) # TODO: load helpers dynamically?
    end

    def respond_to_missing?(name)
      name.split('_').first.in? @helpers
    end

    # Call helper class methods, e.g.,
    # #title_show -> PennMARC::Title.show
    # #subject_facet -> PennMARC::Subject.facet
    def method_missing(name, opts)
      call = name.to_s.split('_')
      helper = call.shift
      meth = call.join('_')
      "PennMARC::#{helper.titleize}".constantize.public_send(meth, opts)
    end

    # Load language map from YAML and memoize in @mappings hash
    # @return [Hash]
    def language_map
      @mappings[:language] ||= load_map('language.yml')
    end

    # Load location map from YAML and memoize in @mappings hash
    # @return [Hash]
    def location_map
      @mappings[:location] ||= load_map('locations.yml')
    end

    # Load relator map from YAML and memoize in @mappings hash
    # @return [Hash]
    def relator_map
      @mappings[:relator] ||= load_map('relator.yml')
    end

    # @param [String] filename of mapping file in config directory, with file extension
    # @return [Hash] mapping as hash
    def load_map(filename)
      YAML.safe_load(File.read(File.join(File.expand_path(__dir__), 'mappings', filename)),
                     symbolize_names: true)
    end
  end
end
