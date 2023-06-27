# frozen_string_literal: true

describe 'PennMARC::Database' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Database }
  let(:record) do
    marc_record(fields: [
                  marc_field(tag: '943', subfields: { a: 'Humanities', '2': 'penncoi' }),
                  marc_field(tag: '943', subfields: { a: 'Social Sciences', b: 'Linguistics', '2': 'penncoi' }),
                  marc_field(tag: '944',
                             subfields: { a: 'Database & Article Index',
                                          b: 'Dictionaries and Thesauri (language based)' }),
                  marc_field(tag: '944', subfields: { a: 'Database & Article Index', b: ['Reference and Handbooks'] })
                ])
  end
  let(:record_uncurated_db) do
    marc_record(fields: [
                  marc_field(tag: '943', subfields: { a: 'Social Sciences', b: 'Linguistics', '2': 'penncoi' }),
                  marc_field(tag: '944', subfields: { a: 'Uncurated Database', b: 'Reference and Handbooks' })
                ])
  end

  describe '.type' do
    it 'returns database types' do
      expect(helper.type(record)).to contain_exactly('Dictionaries and Thesauri (language based)',
                                                     'Reference and Handbooks')
    end

    context 'with uncurated database' do
      it 'returns empty array' do
        expect(helper.type(record_uncurated_db)).to be_empty
      end
    end
  end

  describe '.db_category' do
    it 'returns database categories' do
      expect(helper.db_category(record)).to contain_exactly('Humanities', 'Social Sciences')
    end

    context 'with uncurated database' do
      it 'returns empty array' do
        expect(helper.db_category(record_uncurated_db)).to be_empty
      end
    end
  end

  describe '.db_subcategory' do
    it 'returns database subcategories' do
      expect(helper.db_subcategory(record)).to contain_exactly('Social Sciences--Linguistics')
    end

    context 'with uncurated database' do
      it 'returns empty array' do
        expect(helper.db_subcategory(record_uncurated_db)).to be_empty
      end
    end
  end
end
