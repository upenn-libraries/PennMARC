# frozen_string_literal: true

describe 'PennMARC::Language' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Language }
  let(:record) { record_from marcxml_file }
  let(:mapping) do
    { eng: 'English', und: 'Undetermined' }
  end

  context 'with a test MARCXML file' do
    let(:marcxml_file) { 'test.xml' }

    describe '.search' do
      it 'returns the expected display value' do
        expect(helper.search(record, mapping)).to eq 'English'
      end
    end

    describe '.show' do
      it 'returns the expected show values' do
        expect(helper.show(record)).to eq [] # TODO: i need a better test record...
      end
    end
  end
end
