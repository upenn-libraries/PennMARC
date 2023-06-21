# frozen_string_literal: true

module PennMARC
  # Get fields from the {https://www.oclc.org/bibformats/en/2xx/264.html 264 field}
  class Production < Helper
    class << self
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record)
        get_264_or_880_fields(record, '0')
      end

      # @param [MARC::Record] record
      # @return [Array<String>]
      def distribution_show(record)
        get_264_or_880_fields(record, '2')
      end

      # @param [MARC::Record] record
      # @return [Array<String>]
      def manufacture_show(record)
        get_264_or_880_fields(record, '3')
      end

      def publication_values(record)
        acc = []
        record.fields('245').each do |field|
          field.find_all { |sf| sf.code == 'f' }
               .map(&:value)
               .each { |value| acc << value }
        end
        added_2xx = false
        record.fields(%w[260 261 262]).take(1).each do |field|
          results = field.find_all { |sf| sf.code != '6' }
                         .map(&:value)
          acc << join_and_trim_whitespace(results)
          added_2xx = true
        end
        unless added_2xx
          sf_ab264 = record.fields.select { |field| field.tag == '264' && field.indicator2 == '1' }
                           .take(1)
                           .flat_map do |field|
            field.find_all(&subfield_in(%w[a b])).map(&:value)
          end

          sf_c264_1 = record.fields.select { |field| field.tag == '264' && field.indicator2 == '1' }
                            .take(1)
                            .flat_map do |field|
            field.find_all(&subfield_in(['c']))
                 .map(&:value)
          end

          sf_c264_4 = record.fields.select { |field| field.tag == '264' && field.indicator2 == '4' }
                            .take(1)
                            .flat_map do |field|
            field.find_all { |sf| sf.code == 'c' }
                 .map { |sf| (sf_c264_1.present? ? ', ' : '') + sf.value }
          end

          acc << [sf_ab264, sf_c264_1, sf_c264_4].join(' ')
        end
        acc.map!(&:strip).select!(&:present?)
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def publication_show(record)
        acc = []
        record.fields('245').take(1).each do |field|
          field.find_all { |sf| sf.code == 'f' }
               .map(&:value)
               .each { |value| acc << value }
        end
        record.fields(%w[260 261 262]).take(1).each do |field|
          acc << join_subfields(field, &subfield_not_6_or_8)
        end
        record.fields('880')
              .select { |f| has_subfield6_value(f, /^(260|261|262)/) }
              .take(1)
              .each do |field|
          acc << join_subfields(field, &subfield_not_6_or_8)
        end
        record.fields('880')
              .select { |f| has_subfield6_value(f, /^245/) }
              .each do |field|
          acc << join_subfields(field, &subfield_in(['f']))
        end
        acc += get_264_or_880_fields(record, '1')
        acc.select(&:present?)
      end

      # @param [MARC::Record] record
      # @return [Object]
      def place_of_publication_show(record)
        acc = []
        acc += record.fields('752').map do |field|
          place = join_subfields(field, &subfield_not_in(%w[6 8 e w]))
          place_extra = join_subfields(field, &subfield_in(%w[e w]))
          { value: place, value_append: place_extra, link_type: 'search' }
        end
        acc += get_880_subfield_not_6_or_8(record, '752').map do |result|
          { value: result, link: false }
        end
        acc
      end

      private

      # distribution and manufacture share the same logic except for indicator2
      # @param [MARC::Record] record
      # @param [String] indicator2
      # @return [Array<String>]
      def get_264_or_880_fields(record, indicator2)
        acc = record.fields('264').filter_map do |field|
          next unless field.indicator2 == indicator2

          join_subfields(field, &subfield_in(%w[a b c]))
        end
        acc + record.fields('880').filter_map do |field|
          next unless field.indicator2 == indicator2

          next unless has_subfield6_value(field, /^264/)

          join_subfields(field, &subfield_in(%w[a b c]))
        end
      end
    end
  end
end
