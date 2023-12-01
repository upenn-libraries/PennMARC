# frozen_string_literal: true

module PennMARC
  # Do Link-y stuff
  class Link < Helper
    class << self
      # @todo the legacy code here is a hot mess for a number of reasons, what do we need this field to do?
      # @note port the needed parts from get_offsite_display, don't return HTML
      # @param [MARC::Record] record
      # @return [Object]
      def offsite(record); end

      # Full text links from MARC 856 fields.
      # @param [MARC::Record] record
      # @return [Array] array of hashes
      def full_text(record:)
        indicator2_options = %w[0 1]
        get_links_from_record(record, indicator2_options)
      end

      # Web text links from MARC 856 fields.
      # @param [MARC::Record] record
      # @return [Array] array of hashes
      def web(record:)
        indicator2_options = ['2', ' ', '']
        get_links_from_record(record, indicator2_options)
      end

      private

      # Extract subfield 3 and z/y depending on the presence of either. Extract link url and assemble array
      # with text and link.
      # @param [MARC::Field] field
      # @return [Array]
      def link_text_and_url(field)
        subfield3 = join_subfields(field, &subfield_in?(%w[3]))
        subfield_zy = field.find_all(&subfield_in?(%w[z y])).map(&:value)
        link_text = [subfield3, subfield_zy.first].compact.join(' ')
        link_url = field.find_all(&subfield_in?(%w[u])).map(&:value).first || ''
        [link_text, link_url.sub(' target=_blank', '')]
      end

      # @param [MARC::Record] record
      # @param [Array] indicator2_options
      # @return [Array]
      def get_links_from_record(record, indicator2_options)
        record.fields('856').filter_map do |field|
          next unless field.indicator1 == '4' && indicator2_options.include?(field.indicator2)

          link_text, link_url = link_text_and_url(field)
          {
            link_text: link_text.present? ? link_text : link_url,
            link_url: link_url
          }
        end
      end
    end
  end
end
