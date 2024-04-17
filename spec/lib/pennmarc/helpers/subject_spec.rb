# frozen_string_literal: true

describe 'PennMARC::Subject' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Subject }
  let(:relator_map) do
    { dpc: 'Depicted' }
  end

  describe '.search' do
    let(:record) { marc_record fields: fields }
    let(:values) { helper.search(record, relator_map: relator_map) }

    context 'with a mix of included and excluded tags' do
      let(:fields) do
        [marc_field(tag: '600', indicator2: '5', subfields: { a: 'Excluded Canadian' }),
         marc_field(tag: '610', indicator2: '0', subfields: { a: 'University of Pennsylvania', b: 'Libraries' }),
         marc_field(tag: '691', indicator2: '7', subfields: { a: 'Van Pelt Library', '2': 'local' }),
         marc_field(tag: '696', indicator2: '4', subfields: { a: 'A Developer' }),
         marc_field(tag: '880', indicator2: '0', subfields: { a: 'Alt. Name', '6': '610' })]
      end

      it 'includes only values from valid tags' do
        expect(values).to contain_exactly 'A Developer', 'Alt. Name', 'University of Pennsylvania Libraries',
                                          'Van Pelt Library local'
        expect(values).not_to include 'Excluded Canadian'
      end
    end

    context 'with PRO/CHR values in sf a' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Subject' }),
         marc_field(tag: '650', indicator2: '4', subfields: { a: '%CHR Heading' })]
      end

      it 'removes the PRO/CHR designation' do
        expect(values).to contain_exactly 'Subject', 'Heading'
      end
    end

    context 'with a question mark at the end of sf a' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '4', subfields: { a: 'Potential Subject?' })]
      end

      it 'removes the question mark' do
        expect(values).to contain_exactly 'Potential Subject'
      end
    end

    context 'with a relator code specified' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '4', subfields: { a: 'Unicorns', '4': 'dpc' })]
      end

      it 'includes both the relator code and the mapped value, if found' do
        expect(values.first).to eq 'Unicorns dpc Depicted'
      end
    end
  end

  describe '.facet' do
    let(:record) { marc_record fields: fields }
    let(:values) { helper.facet(record) }

    # TODO: find some more inspiring examples in the corpus
    context 'with a record with poorly-coded heading values' do
      let(:fields) { [marc_field(tag: '650', indicator2: '0', subfields: { a: 'Subject -   Heading' })] }

      it 'properly normalizes the heading value' do
        expect(values.first).to eq 'Subject--Heading'
      end
    end

    context 'with a record with 650 headings with a ǂa that starts with PRO or CHR' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '4', subfields: { a: '%CHR 1998', '5': 'PU' }),
         marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Potok, Adena (donor) (Potok Collection copy)',
                                                              '5': 'PU' })]
      end

      it 'does not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'with a record with an indicator2 value of 3, 5 or 6' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '3', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '5', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '6', subfields: { a: 'Nope' })]
      end

      it 'does not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'with a record with a valid tag, indicator2 and source specified' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '7',
                    subfields: {
                      a: 'Libraries,', d: '22nd Century,', x: 'History.', e: 'relator',
                      '2': 'fast', '0': 'http://fast.org/libraries'
                    })]
      end

      it 'properly concatenates heading components' do
        expect(values.first).to start_with 'Libraries'
        expect(values.first).to end_with '--History'
      end

      it 'excludes URI values from ǂ0 or ǂ1' do
        expect(values.first).not_to include 'http'
      end

      it 'excludes raw relator term values from ǂe' do
        expect(values.first).not_to include 'relator'
      end

      it 'includes active dates from ǂd' do
        expect(values.first).to include '22nd Century'
      end

      it 'joins all values in the expected way' do
        expect(values.first).to eq 'Libraries, 22nd Century--History'
      end
    end

    context 'with a record with an invalid tag, but valid indicator2 and source specified' do
      let(:fields) do
        [marc_field(tag: '654', indicator2: '7', subfields: { c: 'b', a: 'Architectural theory', '2': 'aat' })]
      end

      it 'does not include the field' do
        expect(values).to be_empty
      end
    end

    context 'with a record with trailing periods' do
      let(:fields) do
        [marc_field(tag: '600', indicator2: '0',
                    subfields: {
                      a: 'R.G.', q: '(Robert Gordon).',
                      t: 'Spiritual order and Christian liberty proved to be consistent in the Churches of Christ. '
                    })]
      end

      it 'drops the final trailing period' do
        expect(values).to contain_exactly('R.G. (Robert Gordon). Spiritual order and Christian liberty proved ' \
                                          'to be consistent in the Churches of Christ')
      end
    end

    context 'with a record where a main subject part does not precede other subject parts' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '0', subfields: { b: 'Italian', a: 'Architectural theory' })]
      end

      it 'treats the first part it comes across as a main subject part' do
        expect(values).to contain_exactly('Italian--Architectural theory')
      end
    end
  end

  describe '.show' do
    let(:record) { marc_record fields: fields }
    let(:values) { helper.show(record) }

    context 'with a variety of headings' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '0', subfields: { a: 'Nephrology', v: 'Periodicals' }),
         marc_field(tag: '650', indicator2: '7',
                    subfields: { a: 'Nephrology', '2': 'fast', '0': '(OCoLC)fst01035991' }),
         marc_field(tag: '650', indicator2: '7', subfields: { a: 'Undesirable Heading', '2': 'exclude' }),
         marc_field(tag: '650', indicator2: '2', subfields: { a: 'Nephrology' }),
         marc_field(tag: '650', indicator2: '1', subfields: { a: 'Kidney Diseases' }),
         marc_field(tag: '690', subfields: { a: 'Local Heading' }),
         marc_field(tag: '690', subfields: { a: 'Local Heading' })]
      end

      it 'shows all valid subject headings without duplicates' do
        expect(helper.show(record)).to contain_exactly('Nephrology--Periodicals.', 'Nephrology.', 'Kidney Diseases.',
                                                       'Local Heading.')
      end
    end

    context 'with a robust 650 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '0', subfields: {
                      a: 'Subways',
                      z: ['Pennsylvania,', 'Philadelphia Metropolitan Area,'],
                      v: 'Maps',
                      y: '1989',
                      e: 'relator'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Subways--Pennsylvania--Philadelphia Metropolitan Area--Maps--1989 relator.'
      end
    end

    context 'with the record including trailing punctuation in the parts' do
      let(:fields) do
        [marc_field(tag: '600', indicator2: '7', subfields: {
                      a: 'Franklin, Benjamin,',
                      d: '1706-1790.',
                      '2': 'fast',
                      '0': 'http://id.worldcat.org/fast/34115'
                    }),
         marc_field(tag: '600', indicator1: '1', indicator2: '0', subfields: {
                      a: 'Franklin, Benjamin,',
                      d: '1706-1790',
                      x: 'As inventor.'
                    }),
         marc_field(tag: '650', indicator1: '1', indicator2: '0', subfields: {
                      a: 'Franklin stoves.'
                    })]
      end

      it 'properly handles punctuation in subject parts' do
        expect(values).to contain_exactly 'Franklin, Benjamin, 1706-1790.',
                                          'Franklin, Benjamin, 1706-1790--As inventor.', 'Franklin stoves.'
      end
    end

    context 'with a record without trailing period in last subject part' do
      let(:fields) do
        [marc_field(tag: '651', indicator2: '7',
                    subfields: {
                      a: 'New York State (State)', z: 'New York', '2': 'fast', '0': '(OCoLC)fst01204333',
                      '1': 'https://id.oclc.org/worldcat/entity/E39QbtfRvQh7864Jh4rDGBFDWc'
                    })]
      end

      it 'adds a trailing period' do
        expect(values).to contain_exactly('New York State (State)--New York.')
      end
    end

    context 'with a robust 651 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '651', indicator2: '4', subfields: {
                      a: 'Chicago (Ill.)',
                      x: 'Moral conditions',
                      '3': 'Church minutes',
                      y: '1875-1878',
                      '0': 'http://some.uri/zzz'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Chicago (Ill.)--Moral conditions--Church minutes--1875-1878.'
      end
    end

    context 'with a robust 611 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '611', indicator2: '0', subfields: {
                      a: 'Conference,',
                      c: ['(Johannesburg, South Africa,', 'Cape Town, South Africa,'],
                      d: '2002)',
                      n: '2nd'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Conference, (Johannesburg, South Africa, Cape Town, South Africa, 2002)--2nd.'
      end
    end

    context 'with a robust 600 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '600', indicator2: '0', subfields: {
                      a: 'Person, Significant Author,',
                      b: 'Numerator,',
                      c: ['Title,', 'Rank,'],
                      d: '1899-1971,',
                      t: 'Collection',
                      v: 'Early works to 1950.'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq('Person, Significant Author, Numerator, Title, Rank, 1899-1971, Collection--' \
                                   'Early works to 1950.')
      end
    end
  end

  describe '.childrens_show' do
    let(:record) do
      marc_record(fields: [
                    marc_field(tag: '650', indicator2: '1', subfields: { a: 'Frogs', v: 'Fiction' }),
                    marc_field(tag: '650', indicator2: '1', subfields: { a: 'Toads', v: 'Fiction' }),
                    marc_field(tag: '650', indicator2: '2', subfields: { a: 'Herpetology' })
                  ])
    end
    let(:values) { helper.childrens_show(record) }

    it 'includes heading terms only from subject tags with an indicator 2 of "1"' do
      expect(values).to contain_exactly 'Frogs--Fiction.', 'Toads--Fiction.'
    end
  end

  describe '.medical_show' do
    let(:record) do
      marc_record(
        fields: [
          marc_field(tag: '650', indicator2: '0', subfields: { a: 'Nephhrology', v: 'Periodicals' }),
          marc_field(tag: '650', indicator2: '7',
                     subfields: { a: 'Nephhrology', '2': 'fast', '0': '(OCoLC)fst01035991' }),
          marc_field(tag: '650', indicator2: '2', subfields: { a: 'Nephrology' }),
          marc_field(tag: '650', indicator2: '1', subfields: { a: 'Kidney Diseases' })
        ]
      )
    end

    it 'includes heading terms only from subject tags with indicator 2 of "2"' do
      expect(helper.medical_show(record)).to contain_exactly 'Nephrology.'
    end
  end

  describe '.local_show' do
    let(:record) do
      marc_record(fields: [
                    marc_field(tag: '650', indicator2: '4', subfields: { a: 'Local', v: 'Heading' }),
                    marc_field(tag: '690', indicator2: '4', subfields: { a: 'Super Local.' })
                  ])
    end

    it 'includes heading terms only from subject tags with indicator 2 of "4" or in the 69X range' do
      expect(helper.local_show(record)).to contain_exactly 'Local--Heading.', 'Super Local.'
    end
  end
end
