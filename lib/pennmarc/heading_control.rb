# frozen_string_literal: true

module PennMARC
  # Shared values for controlling inclusion of subject or genre headings
  module HeadingControl
    # These codes are expected to be found in sf2 when the indicator2 value is 7, indicating "source specified". There
    # are some sources whose headings we don't want to display.
    ALLOWED_SOURCE_CODES = %w[aat cct fast ftamc gmgpc gsafd homoit jlabsh lcgft lcsh lcstt lctgm
                              local/osu mesh ndlsh nli nlksh rbbin rbgenr rbmscv rbpap rbpri rbprov rbpub rbtyp].freeze
  end
end
