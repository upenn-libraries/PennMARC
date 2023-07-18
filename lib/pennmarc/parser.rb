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

    # @todo does this fit in an existing helper?
    # @param [MARC::Record] record
    # @return [Object]
    def cartographic_show(record)
      record.fields(%w{255 342}).map do |field|
        join_subfields(field, &subfield_not_6_or_8)
      end
    end

    # @todo move to Identifier helper
    # @param [MARC::Record] record
    # @return [Object]
    def fingerprint_show(record)
      record.fields('026').map do |field|
        join_subfields(field, &subfield_not_in(%w{2 5 6 8}))
      end
    end

    # @todo does this fit in an existing helper?
    # @param [MARC::Record] record
    # @return [Object]
    def arrangement_show(record)
      get_datafield_and_880(record, '351')
    end

    # @param [MARC::Record] record
    # @return [Object]
    def system_details_show(record)
      acc = []
      acc += record.fields('538').map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a i u}))
      end
      acc += record.fields('344').map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b c d e f g h}))
      end
      acc += record.fields(%w{345 346}).map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b}))
      end
      acc += record.fields('347').map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b c d e f}))
      end
      acc += record.fields('880')
                .select { |f| has_subfield6_value(f, /^538/) }
                .map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a i u}))
      end
      acc += record.fields('880')
                .select { |f| has_subfield6_value(f, /^344/) }
                .map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b c d e f g h}))
      end
      acc += record.fields('880')
                .select { |f| has_subfield6_value(f, /^(345|346)/) }
                .map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b}))
      end
      acc += record.fields('880')
                .select { |f| has_subfield6_value(f, /^347/) }
                .map do |field|
        get_sub3_and_other_subs(field, &subfield_in(%w{a b c d e f}))
      end
      acc
    end

    # @todo the legacy code here is a hot mess for a number of reasons, what do we need this field to do?
    # @note port the needed parts from get_offsite_display, don't return HTML
    # @param [MARC::Record] record
    # @return [Object]
    def offsite_show(record); end

    # @todo move this to Creator helper
    # @param [MARC::Record] record
    # @return [Object]
    def contributor_show(record)
      acc = []
      acc += record.fields(%w{700 710})
                   .select { |f| ['', ' ', '0'].member?(f.indicator2) }
                   .select { |f| f.none? { |sf| sf.code == 'i' } }
                   .map do |field|
        contributor = join_subfields(field, &subfield_in(%w{a b c d j q}))
        contributor_append = field.select(&subfield_in(%w{e u 3 4})).map do |sf|
          if sf.code == '4'
            ", #{relator_codes[sf.value]}"
          else
            " #{sf.value}"
          end
        end.join
        { value: contributor, value_append: contributor_append, link_type: 'author_creator_xfacet2' }
      end
      acc += record.fields('880')
                   .select { |f| has_subfield6_value(f, /^(700|710)/) && (f.none? { |sf| sf.code == 'i' }) }
                   .map do |field|
        contributor = join_subfields(field, &subfield_in(%w{a b c d j q}))
        contributor_append = join_subfields(field, &subfield_in(%w{e u 3}))
        { value: contributor, value_append: contributor_append, link_type: 'author_creator_xfacet2' }
      end
      acc
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
