# frozen_string_literal: true

module PennMARC
  # Genre field values come from the {https://www.oclc.org/bibformats/en/6xx/655.html 655}, but for some
  # contexts we are only interested in a subset of the declared terms in a record. Some configuration/values
  # in this helper will be shared with the Subject helper.
  class Genre < Helper
    class << self
      # Genre values for searching
      #
      # @param [MARC::Record] record
      # @return [Array]
      def search(record)
        record.fields('655').map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 2 5 c]))
        end
      end

      # Genre values for display. We display Genre/Term values if they fulfill the following criteria:
      #  - The field is in {https://www.oclc.org/bibformats/en/6xx/655.html MARC 655}. Or the field is in MARC 880 with
      #    subfield 6 including '655'.
      #   AND
      #    - Above fields have an indicator 2 value of: 0 (LSCH) or 4 (No source specified).
      #     OR
      #    - Above fields have a subfield 2 (ontology code) in the list of allowed values.
      #
      # @note legacy method returns a link object
      # @param [MARC::Record] record
      # @return [Array]
      def show(record)
        record.fields(%w[655 880]).filter_map do |field|
          next unless field.indicator2.in?(%w[0 4]) ||
                      subfield_value_in?(field, '2', PennMARC::HeadingControl::ALLOWED_SOURCE_CODES)

          next if field.tag == '880' && subfield_values(field, '6').exclude?('655')

          sub_with_hyphens = field.find_all(&subfield_not_in?(%w[0 2 5 6 8 c e w])).map do |sf|
            sep = %w[a b].exclude?(sf.code) ? ' -- ' : ' '
            sep + sf.value
          end.join.lstrip
          # TODO: what is w??
          eandw_with_hyphens = field.find_all(&subfield_in?(%w[e w])).join(' -- ')
          "#{sub_with_hyphens} #{eandw_with_hyphens}".strip
        end
      end

      # Genre values for faceting. We only set Genre facet values for movies (videos) and manuscripts(?)
      # @todo the Genre facet in Franklin is pretty ugly. It could be cleaned up by limiting the subfields included
      #       here and cleaning up punctuation.
      # @param [MARC::Record] record
      # @param [Hash] location_map
      # @return [Array]
      def facet(record, location_map)
        locations = Location.location record: record, location_map: location_map, display_value: :specific_location
        manuscript = Format.include_manuscripts?(locations)
        video = record.fields('007').any? { |field| field.value.starts_with? 'v' }
        return [] unless manuscript || video

        record.fields('655').filter_map do |field|
          join_subfields field, &subfield_not_in?(%w[0 2 5 c])
        end
      end
    end
  end
end
