# frozen_string_literal: true

describe 'PennMARC::Date' do
  let(:helper) { PennMARC::Date }
  let(:record) { marc_record fields: fields }

  describe '.publication' do
    let(:fields) { [marc_control_field(tag: '008', value: '130827s2010 nyu o 000 1 eng d')] }

    it 'returns publication date' do
      expect(helper.publication(record)).to eq(Time.new(2010))
    end

    it 'returns a year value' do
      expect(helper.publication(record).year).to eq(2010)
    end

    context 'with invalid date' do
      let(:fields) { [marc_control_field(tag: '008', value: 'invalid date')] }

      it 'returns nil' do
        expect(helper.publication(record)).to be_nil
      end
    end
  end

  describe '.added' do
    context 'with a robust itm tag' do
      let(:fields) do
        [marc_field(tag: 'itm', subfields: { g: 'VanPeltLib', i: 'Tw .156', q: '2023-10-19' })]
      end

      it 'returns only the expected date_added value' do
        expect(helper.added(record)).to eq Time.strptime('2023-10-19', '%Y-%m-%d')
      end

      it 'does not output any warning to STDOUT' do
        expect {
          helper.added(record)
        }.not_to output(a_string_including('Error parsing date in date added subfield')).to_stdout
      end
    end

    context "with date formatted '%Y-%m-%d'" do
      let(:fields) { [marc_field(tag: 'itm', subfields: { q: '2023-06-28' })] }

      it 'returns expected value' do
        expect(helper.added(record)).to eq(Time.strptime('2023-06-28', '%Y-%m-%d'))
      end

      it 'returns a year value' do
        expect(helper.added(record).year).to eq(2023)
      end
    end

    context "with date formatted '%Y-%m-%d %H:%M:%S'" do
      let(:fields) { [marc_field(tag: 'itm', subfields: { q: '2023-06-29 11:04:30:10' })] }

      it 'returns expected value' do
        expect(helper.added(record)).to eq(Time.strptime('2023-06-29 11:04:30:10', '%Y-%m-%d %H:%M:%S'))
      end

      it 'returns a year value' do
        expect(helper.added(record).year).to eq(2023)
      end
    end

    context 'with multiple date added values' do
      let(:fields) do
        [marc_field(tag: 'itm', subfields: { q: '2023-06-28' }),
         marc_field(tag: 'itm', subfields: { q: '2023-06-29' })]
      end

      it 'returns most recent date' do
        expect(helper.added(record)).to eq(Time.strptime('2023-06-29', '%Y-%m-%d'))
      end
    end

    context 'with invalid date' do
      let(:fields) do
        [marc_control_field(tag: '001', value: 'mmsid'),
         marc_field(tag: 'itm', subfields: { q: 'invalid date' })]
      end

      it 'returns nil' do
        expect(helper.added(record)).to be_nil
      end

      it 'outputs error message' do
        expect {
          helper.added(record)
        }.to output('Error parsing date in date added subfield. mmsid: mmsid, value: invalid date, ' \
                    "error: invalid date or strptime format - `invalid date' `%Y-%m-%d %H:%M:%S'\n").to_stdout
      end
    end
  end

  describe '.last_updated' do
    let(:fields) { [marc_field(tag: '005', subfields: { q: '20230213163851.1' })] }

    it 'returns date last updated' do
      expect(helper.last_updated(record)).to eq(Time.strptime('20230213163851.1', '%Y%m%d%H%M%S.%N'))
    end

    it 'returns year value' do
      expect(helper.last_updated(record).year).to eq(2023)
    end

    context 'with invalid date' do
      let(:fields) do
        [marc_control_field(tag: '001', value: 'mmsid'),
         marc_field(tag: '005', subfields: { q: 'invalid date' })]
      end

      it 'returns nil' do
        expect(helper.last_updated(record)).to be_nil
      end

      it 'outputs error message' do
        expect {
          helper.last_updated(record)
        }.to output('Error parsing last updated date. mmsid: mmsid, value: invalid date, ' \
                    "error: invalid date or strptime format - `invalid date' `%Y%m%d%H%M%S.%N'\n").to_stdout
      end
    end
  end
end
