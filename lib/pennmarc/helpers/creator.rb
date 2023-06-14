# frozen_string_literal: true

module PennMARC
  # Do Creator-y stuff
  class Creator < Helper
    class << self
      TAGS = %w[100 110].freeze
      AUX_TAGS = %w[100 110 111 400 410 411 700 710 711 800 810 811].freeze


      # Author/Creator search field
      # @note ported from get_author_creator_1_search_values
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of author/creator values
      def search(record, relator_mapping)
        acc = []
        acc += record.fields(TAGS).map do |field|
          pieces = field.filter_map do |sf|
            if sf.code == 'a'
              # after_comma = [trim_trailing(:comma, substring_after(sf.value, ', '))].join(' ').squish
              # before_comma = substring_before(sf.value, ', ')
              # " #{after_comma} #{before_comma}"
              parts = sf.value.partition(',')
              " #{parts[0]} #{parts[2]}"
            elsif !%w[a 1 4 6 8].member?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_mapping[sf.value]}"
            end
          end
          value = pieces.join(' ').squish
          if value.end_with?('.') || value.end_with?('-')
            value
          else
            "#{value}."
          end
        end
        acc += record.fields(TAGS).map do |field|
          pieces = field.filter_map do |sf|
            if !%w[4 6 8].member?(sf.code)
              " #{sf.value}"
            elsif sf.code == '4'
              ", #{relator_mapping[sf.value]}"
            end
          end
          value = join_and_trim_whitespace(pieces)
          if value.end_with?('.') || value.end_with?('-')
            value
          else
            "#{value}."
          end
        end
        acc += record.fields(%w[880])
                     .select { |f| f.any? { |sf| sf.code == '6' && sf.value =~ /^(100|110)/ } }
                     .map do |field|
          suba = field.find_all(&subfield_in(%w[a])).map do |sf|
            # after_comma = join_and_trim_whitespace(
            #   [trim_trailing(:comma, substring_before(sf.value, ','))]
            # )
            # before_comma = substring_after(sf.value, ',')
            # "#{after_comma} #{before_comma}"
            parts = sf.value.partition(',')
            "#{parts[0]} #{parts[2]}"
          end.first
          oth = field.find_all(&subfield_not_in?(%w[6 8 a t])).map(&:value).join(' ').squish
          [suba, oth].join(' ')
        end
        acc
      end

      # Auxiliary Author/Creator search field
      # @note ported from get_author_creator_2_search_values
      # @todo port this later
      # @param [MARC::Record] record
      # @return [Array<String>] array of author/creator values
      def search_aux(record); end

      # Author/Creator display field
      # @note ported from get_author_creator_values
      # @param [MARC::Record] record
      # @param [Hash] relator_mapping
      # @return [Array<String>] array of author/creator values for display
      def show(record, relator_mapping)
        record.fields(TAGS).map do |field|
          name_from_main_entry(field, relator_mapping)
        end
      end

      # Author/Creator sort
      # @note ported from get_author_creator_sort_values
      # @param [MARC::Record] record
      # @return [String] string with author/creator value for sorting
      def sort(record)
        field = record.fields(TAGS).first
        join_subfields(field, &subfield_not_in?(%w[1 4 6 8 e]))
      end

      # Author/Creator for faceting. Grabs values from a plethora of fields, joins defined subfields, then trims some
      # punctuation (@see trim_punctuation)
      # @todo should trim_punctuation apply to each subfield value, or the joined values? i think the joined values
      # @note ported from author_creator_xfacet2_input - is this the best choice? check the copyField declarations -
      #       franklin uses author_creator_f
      # @param [MARC::Record] record
      # @return [Array<String>] array of author/creator values for faceting
      def facet(record)
        source_map = {
          100 => 'abcdjq', 110 => 'abcdjq', 111 => 'abcen',
          700 => 'abcdjq', 710 => 'abcdjq', 711 => 'abcen',
          800 => 'abcdjq', 810 => 'abcdjq', 811 => 'abcen'
        }
        source_map.flat_map do |field_num, subfields|
          record.fields(field_num.to_s).map do |field|
            trim_punctuation(join_subfields(field, &subfield_in?(subfields.split)))
          end
        end
      end

      private

      # Trim punctuation method extracted from Traject macro, to ensure consistent performance
      # @todo move to Util?
      # @param [String] string
      # @return [String] string with relevant punctuation removed
      def trim_punctuation(string)
        return string unless string

        string = string.sub(%r{ *[ ,/;:] *\Z}, '')

        # trailing period if it is preceded by at least three letters (possibly preceded and followed by whitespace)
        string = string.sub(/( *[[:word:]]{3,})\. *\Z/, '\1')

        # single square bracket characters if they are the start and/or end chars and there are no internal square
        # brackets.
        string = string.sub(/\A\[?([^\[\]]+)\]?\Z/, '\1')

        # trim any leading or trailing whitespace
        string.strip
      end

      # Extract the information we care about from 1xx fields, map relator codes, and use appropriate punctuation
      # @todo if this is not reused, don't do this private method as it wont be tested directly (see conference_display?) could move to Util...
      # @note added 2017/04/10: filter out 0 (authority record numbers) added by Alma
      #       added 2022/08/04: filter our 1 (URIs) added my MARCive project
      # @param [MARC::Field] field
      # @return [String] joined subfield values for value from field
      def name_from_main_entry(field, mapping)
        s = field.filter_map do |sf|
          if !%w[0 1 4 6 8].member?(sf.code)
            " #{sf.value}"
          elsif sf.code == '4'
            ", #{mapping[sf.value]}"
          end
        end.join
        s2 = s + (!%w[. -].member?(s.last) ? '.' : '')
        s2.squish
      end

      # Partition a string by char, and return substring up to char
      # @todo remove unless i end up using in .search
      # @todo consider for move to Util and specs
      # @todo is it right to return empty string is char is not found? analyze contexts
      # @param [String] string
      # @param [String|RegEx] char
      # @return [String]
      def substring_before(string, char)
        string.scan(char).present? ? s.split(char, 2)[0] : ''
      end

      # Partition a string by char, and return substring after char
      # @todo consider for move to Util and specs
      # @todo is it right to return empty string is char is not found? analyze contexts
      # @param [String] string
      # @param [String|RegEx] char
      # @return [String]
      def substring_after(string, char)
        string.scan(char).present? ? string.split(char, 2)[1] : ''
      end
    end
  end
end
