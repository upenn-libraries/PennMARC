# frozen_string_literal: true

describe 'PennMARC::Access' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Access }

  describe '.facet' do
    context 'with an electronic record' do
      let(:record) { marc_record fields: [marc_field(tag: tag)] }

      context 'with enrichment via the Alma publishing process' do
        let(:tag) { PennMARC::Enriched::Pub::ELEC_INVENTORY_TAG }

        it 'returns expected access value' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::ONLINE)
        end
      end

      context 'with enrichment with availability info via the Alma API' do
        let(:tag) { PennMARC::Enriched::Api::ELEC_INVENTORY_TAG }

        it 'returns expected access value' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::ONLINE)
        end
      end
    end

    context 'with a print record' do
      let(:record) { marc_record fields: [marc_field(tag: tag)] }

      context 'with enrichment via the Alma publishing process' do
        let(:tag) { PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG }

        it 'returns expected access value' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::AT_THE_LIBRARY)
        end
      end

      context 'with enrichment with availability info via the Alma API' do
        let(:tag) { PennMARC::Enriched::Api::PHYS_INVENTORY_TAG }

        it 'returns expected access value' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::AT_THE_LIBRARY)
        end
      end
    end

    context 'with a record containing a link to a finding aid (as a handle link)' do
      let(:record) do
        marc_record fields: [marc_field(tag: PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG),
                             marc_field(tag: '856', subfields: location_and_access_subfields, **indicators)]
      end

      context 'with an 856 describing a related record, not the record itself' do
        let(:indicators) { { indicator1: '4', indicator2: '2' } }
        let(:location_and_access_subfields) do
          { z: 'Finding Aid', u: 'http://hdl.library.upenn.edu/1017/d/pacscl/UPENN_RBML_MsColl200' }
        end

        it 'does not include online access' do
          expect(helper.facet(record)).not_to include PennMARC::Access::ONLINE
        end
      end

      context 'with an 865 describing a link to a finding aid' do
        let(:indicators) { { indicator1: '4', indicator2: '1' } }
        let(:location_and_access_subfields) do
          { z: 'Finding aid', u: 'http://hdl.library.upenn.edu/1017/d/pacscl/UPENN_RBML_MsColl200' }
        end

        it 'does not include online access' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::AT_THE_LIBRARY)
        end
      end

      context 'with an 856 describing a resource link' do
        let(:indicators) { { indicator1: '4', indicator2: '1' } }
        let(:location_and_access_subfields) do
          { z: 'Connect to resource', u: 'http://hdl.library.upenn.edu/1234' }
        end

        it 'includes online access' do
          expect(helper.facet(record)).to contain_exactly(PennMARC::Access::ONLINE, PennMARC::Access::AT_THE_LIBRARY)
        end
      end
    end
  end
end
