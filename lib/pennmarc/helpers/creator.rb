# frozen_string_literal: true

module PennMARC
  # Do Creator & Author field processing. Main methods pull from 110 and 111 fields. Display methods here no longer
  # return data structures intended for generating "search" links, but some of the split subfield parsing remains from
  # ported methods in case we need to replicate that functionality.
  # @todo can there ever be multiple 100 fields?
  #       can ǂe and ǂ4 both be used at the same time? seems to result in duplicate values
  class Creator < Helper
    class << self
      # Main tags for Author/Creator information
      TAGS = %w[100 110].freeze
      # Aux tags for Author/Creator information, for use in search_aux method
      AUX_TAGS = %w[100 110 111 400 410 411 700 710 711 800 810 811].freeze

      # Author/Creator search field. Includes all subfield values (even ǂ0 URIs) from
      # {https://www.oclc.org/bibformats/en/1xx/100.html 100 Main Entry--Personal Name} and
      # {https://www.oclc.org/bibformats/en/1xx/110.html 110 Main Entry--Corporate Name}. Maps any relator codes found
      # in ǂ4. To better handle name searches, returns names as both "First Last" and "Last, First" if a comma is found
      # in ǂa. Also indexes any linked values in the 880. SOme of the search fields remain incomplete and may need to be
      # further investigated and ported when search result relevancy is considered.
      # @todo this seems bad - why include relator labels? URIs? punctuation? leaving mostly as-is for now,
      #       but this should be reexamined in the relevancy-tuning phase. URIs should def be removed. and shouldn't
      #       indicator1 tell us the order of the name?
      # @note ported from get_author_creator_1_search_values
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of author/creator values for indexing
      def search(record, relator_mapping)
        acc = record.fields(TAGS).map do |field|
          pieces = field.filter_map do |sf|
            if sf.code == 'a'
              convert_name_order(sf.value)
            elsif !%w[a 1 4 6 8].member?(sf.code)
              sf.value
            elsif sf.code == '4'
              relator = translate_relator(sf.value, relator_mapping)
              next if relator.blank?

              relator
            end
          end
          value = join_and_squish(pieces)
          if value.end_with?('.') || value.end_with?('-')
            value
          else
            "#{value}."
          end
        end
        # a second iteration over the same fields produces name entries with the names not reordered
        acc += record.fields(TAGS).map do |field|
          pieces = field.filter_map do |sf|
            if !%w[4 6 8].member?(sf.code)
              sf.value
            elsif sf.code == '4'
              relator = translate_relator(sf.value, relator_mapping)
              next if relator.blank?

              relator
            end
          end
          value = join_and_squish(pieces)
          if value.end_with?('.') || value.end_with?('-')
            value
          else
            "#{value}."
          end
        end
        acc += record.fields(%w[880])
                     .select { |f| f.any? { |sf| sf.code == '6' && sf.value =~ /^(100|110)/ } }
                     .map do |field|
          suba = field.find_all(&subfield_in?(%w[a])).map do |sf|
            convert_name_order(sf.value)
          end.first
          oth = join_and_squish(field.find_all(&subfield_not_in?(%w[6 8 a t])).map(&:value))
          join_and_squish [suba, oth]
        end
        acc.uniq
      end

      # Auxiliary Author/Creator search field
      # @note ported from get_author_creator_2_search_values
      # @todo port this later
      # @param [MARC::Record] record
      # @return [Array<String>] array of extended author/creator values for indexing
      def search_aux(record); end

      # All author/creator values for display (like #show, but multivalued?) - no 880 linkage
      # @note ported from get_author_creator_values (indexed as author_creator_a) - shown on results page
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of author/creator values for display
      def values(record, relator_mapping)
        record.fields(TAGS).map do |field|
          name_from_main_entry(field, relator_mapping)
        end
      end

      # Author/Creator values for display
      # @todo ported from get_author_display - used on record show page. porting did not include 4, e or w values,
      #       which were part of the link object as 'append' values in franklin
      # @param [MARC::Record] record
      # @return [Array<String>] array of author/creator values for display
      def show(record)
        fields = record.fields(TAGS)
        fields += record.fields('880').select { |field| subfield_value_in?(field, '6', TAGS) }
        fields.filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 1 4 6 8 e w]))
        end
      end

      # Author/Creator sort. Does not map and include any relator
      # codes.
      # @todo This includes any URI from ǂ0 which could help to disambiguate in sorts, but ǂ1 is excluded...
      # @note ported from get_author_creator_sort_values
      # @param [MARC::Record] record
      # @return [String] string with author/creator value for sorting
      def sort(record)
        field = record.fields(TAGS).first
        join_subfields(field, &subfield_not_in?(%w[1 4 6 8 e]))
      end

      # Author/Creator for faceting. Grabs values from a plethora of fields, joins defined subfields, then trims some
      # punctuation (@see trim_punctuation)
      # @todo should trim_punctuation apply to each subfield value, or the joined values? i think the joined values
      # @note ported from author_creator_xfacet2_input - is this the best choice? check the copyField declarations -
      #       franklin uses author_creator_f
      # @param [MARC::Record] record
      # @return [Array<String>] array of author/creator values for faceting
      def facet(record)
        source_map = {
          100 => 'abcdjq', 110 => 'abcdjq', 111 => 'abcen',
          700 => 'abcdjq', 710 => 'abcdjq', 711 => 'abcen',
          800 => 'abcdjq', 810 => 'abcdjq', 811 => 'abcen'
        }
        source_map.flat_map do |field_num, subfields|
          record.fields(field_num.to_s).map do |field|
            trim_punctuation(join_subfields(field, &subfield_in?(subfields.split(''))))
          end
        end
      end

      # Conference for display, intended for results display
      # @note ported from get_conference_values
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array<String>] array of conference values
      def conference_show(record, relator_map)
        record.fields('111').filter_map do |field|
          name_from_main_entry field, relator_map
        end
      end

      # Conference detailed display, intended for record show page.
      # @note ported from get_conference_values
      # @todo what is ǂi for?
      # @param [MARC::Record] record
      # @return [Array<String>] array of conference values
      def conference_detail_show(record)
        values = record.fields(%w[111 711]).filter_map do |field|
          next unless field.indicator2.in? ['', ' ']

          conf = if subfield_undefined? field, 'i'
                   join_subfields field, &subfield_not_in?(%w[0 4 5 6 8 e j w])
                 else
                   ''
                 end
          conf_extra = join_subfields field, &subfield_in?(%w[e j w])
          join_and_squish [conf, conf_extra].compact_blank
        end
        values + record.fields('880').filter_map do |field|
          next unless subfield_value_in? field, '6', %w[111 711]

          next if subfield_defined? field, 'i'

          conf = join_subfields(field, &subfield_not_in?(%w[0 4 5 6 8 e j w]))
          conf_extra = join_subfields(field, &subfield_in?(%w[4 e j w]))
          join_and_squish [conf, conf_extra]
        end
      end

      # @todo this supports "Conference" fielded search and may not be needed
      # @note see get_conference_search_values
      def conference_search(record); end

      private

      # Trim punctuation method extracted from Traject macro, to ensure consistent output
      # @todo move to Util?
      # @param [String] string
      # @return [String] string with relevant punctuation removed
      def trim_punctuation(string)
        return string unless string

        string = string.sub(%r{ *[ ,/;:] *\Z}, '')

        # trailing period if it is preceded by at least three letters (possibly preceded and followed by whitespace)
        string = string.sub(/( *[[:word:]]{3,})\. *\Z/, '\1')

        # single square bracket characters if they are the start and/or end chars and there are no internal square
        # brackets.
        string = string.sub(/\A\[?([^\[\]]+)\]?\Z/, '\1')

        # trim any leading or trailing whitespace
        string.strip
      end

      # Extract the information we care about from 1xx fields, map relator codes, and use appropriate punctuation
      # @param [MARC::Field] field
      # @return [String] joined subfield values for value from field
      def name_from_main_entry(field, mapping)
        s = field.filter_map do |sf|
          if !%w[0 1 4 6 8].member?(sf.code)
            " #{sf.value}"
          elsif sf.code == '4'
            relator = translate_relator(sf.value, mapping)
            next if relator.blank?

            ", #{relator}"
          end
        end.join
        (s + (!%w[. -].member?(s.last) ? '.' : '')).squish
      end

      # Translate a relator code using mapping
      # @todo handle case of receiving a URI? E.g., http://loc.gov/relator/aut
      # @param [String] relator_code
      # @param [Hash] mapping
      # @return [String, NilClass]
      def translate_relator(relator_code, mapping)
        return unless relator_code.present?

        mapping[relator_code.to_sym]
      end

      # Convert "Lastname, First" to "First Lastname"
      # @param [String] name value for processing
      # @return [String]
      def convert_name_order(name)
        return name unless name.include? ','

        after_comma = join_and_squish([trim_trailing(:comma, substring_after(name, ', '))])
        before_comma = substring_before(name, ', ')
        "#{after_comma} #{before_comma}".squish
      end
    end
  end
end
