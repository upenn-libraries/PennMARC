# frozen_string_literal: true

module PennMARC
  # Methods for extracting how a record can be accessed
  class Access < Helper
    ONLINE = 'Online'
    AT_THE_LIBRARY = 'At the library'

    class << self
      # Based on enhanced metadata fields added by Alma publishing process or API, determine if the record has
      # electronic access or has physical holdings, and is therefore "Online" or "At the library". If a record is "At
      # the library", but has a link to a finding aid in the 856 field (matching certain criteria), also add 'Online' as
      # an access method.
      # @todo What if none of these criteria match? Should we include "At the library" by default? Records with no value
      #       in this field would be lost if the user selects a facet value.
      # @param [MARC::Record] record
      # @return [Array]
      def facet(record)
        acc = record.filter_map do |field|
          next AT_THE_LIBRARY if physical_holding_tag?(field)
          next ONLINE if electronic_holding_tag?(field)
        end

        return acc if acc.size == 2 # return early if all values are already present

        acc << ONLINE if acc.exclude?(ONLINE) && finding_aid_linkage?(record) # only check if ONLINE isn't already there
        acc
      end

      private

      # Does the record have added electronic holding info?
      # @param [MARC::Field] field
      # @return [Boolean]
      def electronic_holding_tag?(field)
        field.tag.in? [Enriched::Pub::ELEC_INVENTORY_TAG, Enriched::Api::ELEC_INVENTORY_TAG]
      end

      # Does the record have added physical holding info?
      # @param [MARC::Field] field
      # @return [Boolean]
      def physical_holding_tag?(field)
        field.tag.in? [Enriched::Pub::PHYS_INVENTORY_TAG, Enriched::Api::PHYS_INVENTORY_TAG]
      end

      # Check if a record contains an 856 entry for an online finding aid, meeting these criteria:
      # 1. Indicator 1 is 4 (HTTP resource)
      # 2. Indicator 2 is NOT 2 (indicating the linkage is to a "related" thing)
      # 3. The URL specified in subfield u (URI) is a Penn Handle link
      # See: https://www.loc.gov/marc/bibliographic/bd856.html
      # @param [MARC::Record] record
      # @return [Boolean]
      def finding_aid_linkage?(record)
        record.fields('856').filter_map do |field|
          next if field.indicator2 == '2' || field.indicator1 != '4'

          subz = subfield_values(field, 'z')
          subfield_values(field, 'u').filter_map do |value|
            return true if subz.include?('Finding aid') && value.include?('hdl.library.upenn.edu')
          end
        end
        false
      end
    end
  end
end
