# frozen_string_literal: true

module PennMARC
  # reusable static mappers
  class Mappers
    class << self
      # @return [Hash]
      def language
        @language ||= load_map('language.yml')
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
