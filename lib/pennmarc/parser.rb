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

module PennMARC
  attr_accessor :mappings

  DEFINED_HELPERS = %w[Creator Database Date Format Genre Language Link Location Subject Title].freeze

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

    # @param [MARC::Record] record
    # @return [Object]
    def publication_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def edition_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def series_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def production_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def distribution_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def manufacture_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def contained_in_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def cartographic_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def fingerprint_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def arrangement_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def place_of_publication_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def system_details_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def biography_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def summary_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def contents_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def participant_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def credits_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def notes_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def local_notes_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def offsite_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def finding_aid_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def provenance_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def chronology_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def related_collections_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def cited_in_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def publications_about_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def cite_as_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def contributor_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def related_work_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def contains_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def other_edition_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def constituent_unit_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def has_supplement_show(record); end

    # @param [MARC::Record] record
    # @return [Object]
    def access_restriction_show(record); end

    # Load language map from YAML and memoize in @mappings hash
    # @return [Hash]
    def language_map
      @mappings[:language] ||= load_map('language.yml')
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
