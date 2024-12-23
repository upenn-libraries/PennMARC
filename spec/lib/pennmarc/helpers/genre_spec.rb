# frozen_string_literal: true

describe 'PennMARC::Genre' do
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
       marc_field(tag: '655', indicator2: '0', subfields: { a: 'Magazine' }),
       marc_field(tag: '655', indicator2: '7', subfields: { a: 'Magazine', c: 'k', '0': '1234567', '2': 'aat' }),
       marc_field(tag: '655', indicator2: '1', subfields: { a: "Children's Genre" }),
       marc_field(tag: '880', indicator2: '4', subfields: { a: 'Alt. Magazine', '6': '655' })]
    end

    it 'includes only appropriate values, without specified subfields, with proper formatting and without duplicates' do
      expect(values).to contain_exactly 'Magazines Fan literature -- United States -- 20th century', 'Magazine',
                                        'Alt. Magazine'
    end
  end

  describe '.facet' do
    let(:values) { helper.facet(record) }

    context 'with a non-video, non-manuscript record' do
      let(:fields) do
        [marc_control_field(tag: '007', value: 'x'),
         marc_field(tag: 'hld', subfields: { c: 'vanp' }),
         marc_field(tag: '655', indicator2: '0', subfields: { a: 'Genre.' })]
      end

      it 'returns no genre values for faceting' do
        expect(values).to be_empty
      end
    end

    context 'with a video record' do
      let(:fields) do
        [marc_control_field(tag: '007', value: 'v'),
         marc_field(tag: 'hld', subfields: { c: 'vanp' }),
         marc_field(tag: '655', indicator2: '0', subfields: { a: 'Documentary films' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Sports', '2': 'fast' }),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Le cyclisme', '2': 'qlsp' }), # excluded due to sf2
         marc_field(tag: '655', indicator2: '1', subfields: { a: 'Shredding' })] # excluded, invalid indicator value
      end

      it 'contains only the desired genre facet values' do
        expect(values).to contain_exactly 'Documentary films', 'Sports'
      end
    end

    context 'with a manuscript record' do
      let(:record) { marc_record fields: fields, leader: '      t' }
      let(:fields) do
        [marc_control_field(tag: '007', value: 'x'),
         marc_field(tag: '655', indicator2: '7', subfields: { a: 'Astronomy', '2': 'fast' })]
      end

      it 'returns the expected genre values' do
        expect(values).to contain_exactly 'Astronomy'
      end
    end
  end
end
