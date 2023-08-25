# frozen_string_literal: true

module PennMARC
  # reusable static mappers
  class Mappers
    class << self
      # @return [Hash]
      def iso_639_2_language
        @iso_639_2_language ||= load_map('iso639-2-languages.yml')
      end

      def iso_639_3_language
        @iso_639_3_language ||= load_map('iso639-3-languages.yml')
      end

      # @return [Hash]
      def location
        @location ||= load_map('locations.yml')
      end

      # @return [Hash]
      def relator
        @relator ||= load_map('relator.yml')
      end

      # @param [String] filename of mapping file in config directory, with file extension
      # @return [Hash] mapping as hash
      def load_map(filename)
        puts { "Loading #{filename}" }
        YAML.safe_load(File.read(File.join(File.expand_path(__dir__), 'mappings', filename)),
                       symbolize_names: true)
      end
    end
  end
end
