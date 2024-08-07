# frozen_string_literal: true

module PennMARC
  # Do Link-y stuff
  class Link < Helper
    class << self
      # @todo the legacy code here is a hot mess for a number of reasons, what do we need this field to do?
      # @note port the needed parts from get_offsite_display, don't return HTML
      # @param record [MARC::Record]
      # @return [Object]
      def offsite(record); end

      # Full text links from MARC 856 fields.
      # @param record [MARC::Record]
      # @return [Array] array of hashes
      def full_text_links(record)
        indicator2_options = %w[0 1]
        links_from_record(record, indicator2_options)
      end

      # Web text links from MARC 856 fields.
      # @param record [MARC::Record]
      # @return [Array] array of hashes
      def web_links(record)
        indicator2_options = ['2', ' ', '']
        links_from_record(record, indicator2_options)
      end

      private

      # Extract subfield 3 and z/y depending on the presence of either. Extract link url and assemble array
      # with text and link.
      # @param field [MARC::Field]
      # @return [Array]
      def link_text_and_url(field)
        subfield3 = subfield_values(field, 3)
        subfield_zy = field.find_all(&subfield_in?(%w[z y])).map(&:value)
        link_text = [subfield3, subfield_zy.first].compact.join(' ')
        link_url = subfield_values(field, 'u')&.first || ''
        [link_text, link_url.sub(' target=_blank', '')]
      end

      # Assemble array of link text, link URL values from 856 fields. Ensure indicator1 (access method)
      # is always 4 (HTTP) and indicator2 (relationship) can be specified by caller method.
      # @param record [MARC::Record]
      # @param indicator2_options [Array]
      # @return [Array]
      def links_from_record(record, indicator2_options)
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
