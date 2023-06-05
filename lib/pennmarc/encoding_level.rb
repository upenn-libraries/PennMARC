# frozen_string_literal: true

# MARC encoding level
# See: https://www.oclc.org/bibformats/en/fixedfield/elvl.html
# Not sure how this is used
module PennMARC
  module EncodingLevel
    # Official MARC codes (https://www.loc.gov/marc/bibliographic/bdleader.html)
    FULL = ' '
    FULL_NOT_EXAMINED = '1'
    UNFULL_NOT_EXAMINED = '2'
    ABBREVIATED = '3'
    CORE = '4'
    PRELIMINARY = '5'
    MINIMAL = '7'
    PREPUBLICATION = '8'
    UNKNOWN = 'u'
    NOT_APPLICABLE = 'z'

    # OCLC extension codes (https://www.oclc.org/bibformats/en/fixedfield/elvl.html)
    OCLC_FULL = 'I'
    OCLC_MINIMAL = 'K'
    OCLC_BATCH_LEGACY = 'L'
    OCLC_BATCH = 'M'
    OCLC_SOURCE_DELETED = 'J'

    RANK = {
      # top 4 (per nelsonrr), do not differentiate among "good" records
      FULL => 0,
      FULL_NOT_EXAMINED => 0, # 1
      OCLC_FULL => 0, # 2
      CORE => 0, # 3
      UNFULL_NOT_EXAMINED => 4,
      ABBREVIATED => 5,
      PRELIMINARY => 6,
      MINIMAL => 7,
      OCLC_MINIMAL => 8,
      OCLC_BATCH => 9,
      OCLC_BATCH_LEGACY => 10,
      OCLC_SOURCE_DELETED => 11
    }.freeze
  end
end
