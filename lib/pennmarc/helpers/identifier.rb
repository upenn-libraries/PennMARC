# frozen_string_literal: true

module PennMARC
  # Do Identifier-y stuff
  class Identifier < Helper
    class << self
      def mmsid(record)
        record.fields('001').first.value
      end

      def isbn(record); end

      def issn(record); end
    end
  end
end
