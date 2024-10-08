# frozen_string_literal: true

describe 'PennMARC::Series' do
  let(:helper) { PennMARC::Series }
  let(:mapping) { { aut: 'Author' } }
  let(:record) do
    marc_record fields: [marc_field(tag: '410', subfields: { a: 'Evil Giant Megacorp' }),
                         marc_field(tag: '490', subfields: { a: 'Teachings of the feathered pillow' }),
                         marc_field(tag: '880', subfields: { '6': '490', a: 'Учения пернатой подушки' }),
                         marc_field(tag: '800', subfields: { a: 'Bean Bagatolvski', d: '1997-', v: 'bk. 1' }),
                         marc_field(tag: '780', subfields: { a: 'National Comfort Association' }),
                         marc_field(tag: '785', subfields: { a: 'NCA quarterly comfortology bulletin' })]
  end
  let(:empty_record) do
    marc_record fields: [marc_field(tag: '666', subfields: { a: 'test' })]
  end

  describe '.show_query_map' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '440', subfields: { a: 'Teachings of the feathered pillow', n: 'number', p: 'section' }),
        marc_field(tag: '490', subfields: { a: 'Ignored' }),
        marc_field(tag: '830', subfields: { a: 'International litigation in practice', v: 'volume 13.' })
      ]
    end

    it 'returns expected hash' do
      expect(helper.show_query_map(record)).to eq(
        { 'Teachings of the feathered pillow number section' => 'Teachings of the feathered pillow number section',
          'Teachings of the feathered pillow section number' => 'Teachings of the feathered pillow number section',
          'International litigation in practice volume 13.' => 'International litigation in practice' }
      )
    end
  end

  describe '.show' do
    it 'returns the series values for display' do
      expect(helper.show(record, relator_map: mapping)).to contain_exactly(
        'Bean Bagatolvski 1997- bk. 1',
        'Teachings of the feathered pillow',
        'Учения пернатой подушки', 'Evil Giant Megacorp'
      )
    end
  end

  describe '.values' do
    it 'returns the series values' do
      expect(helper.values(record, relator_map: mapping)).to contain_exactly('Bean Bagatolvski 1997- bk. 1.')
    end
  end

  describe '.search' do
    it 'returns the search values' do
      expect(helper.search(record)).to contain_exactly('Bean Bagatolvski 1997- bk. 1', 'Evil Giant Megacorp')
    end

    it 'returns an empty array if no values are found' do
      expect(helper.search(empty_record)).to be_empty
    end
  end

  describe '.get_continues_show' do
    it 'gets continues values for display' do
      expect(helper.get_continues_show(record)).to contain_exactly('National Comfort Association')
    end
  end

  describe '.get_continued_by_show' do
    it 'gets continued by values for display' do
      expect(helper.get_continued_by_show(record)).to contain_exactly('NCA quarterly comfortology bulletin')
    end
  end
end
