# frozen_string_literal: true

module PennMARC
  # Methods that return Library and Location values from Alma enhanced MARC fields
  class Location < Helper
    #  Convert Array of location hashes to single hash with location_code as key and location hash as value
    MAPPINGS = YAML.load_file('lib/pennmarc/mappings/locations.yml')['locations']['location'].index_by do |location|
      location['location_code']
    end

    class << self
      # Retrieves library location from enriched marc 'itm' or 'hld' fields, giving priority to the item location over
      # the holdings location. Returns item's location if available. Otherwise, returns holding's location.
      # {PennMARC::EnrichedMarc} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param [MARC::Record] record
      # @param [Hash] location_map hash with location_code as key and location hash as value
      # @return [Array<String>] Array of library locations retrieved from location_map
      def library(record, location_map)
        location(record:, location_map:, display_value: 'library')
      end

      # Retrieves the specific location from enriched marc 'itm' or 'hld' fields, giving priority to the item location
      # over the holdings location. Returns item library location if available. Otherwise, returns holdings library
      # location.
      # {PennMARC::EnrichedMarc} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param [MARC::Record] record
      # @param [Hash] location_map hash with location_code as key and location hash as value
      # @return [Array<String>] Array of specific locations retrieved from location_map
      def specific_location(record, location_map)
        location(record:, location_map:, display_value: 'specific_location')
      end

      # Base method to retrieve location data from enriched marc 'itm' or 'hld' fields, giving priority to the item
      # location over the holdings location. Returns item location if available. Otherwise, returns holdings location.
      # {PennMARC::EnrichedMarc} maps enriched marc fields and subfields created during Alma publishing.
      # @see https://developers.exlibrisgroup.com/alma/apis/docs/bibs/R0VUIC9hbG1hd3MvdjEvYmlicy97bW1zX2lkfQ==/
      #   Alma documentation for these added fields
      # @param [MARC::Record] record
      # @param [Hash] location_map hash with location_code as key and location hash as value
      # @param [String] display_value field in locations hash to retrieve
      # @return [Array<String>]
      def location(record:, display_value:, location_map: MAPPINGS)
        # get enriched marc location tag and subfield code
        location_tag_and_subfield_code(record) => {tag:, subfield_code:}

        locations = record.fields(tag).flat_map do |field|
          field.filter_map do |subfield|
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
            next unless location_map.key?(subfield.value)

            location_map[subfield.value][display_value]
          end
        end.uniq
        locations << 'Online library' if record.fields(PennMARC::EnrichedMarc::TAG_ELECTRONIC_INVENTORY).any?
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

        tag = PennMARC::EnrichedMarc::TAG_HOLDING
        subfield_code = PennMARC::EnrichedMarc::SUB_HOLDING_SHELVING_LOCATION

        if record.fields(PennMARC::EnrichedMarc::TAG_ITEM).any?
          tag = PennMARC::EnrichedMarc::TAG_ITEM
          subfield_code = PennMARC::EnrichedMarc::SUB_ITEM_CURRENT_LOCATION
        end

        { tag:, subfield_code: }
      end
    end
  end
end
