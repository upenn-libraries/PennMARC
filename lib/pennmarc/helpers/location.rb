# frozen_string_literal: true

module PennMARC
  # Methods that return Library and Location values from Alma enhanced MARC fields
  class Location < Helper
    WEB_LOCATION_CODE = 'web'

    class << self
      # Retrieves library location from enriched marc 'itm' or 'hld' fields, giving priority to the item location over
      # the holdings location. Returns item's location if available. Otherwise, returns holding's location.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param record [MARC::Record]
      # @param location_map [Hash] hash with location_code as key and location hash as value
      # @return [Array<String>] Array of library locations retrieved from location_map
      def library(record, location_map: Mappers.location)
        location(record: record, location_map: location_map, display_value: 'library')
      end

      # Retrieves the specific location from enriched marc 'itm' or 'hld' fields, giving priority to the item location
      # over the holdings location. Returns item library location if available. Otherwise, returns holdings library
      # location.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param record [MARC::Record]
      # @param location_map [Hash] hash with location_code as key and location hash as value
      # @return [Array<String>] Array of specific locations retrieved from location_map
      def specific_location(record, location_map: Mappers.location)
        location(record: record, location_map: location_map, display_value: 'specific_location')
      end

      # Base method to retrieve location data from enriched marc 'itm' or 'hld' fields, giving priority to the item
      # location over the holdings location. Returns item location if available. Otherwise, returns holdings location.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param record [MARC::Record]
      # @param display_value [Symbol,String] field in location hash to retrieve
      # @param location_map [Hash] hash with location_code as key and location hash as value
      # @return [Array<String>]
      def location(record:, display_value:, location_map:)
        # get enriched marc location tag and relevant subfields
        enriched_location_tag_and_subfields(record) => {tag:, location_code_sf:, call_num_sf:, call_num_type_sf:}

        record.fields(tag).flat_map { |field|
          field.filter_map { |subfield|
            # skip unless subfield matches enriched marc tag subfield code
            next unless subfield.code == location_code_sf

            location_code = subfield.value

            next if location_code_to_ignore?(location_map, location_code)

            override = if display_value.to_sym == :specific_location
                         specific_location_override(location_code: location_code, field: field,
                                                    call_num_sf: call_num_sf, call_num_type_sf: call_num_type_sf)
                       end

            override || location_map[location_code.to_sym][display_value.to_sym]
          }.flatten.compact_blank
        }.uniq
      end

      private

      # Determine enriched marc location tag, location code subfield, and call number subfield,
      # giving priority to using 'itm', 'AVA', or 'hld' fields.
      # @param record [MARC::Record]
      # @return [Hash<String, String>] containing location tag and subfield code
      # - `:tag` (String): The enriched marc location tag
      # - `:location_code_sf` (String): The subfield code where location code is stored
      # - `:call_num_sf` (String): The subfield code where call number is stored
      # - `:call_num_type_sf` (String, nil): The subfield code where call number type is stored. nil if unavailable in a
      #                                   MARC field and we need to look for an indicator.
      def enriched_location_tag_and_subfields(record)
        # in holdings records, the shelving location is always the permanent location.
        # in item records, the current location takes into account
        # temporary locations and permanent locations. if you update the item's perm location,
        # the holding's shelving location changes.
        #
        # Since item records may reflect locations more accurately, we use them if they exist;
        # if not, we use the holdings.

        # if the record has an enriched item field present, use it
        if field_defined?(record, Enriched::Pub::ITEM_TAG)
          tag = Enriched::Pub::ITEM_TAG
          location_code_sf = Enriched::Pub::ITEM_CURRENT_LOCATION
          call_num_sf = Enriched::Pub::ITEM_CALL_NUMBER
          call_num_type_sf = Enriched::Pub::ITEM_CALL_NUMBER_TYPE
          # if the record has API inventory tags, use them
        elsif field_defined?(record, Enriched::Api::PHYS_INVENTORY_TAG)
          tag = Enriched::Api::PHYS_INVENTORY_TAG
          location_code_sf = Enriched::Api::PHYS_LOCATION_CODE
          call_num_sf = Enriched::Api::PHYS_CALL_NUMBER
          call_num_type_sf = Enriched::Api::PHYS_CALL_NUMBER_TYPE
          # otherwise use Pub holding tags
        else
          tag = Enriched::Pub::PHYS_INVENTORY_TAG
          location_code_sf = Enriched::Pub::PHYS_LOCATION_CODE
          call_num_sf = Enriched::Pub::HOLDING_CLASSIFICATION_PART
          call_num_type_sf = nil # for hld tags, the call num type is indicator0
        end

        { tag: tag, location_code_sf: location_code_sf, call_num_sf: call_num_sf, call_num_type_sf: call_num_type_sf }
      end

      # Determines whether to ignore a location code.
      # We ignore location codes that are not keys in the location map. Sometimes "happening locations" are
      # mistakenly used in holdings records. That's a data problem that should be fixed. If we encounter a code we can't
      # map, we ignore it, for faceting purposes. We also ignore the location code 'web'. We don't facet for 'web'
      # which is the 'Penn Library Web' location used in Voyager. This location should eventually go away completely
      # with data cleanup in Alma.
      # @param location_map [Hash] hash with location_code as key and location hash as value
      # @param location_code [String] retrieved from record
      # @return [Boolean]
      def location_code_to_ignore?(location_map, location_code)
        !location_map.key?(location_code.to_sym) || location_code == WEB_LOCATION_CODE
      end

      # Retrieves a specific location override based on location code and call number. Specific location overrides are
      # located in `location_overrides.yml`.
      # @param location_code [String]
      # @param field [MARC::Field]
      # @param call_num_sf [String]
      # @param call_num_type_sf [String, nil]
      # @return [String, Nil]
      def specific_location_override(location_code:, field:, call_num_sf:, call_num_type_sf:)
        callnum_type = callnum_type(field: field, call_num_type_sf: call_num_type_sf)
        return unless callnum_type

        override = Mappers.location_overrides.find do |_key, value|
          override_matching?(value: value, location_code: location_code, callnum_type: callnum_type,
                             call_numbers: subfield_values(field, call_num_sf))
        end

        override&.last&.dig(:specific_location)
      end

      # Check value hash for a matching location name override
      # @param [Hash] value
      # @param location_code [String]
      # @param call_numbers [Array]
      # @param callnum_type [String]
      # @return [Boolean]
      def override_matching?(value:, location_code:, call_numbers:, callnum_type:)
        call_numbers.any? do |call_number|
          value[:location_code] == location_code &&
            value[:call_num_type] == callnum_type &&
            call_number.match?(value[:call_num_pattern])
        end

      end

      # Return call num type value for a given field. If no call number subfield is expected (publishing holding
      # inventory case), the first indicator is checked.
      # @param field [MARC::Field]
      # @param call_num_type_sf [String, nil]
      # @return [String, nil]
      def callnum_type(field:, call_num_type_sf:)
        return field.indicator1 if call_num_type_sf.nil?

        subfield_values(field, call_num_type_sf).first
      end
    end
  end
end
