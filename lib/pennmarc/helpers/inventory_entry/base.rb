# frozen_string_literal: true

module PennMARC
  module InventoryEntry
    # Base class for InventoryEntry classes, defines required interface
    class Base
      attr_reader :source, :field, :mapper

      # @param [MARC::DataField] inventory_field
      # @param [Symbol] source
      def initialize(inventory_field, source)
        @source = source
        @field = inventory_field
        @mapper = @source == :api ? Enriched::Api : Enriched::Pub
      end

      # @return [Hash]
      def to_h
        raise NotImplementedError
      end
    end
  end
end
