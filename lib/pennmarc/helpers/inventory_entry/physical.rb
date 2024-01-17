# frozen_string_literal: true

require_relative 'base'

module PennMARC
  module InventoryEntry
    # Represent a Physical inventory entry
    class Physical < Base
      # Call number from inventory entry
      # @return [String (frozen)]
      def call_num
        if source == :pub
          "#{field[mapper::HOLDING_CLASSIFICATION_PART]}#{field[mapper::HOLDING_ITEM_PART]}"
        elsif source == :api
          field[mapper::PHYS_CALL_NUMBER]
        end
      end

      # Priority for inventory entry
      # @note we currently don't return priority in our publishing enrichment
      # @return [String, nil]
      def priority
        return nil if source == :pub

        field[mapper::PHYS_PRIORITY]
      end

      # @return [Hash{Symbol->Unknown}]
      def to_h
        { holding_id: field[mapper::PHYS_HOLDING_ID],
          location_name: field[mapper::PHYS_LOCATION_NAME],
          location_code: field[mapper::PHYS_LOCATION_CODE],
          call_num: call_num,
          priority: priority }
      end
    end
  end
end
