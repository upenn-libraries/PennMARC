# frozen_string_literal: true

module PennMARC
  # Genre field values come from the {https://www.oclc.org/bibformats/en/6xx/655.html 655}, but for some
  # contexts we are only interested in a subset of the declared terms in a record.
  class Genre < Helper
    class << self
      # Genre values for searching. We're less picky about what is included here to enable discovery via any included
      # 655 data.
      #
      # @param [MARC::Record] record
      # @return [Array<String>] array of genre values for search
      def search(record)
        record.fields('655').map { |field|
          join_subfields(field, &subfield_not_in?(%w[0 2 5 c]))
        }.uniq
      end

      # Genre values for display. We display Genre/Term values if they fulfill the following criteria:
      #  - The field is in {https://www.oclc.org/bibformats/en/6xx/655.html MARC 655}. Or the field is in MARC 880 with
      #    subfield 6 including '655'.
      #   AND
      #    - Above fields have an indicator 2 value of: 0 (LSCH) or 4 (No source specified).
      #     OR
      #    - Above fields have a subfield 2 (ontology code) in the list of allowed values.
      # @todo subfields e and w do not appear in the documentation for 655, but we give them special consideration here,
      #       what gives?
      # @note legacy method returns a link object
      # @param [MARC::Record] record
      # @return [Array<String>] array of genre values for display
      def show(record)
        record.fields(%w[655 880]).filter_map { |field|
          next unless allowed_genre_field?(field)

          next if field.tag == '880' && subfield_values(field, '6').exclude?('655')

          subfields = %w[a b]
          sub_with_hyphens = field.find_all(&subfield_not_in?(%w[0 2 5 6 8 c e w])).map { |sf|
            sep = subfields.exclude?(sf.code) ? ' -- ' : ' '
            sep + sf.value
          }.join.lstrip
          "#{sub_with_hyphens} #{field.find_all(&subfield_in?(%w[e w])).join(' -- ')}".strip
        }.uniq
      end

      # Genre values for faceting. We only set Genre facet values for movies (videos) and manuscripts(?)
      # @todo the Genre facet in Franklin is pretty ugly. It could be cleaned up by limiting the subfields included
      #       here and cleaning up punctuation.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def facet(record)
        format_code = record.leader[6] || ' '
        manuscript = Format.include_manuscripts?(format_code)
        video = record.fields('007').any? { |field| field.value.starts_with? 'v' }
        return [] unless manuscript || video

        record.fields('655').filter_map { |field|
          join_subfields field, &subfield_not_in?(%w[0 2 5 c])
        }.uniq
      end

      private

      # @param [MARC::DataField] field
      # @return [TrueClass, FalseClass]
      def allowed_genre_field?(field)
        field.indicator2.in?(%w[0 4]) || subfield_value_in?(field, '2', PennMARC::HeadingControl::ALLOWED_SOURCE_CODES)
      end
    end
  end
end
