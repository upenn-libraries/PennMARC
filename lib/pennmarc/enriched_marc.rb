# frozen_string_literal: true

# Constants for Alma's MARC enrichment
# MARC enrichment is performed during the Alma Publishing process
module PennMARC
  module EnrichedMarc
    # terminology follows the Publishing Profile screen
    TAG_HOLDING = 'hld'
    TAG_ITEM = 'itm'
    TAG_ELECTRONIC_INVENTORY = 'prt'
    TAG_DIGITAL_INVENTORY = 'dig'

    # these are 852 subfield codes; terminology comes from MARC spec
    SUB_HOLDING_SHELVING_LOCATION = 'c'
    SUB_HOLDING_SEQUENCE_NUMBER = '8'
    SUB_HOLDING_CLASSIFICATION_PART = 'h'
    SUB_HOLDING_ITEM_PART = 'i'

    SUB_ITEM_CURRENT_LOCATION = 'g'
    SUB_ITEM_CALL_NUMBER_TYPE = 'h'
    SUB_ITEM_CALL_NUMBER = 'i'
    SUB_ITEM_DATE_CREATED = 'q'

    SUB_ELEC_PORTFOLIO_PID = 'a'
    SUB_ELEC_ACCESS_URL = 'b'
    SUB_ELEC_COLLECTION_NAME = 'c'
    SUB_ELEC_COVERAGE = 'g'

    # TODO: evaluate this in context of changed boundwiths processing
    # a subfield code NOT used by the MARC 21 spec for 852 holdings records.
    # we add this subfield during preprocessing to store boundwith record IDs.
    SUB_BOUND_WITH_ID = 'y'
  end
end