# frozen_string_literal: true

module PennMARC
  # Parser methods for extracting identifier values.
  class Identifier < Helper
    class << self
      # Get Alma MMS ID value
      #
      # @param [MARC::Record] record
      # @return [String]
      def mmsid(record)
        record.fields('001').first.value
      end

      # Get normalized ISXN values for searching of a record. Values aggregated from subfield 'a' and 'z' of the
      # {https://www.oclc.org/bibformats/en/0xx/020.html 020 field}, and subfield 'a', 'l', and 'z' of the
      # the {https://www.oclc.org/bibformats/en/0xx/020.html 022 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def isxn_search(record)
        record.fields(%w[020 022]).filter_map { |field|
          if field.tag == '020'
            field.filter_map { |subfield| normalize_isbn(subfield.value) if subfield_in?(%w[a z]).call(subfield) }
          else
            field.filter_map { |subfield| subfield.value if subfield_in?(%w[a l m y z]).call(subfield) }
          end
        }.flatten.uniq
      end

      # Get ISBN values for display from the {https://www.oclc.org/bibformats/en/0xx/020.html 020 field}
      # and related {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def isbn_show(record)
        values = record.fields('020').filter_map do |field|
          joined_isbn = join_subfields(field, &subfield_in?(%w[a]))
          joined_isbn.presence
        end
        isbn_values = values + linked_alternate(record, '020', &subfield_in?(%w[a]))
        isbn_values.uniq
      end

      # Get ISSN values for display from the {https://www.oclc.org/bibformats/en/0xx/022.html 022 field} and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def issn_show(record)
        values = record.fields('022').filter_map do |field|
          joined_issn = join_subfields(field, &subfield_in?(%w[a]))
          joined_issn.presence
        end
        issn_values = values + linked_alternate(record, '022', &subfield_in?(%w[a]))
        issn_values.uniq
      end

      # Get numeric OCLC ID of first {https://www.oclc.org/bibformats/en/0xx/035.html 035 field}
      # with an OCLC ID defined in subfield 'a'.
      # @param [MARC::Record] record
      # @return [String, nil]
      def oclc_id_show(record)
        ids = Array.wrap(record.fields('035')
                           .find { |field| field.any? { |subfield| subfield_a_is_oclc?(subfield) } })
        ids.flat_map { |field|
          field.filter_map do |subfield|
            # skip unless subfield 'a' is an oclc id value
            next unless subfield_a_is_oclc?(subfield)

            # search for numeric part of oclc id (e.g. '610094484' in '(OCoLC)ocn610094484')
            match = match_oclc_number(subfield)

            # skip unless search to find numeric part of oclc id has a match
            next unless match

            match[1]
          end
        }.first
      end

      # Retrieve valid and invalid numeric OCLC IDs from {https://www.oclc.org/bibformats/en/0xx/035.html 035 field}
      # for search.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def oclc_id_search(record)
        record.fields('035').flat_map { |field|
          field.filter_map do |subfield|
            # skip unless subfield 'a' or 'z'
            next unless subfield.code.in?(%w[a z])

            # skip unless subfield value matches OCLC ID
            next unless subfield_is_oclc?(subfield)

            # search for numeric part of oclc id
            match = match_oclc_number(subfield)

            # skip unless search to find numeric part of oclc id has a match
            next unless match

            match[1]
          end
        }.uniq
      end

      # Get publisher issued identifiers from fields {https://www.oclc.org/bibformats/en/0xx/024.html 024},
      # {https://www.oclc.org/bibformats/en/0xx/024.html 028}, and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}. We do not return DOI values stored in 024 ǂ2,
      # see {PennMARC::Identifier.doi_show} for parsing DOI values.
      #
      # @param [MARC::Record] record
      # @return [Array<string>]
      def publisher_number_show(record)
        record.fields(%w[024 028 880]).filter_map { |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', %w[024 028])

          # do not return doi values from 024 ǂ2
          if field.tag == '024' && subfield_value_in?(field, '2', %w[doi])
            join_subfields(field, &subfield_not_in?(%w[a 2 5 6])).presence
          else
            join_subfields(field, &subfield_not_in?(%w[5 6])).presence
          end
        }.uniq
      end

      # Get publisher issued identifiers for searching of a record. Values extracted from fields
      # {https://www.oclc.org/bibformats/en/0xx/024.html 024} and {https://www.oclc.org/bibformats/en/0xx/028.html 028}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def publisher_number_search(record)
        record.fields(%w[024 028]).filter_map { |field|
          joined_identifiers = join_subfields(field, &subfield_in?(%w[a]))
          joined_identifiers.presence
        }.uniq
      end

      # Retrieve fingerprint for display from the {https://www.oclc.org/bibformats/en/0xx/026.html 026} field
      # @param [MARC::Record] record
      # @return [Array<String>]
      def fingerprint_show(record)
        record.fields('026').map { |field|
          join_subfields(field, &subfield_not_in?(%w[2 5 6 8]))
        }.uniq
      end

      # Retrieve DOI values stored in {https://www.oclc.org/bibformats/en/0xx/024.html 024}.
      # Penn MARC records give the first indicator a value of '7' and ǂ2 a value of 'doi' to denote that ǂa is a doi.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def doi_show(record)
        record.fields('024').filter_map { |field|
          # skip unless indicator1 is '7'
          next unless field.indicator1.in?(%w[7])
          # skip unless ǂ2 is the string literal 'doi'
          next unless subfield_value_in?(field, '2', %w[doi])

          join_subfields(field, &subfield_in?(%w[a]))
        }.uniq
      end

      private

      # Determine if subfield 'a' is an OCLC id.
      #
      # @param [MARC::Subfield]
      # @return [TrueClass, FalseClass]
      def subfield_a_is_oclc?(subfield)
        subfield.code == 'a' && subfield_is_oclc?(subfield)
      end

      # @param [MARC::Subfield]
      # @return [TrueClass, FalseClass]
      def subfield_is_oclc?(subfield)
        (subfield.value =~ /^\(OCoLC\).*/).present?
      end

      # @param [MARC::Subfield]
      # @return [MatchData, nil]
      def match_oclc_number(subfield)
        /^\s*\(OCoLC\)[^1-9]*([1-9][0-9]*).*$/.match(subfield.value)
      end

      # Normalize isbn value using {https://github.com/billdueber/library_stdnums library_stdnums gem}.
      # Converts ISBN10 (ten-digit) to validated ISBN13 (thirteen-digit) and returns both values. If passed
      # ISBN13 parameter, only returns validated ISBN13 value.
      #
      #  @param [String] isbn
      #  @return [Array<String, String>, nil]
      def normalize_isbn(isbn)
        StdNum::ISBN.allNormalizedValues(isbn)
      end
    end
  end
end
