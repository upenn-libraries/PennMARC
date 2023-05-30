# frozen_string_literal: true

require_relative '../../support/marc_spec_helpers'
require_relative '../../../lib/pennmarc'

describe PennMARC::Record do
  include MarcSpecHelpers

  let(:record) do
    record_from 'test.xml'
  end

  subject(:thing) { described_class.new(mappings: []) }

  describe '.test' do
    it 'works' do
      expect(thing.test(record)).to eq '9910148543503681'
    end
  end

  describe '.title_display' do
    it 'returns a single-valued title' do
      expect(thing.title_display(record)).to eq 'The Coopers & Lybrand guide to business tax strategies and planning'
    end
  end
end