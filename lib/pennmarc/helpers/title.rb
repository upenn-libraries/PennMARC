# frozen_string_literal: true

require_relative '../services/title_suggestion_weight_service'

module PennMARC
  # This helper contains logic for parsing out Title and Title-related fields.
  class Title < Helper
    # We use these fields when retrieving auxiliary titles in the *search_aux methods:
    # {https://www.loc.gov/marc/bibliographic/bd130.html 130},
    # {https://www.loc.gov/marc/bibliographic/bd210.html 210},
    # {https://www.loc.gov/marc/bibliographic/bd245.html 245},
    # {https://www.loc.gov/marc/bibliographic/bd246.html 246},
    # {https://www.loc.gov/marc/bibliographic/bd247.html 247},
    # {https://www.loc.gov/marc/bibliographic/bd440.html 440},
    # {https://www.loc.gov/marc/bibliographic/bd490.html 490},
    # {https://www.loc.gov/marc/bibliographic/bd730.html 730},
    # {https://www.loc.gov/marc/bibliographic/bd740.html 740},
    # {https://www.loc.gov/marc/bibliographic/bd830.html 830},
    # {https://www.loc.gov/marc/bibliographic/bd773.html 773},
    # {https://www.loc.gov/marc/bibliographic/bd774.html 774},
    # {https://www.loc.gov/marc/bibliographic/bd780.html 780},
    # {https://www.loc.gov/marc/bibliographic/bd785.html 785},
    # {https://www.loc.gov/marc/bibliographic/bd700.html 700},
    # {https://www.loc.gov/marc/bibliographic/bd710.html 710},
    # {https://www.loc.gov/marc/bibliographic/bd711.html 711},
    # {https://www.loc.gov/marc/bibliographic/bd505.html 505}
    AUX_TITLE_TAGS = {
      main: %w[130 210 240 245 246 247 440 490 730 740 830],
      related: %w[773 774 780 785],
      entity: %w[700 710 711],
      note: %w[505]
    }.freeze

    # This text is used in Alma to indicate a Bib record is a "Host" record for other bibs (bound-withs)
    HOST_BIB_TITLE = 'Host bibliographic record for boundwith'

    # Title to use when no 245 field is present. This "shouldn't" occur, but it does.
    NO_TITLE_PROVIDED = '[No title provided]'

    class << self
      # Values for title suggester, including only ǂa and ǂb from
      # {https://www.loc.gov/marc/bibliographic/bd245.html 245} field. Limits the output to 20 words and strips any
      # trailing slashes.
      # @param record [MARC::Record]
      # @return [Array<String>] array of all title values for suggestion
      def suggest(record)
        record.fields(%w[245]).filter_map do |field|
          join_subfields(field, &subfield_in?(%w[a b]))
            .squish
            .truncate_words(20)
            .sub(%r{ /$}, '')
        end
      end

      # An integer value used for weighing title suggest values. See {PennMARC::TitleSuggestionWeightService} for logic.
      # @param record [MARC::Record]
      # @return [Integer]
      def suggest_weight(record)
        PennMARC::TitleSuggestionWeightService.weight record
      end

      # Main Title Search field. Takes from {https://www.loc.gov/marc/bibliographic/bd245.html 245} and linked 880.
      # @note Ported from get_title_1_search_values.
      # @param record [MARC::Record]
      # @return [Array<String>] array of title values for search
      def search(record)
        record.fields(%w[245 880]).filter_map { |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^245/)

          join_subfields(field, &subfield_not_in?(%w[c 6 8 h]))
        }.uniq
      end

      # Auxiliary Title Search field. Takes from many fields defined in {AUX_TITLE_TAGS} that contain title-like
      # information.
      # @param record [MARC::Record]
      # @return [Array<String>] array of auxiliary title values for search
      def search_aux(record)
        values = search_aux_values(record: record, title_type: :main, &subfield_not_in?(%w[c 6 8])) +
                 search_aux_values(record: record, title_type: :related, &subfield_not_in?(%w[s t])) +
                 search_aux_values(record: record, title_type: :entity, &subfield_in?(%w[t])) +
                 search_aux_values(record: record, title_type: :note, &subfield_in?(%w[t]))
        values.uniq
      end

      # Journal Title Search field. Takes from {https://www.loc.gov/marc/bibliographic/bd245.html 245} and linked 880.
      # We do not return any values if the {https://www.loc.gov/marc/bibliographic/bdleader.html MARC leader}
      # indicates that the record is not a serial.
      # @param record [MARC::Record]
      # @return [Array<String>] journal title information for search
      def journal_search(record)
        return [] if not_a_serial?(record)

        record.fields(%w[245 880]).filter_map { |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^245/)

          join_subfields(field, &subfield_not_in?(%w[c 6 8 h]))
        }.uniq
      end

      # Auxiliary Journal Title Search field. Takes from many fields defined in {AUX_TITLE_TAGS} that contain title-like
      # information. Does not return any titles if the {https://www.loc.gov/marc/bibliographic/bdleader.html MARC leader}
      # indicates that the record is not a serial.
      # @param record [MARC::Record]
      # @return [Array<String>] auxiliary journal title information for search
      def journal_search_aux(record)
        values = search_aux_values(record: record, title_type: :main, journal: true, &subfield_not_in?(%w[c 6 8])) +
                 search_aux_values(record: record, title_type: :related, journal: true, &subfield_not_in?(%w[s t])) +
                 search_aux_values(record: record, title_type: :entity, journal: true, &subfield_in?(%w[t])) +
                 search_aux_values(record: record, title_type: :note, journal: true, &subfield_in?(%w[t]))
        values.uniq
      end

      # Single-valued Title, for use in headings. Takes the first {https://www.oclc.org/bibformats/en/2xx/245.html 245}
      # value. Special consideration for
      # {https://www.oclc.org/bibformats/en/2xx/245.html#punctuation punctuation practices}.
      # @todo is punctuation handling still as desired? treatment here is described in spreadsheet from 2011
      # @param record [MARC::Record]
      # @return [String] single title for display
      def show(record)
        field = record.fields('245')&.first
        return Array.wrap(NO_TITLE_PROVIDED) unless field.present?

        values = title_values(field)
        [format_title(values[:title_or_form]), values[:punctuation], values[:other_info]].compact_blank.join(' ')
      end

      # Same as show, but with all subfields included as found - except for subfield c.
      # @param record [MARC::Record]
      # @return [String] detailed title for display
      def detailed_show(record)
        field = record.fields('245')&.first
        return unless field

        join_subfields(field, &subfield_not_in?(%w[6 8]))
      end

      # Same structure as show, but linked alternate title.
      # @param record [MARC::Record]
      # @return [String, nil] alternate title for display
      def alternate_show(record)
        field = record.fields('880').filter_map { |alternate_field|
          next unless subfield_value?(alternate_field, '6', /^245/)

          alternate_field
        }.first
        return unless field

        values = title_values(field, include_subfield_c: true)
        [format_title(values[:title_or_form]), values[:punctuation], values[:other_info]].compact_blank.join(' ')
      end

      # Canonical title with non-filing characters relocated to the end.
      #
      # @note Currently we index two "title sort" fields: title_nssort (ssort type - regex token filter applied) and
      #       title_sort_tl (text left justified). It is not yet clear why this distinction is useful. For now, use a
      #       properly normalized (leading articles and punctuation removed) single title value here.
      # @todo refactor to reduce complexity
      # @param record [MARC::Record]
      # @return [String] title value for sorting
      def sort(record)
        title_field = record.fields('245').first
        return unless title_field.present?

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
      # @param record [MARC::Record]
      # @return [Array<String>] Array of standardized titles as strings
      def standardized_show(record)
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
        titles = standardized_titles + record.fields('880').filter_map do |field|
          next unless subfield_undefined?(field, 'i') &&
                      subfield_value?(field, '6', /^(130|240|730)/)

          join_subfields field, &subfield_not_in?(%w[5 6 8 e w])
        end
        titles.uniq
      end

      # Other Title for display
      #
      # Data comes from 246 ({https://www.oclc.org/bibformats/en/2xx/246.htm OCLC docs}) and 740
      # ({https://www.oclc.org/bibformats/en/7xx/740.html OCLC docs)}
      #
      # @param record [MARC::Record]
      # @return [Array<String>] Array of other titles as strings
      def other_show(record)
        other_titles = record.fields('246').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        other_titles += record.fields('740')
                              .filter_map do |field|
          next unless field.indicator2.in? ['', ' ', '0', '1', '3']

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
        titles = other_titles + record.fields('880').filter_map do |field|
          next unless subfield_value? field, '6', /^(246|740)/

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
        titles.uniq
      end

      # Former Title for display.
      # These values come from {https://www.oclc.org/bibformats/en/2xx/247.html 247}.
      #
      # @note Ported from get_former_title_display. That method returns a hash for constructing a search link.
      #       We may need to do something like that eventually.
      # @todo what are e and w subfields?
      # @param record [MARC::Record]
      # @return [Array<String>] array of former titles
      def former_show(record)
        record.fields
              .filter_map { |field|
                next unless field.tag == '247' || (field.tag == '880' && subfield_value?(field, '6', /^247/))

                # 6 and 8 are not meaningful for display
                former_title = join_subfields field, &subfield_not_in?(%w[6 8 e w])
                former_title_append = join_subfields field, &subfield_in?(%w[e w])
                "#{former_title} #{former_title_append}".strip
              }.uniq
      end

      # Determine if the record is a "Host" bibliographic record for other bib records ("bound-withs")
      # @param record [MARC::Record]
      # @return [Boolean]
      def host_bib_record?(record)
        record.fields('245').any? do |f|
          title = join_subfields(f, &subfield_in?(%w[a]))
          title.include?(HOST_BIB_TITLE)
        end
      end

      private

      # Extract title values from provided 245 subfields. Main title components are the following:
      # - title_or_form: subfields a and k
      # - other_info: subfields b, n, and p (for alternate title, include subfield c)
      # https://www.oclc.org/bibformats/en/2xx/245.html
      #
      # @param field [MARC::Field]
      # @param include_subfield_c [Boolean]
      # @return [Hash] title values
      def title_values(field, include_subfield_c: false)
        title_or_form = field.find_all(&subfield_in?(%w[a k]))
                             .map { |sf| trim_trailing(:comma, trim_trailing(:slash, sf.value).rstrip) }
                             .first || ''
        other_info = field.find_all(&subfield_in?(include_subfield_c ? %w[b c n p] : %w[b n p]))
                          .map { |sf| trim_trailing(:slash, sf.value) }
                          .join(' ')
        title_punctuation = title_or_form.last
        medium_punctuation = field.find_all { |sf| sf.code == 'h' }
                                  .map { |sf| sf.value.last }
                                  .first
        punctuation = if [title_punctuation, medium_punctuation].include?('=')
                        '='
                      else
                        [title_punctuation, medium_punctuation].include?(':') ? ':' : nil
                      end
        { title_or_form: title_or_form,
          other_info: other_info,
          punctuation: punctuation }
      end

      # Remove trailing equal from title, then remove trailing colon.
      # @param title [String]
      # @return [String]
      def format_title(title)
        trim_trailing(:colon, trim_trailing(:equal, title)).strip
      end

      # Create prefix/filing hash for representing a title value with filing characters removed, with special
      # consideration for bracketed titles
      # @todo Is this still useful?
      # @param title [String]
      # @return [Hash]
      def handle_bracket_prefix(title)
        if title.starts_with? '['
          { prefix: '[', filing: title[1..].strip }
        else
          { prefix: '', filing: title.strip }
        end
      end

      # Evaluate {https://www.loc.gov/marc/bibliographic/bdleader.html MARC leader} to determine if record is a serial.
      # @param record [MARC::Record]
      # @return [Boolean]
      def not_a_serial?(record)
        !record.leader[6..7].ends_with?('s')
      end

      # @param field [MARC::DataField]
      # @param value [String]
      # @return [Boolean]
      def indicators_are_not_value?(field, value)
        field.indicator1 != value && field.indicator2 != value
      end

      # Retrieve auxiliary title values. Returns no values if a journal is expected but the
      # {https://www.loc.gov/marc/bibliographic/bdleader.html MARC leader} indicates that the record is not a serial.
      # We take special consideration for the {https://www.loc.gov/marc/bibliographic/bd505.html 505 field}, extracting
      # values only when indicator1 and indicator2 are both '0'.
      # @param record [MARC::Record]
      # @param title_type [Symbol]
      # @param journal [Boolean]
      # @param join_selector [Proc]
      # @return [Array<String>]
      def search_aux_values(record:, title_type:, journal: false, &join_selector)
        return [] if journal && not_a_serial?(record)

        tags = AUX_TITLE_TAGS[title_type] + ['880']

        record.fields(tags).filter_map do |field|
          next if field.tag == '505' && indicators_are_not_value?(field, '0')

          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^(#{tags.join('|')})/)

          join_subfields(field, &join_selector)
        end
      end
    end
  end
end
