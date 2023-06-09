# frozen_string_literal: true

describe 'PennMARC::Title' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Title }
  let(:record) { record_from marcxml_file }

  context 'with a test MARCXML file' do
    let(:marcxml_file) { 'test.xml' }

    describe '.show' do
      it 'returns the expected display value' do
        expect(helper.show(record)).to eq(
          'The Coopers & Lybrand guide to business tax strategies and planning / by the partners of Coopers & Lybrand.'
        )
      end
    end

    describe '.search' do
      xit 'returns the expected search values' do
        search_values = helper.search(record)
        expect(search_values).to be_an Array
        expect(search_values).to contain_exactly([])
      end
    end

    describe '.sort' do
      it 'returns the expected sort value' do
        expect(helper.sort(record)).to eq 'Coopers & Lybrand guide to business tax strategies and planning / The'
      end
    end
  end
end
