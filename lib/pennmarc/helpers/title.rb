# frozen_string_literal: true

module PennMARC
  # This helper contains logic for parsing out Title and Title-related fields.
  class Title < Helper
    class << self
      # these will be used when completing the *search_aux methods
      AUX_TITLE_TAGS = {
        main: %w[130 210 240 245 246 247 440 490 730 740 830],
        related: %w[773 774 780 785],
        entity: %w[700 710 711]
      }.freeze

      # Main Title Search field. Takes from 245 and linked 880.
      # @note Ported from get_title_1_search_values.
      # @param [MARC::Record] record
      # @return [Array<String>] array of title values for search
      def search(record)
        titles = record.fields('245').filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[c 6 8 h]))
        end
        titles + record.fields('880').filter_map do |field|
          next unless subfield_value?(field, '6', /245/)

          join_subfields(field, &subfield_not_in?(%w[c 6 8 h]))
        end
      end

      # Auxiliary Title Search field. Takes from many fields that contain title-like information.
      # @note Ported from get_title_2_search_values.
      # @todo port this, it is way complicated but essential for relevance
      # @param [MARC::Record] record
      # @return [Array<String>] array of title values for search
      def search_aux(record); end

      # Journal Title Search field.
      # @param [MARC::Record] record
      # @return [Array<String>] journal title information for search
      def journal_search(record)
        record.fields(%w[245 880]).filter_map do |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', %w[245])

          next unless format(record).ends_with?('s')

          join_subfields(field, &subfield_not_in?(%w[c 6 8 h]))
        end
      end

      # Auxiliary Journal Title Search field.
      # @todo port this, it is way complicated but essential for relevance
      # @param [MARC::Record] record
      # @return [Array<String>] journal title information for search
      def journal_search_aux(record)
        search_aux_values(record: record, tags: AUX_TITLE_TAGS[:main], journal: true, exclude: %w[c 6 8]) +
          search_aux_values(record: record, tags: AUX_TITLE_TAGS[:related], journal: true, exclude: %w[s t]) +
          search_aux_values(record: record, tags: AUX_TITLE_TAGS[:entity], journal: true, include: %w[t]) +
          search_aux_values(record: record, tags: %w[505], journal: true, include: %w[t])
      end

      # Single-valued Title, for use in headings. Takes the first {https://www.oclc.org/bibformats/en/2xx/245.html 245}
      # value. Special consideration for
      # {https://www.oclc.org/bibformats/en/2xx/245.html#punctuation punctuation practices}.
      # @todo still consider ǂh? medium, which OCLC doc says DO NOT USE...but that is OCLC...
      # @todo is punctuation handling still as desired? treatment here is described in spreadsheet from 2011
      # @param [MARC::Record] record
      # @return [String] single title for display
      def show(record)
        field = record.fields('245').first
        title_or_form = field.find_all(&subfield_in?(%w[a k]))
                             .map { |sf| trim_trailing(:comma, trim_trailing(:slash, sf.value).rstrip) }
                             .first || ''
        other_info = field.find_all(&subfield_in?(%w[b n p]))
                          .map { |sf| trim_trailing(:slash, sf.value) }
                          .join(' ')
        hpunct = field.find_all { |sf| sf.code == 'h' }.map { |sf| sf.value.last }.first
        punctuation = if [title_or_form.last, hpunct].include?('=')
                        '='
                      else
                        [title_or_form.last, hpunct].include?(':') ? ':' : nil
                      end
        [trim_trailing(:colon, trim_trailing(:equal, title_or_form)).strip,
         punctuation,
         other_info].compact_blank.join(' ')
      end

      # Canonical title with non-filing characters relocated to the end.
      #
      # @note Currently we index two "title sort" fields: title_nssort (ssort type - regex token filter applied) and
      #       title_sort_tl (text left justified). It is not yet clear why this distinction is useful. For now, use a
      #       properly normalized (leading articles and punctuation removed) single title value here.
      # @todo refactor to reduce complexity
      # @param [MARC::Record] record
      # @return [String] title value for sorting
      def sort(record)
        title_field = record.fields('245').first
        # attempt to get number of non-filing characters present, default to 0
        offset = if /^[0-9]$/.match?(title_field.indicator2)
                   title_field.indicator2.to_i
                 else
                   0
                 end
        raw_title = join_subfields(title_field, &subfield_in?(['a'])) # get title from subfield a
        value = if offset.between?(1, 9)
                  { prefix: raw_title[0..offset - 1]&.strip, filing: raw_title[offset..]&.strip }
                elsif raw_title.present?
                  handle_bracket_prefix raw_title
                else
                  # no subfield a, no indicator
                  raw_form = join_subfields(title_field, &subfield_in?(['k']))
                  handle_bracket_prefix raw_form
                end
        value[:filing] = [value[:filing],
                          join_subfields(title_field, &subfield_in?(%w[b n p]))].compact_blank.join(' ')
        [value[:filing], value[:prefix]].join(' ').strip
      end

      # Standardized Title
      #
      # These values are intended for display. There has been distinct logic for storing search values as well
      # (see get_standardized_title_values) but this appears only used with Title Browse functionality. Values come
      # from 130 ({https://www.oclc.org/bibformats/en/1xx/130.html OCLC docs}) and 240
      # ({https://www.oclc.org/bibformats/en/2xx/240.html OCLC docs}) as well as relator fields. Ported from Franklin
      # get_standardized_title_display. Returned values from legacy method are "link" hashes.

      # @note this is simplified from legacy practice as a linking hash is not returned. I believe this only supported
      #       title browse and we will not be supporting that at this time
      # @param [MARC::Record] record
      # @return [Array<String>] Array of standardized titles as strings
      def standardized(record)
        standardized_titles = record.fields(%w[130 240]).map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 6 8 e w]))
        end
        standardized_titles += record.fields('730').filter_map do |field|
          # skip unless one of the indicators is blank
          next unless field.indicator1 == '' || field.indicator2 == ''

          # skip if a subfield i is present
          next if subfield_defined?(field, 'i')

          join_subfields(field, &subfield_not_in?(%w[5 6 8 e w]))
        end
        standardized_titles + record.fields('880').filter_map do |field|
          next unless subfield_undefined?(field, 'i') ||
                      subfield_value_in?(field, '6', %w[130 240 730])

          join_subfields field, &subfield_not_in?(%w[5 6 8 e w])
        end
      end

      # Other Title for display
      #
      # Data comes from 246 ({https://www.oclc.org/bibformats/en/2xx/246.htm OCLC docs}) and 740
      # ({https://www.oclc.org/bibformats/en/7xx/740.html OCLC docs)}
      #
      # @param [MARC::Record] record
      # @return [Array<String>] Array of other titles as strings
      def other(record)
        other_titles = record.fields('246').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        other_titles += record.fields('740')
                              .filter_map do |field|
          next unless field.indicator2.in? ['', ' ', '0', '1', '3']

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
        other_titles + record.fields('880').filter_map do |field|
          next unless subfield_value_in? field, '6', %w[246 740]

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
      end

      # Former Title for display.
      # These values come from {https://www.oclc.org/bibformats/en/2xx/247.html 247}.
      #
      # @note Ported from get_former_title_display. That method returns a hash for constructing a search link.
      #       We may need to do something like that eventually.
      # @todo what are e and w subfields?
      # @param [MARC::Record] record
      # @return [Array<String>] array of former titles
      def former(record)
        record.fields
              .filter_map do |field|
          next unless field.tag == '247' || (field.tag == '880' && subfield_value?(field, '6', /^247/))

          former_title = join_subfields field, &subfield_not_in?(%w[6 8 e w]) # 6 and 8 are not meaningful for display
          former_title_append = join_subfields field, &subfield_in?(%w[e w])
          "#{former_title} #{former_title_append}".strip
        end
      end

      private

      # Create prefix/filing hash for representing a title value with filing characters removed, with special
      # consideration for bracketed titles
      # @todo Is this still useful?
      # @param [String] title
      # @return [Hash]
      def handle_bracket_prefix(title)
        if title.starts_with? '['
          { prefix: '[', filing: title[1..].strip }
        else
          { prefix: '', filing: title.strip }
        end
      end

      def format(rec)
        rec.leader[6..7]
      end

      def search_aux_values(record:, tags:, journal: false, include: [], exclude: [])
        record.fields(tags + ['880']).filter_map do |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', tags)

          next if field.tag == '505' && !(field.indicator1 == '0' && field.indicator2 == '0')

          next if journal && !format(record).ends_with?('s')

          return StandardError if include.present? && exclude.present?

          if exclude.present?
            join_subfields(field, &subfield_not_in?(exclude))
          else
            join_subfields(field, &subfield_in?(include))
          end
        end
      end
    end
  end
end
