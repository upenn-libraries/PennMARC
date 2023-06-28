# frozen_string_literal: true

module PennMARC
  # Do Citation-y stuff
  class Citation < Helper
    class << self
      # Field 510 contains Citations or references to published bibliographic descriptions,
      # reviews, abstracts, or indexes of the content of the described item. Used to specify where an item has been
      # cited or reviewed. Citations or references may be given in a brief form (i.e., using generally recognizable
      # abbreviations, etc.). The actual text of a published description is not recorded in field 510 but rather in
      # field 520 (Summary, Etc. Note).
      # https://www.loc.gov/marc/bibliographic/bd510.html
      # @param [MARC::Record] record
      # @return [Array] array of citations and any linked alternates
      def cited_in_show(record)
        datafield_and_linked_alternate(record, '510')
      end

      # Field 524 is the Preferred Citation of Described Materials Note. It is the Format for the citation of the
      # described materials that is preferred by the custodian. When multiple citation formats exist for the same item,
      # each is recorded in a separate occurrence of field 524. The note is sometimes displayed and/or printed with an
      # introductory phrase that is generated as a display constant based on the first indicator value.
      # https://www.loc.gov/marc/bibliographic/bd524.html
      # @param [MARC::Record] record
      # @return [Array] array of citation of described materials note and any linked alternates
      def cite_as_show(record)
        datafield_and_linked_alternate(record, '524')
      end
    end
  end
end
