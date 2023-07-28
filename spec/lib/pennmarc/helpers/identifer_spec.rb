# frozen_string_literal: true

describe 'PennMARC::Identifier' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Identifier }

  describe '.mmsid' do
    let(:record) { marc_record fields: [marc_control_field(tag: '001', value: '9977233551603681')] }

    it 'returns expected value' do
      expect(helper.mmsid(record)).to eq('9977233551603681')
    end
  end

  describe '.isxn_search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '020', subfields: { a: '9781594205071', z: '1594205078' }),
        marc_field(tag: '022', subfields: { a: '0008-6533', l: '0300-7162', z: '0008-6533' })
      ]
    end

    it 'returns expected search values' do
      expect(helper.isxn_search(record)).to contain_exactly('9781594205071', '1594205078', '0300-7162', '0008-6533')
    end

    it 'converts ISBN10 values to ISBN13' do
      record = marc_record fields: [marc_field(tag: '020', subfields: { a: '0805073698' })]
      expect(helper.isxn_search(record)).to contain_exactly('9780805073690', '0805073698')
    end
  end

  describe '.isbn_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '020', subfields: { a: '9781594205071', z: '1594205078' }),
        marc_field(tag: '020', subfields: { a: '0805073698', z: '9780735222786' }),
        marc_field(tag: '880', subfields: { a: '0735222789', z: '9780805073690', '6': '020' })
      ]
    end

    it 'returns expected show values' do
      expect(helper.isbn_show(record)).to contain_exactly('9781594205071 1594205078', '0805073698 9780735222786',
                                                          '0735222789 9780805073690')
    end
  end

  describe '.issn_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '022', subfields: { a: '0008-6533', z: '0008-6533' }),
        marc_field(tag: '022', subfields: { a: '2470-6302', z: '1534-6714' }),
        marc_field(tag: '880', subfields: { a: '1080-6512', z: '2213-4360', '6': '022' })
      ]
    end

    it 'returns expected show values' do
      expect(helper.issn_show(record)).to contain_exactly('0008-6533 0008-6533', '2470-6302 1534-6714',
                                                          '1080-6512 2213-4360')
    end
  end

  describe '.oclc_id' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '035', subfields: { a: '(PU)4422776-penndb-Voyager' }),
        marc_field(tag: '035', subfields: { a: '(OCoLC)ocn610094484' }),
        marc_field(tag: '035', subfields: { a: '(OCoLC)1483169584' })
      ]
    end

    it 'returns expected show values' do
      expect(helper.oclc_id(record)).to contain_exactly('610094484')
    end
  end

  describe '.publisher_number_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '024', subfields: { a: '602537854325', '6': '880-01' }),
        marc_field(tag: '028', subfields: { a: 'B002086600', b: 'Island Def Jam Music Group', '6': '880-01' }),
        marc_field(tag: '880', subfields: { a: '523458735206', '6': '024' }),
        marc_field(tag: '880', subfields: { a: '006680200B', b: 'Island', '6': '028' })
      ]
    end

    it 'returns expected show values' do
      expect(helper.publisher_number_show(record)).to contain_exactly('602537854325',
                                                                      'B002086600 Island Def Jam Music Group',
                                                                      '523458735206', '006680200B Island')
    end
  end

  describe '.publisher_number_search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '024', subfields: { a: '602537854325' }),
        marc_field(tag: '028', subfields: { a: 'B002086600', b: 'Island Def Jam Music Group' })
      ]
    end

    it 'returns expected search values' do
      expect(helper.publisher_number_search(record)).to contain_exactly('602537854325', 'B002086600')
    end
  end

  describe '.fingerprint_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '026', subfields: { a: 'dete nkck', b: 'vess lodo', c: 'Anno Domini MDCXXXVI', d: '3',
                                            '2': 'fei', '5': 'penn' })
      ]
    end

    it 'returns expected fingerprint values' do
      expect(helper.fingerprint_show(record)).to contain_exactly('dete nkck vess lodo Anno Domini MDCXXXVI 3')
    end
  end
end
