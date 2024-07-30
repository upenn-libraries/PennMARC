# frozen_string_literal: true

module PennMARC
  # Parser methods for extracting date info as DateTime objects
  class Date < Helper
    class << self
      # Retrieve publication date (Date 1) from {https://www.loc.gov/marc/bibliographic/bd008a.html 008 field}.
      # Publication date is a four-digit year found in position 7-10 and may contain 'u' characters to represent
      # partially known dates. We replace any occurrences of 'u' with '0' before converting to DateTime object.
      # @param record [MARC::Record]
      # @return [Time, nil] The publication date, or nil if date found in record is invalid
      def publication(record)
        record.fields('008').filter_map { |field|
          four_digit_year = sanitize_partially_known_date(field.value[7, 4], '0')

          next if four_digit_year.blank?

          Time.new(four_digit_year.to_i)
        }.first
      end

      # Retrieve date added (subfield 'q') from enriched marc 'itm' field.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing. The enriched
      # metadata provided by the Alma API does not include the date created value, so we can't work with that here.
      # @param record [MARC::Record]
      # @return [Time, nil] The date added, or nil if date found in record is invalid
      def added(record)
        record.fields(Enriched::Pub::ITEM_TAG).flat_map { |field|
          subfield_values(field, Enriched::Pub::ITEM_DATE_CREATED).filter_map do |date_added|
            # On 2022-05-02, this field value (as exported in enriched publishing
            # job from Alma) began truncating time to day-level granularity. We have
            # no guarantee that this won't switch back in the future, so for the
            # foreseeable future we should support both formats.

            format = date_added.size == 10 ? '%Y-%m-%d' : '%Y-%m-%d %H:%M:%S'

            Time.strptime(date_added, format)
          rescue StandardError => e
            puts 'Error parsing date in date added subfield. ' \
                 "mmsid: #{Identifier.mmsid(record)}, value: #{date_added}, error: #{e}"
            nil
          end
        }.max
      end

      # Retrieve date last updated from {https://www.loc.gov/marc/bibliographic/bd005.html 005 field}.
      # Date last updated is a sixteen character String recorded in
      # {https://www.iso.org/iso-8601-date-and-time-format.html ISO 8601} format.
      # @param record [MARC::Record]
      # @return [Time, nil] The date last updated, or nil if date found in record is invalid
      def last_updated(record)
        record.fields('005').filter_map { |field|
          begin
            date_time_string = field.value

            next if date_time_string.blank?

            next if date_time_string.start_with?('0000')

            Time.strptime(date_time_string, '%Y%m%d%H%M%S.%N')
          rescue StandardError => e
            puts 'Error parsing last updated date. ' \
                 "mmsid: #{Identifier.mmsid(record)}, value: #{date_time_string}, error: #{e}"
            nil
          end
        }.first
      end

      private

      # Sanitizes a partially known date string by replacing any 'u' occurrences with a specified replacement value.
      # @param date [String] The date string in '%Y' format, potentially containing 'u' characters.
      # @param replacement [String] The value with which to replace 'u' occurrences in the date string.
      # @return [String, nil] The sanitized date string with 'u' characters replaced by the replacement value,
      #   or nil if the date string does not match the expected format.
      def sanitize_partially_known_date(date, replacement)
        # early return unless date begins with zero or more digits followed by zero or more occurrences of 'u'
        return unless /^[0-9]*u*$/.match?(date)

        # replace 'u' occurrences with the specified replacement value
        date.gsub(/u/, replacement)
      end
    end
  end
end
