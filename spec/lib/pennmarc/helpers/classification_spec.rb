# frozen_string_literal: true

describe 'PennMARC::Classification' do
  let(:helper) { PennMARC::Classification }
  let(:record) do
    marc_record fields: [marc_field(tag: tag,
                                    subfields: { call_number_type_sf => '0', call_number_sf => 'TA683 .B3 1909b' }),
                         marc_field(tag: tag,
                                    subfields: { call_number_type_sf => '0', call_number_sf => 'QL756 .S643' }),
                         marc_field(tag: tag,
                                    subfields: { call_number_type_sf => '1', call_number_sf => '691.3 B2141' }),
                         marc_field(tag: tag,
                                    subfields: { call_number_type_sf => '1', call_number_sf => '378.748 POS1952.29' })]
  end

  describe '.facet' do
    context 'with enrichment via the Alma publishing process' do
      let(:tag) { PennMARC::Enriched::Pub::ITEM_TAG }
      let(:call_number_type_sf) { PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE }
      let(:call_number_sf) { PennMARC::Enriched::Pub::ITEM_CALL_NUMBER }

      it 'returns expected values' do
        expect(helper.facet(record)).to contain_exactly('T - Technology', '600 - Technology',
                                                        '300 - Social sciences', 'Q - Science')
      end
    end

    context 'with enrichment with availability info via Alma Api' do
      let(:tag) { PennMARC::Enriched::Api::PHYS_INVENTORY_TAG }
      let(:call_number_type_sf) { PennMARC::Enriched::Api::PHYS_CALL_NUMBER_TYPE }
      let(:call_number_sf) { PennMARC::Enriched::Api::PHYS_CALL_NUMBER }

      it 'returns expected values' do
        expect(helper.facet(record)).to contain_exactly('T - Technology', '600 - Technology',
                                                        '300 - Social sciences', 'Q - Science')
      end
    end
  end
end
