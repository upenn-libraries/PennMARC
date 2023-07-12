# frozen_string_literal: true

describe 'PennMARC::Genre' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Genre }
  let(:record) { marc_record fields: fields }

  describe '.search' do
    let(:values) { helper.search(record) }
    let(:fields) do
      [marc_field(tag: '655', indicator2: '4', subfields: {
                    a: 'Fan magazines', z: 'United States', y: '20th century'
                  }),
       marc_field(tag: '655', indicator2: '', subfields: { a: 'Zines' }),
       marc_field(tag: '655', indicator2: '7', subfields: { a: 'Magazine', '2': 'aat' }),
       marc_field(tag: '655', indicator2: '1', subfields: { a: "Children's Genre" })]
    end

    it 'includes only appropriate values, excluding subfields 0, 2, 5 and c' do
      expect(values).to contain_exactly "Children's Genre", 'Fan magazines United States 20th century',
                                        'Magazine', 'Zines'
    end
  end

  describe '.show' do
    let(:values) { helper.show(record) }
    let(:fields) do
      [marc_field(tag: '655', indicator2: '4', subfields: {
                    a: 'Magazines', b: 'Fan literature', z: 'United States', y: '20th century', '5': 'PU'
                  }),
       marc_field(tag: '655', indicator2: '', subfields: { a: 'Zines' }),
       marc_field(tag: '655', indicator2: '7', subfields: { a: 'Magazine', c: 'k', '0': '1234567', '2': 'aat' }),
       marc_field(tag: '655', indicator2: '1', subfields: { a: "Children's Genre" })]
    end

    it 'includes only appropriate values, excluding specified subfields, with proper formatting' do
      expect(values).to contain_exactly 'Magazines Fan literature -- United States -- 20th century', 'Magazine'
    end
  end

  describe '.facet' do
    let(:values) { helper.facet(record, location_map) }
    let(:location_map) do
      { manu: { specific_location: 'Secure Manuscripts Storage' },
        vanp: { specific_location: 'Van Pelt' } }
    end

    context 'for a non-video, non-manuscript record' do
      let(:fields) do
        [marc_control_field(tag: '007', value: 'x'),
         marc_field(tag: 'hld', subfields: { c: 'vanp' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Genre.' })]
      end

      it 'returns no genre values for faceting' do
        expect(values).to be_empty
      end
    end

    context 'for a video record' do
      let(:fields) do
        [marc_control_field(tag: '007', value: 'v'),
         marc_field(tag: 'hld', subfields: { c: 'vanp' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Documentary films' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Sports' })]
      end

      it 'contains the expected genre facet values' do
        expect(values).to contain_exactly 'Documentary films', 'Sports'
      end
    end

    context 'for a manuscript-located record' do
      let(:fields) do
        [marc_control_field(tag: '007', value: 'x'),
         marc_field(tag: 'hld', subfields: { c: 'manu' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Astronomy', '2': 'zzzz' })]
      end

      it 'returns the expected genre values' do
        expect(values).to contain_exactly 'Astronomy'
      end
    end
  end
end
