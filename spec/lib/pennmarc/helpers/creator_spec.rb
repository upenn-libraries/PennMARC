# frozen_string_literal: true

describe 'PennMARC::Creator' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Creator }
  let(:mapping) { { aut: 'Author' } }

  describe '.search' do
    let(:single_author_record) do
      marc_record fields: [
        marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345',
                                            e: 'author', '4': 'http://cool.uri/vocabulary/relators/aut' }),
        marc_field(tag: '880', subfields: { a: 'Surname, Alternative', '6': '100' })
      ]
    end

    let(:org_author_record) do
      marc_record fields: [
        marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
        marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })
      ]
    end

    it 'contains the expected search field values for a single author work' do
      expect(helper.search(single_author_record, mapping)).to eq [
        'Name Surname http://cool.uri/12345 author.',
        'Surname, Name http://cool.uri/12345 author.',
        'Alternative Surname'
      ]
    end

    it 'contains the expected search field values for a group author work' do
      expect(helper.search(org_author_record, mapping)).to eq [
        'Group of People Annual Meeting.',
        'Alt. Group Name Alt. Annual Meeting'
      ]
    end
  end

  xdescribe '.search_aux'

  describe '.show' do

  end

  describe '.sort' do

  end

  describe '.facet' do

  end

  describe '.conference_show' do

  end

  describe '.conference_detail_show' do

  end

  xdescribe '.conference_search'
end
