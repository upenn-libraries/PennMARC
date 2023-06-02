# frozen_string_literal: true

require 'active_support/all'
require_relative 'helper'
# require_relative 'author_creator'
# require_relative 'database'
# require_relative 'date'
# require_relative 'format'
# require_relative 'genre'
# require_relative 'identifier'
# require_relative 'link'
# require_relative 'location'
# require_relative 'subject'
require_relative 'title'

module PennMARC
  DEFINED_HELPERS = %w[AuthorCreator Database Date Format Genre Link Location Subject Title].freeze

  # Methods here should return values used in the indexer. The parsing logic should
  # NOT return values specific to any particular site/interface, but just general
  # MARC parsing logic for "title", "subject", "author", etc., as much as reasonably
  # possible. We'll see how it goes.
  #
  # Methods should, by default, take in a MARC::Record
  class Parser
    # @param [Array] mappings ???
    def initialize(mappings:, helpers: DEFINED_HELPERS)
      @mappings = mappings # LoC & Dewey translations, Language Code, Location details - may be passed to methods
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
  end
end
