# frozen_string_literal: true

module PennMARC
  # Do Note-y stuff
  class Note < Helper
    class << self
      # @param [MARC::Record] record
      # @return [Object]
      def notes_show(record)
        acc = []
        acc += record.fields(%w[500 502 504 515 518 525 533 550 580 586 588]).map do |field|
          if field.tag == '588'
            join_subfields(field, &subfield_in(%w[a]))
          else
            join_subfields(field, &subfield_not_in(%w[5 6 8]))
          end
        end
        acc += record.fields('880')
                     .select { |f| has_subfield6_value(f, /^(500|502|504|515|518|525|533|550|580|586|588)/) }
                     .map do |field|
          sub6 = field.select(&subfield_in(%w[6])).map(&:value).first
          if sub6 == '588'
            join_subfields(field, &subfield_in(%w[a]))
          else
            join_subfields(field, &subfield_not_in(%w[5 6 8]))
          end
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def local_notes_show(record)
        acc = []
        acc += record.fields('561')
                     .select { |f| f.any? { |sf| sf.code == 'a' && sf.value =~ /^Athenaeum copy: / } }
                     .map do |field|
          join_subfields(field, &subfield_in(%w[a]))
        end
        acc += record.fields(%w[562 563 585 590]).map do |field|
          join_subfields(field, &subfield_not_in(%w[5 6 8]))
        end
        acc += get_880(record, %w[562 563 585 590]) do |sf|
          !%w[5 6 8].member?(sf.code)
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def finding_aid_show(record)
        get_datafield_and_880(record, '555')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def provenance_show(record)
        acc = []
        acc += record.fields('561')
                     .select do |f|
                       ['1', '', ' '].member?(f.indicator1) &&
                         [' ', ''].member?(f.indicator2) &&
                         f.any? { |sf| sf.code == 'a' && sf.value !~ /^Athenaeum copy: / }
                     end.map do |field|
          value = join_subfields(field, &subfield_in(%w[a]))
          { value: value, link: false } if value
        end.compact
        acc += record.fields('880')
                     .select { |f| has_subfield6_value(f, /^561/) }
                     .select { |f| ['1', '', ' '].member?(f.indicator1) && [' ', ''].member?(f.indicator2) }
                     .map do |field|
          value = join_subfields(field, &subfield_in(%w[a]))
          { value: value, link: false } if value
        end.compact
        acc += get_650_and_880(record, 'PRO')
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def participant_show(record)
        get_datafield_and_880(record, '511')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def credits_show(record)
        get_datafield_and_880(record, '508')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def biography_show(record)
        get_datafield_and_880(record, '545')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def summary_show(record)
        get_datafield_and_880(record, '520')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def contents_show(record)
        acc = []
        acc += record.fields('505').flat_map do |field|
          join_subfields(field, &subfield_not_6_or_8).split('--')
        end
        acc += record.fields('880')
                     .select { |f| has_subfield6_value(f, /^505/) }
                     .flat_map do |field|
          join_subfields(field, &subfield_not_6_or_8).split('--')
        end
        acc
      end

      # @param [MARC::Record] record
      # @return [Object]
      def access_restriction_show(record)
        record.fields('506').map do |field|
          join_subfields(field, &subfield_not_in(%w[5 6]))
        end.select(&:present?)
      end
    end
  end
end
