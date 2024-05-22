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

      CONFERENCE_SEARCH_TAGS = %w[111 711 811].freeze

      # subfields NOT to join when combining raw subfield values
      NAME_EXCLUDED_SUBFIELDS = %w[a 1 4 5 6 8 t].freeze

      CONTRIBUTOR_TAGS = %w[700 710].freeze

      # Author/Creator search field. Includes all subfield values (even ǂ0 URIs) from
      # {https://www.oclc.org/bibformats/en/1xx/100.html 100 Main Entry--Personal Name} and
      # {https://www.oclc.org/bibformats/en/1xx/110.html 110 Main Entry--Corporate Name}. Maps any relator codes found
      # in ǂ4. To better handle name searches, returns names as both "First Last" and "Last, First" if a comma is found
      # in ǂa. Also indexes any linked values in the 880.
      # @todo are we including too many details here and gumming up our index? consider UIRs, relator labels, dates...
      # @todo shouldn't indicator1 tell us the order of the name? do we not trust the indicator?
      # @note ported from get_author_creator_1_search_values
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array<String>] array of author/creator values for indexing
      def search(record, relator_map: Mappers.relator)
        name_search_values record: record, tags: TAGS, relator_map: relator_map
      end

      # Auxiliary Author/Creator search field
      # This duplicates the values returned by the search method, but adds in additional MARC tags to include
      # creator-adjacent entities. The added 4xx tags are mostly obsolete, but the 7xx tags are important. See:
      # {https://www.loc.gov/marc/bibliographic/bd700.html MARC 700},
      # {https://www.loc.gov/marc/bibliographic/bd710.html MARC 710},
      # and {https://www.loc.gov/marc/bibliographic/bd711.html MARC 711}. The 800, 810 and 8111 tags are similar in
      # theme to the 7xx fields but apply to serial records.
      # @note ported from get_author_creator_2_search_values
      # @param [MARC::Record] record
      # @return [Array<String>] array of extended author/creator values for indexing
      def search_aux(record, relator_map: Mappers.relator)
        name_search_values record: record, tags: AUX_TAGS, relator_map: relator_map
      end

      # Retrieve creator values for display from fields {https://www.loc.gov/marc/bibliographic/bd100.html 100}
      # and {https://www.loc.gov/marc/bibliographic/bd110.html 110} and their linked alternates. Appends any encoded
      # relationships found in $4. If there are no valid encoded relationships, uses the value found in $e.
      # @param [MARC::Record] record
      # @return [Array<String>] array of author/creator values for display
      def show(record, relator_map: Mappers.relator)
        fields = record.fields(TAGS)
        fields += record.fields('880').select { |field| subfield_value_in?(field, '6', TAGS) }
        fields.filter_map { |field|
          creator = join_subfields(field, &subfield_not_in?(%w[0 1 4 6 8 e w]))
          append_relator(field: field, joined_subfields: creator, relator_term_sf: 'e', relator_map: relator_map)
        }.uniq
      end

      # All author/creator values for display (like #show, but multivalued?) - no 880 linkage
      # Performs additional normalization of author names
      # @note ported from get_author_creator_values (indexed as author_creator_a) - shown on results page
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array<String>] array of author/creator values for display
      def show_aux(record, relator_map: Mappers.relator)
        record.fields(TAGS).map { |field|
          name_from_main_entry(field, relator_map)
        }.uniq
      end

      # Author/Creator sort. Does not map and include any relator codes.
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
        source_map.flat_map { |field_num, subfields|
          record.fields(field_num.to_s).map do |field|
            trim_punctuation(join_subfields(field, &subfield_in?(subfields.chars)))
          end
        }.uniq
      end

      # Conference for display, intended for results display
      # @note ported from get_conference_values
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array<String>] array of conference values
      def conference_show(record, relator_map: Mappers.relator)
        record.fields('111').filter_map { |field|
          name_from_main_entry field, relator_map
        }.uniq
      end

      # Conference detailed display, intended for record show page.
      # @note ported from get_conference_values
      # @todo what is ǂi for?
      # @param [MARC::Record] record
      # @return [Array<String>] array of conference values
      def conference_detail_show(record, relator_map: Mappers.relator)
        conferences = record.fields(%w[111 711]).filter_map do |field|
          next unless field.indicator2.in? ['', ' ']

          conf = if subfield_undefined? field, 'i'
                   join_subfields field, &subfield_not_in?(%w[0 4 5 6 8 e j w])
                 else
                   ''
                 end
          sub_unit = join_subfields(field, &subfield_in?(%w[e w]))
          conf = [conf, sub_unit].compact_blank.join(' ')

          append_relator(field: field, joined_subfields: conf, relator_term_sf: 'j', relator_map: relator_map)
        end
        conferences += record.fields('880').filter_map do |field|
          next unless subfield_value_in? field, '6', %w[111 711]

          next if subfield_defined? field, 'i'

          conf = join_subfields(field, &subfield_not_in?(%w[0 4 5 6 8 e j w]))
          sub_unit = join_subfields(field, &subfield_in?(%w[e w]))
          conf = [conf, sub_unit].compact_blank.join(' ')

          append_relator(field: field, joined_subfields: conf, relator_term_sf: 'j', relator_map: relator_map)
        end
        conferences.uniq
      end

      # Conference name values for searching
      # @param [MARC::Record] record
      # @return [Array<String>]
      def conference_search(record)
        record.fields(CONFERENCE_SEARCH_TAGS).filter_map { |field|
          join_subfields(field, &subfield_in?(%w[a c d e]))
        }.uniq
      end

      # Retrieve contributor values for display from fields {https://www.oclc.org/bibformats/en/7xx/700.html 700}
      # and {https://www.oclc.org/bibformats/en/7xx/710.html 710} and their linked alternates. Joins subfields
      # 'a', 'b', 'c', 'd', 'j', and 'q', 'u', and '3'. Then appends resulting string with any encoded relationships
      # found in $4. If there are no valid encoded relationships, uses the value found in $e.
      # @note legacy version returns array of hash objects including data for display link
      # @todo is it okay to include 880 $4 here? Legacy includes $4 in main author display 880 but not here.
      # @param [MARC::Record] record
      # @ param [Hash] relator_map
      # @return [Array<String>]
      def contributor_show(record, relator_map: Mappers.relator)
        indicator_2_options = ['', ' ', '0']
        fields = record.fields(CONTRIBUTOR_TAGS)
        fields += record.fields('880').select { |field| subfield_value_in?(field, '6', CONTRIBUTOR_TAGS) }
        fields.filter_map { |field|
          next if indicator_2_options.exclude?(field.indicator2) && field.tag.in?(CONTRIBUTOR_TAGS)
          next if subfield_defined? field, 'i'

          contributor = join_subfields(field, &subfield_in?(%w[a b c d j q u 3]))
          append_relator(field: field, joined_subfields: contributor, relator_term_sf: 'e', relator_map: relator_map)
        }.uniq
      end

      private

      # @param [MARC::Record] record
      # @param [Array] tags to consider
      # @param [Hash] relator_map
      # @return [Array<String>] name values from given tags
      def name_search_values(record:, tags:, relator_map:)
        acc = record.fields(tags).filter_map do |field|
          name_from_main_entry field, relator_map, should_convert_name_order: false
        end

        acc += record.fields(tags).filter_map do |field|
          name_from_main_entry field, relator_map, should_convert_name_order: true
        end

        acc += record.fields(['880']).filter_map do |field|
          next unless field.any? { |sf| sf.code == '6' && sf.value.in?(tags) }

          suba = field.find_all(&subfield_in?(%w[a])).filter_map { |sf|
            convert_name_order(sf.value)
          }.first
          oth = join_and_squish(field.find_all(&subfield_not_in?(%w[6 8 a t])).map(&:value))
          join_and_squish [suba, oth]
        end

        acc.uniq
      end

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
      # @param [Hash] mapping
      # @param [Boolean] should_convert_name_order
      # @return [String] joined subfield values for value from field
      def name_from_main_entry(field, mapping, should_convert_name_order: false)
        relator_term_sf = relator_term_subfield(field)
        name = field.filter_map { |sf|
          if sf.code == 'a'
            should_convert_name_order ? convert_name_order(sf.value) : sf.value
          elsif sf.code == relator_term_sf
            next
          elsif NAME_EXCLUDED_SUBFIELDS.exclude?(sf.code)
            sf.value
          end
        }.join(' ')

        name_and_relator = append_relator(field: field,
                                          joined_subfields: name,
                                          relator_term_sf: relator_term_sf,
                                          relator_map: mapping)

        name_and_relator + (%w[. -].member?(name_and_relator.last) ? '' : '.')
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
