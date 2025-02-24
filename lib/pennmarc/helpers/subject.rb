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
      # @todo why are 541 and 561 included here? these fields include info about source of acquisition
      SEARCH_TAGS = %w[541 561 600 610 611 630 650 651 653].freeze

      # Valid indicator 2 values indicating the source thesaurus for subject terms. These are:
      # - 0: LCSH
      # - 1: LC Children's
      # - 2: MeSH
      # - 4: Source not specified (local?)
      # - 7: Source specified in ǂ2
      VALID_SOURCE_INDICATORS = %w[0 1 2 4 7].freeze

      # Tags that serve as sources for Subject facet values
      DISPLAY_TAGS = %w[600 610 611 630 650 651].freeze

      # Local subject heading tags
      LOCAL_TAGS = %w[690 691 697].freeze

      # All Subjects for searching. This includes most subfield content from any field contained in {SEARCH_TAGS} or
      # 69X, including any linked 880 fields. Fields must have an indicator2 value in {VALID_SOURCE_INDICATORS}.
      # @todo this includes subfields that may not be desired like 1 (uri) and 2 (source code) but this might be OK for
      #       a search (non-display) field?
      # @param relator_map [Hash]
      # @param record [MARC::Record]
      # @return [Array<String>] array of all subject values for search
      def search(record, relator_map: Mappers.relator)
        subject_fields(record, type: :search).filter_map { |field|
          subj_parts = field.filter_map do |subfield|
            # TODO: use term hash here? pro/chr would be rejected...
            # TODO: should we care about punctuation in a search field? relator mapping?
            case subfield.code
            when '5', '6', '8', '7' then next
            when 'a'
              # remove %PRO or PRO or %CHR or CHR
              # remove any ? at the end
              subfield.value.gsub(/^%?(PRO|CHR)/, '').gsub(/\?$/, '').strip
            when '4'
              # sf 4 should contain a 3-letter code or URI "that specifies the relationship from the entity described
              # in the record to the entity referenced in the field"
              "#{subfield.value} #{translate_relator(subfield.value.to_sym, relator_map)}".strip
            else
              subfield.value
            end
          end
          next if subj_parts.empty?

          join_and_squish subj_parts
        }.uniq
      end

      # All Subjects for faceting
      #
      # @note this is ported mostly form MG's new-style Subject parsing
      # @param record [MARC::Record]
      # @param override [Boolean] remove undesirable terms or not
      # @return [Array<String>] array of all subject values for faceting
      def facet(record, override: true)
        values = subject_fields(record, type: :facet).filter_map { |field|
          term_hash = build_subject_hash(field)
          next if term_hash.blank? || term_hash[:count]&.zero?

          format_term type: :facet, term: term_hash
        }.uniq
        override ? HeadingControl.term_override(values) : values
      end

      # All Subjects for display. This includes all {DISPLAY_TAGS} and {LOCAL_TAGS}. For tags that specify a source,
      # only those with an allowed source code (see ALLOWED_SOURCE_CODES) are included.
      #
      # @param record [MARC::Record]
      # @param override [Boolean] to remove undesirable terms or not
      # @return [Array] array of all subject values for display
      def show(record, override: true)
        values = subject_fields(record, type: :all).filter_map { |field|
          term_hash = build_subject_hash(field)
          next if term_hash.blank? || term_hash[:count]&.zero?

          format_term type: :display, term: term_hash
        }.uniq
        override ? HeadingControl.term_override(values) : values
      end

      # Get Subjects from "Children" ontology
      #
      # @param record [MARC::Record]
      # @param override [Boolean] remove undesirable terms or not
      # @return [Array] array of children's subject values for display
      def childrens_show(record, override: true)
        values = subject_fields(record, type: :display, options: { tags: DISPLAY_TAGS, indicator2: '1' })
                 .filter_map { |field|
          term_hash = build_subject_hash(field)
          next if term_hash.blank? || term_hash[:count]&.zero?

          format_term type: :display, term: term_hash
        }.uniq
        override ? HeadingControl.term_override(values) : values
      end

      # Get Subjects from "MeSH" ontology
      #
      # @param record [MARC::Record]
      # @param override [Boolean] remove undesirable terms or not
      # @return [Array] array of MeSH subject values for display
      def medical_show(record, override: true)
        values = subject_fields(record, type: :display, options: { tags: DISPLAY_TAGS, indicator2: '2' })
                 .filter_map { |field|
          term_hash = build_subject_hash(field)
          next if term_hash.blank? || term_hash[:count]&.zero?

          format_term type: :display, term: term_hash
        }.uniq
        override ? HeadingControl.term_override(values) : values
      end

      # Get Subject values from {DISPLAY_TAGS} where indicator2 is 4 and {LOCAL_TAGS}. Do not include any values where
      # sf2 includes "penncoi" (Community of Interest).
      #
      # @param record [MARC::Record]
      # @param override [Boolean] to remove undesirable terms
      # @return [Array] array of local subject values for display
      def local_show(record, override: true)
        local_fields = subject_fields(record, type: :display, options: { tags: DISPLAY_TAGS, indicator2: '4' }) +
                       subject_fields(record, type: :local)
        values = local_fields.filter_map { |field|
          next if subfield_value?(field, '2', /penncoi/)

          term_hash = build_subject_hash(field)
          next if term_hash.blank? || term_hash[:count]&.zero?

          format_term type: :display, term: term_hash
        }.uniq
        override ? HeadingControl.term_override(values) : values
      end

      private

      # Get subject fields from a record based on expected usage type. Valid types are currently:
      # - search
      # - facet
      # - display
      # - local
      # @param record [MARC::Record]
      # @param type [String, Symbol] type of fields desired
      # @param options [Hash] options to be passed to the selector method
      # @return [Array<MARC::DataField>] selected fields
      def subject_fields(record, type:, options: {})
        selector_method = case type.to_sym
                          when :search then :subject_search_field?
                          when :facet then :subject_facet_field?
                          when :display then :subject_display_field?
                          when :local then :subject_local_field?
                          when :all then :subject_general_display_field?
                          else
                            raise ArgumentError("Unsupported type specified: #{type}")
                          end
        record.fields.find_all do |field|
          options.any? ? send(selector_method, field, options) : send(selector_method, field)
        end
      end

      # Format a term hash as a string for display
      #
      # @todo support search field formatting?
      # @param type [Symbol]
      # @param term [Hash] components and information as a hash
      # @return [String]
      def format_term(type:, term:)
        return unless type.in? %i[facet display]

        # attempt to handle poorly coded record
        normalize_single_subfield(term[:parts].first) if term[:count] == 1 && term[:parts].first.present?

        case type
        when :facet
          trim_trailing(:period, term[:parts].join('--').strip)
        when :display
          display_value = "#{term[:parts].join('--')} #{term[:append].join(' ')}".strip
          display_value.ends_with?('.') ? display_value : "#{display_value}."
        end
      end

      # Is a field intended for display in a general subject field? To be included, the field tag is in either
      # {DISPLAY_TAGS} or {LOCAL_TAGS}, and has an indicator 2 value that is in {VALID_SOURCE_INDICATORS}. If
      # indicator 2 is '7' - indicating "source specified", the specified source must be in our approved source code
      # list.
      # @see Util.valid_subject_genre_source_code?
      # @param field [MARC::DataField]
      # @return [Boolean] whether a MARC field is intended for display under general "Subjects"
      def subject_general_display_field?(field)
        return false unless field.tag.in?(DISPLAY_TAGS + LOCAL_TAGS) && field.respond_to?(:indicator2)

        return false if field.indicator2.present? && !field.indicator2.in?(VALID_SOURCE_INDICATORS)

        return false if field.indicator2 == '7' && !valid_subject_genre_source_code?(field)

        true
      end

      # @param field [MARC::DataField]
      # @return [Boolean] whether a MARC field is a local subject field (69X)
      def subject_local_field?(field)
        field.tag.in? LOCAL_TAGS
      end

      # @param field [MARC::DataField]
      # @param options [Hash] include :tags and :indicator2 values
      # @return [Boolean] whether a MARC field should be considered for display
      def subject_display_field?(field, options)
        return false unless field.respond_to?(:indicator2)

        return true if field.tag.in?(options[:tags]) && field.indicator2.in?(options[:indicator2])

        false
      end

      # @param field [MARC::DataField]
      # @return [Boolean]
      def subject_facet_field?(field)
        return false unless field.respond_to?(:indicator2)

        return true if field.tag.in?(DISPLAY_TAGS) && field.indicator2.in?(%w[0 2 4])

        return true if field.tag.in?(DISPLAY_TAGS) && field.indicator2 == '7' && valid_subject_genre_source_code?(field)

        false
      end

      # Build a hash of Subject field components for analysis or for building a string.
      #
      # @note Note that we must separately track count (as opposed to simply checking `parts.size`),
      #       because we're using (where? - MK) "subdivision count" as a heuristic for the quality level of the
      #       heading. - MG
      # @todo do i need all this?
      # @param field [MARC::DataField]
      # @return [Hash{Symbol => Integer, Array, Boolean}, Nil]
      def build_subject_hash(field)
        term_info = { count: 0, parts: [], append: [], uri: nil,
                      local: field.indicator2 == '4' || field.tag.starts_with?('69'), # local subject heading
                      vernacular: field.tag == '880' }
        field.each do |subfield|
          case subfield.code
          when '0', '6', '8', '5', '7'
            # explicitly ignore these subfields
            next
          when '1'
            term_info[:uri] = subfield.value.strip
          when 'a'
            # filter out PRO/CHR entirely (but only need to check on local heading types)
            return nil if term_info[:local] && subfield.value =~ /^%?(PRO|CHR)([ $]|$)/

            # remove trailing punctuation of previous subject part
            trim_trailing_commas_or_periods!(term_info[:parts].last)

            term_info[:parts] << subfield.value.strip
            term_info[:count] += 1
          when '2'
            term_info[:source] = subfield.value.strip
          when 'e', 'w'
            # 'e' is relator term; not sure what 'w' is. These are used to append for record-view display only
            term_info[:append] << subfield.value.strip # TODO: map relator code?
          when 'b', 'c', 'd', 'p', 'q', 't'
            # these are appended to the last component (part) if possible (i.e., when joined, should have no delimiter)
            # if there is no preceding part then this is simply added to the parts array
            to_append = " #{subfield.value.strip}"

            term_info[:parts].empty? ? term_info[:parts] << subfield.value.strip : term_info[:parts].last << to_append
            term_info[:count] += 1
          else
            # the usual case; add a new component to `parts`
            # this typically includes g, v, x, y, z, 4

            # remove trailing punctuation of previous subject part
            trim_trailing_commas_or_periods!(term_info[:parts].last)

            term_info[:parts] << subfield.value.strip
            term_info[:count] += 1
          end
        end
        term_info
      end

      # Determine if a field should be considered for Subject search inclusion. It must be either contained in
      # {SEARCH_TAGS}, be an 880 field otherwise linked to a valid Search tag, or be in {LOCAL_TAGS}.
      # @param field [MARC::DataField]
      # @return [Boolean]
      def subject_search_field?(field)
        return false unless field.respond_to?(:indicator2) && VALID_SOURCE_INDICATORS.include?(field.indicator2)

        tag = if field.tag == '880'
                subfield_values(field, '6').first
              else
                field.tag
              end
        subject_search_tag? tag
      end

      # Is a given tag a subject search field? Yes if it is contained in {SEARCH_TAGS} or starts with 69.
      # @param tag [String, nil]
      # @return [Boolean]
      def subject_search_tag?(tag)
        return false if tag.blank?

        tag = tag[0..2]
        tag&.in?(SEARCH_TAGS) || tag&.start_with?('69')
      end

      # when we've only encountered one subfield, assume that it might be a poorly-coded record
      # with a bunch of subdivisions mashed together, and attempt to convert it to a consistent
      # form.
      # @param first_part [String]
      # @return [String, nil] normalized string
      def normalize_single_subfield(first_part)
        first_part.gsub!(/([[[:alnum:]])])(\s+--\s*|\s*--\s+)([[[:upper:]][[:digit:]]])/, '\1--\3')
        first_part.gsub!(/([[[:alpha:]])])\s+-\s+([[:upper:]]|[[:digit:]]{2,})/, '\1--\2')
        first_part.gsub!(/([[[:alnum:]])])\s+-\s+([[:upper:]])/, '\1--\2')
      end

      # removes trailing comma or period, manipulating the string in place
      # @param subject_part [String, nil]
      # @return [String, nil]
      def trim_trailing_commas_or_periods!(subject_part)
        return if subject_part.blank?

        trim_trailing!(:comma, subject_part) || trim_trailing!(:period, subject_part)
      end
    end
  end
end
