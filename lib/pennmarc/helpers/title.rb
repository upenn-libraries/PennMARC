# frozen_string_literal: true

module PennMARC
  # Do Title-y stuff
  # https://www.loc.gov/marc/bibliographic/bd245.html
  class Title < Helper
    TITLE_STATEMENT = '245'
    ALTERNATE_TITLE_FIELD = '880'

    class << self
      def search(record)
        record.fields(TITLE_STATEMENT).take(1).map do |field|
          a_or_k = field.find_all(&subfield_in?(%w[a k]))
                        .map { |sf| trim_trailing(:comma, trim_trailing(:slash, sf.value).rstrip) }
                        .first || ''
          joined = field.find_all(&subfield_in?(%w[b n p]))
                        .map { |sf| trim_trailing(:slash, sf.value) }
                        .join(' ')

          apunct = a_or_k[-1]
          hpunct = field.find_all { |sf| sf.code == 'h' }
                        .map { |sf| sf.value[-1] }
                        .first
          punct = if [apunct, hpunct].member?('=')
                    '='
                  else
                    [apunct, hpunct].member?(':') ? ':' : nil
                  end

          [trim_trailing(:colon, trim_trailing(:equal, a_or_k)), punct, joined]
            .select(&:present?).join(' ')
        end
      end

      # @param [MARC::Record] record
      # @return [String]
      def show(record)
        acc = []
        acc += record.fields(TITLE_STATEMENT).map do |field|
          join_subfields(field, &subfield_not_in?(%w[6 8]))
        end
        acc += linked_alternate(record, TITLE_STATEMENT, &subfield_not_in?(%w[6 8]))
               .map { |value| " = #{value}" }
        acc.join(' ')
      end

      # Canonical title, with nonfiling characters removed, if present and specified
      # TODO: it seems we are currently using a multivalued field for sorting...check the schema...
      def sort(record); end

      # we dont facet by title...but there is xfacet stuff currently that supports title browse
      # def facet(record:); end

      def standardized(record); end

      def other(record); end

      def former(record); end

      # get title values from fields (e.g., 240 and/or 880)
      # used in sort?
      # def title(record, include_alternates:); end
    end
  end
end
