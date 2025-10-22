# frozen_string_literal: true

module PennMARC
  # A service to calculate suggestion weights based on a variety of criteria
  class TitleSuggestionWeightService
    # Starting score
    BASE_WEIGHT = 10

    # Array of symbols referring to methods on this object that return a boolean and the scoring factor if the
    # method returns true.
    FACTORS = [
      [:targeted_format?,             8],
      [:published_in_last_ten_years?, 5],
      [:electronic_holdings?,         3],
      [:high_encoding_level?,         2],
      [:physical_holdings?,           1],
      [:low_encoding_level?,         -2],
      [:weird_format?,               -5],
      [:no_holdings?,                -10]
    ].freeze

    # Score higher records with these formats
    TARGETED_FORMATS = [Format::BOOK, Format::WEBSITE_DATABASE, Format::JOURNAL_PERIODICAL, Format::NEWSPAPER,
                        Format::SOUND_RECORDING, Format::MUSICAL_SCORE].freeze
    # Score lower these formats
    WEIRD_FORMATS = [Format::OTHER, Format::THREE_D_OBJECT].freeze

    class << self
      # Calculate a weight for use in sorting good title suggestions from bad
      # @param [MARC::Record] record
      # @return [Integer]
      def weight(record)
        factors.reduce(BASE_WEIGHT) do |weight, (call, score)|
          if respond_to?(call, true)
            weight + (public_send(call, record) ? score : 0)
          else
            warn "Unknown weighting method: #{call}"
            next
          end
        end
      end

      # @return [Array[Array]]
      def factors
        FACTORS
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def published_in_last_ten_years?(record)
        return false unless Date.publication(record).present?

        Date.publication(record) > 10.years.ago
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def electronic_holdings?(record)
        Inventory.electronic(record).any?
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def physical_holdings?(record)
        Inventory.physical(record).any?
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def targeted_format?(record)
        (Format.facet(record) & TARGETED_FORMATS).any?
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def high_encoding_level?(record)
        Encoding.level_sort(record) == 0
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def weird_format?(record)
        (Format.facet(record) & WEIRD_FORMATS).any?
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def no_holdings?(record)
        !electronic_holdings?(record) && Inventory.physical(record).none?
      end

      # @param [MARC::Record] record
      # @return [Boolean]
      def low_encoding_level?(record)
        return false unless Encoding.level_sort(record).present?

        Encoding.level_sort(record) > 4
      end
    end
  end
end
