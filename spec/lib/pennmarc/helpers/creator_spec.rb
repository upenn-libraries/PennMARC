# frozen_string_literal: true

describe 'PennMARC::Creator' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Creator }
  let(:mapping) do
    { rbr: 'Rubricator', prg: 'Programmer', frg: 'Forger' }
  end

  describe '.search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '100', subfields: { a: 'Surname, Name', d: '1941', '0': 'http://cool.uri', '4': 'rbr' }),
        marc_field(tag: '110', subfields: { a: 'Evil Corp.', b: 'R&D' }),
        marc_field(tag: '880', subfields: { a: 'Surname, Alternative', d: '1941', '6': '100' }),
        marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Evil Corp. Name', b: 'Alt. R&D' })
      ]
    end

    let(:output) { helper.search(record, mapping) }

    it 'test' do
      expect(output).to eq []
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
