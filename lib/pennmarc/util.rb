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

    # Get all subfield values for a provided subfield from any occurrence of a provided tag/tags
    # @param [String|Array] tag tags to consider
    # @param [String|Symbol] subfield to take the values from
    # @param [MARC::Record] record source
    # @return [Array] array of subfield values
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
    # @return [Array] array of linked alternates
    def linked_alternate(record, subfield6_value, &selector)
      record.fields('880').filter_map do |field|
        next unless subfield_value?(field, '6', /^#{Array.wrap(subfield6_value).join('|')}/)

        field.select { |sf| selector.call(sf) }.map(&:value).join(' ')
      end
    end
    alias get_880 linked_alternate

    # Common case of wanting to extract all the subfields besides 6 or 8,
    # from 880 datafield that has a particular subfield 6 value. We exclude 6 because
    # that value is the linkage ID itself and 8 because... IDK
    # @param [MARC::Record] record
    # @param [String|Array] subfield6_value either a string to look for in sub6 or an array of them
    # @return [Array] array of linked alternates without 8 or 6 values
    def linked_alternate_not_6_or_8(record, subfield6_value)
      linked_alternate(record, subfield6_value) do |sf|
        !%w{6 8}.member?(sf.code)
      end
    end

    # Returns the non-6,8 subfields from a datafield and its 880 link.
    # @param [MARC::Record] record
    # @param [String] tag
    # @return [Array] acc
    def datafield_and_linked_alternate(record, tag)
      record.fields(tag).filter_map do |field|
        join_subfields(field, &subfield_not_in?(%w{6 8}))
      end + linked_alternate_not_6_or_8(record, tag)
    end

    # Get the substring of a string up to a given target character
    # @param [Object] string to split
    # @param [Object] target character to split upon
    # @return [String (frozen)]
    def substring_before(string, target)
      string.scan(target).present? ? string.split(target, 2).first : ''
    end

    # Get the substring of a string after the first occurrence of a target character
    # @param [Object] string to split
    # @param [Object] target character to split upon
    # @return [String (frozen)]
    def substring_after(string, target)
      string.scan(target).present? ? string.split(target, 2).second : ''
    end

    # Join array and normalizing extraneous spaces
    # @param [Array] array
    # @return [String]
    def join_and_squish(array)
      array.join(' ').squish
    end
    alias join_and_trim_whitespace join_and_squish
  end
end
