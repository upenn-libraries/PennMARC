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

      # Get Format values for faceting.
      # @todo not sure how this might be broken down, wrap complex conditional expressions in methods?
      # @note ported from get_format
      # @param [MARC::Record] record
      # @return [Array<String>]
      def facet(record)
        acc = []

        format_code = leader_format(record.leader)

        # get 007 and 008 values
        f007 = record.fields('007').map(&:value)
        f008 = record.fields('008').first&.value || ''

        # is a 260 entry present, and does it have a b that matches 'press'
        f260press = record.fields('260').any? do |field|
          field.select { |sf| sf.code == 'b' && sf.value =~ /press/i }.any?
        end

        # first letter of every 006
        f006firsts = record.fields('006').map do |field|
          field.value[0]
        end

        # get subfield values from 245 and 337
        # TODO: create subfield_values record:, subfields: []
        # TODO: use intelligible names for these variables
        f245k = record.fields('245').flat_map { |field| subfield_values(field, :k) }
        f245h = record.fields('245').flat_map { |field| subfield_values(field, :h) }
        f337a = record.fields('337').flat_map { |field| subfield_values(field, :a) }

        # TODO: exactly what's going on here? is call_nums an accurate variable name?
        call_nums = record.fields(EnrichedMarc::TAG_HOLDING).map do |field|
          # h gives us the 'Classification part' which contains strings like 'Microfilm'
          join_subfields(field, &subfield_in?([EnrichedMarc::SUB_HOLDING_CLASSIFICATION_PART,
                                               EnrichedMarc::SUB_HOLDING_ITEM_PART]))
        end

        # get specific_location values from inventory info
        # locations = Location.location(record: record, display_value: 'specific_location') # TODO: from AM's MR
        locations = []

        # TODO: locations_include_manuscripts?(locations)
        if locations.any? { |loc| loc =~ /manuscripts/i }
          acc << 'Manuscript'
        # TODO: archives_but_not_cajs_or_nursing(locations) ?
        elsif locations.any? { |loc| loc =~ /archives/i } &&
              locations.none? { |loc| loc =~ /cajs/i } &&
              locations.none? { |loc| loc =~ /nursing/i }
          acc << 'Archive'
        # TODO micro_or_microform_location(locations)
        elsif locations.any? { |loc| loc =~ /micro/i } ||
              f245h.any? { |val| val =~ /micro/i } ||
              call_nums.any? { |val| val =~ /micro/i } ||
              f337a.any? { |val| val =~ /microform/i }
          acc << 'Microformat'
        else
          # these next 4 can have this format plus ONE of the formats down farther below
          acc << 'Thesis/Dissertation' if record.fields('502').any? && format_code == 'tm' # TODO: thesis_or_dissertation?(record, format_code)
          acc << 'Conference/Event' if record.fields('111').any? || record.fields('711').any? # TODO: conference_event?(record)
          acc << 'Newspaper' if format_code == 'as' && (f008[21] == 'n' || f008[22] == 'e') # TODO: newspaper?()
          acc << 'Government document' if !format_code[0].in?(%w[c d i j]) && f008[28].in?(%w[f i o]) && !f260press # TODO: government_document?(record)

          # only one of these
          # TODO: convert to case?
          acc << if format_code&.end_with?('i') ||
                    (format_code == 'am' && f006firsts.include?('m') && f006firsts.include?('s')) # TODO: website_database?(record)
                   'Website/Database'
                 elsif format_code.in?(%w[aa ac am tm]) &&
                       f245k.none? { |v| v =~ /kit/i } &&
                       f245h.none? { |v| v =~ /micro/i } # TODO: book?(record)
                   'Book'
                 elsif format_code.in?(%w[ca cb cd cm cs dm]) # TODO: musical_score?(format_code)
                   'Musical score'
                 elsif format_code&.start_with?('e') || format_code == 'fm' # TODO: map_atlas?(format_code)
                   'Map/Atlas'
                 elsif format_code == 'gm' # TODO: graphical_media?(format_code)
                   # TODO: graphical_media_type(f007? record?)
                   if f007.any? { |v| v.start_with?('v') }
                     'Video'
                   elsif f007.any? { |v| v.start_with?('g') }
                     'Projected graphic'
                   else
                     'Video' # TODO?
                   end
                 elsif format_code.in?(%w[im jm jc jd js]) # TODO: sound_recording?(format_code)
                   'Sound recording'
                 elsif format_code.in?(%w[km kd])
                   'Image'
                 elsif format_code == 'mm'
                   'Datafile'
                 elsif format_code.in?(%w[as gs])
                   'Journal/Periodical'
                 elsif format_code&.start_with?('r') # TODO: 3d_object?(format_code)
                   '3D object'
                 else
                   'Other'
                 end
        end
        acc.concat(curated_format(record))
      end

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

      private

      # Get 'Curated' format - this must be a Penn-specific practice
      # @todo find out more about Penn's 944 usage before refactoring
      # @param [MARC::Record] record
      # @return [Array]
      def curated_format(record)
        record.fields('944').map do |field|
          sf = field.find { |sf| sf.code == 'a' }
          sf.nil? || (sf.value == sf.value.to_i.to_s) ? nil : sf.value
        end.compact.uniq
      end

      def leader_format(leader)
        leader[6..7]
      end
    end
  end
end
