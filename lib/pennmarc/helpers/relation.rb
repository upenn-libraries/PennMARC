# frozen_string_literal: true

module PennMARC
  # Do Relation-y stuff
  class Relation < Helper
    class << self
      CHRONOLOGY_PREFIX = 'CHR'

      RELATED_WORK_FIELDS = %w[700 710 711 730].freeze
      CONTAINS_FIELDS = %w[700 710 711 730 740].freeze

      # Get values for "{https://www.oclc.org/bibformats/en/7xx/773.html Host Item}" for this record. Values contained
      # in this field should be sufficient to locate host item record.
      #
      # @param [MARC::Record] record
      # @return [Array] contained in values for display
      def contained_in_show(record)
        record.fields('773').map do |field|
          join_subfields(field, &subfield_not_in(%w[6 7 8 w]))
        end
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
      # @return [Object]
      def publications_about_show(record)
        datafield_and_linked_alternate(record, '581')
      end

      # @param [MARC::Record] record
      # @param [Hash] relator_map
      # @return [Object]
      def related_work_show(record, relator_map)
        values = record.fields(RELATED_WORK_FIELDS).filter_map do |field|
          next unless field.indicator2.blank?

          next unless subfield_defined?(field, 't')

          subi = remove_paren_value_from_subfield_i(field) || '' # TODO: PP ported this helper in Edition MR
          related_text = field.filter_map do |sf|
            if %w[0 4 i].exclude?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_map[sf.value]}"
            end
          end.join
          [subi, related_text].compact_blank.join(':')
        end
        values + record.fields('880').filter_map do |field|
          next unless field.indicator2.blank?

          next unless subfield_value?(field, '6', /^(#{RELATED_WORK_FIELDS.join('|')})/)

          next unless subfield_defined?(field, 't')

          subi = remove_paren_value_from_subfield_i(field) || ''
          related_text = field.filter_map do |sf|
            if %w[0 4 i].exclude?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_map[sf.value]}"
            end
          end.join
          [subi, related_text].compact_blank.join(':')
        end
      end

      # @param [MARC::Record] record
      # @return [Object]
      def contains_show(record)
        acc = []
        acc += record.fields(CONTAINS_FIELDS)
                     .select { |f| f.indicator2 == '2' }
                     .map do |field|
          subi = remove_paren_value_from_subfield_i(field) || ''
          contains = field.map do |sf|
            if !%w[0 4 5 6 8 i].member?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_codes[sf.value]}"
            end
          end.compact.join
          [subi, contains].select(&:present?).join(':')
        end
        acc += record.fields('880')
                     .select { |f| f.indicator2 == '2' }
                     .select { |f| has_subfield6_value(f, /^(#{CONTAINS_FIELDS.join('|')})/) }
                     .map do |field|
          subi = remove_paren_value_from_subfield_i(field) || ''
          contains = join_subfields(field, &subfield_not_in(%w[0 5 6 8 i]))
          [subi, contains].select(&:present?).join(':')
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def constituent_unit_show(record)
        acc = []
        acc += record.fields('774').map do |field|
          join_subfields(field, &subfield_in(%w[i a s t]))
        end.select(&:present?)
        acc += get_880(record, '774') do |sf|
          %w[i a s t].member?(sf.code)
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def has_supplement_show(record)
        acc = []
        acc += record.fields('770').map do |field|
          join_subfields(field, &subfield_not_6_or_8)
        end.select(&:present?)
        acc += get_880_subfield_not_6_or_8(record, '770')
        acc
      end
    end
  end
end
