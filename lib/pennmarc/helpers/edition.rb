# frozen_string_literal: true

module PennMARC
  # Do Edition-y stuff
  class Edition < Helper
    class << self
      def show(record)
        acc = []
        acc += record.fields('250').map do |field|
          join_subfields(field, &subfield_not_in(%w[6 8]))
        end
        acc += record.fields('880')
                     .select { |f| has_subfield6_value(f, /^250/) }
                     .map do |field|
          join_subfields(field, &subfield_not_in(%w[6 8]))
        end
        acc
      end

      def values(record)
        record.fields('250').take(1).map do |field|
          results = field.find_all(&subfield_not_in(%w[6 8])).map(&:value)
          join_and_trim_whitespace(results)
        end
      end

      def other_edition_values(_record)
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
        {
          value: other_editions,
          value_prepend: "#{trim_trailing_period(subi)}:",
          value_append: other_editions_append,
          link_type: 'author_creator_xfacet2'
        }
      end

      # @todo this one is a bit complicated and returns a link hash
      # @param [MARC::Record] record
      # @return [Object]
      def other_edition_show(record)
        acc = []
        acc += record.fields('775')
                     .select { |f| f.any? { |sf| sf.code == 'i' } }
                     .map do |field|
          get_other_edition_value(field)
        end
        acc += record.fields('880')
                     .select { |f| ['', ' '].member?(f.indicator2) }
                     .select { |f| has_subfield6_value(f, /^775/) }
                     .select { |f| f.any? { |sf| sf.code == 'i' } }
                     .map do |field|
          get_other_edition_value(field)
        end
        acc
      end
    end
  end
end
