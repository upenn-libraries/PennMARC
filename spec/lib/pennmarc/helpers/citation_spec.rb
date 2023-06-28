# frozen_string_literal: true

describe 'PennMARC::Citation' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Citation }

  describe '.cited_in_show' do
    let(:record) do
      marc_record fields: [marc_field(tag: '510', subfields: { a: 'Perkins Archive' }),
                           marc_field(tag: '880', subfields: { '6': '510', a: 'パーキンスのアーカイブ' })]
    end

    it 'returns expected citation values' do
      expect(helper.cited_in_show(record)).to contain_exactly('Perkins Archive', 'パーキンスのアーカイブ')
    end
  end

  describe '.cite_as_show' do
    let(:record) { marc_record fields: [marc_field(tag: '524', subfields: {a: 'Perkins Historical Archive, Box 2'})] }

    it 'returns expected citation values' do
      expect(helper.cite_as_show(record)).to contain_exactly('Perkins Historical Archive, Box 2')
    end
  end
end

