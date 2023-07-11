# frozen_string_literal: true

module PennMARC
  # Extracts data related to a resource's production, distribution, manufacture, and publication.
  class Production < Helper
    class << self
      # Retrieve production values for display from {https://www.oclc.org/bibformats/en/2xx/264.html 264 field}.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record)
        get_264_or_880_fields(record, '0')
      end

      # Retrieve distribution values for display from {https://www.oclc.org/bibformats/en/2xx/264.html 264 field}.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def distribution_show(record)
        get_264_or_880_fields(record, '2')
      end

      # Retrieve manufacture values for display from {https://www.oclc.org/bibformats/en/2xx/264.html 264 field}.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def manufacture_show(record)
        get_264_or_880_fields(record, '3')
      end

      # Retrieve publication values. Return publication values from
      # {https://www.oclc.org/bibformats/en/2xx/264.html 264 field} only if none found
      # {https://www.oclc.org/bibformats/en/2xx/260.html 260}-262 fields.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def publication_values(record)
        # first get inclusive dates
        values = record.fields('245').first(1).flat_map { |field| subfield_values(field, 'f') }
        added_2xx = record.fields(%w[260 261 262])
                          .first(1)
                          .map do |field|
          join_subfields(field, &subfield_not_in?(['6'])).squish
        end

        if added_2xx.present?
          values += added_2xx
        else
          fields264 = record.fields('264')

          pub_place_name = fields264
                           .find(-> { [] }) { |field| field.indicator2 == '1' }
                           .filter_map { |sf| sf.value if sf.code.in?(%w[a b]) }

          pub_date = fields264
                     .find(-> { [] }) { |field| field.indicator2 == '1' }
                     .filter_map { |sf| sf.value if sf.code.in?(['c']) }

          copyright_date = fields264
                           .find(-> { [] }) { |field| field.indicator2 == '4' }
                           .filter_map { |sf| "#{pub_date.present? ? ', ' : ''}#{sf.value}" if sf.code.in?(['c']) }

          joined264 = Array.wrap((pub_place_name + pub_date + copyright_date).join(' '))

          values += joined264
        end
        values.filter_map { |value| value&.strip }
      end

      # Retrieve publication values for display from fields
      # {https://www.oclc.org/bibformats/en/2xx/245.html 245},
      # {https://www.oclc.org/bibformats/en/2xx/260.html 260}-262, and their linked alternates,
      # and {https://www.oclc.org/bibformats/en/2xx/264.html 264} and its linked alternate.
      # @param [MARC::Record] record
      # @return [Object]
      def publication_show(record)
        values = record.fields('245').first(1).flat_map { |field| subfield_values(field, 'f') }

        values += record.fields(%w[260 261 262]).first(1).map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end

        values += record.fields('880').filter_map { |field| field if subfield_value?(field, '6', /^(260|261|262)/) }
                        .first(1).map { |field| join_subfields(field, &subfield_not_in?(%w[6 8])) }

        values += record.fields('880').filter_map do |field|
          next unless subfield_value?(field, '6', /^245/)

          join_subfields(field, &subfield_in?(['f']))
        end

        values += get_264_or_880_fields(record, '1')
        values.compact_blank
      end

      # Retrieve place of publication for display from {https://www.oclc.org/bibformats/en/7xx/752.html 752 field} and
      # its linked alternate.
      # @note legacy version returns array of hash objects including data for display link
      # @param [MARC::Record] record
      # @return [Object]
      def place_of_publication_show(record)
        record.fields(%w[752 880]).filter_map do |field|
          next if field.tag == '880' && subfield_values(field, '6').exclude?('752')

          place = join_subfields(field, &subfield_not_in?(%w[6 8 e w]))
          place_extra = join_subfields(field, &subfield_in?(%w[e w]))
          "#{place} #{place_extra}"
        end
      end

      private

      # base method to retrieve production values from {https://www.oclc.org/bibformats/en/2xx/264.html 264 field} based
      # on indicator2.
      # distribution and manufacture share the same logic except for indicator2
      # @param [MARC::Record] record
      # @param [String] indicator2
      # @return [Array<String>]
      def get_264_or_880_fields(record, indicator2)
        values = record.fields('264').filter_map do |field|
          next unless field.indicator2 == indicator2

          join_subfields(field, &subfield_in?(%w[a b c]))
        end
        values + record.fields('880').filter_map do |field|
          next unless field.indicator2 == indicator2

          next unless subfield_value?(field, '6', /^264/)

          join_subfields(field, &subfield_in?(%w[a b c]))
        end
      end
    end
  end
end
