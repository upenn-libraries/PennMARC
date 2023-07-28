# frozen_string_literal: true

describe 'PennMARC::Title' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Title }

  describe '.search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '245', subfields: { a: 'Title', b: 'Subtitle', c: 'Responsibility', h: 'Medium' }),
        marc_field(tag: '880', subfields: { a: 'Linked Title', '6': '245' })
      ]
    end

    it 'returns search values without ǂc or ǂh content' do
      values = helper.search(record)
      expect(values).to contain_exactly 'Linked Title', 'Title Subtitle'
      expect(values).not_to include 'Responsibility', 'Medium'
    end
  end

  describe '.search_aux' do
    it 'returns search aux values', pending: 'Not implemented yet'
  end

  describe '.show' do
    let(:record) { marc_record fields: [marc_field(tag: '245', subfields: subfields)] }

    context 'with ǂa, ǂk and ǂn defined' do
      let(:subfields) { { a: 'Five Decades of MARC usage', k: 'journals', n: 'Part One' } }

      it 'returns single title value with text from ǂa and ǂn but not ǂk' do
        expect(helper.show(record)).to eq 'Five Decades of MARC usage Part One'
      end
    end

    context 'with no ǂa but a ǂk and ǂn defined' do
      let(:subfields) { { k: 'journals', n: 'Part One' } }

      it 'returns single title value with text from ǂk and ǂn' do
        expect(helper.show(record)).to eq 'journals Part One'
      end
    end

    context 'with ǂa containing an " = "' do
      let(:subfields) { { a: 'There is a parallel statement = ', b: 'Parallel statement / ' } }

      it 'returns single title value with text from ǂa and ǂb joined with an " = " and other trailing punctuation
          removed' do
        expect(helper.show(record)).to eq 'There is a parallel statement = Parallel statement'
      end
    end

    context 'with ǂa containing an " : "' do
      let(:subfields) { { a: 'There is an other statement : ', b: 'Other statement' } }

      it 'returns single title value with text from ǂa and ǂn' do
        expect(helper.show(record)).to eq 'There is an other statement : Other statement'
      end
    end
  end

  describe '.sort' do
    context 'with a record with a valid indicator2 value' do
      let(:record) do
        marc_record fields: [
          marc_field(tag: '245', indicator2: '4', subfields: {
                       a: 'The Record Title',
                       b: 'Remainder', n: 'Number', p: 'Section',
                       h: 'Do not display'
                     })
        ]
      end

      it 'properly removes and appends the number of characters specified in indicator 2' do
        value = helper.sort(record)
        expect(value).to start_with 'Record Title'
        expect(value).to end_with 'The'
      end

      it 'includes ǂb, ǂn and ǂp values' do
        expect(helper.sort(record)).to eq 'Record Title Remainder Number Section The'
      end
    end

    context 'with a record with no indicator2 value' do
      let(:record) do
        marc_record fields: [marc_field(tag: '245', subfields: { a: 'The Record Title' })]
      end

      it 'does not transform the title value' do
        expect(helper.sort(record)).to eq 'The Record Title'
      end
    end

    context 'with a record with no ǂa and no indicator2 value' do
      let(:record) do
        marc_record fields: [marc_field(tag: '245', subfields: { k: 'diaries' })]
      end

      it 'uses ǂk (form) value without transformation' do
        expect(helper.sort(record)).to eq 'diaries'
      end
    end

    context 'with a record with a leading bracket' do
      let(:record) do
        marc_record fields: [marc_field(tag: '245', subfields: { a: '[The Record Title]' })]
      end

      # TODO: is this the expected behavior? It would sort right, but looks silly.
      it 'removes the leading bracket and appends it to the full value' do
        expect(helper.sort(record)).to eq 'The Record Title] ['
      end
    end
  end

  describe '.standardized' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '130', subfields: { a: 'Uniform Title', f: '2000', '8': 'Not Included' }),
        marc_field(tag: '240', subfields: { a: 'Another Uniform Title', '0': 'Ugly Control Number' }),
        marc_field(tag: '730', indicator2: '', subfields: { a: 'Yet Another Uniform Title' }),
        marc_field(tag: '730', indicator1: '0', indicator2: '2', subfields: { a: 'Not Printed Title' }),
        marc_field(tag: '730', indicator1: '', subfields: { i: 'Subfield i Title' }),
        marc_field(tag: '880', subfields: { '6': '240', a: 'Translated Uniform Title' })
      ]
    end

    it 'returns the expected standardized title display values' do
      values = helper.standardized(record)
      expect(values).to contain_exactly(
        'Another Uniform Title', 'Translated Uniform Title', 'Uniform Title 2000', 'Yet Another Uniform Title'
      )
      expect(values).not_to include 'Not Printed Title', 'Subfield i Title'
    end
  end

  describe '.other' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '246', subfields: { a: 'Varied Title', f: '2000', '8': 'Not Included' }),
        marc_field(tag: '740', indicator2: '0', subfields: { a: 'Uncontrolled Title', '5': 'Penn' }),
        marc_field(tag: '740', indicator2: '2', subfields: { a: 'A Title We Do Not Like' }),
        marc_field(tag: '880', subfields: { '6': '246', a: 'Alternate Varied Title' })
      ]
    end

    it 'returns the expected other title display values' do
      expect(helper.other(record)).to contain_exactly(
        'Alternate Varied Title', 'Uncontrolled Title', 'Varied Title 2000'
      )
    end
  end

  describe '.former' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '247', subfields: { a: 'Former Title', n: 'Part', '6': 'Linkage', e: 'Append' }),
        marc_field(tag: '880', subfields: { a: 'Alt Title', n: 'Part', '6': '247' })
      ]
    end

    it 'returns the expected former title value' do
      values = helper.former(record)
      expect(values).to contain_exactly 'Former Title Part Append', 'Alt Title Part'
      expect(values).not_to include 'Linkage', '247'
    end
  end
end
