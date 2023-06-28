# frozen_string_literal: true

module PennMARC
  # This helper extracts subject heading in various ways to facilitate searching, faceting and display of subject
  # values. Michael Gibney did a lot to clean up Subject parsing in discovery-app, but much of it was intended to
  # support features (xfacet) that we will no longer support.
  class Subject < Helper
    class << self
      # Tags that serve as sources for Subject search values
      # @todo why are 541 and 561 included here?
      SEARCH_TAGS = %w[541 561 600 610 611 630 650 651 653].freeze
      # Valid indicator 2 values indicating the source thesaurus for subject terms. These are:
      # - 0: LCSH
      # - 1: LC Children's
      # - 2: MeSH
      # - 4: Source not specified (local?)
      # - 7: Source specified in ǂ2
      SEARCH_SOURCE_INDICATORS = %w[0 1 2 4 7].freeze

      # All Subjects for searching. This includes most subfield content from any field contained in {SEARCH_TAGS} or 69X,
      # including any linked 880 fields. Fields must have an indicator2 value in {SEARCH_SOURCE_INDICATORS}.
      # @todo this includes subfields that may not be desired like 1 (uri) and 2 (source code) but this might be OK for
      #       a search (non-display) field?
      # @note ported from get_subject_search_values
      # @param [Hash] relator_map
      # @param [MARC::Record] record
      # @return [Array]
      def search(record, relator_map)
        subject_search_fields(record).filter_map do |field|
          subj_parts = field.filter_map do |sf|
            next if sf.code.in? %w[5 6 8]

            # TODO: why do we care about punctuation in a search field? relator mapping?
            case sf.code
            when 'a'
              " #{sf.value.gsub(/^%?(PRO|CHR)/, '').gsub(/\?$/, '')}" # TODO: what is this regex doing?
            when '4'
              "#{sf.value}, #{relator_map[sf.value]}"
            else
              " #{sf.value}"
            end
          end
          next if subj_parts.empty?

          join_and_squish subj_parts
        end
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

      # Return valid Subject Search fields from a record
      # @param [MARC::Record] record
      # @return [Array<MARC::DataField>]
      def subject_search_fields(record)
        record.fields.find_all { |field| subject_search_field? field }
      end

      # Determine if a field should be considered for Subject search inclusion. It must be either contained in
      # SEARCH_TAGS, be an 880 field otherwise linked to a valid Search tag, or be a 69X field (local subject).
      # THe indicator 2 of any field cannot be in
      # @param [MARC::DataField] field
      # @return [Boolean]
      def subject_search_field?(field)
        return false if field.blank? || SEARCH_SOURCE_INDICATORS.exclude?(field.indicator2)

        if subject_search_tag?(field.tag)
          true
        elsif field.tag == '880'
          sub6 = field.find_all { |sf| sf.code == '6' }.map(&:value).first
          subject_search_tag? sub6
        else
          false
        end
      end

      # Is a given tag a subject search field? Yes if it is contained in SEARCH_TAGS or starts with 69.
      # @param [String, NilClass] tag
      # @return [Boolean]
      def subject_search_tag?(tag)
        return false if tag.blank?

        tag = tag[0..2]
        tag&.in?(SEARCH_TAGS) || tag&.start_with?('69')
      end
    end
  end
end
