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
        record.fields(%w[020 022]).map do |field|
          if field.tag == '020'
            field.filter_map { |subfield| normalize_isbn(subfield.value) if subfield_in?(%w[a z]).call(subfield) }
          else
            field.filter_map { |subfield| normalize_issn(subfield.value) if subfield_in?(%w[a l z]).call(subfield) }
          end
        end.flatten.compact.uniq
      end

      # Get ISBN values for display from the {https://www.oclc.org/bibformats/en/0xx/020.html 020 field}
      # and related {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      # todo look into z subfield for 020 field, should we show cancelled isbn?
      def isbn_show(record)
        acc = []
        acc += record.fields('020').map do |field|
          join_subfields(field, &subfield_in?(%w[a z]))
        end.select(&:present?)
        acc += get_880(record, '020', &subfield_in?(%w[a z]))
        acc
      end

      # Get ISSN values for display from the {https://www.oclc.org/bibformats/en/0xx/022.html 022 field} and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def issn_show(record)
        acc = []
        acc += record.fields('022').map do |field|
          join_subfields(field, &subfield_in?(%w[a z]))
        end.select(&:present?)
        acc += get_880(record, '022', &subfield_in?(%w[a z]))
        acc
      end

      # Get numeric OCLC ID of first {https://www.oclc.org/bibformats/en/0xx/035.html 035 field}
      # with an OCLC ID defined in subfield 'a'.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def oclc_id(record)
        record.fields('035')
              .select { |field| field.any? { |subfield| subfield_a_is_oclc?(subfield) } }
              .take(1)
              .flat_map do |field|
                field.find_all { |subfield| subfield_a_is_oclc?(subfield) }.map do |subfield|
                  match = /^\s*\(OCoLC\)[^1-9]*([1-9][0-9]*).*$/.match(subfield.value)
                  match[1] if match
                end.compact
              end
      end

      # Get publisher issued identifiers from fields {https://www.oclc.org/bibformats/en/0xx/024.html 024},
      # {https://www.oclc.org/bibformats/en/0xx/024.html 028}, and related
      # {https://www.oclc.org/bibformats/en/8xx/880.html 880 field}.
      #
      # @param [MARC::Record] record
      # @return [Array<string>]
      def publisher_number_show(record)
        acc = []
        acc += record.fields(%w[024 028]).map do |field|
          join_subfields(field, &subfield_not_in?(%w[5 6]))
        end.select(&:present?)
        acc += get_880(record, %w[024 028], &subfield_not_in?(%w[5 6]))
        acc
      end

      # Get publisher issued identifiers for searching of a record. Values extracted from fields
      # {https://www.oclc.org/bibformats/en/0xx/024.html 024} and {https://www.oclc.org/bibformats/en/0xx/024.html 028}.
      #
      # @param [MARC::Record] record
      # @return [Array<String>]
      def publisher_number_search(record)
        record.fields(%w[024 028]).map do |field|
          join_subfields(field, &subfield_in?(%w[a]))
        end.select(&:present?)
      end

      private

      # Determine if subfield 'a' is an OCLC id.
      #
      # @param [MARC::Subfield]
      # @return [TrueClass, FalseClass]
      def subfield_a_is_oclc?(subfield)
        subfield.code == 'a' && subfield.value =~ /^\(OCoLC\).*/
      end

      # Normalize isbn value using {https://github.com/billdueber/library_stdnums library_stdnums gem}.
      # Converts ISBN10 (ten-digit) to validated ISBN13 (thriteen-digit) and returns both values. If passed
      # ISBN13 parameter, only returns validated ISBN13 value.
      #
      #  @param [String] isbn
      #  @return [Array<String, String>, nil]
      def normalize_isbn(isbn)
        StdNum::ISBN.allNormalizedValues(isbn)
      end

      # Normalizes issn value using {https://github.com/billdueber/library_stdnums library_stdnums gem}
      #
      # @param [String] issn
      # @return [String, nil]
      def normalize_issn(issn)
        StdNum::ISSN.normalize(issn)
      end
    end
  end
end
