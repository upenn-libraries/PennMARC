# frozen_string_literal: true

module PennMARC
  # class to hold "utility" methods used in MARC parsing methods
  module Util
    # Join subfields from a field selected based on a provided proc
    # @param [MARC::DataField] field
    # @param [Proc] selector
    # @return [String]
    def join_subfields(field, &selector)
      field.select { |v| selector.call(v) }.filter_map { |sf|
        value = sf.value&.strip
        next unless value.present?

        value
      }.join(' ').squish
    end

    # returns true if field has a value that matches
    # passed-in regex and passed in subfield
    # @todo example usage
    # @param [MARC::DataField] field
    # @param [String|Integer|Symbol] subfield
    # @param [Regexp] regex
    # @return [TrueClass, FalseClass]
    def subfield_value?(field, subfield, regex)
      field.any? { |sf| sf.code == subfield.to_s && sf.value =~ regex }
    end

    # returns true iff a given field has a given subfield value in a given array
    # TODO: example usage
    # @param [MARC:DataField] field
    # @param [String|Integer|Symbol] subfield
    # @param [Array] array
    # @return [TrueClass, FalseClass]
    def subfield_value_in?(field, subfield, array)
      field.any? { |sf| sf.code == subfield.to_s && sf.value.in?(array) }
    end

    # returns a lambda checking if passed-in subfield's code is a member of array
    # TODO: include lambda returning methods in their own module?
    # @param [Array] array
    # @return [Proc]
    def subfield_in?(array)
      ->(subfield) { array.member?(subfield.code) }
    end

    # returns a lambda checking if passed-in subfield's code is NOT a member of array
    # TODO: include lambda returning methods in their own module?
    # @param [Array] array
    # @return [Proc]
    def subfield_not_in?(array)
      ->(subfield) { !array.member?(subfield.code) }
    end

    # Check if a field has a given subfield defined
    # @param [MARC::DataField] field
    # @param [String|Symbol|Integer] subfield
    # @return [TrueClass, FalseClass]
    def subfield_defined?(field, subfield)
      field.any? { |sf| sf.code == subfield.to_s }
    end

    # Check if a field does not have a given subfield defined
    # @param [MARC::DataField] field
    # @param [String|Symbol|Integer] subfield
    # @return [TrueClass, FalseClass]
    def subfield_undefined?(field, subfield)
      field.none? { |sf| sf.code == subfield.to_s }
    end

    # Gets all subfield values for a subfield in a given field
    # @param [MARC::DataField] field
    # @param [String|Symbol] subfield as a string or symbol
    # @return [Array] subfield values for given subfield code
    def subfield_values(field, subfield)
      field.filter_map do |sf|
        next unless sf.code == subfield.to_s

        next unless sf.value.present?

        sf.value
      end
    end

    # Get all subfield values for a provided subfield form any occurrence of a provided tag/tags
    # @param [String|Array] tag tags to consider
    # @param [String|Symbol] subfield to take the values from
    # @param [MARC::Record] record source
    def subfield_values_for(tag:, subfield:, record:)
      record.fields(tag).flat_map do |field|
        subfield_values field, subfield
      end
    end

    # @param [Symbol|String] trailer to target for removal
    # @param [String] string to modify
    def trim_trailing(trailer, string)
      map = { semicolon: /\s*;\s*$/,
              colon: /\s*:\s*$/,
              equal: /=$/,
              slash: %r{\s*/\s*$},
              comma: /\s*,\s*$/,
              period: /\.\s*$/ } # TODO: revise to exclude "etc."
      string.sub map[trailer.to_sym], ''
    end

    # MARC 880 field "Alternate Graphic Representation" contains text "linked" to another
    # field (e.g., 254 [Title]) used as an alternate representation. Often used to hold
    # translations of title values. A common need is to extract subfields as selected by
    # passed-in block from 880 datafield that has a particular subfield 6 value.
    # See: https://www.loc.gov/marc/bibliographic/bd880.html
    # @param [MARC::Record] record
    # @param [String|Array] subfield6_value either a string to look for in sub6 or an array of them
    # @param selector [Proc] takes a subfield as argument, returns a boolean
    # @return [Array]
    def linked_alternate(record, subfield6_value, &selector)
      record.fields('880').filter_map do |field|
        next unless subfield_value?(field, '6', /^#{Array.wrap(subfield6_value).join('|')}/)

        field.select { |sf| selector.call(sf) }.map(&:value).join(' ')
      end
    end
    alias get_880 linked_alternate
  end
end
