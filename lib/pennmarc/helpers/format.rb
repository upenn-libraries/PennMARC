# frozen_string_literal: true

module PennMARC
  # Handle parsing out "Format" and "Other Format" values. Special care goes into controlling the format values for
  # faceting.
  class Format < Helper
    class << self
      # These constants represent the set of desired Format values for faceting.
      ARCHIVE = 'Archive'
      BOOK = 'Book'
      CONFERENCE_EVENT = 'Conference/Event'
      DATAFILE = 'Datafile'
      GOVDOC = 'Government document'
      IMAGE = 'Image'
      JOURNAL_PERIODICAL = 'Journal/Periodical'
      MANUSCRIPT = 'Manuscript'
      MAP_ATLAS = 'Map/Atlas'
      MICROFORMAT = 'Microformat'
      MUSICAL_SCORE = 'Musical score'
      NEWSPAPER = 'Newspaper'
      OTHER = 'Other'
      PROJECTED_GRAPHIC = 'Projected graphic'
      SOUND_RECORDING = 'Sound recording'
      THESIS_DISSERTATION = 'Thesis/Dissertation'
      THREE_D_OBJECT = '3D object'
      VIDEO = 'Video'
      WEBSITE_DATABASE = 'Website/Database'

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
      # 4. Medium values from {https://www.oclc.org/bibformats/en/2xx/245.html#subfieldh 245 ǂh}
      # 5. Media Type values from {https://www.oclc.org/bibformats/en/3xx/337.html#subfielda 337 ǂa}
      # Additional fields are considered for many of the formats. Much of this logic has been moved to private methods
      # to keep this method from becoming too unwieldy.
      # @todo is the conditional structure here still best practice? see the "Thesis on Microfilm" case in the specs
      #       for this helper method
      # @note ported from get_format
      # @param [MARC::Record] record
      # @param [Hash] location_map
      # @return [Array<String>] format values for faceting

      def facet(record, location_map)
        formats = []
        format_code = leader_format(record.leader)
        f007 = record.fields('007').map(&:value)
        f008 = record.fields('008').first&.value || ''
        f006_forms = record.fields('006').map { |field| field.value[0] }
        title_medium = subfield_values_for tag: '245', subfield: :h, record: record
        media_type = subfield_values_for tag: '337', subfield: :a, record: record

        # Get Call Number for holdings - ǂh gives us the 'Classification part' which can contain strings like
        # 'Microfilm'
        call_nums = record.fields(EnrichedMarc::TAG_HOLDING).map do |field|
          join_subfields(field, &subfield_in?([EnrichedMarc::SUB_HOLDING_CLASSIFICATION_PART,
                                               EnrichedMarc::SUB_HOLDING_ITEM_PART]))
        end

        # get all specific_location values from inventory info
        locations = Location.location record: record, location_map: location_map, display_value: :specific_location

        if include_manuscripts?(locations)
          formats << MANUSCRIPT
        elsif archives_but_not_cajs_or_nursing?(locations)
          formats << ARCHIVE
        elsif micro_or_microform?(call_nums, locations, media_type, title_medium)
          formats << MICROFORMAT
        else
          # any of these
          formats << THESIS_DISSERTATION if thesis_or_dissertation?(format_code, record)
          formats << CONFERENCE_EVENT if conference_event?(record)
          formats << NEWSPAPER if newspaper?(f008, format_code)
          formats << GOVDOC if government_document?(f008, record, format_code)

          # but only one of these
          formats << if website_database?(f006_forms, format_code)
                       WEBSITE_DATABASE
                     elsif book?(format_code, title_medium, record)
                       BOOK
                     elsif musical_score?(format_code)
                       MUSICAL_SCORE
                     elsif map_atlas?(format_code)
                       MAP_ATLAS
                     elsif graphical_media?(format_code)
                       graphical_media_type(f007)
                     elsif sound_recording?(format_code)
                       SOUND_RECORDING
                     elsif image?(format_code)
                       IMAGE
                     elsif datafile?(format_code)
                       DATAFILE
                     elsif journal_periodical?(format_code)
                       JOURNAL_PERIODICAL
                     elsif three_d_object?(format_code)
                       THREE_D_OBJECT
                     else
                       OTHER
                     end
        end
        formats.concat(curated_format(record))
      end

      # Show "Other Format" values from {https://www.oclc.org/bibformats/en/7xx/776.html 776} and any 880 linkage.
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

      # Get 'Curated' format from.
      # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Alma local field
      # 944} ǂa, as long as it is not a numerical value.
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

      # @param [Array<String>] f006_forms
      # @param [String] format_code
      # @return [Boolean]
      def website_database?(f006_forms, format_code)
        format_code&.end_with?('i') ||
          (format_code == 'am' && f006_forms.include?('m') && f006_forms.include?('s'))
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

      # @todo "cajs" has no match in our location map, so it is not doing anything. Does this intend to catch cjsambx
      #       "Library at the Katz Center - Archives"?
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
          PROJECTED_GRAPHIC
        else
          VIDEO
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
