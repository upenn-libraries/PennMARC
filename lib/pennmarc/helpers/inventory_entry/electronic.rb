# frozen_string_literal: true

require_relative 'base'

module PennMARC
  module InventoryEntry
    # Represent a Electronic inventory entry - simple because the subfield specification is identical across
    # entries returned by the API and Alma Publishing enrichment
    class Electronic < Base
      # @return [Hash{Symbol->Unknown}]
      def to_h
        { portfolio_id: field[mapper::ELEC_PORTFOLIO_ID],
          url: field[mapper::ELEC_SERVICE_URL],
          collection_name: field[mapper::ELEC_COLLECTION_NAME],
          coverage: field[mapper::ELEC_COVERAGE_STMT],
          note: field[mapper::ELEC_PUBLIC_NOTE] }
      end
    end
  end
end
