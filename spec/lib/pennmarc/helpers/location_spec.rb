# frozen_string_literal: true

describe 'PennMARC::Location' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Location }
  let(:record) { record_from 'test.xml' }

  describe 'library' do
    it 'calls location method' do
      allow(helper).to receive(:location)
      allow(helper).to receive(:library).and_call_original

      helper.library(record, helper::MAPPINGS)

      expect(helper).to have_received(:location)
    end
  end

  describe 'specific_location' do
    it 'calls location method' do
      allow(helper).to receive(:location)
      allow(helper).to receive(:specific_location).and_call_original

      helper.specific_location(record, helper::MAPPINGS)

      expect(helper).to have_received(:location)
    end
  end

  describe 'location' do
    it 'returns expected value' do
      expect(helper.location(record:, location_map: helper::MAPPINGS,
                             display_value: 'library')).to contain_exactly('LIBRA')
      expect(helper.location(record:, location_map: helper::MAPPINGS,
                             display_value: 'specific_location')).to contain_exactly('LIBRA')
    end

    context 'with multiple library locations' do
      let(:record) { marc_record(fields: [marc_field(tag: 'itm', subfields: { g: %w[stor oovanp] })]) }

      it 'returns expected value' do
        expect(helper.location(record:, location_map: helper::MAPPINGS,
                               display_value: 'library')).to contain_exactly('LIBRA',
                                                                             'Van Pelt-Dietrich Library Center')
      end
    end

    context 'without enriched marc location tag' do
      let(:record) { marc_record(fields: [marc_field(tag: '852', subfields: { g: %w[stor oovanp] })]) }

      it 'returns expected value' do
        expect(helper.location(record:, location_map: helper::MAPPINGS, display_value: 'library')).to be_empty
      end
    end

    context 'with electronic inventory tag' do
      let(:record) { marc_record(fields: [marc_field(tag: 'itm', subfields: { g: %w[stor] }), marc_field(tag: 'prt')]) }

      it 'returns expected value' do
        expect(helper.location(record:, location_map: helper::MAPPINGS,
                               display_value: 'library')).to contain_exactly('LIBRA', 'Online library')
      end
    end
  end
end
