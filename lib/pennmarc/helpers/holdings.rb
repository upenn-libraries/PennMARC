# frozen_string_literal: true

module PennMARC
  # Methods for extracting holdings information when available
  class Holdings < Helper
    class << self
      # Hash of Holdings information
      # @param [MARC::Record] record
      # @return [Array<Hash>]
      def holdings(record)

        # TODO: combine elec and phys, or use distinct fields?
        # TODO: adapt to support API AVA/AVE fields
        
        # from discovery-app for electronic inventory

        # API enriched MARC looks like (for Nature):
        # <datafield ind1=" " ind2=" " tag="AVE">
        #   <subfield code="8">53496697910003681</subfield> [portfolio pid]
        #   <subfield code="c">61496697940003681</subfield> [collection id for e-resource]
        #   <subfield code="e">Available</subfield> [???]
        #   <subfield code="l">VanPeltLib</subfield> [library code - not always present]
        #   <subfield code="m">Nature Publishing Journals</subfield> [collection name]
        #   <subfield code="s">Available from 1869 volume: 1 issue: 1.</subfield> [coverage statement]
        #   <subfield code="t">Nature</subfield> [interface name]
        #   <subfield code="a">01UPENN_INST</subfield> [inst code]
        #   <subfield code="0">9977047322103681</subfield> [mms id]
        # </datafield>
        # <datafield ind1=" " ind2=" " tag="AVE">
        #   <subfield code="8">53669079930003681</subfield>
        #   <subfield code="c">61504800570003681</subfield>
        #   <subfield code="e">Available</subfield>
        #   <subfield code="m">General OneFile</subfield>
        #   <subfield code="s">Available from 01/06/2000 until 12/23/2021.</subfield>
        #   <subfield code="t">Galegroup</subfield>
        #   <subfield code="a">01UPENN_INST</subfield>
        #   <subfield code="0">9977047322103681</subfield>
        # </datafield>

        # Pub process enriched MARC looks like this:
        # <datafield tag="prt" ind1=" " ind2=" ">
        #   <subfield code="pid">5310486800000521</subfield>
        #   <subfield code="url">https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01UPENN_INST/openurl?u.ignore_date_coverage=true&amp;rft.mms_id=9926519600521</subfield>
        #   <subfield code="iface">PubMed Central</subfield>
        #   <subfield code="coverage"> Available from 2005 volume: 1. Most recent 1 year(s) not available.</subfield>
        #   <subfield code="library">MAIN</subfield>
        #   <subfield code="collection">PubMed Central (Training)</subfield>
        #   <subfield code="czcolid">61111058563444000</subfield>
        #   <subfield code="8">5310486800000521</subfield>
        # </datafield>
        elec = record.fields(EnrichedMarc::TAG_ELECTRONIC_INVENTORY)
                     .filter_map do |item|
          next unless item[EnrichedMarc::SUB_ELEC_COLLECTION_NAME].present?

          {
            portfolio_pid: item[EnrichedMarc::SUB_ELEC_PORTFOLIO_PID],
            url: item[EnrichedMarc::SUB_ELEC_ACCESS_URL],
            collection: item[EnrichedMarc::SUB_ELEC_COLLECTION_NAME],
            coverage: item[EnrichedMarc::SUB_ELEC_COVERAGE],
          }
        end

        # from discovery-app for physical inventory
        # API enriched MARC looks like:


        # Pub Process enriched MARC looks like:
        # <datafield tag="hld" ind1="0" ind2=" ">
        #   <subfield code="b">MAIN</subfield>
        #   <subfield code="c">main</subfield>
        #   <subfield code="h">NA2540</subfield>
        #   <subfield code="i">.G63 2009</subfield>
        #   <subfield code="8">226026380000541</subfield>
        # </datafield>
        phys = record.fields(EnrichedMarc::TAG_HOLDING).map do |item|
          # Alma never populates subfield 'a' which is 'location'
          # it appears to store the location code in 'c'
          # and display name in 'b'
          {
            holding_id: item[EnrichedMarc::SUB_HOLDING_SEQUENCE_NUMBER],
            location: item[EnrichedMarc::SUB_HOLDING_SHELVING_LOCATION],
            classification_part: item[EnrichedMarc::SUB_HOLDING_CLASSIFICATION_PART],
            item_part: item[EnrichedMarc::SUB_HOLDING_ITEM_PART],
          }
        end
        elec + phys
      end

      # Count of all electronic portfolios
      # @param [MARC::Record] record
      # @return [Integer]
      def electronic_portfolio_count(record)
        record.tags.count { |tag| tag.in? %w[AVE PRT] }
      end

      # Count of all physical holdings
      # @param [MARC::Record] record
      # @return [Integer]
      def physical_holding_count(record)
        record.tags.count { |tag| tag.in? %w[AVA HLD] }
      end
    end
  end
end
