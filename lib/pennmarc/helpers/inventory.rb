# frozen_string_literal: true

module PennMARC
  # Methods for extracting holdings information ("inventory") when available
  class Inventory < Helper
    class << self
      # Hash of Physical holdings information
      # @param [MARC::Record] record
      # @return [Array, nil]
      def physical(record)
        if pub_enrichment_tags?(record)
          physical_entries(record, source: :pub)
        elsif api_enrichment_tags?(record)
          physical_entries(record, source: :api)
        end
      end

      # Hash of Electronic inventory information
      # @param [MARC::Record] record
      # @return [Array, nil]
      def electronic(record)
        if pub_enrichment_tags?(record)
          electronic_entries(record, source: :pub)
        elsif api_enrichment_tags?(record)
          electronic_entries(record, source: :api)
        end
      end

      # Count of all electronic portfolios
      # @param [MARC::Record] record
      # @return [Integer]
      def electronic_portfolio_count(record)
        record.tags.count { |tag| tag.in? %w[AVE PRT] }
      end

      # Count of all physical holdings
      # @param [MARC::Record] record
      # @return [Integer]
      def physical_holding_count(record)
        record.tags.count { |tag| tag.in? %w[AVA HLD] }
      end

      private

      # Compose hash of Physical inventory details
      # @note call num handling and priority and naming scheme for pub info keep this from being DRY'd up
      # @param [MARC::Record] record
      # @param [Symbol] source for enrichment
      # @return [Array<Hash>]
      def physical_entries(record, source:)
        if source == :api
          record.fields(Enriched::Api::PHYS_INVENTORY_TAG).map do |e|
            { holding_id: e[Enriched::Api::PHYS_HOLDING_ID],
              location_name: e[Enriched::Api::PHYS_LOCATION_NAME],
              location_code: e[Enriched::Api::PHYS_LOCATION_CODE],
              call_num: e[Enriched::Api::PHYS_CALL_NUMBER],
              priority: e[Enriched::Api::PHYS_PRIORITY] }
          end
        elsif source == :pub
          record.fields(Enriched::Pub::PHYS_INVENTORY_TAG).map do |e|
            { holding_id: e[Enriched::Pub::HOLDING_ID],
              location_name: e[Enriched::Pub::HOLDING_LOCATION_NAME],
              location_code: e[Enriched::Pub::HOLDING_LOCATION_CODE],
              call_num: "#{Enriched::Pub::HOLDING_CLASSIFICATION_PART}#{Enriched::Pub::HOLDING_ITEM_PART}",
              priority: '' } # TODO: can we publish this priority value? we get it from the API
          end
        end
      end

      # Compose hash of Electronic inventory details
      # @param [MARC::Record] record
      # @param [Symbol] source for enrichment
      # @return [Array<Hash>]
      def electronic_entries(record, source:)
        mapper = source == :api ? Enriched::Api : Enriched::Pub
        record.fields(mapper::ELEC_INVENTORY_TAG).map do |e|
          { portfolio_id: e[mapper::ELEC_PORTFOLIO_ID],
            url: e[mapper::ELEC_SERVICE_URL],
            collection_name: e[mapper::ELEC_COLLECTION_NAME],
            coverage: e[mapper::ELEC_COVERAGE_STMT],
            note: e[mapper::ELEC_PUBLIC_NOTE] }
        end
      end

      # Does the record include tags from Publishing inventory enrichment?
      # @todo move to Util?
      # @param [MARC::Record] record
      # @return [Boolean]
      def pub_enrichment_tags?(record)
        record.tags.intersect?(
          [Enriched::Pub::PHYS_INVENTORY_TAG, Enriched::Pub::ELEC_INVENTORY_TAG, Enriched::Pub::ITEM_TAG]
        ).any?
      end

      # Does the record include tags from API inventory enrichment?
      # @todo move to Util?
      # @param [MARC::Record] record
      # @return [Boolean]
      def api_enrichment_tags?(record)
        record.tags.intersect?(
          [Enriched::Api::PHYS_INVENTORY_TAG, Enriched::Api::ELEC_INVENTORY_TAG]
        ).any?
      end
    end
  end
end
