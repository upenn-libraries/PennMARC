# frozen_string_literal: true

module PennMARC
  # This helper contains logic for parsing out Title and Title-related fields.
  class Title < Helper
    class << self
      # Title Search
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def search(record)
        record.fields('245').take(1).map do |field|
          a_or_k = field.find_all(&subfield_in?(%w[a k]))
                        .map { |sf| trim_trailing(:comma, trim_trailing(:slash, sf.value).rstrip) }
                        .first || ''
          joined = field.find_all(&subfield_in?(%w[b n p]))
                        .map { |sf| trim_trailing(:slash, sf.value) }
                        .join(' ')
          apunct = a_or_k[-1]
          hpunct = field.find_all { |sf| sf.code == 'h' }
                        .map { |sf| sf.value[-1] }
                        .first
          punct = if [apunct, hpunct].member?('=')
                    '='
                  else
                    [apunct, hpunct].member?(':') ? ':' : nil
                  end

          [trim_trailing(:colon, trim_trailing(:equal, a_or_k)), punct, joined]
            .select(&:present?).join(' ')
        end
      end

      # Display Title
      #
      # @param [MARC::Record] record
      # @return [String] single valued title
      def show(record)
        acc = []
        acc += record.fields('245').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        acc += linked_alternate(record, '245', &subfield_not_in?(%w[6 8]))
               .map { |value| " = #{value}" }
        acc.join(' ')
      end

      # Canonical title, with non-filing characters removed, if present and specified. Currently we index two "title
      # sort" fields: title_nssort (ssort type - regex token filter applied) and title_sort_tl (text left justified).
      # It is not yet clear why this distinction is useful. For now, use a properly normalized (leading
      # articles and punctuation removed) single title value here.
      # @todo refactor to reduce complexity
      # @param [MARC::Record] record
      # @return [String]
      def sort(record)
        title_field = record.fields('245').first
        return unless title_field

        # attempt to get number of non-filing characters present, default to 0
        offset = if title_field.indicator2 =~ /^[0-9]$/
                   title_field.indicator2.to_i
                 else
                   0
                 end
        raw_title = join_subfields(title_field, &subfield_in?(['a'])) # get title from subfield a
        value = if offset.between?(1, 9)
                  { prefix: raw_title[0..offset - 1].strip, filing: raw_title[offset..].strip }
                elsif raw_title
                  handle_bracket_prefix raw_title
                else
                  # no subfield a, no indicator
                  raw_form = join_subfields(title_field, &subfield_in?(['a']))
                  handle_bracket_prefix raw_form
                end
        value[:filing] = [value[:filing],
                          join_subfields(title_field, &subfield_in?(%w[b n p]))].join(' ')
        value[:filing] + value[:prefix]
      end

      # Create prefix/filing hash for representing a title value with filing characters removed, with special
      # consideration for bracketed titles
      # @todo Is this still useful?
      # @param [String] title
      # @return [Hash]
      def handle_bracket_prefix(title)
        if title.starts_with? '['
          { prefix: '[', filing: title[1..] } # this seems silly
        else
          { prefix: '', filing: title }
        end
      end

      # Standardized Title
      #
      # These values are intended for display. There has been distinct logic for storing search values as well
      # (see get_standardized_title_values) but this appears only used with Title Browse functionality. Values come
      # from 130 ({https://www.oclc.org/bibformats/en/1xx/130.html OCLC docs}) and 240
      # ({https://www.oclc.org/bibformats/en/2xx/240.html OCLC docs}) as well as relator fields. Ported from Franklin
      # get_standardized_title_display. Returned values from legacy method are "link" hashes.
      #
      # @param [MARC::Record] record
      # @return [Array<String>] Array of standardized titles as strings
      def standardized(record)
        standardized_titles = []
        standardized_titles += titles_from_130_240(record)
        standardized_titles += titles_from_730(record)
        standardized_titles + standardized_titles_from_880(record)
      end

      # Other Title
      #
      # These titles are intended for display. Data comes from 246
      # ({https://www.oclc.org/bibformats/en/2xx/246.htm OCLC docs}) and 740
      # ({https://www.oclc.org/bibformats/en/7xx/740.html OCLC docs)}
      #
      # Ported from get_other_title_display
      # @param [MARC::Record] record
      # @return [Array<String>] Array of other titles as strings
      def other(record)
        other_titles = []
        other_titles += titles_from_246(record)
        other_titles += titles_from_740(record)
        other_titles + other_titles_from_880(record)
      end

      # Former Title
      # These titles are intended for display
      #
      # https://www.loc.gov/marc/bibliographic/concise/bd247.html
      # https://www.oclc.org/bibformats/en/2xx/247.html
      #
      # Ported from get_former_title_display. That method returns a hash for constructing a search link.
      # We may need to do something like that eventually.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def former(record)
        record.fields
              .select { |field| field.tag == '247' || (field.tag == '880' && subfield_value?(field, '6', /^247/)) } # TODO: this is a common pattern, how can we make this more clear?
              .map do |field|
          former_title = join_subfields field, &subfield_not_in?(%w[6 8 e w]) # 6 and 8 are not meaningful for display
          former_title_append = join_subfields field, &subfield_in?(%w[e w]) # TODO: e and w appear undocumented - what are they?
          "#{former_title} #{former_title_append}"
        end
      end
    end
  end
end
