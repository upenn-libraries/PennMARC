# frozen_string_literal: true

describe 'PennMARC::Inventory' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Inventory }
  let(:record) do
    marc_record fields: fields
  end

  describe 'physical' do
    let(:fields) do
      [marc_field(tag: mapper::PHYS_INVENTORY_TAG,
                  subfields: subfields)]
    end

    context 'with API enrichment fields' do
      let(:mapper) { PennMARC::Enriched::Api }
      let(:subfields) do
        { mapper::PHYS_CALL_NUMBER => 'AB123.4',
          mapper::PHYS_HOLDING_ID => '123456789',
          mapper::PHYS_LOCATION_CODE => 'vanpelt',
          mapper::PHYS_LOCATION_NAME => 'Van Pelt Library',
          mapper::PHYS_PRIORITY => '1' }
      end

      it 'returns expected array of hash values' do
        expect(helper.physical(record)).to contain_exactly(
          { call_num: 'AB123.4', holding_id: '123456789', location_code: 'vanpelt',
            location_name: 'Van Pelt Library', priority: '1' }
        )
      end
    end

    context 'with Pub enrichment fields' do
      let(:mapper) { PennMARC::Enriched::Pub }
      let(:subfields) do
        { mapper::HOLDING_CLASSIFICATION_PART => 'AB123',
          mapper::HOLDING_ITEM_PART => '.4',
          mapper::PHYS_HOLDING_ID => '123456789',
          mapper::PHYS_LOCATION_CODE => 'vanpelt',
          mapper::PHYS_LOCATION_NAME => 'Van Pelt Library' }
      end

      it 'returns expected array of hash values' do
        expect(helper.physical(record)).to contain_exactly(
          { call_num: 'AB123.4', holding_id: '123456789', location_code: 'vanpelt',
            location_name: 'Van Pelt Library', priority: nil }
        )
      end
    end
  end

  describe 'electronic' do
    let(:fields) do
      [marc_field(tag: mapper::ELEC_INVENTORY_TAG,
                  subfields: subfields)]
    end
    let(:subfields) do
      { mapper::ELEC_PORTFOLIO_ID => '234567890',
        mapper::ELEC_SERVICE_URL => 'https://www.iwish.com',
        mapper::ELEC_COLLECTION_NAME => 'All Articles Repo',
        mapper::ELEC_COVERAGE_STMT => 'All time',
        mapper::ELEC_PUBLIC_NOTE => 'Portfolio public note' }
    end

    context 'with API enrichment fields' do
      let(:mapper) { PennMARC::Enriched::Api }

      it 'returns expected array of hash values' do
        expect(helper.electronic(record)).to contain_exactly(
          { portfolio_id: '234567890', url: 'https://www.iwish.com', collection_name: 'All Articles Repo',
            coverage: 'All time', note: 'Portfolio public note' }
        )
      end
    end

    context 'with Pub enrichment fields' do
      let(:mapper) { PennMARC::Enriched::Pub }

      it 'returns expected array of hash values' do
        expect(helper.electronic(record)).to contain_exactly(
          { portfolio_id: '234567890', url: 'https://www.iwish.com', collection_name: 'All Articles Repo',
            coverage: 'All time', note: 'Portfolio public note' }
        )
      end
    end
  end

  describe 'electronic_portfolio_count' do
    let(:fields) { [marc_field(tag: inventory_tag), marc_field(tag: inventory_tag)] }

    context 'with API enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Api::ELEC_INVENTORY_TAG }

      it 'returns the correct count' do
        expect(helper.electronic_portfolio_count(record)).to eq 2
      end
    end

    context 'with Pub enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Pub::ELEC_INVENTORY_TAG }

      it 'returns the correct count' do
        expect(helper.electronic_portfolio_count(record)).to eq 2
      end
    end
  end

  describe 'physical_holding_count' do
    let(:fields) { [marc_field(tag: inventory_tag), marc_field(tag: inventory_tag)] }

    context 'with API enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Api::PHYS_INVENTORY_TAG }

      it 'returns the correct count' do
        expect(helper.physical_holding_count(record)).to eq 2
      end
    end

    context 'with Pub enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG }

      it 'returns the correct count' do
        expect(helper.physical_holding_count(record)).to eq 2
      end
    end
  end
end
