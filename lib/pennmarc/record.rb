# frozen_string_literal: true

require 'active_support'
require_relative 'title/title'

module PennMARC
  # Methods here should return values used in the indexer. The parsing logic should
  # NOT return values specific to any particular site/interface, but just general
  # MARC parsing logic for "title", "subject", "author", etc., as much as reasonably
  # possible. We'll see how it goes.
  #
  # Methods should, by default, take in a MARC::Record
  class Record
    def initialize(mappings:)
      @mappings = mappings
    end

    def test(record)
      record.fields('001').first.value
    end

    # A single-valued title field
    def title_display(record)
      PennMARC::Title.for_display(record)
    end

    def title_search; end

    def title_sort; end
  end
end
