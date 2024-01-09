# frozen_string_literal: true

module PennMARC
  # Methods for extracting holdings information when available
  class Holdings < Helper
    class << self
      # Hash of Holdings information
      # @param [MARC::Record] record
      # @return [Array<Hash>]
      def holdings(record)

        # TODO: combine elec and phys, or use distinct fields?
        # TODO: adapt to support API AVA/AVE fields
        
        # from discovery-app for electronic inventory
        elec = record.fields(EnrichedMarc::TAG_ELECTRONIC_INVENTORY)
                     .filter_map do |item|
          next unless item[EnrichedMarc::SUB_ELEC_COLLECTION_NAME].present?

          {
            portfolio_pid: item[EnrichedMarc::SUB_ELEC_PORTFOLIO_PID],
            url: item[EnrichedMarc::SUB_ELEC_ACCESS_URL],
            collection: item[EnrichedMarc::SUB_ELEC_COLLECTION_NAME],
            coverage: item[EnrichedMarc::SUB_ELEC_COVERAGE],
          }
        end

        # from discovery-app for physical inventory
        phys = record.fields(EnrichedMarc::TAG_HOLDING).map do |item|
          # Alma never populates subfield 'a' which is 'location'
          # it appears to store the location code in 'c'
          # and display name in 'b'
          {
            holding_id: item[EnrichedMarc::SUB_HOLDING_SEQUENCE_NUMBER],
            location: item[EnrichedMarc::SUB_HOLDING_SHELVING_LOCATION],
            classification_part: item[EnrichedMarc::SUB_HOLDING_CLASSIFICATION_PART],
            item_part: item[EnrichedMarc::SUB_HOLDING_ITEM_PART],
          }
        end
        elec + phys
      end

      # Count of brief holdings
      # @param [MARC::Record] record
      # @return [Integer]
      def brief_holding_count(record)

      end

      # Count of all holdings
      # @param [MARC::Record] record
      # @return [Integer]
      def all_holding_count(record)

      end
    end
  end
end
