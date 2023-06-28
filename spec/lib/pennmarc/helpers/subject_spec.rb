# frozen_string_literal: true

describe 'PennMARC::Subject' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Subject }
  let(:relator_map) do
    {}
  end

  describe '.search' do
    context 'with a mix of included and excluded tags' do
      let(:record) do
        marc_record fields: [
          marc_field(tag: '600', indicator2: '5', subfields: { a: 'Excluded Canadian' }),
          marc_field(tag: '610', indicator2: '0', subfields: { a: 'University of Pennsylvania', b: 'Libraries' }),
          marc_field(tag: '691', indicator2: '7', subfields: { a: 'Van Pelt Library', '2': 'local' }),
          marc_field(tag: '696', indicator2: '4', subfields: { a: 'A Developer' }),
          marc_field(tag: '880', indicator2: '0', subfields: { a: 'Alt. Name', '6': '610' })
        ]
      end

      it 'does expected stuff' do
        values = helper.search(record, relator_map)
        expect(values).to contain_exactly 'A Developer', 'Alt. Name', 'University of Pennsylvania Libraries',
                                          'Van Pelt Library local'
        expect(values).not_to include 'Excluded Canadian'
      end
    end
  end

  describe '.show' do

  end

  describe '.facet' do

  end

  describe '.childrens_show' do

  end

  describe '.medical_show' do

  end

  describe '.local_show' do

  end
end
