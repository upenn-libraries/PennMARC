# frozen_string_literal: true

module PennMARC
  # This helper extracts subject heading in various ways to facilitate searching, faceting and display of subject
  # values. Michael Gibney did a lot to clean up Subject parsing in discovery-app, but much of it was intended to
  # support features (xfacet) that we will no longer support.
  class Subject < Helper
    class << self
      SEARCH_TAGS = %w[541 561 600 610 611 630 650 651 653].freeze
      
      # All Subjects for searching
      #
      # @note ported from get_subject_search_values
      # @param [Hash] relator_map
      # @param [MARC::Record] record
      # @return [Array]
      def search(record, relator_map)
        record.fields.find_all { |f| is_subject_search_field(f) }
              .map do |field|
          subj = []
          field.each do |sf|
            if sf.code == 'a'
              subj << " #{sf.value.gsub(/^%?(PRO|CHR)/, '').gsub(/\?$/, '')}" # TODO: what is this regex doing
            elsif sf.code == '4'
              subj << "#{sf.value}, #{relator_map[sf.value]}"
            elsif !%w[a 4 5 6 8].member?(sf.code)
              subj << " #{sf.value}"
            end
          end
          join_and_squish(subj) if subj.present?
        end.compact
      end

      # All Subjects for display
      #
      # @todo port get_subject_display
      # @param [MARC::Record] record
      # @return [Array]
      def show(record); end

      # All Subjects for faceting
      #
      # @todo see get_subject_xfacet_values, but there may be more to consider
      # @param [MARC::Record] record
      # @return [Array]
      def facet(record); end

      # Get Subjects from "Children" ontology
      #
      # @todo port get_children_subject_display
      # @param [MARC::Record] record
      # @return [Array]
      def childrens_show(record); end

      # Get Subjects from "MeSH" ontology
      #
      # @todo port get_medical_subject_display
      # @param [MARC::Record] record
      # @return [Array]
      def medical_show(record); end

      # Get Subject from local ontology
      #
      # @todo port get_local_subject_display
      # @param [MARC::Record] record
      # @return [Array]
      def local_show(record); end
      
      private
      
      # @param [MARC::DataField] field
      # @return [Boolean]
      def subject_search_field?(field)
        if !(field.respond_to?(:indicator2) && %w[0 1 2 4 7].member?(field.indicator2))
          false
        elsif SEARCH_TAGS.member?(field.tag) || field.tag.start_with?('69')
          true
        elsif field.tag == '880'
          sub6 = (field.find_all { |sf| sf.code == '6' }.map(&:value).first || '')[0..2]
          SEARCH_TAGS.member?(sub6) || sub6.start_with?('69')
        else
          false
        end
      end
    end
  end
end
