# frozen_string_literal: true

module PennMARC
  # Methods for extracting how a record can be accessed
  class Access < Helper
    ONLINE = 'Online'
    AT_THE_LIBRARY = 'At the library'
    HANDLE_BASE_URL = 'hdl.library.upenn.edu'
    COLENDA_BASE_URL = 'colenda.library.upenn.edu'

    class << self
      # Based on enhanced metadata fields added by Alma publishing process or API, determine if the record has
      # electronic access or has physical holdings, and is therefore "Online" or "At the library". If a record is "At
      # the library", but has a link to a finding aid in the 856 field (matching certain criteria), also add 'Online' as
      # an access method.
      # Because Alma E-Collections don't return electronic inventory, check some MARC control fields and other fields
      # for indicators of an online resource, but only if n other Online indicators are present.
      # @param record [MARC::Record]
      # @return [Array]
      def facet(record)
        values = record.filter_map do |field|
          next AT_THE_LIBRARY if physical_holding_tag?(field)
          next ONLINE if electronic_holding_tag?(field)
        end

        return values if values.size == 2 # return early if all values are already present

        # only check if ONLINE isn't already there
        values << ONLINE if values.exclude?(ONLINE) && marc_indicators?(record)
        values.uniq
      end

      private

      # @param [MARC::Record] record
      # @return [Boolean]
      def marc_indicators?(record)
        return true if resource_link?(record) || electronic_database?(record)

        [eresource_form?(record),
         eresource_material_designation?(record),
         online_computer_file_form?(record),
         online_carrier_type?(record)].count(true) >= 2
      end

      # Does the record have added electronic holding info?
      # @param field [MARC::Field]
      # @return [Boolean]
      def electronic_holding_tag?(field)
        field.tag.in? [Enriched::Pub::ELEC_INVENTORY_TAG, Enriched::Api::ELEC_INVENTORY_TAG]
      end

      # Does the record have added physical holding info?
      # @param field [MARC::Field]
      # @return [Boolean]
      def physical_holding_tag?(field)
        field.tag.in? [Enriched::Pub::PHYS_INVENTORY_TAG, Enriched::Api::PHYS_INVENTORY_TAG]
      end

      # Check if a record contains an 856 entry with a Penn Handle server link meeting these criteria:
      # 1. Indicator 1 is 4 (HTTP resource)
      # 2. Indicator 2 is NOT 2 (indicating the linkage is to a "related" thing)
      # 3. The URL specified in subfield u (URI) is a Penn Handle link or Penn Colenda link
      # 4. The subfield z does NOT include the string 'Finding aid'
      # See: https://www.loc.gov/marc/bibliographic/bd856.html
      # @note Some electronic records do not have Portfolios in Alma, so we rely upon the Resource Link in the 856 to
      #       get these records included in the Online category.
      # @param record [MARC::Record]
      # @return [Boolean]
      def resource_link?(record)
        record.fields('856').any? { |field| valid_resource_field?(field) }
      end

      # Does the record have an 006 suggesting an electronic resource?
      # Check position 6 "Form of item" for an `m` indicating "Computer file/Electronic resource"
      # @see https://www.loc.gov/marc/bibliographic/bd006.html
      # @param record [MARC::Record]
      # @return [Boolean]
      def eresource_form?(record)
        return false unless field_defined?(record, '006')

        record.fields('006').first.value[6] == 'm'
      end

      # Does the record have an 007 indicating an electronic resource?
      # Check pos 0 for a `c` ("Electronic resource") and position 1 for an `r` ("Remote")
      # @see https://www.loc.gov/marc/bibliographic/bd007c.html
      # @param record [MARC::Record]
      # @return [Boolean]
      def eresource_material_designation?(record)
        return false unless field_defined?(record, '007')

        record.fields('007').first.value[0..1] == 'cr'
      end

      # Does the record have an 008 indicating an electronic resource?
      # https://www.loc.gov/marc/bibliographic/bd008c.html
      # @param record [MARC::Record]
      # @return [Boolean]
      def online_computer_file_form?(record)
        return false unless field_defined?(record, '008')

        record.fields('008').first.value[23] == 'o'
      end

      # Does the record have an 338 indicating an electronic resource?
      # @see https://www.loc.gov/marc/bibliographic/bd338.html, https://www.loc.gov/standards/valuelist/rdacarrier.html
      # @param record [MARC::Record]
      # @return [Boolean]
      def online_carrier_type?(record)
        return false unless field_defined?(record, '338')

        return false unless subfield_values_for(tag: '338', subfield: 'a', record: record).include?('online resource')

        subfield_values_for(tag: '338', subfield: 'b', record: record).include?('cr')
      end

      # Databases are always electronic resources
      # @param record [MARC::Record]
      # @return [Boolean]
      def electronic_database?(record)
        Database.type_facet(record).any?
      end

      # Check if a field contains valid resource
      # @param field [MARC::Field]
      # @return [Boolean]
      def valid_resource_field?(field)
        return false if field.indicator2 == '2' || field.indicator1 != '4'
        return false if subfield_values(field, 'z')&.include?('Finding aid')

        subfield_values(field, 'u').any? do |value|
          [HANDLE_BASE_URL, COLENDA_BASE_URL].any? { |url| value.include?(url) }
        end
      end
    end
  end
end
