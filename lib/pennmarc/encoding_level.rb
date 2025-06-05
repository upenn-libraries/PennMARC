# frozen_string_literal: true

# MARC {https://www.oclc.org/bibformats/en/fixedfield/elvl.html encoding level values} and a means of ranking them.
# See the `EncodingRank` helper for usage.
module PennMARC
  module EncodingLevel
    # {https://www.loc.gov/marc/bibliographic/bdleader.html Official MARC codes}
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

    # {https://www.oclc.org/bibformats/en/fixedfield/elvl.html OCLC extension codes}. These are deprecated but still
    # found in our records.
    OCLC_FULL = 'I'
    OCLC_MINIMAL = 'K'
    OCLC_BATCH_LEGACY = 'L'
    OCLC_BATCH = 'M'
    OCLC_SOURCE_DELETED = 'J'

    RANK = {
      # top 4 (per nelsonrr), do not differentiate among "good" records
      FULL => 0,
      FULL_NOT_EXAMINED => 0,
      OCLC_FULL => 0,
      CORE => 0,
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
