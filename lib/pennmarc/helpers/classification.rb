# frozen_string_literal: true

module PennMARC
  # Generates library of congress and dewey classifications using call number data.
  class Classification < Helper
    # Subfield value that identifies Library of Congress call number
    LOC_CALL_NUMBER_TYPE = '0'

    # Subfield value that identifies Dewey call number
    DEWEY_CALL_NUMBER_TYPE = '1'

    # Hash that maps call number type to the appropriate mapper
    CLASSIFICATION_MAPS = {
      LOC_CALL_NUMBER_TYPE => Mappers.loc_classification,
      DEWEY_CALL_NUMBER_TYPE => Mappers.dewey_classification
    }.freeze

    # Enriched MARC tags that hold classification data
    TAGS = [Enriched::Pub::ITEM_TAG, Enriched::Api::PHYS_INVENTORY_TAG].freeze

    class << self
      # Parse classification values for faceting. We retrieve classification values from enriched MARC fields 'itm' or
      # 'AVA' originating respectively from the Alma publishing process or from the Alma Api. We return the
      # highest level LOC or Dewey classifications from each available call number, joining the class code with
      # its title in a single string. See {PennMARC::Enriched} and {PennMARC::Enriched::Api} for more
      # information on the enriched MARC fields.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/ AVA docs
      # @param record [MARC::Record]
      # @return [Array<String>] array of classifications
      def facet(record)
        record.fields(TAGS).flat_map { |field|
          call_number_type = subfield_values(field, call_number_type_sf(field))&.first
          call_numbers = subfield_values(field, call_number_sf(field))

          call_numbers.filter_map do |call_number|
            class_code = call_number[0]
            title = translate_classification(class_code, call_number_type)
            next if title.blank?

            format_facet(class_code, call_number_type, title)
          end
        }.uniq
      end

      private

      # Retrieve subfield code that stores the call number on enriched marc field
      # @param field [MARC::DataField]
      # @return [String]
      def call_number_sf(field)
        return Enriched::Pub::ITEM_CALL_NUMBER if field.tag == Enriched::Pub::ITEM_TAG

        Enriched::Api::PHYS_CALL_NUMBER
      end

      # Retrieve subfield code that stores call number type on enriched marc field
      # @param field [MARC::DataField]
      # @return [String]
      def call_number_type_sf(field)
        return Enriched::Pub::ITEM_CALL_NUMBER_TYPE if field.tag == Enriched::Pub::ITEM_TAG

        Enriched::Api::PHYS_CALL_NUMBER_TYPE
      end

      # retrieve title of classification based on single char classification code and call number type
      # @param class_code [String] classification code
      # @param call_number_type [String] value from call number type subfield
      # @return [String, nil]
      def translate_classification(class_code, call_number_type)
        map = CLASSIFICATION_MAPS[call_number_type]

        return if map.blank?

        translate_relator(class_code, map)
      end

      # format classification facet by joining single character classification code with its corresponding title.
      # Our Dewey mapping codes are single digit, so we must concatenate '00' to the class code to accurately reflect
      # Dewey class codes.
      # @param [String] class_code
      # @param [String] call_number_type
      # @param [String] title
      # @return [String]
      def format_facet(class_code, call_number_type, title)
        return [class_code, title].join(' - ') if loc_call_number_type?(call_number_type)

        ["#{class_code}00", title].join(' - ')
      end

      # Determine whether call number type is library of congress
      # @param call_number_type [String] value from call number type subfield
      # @return [Boolean]
      def loc_call_number_type?(call_number_type)
        call_number_type == '0'
      end
    end
  end
end
