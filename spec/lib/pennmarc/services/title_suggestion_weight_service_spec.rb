# frozen_string_literal: true

describe PennMARC::TitleSuggestionWeightService do
  let(:record) { instance_double MARC::Record }

  describe '.weight' do
    context 'with defined factors' do
      before do
        allow(described_class).to receive_messages(
          targeted_format?: true,
          published_in_last_ten_years?: false,
          electronic_holdings?: false,
          high_encoding_level?: false,
          physical_holdings?: false,
          low_encoding_level?: false,
          weird_format?: false,
          no_holdings?: false
        )
      end

      it 'scores properly based on factor responce valence' do
        expected_score = described_class::BASE_WEIGHT + described_class::FACTORS[0].second
        expect(described_class.weight(record)).to eq expected_score
      end
    end
  end

  describe '.published_in_the_last_ten_years' do
    before { allow(PennMARC::Date).to receive(:publication).with(record).and_return(record_date) }

    let(:value) { described_class.published_in_last_ten_years?(record) }

    context 'with no date' do
      let(:record_date) { nil }

      it 'returns true' do
        expect(value).to be false
      end
    end

    context 'with a recent date' do
      let(:record_date) { Time.now }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'with an ancient date' do
      let(:record_date) { Time.now - 400.years }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.targeted_format?' do
    before { allow(PennMARC::Format).to receive(:facet).with(record).and_return([record_format]) }

    let(:value) { described_class.targeted_format?(record) }

    context 'with no format' do
      let(:record_format) { nil }

      it 'returns false' do
        expect(value).to be false
      end
    end

    context 'with a targeted format' do
      let(:record_format) { PennMARC::TitleSuggestionWeightService::TARGETED_FORMATS.sample }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'with a non-targeted format' do
      let(:record_format) { PennMARC::TitleSuggestionWeightService::WEIRD_FORMATS.sample }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.weird_format?' do
    before { allow(PennMARC::Format).to receive(:facet).with(record).and_return([record_format]) }

    let(:value) { described_class.weird_format?(record) }

    context 'with no format' do
      let(:record_format) { nil }

      it 'returns false' do
        expect(value).to be false
      end
    end

    context 'with a weird format' do
      let(:record_format) { PennMARC::TitleSuggestionWeightService::WEIRD_FORMATS.sample }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'with a non-weird format' do
      let(:record_format) { PennMARC::TitleSuggestionWeightService::TARGETED_FORMATS.sample }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.low_encoding_level?' do
    before { allow(PennMARC::Encoding).to receive(:level_sort).with(record).and_return(encoding_sort_score) }

    let(:value) { described_class.low_encoding_level?(record) }

    context 'with no encoding level' do
      let(:encoding_sort_score) { nil }

      it 'returns false' do
        expect(value).to be false
      end
    end

    context 'with a low encoding level' do
      let(:encoding_sort_score) { 11 }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'with a high encoding level' do
      let(:encoding_sort_score) { PennMARC::TitleSuggestionWeightService::HIGH_ENCODING_SORT_LEVEL }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.electronic_holdings?' do
    before do
      allow(PennMARC::Inventory).to receive(:electronic).with(record).and_return(holdings)
    end

    let(:value) { described_class.electronic_holdings?(record) }

    context 'with electronic holdings' do
      let(:holdings) { [PennMARC::InventoryEntry::Electronic] }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'without any holdings' do
      let(:holdings) { [] }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.physical_holdings?' do
    before do
      allow(PennMARC::Inventory).to receive(:physical).with(record).and_return(holdings)
    end

    let(:value) { described_class.physical_holdings?(record) }

    context 'with physical holdings' do
      let(:holdings) { [PennMARC::InventoryEntry::Physical] }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'without any holdings' do
      let(:holdings) { [] }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end

  describe '.no_holdings?' do
    before do
      allow(PennMARC::Inventory).to receive(:physical).with(record).and_return(physical_holdings)
      allow(PennMARC::Inventory).to receive(:electronic).with(record).and_return(electronic_holdings)
    end

    let(:value) { described_class.no_holdings?(record) }

    context 'with neither physical nor electronic holdings' do
      let(:physical_holdings) { [] }
      let(:electronic_holdings) { [] }

      it 'returns true' do
        expect(value).to be true
      end
    end

    context 'with only electronic holdings' do
      let(:physical_holdings) { [] }
      let(:electronic_holdings) { [instance_double(PennMARC::InventoryEntry::Electronic)] }

      it 'returns false' do
        expect(value).to be false
      end
    end

    context 'with only physical holdings' do
      let(:physical_holdings) { [instance_double(PennMARC::InventoryEntry::Physical)] }
      let(:electronic_holdings) { [] }

      it 'returns false' do
        expect(value).to be false
      end
    end
  end
end
