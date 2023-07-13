# frozen_string_literal: true

module PennMARC
  # Extracts notes from {https://www.oclc.org/bibformats/en/5xx.html 5xx} fields (mostly).
  class Note < Helper
    class << self
      # Retrieve notes for display from fields {https://www.oclc.org/bibformats/en/5xx/500.html 500},
      # {https://www.oclc.org/bibformats/en/5xx/502.html 502}, {https://www.oclc.org/bibformats/en/5xx/504.html 504},
      # {https://www.oclc.org/bibformats/en/5xx/515.html 515}, {https://www.oclc.org/bibformats/en/5xx/518.html 518}
      # {https://www.oclc.org/bibformats/en/5xx/525.html 525}, {https://www.oclc.org/bibformats/en/5xx/533.html 533},
      # {https://www.oclc.org/bibformats/en/5xx/550.html 550}, {https://www.oclc.org/bibformats/en/5xx/580.html 580},
      # {https://www.oclc.org/bibformats/en/5xx/586.html 586}, {https://www.oclc.org/bibformats/en/5xx/588.html 588},
      # and their linked alternates.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def notes_show(record)
        notes_fields = %w[500 502 504 515 518 525 533 550 580 586 588]
        record.fields(notes_fields + ['880']).filter_map do |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', notes_fields)

          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
      end

      # Retrieve local notes for display from fields {https://www.oclc.org/bibformats/en/5xx/561.html 561},
      # {https://www.oclc.org/bibformats/en/5xx/562.html 562}, {https://www.oclc.org/bibformats/en/5xx/563.html 563},
      # {https://www.oclc.org/bibformats/en/5xx/585.html 585}, {https://www.oclc.org/bibformats/en/5xx/590.html 590}.
      # Includes linked alternates except for 561.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def local_notes_show(record)
        local_notes = record.fields('561').filter_map do |field|
          next unless subfield_value?(field, 'a', /^Athenaeum copy: /)

          join_subfields(field, &subfield_in?(%w[a]))
        end
        local_notes + record.fields(%w[562 563 585 590 880]).map do |field|
          join_subfields(field, &subfield_not_in?(%w[5 6 8]))
        end
      end

      # Retrieve provenance notes for display from fields {https://www.oclc.org/bibformats/en/5xx/561.html 561} and
      # prefixed subject field {https://www.oclc.org/bibformats/en/6xx/650.html 650} and its linked alternate.
      # Ignores 561 fields with subfield 'a' values that begin with 'Athenaeum copy: ' and 650 fields where subfield 'a'
      # does not have the prefix 'PRO'.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def provenance_show(record)
        provenance_notes = record.fields(%w[561 880]).filter_map do |field|
          next unless field.indicator1.in?(['1', '', ' '])

          next unless field.indicator2.in?([' ', ''])

          next if subfield_value?(field, 'a', /^Athenaeum copy: /)

          join_subfields(field, &subfield_in?(%w[a]))
        end
        provenance_notes + prefixed_subject_and_alternate(record, 'PRO')
      end

      # Retrieve contents notes for display from fields {https://www.oclc.org/bibformats/en/5xx/505.html 505} and
      # its linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def contents_show(record)
        record.fields(%w[505 880]).filter_map do |field|
          next if field.tag == '880' && subfield_value_not_in?(field, '6', %w[505])

          join_subfields(field, &subfield_not_in?(%w[6 8])).split('--')
        end.flatten
      end

      # Retrieve access restricted notes for display from field {https://www.oclc.org/bibformats/en/5xx/506.html 506}.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def access_restriction_show(record)
        record.fields('506').filter_map do |field|
          join_subfields(field, &subfield_not_in?(%w[5 6]))
        end
      end

      # Retrieve finding aid notes for display from field {https://www.oclc.org/bibformats/en/5xx/555.html 555} and its
      # linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def finding_aid_show(record)
        datafield_and_linked_alternate(record, '555')
      end

      # Retrieve participant notes for display from field {https://www.oclc.org/bibformats/en/5xx/511.html 511} and its
      # linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def participant_show(record)
        datafield_and_linked_alternate(record, '511')
      end

      # Retrieve credits notes for display from field {https://www.oclc.org/bibformats/en/5xx/508.html 508} and its
      # linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def credits_show(record)
        datafield_and_linked_alternate(record, '508')
      end

      # Retrieve biography notes for display from field {https://www.oclc.org/bibformats/en/5xx/545.html 545} and its
      # linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def biography_show(record)
        datafield_and_linked_alternate(record, '545')
      end

      # Retrieve summary notes for display from field {https://www.oclc.org/bibformats/en/5xx/520.html 520} and its
      # linked alternate.
      # @param [MARC::Record] record
      # @return [Array<String>]
      def summary_show(record)
        datafield_and_linked_alternate(record, '520')
      end
    end
  end
end
