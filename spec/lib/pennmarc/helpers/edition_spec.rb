# frozen_string_literal: true

describe 'PennMARC::Edition' do
  let(:helper) { PennMARC::Edition }
  let(:mapping) { { aut: 'Author' } }
  let(:record) do
    marc_record fields: [marc_field(tag: '250', subfields: { a: '5th Edition', b: 'Remastered' }),
                         marc_field(tag: '880', subfields: { '6': '250', b: 'رمستر' }),
                         marc_field(tag: '775', subfields: { i: 'Other Edition (Remove)',
                                                             h: 'Cool Book',
                                                             t: 'aut' }),
                         marc_field(tag: '880', subfields: { '6': '775', i: 'Autre Editione' })]
  end

  describe '.show' do
    it 'returns the editions' do
      expect(helper.show(record)).to contain_exactly('5th Edition Remastered', 'رمستر')
    end

    it 'returns the editions without alternate' do
      expect(helper.show(record, with_alternate: false)).to contain_exactly('5th Edition Remastered')
    end
  end

  describe '.values' do
    it 'returns the values' do
      expect(helper.values(record)).to eq('5th Edition Remastered')
    end
  end

  describe '.other_show' do
    it 'returns other edition values' do
      expect(helper.other_show(record, relator_map: mapping)).to(
        contain_exactly('Autre Editione', 'Other Edition: Author. (Cool Book)')
      )
    end
  end
end
