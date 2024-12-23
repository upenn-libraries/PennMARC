# frozen_string_literal: true

describe 'PennMARC::Title' do
  let(:helper) { PennMARC::Title }
  let(:leader) { nil }
  let(:fields) { [marc_field(tag: '245', subfields: subfields)] }
  let(:record) { marc_record fields: fields, leader: leader }

  describe '.search' do
    let(:fields) do
      [marc_field(tag: '245', subfields: { a: 'Title', b: 'Subtitle', c: 'Responsibility', h: 'Medium' }),
       marc_field(tag: '880', subfields: { a: 'Linked Title', '6': '245' })]
    end

    it 'returns search values without ǂc or ǂh content' do
      values = helper.search(record)
      expect(values).to contain_exactly 'Linked Title', 'Title Subtitle'
      expect(values).not_to include 'Responsibility', 'Medium'
    end
  end

  describe '.search_aux' do
    let(:leader) { 'ZZZZZnaaZa22ZZZZZzZZ4500' }
    let(:fields) do
      [marc_field(tag: '130', subfields: { a: 'Uniform Title', c: '130 not included' }),
       marc_field(tag: '880', subfields: { '6': '130', a: 'Alternative Uniform Title' }),
       marc_field(tag: '773', subfields: { a: 'Host Uniform Title', s: '773 not included' }),
       marc_field(tag: '700', subfields: { t: 'Personal Entry Title', s: '700 not included' }),
       marc_field(tag: '505', subfields: { t: 'Invalid Formatted Contents Note Title' }, indicator1: 'invalid'),
       marc_field(tag: '505', subfields: { t: 'Formatted Contents Note Title', s: '505 not included' },
                  indicator1: '0', indicator2: '0')]
    end

    it 'returns auxiliary titles' do
      expect(helper.search_aux(record)).to contain_exactly('Uniform Title', 'Host Uniform Title',
                                                           'Alternative Uniform Title', 'Personal Entry Title',
                                                           'Formatted Contents Note Title')
    end

    context 'when the leader indicates the record is a serial' do
      let(:leader) { 'ZZZZZnasZa22ZZZZZzZZ4500' }

      it 'returns auxiliary titles' do
        expect(helper.search_aux(record)).to contain_exactly('Uniform Title', 'Host Uniform Title',
                                                             'Alternative Uniform Title', 'Personal Entry Title',
                                                             'Formatted Contents Note Title')
      end
    end
  end

  describe '.journal_search' do
    let(:leader) { 'ZZZZZnasZa22ZZZZZzZZ4500' }
    let(:fields) do
      [marc_field(tag: '245', subfields: { a: 'Some Journal Title' }),
       marc_field(tag: '880', subfields: { a: 'Alternative Script', '6': '245' }),
       marc_field(tag: '880', subfields: { a: 'Unrelated 880', '6': 'invalid' })]
    end

    it 'returns journal search titles' do
      expect(helper.journal_search(record)).to contain_exactly('Some Journal Title', 'Alternative Script')
    end

    context 'when the record is not a serial' do
      let(:leader) { 'ZZZZZnaaZa22ZZZZZzZZ4500' }

      it 'returns an empty array' do
        expect(helper.journal_search_aux(record)).to be_empty
      end
    end
  end

  describe '.journal_search_aux' do
    let(:leader) { 'ZZZZZnasZa22ZZZZZzZZ4500' }
    let(:fields) do
      [marc_field(tag: '130', subfields: { a: 'Uniform Title', c: '130 not included' }),
       marc_field(tag: '880', subfields: { '6': '130', a: 'Alternative Uniform Title' }),
       marc_field(tag: '773', subfields: { a: 'Host Uniform Title', s: '773 not included' }),
       marc_field(tag: '700', subfields: { t: 'Personal Entry Title', s: '700 not included' }),
       marc_field(tag: '505', subfields: { t: 'Invalid Formatted Contents Note Title' }, indicator1: 'invalid'),
       marc_field(tag: '505', subfields: { t: 'Formatted Contents Note Title', s: '505 not included' },
                  indicator1: '0', indicator2: '0')]
    end

    it 'returns auxiliary journal search titles' do
      expect(helper.journal_search_aux(record)).to contain_exactly('Uniform Title', 'Alternative Uniform Title',
                                                                   'Host Uniform Title', 'Personal Entry Title',
                                                                   'Formatted Contents Note Title')
    end

    context 'when the record is not a serial' do
      let(:leader) { 'ZZZZZnaaZa22ZZZZZzZZ4500' }

      it 'returns an empty array' do
        expect(helper.journal_search_aux(record)).to be_empty
      end
    end
  end

  describe '.show' do
    context 'with no 245' do
      let(:fields) do
        # Simulate a miscoded record
        [marc_field(tag: '246', indicator1: '1', indicator2: '4', subfields: { a: 'The horn concertos', c: 'Mozart' })]
      end

      it 'returns default title' do
        expect(helper.show(record)).to eq [PennMARC::Title::NO_TITLE_PROVIDED]
      end
    end

    context 'with ǂa, ǂk and ǂn defined' do
      let(:fields) { [marc_field(tag: '245', subfields: subfields)] }
      let(:subfields) { { a: 'Five Decades of MARC usage', k: 'journals', n: 'Part One' } }

      it 'returns single title value with text from ǂa and ǂn but not ǂk' do
        expect(helper.show(record)).to eq 'Five Decades of MARC usage Part One'
      end
    end

    context 'with no ǂa but a ǂk and ǂn defined' do
      let(:fields) { [marc_field(tag: '245', subfields: subfields)] }
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

  describe '.detailed_show' do
    context 'with subfields ǂk, ǂf and ǂc' do
      let(:fields) do
        [marc_field(tag: '245', subfields: { k: 'Letters,', f: '1972-1982,', b: 'to Lewis Mumford.' })]
      end

      it 'returns detailed title values' do
        expect(helper.detailed_show(record)).to eq 'Letters, 1972-1982, to Lewis Mumford.'
      end
    end

    context 'with subfields ǂk and ǂb' do
      let(:fields) do
        [marc_field(tag: '245', subfields: { k: 'Letters', b: 'to Lewis Mumford.' })]
      end

      it 'returns title value without dates' do
        expect(helper.detailed_show(record)).to eq 'Letters to Lewis Mumford.'
      end
    end

    # e.g., 9977704838303681
    context 'with ǂa containing an " : " as well as inclusive dates' do
      let(:fields) do
        [marc_field(tag: '245', subfields: { a: 'The frugal housewife : ',
                                             b: 'dedicated to those who are not ashamed of economy, ',
                                             f: '1830 / ', c: 'by the author of Hobomok.' })]
      end

      it 'returns single title value with text from ǂa and ǂn' do
        expect(helper.detailed_show(record)).to eq(
          'The frugal housewife : dedicated to those who are not ashamed of economy, 1830 / by the author of Hobomok.'
        )
      end
    end
  end

  describe '.alternate_show' do
    let(:fields) do
      [marc_field(tag: '245', subfields: { k: 'Letters', b: 'to Lewis Mumford. ' }),
       marc_field(tag: '880', subfields: { '6': '245', k: 'Lettres', b: 'à Lewis Mumford.' })]
    end

    context 'with subfields ǂk and ǂb' do
      it 'returns alternate title values' do
        expect(helper.alternate_show(record)).to eq 'Lettres à Lewis Mumford.'
      end
    end

    context 'when 880 field is not present' do
      let(:fields) do
        [marc_field(tag: '245', subfields: { k: 'Letters', b: 'to Lewis Mumford. ' })]
      end

      it 'returns nil' do
        expect(helper.alternate_show(record)).to be_nil
      end
    end
  end

  describe '.sort' do
    context 'with no 245' do
      let(:fields) do
        # Simulate a miscoded record
        [marc_field(tag: '246', indicator1: '1', indicator2: '4', subfields: { a: 'The horn concertos', c: 'Mozart' })]
      end

      it 'returns nil' do
        expect(helper.sort(record)).to be_nil
      end
    end

    context 'with a record with a valid indicator2 value' do
      let(:fields) do
        [marc_field(tag: '245', indicator2: '4', subfields: {
                      a: 'The Record Title',
                      b: 'Remainder', n: 'Number', p: 'Section',
                      h: 'Do not display'
                    })]
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
      let(:fields) do
        [marc_field(tag: '245', subfields: { a: 'The Record Title' })]
      end

      it 'does not transform the title value' do
        expect(helper.sort(record)).to eq 'The Record Title'
      end
    end

    context 'with a record with no ǂa and no indicator2 value' do
      let(:fields) { [marc_field(tag: '245', subfields: { k: 'diaries' })] }

      it 'uses ǂk (form) value without transformation' do
        expect(helper.sort(record)).to eq 'diaries'
      end
    end

    context 'with a record with a leading bracket' do
      let(:fields) { [marc_field(tag: '245', subfields: { a: '[The Record Title]' })] }

      # TODO: is this the expected behavior? It would sort right, but looks silly.
      it 'removes the leading bracket and appends it to the full value' do
        expect(helper.sort(record)).to eq 'The Record Title] ['
      end
    end
  end

  describe '.standardized_show' do
    let(:fields) do
      [marc_field(tag: '130', subfields: { a: 'Uniform Title', f: '2000', '8': 'Not Included' }),
       marc_field(tag: '240', subfields: { a: 'Another Uniform Title', '0': 'Ugly Control Number' }),
       marc_field(tag: '730', indicator2: '', subfields: { a: 'Yet Another Uniform Title' }),
       marc_field(tag: '730', indicator1: '0', indicator2: '2', subfields: { a: 'Not Printed Title' }),
       marc_field(tag: '730', indicator1: '', subfields: { i: 'Subfield i Title' }),
       marc_field(tag: '880', subfields: { '6': '240', a: 'Translated Uniform Title' }),
       marc_field(tag: '880', subfields: { '6': '730', a: 'Alt Ignore', i: 'Alt Subfield i' }),
       marc_field(tag: '880', subfields: { '6': '100', a: 'Alt Ignore' })]
    end

    it 'returns the expected standardized title display values' do
      values = helper.standardized_show(record)
      expect(values).to contain_exactly(
        'Another Uniform Title', 'Translated Uniform Title', 'Uniform Title 2000', 'Yet Another Uniform Title'
      )
      expect(values).not_to include 'Not Printed Title', 'Subfield i Title', 'Alt Ignore'
    end
  end

  describe '.other_show' do
    let(:fields) do
      [marc_field(tag: '246', subfields: { a: 'Varied Title', f: '2000', '8': 'Not Included' }),
       marc_field(tag: '740', indicator2: '0', subfields: { a: 'Uncontrolled Title', '5': 'Penn' }),
       marc_field(tag: '740', indicator2: '2', subfields: { a: 'A Title We Do Not Like' }),
       marc_field(tag: '880', subfields: { '6': '246', a: 'Alternate Varied Title' })]
    end

    it 'returns the expected other title display values' do
      expect(helper.other_show(record)).to contain_exactly(
        'Alternate Varied Title', 'Uncontrolled Title', 'Varied Title 2000'
      )
    end
  end

  describe '.former_show' do
    let(:fields) do
      [marc_field(tag: '247', subfields: { a: 'Former Title', n: 'Part', '6': 'Linkage', e: 'Append' }),
       marc_field(tag: '880', subfields: { a: 'Alt Title', n: 'Part', '6': '247' })]
    end

    it 'returns the expected former title value' do
      values = helper.former_show(record)
      expect(values).to contain_exactly 'Former Title Part Append', 'Alt Title Part'
      expect(values).not_to include 'Linkage', '247'
    end
  end

  describe '.host_bib_record?' do
    let(:fields) { [marc_field(tag: '245', subfields: subfields)] }

    context 'with a host record' do
      let(:subfields) { { a: "#{PennMARC::Title::HOST_BIB_TITLE} for 123456789" } }

      it 'returns true' do
        expect(helper.host_bib_record?(record)).to be true
      end
    end

    context 'with a non-host record' do
      let(:subfields) { { a: 'Regular record' } }

      it 'returns false' do
        expect(helper.host_bib_record?(record)).to be false
      end
    end
  end
end
