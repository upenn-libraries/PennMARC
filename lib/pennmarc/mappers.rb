# frozen_string_literal: true

module PennMARC
  # reusable static mappers
  class Mappers
    class << self
      # @return [Hash, nil]
      def heading_overrides
        @heading_overrides ||= load_map('headings_override.yml', symbolize_names: false)
      end

      # @return [Hash, nil]
      def headings_to_remove
        @headings_to_remove ||= load_map('headings_remove.yml', symbolize_names: false)
      end

      # @return [Hash, nil]
      def iso_639_2_language
        @iso_639_2_language ||= load_map('iso639-2-languages.yml')
      end

      # @return [Hash, nil]
      def iso_639_3_language
        @iso_639_3_language ||= load_map('iso639-3-languages.yml')
      end

      # @return [Hash, nil]
      def location
        @location ||= load_map('locations.yml')
      end

      # @return [Hash, nil]
      def location_overrides
        @location_overrides ||= load_map('location_overrides.yml')
      end

      # @return [Hash, nil]
      def relator
        @relator ||= load_map('relator.yml')
      end

      # @return [Hash, nil]
      def loc_classification
        @loc_classification ||= load_map('loc_classification.yml')
      end

      # @return [Hash, nil]
      def dewey_classification
        @dewey_classification ||= load_map('dewey_classification.yml')
      end

      # @param filename [String] name of mapping file in config directory, with file extension
      # @param symbolize_names [Boolean] whether to symbolize keys in returned hash
      # @return [Hash, nil] mapping as hash
      def load_map(filename, symbolize_names: true)
        YAML.safe_load(File.read(File.join(File.expand_path(__dir__), 'mappings', filename)),
                       symbolize_names: symbolize_names)
      end
    end
  end
end
