# frozen_string_literal: true

require 'net/http'
require 'json'

# Dumb API client for grabbing bibs
class SimpleAlmaApiClient
  def self.bib(id:)
    opts = ['expand=p_avail,e_avail,d_avail', 'format=json', "apikey=#{ENV['ALMA_API_KEY']}"]
    uri = URI("https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs/#{id}?#{opts.join('&')}")
    resp = Net::HTTP.get uri
    parsed_resp = JSON.parse resp
    parsed_resp['anies'].first
  end
end

namespace :pennmarc do
  desc 'Get MARCXML for an Alma MMS ID'
  task :alma_marcxml, [:mmsid] do |_t, args|
    require 'rexml/document'
    marcxml = SimpleAlmaApiClient.bib id: args[:mmsid]
    output = +''
    REXML::Document.new(marcxml).write(output, 2)
    puts output.encode('utf-8') # rubymine console struggles with utf-16
  end

  desc 'Get all output from Helpers'
  task :output_for, [:mms_id] do |_t, args|
    require 'marc'
    require_relative 'lib/pennmarc/parser'
    record = MARC::XMLReader.new(StringIO.new(SimpleAlmaApiClient.bib(id: args[:mms_id]))).first
    output_hash = {}
    PennMARC::Parser::DEFINED_HELPERS.each do |helper|
      output_hash[helper] = {}
      helper_class = "PennMARC::#{helper}".constantize
      interesting_methods = helper_class.public_methods - PennMARC::Util.instance_methods - Object.methods
      interesting_methods.each do |method|
        output_hash[helper][method] = helper_class.public_send method.to_sym, record
      rescue StandardError => e
        output_hash[helper][method] = "Can't determine output: #{e.message}"
      end
    end
    puts jj output_hash
  end
end
