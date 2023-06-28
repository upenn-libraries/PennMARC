# frozen_string_literal: true

module PennMARC
  # This helper extracts subject heading in various ways to facilitate searching, faceting and display of subject
  # values. Michael Gibney did a lot to "clean up" Subject parsing in discovery-app, but much of it was intended to
  # support features (xfacet) that we will no longer support, and ties display and xfacet field parsing together too
  # tightly to be preserved. As a result fo this, display methods and facet methods below are ported from their state
  # prior to Michael's 2/2021 subject parsing changes.
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

      # Tags that serve as sources for Subject facet values
      FACET_TAGS = %w[600 610 611 630 650 651].freeze

      # These codes are expected to be found in sf2 when the indicator2 value is 7, indicating "source specified". There
      # are some sources whose headings we don't want to display.
      ALLOWED_SUBJ_GENRE_ONTOLOGIES = %w[aat cct fast ftamc gmgpc gsafd homoit jlabsh lcgft lcsh lcstt lctgm
                                         local/osu mesh ndlsh nlksh rbbin rbgenr rbmscv rbpap rbpri rbprov rbpub rbtyp].freeze

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
              # TODO: use relation mapping method from Title helper? for potential URI support?
              # # sf 4 should contain a 3-letter code or URI "that specifies the relationship from the entity described
              # in the record to the entity referenced in the field"
              "#{sf.value}, #{relator_map[sf.value]}"
            else
              " #{sf.value}"
            end
          end
          next if subj_parts.empty?

          join_and_squish subj_parts
        end
      end

      # All Subjects for faceting
      #
      # @todo see get_subject_xfacet_values, this is copyField'ed into subject_f at index time, but there's some
      #       additional processing going on in the copyField action. there's also 'get_subject_facet_values' that is
      #       now put into 'toplevel_subject_f` - this is a more reasonable target for porting.
      # @param [MARC::Record] record
      # @return [Array]
      def facet(record)
        subject_fields(record, type: :facet).filter_map do |field|
          hash = build_subject_hash(field)
          next if hash[:count].zero?

          normalize_single_subfield(hash[:parts].first) if hash[:count].one?

          # assemble subject hash
          "#{hash[:parts].join('--')} #{hash[:lasts].join(' ')}".strip
        end
      end

      # when we've only encountered one subfield, assume that it might be a poorly-coded record
      # with a bunch of subdivisions mashed together, and attempt to convert it to a consistent
      # form.
      def normalize_single_subfield(first_part)
        first_part.gsub!(/([[[:alnum:]])])(\s+--\s*|\s*--\s+)([[[:upper:]][[:digit:]]])/, '\1--\3')
        first_part.gsub!(/([[[:alpha:]])])\s+-\s+([[:upper:]]|[[:digit:]]{2,})/, '\1--\2')
        first_part.gsub!(/([[[:alnum:]])])\s+-\s+([[:upper:]])/, '\1--\2')
      end

      # All Subjects for display
      #
      # @param [MARC::Record] record
      # @return [Array]
      def show(record); end

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

      # Get subject fields from a record based on expected usage type. Valid types are currently:
      # - search
      # - facet
      # @param [MARC::Record] record
      # @param [String, Symbol] type
      # @return [Array<MARC::DataField>] selected fields
      def subject_fields(record, type:)
        selector_method = case type.to_sym
                          when :search
                            :subject_search_field?
                          when :facet
                            :subject_facet_field?
                          else
                            raise StandardError # TODO: do better
                          end
        record.fields.find_all { |field| send(selector_method, field) }
      end

      # @param [MARC::DataField] field
      # @return [Boolean]
      def subject_facet_field?(field)
        return false if field.blank?

        return true if field.tag.in?(FACET_TAGS) && field.indicator2.in?(%w[0 2 4])

        return true if field.indicator2 == '7' && valid_ontology_code?(field)

        false
      end

      # @param [MARC::DataField] field
      # @return [Boolean]
      def valid_ontology_code?(field)
        field.any? do |subfield|
          subfield.code == '2' && subfield.value.in?(ALLOWED_SUBJ_GENRE_ONTOLOGIES)
        end
      end

      # @note Note that we must separately track count (as opposed to simply checking `parts.size`),
      #       because we're using "subdivision count" as a heuristic for the quality level of the heading. - MG
      # @todo do i need all this?
      # @todo do i need to handle punctuation? see append_new_part
      def build_subject_hash(field)
        term_info = { count: 0, parts: [], append: [], lasts: [],
                      local: field.indicator2 == '4' || field.tag.starts_with?('69'), # local subject heading
                      vernacular: field.tag == '880' }
        field.each do |subfield|
          case subfield.code
          when '0', '6', '8', '5', '1'
            # ignore these subfields
            next
          when 'a'
            # filter out PRO/CHR entirely (but only need to check on local heading types)
            return nil if term_info[:local] && subfield.value =~ /^%?(PRO|CHR)([ $]|$)/
          when '2'
            # use the _last_ source specified, so don't worry about overriding any prior values
            term_info[:source_specified] = subfield.value.strip
            next
          when 'e', 'w'
            # 'e' is relator term; not sure what 'w' is. These are used to append for record-view display only
            term_info[:append] << subfield.value.strip
            next
          when 'b', 'c', 'd', 'p', 'q', 't'
            # these are appended to the last component if possible (i.e., when joined, should have no delimiter)
            term_info[:lasts] << subfield.value.strip
            term_info[:count] += 1
            next
          else
            # the usual case; add a new component to `parts`
            term_info[:parts] << subfield.value.strip
            term_info[:count] += 1
          end
        end
        term_info
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
