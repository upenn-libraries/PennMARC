# frozen_string_literal: true

describe PennMARC::Parser do
  include MarcSpecHelpers

  subject(:parser) { described_class.new }

  let(:record) { record_from 'test.xml' }

  it 'delegates to helper modules properly' do
    expect(parser.language_values(record)).to contain_exactly 'English'
  end

  it 'delegates to helper modules properly with extra params' do
    bogus_map = { eng: 'American' }
    expect(parser.language_values(record, iso_639_2_mapping: bogus_map,
                                          iso_639_3_mapping: bogus_map)).to contain_exactly 'American'
  end

  it 'raises an exception if the method call is invalid' do
    expect { parser.title(record) }.to raise_error NoMethodError
    expect { parser.title_nope(record) }.to raise_error NoMethodError
  end

  describe '#respond_to?' do
    it 'returns true if a helper has the expected method' do
      expect(parser).to respond_to :language_values
    end

    it 'returns false if a helper does not have the expected method' do
      expect(parser).not_to respond_to :language_nope
      expect(parser).not_to respond_to :nope
    end
  end
end
