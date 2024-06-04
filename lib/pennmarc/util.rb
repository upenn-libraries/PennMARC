# frozen_string_literal: true

require_relative 'heading_control'

module PennMARC
  # class to hold "utility" methods used in MARC parsing methods
  module Util
    TRAILING_PUNCTUATIONS_PATTERNS = { semicolon: /\s*;\s*$/,
                                       colon: /\s*:\s*$/,
                                       equal: /=$/,
                                       slash: %r{\s*/\s*$},
                                       comma: /\s*,\s*$/,
                                       period: /\.\s*$/ }.freeze # TODO: revise to exclude "etc."

    # Check if a given record has a field present by tag (e.g., '041')
    # @param [MARC::Record] record
    # @param [String] marc_field
    # @return [Boolean]
    def field_defined?(record, marc_field)
      record.select { |field| field.tag == marc_field }.any?
    end

    # Join subfields from a field selected based on a provided proc
    # @param [MARC::DataField, nil] field
    # @param [Proc] selector
    # @return [String]
    def join_subfields(field, &selector)
      return '' unless field

      field.select(&selector).filter_map { |sf|
        value = sf.value&.strip
        next if value.blank?

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
      field&.any? { |sf| sf.code == subfield.to_s && sf.value =~ regex }
    end

    # returns true if a given field has a given subfield value in a given array
    # TODO: example usage
    # @param [MARC:DataField] field
    # @param [String|Integer|Symbol] subfield
    # @param [Array] array
    # @return [TrueClass, FalseClass]
    def subfield_value_in?(field, subfield, array)
      field.any? { |sf| sf.code == subfield.to_s && sf.value.in?(array) }
    end

    # returns true if a given field does not have a given subfield value in a given array
    # @param [MARC:DataField] field
    # @param [String|Integer|Symbol] subfield
    # @param [Array] array
    # @return [TrueClass, FalseClass
    def subfield_value_not_in?(field, subfield, array)
      field.none? { |sf| sf.code == subfield.to_s && sf.value.in?(array) }
    end

    # returns a lambda checking if passed-in subfield's code is a member of array
    # @param [Array] array
    # @return [Proc]
    def subfield_in?(array)
      ->(subfield) { array.member?(subfield.code) }
    end

    # returns a lambda checking if passed-in subfield's code is NOT a member of array
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

        next if sf.value.blank?

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
    # @return [String]
    def trim_trailing(trailer, string)
      string.sub TRAILING_PUNCTUATIONS_PATTERNS[trailer.to_sym], ''
    end

    # trim trailing punctuation, manipulating string in place
    # @param [Symbol|String] trailer to target for removal
    # @param [String] string to modify
    # @return [String, Nil] string to modify
    def trim_trailing!(trailer, string)
      string.sub! TRAILING_PUNCTUATIONS_PATTERNS[trailer.to_sym], ''
    end

    # Intelligently append given punctuation to the end of a string
    # @param [Symbol] trailer
    # @param [String] string
    # @return [String]
    def append_trailing(trailer, string)
      return string if string.end_with?('.', '-')

      map = { semicolon: ';',
              colon: ':',
              slash: '/',
              comma: ',',
              period: '.' }
      string + map[trailer.to_sym]
    end

    # MARC 880 field "Alternate Graphic Representation" contains text "linked" to another
    # field (e.g., 254 [Title]) used as an alternate representation. Often used to hold
    # translations of title values. A common need is to extract subfields as selected by
    # passed-in block from 880 datafield that has a particular subfield 6 value.
    # See: https://www.loc.gov/marc/bibliographic/bd880.html
    # @param [MARC::Record] record
    # @param [String|Array] subfield6_value either a string to look for in sub6 or an array of them
    # @param [Proc] selector takes a subfield as argument, returns a boolean
    # @return [Array] array of linked alternates
    def linked_alternate(record, subfield6_value, &selector)
      record.fields('880').filter_map do |field|
        next unless subfield_value?(field, '6', /^#{Array.wrap(subfield6_value).join('|')}/)

        field.select(&selector).map(&:value).join(' ')
      end
    end

    # Common case of wanting to extract all the subfields besides 6 or 8,
    # from 880 datafield that has a particular subfield 6 value. We exclude 6 because
    # that value is the linkage ID itself and 8 because... IDK
    # @param [MARC::Record] record
    # @param [String|Array] subfield6_value either a string to look for in sub6 or an array of them
    # @return [Array] array of linked alternates without 8 or 6 values
    def linked_alternate_not_6_or_8(record, subfield6_value)
      excluded_subfields = %w[6 8]
      linked_alternate(record, subfield6_value) do |sf|
        excluded_subfields.exclude?(sf.code)
      end
    end

    # Returns the non-6,8 subfields from a datafield and its 880 link.
    # @param [MARC::Record] record
    # @param [String] tag
    # @return [Array<String>] values
    def datafield_and_linked_alternate(record, tag)
      record.fields(tag).filter_map { |field|
        join_subfields(field, &subfield_not_in?(%w[6 8]))
      } + linked_alternate_not_6_or_8(record, tag)
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

    # If there's a subfield i, extract its value, and if there's something
    # in parentheses in that value, extract that.
    # @param [MARC::Field] field
    # @return [String] subfield i without parentheses value
    def remove_paren_value_from_subfield_i(field)
      val = field.filter_map { |sf|
        next unless sf.code == 'i'

        match = /\((.+?)\)/.match(sf.value)
        if match
          sf.value.sub("(#{match[1]})", '')
        else
          sf.value
        end
      }.first || ''
      trim_trailing(:colon, trim_trailing(:period, val))
    end

    # Translate a relator code using mapping
    # @todo handle case of receiving a URI? E.g., http://loc.gov/relator/aut
    # @param [String, NilClass] relator_code
    # @param [Hash] mapping
    # @return [String, NilClass] full relator string
    def translate_relator(relator_code, mapping)
      return if relator_code.blank?

      mapping[relator_code.to_sym]
    end

    # Get 650 & 880 for Provenance and Chronology: prefix should be 'PRO' or 'CHR' and may be preceded by a '%'
    # @note 11/2018: do not display $5 in PRO or CHR subjs
    # @param [MARC::Record] record
    # @param [String] prefix to select from subject field
    # @return [Array] array of values
    def prefixed_subject_and_alternate(record, prefix)
      record.fields(%w[650 880]).filter_map { |field|
        next unless field.indicator2 == '4'

        next if field.tag == '880' && subfield_values(field, '6').exclude?('650')

        next unless field.any? { |sf| sf.code == 'a' && sf.value =~ /^(#{prefix}|%#{prefix})/ }

        elements = field.select(&subfield_in?(%w[a])).map { |sf| sf.value.gsub(/^%?#{prefix}/, '') }
        elements << join_subfields(field, &subfield_not_in?(%w[a 6 8 e w 5]))
        join_and_squish elements
      }.uniq
    end

    # Does the given field specify an allowed source code?
    #
    # @param [MARC::DataField] field
    # @return [Boolean]
    def valid_subject_genre_source_code?(field)
      subfield_value_in?(field, '2', PennMARC::HeadingControl::ALLOWED_SOURCE_CODES)
    end

    # Does a field or its linked alternate match any of the specified tags?
    # @param [MARC::Field] field
    # @param [Array<String>] tags
    # @return [TrueClass, FalseClass]
    def field_or_its_linked_alternate?(field, tags)
      return true if field.tag.in? tags
      return true if field.tag == '880' && subfield_value_in?(field, '6', tags)

      false
    end

    # Match any open dates ending a given string to determine join separator for relator term in 1xx/7xx fields.
    # @param [String] str
    # @return [String (frozen)]
    def relator_join_separator(str)
      /\b\d+-\z/.match?(str) ? ' ' : ', '
    end

    # For a given field, determine in which subfield to find relator term
    # The following fields and their linked alternates use $j for relator terms:
    # {https://www.loc.gov/marc/bibliographic/bd111.html 111}, {https://www.loc.gov/marc/bibliographic/bd411.html 411},
    # {https://www.loc.gov/marc/bibliographic/bd611.html 611}, {https://www.loc.gov/marc/bibliographic/bd711.html 711},
    # {https://www.loc.gov/marc/bibliographic/bd811.html 811}
    # @param [MARC:Field] field
    # @return [String (frozen)]
    def relator_term_subfield(field)
      field_or_its_linked_alternate?(field, %w[111 411 611 711 811]) ? 'j' : 'e'
    end

    # Appends a relator value to the given string. It prioritizes relator codes found in subfield $4
    # and falls back to the specified relator term subfield (defaulting to 'e') if no valid codes are found in $4.
    # Use with 1xx/7xx fields.
    # @param [MARC::Field] field where relator values are stored
    # @param [String] joined_subfields the string to which the relator is appended
    # @param [String] relator_term_sf MARC subfield that stores relator term
    # @param [Hash] relator_map
    # @return [String]
    def append_relator(field:, joined_subfields:, relator_term_sf:, relator_map: Mappers.relator)
      joined_subfields = trim_trailing(:comma, joined_subfields)

      join_separator = relator_join_separator(joined_subfields)

      relator = subfield_values(field, '4').filter_map { |code| translate_relator(code, relator_map) }

      relator = subfield_values(field, relator_term_sf) if relator.blank?

      relator = append_trailing(:period, relator.join(', ')) if relator.present?

      [joined_subfields, relator].compact_blank.join(join_separator).squish
    end

    # Returns a relator value of the given field. Like append_relator, it prioritizes relator codes found in subfileld
    # $4 and falls back to the specified relator term subfield relator_term_sf if no valid codes are found in $4
    # @param [MARC::Field] field where relator values are stored
    # @param [String] relator_term_sf MARC subfield that stores relator term
    # @param [Hash] relator_map
    # @return [String]
    def relator(field:, relator_term_sf:, relator_map: Mappers.relator)
      relator = subfield_values(field, '4').filter_map { |code| translate_relator(code, relator_map) }
      relator = subfield_values(field, relator_term_sf) if relator.blank?
      relator.join
    end
  end
end
