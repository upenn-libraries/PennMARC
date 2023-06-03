# frozen_string_literal: true

module PennMARC
  # Do Location-y stuff
  class Location
    # this will use a mapping from parsed XML...
    class << self
      def library(record:); end

      def specific_location(record:); end
    end
  end
end
