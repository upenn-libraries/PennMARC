# frozen_string_literal: true

describe PennMARC::TitleSuggestionWeightService do
  let(:record) { instance_double MARC::Record }

  describe '.weight' do
    context 'with a weight factor that has no corresponding method' do
      let(:factors) { [[:bad_name, 0]] }

      before { allow(described_class).to receive(:factors).and_return(factors) }

      it 'logs a warning to STDERR' do
        expect { described_class.weight(record) }.to output("Unknown weighting method: bad_name\n").to_stderr
      end
    end

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

end
