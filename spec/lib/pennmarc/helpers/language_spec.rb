# frozen_string_literal: true

describe 'PennMARC::Language' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Language }
  let(:iso_639_2_mapping) do
    { eng: 'English', und: 'Undetermined', fre: 'French', ger: 'German' }
  end
  let(:iso_639_3_mapping) do
    { eng: 'American', und: 'Undetermined', fre: 'Francais', ger: 'Deutsch' }
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
  let(:second_record) do
    marc_record fields: [
      marc_field(tag: '041', subfields: { '2': 'iso639-3', a: 'eng', b: 'fre', d: 'ger' }),
    ]
  end
  let(:empty_record) do
    marc_record fields: [
      marc_field(tag: '041', subfields: { c: 'test' })
    ]
  end

  describe '.search' do
    it 'returns the expected display values from iso639-2' do
      expect(helper.search(record,
                           iso_639_2_mapping: iso_639_2_mapping,
                           iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('English', 'French', 'German')
    end

    it 'returns the expected display values from iso639-3' do
      expect(helper.search(second_record,
                           iso_639_2_mapping: iso_639_2_mapping,
                           iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly('American', 'Francais', 'Deutsch')
    end

    it 'returns undetermined when there are no values' do
      expect(helper.search(empty_record,
                           iso_639_2_mapping: iso_639_2_mapping,
                           iso_639_3_mapping: iso_639_3_mapping)).to contain_exactly(:und)
    end
  end

  describe '.show' do
    it 'returns the expected show values' do
      expect(helper.show(record)).to contain_exactly 'Great Content', 'More!', 'Mas!'
    end
  end
end
