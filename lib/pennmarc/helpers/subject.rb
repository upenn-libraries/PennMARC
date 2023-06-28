# frozen_string_literal: true

module PennMARC
  # This helper extracts subject heading in various ways to facilitate searching, faceting and display of subject
  # values. Michael Gibney did a lot to clean up Subject parsing in discovery-app, but much of it was intended to
  # support features (xfacet) that we will no longer support.
  class Subject < Helper
    class << self
      # All Subjects for searching
      #
      # @todo see get_subject_search_values, but there might be more to consider
      # @param [MARC::Record] record
      # @return [Array]
      def search(record); end

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
    end
  end
end
