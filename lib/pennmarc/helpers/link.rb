# frozen_string_literal: true

module PennMARC
  # Do Link-y stuff
  class Link < Helper
    class << self
      def full_text(record:); end

      def web(record:); end
    end
  end
end
