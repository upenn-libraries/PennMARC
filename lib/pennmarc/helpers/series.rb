# frozen_string_literal: true

module PennMARC
  # Do Series-y stuff
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
      SERIES_TAGS = %w[800 810 811 830 400 411 440 490].freeze
      def show(record, relator_mapping)
        acc = []

        tags_present = SERIES_TAGS.select { |tag| record[tag].present? }

        if %w[800 810 811 400 410 411].member?(tags_present.first)
          acc += author_show_entries(record, tags_present.first, relator_mapping)
        elsif %w[830 440 490].member?(tags_present.first)
          acc += title_show_entries(record, tags_present.first)
        end

        acc += remaining_show_fields(record, tags_present)
        acc += series_880_fields(record)

        acc
      end

      def values(record, relator_mapping)
        acc = []
        added_8xx = false
        record.fields(%w[800 810 811 830]).take(1).each do |field|
          acc << get_series_8xx_field(field, relator_mapping)
          added_8xx = true
        end
        unless added_8xx
          record.fields(%w[400 410 411 440 490]).take(1).map do |field|
            acc << get_series_4xx_field(field)
          end
        end
        acc
      end

      def search(record)
        acc = []
        acc += record.fields(%w[400 410 411]).filter_map do |field|
          next if field.indicator2 == '0'

          join_subfields(field, &subfield_not_in?(%w[4 6 8]))
        end
        acc += record.fields(%w[400 410 411]).filter_map do |field|
          next if field.indicator2 == '1'

          join_subfields(field, &subfield_not_in?(%w[4 6 8 a]))
        end
        acc += record.fields(%w[440]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 5 6 8 w]))
        end
        acc += record.fields(%w[800 810 811]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 4 5 6 7 8 w]))
        end
        acc += record.fields(%w[830]).filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[0 5 6 7 8 w]))
        end
        acc += record.fields(%w[533]).filter_map do |field|
          filtered_values = field.filter_map { |sf| sf.value if sf.code == 'f' }
          next if filtered_values.empty?

          filtered_values.map { |v| v.gsub(/\(|\)/, '') }.join(' ')
        end
        acc
      end

      def get_continues_display(record)
        get_continues(record, '780')
      end

      def get_continued_by_display(record)
        get_continues(record, '785')
      end

      private

      def author_show_entries(record, first_tag, relator_mapping)
        acc = []
        record.fields(first_tag).each do |field|
          # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
          series = join_subfields(field, &subfield_not_in?(%w[0 5 6 8 e t w v n]))
          pairs = field.map do |sf|
            if %w[e w v n t].member?(sf.code)
              [' ', sf.value]
            elsif sf.code == '4'
              [', ', translate_relator(sf.value, relator_mapping)]
            end
          end
          series_append = pairs.flatten.join.strip
          acc << { value: series, value_append: series_append, link_type: 'author_search' }
        end
        acc
      end

      def title_show_entries(record, first_tag)
        acc = []
        record.fields(first_tag).each do |field|
          # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
          series = join_subfields(field, &subfield_not_in?(%w[0 5 6 8 c e w v n]))
          series_append = join_subfields(field, &subfield_in?(%w[c e w v n]))
          acc << { value: series, value_append: series_append, link_type: 'title_search' }
        end
        acc
      end

      def remaining_show_fields(record, tags_present)
        acc = []
        record.fields(tags_present.drop(1)).each do |field|
          # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
          series = join_subfields(field, &subfield_not_in?(%w[0 5 6 8]))
          acc << { value: series, link: false }
        end
        acc
      end

      # TODO: use linked alternate util like this: [{ value: linked_alternate(record, %w[800 811 830 400 411 440 490], &subfield_not_in?(%w[5 6 8])), link: false }]
      def series_880_fields(record)
        acc = []
        record.fields('880').filter_map do |field|
          next unless subfield_value?(field, '6', /^(800|810|811|830|400|410|411|440|490)/)

          series = join_subfields(field, &subfield_not_in?(%w[5 6 8]))
          acc << { value: series, link: false }
        end
        acc
      end

      def get_series_8xx_field(field, relator_mapping)
        s = field.map do |sf|
          # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
          if %w[0 4 5 6 8].exclude?(sf.code)
            " #{sf.value}"
          elsif sf.code == '4'
            ", #{translate_relator(sf.value, relator_mapping)}"
          end
        end.compact.join
        s2 = s + (%w[. -].exclude?(s[-1]) ? '.' : '')
        normalize_space(s2)
      end

      # logic for 'Continues' and 'Continued By' is very similar
      def get_continues(record, tag)
        record.fields.filter_map do |field|
          next unless field.tag == tag || (field.tag == '880' && subfield_value?(field, '6', /^#{tag}/))
          next unless field.any?(&subfield_in?(%w[i a s t n d]))

          join_subfields(field, &subfield_in?(%w[i a s t n d]))
        end
      end
    end
  end
end
