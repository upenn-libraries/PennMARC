# frozen_string_literal: true

module PennMARC
  # Do Date-y stuff
  class Date < Helper
    class << self
      def publication(record:); end

      # see recently_added_isort
      def added(record:); end

      def last_updated(record:); end
    end
  end
end
