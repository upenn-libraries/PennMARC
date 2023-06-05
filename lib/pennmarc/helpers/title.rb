# frozen_string_literal: true

module PennMARC
  # This helper contains logic for parsing out Title and Title-related fields.
  class Title < Helper
    class << self
      # Title Search
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
      # @return [String]
      def show(record)
        acc = []
        acc += record.fields('245').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        acc += linked_alternate(record, '245', &subfield_not_in?(%w[6 8]))
               .map { |value| " = #{value}" }
        acc.join(' ')
      end

      # Canonical title, with nonfiling characters removed, if present and specified
      # TODO: it seems we are currently using a multivalued field for sorting...check the schema...
      def sort(record); end

      # we dont facet by title...but there is xfacet stuff currently that supports title browse
      # def facet(record:); end

      # Standardized Title
      #
      # These values are intended for display. There has been distinct logic for storing search values as well
      # (see get_standardized_title_values) but this appears only used with Title Browse functionality.
      #
      # 130: https://www.oclc.org/bibformats/en/1xx/130.html
      # 240: https://www.oclc.org/bibformats/en/2xx/240.html
      #
      # Ported from get_standardized_title_display. Returned values from legacy method are "link" hashes.
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
      # These titles are intended for display
      #
      # 246: https://www.oclc.org/bibformats/en/2xx/246.html
      # 740: https://www.oclc.org/bibformats/en/7xx/740.html
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
