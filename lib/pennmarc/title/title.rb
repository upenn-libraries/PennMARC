# frozen_string_literal: true

require_relative '../marc_util'

module PennMARC
  # Do Title-y stuff
  class Title
    extend MarcUtil

    class << self
      def values(record)
        record.fields('245').take(1).map do |field|
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

      # TODO: an example here...
      def for_display(record)
        values(record).first
      end
    end
  end
end
