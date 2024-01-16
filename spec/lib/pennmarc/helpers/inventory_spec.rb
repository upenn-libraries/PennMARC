# frozen_string_literal: true

describe 'PennMARC::Inventory' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Inventory }
  let(:record) { marc_record fields: fields }

  describe 'physical' do
    let(:fields) do
      [marc_field(tag: inventory_tag, subfields: {}),
       marc_field(tag: inventory_tag, subfields: {})]
    end

    context 'with API enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Api::PHYS_INVENTORY_TAG }

      it 'returns expected array of hash values' do
        expect(helper.physical(record)).to contain_exactly({}, {})
      end
    end

    context 'with Pub enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG }

      it 'returns expected array of hash values' do
        expect(helper.physical(record)).to contain_exactly({}, {})
      end
    end
  end

  describe 'electronic' do
    let(:fields) do
      [marc_field(tag: inventory_tag, subfields: {}),
       marc_field(tag: inventory_tag, subfields: {})]
    end

    context 'with API enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Api::ELEC_INVENTORY_TAG }

      it 'returns expected array of hash values' do
        expect(helper.electronic(record)).to contain_exactly({}, {})
      end
    end

    context 'with Pub enrichment fields' do
      let(:inventory_tag) { PennMARC::Enriched::Pub::ELEC_INVENTORY_TAG }

      it 'returns expected array of hash values' do
        expect(helper.electronic(record)).to contain_exactly({}, {})
      end
    end
  end

  describe 'electronic_portfolio_count' do
    let(:fields) do
      [marc_field(tag: inventory_tag, subfields: {}),
       marc_field(tag: inventory_tag, subfields: {})]
    end

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
    let(:fields) do
      [marc_field(tag: inventory_tag, subfields: {}),
       marc_field(tag: inventory_tag, subfields: {})]
    end

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
