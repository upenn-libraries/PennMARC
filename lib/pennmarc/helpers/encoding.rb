# frozen_string_literal: true

module PennMARC
  # Extract encoding level and provide an opinionated rating of the encoding level
  class Encoding < Helper
    class << self
      LEADER_POSITION = 17

      # Return a value corresponding to the {https://www.oclc.org/bibformats/en/fixedfield/elvl.html encoding level}
      # from the MARC leader. Lower numbers indicate a higher level of description. See {PennMARC::EncodingLevel} for
      # hash that determines the ranking. We still consider some "legacy" OCLC non-numeric codes here, though they are
      # no longer recommended for use by OCLC. If an invalid value is found, nil is returned.
      # @param [MARC::Record] record
      # @return [Integer, nil]
      def level_sort(record:)
        EncodingLevel::RANK[
          record.leader[LEADER_POSITION]
        ]
      end
    end
  end
end
