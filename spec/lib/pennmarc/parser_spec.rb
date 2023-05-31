# frozen_string_literal: true

describe PennMARC::Parser do
  include MarcSpecHelpers

  let(:record) do
    record_from 'test.xml'
  end

  subject(:thing) { described_class.new(mappings: []) }

  describe '.mmsid' do
    it 'returns an Alma MMS ID' do
      expect(thing.mmsid(record)).to eq '9910148543503681'
    end
  end

  describe '.title_display' do
    it 'returns a single-valued title' do
      expect(thing.title_display(record)).to eq 'The Coopers & Lybrand guide to business tax strategies and planning'
    end
  end

  describe '.title_search' do
    it 'returns many title values' do
      expect(thing.title_search(record)).to match_array []
    end
  end

  describe '.title_sort' do
    it 'returns the primary title for use in sorts' do
      expect(thing.title_sort(record)).to eq ''
    end
  end
end
