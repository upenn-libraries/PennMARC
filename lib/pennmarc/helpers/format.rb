# frozen_string_literal: true

module PennMARC
  # Do Format-y stuff
  class Format < Helper
    class << self
      # Get any Format values from {https://www.oclc.org/bibformats/en/3xx/300.html 300},
      # 254, 255, 310, 342, 352 or {https://www.oclc.org/bibformats/en/3xx/340.html 340} field. based on the source
      # field, different subfields are used.
      # @note ported from get_format_display
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record)
        results = record.fields('300').map { |f| join_subfields(f, &subfield_not_in?(%w[3 6 8])) }
        results += record.fields(%w[254 255 310 342 352 362]).map do |f|
          join_subfields(f, &subfield_not_in?(%w[6 8]))
        end
        results += record.fields('340').map { |f| join_subfields(f, &subfield_not_in?(%w[0 2 6 8])) }
        results += record.fields('880').map do |f|
          subfield_to_ignore = if subfield_value?(f, 6, /^300/)
                                 %w[3 6 8]
                               elsif subfield_value?(f, 6, /^(254|255|310|342|352|362)/)
                                 %w[6 8]
                               elsif subfield_value?(f, 6, /^340/)
                                 %w[0 2 6 8]
                               end
          join_subfields(f, &subfield_not_in?(subfield_to_ignore))
        end
        results.compact_blank
      end

      # @todo port from get_format
      # @param [MARC::Record] record
      # @return [Array<String>]
      def facet(record); end

      # Show "Other Format" vales from {https://www.oclc.org/bibformats/en/7xx/776.html 776} and any 880 linkage.
      # @todo is 774 an error in the linked field in legacy? i changed to 776 here
      # @todo port get_other_format_display
      # @param [MARC::Record] record
      # @return [Array]
      def other_show(record)
        acc = record.fields('776').filter_map do |field|
          value = join_subfields(field, &subfield_in?(%w[i a s t o]))
          next if value.blank?

          value
        end
        acc + linked_alternate(record, '776') do |sf|
          sf.code.in? %w[i a s t o]
        end
      end
    end
  end
end
