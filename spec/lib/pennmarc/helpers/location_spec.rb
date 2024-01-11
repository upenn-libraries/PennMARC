# frozen_string_literal: true

describe 'PennMARC::Location' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Location }
  let(:mapping) { location_map }

  describe 'location' do
    context "with only 'itm' field present" do
      let(:record) { marc_record(fields: [marc_field(tag: 'itm', subfields: { g: 'stor' })]) }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context "with only 'hld' field present" do
      let(:record) { marc_record(fields: [marc_field(tag: 'hld', subfields: { c: 'stor' })]) }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context "with both 'hld' and 'itm' fields present" do
      let(:record) do
        marc_record(fields: [marc_field(tag: 'itm', subfields: { g: 'stor' }),
                             marc_field(tag: 'hld', subfields: { c: 'dent' })])
      end

      it 'returns item location' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
      end
    end

    context 'with multiple library locations' do
      let(:record) { marc_record(fields: [marc_field(tag: 'itm', subfields: { g: %w[dent] })]) }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('Health Sciences Libraries',
                                                                            'Levy Dental Medicine Library')
      end
    end

    context 'without enriched marc location tag' do
      let(:record) { marc_record(fields: [marc_field(tag: '852', subfields: { g: 'stor' })]) }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to be_empty
      end
    end

    context 'with electronic inventory tag' do
      let(:record) { marc_record(fields: [marc_field(tag: 'itm', subfields: { g: 'stor' }), marc_field(tag: 'prt')]) }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA', PennMARC::Location::ONLINE_LIBRARY)
      end
    end

    context 'with AVA fields' do
      let(:record) do
        marc_record(fields: [marc_field(tag: 'AVA', subfields: { b: 'Libra', c: 'LIBRA', j: 'stor' })])
      end

      it 'returns expected values' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to(
          contain_exactly('LIBRA')
        )
      end
    end

    context 'with AVE fields' do
      let(:record) do
        marc_record(fields: [marc_field(tag: 'AVE', subfields: { m: 'Nature' })])
      end

      it 'returns expected values' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to(
          contain_exactly(PennMARC::Location::ONLINE_LIBRARY)
        )
      end
    end
  end
end
