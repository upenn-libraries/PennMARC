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
    it 'shows series' do
      expect(helper.show(record, mapping)).to eq([{ link_type: 'author_search',
                                                    value: 'Patrick Perkins 1997-',
                                                    value_append: 'Teachings bk. 1' },
                                                  { link: false, value: 'Teachings of the feathered serpent' },
                                                  { link: false, value: 'Le Teachings' }])
    end
  end

  describe '.values' do

  end

  describe '.search' do

  end

  describe '.get_continues_display' do

  end

  describe '.get_continued_by_display' do

  end
end

