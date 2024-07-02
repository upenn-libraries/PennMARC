# frozen_string_literal: true

describe 'PennMARC::Language' do
  let(:helper) { PennMARC::Language }
  let(:iso_639_2_mapping) do
    { eng: 'English', und: 'Undetermined', fre: 'French', ger: 'German', ulw: 'Ulwa' }
  end
  let(:iso_639_3_mapping) do
    { eng: 'American', und: 'Undetermined', fre: 'Francais', ger: 'Deutsch', twf: 'Northern Tiwa' }
  end
  let(:record) do
    marc_record fields: [
      marc_control_field(tag: '008', value: '                                   eng'),
      marc_field(tag: '041', subfields: { '2': 'iso639-2', a: 'eng', b: 'fre', d: 'ger' }),
      marc_field(tag: '546', subfields: { a: 'Great', c: 'Content', '6': 'Not Included' }),
      marc_field(tag: '546', subfields: { b: 'More!', '8': 'Not Included' }),
      marc_field(tag: '880', subfields: { c: 'Mas!', '6': '546', '8': 'Not Included' })
    ]
  end

  describe '.show' do
    it 'returns the expected show values' do
      expect(helper.show(record)).to contain_exactly 'Great Content', 'More!', 'Mas!'
    end
  end

  describe '.search' do
    context 'when using iso 639-2 spec' do
      it 'returns the expected display values from iso639-2' do
        expect(helper.values(record,
                             iso_639_2_mapping: iso_639_2_mapping,
                             iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('English', 'French', 'German')
      end
    end

    context 'when using iso639-3 spec' do
      let(:record) do
        marc_record fields: [marc_field(tag: '041', subfields: { '2': 'iso639-3', a: 'eng', b: 'fre', d: 'ger' }),
                             marc_field(tag: '041', subfields: { '2': 'iso639-3', a: 'twf' })]
      end

      it 'returns the expected display values from iso639-3' do
        expect(helper.values(record,
                             iso_639_2_mapping: iso_639_2_mapping,
                             iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('American', 'Francais',
                                                                                       'Deutsch', 'Northern Tiwa')
      end
    end

    context 'when using multiple specs' do
      let(:record) do
        marc_record fields: [marc_field(tag: '041', subfields: { '2': 'iso639-3', a: 'eng', b: 'fre', d: 'ger' }),
                             marc_field(tag: '041', subfields: { '2': 'iso639-2', a: 'ulw' })]
      end

      it 'returns the expected display values from iso639-3' do
        expect(helper.values(record,
                             iso_639_2_mapping: iso_639_2_mapping,
                             iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('American', 'Francais',
                                                                                       'Deutsch', 'Ulwa')
      end
    end

    context 'with an empty record' do
      let(:record) do
        marc_record fields: [marc_field(tag: '041', subfields: { c: 'test' })]
      end

      it 'returns undetermined when there are no values' do
        expect(helper.values(record,
                             iso_639_2_mapping: iso_639_2_mapping,
                             iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('Undetermined')
      end
    end
  end
end
