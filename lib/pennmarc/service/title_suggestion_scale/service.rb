# frozen_string_literal: true

module PennMARC
  module TitleSuggestionScale
    # A service to calculate suggestion weights based on a variety of criteria
    class Service
      class << self
        BASE_WEIGHT = 10

        FACTORS = [
          [:published_in_last_ten_years?, 2],
          [:electronic_holdings?, 3],
          [:physical_holdings?, 1],
          [:targeted_format?, 2],
          [:high_encoding_level?, 1],
          [:weird_format?, -1],
          [:no_holdings?, -3],
          [:low_encoding_level?, -2]
        ].freeze

        TARGETED_FORMATS = [Format::BOOK, Format::WEBSITE_DATABASE, Format::JOURNAL_PERIODICAL, Format::NEWSPAPER,
                            Format::SOUND_RECORDING, Format::MUSICAL_SCORE].freeze
        WEIRD_FORMATS = [Format::OTHER, Format::THREE_D_OBJECT].freeze

        def weight(record)
          weight = BASE_WEIGHT
          FACTORS.each do |call, score|
            weight + score if send(call, record)
          rescue NameError => _e
            next
          end
          weight
        end

        def published_in_last_ten_years?(record)
          return false unless Date.publication(record).present?

          Date.publication(record) < 10.years.ago
        end

        def electronic_holdings?(record)
          Inventory.electronic(record)&.any?
        end

        def physical_holdings?(record)
          Inventory.physical(record)&.any?
        end

        def targeted_format?(record)
          (Format.facet(record) | TARGETED_FORMATS).any?
        end

        def high_encoding_level?(record)
          case Encoding.level_sort(record)
          when 0
            true
          else
            false
          end
        end

        def weird_format?(record)
          (Format.facet(record) | WEIRD_FORMATS).any?
        end

        def no_holdings?(record)
          !electronic_holdings?(record) && Inventory.physical(record)&.none?
        end

        def low_encoding_level?(record)
          Encoding.level_sort(record) > 4
        end
      end
    end
  end
end
