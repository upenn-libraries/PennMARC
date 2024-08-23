# frozen_string_literal: true

describe 'PennMARC::Location' do
  let(:helper) { PennMARC::Location }
  let(:enriched_marc) { PennMARC::Enriched }
  let(:mapping) { location_map }
  let(:record) { marc_record(fields: fields) }

  describe 'location' do
    context "with only 'itm' field present" do
      let(:fields) do
        [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                    subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor' })]
      end

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context "with only 'hld' field present" do
      let(:fields) do
        [marc_field(tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                    subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'stor' })]
      end

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
        expect(helper.location(record: record, location_map: mapping,
                               display_value: 'specific_location')).to contain_exactly('LIBRA')
      end
    end

    context 'with both holding and item tag fields present=' do
      let(:fields) do
        [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                    subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor' }),
         marc_field(tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                    subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'dent' })]
      end

      it 'returns item location' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('LIBRA')
      end
    end

    context 'with multiple library locations' do
      let(:fields) { [marc_field(tag: enriched_marc::Pub::ITEM_TAG, subfields: { g: %w[dent] })] }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping,
                               display_value: :library)).to contain_exactly('Health Sciences Libraries',
                                                                            'Levy Dental Medicine Library')
      end
    end

    context 'without enriched marc location tag' do
      let(:fields) { [marc_field(tag: '852', subfields: { g: 'stor' })] }

      it 'returns expected value' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to be_empty
      end
    end

    context 'with AVA fields' do
      let(:fields) do
        [marc_field(tag: enriched_marc::Api::PHYS_INVENTORY_TAG,
                    subfields: { enriched_marc::Api::PHYS_LIBRARY_CODE => 'Libra',
                                 enriched_marc::Api::PHYS_LOCATION_NAME => 'LIBRA',
                                 enriched_marc::Api::PHYS_LOCATION_CODE => 'stor' })]
      end

      it 'returns expected values' do
        expect(helper.location(record: record, location_map: mapping, display_value: :library)).to(
          contain_exactly('LIBRA')
        )
      end
    end

    context 'with a specific location override' do
      context 'with item fields and LC call nums' do
        let(:fields) do
          [marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                      subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'vanp',
                                   enriched_marc::Pub::ITEM_CALL_NUMBER_TYPE =>
                                     PennMARC::Classification::LOC_CALL_NUMBER_TYPE,
                                   enriched_marc::Pub::ITEM_CALL_NUMBER => 'ML3534 .D85 1984' }),
           marc_field(tag: enriched_marc::Pub::ITEM_TAG,
                      subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'stor',
                                   enriched_marc::Pub::ITEM_CALL_NUMBER_TYPE => '8',
                                   enriched_marc::Pub::ITEM_CALL_NUMBER => 'L3534 .D85 1984' })]
        end

        it 'returns expected values' do
          expect(helper.location(record: record, display_value: :specific_location, location_map: mapping))
            .to(contain_exactly(PennMARC::Mappers.location_overrides[:albrecht][:specific_location], 'LIBRA'))
        end

        it 'returns expected values when receiving a string for display_value' do
          expect(helper.location(record: record, display_value: 'specific_location', location_map: mapping))
            .to(contain_exactly(PennMARC::Mappers.location_overrides[:albrecht][:specific_location], 'LIBRA'))
        end
      end

      context 'with item fields and microfilm call nums' do
        let(:fields) do
          [marc_field(tag: enriched_marc::Pub::ITEM_TAG, indicator1: ' ',
                      subfields: { enriched_marc::Pub::ITEM_CURRENT_LOCATION => 'vanp',
                                   enriched_marc::Pub::ITEM_CALL_NUMBER_TYPE => '8',
                                   enriched_marc::Pub::ITEM_CALL_NUMBER => 'Microfilm 3140 item 8' })]
        end

        it 'returns expected values' do
          expect(helper.location(record: record, display_value: :specific_location, location_map: mapping))
            .to(contain_exactly(PennMARC::Mappers.location[:vanp][:specific_location]))
        end
      end

      context 'with holding fields and both LC and non-LC call num type' do
        let(:fields) do
          [marc_field(indicator1: '8', tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                      subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'vanp' }),
           marc_field(indicator1: '0', tag: enriched_marc::Pub::PHYS_INVENTORY_TAG,
                      subfields: { enriched_marc::Pub::PHYS_LOCATION_CODE => 'vanp',
                                   enriched_marc::Pub::HOLDING_CLASSIFICATION_PART => 'ML3534' })]
        end

        it 'returns expected values' do
          expect(helper.location(record: record, display_value: :specific_location, location_map: mapping))
            .to(contain_exactly(PennMARC::Mappers.location[:vanp][:specific_location],
                                PennMARC::Mappers.location_overrides[:albrecht][:specific_location]))
        end
      end

      context 'with a variety of holding fields from the Alma API enrichment' do
        let(:fields) do
          [marc_field(tag: enriched_marc::Api::PHYS_INVENTORY_TAG,
                      subfields: { enriched_marc::Api::PHYS_CALL_NUMBER => 'Locked Closet Floor',
                                   enriched_marc::Api::PHYS_CALL_NUMBER_TYPE => '8' }),
           marc_field(tag: enriched_marc::Api::PHYS_INVENTORY_TAG,
                      subfields: { enriched_marc::Api::PHYS_LOCATION_CODE => 'vanp',
                                   enriched_marc::Api::PHYS_CALL_NUMBER => ['ML123 .P567 1875', 'ML123'],
                                   enriched_marc::Api::PHYS_CALL_NUMBER_TYPE =>
                                     PennMARC::Classification::LOC_CALL_NUMBER_TYPE }),
           marc_field(tag: enriched_marc::Api::PHYS_INVENTORY_TAG,
                      subfields: { enriched_marc::Api::PHYS_LOCATION_CODE => 'vanp',
                                   enriched_marc::Api::PHYS_CALL_NUMBER => 'P789 .D123 2012',
                                   enriched_marc::Api::PHYS_CALL_NUMBER_TYPE =>
                                     PennMARC::Classification::LOC_CALL_NUMBER_TYPE })]
        end

        it 'returns expected values' do
          expect(helper.location(record: record, display_value: :specific_location, location_map: mapping))
            .to(contain_exactly(PennMARC::Mappers.location[:vanp][:specific_location],
                                PennMARC::Mappers.location_overrides[:albrecht][:specific_location]))
        end
      end
    end
  end
end
