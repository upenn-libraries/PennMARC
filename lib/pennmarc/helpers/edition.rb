# frozen_string_literal: true

module PennMARC
  # Do Edition-y stuff
  class Edition < Helper
    class << self
      # Edition values for display on a record page.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def show(record)
        acc = []
        acc += record.fields('250').map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        acc += record.fields('880')
                     .select { |f| subfield_value?(f, '6', /^250/) }
                     .map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        acc
      end

      # Edition values for display in search results.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def values(record)
        record.fields('250').take(1).map do |field|
          results = field.find_all(&subfield_not_in?(%w[6 8])).map(&:value)
          join_and_squish(results)
        end
      end

      # @param [MARC::Record] record
      # @return [Array<String>]
      def other_show(record)
        acc = []
        acc += record.fields('775')
                     .select { |f| f.any? { |sf| sf.code == 'i' } }
                     .map do |field|
          other_edition_value(field)
        end
        acc += record.fields('880')
                     .select { |f| ['', ' '].member?(f.indicator2) }
                     .select { |f| subfield_value?(f, '6', /^775/) }
                     .select { |f| f.any? { |sf| sf.code == 'i' } }
                     .map do |field|
          other_edition_value(field)
        end
        acc
      end

      private

      # @param [MARC::DataField] field
      # @return [String (frozen)]
      def other_edition_value(field)
        subi = remove_paren_value_from_subfield_i(field) || ''
        other_editions = field.map do |sf|
          if %w[s x z].member?(sf.code)
            " #{sf.value}"
          elsif sf.code == 't'
            " #{relator_codes[sf.value]}. "
          end
        end.compact.join
        other_editions_append = field.map do |sf|
          if !%w[i h s t x z e f o r w y 7].member?(sf.code)
            " #{sf.value}"
          elsif sf.code == 'h'
            " (#{sf.value}) "
          end
        end.compact.join
        prepend = trim_trailing :period, subi
        "#{prepend}: #{other_editions} #{other_editions_append}"
      end
    end
  end
end
