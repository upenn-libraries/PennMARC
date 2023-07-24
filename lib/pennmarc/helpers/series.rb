# frozen_string_literal: true

module PennMARC
  # Do Series and series-related field processing. Many of these fields are added entries that are justified by
  # corresponding series statements (usually 490). These fields provide information about the published series in which
  # a book, encoded finding aid, or other published work has appeared
  # @todo We may want to include 410 in the display tags, since it is included in references below.
  class Series < Helper
    class << self
      # 800 - Series Added Entry-Personal Name - https://www.loc.gov/marc/bibliographic/bd800.html
      # 810 - Series Added Entry-Corporate Name - https://www.loc.gov/marc/bibliographic/bd810.html
      # 410 - Series Statement/Added Entry-Corporate Name - https://www.loc.gov/marc/bibliographic/bd410.html
      # 811 - Series Added Entry-Meeting Name - https://www.loc.gov/marc/bibliographic/bd811.html
      # 830 - Series Added Entry-Uniform Title - https://www.loc.gov/marc/bibliographic/bd830.html
      # 400 - Series Statement/Added Entry-Personal Name - https://www.loc.gov/marc/bibliographic/bd400.html
      # 411 - Series Statement/Added Entry Meeting Name - https://www.loc.gov/marc/bibliographic/bd411.html
      # 440 - Series Statement/Added Entry-Title - https://www.loc.gov/marc/bibliographic/bd440.html
      # 490 - Series Statement - https://www.loc.gov/marc/bibliographic/bd490.html
      DISPLAY_TAGS = %w[800 810 811 830 400 411 440 490].freeze

      # Fields for display that pertain to series information.
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of series information
      def show(record, relator_mapping)
        tags_present = DISPLAY_TAGS.select { |tag| record[tag].present? }

        values = if %w[800 810 811 400 410 411].member?(tags_present.first)
                   author_show_entries(record, tags_present.first, relator_mapping)
                 elsif %w[830 440 490].member?(tags_present.first)
                   title_show_entries(record, tags_present.first)
                 end || []

        values += remaining_show_entries(record, tags_present)
        values + series_880_fields(record)
      end

      # Values from series fields for display.
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of series values
      def values(record, relator_mapping)
        series_8x = record.fields(%w[800 810 811 830]).first
        return Array.wrap(series_8xx_field(series_8x, relator_mapping)) if series_8x

        series_4x = record.fields(%w[400 410 411 440 490]).first
        return Array.wrap(series_4xx_field(series_4x, relator_mapping)) if series_4x
      end

      # Series fields for search.
      # @param [MARC::Record] record
      # @return [Array<String>] array of series values
      def search(record)
        values = record.fields(%w[400 410 411]).filter_map do |field|
          subfields = if field.indicator2 != '0'
                        %w[4 6 8]
                      elsif field.indicator2 != '1'
                        %w[4 6 8 a]
                      else
                        next
                      end
          join_subfields(field, &subfield_not_in?(subfields))
        end
        values += record.fields(%w[440]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 5 6 8 w]))
        end
        values += record.fields(%w[800 810 811]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 4 5 6 7 8 w]))
        end
        values += record.fields(%w[830]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 5 6 7 8 w]))
        end
        values += record.fields(%w[533]).filter_map do |field|
          filtered_values = field.filter_map { |sf| sf.value if sf.code == 'f' }
          next if filtered_values.empty?

          filtered_values.map { |v| v.gsub(/\(|\)/, '') }.join(' ')
        end
        values
      end

      # Information concerning the immediate predecessor of the target item (chronological relationship). When a note
      # is generated from this field, the introductory term or phrase may be generated based on the value in the second
      # indicator position for display.
      # https://www.loc.gov/marc/bibliographic/bd780.html
      # @param [MARC::Record] record
      # @return [String] continues fields string
      def get_continues_display(record)
        continues(record, '780')
      end

      # Information concerning the immediate successor to the target item (chronological relationship). When a note is
      # generated from this field, the introductory phrase may be generated based on the value in the second indicator
      # position for display.
      # https://www.loc.gov/marc/bibliographic/bd785.html
      # @param [MARC::Record] record
      # @return [String] continued by fields string
      def get_continued_by_display(record)
        continues(record, '785')
      end

      private

      # If any of these values: 800 810 811 400 410 411 are present, return a string with series information and
      # appended values.
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      # @param [MARC::Record] record
      # @param [String] first_tag
      # @param [Hash] relator_mapping
      # @return [Array<Hash>] array of author show entry hashes
      def author_show_entries(record, first_tag, relator_mapping)
        record.fields(first_tag).map do |field|
          series = join_subfields(field, &subfield_not_in?(%w[0 5 6 8 e t w v n]))
          pairs = field.map do |sf|
            if %w[e w v n t].member?(sf.code)
              [' ', sf.value]
            elsif sf.code == '4'
              [', ', translate_relator(sf.value, relator_mapping)]
            end
          end
          series_append = pairs.flatten.join.strip
          "#{series} #{series_append}".squish
        end || []
      end

      # If any of these values: 830 440 490 are present, return a string with series information and appended values.
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      # @param [MARC::Record] record
      # @param [String] first_tag
      # @return [Array<Hash>] array of author show entry hashes
      def title_show_entries(record, first_tag)
        record.fields(first_tag).map do |field|
          series = join_subfields(field, &subfield_not_in?(%w[0 5 6 8 c e w v n]))
          series_append = join_subfields(field, &subfield_in?(%w[c e w v n]))
          "#{series} #{series_append}".squish
        end || []
      end

      # Assemble an array of hashes that includes the remaining show entries.
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      # @param [MARC::Record] record
      # @param [Array<String>] tags_present
      # @return [Array<Hash>] array of remaining show entry hashes
      def remaining_show_entries(record, tags_present)
        record.fields(tags_present.drop(1)).map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 5 6 8]))
        end || []
      end

      # TODO: use linked alternate in place of this function
      # @note There are multiple locations in these helpers where we should be able to use the linked_alternate util.
      # @note This requires a more comprehensive evaluation and refactor of the linked_alternate utility.
      #
      # Fully content-designated representation, in a different script, of another field in the same record. Field 880
      # is linked to the associated regular field by subfield $6 (Linkage). A subfield $6 in the associated field also
      # links that field to the 880 field. The data in field 880 may be in more than one script. This function exists
      # because it differs than the tradition use of linked_alternate.
      # @param [MARC::Record] record
      def series_880_fields(record)
        record.fields('880').filter_map do |field|
          next unless subfield_value?(field, '6', /^(800|810|811|830|400|410|411|440|490)/)

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end || []
      end

      # Assemble a formatted string of a given 8xx field.
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      # @param [String] field
      # @param [Hash] relator_mapping
      # @return [String] series 8xx field
      def series_8xx_field(field, relator_mapping)
        s = field.filter_map do |sf|
          if %w[0 4 5 6 8].exclude?(sf.code)
            " #{sf.value}"
          elsif sf.code == '4'
            ", #{translate_relator(sf.value, relator_mapping)}"
          end
        end.join
        s2 = s + (%w[. -].exclude?(s[-1]) ? '.' : '')
        s2.squish
      end

      # Assemble a formatted string of a given 4xx field.
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      # @param [String] field
      # @param [Hash] relator_mapping
      # @return [String] series 4xx field
      def series_4xx_field(field, relator_mapping)
        s = field.filter_map do |sf|
          if %w[0 4 6 8].exclude?(sf.code)
            " #{sf.value}"
          elsif sf.code == '4'
            ", #{translate_relator(sf.value, relator_mapping)}"
          end
        end.join
        s2 = s + (%w[. -].exclude?(s[-1]) ? '.' : '')
        s2.squish
      end

      # Get subfields from a given field (continues or continued_by).
      # @param [MARC::Record] record
      # @param [String] tag
      # @return [String] joined subfields
      def continues(record, tag)
        record.fields.filter_map do |field|
          next unless field.tag == tag || (field.tag == '880' && subfield_value?(field, '6', /^#{tag}/))
          next unless field.any?(&subfield_in?(%w[i a s t n d]))

          join_subfields(field, &subfield_in?(%w[i a s t n d]))
        end
      end
    end
  end
end
