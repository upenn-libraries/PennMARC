# frozen_string_literal: true

require 'active_support'
require_relative 'title'

module PennMARC
  # Methods here should return values used in the indexer. The parsing logic should
  # NOT return values specific to any particular site/interface, but just general
  # MARC parsing logic for "title", "subject", "author", etc., as much as reasonably
  # possible. We'll see how it goes.
  #
  # Methods should, by default, take in a MARC::Record
  class Parser
    # @param [Array] mappings ???
    def initialize(mappings:)
      @mappings = mappings
    end

    # MMS ID from Alma, a Bib records primary identifier
    # @param [MARC::Record] record
    def mmsid(record)
      record.fields('001').first.value
    end

    # A single-valued title field
    # @param [MARC::Record] record
    def title_display(record)
      PennMARC::Title.for_display(record)
    end

    # All title values?
    # @param [MARC::Record] record
    def title_search(record)
      PennMARC::Title.for_search(record)
    end

    # Title, normalized for sorting. "Nonfiling" characters removed.
    # @param [MARC::Record] record
    def title_sort(record)
      PennMARC::Title.for_sort(record)
    end

    def title_standardized(record)
      PennMARC::Title.standardized(record)
    end

    def title_linked_alternate(record)
      PennMARC::Title.alternate(record)
    end
  end
end
