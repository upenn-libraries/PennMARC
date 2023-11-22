# frozen_string_literal: true

module PennMARC
  # Logic for extracting and translating Language values for a record. Penn practice is to verify the value present in
  # the {https://www.oclc.org/bibformats/en/fixedfield/lang.html 008 control field} as a three letter code. This code
  # is then mapped to a display-friendly value using the a provided mapping hash.
  class Language < Helper
    # Used when no value is present in the control field - still mapped
    UNDETERMINED_CODE = :und
    LANGUAGE_SUBFIELDS = %w[a b d e g h i j k m n p q r t].freeze

    class << self
      # Get language values for display from the {https://www.oclc.org/bibformats/en/5xx/546.html 546 field} and
      # related 880.
      # @param [MARC::Record] record
      # @return [Array<String>] language values and notes
      def show(record)
        values = record.fields('546').map do |field|
          join_subfields field, &subfield_not_in?(%w[6 8])
        end
        values + linked_alternate(record, '546', &subfield_not_in?(%w[6 8]))
      end

      # Get language values for searching and faceting of a record. The values are extracted from subfields
      # in the 041 field. Language facet and search values will typically be the same, with the exception of `zxx`,
      # when no linguistic content is found.
      #
      # @note In franklin, we extracted the language code from the 008 control field. After engaging cataloging unit
      #   representatives, we decided to also extract these values from the 041 field: Includes records for
      #   multilingual items, items that involve translation, and items where the medium of communication is a sign
      #   language. https://www.loc.gov/marc/bibliographic/bd041.html
      #
      # @param [MARC::Record] record
      # @param [Hash] iso_639_2_mapping iso-639-2 spec hash for language code translation
      # @param [Hash] iso_639_3_mapping iso-639-3 spec hash for language code translation
      # @return [Array] array of language values
      def values(record, iso_639_2_mapping: Mappers.iso_639_2_language, iso_639_3_mapping: Mappers.iso_639_3_language)
        values = record.fields('041').filter_map { |field|
          mapper = subfield_value?(field, '2', /iso639-3/) ? iso_639_3_mapping : iso_639_2_mapping
          field.filter_map do |sf|
            next unless LANGUAGE_SUBFIELDS.include? sf.code

            mapper[sf.value&.to_sym]
          end
        }.flatten
        control_field = record['008']&.value
        values << iso_639_2_mapping[control_field[35..37]&.to_sym] if control_field.present?
        values.empty? ? values << iso_639_2_mapping[UNDETERMINED_CODE] : values.uniq
      end
    end
  end
end
