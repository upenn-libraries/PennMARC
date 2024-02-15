# frozen_string_literal: true

describe 'PennMARC::Location' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Location }
  let(:enriched_marc) { PennMARC::Enriched }
  let(:mapping) { location_map }

  describe 'location' do
    context "with only 'itm' field present" do
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                                        subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor' })])
      end

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context "with only 'hld' field present" do
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                                        subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'stor' })])
      end

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context 'with both holding and item tag fields present=' do
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                                        subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor' }),
                             marc_field(tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                                        subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'dent' })])
      end

      it 'returns item location' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
      end
    end

    context 'with multiple library locations' do
      let(:record) { marc_record(fields: [marc_field(tag: enriched_marc::Pub::ITEM_TAG, subfields: { g: %w[dent] })]) }

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
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                                        subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor' }),
                             marc_field(tag: enriched_marc::Pub::ELEC_INVENTORY_TAG)])
      end

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA', helper::ONLINE_LIBRARY)
      end
    end

    context 'with AVA fields' do
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Api::PHYS_INVENTORY_TAG,
                                        subfields: {
                                          enriched_marc::Api::PHYS_LIBRARY_CODE => 'Libra',
                                          enriched_marc::Api::PHYS_LOCATION_NAME => 'LIBRA',
                                          enriched_marc::Api::PHYS_LOCATION_CODE => 'stor'
                                        })])
      end

      it 'returns expected values' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to(
          contain_exactly('LIBRA')
        )
      end
    end

    context 'with AVE fields' do
      let(:record) do
        marc_record(fields: [marc_field(tag: enriched_marc::Api::ELEC_INVENTORY_TAG,
                                        subfields: { enriched_marc::Api::ELEC_COLLECTION_NAME => 'Nature' })])
      end

      it 'returns expected values' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to(
          contain_exactly(helper::ONLINE_LIBRARY)
        )
      end
    end
  end

  context 'with a specific location override' do
    let(:record) do
      marc_record(fields: [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                                      subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'vanp',
                                                   enriched_marc::Pub::ITEM_CALL_NUMBER => 'ML3534 .D85 1984' }),
                           marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                                      subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor',
                                                   enriched_marc::Pub::ITEM_CALL_NUMBER => 'L3534 .D85 1984' })])
    end

    it 'returns expected values' do
      expect(helper.location(record: record, display_value: :specific_location, location_map: mapping))
        .to(contain_exactly(helper::ALBRECHT_MUSIC_SPECIFIC_LOCATION, 'LIBRA'))
    end
  end
end
