# frozen_string_literal: true

module PennMARC
  # Logic for extracting and translating Language values for a record. Penn practice is to verify the value present in
  # the {https://www.oclc.org/bibformats/en/fixedfield/lang.html 008 control field} as a three letter code. This code
  # is then mapped to a display-friendly value using the a provided mapping hash.
  # @todo should we consider values in the {https://www.oclc.org/bibformats/en/0xx/041.html 041 field}?
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

      # @note In franklin, we extracted the language code from the 008 control field. After engaging cataloging unit
      #   representatives, we decided to extract these values from the 041 field: Includes records for multilingual
      #   items, items that involve translation, and items where the medium of communication is a sign language.
      #   https://www.loc.gov/marc/bibliographic/bd041.html
      #
      # Get language values for searching and faceting of a record. The values are extracted from subfields
      # in the 041 field. Language facet and search values will typically be the same, with the exception of `zxx`,
      # when no linguistic content is found.
      #
      # @param [MARC::Record] record
      # @param [Hash] language_map hash for language code translation
      # @return [Array] array of language values
      def search(record, language_map: Mappers.language)
        values = record['041']&.filter_map { |sf|
          next if LANGUAGE_SUBFIELDS.exclude?(sf.code)

          language_map[sf.value.to_sym]
        } || []
        control_field = record['008']&.value
        if control_field.present?
          language_code = control_field[35..37]
          values << language_map[language_code.to_sym || UNDETERMINED_CODE]
        end
        values.empty? ? values << UNDETERMINED_CODE : values.uniq
      end
    end
  end
end
