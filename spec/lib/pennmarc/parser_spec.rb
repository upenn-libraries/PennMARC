# frozen_string_literal: true

describe PennMARC::Parser do
  include MarcSpecHelpers

  subject(:parser) { described_class.new }

  let(:record) { record_from 'test.xml' }

  it 'delegates to helper modules properly' do
    expect(parser.language_search(record)).to eq 'English'
  end

  it 'delegates to helper modules properly with extra params' do
    bogus_map = { eng: 'American' }
    expect(parser.language_search(record, language_map: bogus_map)).to eq 'American'
  end

  it 'raises an exception if the method call is invalid' do
    expect { parser.title(record) }.to raise_error NoMethodError
    expect { parser.title_nope(record) }.to raise_error NoMethodError
  end

  describe '#respond_to?' do
    it 'returns true if a helper has the expected method' do
      expect(parser).to respond_to :language_search
    end

    it 'returns false if a helper does not have the expected method' do
      expect(parser).not_to respond_to :language_nope
      expect(parser).not_to respond_to :nope
    end
  end
end
