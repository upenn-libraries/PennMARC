# frozen_string_literal: true

describe 'PennMARC::Series' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Series }
  let(:mapping) { { aut: 'Author' } }
  let(:record) do
    marc_record fields: [marc_field(tag: '490', subfields: { 'a': 'Teachings of the feathered serpent' }),
                         marc_field(tag: '880', subfields: { '6': '490', a: 'Le Teachings' }),
                         marc_field(tag: '800', subfields: { a: 'Patrick Perkins', d: '1997-', t: 'Teachings', v: 'bk. 1' })]
  end

  describe '.show' do
    it 'returns the series' do
      expect(helper.show(record, mapping)).to contain_exactly({ link_type: 'author_search',
                                                                value: 'Patrick Perkins 1997-',
                                                                value_append: 'Teachings bk. 1' },
                                                              { link: false, value: 'Teachings of the feathered serpent' },
                                                              { link: false, value: 'Le Teachings' })
    end
  end

  describe '.values' do
    it 'returns the values' do
      expect(helper.values(record, mapping)).to contain_exactly('Patrick Perkins 1997- Teachings bk. 1.')
    end
  end

  describe '.search' do
    it 'returns the search values' do
      expect(helper.search(record)).to eq('test')
    end
  end

  describe '.get_continues_display' do

  end

  describe '.get_continued_by_display' do

  end
end

