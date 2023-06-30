# frozen_string_literal: true

describe 'PennMARC::Subject' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Subject }
  let(:relator_map) do
    {}
  end

  describe '.search' do
    context 'with a mix of included and excluded tags' do
      let(:record) do
        marc_record fields: [
          marc_field(tag: '600', indicator2: '5', subfields: { a: 'Excluded Canadian' }),
          marc_field(tag: '610', indicator2: '0', subfields: { a: 'University of Pennsylvania', b: 'Libraries' }),
          marc_field(tag: '691', indicator2: '7', subfields: { a: 'Van Pelt Library', '2': 'local' }),
          marc_field(tag: '696', indicator2: '4', subfields: { a: 'A Developer' }),
          marc_field(tag: '880', indicator2: '0', subfields: { a: 'Alt. Name', '6': '610' })
        ]
      end

      it 'includes only values from valid tags' do
        values = helper.search(record, relator_map)
        expect(values).to contain_exactly 'A Developer', 'Alt. Name', 'University of Pennsylvania Libraries',
                                          'Van Pelt Library local'
        expect(values).not_to include 'Excluded Canadian'
      end
    end
  end

  describe '.show' do
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
        [marc_field(tag: '650', indicator2: '4', subfields: { a: 'CHR 1998', '5': 'PU' }),
         marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Potok, Adena (donor) (Potok Collection copy)',
                                                              '5': 'PU' })]
      end

      it 'des not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'for a record with an indicator2 value of 3 5 or 6' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '3', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '5', subfields: { a: 'Nope' }),
         marc_field(tag: '650', indicator2: '6', subfields: { a: 'Nope' })]
      end

      it 'des not include the headings' do
        expect(values).to be_empty
      end
    end

    context 'for a record with a valid 650 field' do
      let(:fields) do
        [marc_field(tag: '650', indicator2: '7',
                    subfields: {
                      a: 'Libraries', x: 'History', e: 'relator', d: '22nd Century',
                      '2': 'fast', '0': 'http://fast.org/history'
                    })]
      end

      it 'properly concatenates heading components' do
        expect(values.first).to include 'Libraries--History'
      end

      it 'excludes URI values from ǂ0 or ǂ1' do
        expect(values.first).not_to include 'http'
      end

      it 'excludes relator term values from ǂe' do
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

  describe '.childrens_show' do
    let(:record) do
      marc_record(fields: [
                    marc_field(tag: '650', indicator2: '1', subfields: { a: 'Frogs', v: 'Fiction' }),
                    marc_field(tag: '650', indicator2: '1', subfields: { a: 'Toads', v: 'Fiction' })
                  ])
    end
    let(:values) { helper.childrens_show(record) }

    it 'works' do
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
          marc_field(tag: '650', indicator1: '1', indicator2: '2', subfields: { a: 'Nephrology' }),
          marc_field(tag: '650', indicator1: '2', indicator2: '1', subfields: { a: 'Kidney Diseases' })
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
