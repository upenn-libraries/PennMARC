# frozen_string_literal: true

module PennMARC
  # Methods that return Library and Location values from Alma enhanced MARC fields
  class Location < Helper
    ONLINE_LIBRARY = 'Online library'

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
        location_tag_and_subfield_code(record) => {tag:, subfield_code:}

        locations = record.fields(tag).flat_map { |field|
          field.filter_map { |subfield|
            # skip unless subfield code does not match enriched marc tag subfield code
            next unless subfield.code == subfield_code

            # skip if subfield value is 'web'
            # we don't facet for 'web' which is the 'Penn Library Web' location used in Voyager.
            # this location should eventually go away completely with data cleanup in Alma.
            next if subfield.value == 'web'

            # skip unless subfield value is a key in location_map
            # sometimes "happening locations" are mistakenly used in holdings records.
            # that's a data problem that should be fixed.
            # here, if we encounter a code we can't map, we ignore it, for faceting purposes
            next unless location_map.key?(subfield.value.to_sym)

            location_map[subfield.value.to_sym][display_value.to_sym]
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
      # - `:tag` (String): The enriched marc location tag
      # - `:subfield_code` (String): The relevant subfield code
      def location_tag_and_subfield_code(record)
        # in holdings records, the shelving location is always the permanent location.
        # in item records, the current location takes into account
        # temporary locations and permanent locations. if you update the item's perm location,
        # the holding's shelving location changes.
        #
        # Since item records may reflect locations more accurately, we use them if they exist;
        # if not, we use the holdings.

        # if the record has an enriched item field present, use it
        if field_defined?(record, PennMARC::Enriched::Pub::ITEM_TAG)
          tag = PennMARC::Enriched::Pub::ITEM_TAG
          subfield_code = PennMARC::Enriched::Pub::ITEM_CURRENT_LOCATION
        # if the record has API inventory tags, use them
        elsif field_defined?(record, Enriched::Api::PHYS_INVENTORY_TAG)
          tag = Enriched::Api::PHYS_INVENTORY_TAG
          subfield_code = Enriched::Api::PHYS_LOCATION_CODE
        # otherwise use Pub holding tags
        else
          tag = PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG
          subfield_code = PennMARC::Enriched::Pub::HOLDING_LOCATION_CODE
        end

        { tag: tag, subfield_code: subfield_code }
      end
    end
  end
end
