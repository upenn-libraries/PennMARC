# frozen_string_literal: true

describe 'PennMARC::Format' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Format }

  describe '.format' do
    let(:formats) { helper.facet(record) }

    context 'for an "Archive"' do

    end

    context 'for a "Newspaper"' do

    end

    context 'for a "Book"' do
      let(:record) do
        marc_record(fields: fields, leader: '      aa  ')
      end
      let(:fields) do
        [marc_field(tag: '245', subfields: { k: 'blah' })]
      end

      it 'returns a facet value including only "Book"' do
        expect(formats).to eq ['Book']
      end
    end

    context 'for a "Projected Graphic"' do

    end

    context 'with a "Curated Format" set' do

    end
  end

  describe '.show' do
    let(:record) { marc_record fields: fields }

    context 'with entry in the 300 field' do
      let(:fields) do
        [marc_field(tag: '300', subfields: { a: '1 volume', b: 'illustration, maps', c: '12cm', '3': 'excluded' }),
         marc_field(tag: '880', subfields: { '6': '300', a: 'Alt. Extent' })]
      end

      it 'returns the expected format values' do
        value = helper.show(record)
        expect(value).to contain_exactly '1 volume illustration, maps 12cm', 'Alt. Extent'
        expect(value.join(' ')).not_to include 'excluded'
      end
    end

    context 'with entry in the 255 field' do
      let(:fields) do
        [marc_field(tag: '255', subfields: { a: 'Scale 1:24,000', b: 'Mercator projection',
                                             c: '(W 150°--W 30°/N 70°--N 40°)' }),
         marc_field(tag: '880', subfields: { '6': '255', a: 'Alt. Scale', b: 'Alt. Projection' })]
      end

      it 'returns the expected format values' do
        expect(helper.show(record)).to contain_exactly 'Alt. Scale Alt. Projection',
                                                       'Scale 1:24,000 Mercator projection (W 150°--W 30°/N 70°--N 40°)'
      end
    end
    context 'with entries in the 340' do
      let(:fields) do
        [marc_field(tag: '340', subfields: { a: 'cassette tape', b: '90 min', '0': 'excluded' }),
         marc_field(tag: '880', subfields: { '6': '340', a: 'alt. extent' })]
      end

      it 'returns the expected format values' do
        value = helper.show(record)
        expect(value).to contain_exactly 'cassette tape 90 min', 'alt. extent'
        expect(value.join(' ')).not_to include 'excluded'
      end
    end
  end

  describe '.other_show' do
    let(:record) do
      marc_record fields: [marc_field(tag: '776', subfields: {
                                        i: 'Online edition', a: 'Author, Name', t: 'Title', b: 'First Edition',
                                        d: 'Some Publisher', w: '(OCoLC)12345'
                                      }),
                           marc_field(tag: '880', subfields: {
                                        '6': '776', i: 'Alt. Online Edition', t: 'Alt. Title'
                                      })]
    end

    it 'returns other format information for display, with data from only ǂi, ǂa, ǂs, ǂt and ǂo' do
      expect(helper.other_show(record)).to contain_exactly 'Online edition Author, Name Title',
                                                           'Alt. Online Edition Alt. Title'
    end
  end
end
