# frozen_string_literal: true

# class to hold "utility" methods used in MARC parsing methods
module MarcUtil
  # returns true if field has a value that matches
  # passed-in regex and passed in subfield
  # TODO: example usage
  # @param [MARC::DataField] field
  # @param [String|Integer|Symbol] subf
  # @param [Regexp] regex
  # @return [TrueClass, FalseClass]
  def subfield_value?(field, subf, regex)
    field.any? { |sf| sf.code == subf.to_s && sf.value =~ regex }
  end

  # returns true iff a given field has a given subfield value in a given array
  # TODO: example usage
  # @param [MARC:DataField] field
  # @param [String|Integer|Symbol] subf
  # @param [Array] array
  # @return [TrueClass, FalseClass]
  def subfield_value_in?(field, subf, array)
    field.any? { |sf| sf.code == subf.to_s && sf.value.in?(array) }
  end

  # returns a lambda checking if passed-in subfield's code is a member of array
  # @param [Array] array
  # @return [Proc]
  def subfield_in?(array)
    ->(subfield) { array.member?(subfield.code) }
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
end
