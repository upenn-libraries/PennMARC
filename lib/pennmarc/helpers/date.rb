# frozen_string_literal: true

module PennMARC
  # Parser methods for extracting date info as DateTime objects
  class Date < Helper
    class << self
      # Retrieve publication date (Date 1) from {https://www.loc.gov/marc/bibliographic/bd008a.html 008 field}.
      # Publication date is a four-digit year found in position 7-10 and may contain 'u' characters to represent partially known dates. We
      # replace any occurrences of 'u' with '0' before converting to DateTime object.
      # @param [MARC::Record] record
      # @return [DateTime, nil] The publication date, or nil if date found in record is invalid
      def publication(record)
        record.fields('008').filter_map do |field|
          four_digit_year = sanitize_partially_known_date(field.value[7, 4], '0')

          next unless four_digit_year.present?

          DateTime.new(four_digit_year.to_i)
        end.first
      end

      # Retrieve date added (subfield 'q') from enriched marc 'itm' field.
      # {PennMARC::EnrichedMarc} maps enriched marc fields and subfields created during Alma publishing.
      # @param [MARC::Record] record
      # @return [DateTime, nil] The date added, or nil if date found in record is invalid
      def added(record)
        record.fields(EnrichedMarc::TAG_ITEM).flat_map do |field|
          field.filter_map do |subfield|
            # skip unless field has date created subfield
            next unless subfield_defined?(field, EnrichedMarc::SUB_ITEM_DATE_CREATED)

            # On 2022-05-02, this field value (as exported in enriched publishing
            # job from Alma) began truncating time to day-level granularity. We have
            # no guarantee that this won't switch back in the future, so for the
            # foreseeable future we should support both formats.

            format = subfield.value.size == 10 ? '%Y-%m-%d' : '%Y-%m-%d %H:%M:%S'

            DateTime.strptime(subfield.value, format)

          rescue StandardError => e
            puts "Error parsing date in date added subfield: #{subfield.value} - #{e}"
            nil
          end
        end.max
      end

      # Retrieve date last updated from {https://www.loc.gov/marc/bibliographic/bd005.html 005 field}.
      # @param [MARC::Record] record
      # @return [DateTime, nil] The date last updated, or nil if date found in record is invalid
      def last_updated(record)
        record.fields('005').filter_map do |field|
          date_time_string = field.value

          next if date_time_string.blank?

          next if date_time_string.start_with?('0000')

          next if date_time_string.to_i.zero?

          DateTime.new(date_time_string.to_i)

        rescue StandardError => e
          puts "Error parsing last updated date: #{date_time_string} - #{e}"
          nil
        end.first
      end

      private

      # Sanitizes a partially known date string by replacing any 'u' occurrences with a specified replacement value.
      # @param [String] date The date string in '%Y' format, potentially containing 'u' characters.
      # @param [String] replacement The value with which to replace 'u' occurrences in the date string.
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
