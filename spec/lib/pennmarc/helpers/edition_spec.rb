# frozen_string_literal: true

describe 'PennMARC::Edition' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Edition }
  let(:record) do
    marc_record fields: [marc_field(tag: '250', subfields: { a: '5th Edition', b: 'Remastered' }),
                         marc_field(tag: '880', subfields: { '6': '250', b: 'رمستر' }),
                         marc_field(tag: '775', subfields: { i: 'Other Edition (Remove)',
                                                             h: 'Cool Book' })]
  end

  describe '.show' do
    it 'returns the editions' do
      expect(helper.show(record)).to contain_exactly('5th Edition Remastered', 'رمستر')
    end
  end

  describe '.values' do
    it 'returns the values' do
      expect(helper.values(record)).to contain_exactly('5th Edition Remastered')
    end
  end

  describe '.other_show' do
    it 'returns other edition values' do
      expect(helper.other_show(record)).to contain_exactly('Other Edition :   (Cool Book) ')
    end
  end
end



