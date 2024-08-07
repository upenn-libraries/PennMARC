# frozen_string_literal: true

module PennMARC
  # Shared tools and values for controlling handling of subject or genre headings
  class HeadingControl
    # These codes are expected to be found in sf2 of a subject/genre field when the indicator2 value is 7, indicating
    # "source specified". There are some sources whose headings we don't want to display.
    ALLOWED_SOURCE_CODES = %w[aat cct fast ftamc gmgpc gsafd homoit jlabsh lcgft lcsh lcstt lctgm
                              local/osu mesh ndlsh nli nlksh rbbin rbgenr rbmscv rbpap rbpri rbprov rbpub rbtyp].freeze

    REMOVE_TERM_REGEX = /#{Mappers.headings_to_remove&.join('|')}/i
    REPLACE_TERM_REGEX = /(#{Mappers.heading_overrides.keys.join('|')})/i

    class << self
      # Replace or remove any terms in provided values pursuant to the configuration in remove and override mappers.
      # Used to remove or replace offensive or otherwise undesirable subject headings.
      # @param values [Array]
      # @return [Array] values with terms removed/replaced
      def term_override(values)
        values.filter_map do |value|
          # Remove values if they contain a remove term
          next nil if value.match?(REMOVE_TERM_REGEX)

          # return early if theres no terms to replace
          next value if value.match(REPLACE_TERM_REGEX).nil?

          # lookup and perform replacement
          value.sub(::Regexp.last_match.to_s, Mappers.heading_overrides[::Regexp.last_match.to_s.downcase])
        end
      end
    end
  end
end
