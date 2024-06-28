# frozen_string_literal: true

module PennMARC
  # Extracts notes from {https://www.oclc.org/bibformats/en/5xx.html 5xx} fields (mostly).
  class Note < Helper
    class << self
      # Retrieve notes for display from fields {https://www.oclc.org/bibformats/en/5xx/500.html 500},
      # {https://www.oclc.org/bibformats/en/5xx/502.html 502}, {https://www.oclc.org/bibformats/en/5xx/504.html 504},
      # {https://www.oclc.org/bibformats/en/5xx/515.html 515}, {https://www.oclc.org/bibformats/en/5xx/518.html 518},
      # {https://www.oclc.org/bibformats/en/5xx/525.html 525}, {https://www.oclc.org/bibformats/en/5xx/533.html 533},
      # {https://www.oclc.org/bibformats/en/5xx/540.html 540}, {https://www.oclc.org/bibformats/en/5xx/550.html 550},
      # {https://www.oclc.org/bibformats/en/5xx/580.html 580}, {https://www.oclc.org/bibformats/en/5xx/586.html 586},
      # {https://www.oclc.org/bibformats/en/5xx/588.html 588}
      # and their linked alternates.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def notes_show(record)
        notes_fields = %w[500 502 504 515 518 525 533 540 550 580 586 588]
        record.fields(notes_fields + ['880']).filter_map { |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^(#{notes_fields.join('|')})/)

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        }.uniq
      end

      # Retrieve local notes for display from fields {https://www.oclc.org/bibformats/en/5xx/561.html 561},
      # {https://www.oclc.org/bibformats/en/5xx/562.html 562}, {https://www.oclc.org/bibformats/en/5xx/563.html 563},
      # {https://www.oclc.org/bibformats/en/5xx/585.html 585}, {https://www.oclc.org/bibformats/en/5xx/590.html 590}.
      # Includes linked alternates except for 561.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def local_notes_show(record)
        local_notes = record.fields('561').filter_map do |field|
          next unless subfield_value?(field, 'a', /^Athenaeum copy: /)

          join_subfields(field, &subfield_in?(%w[a]))
        end

        additional_fields = %w[562 563 585 590]

        notes = local_notes + record.fields(additional_fields + ['880']).filter_map do |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^(#{additional_fields.join('|')})/)

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
        notes.uniq
      end

      # Retrieve provenance notes for display from fields {https://www.oclc.org/bibformats/en/5xx/561.html 561} and
      # prefixed subject field {https://www.oclc.org/bibformats/en/6xx/650.html 650} and its linked alternate.
      # Ignores 561 fields with subfield 'a' values that begin with 'Athenaeum copy: ' and 650 fields where subfield 'a'
      # does not have the prefix 'PRO'.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def provenance_show(record)
        provenance_notes = record.fields(%w[561 880]).filter_map do |field|
          next unless field.indicator1.in?(['1', '', ' '])

          next unless field.indicator2.in?([' ', ''])

          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^561/)

          next if subfield_value?(field, 'a', /^Athenaeum copy: /)

          join_subfields(field, &subfield_in?(%w[a]))
        end
        notes = provenance_notes + prefixed_subject_and_alternate(record, 'PRO')
        notes.uniq
      end

      # Retrieve contents notes for display from fields {https://www.oclc.org/bibformats/en/5xx/505.html 505} and, if
      # include_vernacular param is true, its linked alternate. Used for display and searching.
      # @param record [MARC::Record]
      # @param include_vernacular [Boolean]
      # @return [Array<String>]
      def contents_values(record, include_vernacular: true)
        record.fields(%w[505 880]).filter_map { |field|
          if field.tag == '880'
            next unless include_vernacular

            next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^505/)
          end

          join_subfields(field, &subfield_not_in?(%w[6 8])).split('--')
        }.flatten.uniq
      end

      # Get content note values for searching
      # @param record [MARC::Record]
      # @return [Array<String>]
      def contents_search(record)
        record.fields('505').map do |field|
          join_subfields(field, &subfield_in?(%w[a g r t u]))
        end
      end

      # Retrieve access restricted notes for display from field {https://www.oclc.org/bibformats/en/5xx/506.html 506}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def access_restriction_show(record)
        record.fields('506').filter_map { |field|
          join_subfields(field, &subfield_not_in?(%w[5 6]))
        }.uniq
      end

      # Retrieve finding aid notes for display from field {https://www.oclc.org/bibformats/en/5xx/555.html 555} and its
      # linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def finding_aid_show(record)
        datafield_and_linked_alternate(record, '555')
      end

      # Retrieve participant notes for display from field {https://www.oclc.org/bibformats/en/5xx/511.html 511} and its
      # linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def participant_show(record)
        datafield_and_linked_alternate(record, '511')
      end

      # Retrieve credits notes for display from field {https://www.oclc.org/bibformats/en/5xx/508.html 508} and its
      # linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def credits_show(record)
        datafield_and_linked_alternate(record, '508')
      end

      # Retrieve biography notes for display from field {https://www.oclc.org/bibformats/en/5xx/545.html 545} and its
      # linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def biography_show(record)
        datafield_and_linked_alternate(record, '545')
      end

      # Retrieve summary notes for display from field {https://www.oclc.org/bibformats/en/5xx/520.html 520} and its
      # linked alternate.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def summary_show(record)
        datafield_and_linked_alternate(record, '520')
      end

      # Retrieve arrangement values for display from field field {https://www.oclc.org/bibformats/en/3xx/351.html 351}.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def arrangement_show(record)
        datafield_and_linked_alternate(record, '351')
      end

      # Retrieve system details notes for display from fields {https://www.oclc.org/bibformats/en/5xx/538.html 538},
      # {https://www.oclc.org/bibformats/en/3xx/344.html 344}, {https://www.oclc.org/bibformats/en/3xx/345.html 345},
      # {https://www.oclc.org/bibformats/en/3xx/346.html 346}, {https://www.oclc.org/bibformats/en/3xx/347.html 347},
      # and their linked alternates.
      # @param record [MARC::Record]
      # @return [Array<String>]
      def system_details_show(record)
        system_details_notes = record.fields(%w[538 880]).filter_map do |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^538/)

          sub3_and_other_subs(field, &subfield_in?(%w[a i u]))
        end
        system_details_notes += record.fields(%w[344 880]).filter_map do |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^344/)

          sub3_and_other_subs(field, &subfield_in?(%w[a b c d e f g h]))
        end
        system_details_notes += record.fields(%w[345 346 880]).filter_map do |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^(345|346)/)

          sub3_and_other_subs(field, &subfield_in?(%w[a b]))
        end
        system_details_notes += record.fields(%w[347 880]).filter_map do |field|
          next if field.tag == '880' && no_subfield_value_matches?(field, '6', /^347/)

          sub3_and_other_subs(field, &subfield_in?(%w[a b c d e f]))
        end
        system_details_notes.uniq
      end

      # Retrieve "With" notes for display from field {https://www.loc.gov/marc/bibliographic/bd501.html 501}
      # @param record [Marc::Record]
      # @return [Array<String>]
      def bound_with_show(record)
        record.fields('501').filter_map { |field| join_subfields(field, &subfield_in?(['a'])).presence }.uniq
      end

      private

      # For system details: extract subfield ǂ3 plus other subfields as specified by passed-in block. Pays special
      # attention to punctuation, joining subfield ǂ3 values with a colon-space (': ').
      # @param field [MARC::DataField]
      # @param & [Proc]
      # @return [String]
      def sub3_and_other_subs(field, &)
        sub3 = field.filter_map { |sf| trim_trailing('period', sf.value) if sf.code == '3' }.join(': ')
        oth_subs = join_subfields(field, &)
        [sub3, trim_trailing('semicolon', oth_subs)].join(' ')
      end
    end
  end
end
