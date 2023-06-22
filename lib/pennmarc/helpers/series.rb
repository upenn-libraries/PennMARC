# frozen_string_literal: true

module PennMARC
  # Do Series-y stuff
  class Series < Helper
    class << self
      def show(record)
        acc = []

        tags_present = series_tags.select { |tag| record[tag].present? }

        if %w[800 810 811 400 410 411].member?(tags_present.first)
          record.fields(tags_present.first).each do |field|
            # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
            series = join_subfields(field, &subfield_not_in(%w[0 5 6 8 e t w v n]))
            pairs = field.map do |sf|
              if %w[e w v n t].member?(sf.code)
                [' ', sf.value]
              elsif sf.code == '4'
                [', ', relator_codes[sf.value]]
              end
            end
            series_append = pairs.flatten.join.strip
            acc << { value: series, value_append: series_append, link_type: 'author_search' }
          end
        elsif %w[830 440 490].member?(tags_present.first)
          record.fields(tags_present.first).each do |field|
            # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
            series = join_subfields(field, &subfield_not_in(%w[0 5 6 8 c e w v n]))
            series_append = join_subfields(field, &subfield_in(%w[c e w v n]))
            acc << { value: series, value_append: series_append, link_type: 'title_search' }
          end
        end

        record.fields(tags_present.drop(1)).each do |field|
          # added 2017/04/10: filter out 0 (authority record numbers) added by Alma
          series = join_subfields(field, &subfield_not_in(%w[0 5 6 8]))
          acc << { value: series, link: false }
        end

        record.fields('880')
              .select { |f| has_subfield6_value(f, /^(800|810|811|830|400|410|411|440|490)/) }
              .each do |field|
          series = join_subfields(field, &subfield_not_in(%w[5 6 8]))
          acc << { value: series, link: false }
        end

        acc
      end

      def values(record)
        acc = []
        added_8xx = false
        record.fields(%w[800 810 811 830]).take(1).each do |field|
          acc << get_series_8xx_field(field)
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
        acc += record.fields(%w[400 410 411])
                     .select { |f| f.indicator2 == '0' }
                     .map do |field|
          join_subfields(field, &subfield_not_in(%w[4 6 8]))
        end
        acc += record.fields(%w[400 410 411])
                     .select { |f| f.indicator2 == '1' }
                     .map do |field|
          join_subfields(field, &subfield_not_in(%w[4 6 8 a]))
        end
        acc += record.fields(%w[440])
                     .map do |field|
          join_subfields(field, &subfield_not_in(%w[0 5 6 8 w]))
        end
        acc += record.fields(%w[800 810 811])
                     .map do |field|
          join_subfields(field, &subfield_not_in(%w[0 4 5 6 7 8 w]))
        end
        acc += record do |field|
          join_subfields(field, &subfield_not_in(%w[0 5 6 7 8 w]))
        end
        acc + record.fields(%w[533])
                    .map do |field|
                field.find_all { |sf| sf.code == 'f' }
                     .map(&:value)
                     .map { |v| v.gsub(/\(|\)/, '') }
                     .join(' ')
              end
      end

      def get_continues_display(record)
        get_continues(record, '780')
      end

      def get_continued_by_display(record)
        get_continues(record, '785')
      end

      private

      # logic for 'Continues' and 'Continued By' is very similar
      def get_continues(record, tag)
        record.fields
              .select { |f| f.tag == tag || (f.tag == '880' && has_subfield6_value(f, /^#{tag}/)) }
              .select { |f| f.any?(&subfield_in(%w[i a s t n d])) }
              .map do |field|
          join_subfields(field, &subfield_in(%w[i a s t n d]))
        end
      end
    end
  end
end
