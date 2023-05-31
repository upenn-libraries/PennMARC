# frozen_string_literal: true

require_relative 'marc_util'

module PennMARC
  # Do Title-y stuff
  # https://www.loc.gov/marc/bibliographic/bd245.html
  class Title
    extend MarcUtil

    attr_accessor :record

    TITLE_STATEMENT = '245'
    ALTERNATE_TITLE_FIELD = '880'

    def initialize(record:)
      @record = record
    end

    # @return [Array<MARC::Datafield>]
    def title_statement
      @title_statement ||= record.fields(TITLE_STATEMENT)
    end

    def alt_representation
      @alt_representation ||= record.fields(ALTERNATE_TITLE_FIELD)
                                    .select { |field| subfield_value?(field, 6, /^#{TITLE_STATEMENT}/) }
    end

    def display
      # standard = title_statement.map { |field| join_subfields(field, &subfield_not_in(%w[6 8])) }
      # alternate = alt_representation.map do |alt|
      #   alt.fields.reject { |subfield| subfield.value.in? %w[6 8] }.join(' ')
      # end
    end

    private

    #
    #
    # class << self
    #   def for_search(record)
    #     record.fields(TITLE_FIELD).take(1).map do |field|
    #       a_or_k = field.find_all(&subfield_in?(%w[a k]))
    #                     .map { |sf| trim_trailing(:comma, trim_trailing(:slash, sf.value).rstrip) }
    #                     .first || ''
    #       joined = field.find_all(&subfield_in?(%w[b n p]))
    #                     .map { |sf| trim_trailing(:slash, sf.value) }
    #                     .join(' ')
    #
    #       apunct = a_or_k[-1]
    #       hpunct = field.find_all { |sf| sf.code == 'h' }
    #                     .map { |sf| sf.value[-1] }
    #                     .first
    #       punct = if [apunct, hpunct].member?('=')
    #                 '='
    #               else
    #                 [apunct, hpunct].member?(':') ? ':' : nil
    #               end
    #
    #       [trim_trailing(:colon, trim_trailing(:equal, a_or_k)), punct, joined]
    #         .select(&:present?).join(' ')
    #     end
    #   end
    #
    #   # @param [MARC::Record] record
    #   # @return [String]
    #   def for_display(record)
    #     acc = []
    #     acc += record.fields(TITLE_FIELD).map do |field|
    #       join_subfields(field, &subfield_not_in(%w[6 8]))
    #     end
    #     acc += linked_alternate(record, TITLE_FIELD, &subfield_not_in(%w[6 8]))
    #            .map { |value| " = #{value}" }
    #     acc.join(' ')
    #   end
    #
    #   # Canonical title, with nonfiling characters removed, if present and specified
    #   # TODO: it seems we are currently using a multivalued field for sorting...check the schema...
    #   def for_sort(record)
    #
    #   end
    #
    #   # get title values form fields (e.g., 240 and/or 880)
    #   def title(record, include_alternates:); end
    # end
  end
end
