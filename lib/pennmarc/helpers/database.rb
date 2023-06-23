# frozen_string_literal: true

module PennMARC
  # Parses Database Subject Category and Database Type local fields
  class Database < Helper
    # Database format type used to facet databases, found in
    # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Almalocal
    # local field 944} subfield 'a'.
    DATABASES_FACET_VALUE = 'Database & Article Index'
    # Penn Libraries' Community of Interest code used in
    # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Almalocal
    # local field 943} subfield '2'.
    COI_CODE = 'penncoi'

    class << self
      # Retrieves database subtype (subfield 'b') from
      # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Almalocal
      # local field 944}. Only returns database subtype if Penn's Database facet value is present in subfield 'a'.
      # @param [Marc::Record]
      # @return [Array<string>] Array of types
      def type(record)
        record.fields('944').filter_map do |field|
          # skip unless specified database format type present
          next unless subfield_value?(field, 'a', /#{DATABASES_FACET_VALUE}/)

          type = field.find { |subfield| subfield.code == 'b' }
          type&.value
        end
      end

      # Retrieves database subject category/communities of interest (subfield 'a') from
      # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Almalocal
      # local field 943}. Only returns database subject category if Penn's Community of Interest code is present in
      # subfield '2'.
      # @param [Marc::Record]
      # @return [Array<string>] Array of categories
      def db_category(record)
        return [] unless curated_db?(record)

        record.fields('943').filter_map do |field|
          # skip unless Community of Interest code is in subfield '2'
          next unless subfield_value?(field, '2', /#{COI_CODE}/)

          category = field.find { |subfield| subfield.code == 'a' }
          category&.value
        end
      end

      # Concatenates database subject category with database sub subject category in the format "category--subcategory"
      # if both values are present.
      # Retrieves both values respectively from subfield 'a' and subfield 'b' of
      # {https://upennlibrary.atlassian.net/wiki/spaces/ALMA/pages/323912493/Local+9XX+Field+Use+in+Almalocal
      # local field 943}. Only returns subcategory if Penn's Community of Interest code is present in subfield '2'.
      # @note return value differs from legacy implementation. This version only returns ["category--subcategory"] or
      #   an empty array.
      # @param [Marc::Record]
      # @return [Array<string>] Array of "category--subcategory"
      def db_subcategory(record)
        return [] unless curated_db?(record)

        record.fields('943').filter_map do |field|
          # skip unless Community of Interest code is in subfield '2'
          next unless subfield_value?(field, '2', /#{COI_CODE}/)

          category = field.find { |subfield| subfield.code == 'a' }

          # skip unless category is present
          next unless category.present?

          subcategory = field.find { |subfield| subfield.code == 'b' }

          # skip unless subcategory is present
          next unless subcategory.present?

          "#{category.value}--#{subcategory.value}"
        end
      end

      private

      # Determines if Database format type is format type used to facet databases
      # @param [Marc::Record]
      # @return [TrueClass, FalseClass]
      def curated_db?(record)
        record.fields('944').any? { |field| subfield_value?(field, 'a', /#{DATABASES_FACET_VALUE}/) }
      end
    end
  end
end
