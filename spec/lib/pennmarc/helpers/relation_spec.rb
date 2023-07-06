# frozen_string_literal: true

describe 'PennMARC::Relation' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Relation }
  let(:record) { marc_record fields: fields }
  let(:relator_map) { { aut: 'Author' } }

  describe '.contained_in_show' do
    let(:fields) do
      [marc_field(tag: '773', subfields: { i: 'Contained in (work):', t: 'National geographic magazine',
                                           w: '(OCoLC)12345' })]
    end

    it 'returns only the specified subfields' do
      expect(helper.contained_in_show(record)).to eq ['Contained in (work): National geographic magazine']
    end
  end

  describe '.chronology_show' do
    let(:fields) do
      [marc_field(tag: '650', indicator2: '4', subfields: { a: 'CHR Heading' }),
       marc_field(tag: '650', indicator2: '4', subfields: { a: 'Regular Local Heading' }),
       marc_field(tag: '650', indicator2: '1', subfields: { a: 'LoC Heading' }),
       marc_field(tag: '880', indicator2: '4', subfields: { '6': '650', a: 'CHR Alt. Heading' }),
       marc_field(tag: '880', indicator2: '4', subfields: { '6': '999', a: 'Another Alt.' })]
    end

    it 'returns only the specified subfield data and linked alternate field with CHR prefix removed' do
      expect(helper.chronology_show(record)).to eq ['Heading', 'Alt. Heading']
    end
  end

  describe '.related_collections_show' do
    let(:fields) do
      [marc_field(tag: '544', subfields: { d: 'Penn Papers', c: 'USA' }),
       marc_field(tag: '880', subfields: { '6': '544', d: 'Penn Papers Alt.' })]
    end

    it 'returns all expected subfield data for field and linked alternate' do
      expect(helper.related_collections_show(record)).to eq ['Penn Papers USA', 'Penn Papers Alt.']
    end
  end

  describe '.publications_about_show' do
    let(:fields) do
      [marc_field(tag: '581', subfields: { '3': 'Preliminary Report', a: '"Super Important Research Topic", 1977' }),
       marc_field(tag: '880', subfields: { '6': '581', '3': 'Alt. Preliminary Report' })]
    end

    it 'returns all expected subfield data for field and linked alternate' do
      expect(helper.publications_about_show(record)).to eq ['Preliminary Report "Super Important Research Topic", 1977',
                                                            'Alt. Preliminary Report']
    end
  end

  describe 'related_work_show' do
    let(:fields) do
      [marc_field(tag: '730', indicator2: '', subfields: { i: 'Adaptation of (work):', a: 'Wayne\'s World' }),
       marc_field(tag: '700', indicator2: '2', subfields: { i: 'Container of (work):', a: 'Wayne Campbell' }),
       marc_field(tag: '880', indicator2: '', subfields: { i: 'Alt. Prefix:', a: 'Alt. Wayne' })
      ]
    end

    it 'returns specified subfield values from specified field with blank indicator2' do
      values = helper.related_work_show record, relator_map
      expect(values).to contain_exactly 'Adaptation of: Wayne\s World', 'Alt. Prefix: Alt. Wayne'
    end
  end

  describe 'contains_show' do

  end

  describe '.has_supplement_show' do

  end
end
