# frozen_string_literal: true

module PennMARC
  # Do Creator & Author field processing. Main methods pull from 110 and 111 fields.
  # @todo can there ever be multiple 100 fields?
  #       can ǂe and ǂ4 both be used at the same time? seems to result in duplicate values
  class Creator < Helper
    # Main tags for Author/Creator information
    TAGS = %w[100 110].freeze

    # For creator fields intended for display, these subfields are ignored
    DISPLAY_EXCLUDED_SUBFIELDS = %w[a 0 1 4 5 6 8 t].freeze

    # For creator fields intended for searching, these subfields are ignored
    SEARCH_EXCLUDED_SUBFIELDS = %w[a 1 4 5 6 8 t].freeze

    # Aux tags for Author/Creator information, for use in search_aux method
    AUX_TAGS = %w[100 110 111 400 410 411 700 710 711 800 810 811].freeze

    CONFERENCE_SEARCH_TAGS = %w[111 711 811].freeze
    CORPORATE_SEARCH_TAGS = %w[110 710 810].freeze

    CONTRIBUTOR_TAGS = %w[700 710].freeze
    CONTRIBUTOR_DISPLAY_SUBFIELDS = %w[a b c d j q u 3].freeze

    FACET_SOURCE_MAP = {
      100 => 'abcdjq', 110 => 'abcdjq', 111 => 'abcen',
      700 => 'abcdjq', 710 => 'abcdjq', 711 => 'abcen',
      800 => 'abcdjq', 810 => 'abcdjq', 811 => 'abcen'
    }.freeze

    class << self
      # Author/Creator search field, from tags
      # {https://www.oclc.org/bibformats/en/1xx/100.html 100 Main Entry--Personal Name} and
      # {https://www.oclc.org/bibformats/en/1xx/110.html 110 Main Entry--Corporate Name}. Includes subfield values
      # except for those in the {DISPLAY_EXCLUDED_SUBFIELDS} constant. Maps any relator codes found in ǂ4. To better
      # handle name searches, returns names as both "First Last" and "Last, First" if a comma is found in ǂa. Also
      # indexes any linked values in the 880.
      # @param record [MARC::Record]
      # @param relator_map [Hash]
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
      # theme to the 7xx fields but apply to serial records. Includes all subfield values except those in the
      # {SEARCH_EXCLUDED_SUBFIELDS} constant.
      # @param record [MARC::Record]
      # @return [Array<String>] array of extended author/creator values for indexing
      def search_aux(record, relator_map: Mappers.relator)
        name_search_values record: record, tags: AUX_TAGS, relator_map: relator_map
      end

      # Retrieve creator values for display from fields {https://www.loc.gov/marc/bibliographic/bd100.html 100},
      # {https://www.loc.gov/marc/bibliographic/bd110.html 110} and their linked alternates. First, join each subfield
      # value except for those defined in the {DISPLAY_EXCLUDED_SUBFIELDS} constant. Then, appends any encoded relators
      # found in $4. If there are no valid encoded relators, uses the value found in $e.
      # @param record [MARC::Record]
      # @return [Array<String>] array of author/creator values for display
      def show(record, relator_map: Mappers.relator)
        fields = record.fields(TAGS)
        fields += record.fields('880').select { |field| subfield_value?(field, '6', /^(#{TAGS.join('|')})/) }
        fields.filter_map { |field|
          parse_show_value(field, relator_map: relator_map)
        }.uniq
      end

      # Hash with main creator show values as the fields and the corresponding facet as the values.
      # Does not include linked 880s.
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @return [Hash]
      def show_facet_map(record, relator_map: Mappers.relator)
        creators = record.fields(TAGS).filter_map do |field|
          show = parse_show_value(field, relator_map: relator_map)
          facet = parse_facet_value(field, FACET_SOURCE_MAP[field.tag.to_i].chars)
          { show: show, facet: facet }
        end
        creators.to_h { |h| [h[:show], h[:facet]] }
      end

      # Returns the list of authors with name (subfield $a) only
      # @param record [MARC::Record]
      # @param main_tags_only [Boolean] only use TAGS; otherwise use both TAGS and CONTRIBUTOR_TAGS
      # @param first_initial_only [Boolean] only use the first initial instead of first name
      # @return [Array<String>] names of the authors
      def authors_list(record, main_tags_only: false, first_initial_only: false)
        fields = record.fields(main_tags_only ? TAGS : TAGS + CONTRIBUTOR_TAGS)
        fields.filter_map { |field|
          if field['a'].present?
            name = trim_trailing(:comma, field['a'])
            first_initial_only ? abbreviate_name(name) : name
          end
        }.uniq
      end

      # Show the authors and contributors grouped together by relators with only names
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @param include_authors [Boolean] include author fields TAGS
      # @param name_only [Boolean] include only the name subfield $a
      # @param vernacular [Boolean] include field 880 with subfield $6
      # @return [Hash]
      def contributors_list(record, relator_map: Mappers.relator, include_authors: true, name_only: true,
                            vernacular: false)
        indicator_2_options = ['', ' ', '0']
        tags = CONTRIBUTOR_TAGS

        fields = record.fields(tags)
        fields += record.fields('880').select { |field| subfield_value_in?(field, '6', CONTRIBUTOR_TAGS) } if vernacular

        contributors = {}
        fields.each do |field|
          next if indicator_2_options.exclude?(field.indicator2) && field.tag.in?(CONTRIBUTOR_TAGS)
          next if subfield_defined? field, 'i'

          relator = relator(field: field, relator_term_sf: 'e', relator_map: relator_map)
          relator = 'Contributor' if relator.blank?
          relator = trim_punctuation(relator).capitalize

          name = trim_trailing(:comma, field['a'])
          name = "#{name} #{join_subfields(field, &subfield_in?(%w[b c d j q u 3]))}, #{relator}" unless name_only

          if contributors.key?(relator)
            contributors[relator].push(name)
          else
            contributors[relator] = [name]
          end
        end

        # add the authors
        if include_authors
          authors = authors_list(record, main_tags_only: true)
          if contributors.key?('Author')
            contributors['Author'] += authors
          else
            contributors['Author'] = authors
          end
        end
        contributors
      end

      # All author/creator values for display (like #show, but multivalued?) - no 880 linkage
      # Performs additional normalization of author names
      # @note ported from get_author_creator_values (indexed as author_creator_a) - shown on results page
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @return [Array<String>] array of author/creator values for display
      def show_aux(record, relator_map: Mappers.relator)
        record.fields(TAGS).map { |field|
          name_from_main_entry(field, relator_map)
        }.uniq
      end

      # Author/Creator sort. Does not map or include any relator codes.
      # @todo This includes any URI from ǂ0 which could help to disambiguate in sorts, but ǂ1 is excluded...
      # @note ported from get_author_creator_sort_values
      # @param record [MARC::Record]
      # @return [String] string with author/creator value for sorting
      def sort(record)
        field = record.fields(TAGS).first
        join_subfields(field, &subfield_not_in?(%w[1 4 6 8 e]))
      end

      # Author/Creator for faceting. Grabs values from a plethora of fields, joins defined subfields, then trims some
      # punctuation (@see Util.trim_punctuation)
      # @todo should trim_punctuation apply to each subfield value, or the joined values? i think the joined values
      # @param record [MARC::Record]
      # @return [Array<String>] array of author/creator values for faceting
      def facet(record)
        FACET_SOURCE_MAP.flat_map { |field_num, subfields|
          record.fields(field_num.to_s).map do |field|
            parse_facet_value(field, subfields.chars)
          end
        }.uniq
      end

      # Conference for display, intended for results display
      # @note ported from get_conference_values
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @return [Array<String>] array of conference values
      def conference_show(record, relator_map: Mappers.relator)
        record.fields('111').filter_map { |field|
          name_from_main_entry field, relator_map
        }.uniq
      end

      # Conference detailed display, intended for record show page. Retrieve conference values for record display from
      # {https://www.loc.gov/marc/bibliographic/bd111.html 111}, {https://www.loc.gov/marc/bibliographic/bd711.html 711}
      # , and their linked 880s. If there is no $i, we join subfield $i we join subfield values other than
      # $0, $4, $5, $6, $8, $e, $j, and $w. to create the conference value. We then join the conference subunit value
      # using subfields $e and $w. We append any relators, preferring those defined in $4 and using $j as a fallback.
      # @note ported from get_conference_values
      # @todo what is ǂi for?
      # @param record [MARC::Record]
      # @return [Array<String>] array of conference values
      def conference_detail_show(record, relator_map: Mappers.relator)
        conferences = record.fields(%w[111 711]).filter_map do |field|
          next unless field.indicator2.in? ['', ' ']

          parse_conference_detail_show_value(field, relator_map: relator_map)
        end
        conferences += record.fields('880').filter_map do |field|
          next unless subfield_value? field, '6', /^(111|711)/

          next if subfield_defined? field, 'i'

          conf = join_subfields(field, &subfield_not_in?(%w[0 4 5 6 8 e j w]))
          sub_unit = join_subfields(field, &subfield_in?(%w[e w]))
          conf = [conf, sub_unit].compact_blank.join(' ')

          append_relator(field: field, joined_subfields: conf, relator_term_sf: 'j', relator_map: relator_map)
        end
        conferences.uniq
      end

      # Return hash of detailed conference values mapped to their corresponding facets from fields
      # {https://www.loc.gov/marc/bibliographic/bd111.html 111} and
      # {https://www.loc.gov/marc/bibliographic/bd711.html 711}. Does not include linked 880s.
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @return [Hash]
      def conference_detail_show_facet_map(record, relator_map: Mappers.relator)
        conferences = record.fields(%w[111 711]).filter_map do |field|
          next unless field.indicator2.in? ['', ' ']

          show = parse_conference_detail_show_value(field, relator_map: relator_map)
          facet = parse_facet_value(field, FACET_SOURCE_MAP[field.tag.to_i].chars)
          { show: show, facet: facet }
        end

        conferences.to_h { |conf| [conf[:show], conf[:facet]] }
      end

      # Conference name values for searching
      # @param record [MARC::Record]
      # @return [Array<String>]
      def conference_search(record)
        record.fields(CONFERENCE_SEARCH_TAGS).filter_map { |field|
          join_subfields(field, &subfield_in?(%w[a c d e]))
        }.uniq
      end

      # Corporate author search values for searching
      # @param record [MARC::Record]
      # @return [Array<String>]
      def corporate_search(record)
        record.fields(CORPORATE_SEARCH_TAGS).filter_map do |field|
          join_subfields(field, &subfield_in?(%w[a b c d]))
        end
      end

      # Retrieve contributor values for display from fields {https://www.oclc.org/bibformats/en/7xx/700.html 700}
      # and {https://www.oclc.org/bibformats/en/7xx/710.html 710} and their linked alternates. Joins subfields
      # defined in {CONTRIBUTOR_DISPLAY_SUBFIELDS}, then appends resulting string with any encoded relationships
      # found in $4. If there are no valid encoded relationships, uses the value found in $e.
      # @note legacy version returns array of hash objects including data for display link
      # @param record [MARC::Record]
      # @param relator_map [Hash]
      # @param name_only [Boolean]
      # @param vernacular [Boolean]
      # @return [Array<String>]
      def contributor_show(record, relator_map: Mappers.relator, name_only: false, vernacular: true)
        indicator_2_options = ['', ' ', '0']
        fields = record.fields(CONTRIBUTOR_TAGS)
        if vernacular
          fields += record.fields('880').select { |f| subfield_value?(f, '6', /^(#{CONTRIBUTOR_TAGS.join('|')})/) }
        end
        sf = name_only ? %w[a] : CONTRIBUTOR_DISPLAY_SUBFIELDS
        fields.filter_map { |field|
          next if indicator_2_options.exclude?(field.indicator2) && field.tag.in?(CONTRIBUTOR_TAGS)
          next if subfield_defined? field, 'i'

          contributor = join_subfields(field, &subfield_in?(sf))
          append_relator(field: field, joined_subfields: contributor, relator_term_sf: 'e', relator_map: relator_map)
        }.uniq
      end

      private

      # @param record [MARC::Record]
      # @param tags [Array] tags to consider
      # @param relator_map [Hash]
      # @return [Array<String>] name values from given tags
      def name_search_values(record:, tags:, relator_map:)
        acc = record.fields(tags).filter_map do |field|
          name_from_main_entry field, relator_map, should_convert_name_order: false, for_display: false
        end

        acc += record.fields(tags).filter_map do |field|
          name_from_main_entry field, relator_map, should_convert_name_order: true, for_display: false
        end

        acc += record.fields(['880']).filter_map do |field|
          next unless subfield_value?(field, '6', /^(#{tags.join('|')})/)

          suba = field.find_all(&subfield_in?(%w[a])).filter_map { |sf|
            convert_name_order(sf.value)
          }.first
          oth = join_and_squish(field.find_all(&subfield_not_in?(%w[6 8 a t])).map(&:value))
          join_and_squish [suba, oth]
        end

        acc.uniq
      end

      # Extract the information we care about from 1xx fields, map relator codes, and use appropriate punctuation
      # @param field [MARC::Field]
      # @param mapping [Hash]
      # @param should_convert_name_order [Boolean]
      # @param for_display [Boolean]
      # @return [String] joined subfield values for value from field
      def name_from_main_entry(field, mapping, should_convert_name_order: false, for_display: true)
        subfield_exclude_spec = for_display ? DISPLAY_EXCLUDED_SUBFIELDS : SEARCH_EXCLUDED_SUBFIELDS
        relator_term_sf = relator_term_subfield(field)
        name = field.filter_map { |sf|
          if sf.code == 'a'
            should_convert_name_order ? convert_name_order(sf.value) : trim_trailing(:comma, sf.value)
          elsif sf.code == relator_term_sf
            next
          elsif subfield_exclude_spec.exclude?(sf.code)
            sf.value
          end
        }.join(' ')

        name_and_relator = append_relator(field: field,
                                          joined_subfields: name,
                                          relator_term_sf: relator_term_sf,
                                          relator_map: mapping)

        return name_and_relator unless for_display

        name_and_relator + (%w[. -].member?(name_and_relator.last) ? '' : '.')
      end

      # Convert "Lastname, First" to "First Lastname"
      # @param name [String] value for processing
      # @return [String]
      def convert_name_order(name)
        name = trim_trailing(:comma, name)
        return name unless name.include? ','

        after_comma = join_and_squish([trim_trailing(:comma, substring_after(name, ', '))])
        before_comma = substring_before(name, ', ')
        "#{after_comma} #{before_comma}".squish
      end

      # Convert "Lastname, First" to "Lastname, F"
      # @param name [String]
      # @return [String]
      def abbreviate_name(name)
        name = trim_trailing(:comma, name)
        return name unless name.include? ','

        after_comma = join_and_squish([trim_trailing(:comma, substring_after(name, ','))])
        before_comma = substring_before(name, ',')
        abbrv = "#{before_comma},"
        abbrv += " #{after_comma.first.upcase}." if after_comma.present?
        abbrv
      end

      # Parse creator facet value from given creator field and desired subfields
      # @param field [MARC::Field]
      # @param subfields [Array<String>]
      # @return [String]
      def parse_facet_value(field, subfields)
        trim_punctuation(join_subfields(field, &subfield_in?(subfields)))
      end

      # Parse creator show value from given main creator fields (100/110).
      # @param field [MARC::Field]
      # @param relator_map [Hash]
      # @return [String]
      def parse_show_value(field, relator_map: Mappers.relator)
        creator = join_subfields(field, &subfield_not_in?(%w[0 1 4 6 8 e w]))
        append_relator(field: field, joined_subfields: creator, relator_term_sf: 'e', relator_map: relator_map)
      end

      # Parse detailed conference show value from given conference field (111/711). If there is no $i, we join subfield
      # values other than $0, $4, $5, $6, $8, $e, $j, and $w to create conference value. We join subfields $e and $w to
      # determine the subunit value. We append any relators, preferring those defined in $4 and using $j as a fallback.
      # @param field [MARC::Field]
      # @return [String]
      def parse_conference_detail_show_value(field, relator_map: Mappers.relator)
        conf = if subfield_undefined? field, 'i'
                 join_subfields field, &subfield_not_in?(%w[0 4 5 6 8 e j w])
               else
                 ''
               end
        sub_unit = join_subfields(field, &subfield_in?(%w[e w]))
        conf = [conf, sub_unit].compact_blank.join(' ')

        append_relator(field: field, joined_subfields: conf, relator_term_sf: 'j', relator_map: relator_map)
      end
    end
  end
end
