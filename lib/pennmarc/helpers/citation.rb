# frozen_string_literal: true

module PennMARC
  # Do Citation-y stuff
  class Citation < Helper
    class << self
      # @param [MARC::Record] record
      # @return [Object]
      def cited_in_show(record)
        get_datafield_and_880(record, '510')
      end

      # @param [MARC::Record] record
      # @return [Object]
      def cite_as_show(record)
        get_datafield_and_880(record, '524')
      end
    end
  end
end
