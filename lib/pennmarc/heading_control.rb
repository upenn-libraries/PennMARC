# frozen_string_literal: true

require 'multi_string_replace'

module PennMARC
  # Shared tools and values for controlling handling of subject or genre headings
  class HeadingControl
    # These codes are expected to be found in sf2 of a subject/genre field when the indicator2 value is 7, indicating
    # "source specified". There are some sources whose headings we don't want to display.
    ALLOWED_SOURCE_CODES = %w[aat cct fast ftamc gmgpc gsafd homoit jlabsh lcgft lcsh lcstt lctgm
                              local/osu mesh ndlsh nli nlksh rbbin rbgenr rbmscv rbpap rbpri rbprov rbpub rbtyp].freeze

    class << self
      # Replace or remove any terms in provided values pursuant to the configuration in remove and override mappers.
      # Used to remove or replace offensive or otherwise undesirable subject headings.
      # @param values [Array]
      # @return [Array] values with terms removed/replaced
      def term_override(values)
        values.filter_map do |value|
          # Remove values if they contain a remove term
          next nil if value.match?(/#{Mappers.headings_to_remove&.join('|')}/i)

          # Replace values using multi_string_replace gem
          MultiStringReplace.replace value, Mappers.heading_overrides
        end
      end
    end
  end
end
