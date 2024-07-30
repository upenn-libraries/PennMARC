# frozen_string_literal: true

module PennMARC
  # Extracts data related to a resource's production, distribution, manufacture, and publication.
  class Production < Helper
    class << self
      # Retrieve production values for display from {https://www.loc.gov/marc/bibliographic/bd264.html 264 field}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def show(record)
        get_264_or_880_fields(record, '0').uniq
      end

      # Retrieve production values for searching. Includes only
      # {https://www.loc.gov/marc/bibliographic/bd260.html 260} and
      # {https://www.loc.gov/marc/bibliographic/bd264.html 264}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def search(record)
        values = record.fields('260').filter_map do |field|
          join_subfields(field, &subfield_in?(['b']))
        end
        values + record.fields('264').filter_map { |field|
          next unless field.indicator2 == '1'

          join_subfields(field, &subfield_in?(['b']))
        }.uniq
      end

      # Retrieve distribution values for display from {https://www.loc.gov/marc/bibliographic/bd264.html 264 field}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def distribution_show(record)
        get_264_or_880_fields(record, '2').uniq
      end

      # Retrieve manufacture values for display from {https://www.loc.gov/marc/bibliographic/bd264.html 264 field}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def manufacture_show(record)
        get_264_or_880_fields(record, '3').uniq
      end

      # Retrieve publication values. Return publication values from
      # {https://www.loc.gov/marc/bibliographic/bd264.html 264 field} only if none found
      # {https://www.loc.gov/marc/bibliographic/bd260.html 260}-262 fields.
      # @param record [MARC::Record]
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
        values.filter_map { |value| value&.strip }.uniq
      end

      # Retrieve publication values for display from fields
      # {https://www.loc.gov/marc/bibliographic/bd245.html 245},
      # {https://www.loc.gov/marc/bibliographic/bd260.html 260}-262 and their linked alternates,
      # and {https://www.loc.gov/marc/bibliographic/bd264.html 264} and its linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
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
        values.compact_blank.uniq
      end

      # Retrieve publication values for citation
      # {https://www.loc.gov/marc/bibliographic/bd245.html 245},
      # {https://www.loc.gov/marc/bibliographic/bd260.html 260}-262 and their linked alternates,
      # and {https://www.loc.gov/marc/bibliographic/bd264.html 264} and its linked alternate.
      # @param record [MARC::Record]
      # @param with_year [Boolean] return results with publication year if true
      # @return [Array<String>]
      def publication_citation_show(record, with_year: true)
        values = record.fields('245').first(1).flat_map { |field| subfield_values(field, 'f') }

        subfields = with_year ? %w[6 8] : %w[6 8 c]
        values += record.fields(%w[260 261 262]).first(1).map do |field|
          join_subfields(field, &subfield_not_in?(subfields))
        end

        subfields = with_year ? %w[a b c] : %w[a b]
        values += record.fields('264').filter_map do |field|
          next unless field.indicator2 == '1'

          join_subfields(field, &subfield_in?(subfields))
        end

        values.compact_blank.uniq
      end

      # Returns the place of publication for RIS
      # @param record [MARC::Record]
      # @return [Array<String>]
      def publication_ris_place_of_pub(record)
        get_publication_ris_values(record, 'a')
      end

      # Returns the publisher for RIS
      # @param record [MARC::Record]
      # @return [Array<String>]
      def publication_ris_publisher(record)
        get_publication_ris_values(record, 'b')
      end

      # Retrieve place of publication for display from {https://www.loc.gov/marc/bibliographic/bd752.html 752 field} and
      # its linked alternate.
      # @note legacy version returns array of hash objects including data for display link
      # @param record [MARC::Record]
      # @return [Array<String>]
      def place_of_publication_show(record)
        record.fields(%w[752 880]).filter_map { |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^752/)

          place = join_subfields(field, &subfield_not_in?(%w[6 8 e w]))
          place_extra = join_subfields(field, &subfield_in?(%w[e w]))
          "#{place} #{place_extra}"
        }.uniq
      end

      # Retrieves place of publication values for searching. Includes
      # {https://www.loc.gov/marc/bibliographic/bd752.html 752} as well as sf a from
      # {https://www.loc.gov/marc/bibliographic/bd260.html 260} and
      # {https://www.loc.gov/marc/bibliographic/bd264.html 264} with an indicator2 of 1.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def place_of_publication_search(record)
        values = record.fields('260').filter_map do |field|
          join_subfields(field, &subfield_in?(['a']))
        end
        values += record.fields('264').filter_map do |field|
          next unless field.indicator2 == '1'

          join_subfields(field, &subfield_in?(['a']))
        end
        values + record.fields('752').filter_map { |field|
          join_subfields(field, &subfield_in?(%w[a b c d f g h]))
        }.uniq
      end

      private

      # base method to retrieve production values from {https://www.loc.gov/marc/bibliographic/bd264.html 264 field}
      # based on indicator2. "Distribution" and "manufacture" share the same logic except for indicator2.
      # @param record [MARC::Record]
      # @param indicator2 [String]
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

      # Returns the publication value of the given subfield
      # @param record [MARC::Record]
      # @param subfield [String]
      # @return [Array<String>]
      def get_publication_ris_values(record, subfield)
        values = record.fields('245').first(1).flat_map { |field| subfield_values(field, 'f') }

        values += record.fields(%w[260 261 262]).first(1).map do |field|
          join_subfields(field, &subfield_in?([subfield]))
        end

        values += record.fields('264').filter_map do |field|
          next unless field.indicator2 == '1'

          join_subfields(field, &subfield_in?([subfield]))
        end

        values.compact_blank.uniq
      end
    end
  end
end
