# frozen_string_literal: true

describe 'PennMARC::Classification' do
  let(:helper) { PennMARC::Classification }
  let(:record) { marc_record fields: fields }

  describe '.facet' do
    let(:fields) do
      [marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '0', config[:call_number_sf] => 'TA683 .B3 1909b' }),
       marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '0', config[:call_number_sf] => 'QL756 .S643' }),
       marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '1', config[:call_number_sf] => '691.3 B2141' }),
       marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '1', config[:call_number_sf] => '378.748 POS1952.29' })]
    end

    context 'with enrichment via the Alma publishing process and itm fields' do
      let(:config) do
        { tag: PennMARC::Enriched::Pub::ITEM_TAG,
          call_number_type_sf: PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE,
          call_number_sf: PennMARC::Enriched::Pub::ITEM_CALL_NUMBER }
      end

      it 'returns expected values' do
        expect(helper.facet(record)).to contain_exactly('T - Technology', '600 - Technology',
                                                        '300 - Social sciences', 'Q - Science')
      end
    end

    context 'with enrichment with availability info via Alma Api' do
      let(:config) do
        { tag: PennMARC::Enriched::Api::PHYS_INVENTORY_TAG,
          call_number_type_sf: PennMARC::Enriched::Api::PHYS_CALL_NUMBER_TYPE,
          call_number_sf: PennMARC::Enriched::Api::PHYS_CALL_NUMBER }
      end

      it 'returns expected values' do
        expect(helper.facet(record)).to contain_exactly('T - Technology', '600 - Technology',
                                                        '300 - Social sciences', 'Q - Science')
      end
    end
  end

  describe '.sort' do
    context 'with enrichment via the Alma publishing process and itm fields' do
      let(:fields) do
        [marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG, subfields: {
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE => '0',
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER => 'QL756 .S643'
                    }),
         marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG, subfields: {
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE => '0',
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER => 'Secret Drawer Copy'
                    }),
         marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG, subfields: {
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE => '1',
                      PennMARC::Enriched::Pub::ITEM_CALL_NUMBER => '691.3 B2141'
                    })]
      end

      it 'excludes call numbers not designated as LC call numbers' do
        expect(helper.sort(record)).not_to include '2141'
      end

      it 'returns expected normalized values' do
        expect(helper.sort(record)).to match_array 'QL.0756.S643'
      end

      it 'excludes call numbers that are improper LC call numbers' do
        expect(helper.sort(record)).not_to include 'Secret'
      end
    end

    context 'with enrichment via the Alma publishing process and only hld fields' do
      let(:fields) do
        [marc_field(tag: PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG,
                    subfields: { PennMARC::Enriched::Pub::HOLDING_CLASSIFICATION_PART => 'KF6450',
                                 PennMARC::Enriched::Pub::HOLDING_ITEM_PART => '.C59 1989' })]
      end

      it 'returns expected normalized values' do
        expect(helper.sort(record)).to match_array 'KF.6450.C59.1989'
      end
    end

    context 'with enrichment with availability info via Alma Api' do
      let(:fields) do
        [marc_field(tag: PennMARC::Enriched::Api::PHYS_INVENTORY_TAG, subfields: {
                      PennMARC::Enriched::Api::PHYS_CALL_NUMBER_TYPE => '0',
                      PennMARC::Enriched::Api::PHYS_CALL_NUMBER => 'QL756 .S643'
                    })]
      end

      it 'returns expected normalized values' do
        expect(helper.sort(record)).to match_array 'QL.0756.S643'
      end
    end
  end

  describe '.call_number_search' do
    let(:fields) do
      [marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '0', config[:call_number_sf] => 'QL756 .S643' }),
       marc_field(tag: config[:tag],
                  subfields: { config[:call_number_type_sf] => '1', config[:call_number_sf] => '691.3 B2141' })]
    end

    context 'with enrichment via the Alma publishing process' do
      let(:config) do
        { tag: PennMARC::Enriched::Pub::ITEM_TAG,
          call_number_type_sf: PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE,
          call_number_sf: PennMARC::Enriched::Pub::ITEM_CALL_NUMBER }
      end

      it 'returns expected values' do
        expect(helper.call_number_search(record)).to contain_exactly '691.3 B2141', 'QL756 .S643'
      end
    end

    context 'with enrichment via the Alma publishing process and no itm fields' do
      let(:fields) do
        [marc_field(tag: PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG,
                    subfields: { PennMARC::Enriched::Pub::HOLDING_CLASSIFICATION_PART => 'KF6450',
                                 PennMARC::Enriched::Pub::HOLDING_ITEM_PART => '.C59 1989' })]
      end

      it 'returns expected values from the hld tag' do
        expect(helper.call_number_search(record)).to contain_exactly('KF6450 .C59 1989')
      end
    end

    context 'with enrichment via the Alma publishing process and values from both hld and itm fields' do
      let(:fields) do
        [marc_field(tag: PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG,
                    subfields: { PennMARC::Enriched::Pub::HOLDING_CLASSIFICATION_PART => 'KF6450',
                                 PennMARC::Enriched::Pub::HOLDING_ITEM_PART => '.C59 1989' }),
         marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG,
                    subfields: { PennMARC::Enriched::Pub::ITEM_CALL_NUMBER => 'KF6450 .C59 1989' })]
      end

      it 'returns a single call number' do
        expect(helper.call_number_search(record)).to contain_exactly('KF6450 .C59 1989')
      end
    end

    context 'with enrichment with availability info via Alma Api' do
      let(:config) do
        { tag: PennMARC::Enriched::Api::PHYS_INVENTORY_TAG,
          call_number_type_sf: PennMARC::Enriched::Api::PHYS_CALL_NUMBER_TYPE,
          call_number_sf: PennMARC::Enriched::Api::PHYS_CALL_NUMBER }
      end

      it 'returns expected values' do
        expect(helper.call_number_search(record)).to contain_exactly '691.3 B2141', 'QL756 .S643'
      end
    end
  end
end
