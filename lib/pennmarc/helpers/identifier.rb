# frozen_string_literal: true

module PennMARC
  # Parser methods for extracting identifier values.
  class Identifier < Helper
    class << self

      # define regex to match doi like values
      # For detailed explanation of regex see {https://stackoverflow.com/a/10324802}
      # See {https://www.doi.org/the-identifier/resources/handbook/2_numbering} for DOI specifications
      # @todo in the SO post, there are concerns raised about registrant code possibly being shorter than 4 characters
      # and the valid presence of `<`, '>' in a DOI
      DOI_REGEX = Regexp.new('\b(10[.][0-9]{4,}(?:[.][0-9]+)*/(?:(?!["&\'<>])\S)+)\b')

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
            field.filter_map { |subfield| subfield.value if subfield_in?(%w[a l z]).call(subfield) }
          end
        }.flatten.uniq
      end

      # Get ISBN values for display from the {https://www.oclc.org/bibformats/en/0xx/020.html 020 field}
      # and related {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      # @todo look into z subfield for 020 field, should we show cancelled isbn?
      def isbn_show(record)
        isbn_values = record.fields('020').filter_map do |field|
          joined_isbn = join_subfields(field, &subfield_in?(%w[a z]))
          joined_isbn.presence
        end
        isbn_values + linked_alternate(record, '020', &subfield_in?(%w[a z]))
      end

      # Get ISSN values for display from the {https://www.oclc.org/bibformats/en/0xx/022.html 022 field} and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def issn_show(record)
        issn_values = record.fields('022').filter_map do |field|
          joined_issn = join_subfields(field, &subfield_in?(%w[a z]))
          joined_issn.presence
        end
        issn_values + linked_alternate(record, '022', &subfield_in?(%w[a z]))
      end

      # Get numeric OCLC ID of first {https://www.oclc.org/bibformats/en/0xx/035.html 035 field}
      # with an OCLC ID defined in subfield 'a'.
      #
      # @todo We should evaluate this to return a single value in the future since subfield a is non-repeatable
      # @param [MARC::Record] record
      # @return [Array<String>]
      def oclc_id(record)
        oclc_id = Array.wrap(record.fields('035')
                         .find { |field| field.any? { |subfield| subfield_a_is_oclc?(subfield) } })

        oclc_id.flat_map do |field|
          field.filter_map do |subfield|
            # skip unless subfield 'a' is an oclc id value
            next unless subfield_a_is_oclc?(subfield)

            # search for numeric part of oclc id (e.g. '610094484' in '(OCoLC)ocn610094484')
            match = /^\s*\(OCoLC\)[^1-9]*([1-9][0-9]*).*$/.match(subfield.value)

            # skip unless search to find numeric part of oclc id has a match
            next unless match

            match[1]
          end
        end
      end

      # Get publisher issued identifiers from fields {https://www.oclc.org/bibformats/en/0xx/024.html 024},
      # {https://www.oclc.org/bibformats/en/0xx/024.html 028}, and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}. We do not return DOI values stored in 024 ǂ2,
      # see {PennMARC::Identifier.doi_show} for parsing DOI values.
      #
      # @param [MARC::Record] record
      # @return [Array<string>]
      def publisher_number_show(record)
        record.fields(%w[024 028 880]).filter_map do |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', %w[024 028])

          # do not return doi values from 024 ǂ2
          if field.tag == '024' && subfield_value_is_a_doi?(field, '2')
            join_subfields(field, &subfield_not_in?(%w[2 5 6])).presence
          else
            join_subfields(field, &subfield_not_in?(%w[5 6])).presence
          end
        end
      end

      # Get publisher issued identifiers for searching of a record. Values extracted from fields
      # {https://www.oclc.org/bibformats/en/0xx/024.html 024} and {https://www.oclc.org/bibformats/en/0xx/028.html 028}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def publisher_number_search(record)
        record.fields(%w[024 028]).filter_map do |field|
          joined_identifiers = join_subfields(field, &subfield_in?(%w[a]))
          joined_identifiers.presence
        end
      end

      # Retrieve fingerprint for display from the {https://www.oclc.org/bibformats/en/0xx/026.html 026} field
      # @param [MARC::Record] record
      # @return [Array<String>]
      def fingerprint_show(record)
        record.fields('026').map do |field|
          join_subfields(field, &subfield_not_in?(%w[2 5 6 8]))
        end
      end

      # Retrieve DOI values stored in {https://www.oclc.org/bibformats/en/0xx/024.html 024} ǂ2.
      # {PennMARC::Identifier::DOI_REGEX} is the regular expression used to identify DOI values.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def doi_show(record)
        record.fields('024').flat_map do |field|
          field.filter_map do |subfield|
            next unless subfield.code == '2'
            next unless subfield_value_is_a_doi?(field, subfield.code)

            subfield.value.match(DOI_REGEX)[0]
          end
        end
      end

      private

      # Determine if subfield 'a' is an OCLC id.
      #
      # @param [MARC::Subfield]
      # @return [TrueClass, FalseClass]
      def subfield_a_is_oclc?(subfield)
        subfield.code == 'a' && (subfield.value =~ /^\(OCoLC\).*/).present?
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

      # returns true if field has a subfield value that looks like a DOI
      # @param [MARC::DataField] field
      # @param [String|Integer|Symbol] subfield
      # @return [TrueClass, FalseClass]
      def subfield_value_is_a_doi?(field, subfield)
        subfield_value?(field, subfield, DOI_REGEX)
      end
    end
  end
end
