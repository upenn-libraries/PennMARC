# frozen_string_literal: true

module PennMARC
  # Do Relation-y stuff
  class Relation < Helper
    class << self
      # @param [MARC::Record] record
      # @return [Object]
      def contained_in_show(record)
        record.fields('773').map do |field|
          results = field.find_all(&subfield_not_in(%w[6 7 8 w])).map(&:value)
          join_and_trim_whitespace(results)
        end
      end

      # @param [MARC::Record] record
      # @return [Object]
      def chronology_show(record); end

      # @param [MARC::Record] record
      # @return [Object]
      def related_collections_show(record); end

      # @param [MARC::Record] record
      # @return [Object]
      def publications_about_show(record); end

      # @param [MARC::Record] record
      # @return [Object]
      def related_work_show(record)
        acc = []
        acc += record.fields(%w[700 710 711 730])
                     .select { |f| ['', ' '].member?(f.indicator2) }
                     .select { |f| f.any? { |sf| sf.code == 't' } }
                     .map do |field|
          subi = remove_paren_value_from_subfield_i(field) || ''
          related = field.map do |sf|
            if !%w[0 4 i].member?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_codes[sf.value]}"
            end
          end.compact.join
          [subi, related].select(&:present?).join(':')
        end
        acc += record.fields('880')
                     .select { |f| ['', ' '].member?(f.indicator2) }
                     .select { |f| has_subfield6_value(f, /^(700|710|711|730)/) }
                     .select { |f| f.any? { |sf| sf.code == 't' } }
                     .map do |field|
          subi = remove_paren_value_from_subfield_i(field) || ''
          related = field.map do |sf|
            if !%w[0 4 i].member?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_codes[sf.value]}"
            end
          end.compact.join
          [subi, related].select(&:present?).join(':')
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def contains_show(record)
        acc = []
        acc += record.fields(%w[700 710 711 730 740])
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
                     .select { |f| has_subfield6_value(f, /^(700|710|711|730|740)/) }
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
