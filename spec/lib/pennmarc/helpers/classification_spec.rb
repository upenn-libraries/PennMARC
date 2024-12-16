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
    let(:fields) { [marc_field(tag: tag, subfields: subfields)] }

    context 'with a straightforward LC call number' do
      let(:tag) { '050' }
      let(:subfields) { { a: 'Q175', b: ' .K95' } }

      it 'produces a normalized call number' do
        expect(helper.sort(record)).to eq ['Q..0175.K95']
      end
    end

    context 'with a slightly less straightforward call number' do
      let(:tag) { '050' }
      let(:subfields) { { a: 'SB320.8.N45', b: ' L43 1984', '1': 'http://URI' } }

      it 'produces a normalized call number' do
        expect(helper.sort(record)).to eq ['SB.03208.N45.L43--1984']
      end

      it 'does not include values form undesirable subfields' do
        expect(helper.sort(record).first).not_to include 'URI'
      end
    end

    # TODO: would we ever find a Dewey number in 050? probably not
    context 'with a Dewey call number' do
      let(:tag) { '050' }
      let(:subfields) { { a: '629.41 T939' } }

      it 'produces a normalized call number' do
        expect(helper.sort(record)).to eq []
      end
    end

    context 'with nonsense in the 050 field' do
      let(:tag) { '050' }
      let(:subfields) { { a: '123 foo bar baz', b: 'quux 1792' } }

      it 'produces a normalized call number' do
        expect(helper.sort(record)).to eq []
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
