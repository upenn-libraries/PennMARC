# frozen_string_literal: true

describe 'PennMARC::Series' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Series }
  let(:mapping) { { aut: 'Author' } }
  let(:record) do
    marc_record fields: [marc_field(tag: '490', subfields: { 'a': 'Teachings of the feathered pillow' }),
                         marc_field(tag: '880', subfields: { '6': '490', a: 'Учения пернатой подушки' }),
                         marc_field(tag: '800', subfields: { a: 'Bean Bagatolvski', d: '1997-', v: 'bk. 1' }),
                         marc_field(tag: '780', subfields: { a: 'National Comfort Association' }),
                         marc_field(tag: '785', subfields: { a: 'NCA quarterly comfortology bulletin' })]
  end

  describe '.show' do
    it 'returns the series' do
      expect(helper.show(record, mapping)).to contain_exactly({ link_type: 'author_search',
                                                                value: 'Bean Bagatolvski 1997-',
                                                                value_append: 'bk. 1' },
                                                              { link: false, value: 'Teachings of the feathered pillow' },
                                                              { link: false, value: 'Учения пернатой подушки' })
    end
  end

  describe '.values' do
    it 'returns the values' do
      expect(helper.values(record, mapping)).to contain_exactly('Bean Bagatolvski 1997- bk. 1.')
    end
  end

  describe '.search' do
    it 'returns the search values' do
      expect(helper.search(record)).to contain_exactly('Bean Bagatolvski 1997- bk. 1')
    end
  end

  describe '.get_continues_display' do
    it 'gets continues for display' do
      expect(helper.get_continues_display(record)).to contain_exactly('National Comfort Association')
    end
  end

  describe '.get_continued_by_display' do
    it 'gets continued by display' do
      expect(helper.get_continued_by_display(record)).to contain_exactly('NCA quarterly comfortology bulletin')
    end
  end
end

