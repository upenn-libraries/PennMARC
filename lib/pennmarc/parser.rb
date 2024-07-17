# frozen_string_literal: true

require 'active_support/all'
require_relative 'helpers/helper'

# Require all files in helpers directory
# TODO: this double-requires Helper, but that needs to be required before other helpers...
Dir[File.join(__dir__, 'helpers', '*.rb')].each { |file| require file }

# Top level gem namespace
module PennMARC
  # Access point for magic calls to helper methods
  class Parser
    # Allow calls to `respond_to?` on parser instances to respond accurately by checking helper classes
    # @param name [String, Symbol]
    # @return [Boolean]
    def respond_to_missing?(name, include_private = false)
      helper, method_name = parse_call(name)
      begin
        "PennMARC::#{helper}".constantize.respond_to?(method_name)
      rescue NameError
        super # Helper is not defined, so check self
      end
    end

    # Call helper class methods, passing along additional arguments as needed, e.g.:
    # #title_show -> PennMARC::Title.show
    # #subject_facet -> PennMARC::Subject.facet
    # @param name [Symbol]
    # @param record [MARC::Record]
    # @param opts [Array]
    def method_missing(name, record, *opts)
      helper, method_name = parse_call(name)
      raise NoMethodError unless helper && method_name

      helper_klass = "PennMARC::#{helper.titleize}".constantize
      if opts.any?
        helper_klass.public_send(method_name, record, **opts.first)
      else
        helper_klass.public_send(method_name, record)
      end
    end

    private

    # Parse out a method call name in the way method_missing is configured to handle
    # @param name [String, Symbol]
    # @return [Array]
    def parse_call(name)
      call = name.to_s.split('_')
      [call.shift&.titleize, call.join('_').to_sym]
    end
  end
end
