# frozen_string_literal: true

describe 'PennMARC::Citation' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Citation }

  describe '.cited_in_show' do
    let(:record) { marc_record fields: [marc_field(tag: '510', subfields: {a: 'Patrick'}),
                                      marc_field(tag: '880', subfields: {'6': '510', a: 'パトリック'})] }

    it 'returns expected citation values' do
      expect(helper.cited_in_show(record)).to contain_exactly('Patrick', 'パトリック')
    end
  end
end

