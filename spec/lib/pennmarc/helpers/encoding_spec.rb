# frozen_string_literal: true

describe 'PennMARC::Encoding' do
  let(:helper) { PennMARC::Encoding }

  describe '.sort' do
    let(:record) { marc_record leader: leader }
    let(:result) { helper.level_sort record }
    let(:leader) { "                 #{level}     " }

    context 'with an empty value' do
      let(:level) { PennMARC::EncodingLevel::FULL }

      it 'returns 0' do
        expect(result).to eq 0
      end
    end

    context 'with an official MARC code present' do
      let(:level) { PennMARC::EncodingLevel::MINIMAL }

      it 'returns 7' do
        expect(result).to eq 7
      end
    end

    context 'with an OCLC extension code' do
      let(:level) { PennMARC::EncodingLevel::OCLC_BATCH }

      it 'returns 9' do
        expect(result).to eq 9
      end
    end

    context 'with an unhandled value' do
      let(:level) { 'T' }

      it 'returns nil' do
        expect(result).to be_nil
      end
    end
  end
end
