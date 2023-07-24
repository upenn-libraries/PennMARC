# frozen_string_literal: true

module PennMARC
  # Do Edition and edition-related field processing.
  class Edition < Helper
    class << self
      # Edition values for display on a record page. Field 250 is information relating to the edition of a work as
      # determined by applicable cataloging rules. For mixed materials, field 250 is used to record statements relating
      # to collections that contain versions of works existing in two or more versions (or states) in single or multiple
      # copies (e.g., different drafts of a film script). For continuing resources, this field is not used for
      # sequential edition statements such as 1st- ed. This type of information is contained in field 362 (Dates of
      # Publication and/or Volume Designation).
      # https://www.loc.gov/marc/bibliographic/bd250.html
      # @param [MARC::Record] record
      # @return [Array<String>] array of editions and their alternates
      def show(record)
        record.fields('250').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end + linked_alternate_not_6_or_8(record, '250')
      end

      # Edition values for display in search results. Just grab the first 250 field.
      # @param [MARC::Record] record
      # @return [String, NilClass] string of all first 250 subfields, excluding 6 and 8
      def values(record)
        edition = record.fields('250').first
        return unless edition.present?

        join_subfields(edition, &subfield_not_in?(%w[6 8]))
      end

      # Entry for another available edition of the target item (horizontal relationship). When a note is generated
      # from this field, the introductory phrase Other editions available: may be generated based on the field tag for
      # display.
      # https://www.loc.gov/marc/bibliographic/bd775.html
      # @param [MARC::Record] record
      # @return [Array<String>] array of other edition strings
      def other_show(record, relator_mapping)
        record.fields('775').filter_map do |field|
          next unless subfield_defined?(field, :i)

          other_edition_value(field, relator_mapping)
        end + record.fields('880').filter_map do |field|
          next unless field.indicator2.blank? && subfield_value_in?(field, '6', %w[775]) &&
                      subfield_defined?(field, 'i')

          other_edition_value(field, relator_mapping)
        end
      end

      private

      # Assemble a string of relevant edition information.
      # @param [MARC::DataField] field
      # @param [Hash] relator_mapping
      # @return [String (frozen)] assembled other version string
      def other_edition_value(field, relator_mapping)
        subi = remove_paren_value_from_subfield_i(field) || ''
        other_editions = field.filter_map do |sf|
          next if %w[6 8].member?(sf.code)

          if %w[s x z].member?(sf.code)
            " #{sf.value}"
          elsif sf.code == 't'
            relator = translate_relator(sf.value, relator_mapping)
            next if relator.blank?

            " #{relator}. "
          end
        end.join
        other_editions_append = field.filter_map do |sf|
          next if %w[6 8].member?(sf.code)

          if %w[i h s t x z e f o r w y 7].exclude?(sf.code)
            " #{sf.value}"
          elsif sf.code == 'h'
            " (#{sf.value}) "
          end
        end.join
        prepend = trim_trailing(:period, subi).squish

        if other_editions.present? || other_editions_append.present?
          "#{prepend}: #{other_editions} #{other_editions_append}".squish
        else
          prepend
        end
      end
    end
  end
end
