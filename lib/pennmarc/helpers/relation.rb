# frozen_string_literal: true

module PennMARC
  # These MARC parsing method are grouped in virtue of their role as describing the relationship of a record to other
  # records.
  class Relation < Helper
    class << self
      CHRONOLOGY_PREFIX = 'CHR'

      RELATED_WORK_FIELDS = %w[700 710 711 730].freeze
      CONTAINS_FIELDS = %w[700 710 711 730 740].freeze

      # Get values for "{https://www.oclc.org/bibformats/en/7xx/773.html Host Item}" for this record. Values contained
      # in this field should be sufficient to locate host item record.
      #
      # @param [MARC::Record] record
      # @return [Array<String>] contained in values for display
      def contained_in_show(record)
        record.fields('773').map { |field|
          join_subfields(field, &subfield_not_in?(%w[6 7 8 w]))
        }.uniq
      end

      # Get "chronology" information from specially-prefixed 650 (subject) fields
      # @todo why do we stuff chronology data in a 650 field?
      # @param [MARC::Record] record
      # @return [Array] array of chronology values
      def chronology_show(record)
        prefixed_subject_and_alternate(record, CHRONOLOGY_PREFIX)
      end

      # Get notes for Related Collections from {https://www.oclc.org/bibformats/en/5xx/544.html MARC 544}.
      # @param [MARC::Record] record
      # @return [Array]
      def related_collections_show(record)
        datafield_and_linked_alternate(record, '544')
      end

      # Get notes for "Publication About" from {https://www.oclc.org/bibformats/en/5xx/581.html MARC 581}.
      # @param [MARC::Record] record
      # @return [Array]
      def publications_about_show(record)
        datafield_and_linked_alternate(record, '581')
      end

      # Get related work from {RELATED_WORK_FIELDS} in the 7XX range. Require presence of sf t (title) and absence of
      # an indicator2 value. Prefix returned values with sf i value. Also map relator codes found in sf 4. Ignore sf 0.
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array]
      def related_work_show(record, relator_map: Mappers.relator)
        fields = record.fields(RELATED_WORK_FIELDS)
        fields += record.fields('880').select { |f| subfield_value?(f, '6', /^(#{RELATED_WORK_FIELDS.join('|')})/) }
        fields.filter_map { |field|
          next if field.indicator2.present?

          next unless subfield_defined?(field, 't')

          relator_term_sf = relator_term_subfield(field)

          sf_exclude = %w[0 4 6 8 i] << relator_term_sf

          values_with_title_prefix(field,
                                   relator_term_sf: relator_term_sf,
                                   relator_map: relator_map,
                                   &subfield_not_in?(sf_exclude))
        }.uniq
      end

      # Get "Contains" values from {CONTAINS_FIELDS} in the 7XX range. Must have indicator 2 value of 2 indicating an
      # "Analytical Entry" meaning that the record is contained by the matching field. Map relator codes in sf 4. Ignore
      # values in sf 0, 5, 6, and 8.
      # @todo is it okay to include 880 $4 here? Legacy includes untranslated $4, why?
      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Array<String>]
      def contains_show(record, relator_map: Mappers.relator)
        fields = record.fields(CONTAINS_FIELDS)
        fields += record.fields('880').select { |f| subfield_value?(f, '6', /^(#{CONTAINS_FIELDS.join('|')})/) }
        fields.filter_map { |field|
          next unless field.indicator2 == '2'

          relator_term_sf = relator_term_subfield(field)

          sf_exclude = %w[0 4 5 6 8 i] << relator_term_sf

          values_with_title_prefix(field,
                                   relator_term_sf: relator_term_sf,
                                   relator_map: relator_map,
                                   &subfield_not_in?(sf_exclude))
        }.uniq
      end

      # Get "Constituent Unit" values from {https://www.oclc.org/bibformats/en/7xx/774.html MARC 774}. Include
      # subfield values in i, a, s and t.
      # @param [MARC::Record] record
      # @return [Array]
      def constituent_unit_show(record)
        values = record.fields('774').filter_map do |field|
          join_subfields(field, &subfield_in?(%w[i a s t]))
        end
        constituent_values = values + linked_alternate(record, '774', &subfield_in?(%w[i a s t]))
        constituent_values.uniq
      end

      # Get "Has Supplement" values from {https://www.oclc.org/bibformats/en/7xx/770.html MARC 770}. Ignore
      # subfield values in 6 and 8.
      # @param [MARC::Record] record
      # @return [Array]
      def has_supplement_show(record)
        datafield_and_linked_alternate(record, '770')
      end

      private

      # Handle common behavior when a relator field references a title in subfield i
      # @param [MARC::DataField] field
      # @param [String, nil] relator_term_sf subfield that holds relator term
      # @param [Hash, nil] relator_map map relator in sf4 using this map, optional
      # @param [Proc] join_selector
      # @return [String] extracted and processed values from field
      def values_with_title_prefix(field, relator_term_sf: nil, relator_map: nil, &join_selector)
        subi = remove_paren_value_from_subfield_i(field) || ''

        title = join_subfields(field, &join_selector)

        title_with_relator = append_relator(field: field,
                                            joined_subfields: title,
                                            relator_term_sf: relator_term_sf,
                                            relator_map: relator_map)

        [subi, title_with_relator].compact_blank.join(': ')
      end
    end
  end
end
