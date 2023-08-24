# frozen_string_literal: true

describe 'PennMARC::Language' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Language }
  let(:mapping) do
    { eng: 'English', und: 'Undetermined', fre: 'French', ger: 'German' }
  end
  let(:record) do
    marc_record fields: [
      marc_control_field(tag: '008', value: '                                   eng'),
      marc_field(tag: '041', subfields: { a: 'eng', b: 'fre', d: 'ger' }),
      marc_field(tag: '546', subfields: { a: 'Great', c: 'Content', '6': 'Not Included' }),
      marc_field(tag: '546', subfields: { b: 'More!', '8': 'Not Included' }),
      marc_field(tag: '880', subfields: { c: 'Mas!', '6': '546', '8': 'Not Included' })
    ]
  end

  describe '.search' do
    it 'returns the expected display values' do
      expect(helper.search(record, language_map: mapping)).to contain_exactly('English', 'French', 'German')
    end
  end

  describe '.show' do
    it 'returns the expected show values' do
      expect(helper.show(record)).to contain_exactly 'Great Content', 'More!', 'Mas!'
    end
  end
end
