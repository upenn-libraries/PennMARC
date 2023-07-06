# frozen_string_literal: true

describe 'PennMARC::Subject' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Subject }
  let(:relator_map) do
    { dpc: 'Depicted' }
  end

  describe '.search' do
    let(:record) { marc_record fields: fields }
    let(:values) { helper.search(record, relator_map) }

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
    let(:record) { marc_record fields: }
    let(:values) { helper.facet(record) }

    # TODO: find some more inspiring examples in the corpus
    context 'for a record with poorly-coded heading values' do
      let(:fields) { [marc_field(tag: '650', indicator2: '0', subfields: { a: 'Subject -   Heading' })] }

      it 'properly normalizes the heading value' do
        expect(values.first).to eq 'Subject--Heading'
      end
    end

    context 'for a record with 650 headings with a ǂa that starts with PRO or CHR' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '4', subfields: { a: '%CHR 1998', '5': 'PU' }),
         marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Potok, Adena (donor) (Potok Collection copy)',
                                                              '5': 'PU' })]
      end

      it 'does not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'for a record with an indicator2 value of 3, 5 or 6' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '3', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '5', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '6', subfields: { a: 'Nope' })]
      end

      it 'does not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'for a record with a valid tag, indicator2 and source specified' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '7',
                    subfields: {
                      a: 'Libraries', x: 'History', e: 'relator', d: '22nd Century',
                      '2': 'fast', '0': 'http://fast.org/libraries'
                    })]
      end

      it 'properly concatenates heading components' do
        expect(values.first).to include 'Libraries--History'
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
        expect(values.first).to eq 'Libraries--History 22nd Century'
      end
    end
  end

  describe '.show' do
    let(:record) { marc_record fields: }
    let(:values) { helper.facet(record) }

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
        expect(helper.show(record)).to match_array ['Nephrology--Periodicals', 'Nephrology',
                                                    'Kidney Diseases', 'Local Heading']
      end
    end

    context 'with a robust 650 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '0', subfields: {
                      a: 'Subways',
                      z: ['Pennsylvania', 'Philadelphia Metropolitan Area'],
                      v: 'Maps',
                      y: '1989',
                      e: 'relator'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Subways--Pennsylvania--Philadelphia Metropolitan Area--Maps--1989'
        expect(values.first).not_to include 'relator'
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
        expect(values.first).to eq 'Chicago (Ill.)--Moral conditions--Church minutes--1875-1878'
      end
    end

    context 'with a robust 611 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '611', indicator2: '0', subfields: {
                      a: 'Conference',
                      d: '(2002',
                      n: '2nd',
                      c: ['Johannesburg, South Africa', 'Cape Town, South Africa)']
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Conference--2nd (2002 Johannesburg, South Africa Cape Town, South Africa)'
      end
    end

    context 'with a robust 600 heading including many subfields' do
      let(:fields) do
        [marc_field(tag: '600', indicator2: '0', subfields: {
                      a: 'Person, Significant Author',
                      d: '1899-1971',
                      v: 'Early works to 1950',
                      t: 'Collection'
                    })]
      end

      it 'properly formats the heading parts' do
        expect(values.first).to eq 'Person, Significant Author--Early works to 1950 1899-1971 Collection'
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
      expect(values).to contain_exactly 'Frogs--Fiction', 'Toads--Fiction'
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
      expect(helper.medical_show(record)).to contain_exactly 'Nephrology'
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
      expect(helper.local_show(record)).to contain_exactly 'Local--Heading', 'Super Local.'
    end
  end
end
