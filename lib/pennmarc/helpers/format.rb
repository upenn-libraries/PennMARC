# frozen_string_literal: true

require_relative '../enriched_marc'

module PennMARC
  # Do Format-y stuff
  class Format < Helper
    class << self
      # Get any Format values from {https://www.oclc.org/bibformats/en/3xx/300.html 300},
      # 254, 255, 310, 342, 352 or {https://www.oclc.org/bibformats/en/3xx/340.html 340} field. based on the source
      # field, different subfields are used.
      # @note ported from get_format_display
      # @param [MARC::Record] record
      # @return [Array<String>] format values for display
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

      # Get Format values for faceting. Format values are determined using complex logic for each possible format value.
      # The primary fields considered in determining Format facet values are:
      #
      # 1. "Type of Record" and "Bibliographic level" values extracted from the
      #    {https://www.loc.gov/marc/bibliographic/bdleader.html MARC leader}.
      # 2. Location name values and "Classification part" from Alma "enhanced" MARC holding/item information
      # 3. {https://www.loc.gov/marc/bibliographic/bd007.html 007} values, the first
      #    {https://www.loc.gov/marc/bibliographic/bd008.html 008} value, and the first character form all
      #    {https://www.loc.gov/marc/bibliographic/bd006.html 006} values (form)
      # 4. Medium values form {https://www.oclc.org/bibformats/en/2xx/245.html#subfieldh 245 ǂh}
      # 5. Media Type values from {https://www.oclc.org/bibformats/en/3xx/337.html#subfielda 337 ǂa}
      # Additional fields are considered for many of the formats. Much of this logic has been moved to private methods
      # to keep this method from becoming too unwieldy.
      # @todo is the conditional structure here still best practice? see the "Thesis on Microfilm" case in the specs
      #       for this helper method
      # @todo learn more about the "Curated format" values considered in 944 field
      # @note ported from get_format
      # @param [MARC::Record] record
      # @return [Array<String>] format values for faceting
      def facet(record)
        formats = []
        format_code = leader_format(record.leader)
        f007 = record.fields('007').map(&:value)
        f008 = record.fields('008').first&.value || ''
        f006firsts = record.fields('006').map { |field| field.value[0] }
        title_medium = subfield_values_for tag: '245', subfield: :h, record: record
        media_type = subfield_values_for tag: '337', subfield: :a, record: record

        # TODO: exactly what's going on here? is call_nums an accurate variable name?
        call_nums = record.fields(EnrichedMarc::TAG_HOLDING).map do |field|
          # h gives us the 'Classification part' which contains strings like 'Microfilm'
          join_subfields(field, &subfield_in?([EnrichedMarc::SUB_HOLDING_CLASSIFICATION_PART,
                                               EnrichedMarc::SUB_HOLDING_ITEM_PART]))
        end

        # get specific_location values from inventory info
        # locations = Location.location(record: record, display_value: 'specific_location') # TODO: from AM's MR
        locations = []

        if include_manuscripts?(locations)
          formats << 'Manuscript'
        elsif archives_but_not_cajs_or_nursing?(locations)
          formats << 'Archive'
        elsif micro_or_microform?(call_nums, locations, media_type, title_medium)
          formats << 'Microformat'
        else
          # any of these
          formats << 'Thesis/Dissertation' if thesis_or_dissertation?(format_code, record)
          formats << 'Conference/Event' if conference_event?(record)
          formats << 'Newspaper' if newspaper?(f008, format_code)
          formats << 'Government document' if government_document?(f008, record, format_code)

          # but only one of these
          formats << if website_database?(f006firsts, format_code)
                       'Website/Database'
                     elsif book?(format_code, title_medium, record)
                       'Book'
                     elsif musical_score?(format_code)
                       'Musical score'
                     elsif map_atlas?(format_code)
                       'Map/Atlas'
                     elsif graphical_media?(format_code)
                       graphical_media_type(f007)
                     elsif sound_recording?(format_code)
                       'Sound recording'
                     elsif image?(format_code)
                       'Image'
                     elsif datafile?(format_code)
                       'Datafile'
                     elsif journal_periodical?(format_code)
                       'Journal/Periodical'
                     elsif three_d_object?(format_code)
                       '3D object'
                     else
                       'Other'
                     end
        end
        formats.concat(curated_format(record))
      end

      # Show "Other Format" vales from {https://www.oclc.org/bibformats/en/7xx/776.html 776} and any 880 linkage.
      # @todo is 774 an error in the linked field in legacy? i changed to 776 here
      # @param [MARC::Record] record
      # @return [Array] other format values for display
      def other_show(record)
        other_formats = record.fields('776').filter_map do |field|
          value = join_subfields(field, &subfield_in?(%w[i a s t o]))
          next if value.blank?

          value
        end
        other_formats + linked_alternate(record, '776') do |sf|
          sf.code.in? %w[i a s t o]
        end
      end

      private

      # Get 'Curated' format - this must be a Penn-specific practice
      # @todo find out more about Penn's 944 usage before refactoring
      # @param [MARC::Record] record
      # @return [Array]
      def curated_format(record)
        record.fields('944').filter_map do |field|
          subfield_a = field.find { |sf| sf.code == 'a' }
          next if subfield_a.nil? || (subfield_a.value == subfield_a.value.to_i.to_s)

          subfield_a.value
        end.uniq
      end

      # @param [String] format_code
      # @return [Boolean]
      def image?(format_code)
        format_code.in?(%w[km kd])
      end

      # @param [String] format_code
      # @return [Boolean]
      def datafile?(format_code)
        format_code == 'mm'
      end

      # @param [String] format_code
      # @return [Boolean]
      def journal_periodical?(format_code)
        format_code.in?(%w[as gs])
      end

      # @param [String] format_code
      # @return [Boolean]
      def three_d_object?(format_code)
        format_code.start_with?('r')
      end

      # @param [String] format_code
      # @return [Boolean]
      def sound_recording?(format_code)
        format_code.in?(%w[im jm jc jd js])
      end

      # @param [String] format_code
      # @return [Boolean]
      def graphical_media?(format_code)
        format_code == 'gm'
      end

      # @param [String] format_code
      # @return [Boolean]
      def map_atlas?(format_code)
        format_code&.start_with?('e') || format_code == 'fm'
      end

      # @param [String] format_code
      # @return [Boolean]
      def musical_score?(format_code)
        format_code.in?(%w[ca cb cd cm cs dm])
      end

      # @param [String] format_code
      # @param [Array<String>] title_medium
      # @param [MARC::Record] record
      # @return [Boolean]
      def book?(format_code, title_medium, record)
        title_forms = subfield_values_for tag: '245', subfield: :k, record: record
        format_code.in?(%w[aa ac am tm]) &&
          title_forms.none? { |v| v =~ /kit/i } &&
          title_medium.none? { |v| v =~ /micro/i }
      end

      # @param [Array<String>] f006firsts
      # @param [String] format_code
      # @return [Boolean]
      def website_database?(f006firsts, format_code)
        format_code&.end_with?('i') ||
          (format_code == 'am' && f006firsts.include?('m') && f006firsts.include?('s'))
      end

      # @param [String] f008
      # @param [MARC::Record] record
      # @param [String] format_code
      # @return [Boolean]
      def government_document?(f008, record, format_code)
        # is a 260 entry present, and does it have a b that matches 'press'
        f260press = record.fields('260').any? do |field|
          field.select { |sf| sf.code == 'b' && sf.value =~ /press/i }.any?
        end
        %w[c d i j].exclude?(format_code[0]) && f008[28].in?(%w[f i o]) && !f260press
      end

      # @param [String] f008
      # @param [String] format_code
      # @return [Boolean]
      def newspaper?(f008, format_code)
        format_code == 'as' && (f008[21] == 'n' || f008[22] == 'e')
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def conference_event?(record)
        record.fields('111').any? || record.fields('711').any? # TODO: use field_present helper here and below?
      end

      # @param [MARC::Record] record
      # @param [String] format_code
      # @return [Boolean]
      def thesis_or_dissertation?(format_code, record)
        record.fields('502').any? && format_code == 'tm'
      end

      # @param [Array<String>] title_medium
      # @param [Array<String>] media_type
      # @param [Array<String>] locations
      # @param [Array<String>] call_nums
      # @return [Boolean]
      def micro_or_microform?(call_nums, locations, media_type, title_medium)
        locations.any? { |loc| loc =~ /micro/i } ||
          title_medium.any? { |val| val =~ /micro/i } ||
          call_nums.any? { |val| val =~ /micro/i } ||
          media_type.any? { |val| val =~ /microform/i }
      end

      # @param [Array<String>] locations
      # @return [Boolean]
      def archives_but_not_cajs_or_nursing?(locations)
        locations.any? { |loc| loc =~ /archives/i } &&
          locations.none? { |loc| loc =~ /cajs/i } &&
          locations.none? { |loc| loc =~ /nursing/i }
      end

      # @param [Array<String>] locations
      # @return [Boolean]
      def include_manuscripts?(locations)
        locations.any? { |loc| loc =~ /manuscripts/i }
      end

      # Consider {https://www.loc.gov/marc/bibliographic/bd007g.html 007} to determine graphical media format
      # @param [Array<String>] f007
      # @return [String (frozen)]
      def graphical_media_type(f007)
        if f007.any? { |v| v.start_with?('g') }
          'Projected graphic'
        else
          'Video'
        end
      end

      # @param [String] leader
      # @return [String]
      def leader_format(leader)
        leader[6..7] || '  '
      end
    end
  end
end
