# frozen_string_literal: true

require_relative 'inventory_entry/electronic'
require_relative 'inventory_entry/physical'

module PennMARC
  # Methods for extracting holdings information ("inventory") when available
  class Inventory < Helper
    PHYSICAL_INVENTORY_TAGS = [
      Enriched::Pub::PHYS_INVENTORY_TAG,
      Enriched::Api::PHYS_INVENTORY_TAG
    ].freeze

    ELECTRONIC_INVENTORY_TAGS = [
      Enriched::Pub::ELEC_INVENTORY_TAG,
      Enriched::Api::ELEC_INVENTORY_TAG
    ].freeze

    class << self
      # Hash of Physical holdings information
      # @param record [MARC::Record]
      # @return [Array, nil]
      def physical(record)
        source = enrichment_source(record)
        return unless source

        record.fields(PHYSICAL_INVENTORY_TAGS).map do |entry|
          InventoryEntry::Physical.new(entry, source).to_h
        end
      end

      # Hash of Electronic inventory information
      # @param record [MARC::Record]
      # @return [Array, nil]
      def electronic(record)
        source = enrichment_source(record)
        return unless source

        record.fields(ELECTRONIC_INVENTORY_TAGS).map do |entry|
          InventoryEntry::Electronic.new(entry, source).to_h
        end
      end

      # Count of all electronic portfolios
      # @param record [MARC::Record]
      # @return [Integer]
      def electronic_portfolio_count(record)
        record.count { |field| field.tag.in? %w[AVE prt] }
      end

      # Count of all physical holdings
      # @param record [MARC::Record]
      # @return [Integer]
      def physical_holding_count(record)
        record.count { |field| field.tag.in? %w[AVA hld] }
      end

      private

      # Determine the source of the MARC inventory enrichment
      # @param record [MARC::Record]
      # @return [Symbol, nil]
      def enrichment_source(record)
        if pub_enrichment_tags?(record)
          :pub
        elsif api_enrichment_tags?(record)
          :api
        end
      end

      # Does the record include tags from Publishing inventory enrichment?
      # @todo move to Util?
      # @param record [MARC::Record]
      # @return [Boolean]
      def pub_enrichment_tags?(record)
        record.tags.intersect?(
          [Enriched::Pub::PHYS_INVENTORY_TAG, Enriched::Pub::ELEC_INVENTORY_TAG, Enriched::Pub::ITEM_TAG]
        )
      end

      # Does the record include tags from API inventory enrichment?
      # @todo move to Util?
      # @param record [MARC::Record]
      # @return [Boolean]
      def api_enrichment_tags?(record)
        record.tags.intersect?(
          [Enriched::Api::PHYS_INVENTORY_TAG, Enriched::Api::ELEC_INVENTORY_TAG]
        )
      end
    end
  end
end
