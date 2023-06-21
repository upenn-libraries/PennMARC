# frozen_string_literal: true

module PennMARC
  # Do Format-y stuff
  class Format < Helper
    class << self
      # @todo port get_format_display
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record); end

      # @todo port from get_format
      # @param [MARC::Record] record
      # @return [Array<String>]
      def facet(record); end

      # Show "Other Format" vales from {https://www.oclc.org/bibformats/en/7xx/776.html 776} and any 880 linkage.
      # @todo is 774 an error in the linked field in legacy? i changed to 776 here
      # @todo port get_other_format_display
      # @param [MARC::Record] record
      # @return [Array<String>]
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
