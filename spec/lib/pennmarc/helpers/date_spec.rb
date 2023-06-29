# frozen_string_literal: true

describe 'PennMarc::Date' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Date }
  let(:record) { marc_record fields: fields }

  describe '.publication' do
    let(:fields) { [marc_control_field(tag: '008', value: '130827s2010 nyu o 000 1 eng d')] }

    it 'returns publication date' do
      expect(helper.publication(record)).to eq(DateTime.iso8601('2010'))
    end

    context 'with invalid date' do
      let(:fields) { [marc_control_field(tag: '008', value: 'invalid date')] }

      it 'returns nil' do
        expect(helper.publication(record)).to be_nil
      end
    end
  end

  describe '.added' do
    context "with date formatted '%Y-%m-%d' " do
      let(:fields) { [marc_field(tag: 'itm', subfields: { q: '2023-06-28' })] }

      it 'returns expected value' do
        expect(helper.added(record)).to eq(DateTime.strptime('2023-06-28', '%Y-%m-%d'))
      end
    end

    context "with date formatted '%Y-%m-%d %H:%M:%S'" do
      let(:fields) { [marc_field(tag: 'itm', subfields: { q: '2023-06-29 11:04:30:10' })] }

      it 'returns expected value' do
        expect(helper.added(record)).to eq(DateTime.strptime('2023-06-29 11:04:30:10', '%Y-%m-%d %H:%M:%S'))
      end
    end

    context 'with multiple date added values' do
      let(:fields) do
        [marc_field(tag: 'itm', subfields: { q: '2023-06-28' }),
         marc_field(tag: 'itm', subfields: { q: '2023-06-29' })]
      end

      it 'returns most recent date' do
        expect(helper.added(record)).to eq(DateTime.strptime('2023-06-29', '%Y-%m-%d'))
      end
    end

    context 'with invalid date' do
      let(:fields) { [marc_field(tag: 'itm', subfields: { q: 'invalid date' })] }

      it 'returns nil' do
        expect(helper.added(record)).to be_nil
      end

      it 'outputs error message' do
        expect do
          helper.added(record)
        end.to output("Error parsing date in date added subfield: invalid date - invalid date\n").to_stdout
      end
    end
  end

  describe '.last_updated' do
    let(:fields) { [marc_field(tag: '005', subfields: { q: '20230213163851.0' })] }

    it 'returns date last updated' do
      expect(helper.last_updated(record)).to eq(DateTime.iso8601('20230213163851.0'))
    end

    context 'with invalid date' do
      let(:fields) { [marc_field(tag: '005', subfields: { q: 'invalid date' })] }

      it 'returns nil' do
        expect(helper.last_updated(record)).to be_nil
      end

      it 'outputs error message' do
        expect do
          helper.last_updated(record)
        end.to output("Error parsing last updated date: invalid date - invalid date\n").to_stdout
      end
    end
  end
end
