# frozen_string_literal: true

# Constants for Alma's MARC enrichment, performed and included in the MARCXML either by the Publishing process or by
# API service
module PennMARC
  module Enriched
    # Enriched MARC fields added by configurable setting in the Publishing profile that generates the MARCXML
    # TODO: review if we can/should modify the subfields used in the pub profile to create parity with API subfields as
    #       that could simplify this mapping tremendously
    module Pub
      # Enrichment Tag Names
      PHYS_INVENTORY_TAG = 'hld'
      ELEC_INVENTORY_TAG = 'prt'
      ITEM_TAG = 'itm'
      RELATED_RECORD_TAGS = %w[REL rel].freeze

      # Subfields for HLD tags
      # Follow MARC 852 spec: https://www.loc.gov/marc/holdings/hd852.html, but names are translated into Alma parlance
      PHYS_LOCATION_NAME = 'b' # e.g., Libra
      PHYS_LOCATION_CODE = 'c' # e.g., stor
      HOLDING_CLASSIFICATION_PART = 'h' # "classification part" first part of call num e.g., KF6450
      HOLDING_ITEM_PART = 'i' # "item part?" second part of call num e.g., .C59 1989
      PHYS_PUBLIC_NOTE = 'z'
      PHYS_INTERNAL_NOTE = 'x'
      PHYS_HOLDING_ID = '8'

      # Subfields for ITM tags
      ITEM_CURRENT_LOCATION = 'g'
      ITEM_CALL_NUMBER_TYPE = 'h'
      ITEM_CALL_NUMBER = 'i'
      ITEM_DATE_CREATED = 'q'

      # Subfields for PRT tags
      ELEC_PORTFOLIO_ID = 'a'
      ELEC_SERVICE_URL = 'b'
      ELEC_COLLECTION_NAME = 'c'
      ELEC_INTERFACE_NAME = 'e'
      ELEC_PUBLIC_NOTE = 'f'
      ELEC_COVERAGE_STMT = 'g'

      # other values that could be added if we configured the Alma pub profile (and values are set on the record)
      # - Authentication note
      # - "static URL"
      # - Electronic material type
      # - Collection ID
      # - create/update/activation date
      # - license code
      # - portfolio coverage info
      #   - from year, until year (month, day volume issue)
      # - portfolio embargo info
      #   - years/months embargo'd

      # TODO: evaluate this in context of changed boundwiths processing
      # Franklin legacy note:
      #   a subfield code NOT used by the MARC 21 spec for 852 holdings records.
      #   we add this subfield during preprocessing to store boundwith record IDs.
      # BOUND_WITH_ID = 'y'
    end

    # MARC enrichment originating from Alma API
    # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/ Alma docs
    # We cannot modify these subfield settings
    module Api
      # Enrichment Tag Names
      PHYS_INVENTORY_TAG = 'AVA'
      ELEC_INVENTORY_TAG = 'AVE'

      # Physical Holding (AVA) subfields
      PHYS_CALL_NUMBER = 'd'
      PHYS_CALL_NUMBER_TYPE = 'k'
      PHYS_LIBRARY_CODE = 'b'
      PHYS_LIBRARY_NAME = 'q'
      PHYS_LOCATION_CODE = 'j'
      PHYS_LOCATION_NAME = 'c'
      PHYS_HOLDING_ID = '8'
      PHYS_AVAILABILITY = 'e'
      PHYS_TOTAL_ITEMS = 'f'
      PHYS_UNAVAILABLE_ITEMS = 'g'
      PHYS_SUMMARY_INFO = 'v'
      PHYS_PRIORITY = 'p'

      # Electronic Portfolio (AVE) subfields
      ELEC_LIBRARY_CODE = 'l'
      ELEC_COLLECTION_NAME = 'm'
      ELEC_PUBLIC_NOTE = 'n'
      ELEC_SERVICE_URL = 'u'
      ELEC_COVERAGE_STMT = 's'
      ELEC_INTERFACE_NAME = 't'
      ELEC_PORTFOLIO_ID = '8'
      ELEC_COLLECTION_ID = 'c'
      ELEC_ACTIVATION_STATUS = 'e'
    end
  end
end
