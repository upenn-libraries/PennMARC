# frozen_string_literal: true

module PennMARC
  # Methods that return Library and Location values from Alma enhanced MARC fields
  class Location < Helper
    ONLINE_LIBRARY = 'Online library'
    VAN_PELT_LOCATION_CODE = 'vanp'
    WEB_LOCATION_CODE = 'web'
    ALBRECHT_MUSIC_SPECIFIC_LOCATION = 'Van Pelt - Albrecht Music Library'
    LOC_MUSIC_CALL_NUM_PREFIX = 'M'

    class << self
      # Retrieves library location from enriched marc 'itm' or 'hld' fields, giving priority to the item location over
      # the holdings location. Returns item's location if available. Otherwise, returns holding's location.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param [MARC::Record] record
      # @param [Hash] location_map hash with location_code as key and location hash as value
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
      # @param [MARC::Record] record
      # @param [Hash] location_map hash with location_code as key and location hash as value
      # @return [Array<String>] Array of specific locations retrieved from location_map
      def specific_location(record, location_map: Mappers.location)
        location(record: record, location_map: location_map, display_value: 'specific_location')
      end

      # Base method to retrieve location data from enriched marc 'itm' or 'hld' fields, giving priority to the item
      # location over the holdings location. Returns item location if available. Otherwise, returns holdings location.
      # {PennMARC::Enriched} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param [MARC::Record] record
      # @param [Symbol | String] display_value field in location hash to retrieve
      # @param [Hash] location_map hash with location_code as key and location hash as value
      # @return [Array<String>]
      def location(record:, display_value:, location_map:)
        # get enriched marc location tag and subfield code
        marc_location_fields(record) => {field:, location_code_sf:, call_num_sf:}

        locations = record.fields(field).flat_map { |field|
          field.filter_map { |subfield|
            # skip unless subfield code does not match enriched marc tag subfield code
            next unless subfield.code == location_code_sf

            location_code = subfield.value

            next if location_code_to_ignore?(location_map, location_code)

            if specific_location_albrecht?(display_value: display_value, location_code: location_code, field: field,
                                           call_num_sf: call_num_sf)
              ALBRECHT_MUSIC_SPECIFIC_LOCATION
            else
              location_map[location_code.to_sym][display_value.to_sym]
            end
          }.flatten.compact_blank
        }.uniq
        if record.tags.intersect?([Enriched::Pub::ELEC_INVENTORY_TAG, Enriched::Api::ELEC_INVENTORY_TAG])
          locations << ONLINE_LIBRARY
        end

        locations
      end

      private

      # Determine enriched marc location tag ('itm' or 'hld') and subfield code, giving priority to using 'itm' tag and
      # subfield.
      # @param [MARC::Record]
      # @return [Hash<String, String>] containing location tag and subfield code
      # - `:field` (String): The enriched marc location tag
      # - `:location_code_sf` (String): The subfield code where location code is stored
      # - `:call_num_sf` (String): The subfield code where call number is stored
      def marc_location_fields(record)
        # in holdings records, the shelving location is always the permanent location.
        # in item records, the current location takes into account
        # temporary locations and permanent locations. if you update the item's perm location,
        # the holding's shelving location changes.
        #
        # Since item records may reflect locations more accurately, we use them if they exist;
        # if not, we use the holdings.

        # if the record has an enriched item field present, use it
        if field_defined?(record, Enriched::Pub::ITEM_TAG)
          field = Enriched::Pub::ITEM_TAG
          location_code_sf = Enriched::Pub::ITEM_CURRENT_LOCATION
          call_num_sf = Enriched::Pub::ITEM_CALL_NUMBER
          # if the record has API inventory tags, use them
        elsif field_defined?(record, Enriched::Api::PHYS_INVENTORY_TAG)
          field = Enriched::Api::PHYS_INVENTORY_TAG
          location_code_sf = Enriched::Api::PHYS_LOCATION_CODE
          call_num_sf = Enriched::Api::PHYS_CALL_NUMBER
          # otherwise use Pub holding tags
        else
          field = Enriched::Pub::PHYS_INVENTORY_TAG
          location_code_sf = Enriched::Pub::PHYS_LOCATION_CODE
        end

        { field: field, location_code_sf: location_code_sf, call_num_sf: call_num_sf }
      end

      # Determines whether to ignore a location code.
      # We ignore location codes that are not keys in the location map. Sometimes "happening locations" are
      # mistakenly used in holdings records. That's a data problem that should be fixed. If we encounter a code we can't
      # map, we ignore it, for faceting purposes. We also ignore the location code 'web'. We don't facet for 'web'
      # which is the 'Penn Library Web' location used in Voyager. This location should eventually go away completely
      # with data cleanup in Alma.
      # @param [location_map] location_map hash with location_code as key and location hash as value
      # @param [location_code] location_code retrieved from record
      # @return [Boolean]
      def location_code_to_ignore?(location_map, location_code)
        location_map.key?(location_code.to_sym) == false || location_code == WEB_LOCATION_CODE
      end

      # Determine whether the specific location is in "Van Pelt - Albrecht Music Library". If the location_code is
      # 'vanp' and the record represents a music title using library of congress call number classifications
      # this returns true.
      # @param [String] display_value
      # @param [String] location_code
      # @param [MARC::Field] field
      # @param [MARC::Subfield] call_num_sf
      # @return [Boolean]
      def specific_location_albrecht?(display_value:, location_code:, field:, call_num_sf:)
        display_value == :specific_location && location_code == VAN_PELT_LOCATION_CODE && music_call_num?(field,
                                                                                                          call_num_sf)
      end

      # Determines whether any call numbers stored in a given field represent a music title according to the Library of
      # Congress classification
      # @param [MARC::Field] field
      # @param [MARC::Subfield] call_num_sf
      # @return [Boolean]
      def music_call_num?(field, call_num_sf)
        call_numbers = subfield_values(field, call_num_sf)
        call_numbers.any? { |call_num| call_num.chr == LOC_MUSIC_CALL_NUM_PREFIX }
      end
    end
  end
end
