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
        marc_field(tag: '020', subfields: { a: '9781594205071', z: '1555975275' }),
        marc_field(tag: '022', subfields: { a: '0008-6533', l: '0300-7162', z: '0799-5946 ' })
      ]
    end

    it 'returns expected search values' do
      expect(helper.isxn_search(record)).to contain_exactly('9781594205071', '1555975275', '9781555975272',
                                                            '1594205078', '0300-7162', '0008-6533', '0799-5946 ')
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

    it 'returns expected ǂa values' do
      expect(helper.isbn_show(record)).to contain_exactly('9781594205071', '0805073698',
                                                          '0735222789')
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

    it 'returns ǂa values' do
      expect(helper.issn_show(record)).to contain_exactly('0008-6533', '2470-6302',
                                                          '1080-6512')
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
        marc_field(tag: '024', subfields: { a: '10.18574/9781479842865', '2': 'doi' }),
        marc_field(tag: '028', subfields: { a: 'B002086600', b: 'Island Def Jam Music Group', '6': '880-01' }),
        marc_field(tag: '880', subfields: { a: '523458735206', '6': '024' }),
        marc_field(tag: '880', subfields: { a: '006680200B', b: 'Island', '6': '028' }),
        marc_field(tag: '880', subfields: { a: '006680200B', b: 'Island', '6': '021' })
      ]
    end

    it 'returns expected show values' do
      expect(helper.publisher_number_show(record)).to contain_exactly('602537854325',
                                                                      'B002086600 Island Def Jam Music Group',
                                                                      '523458735206', '006680200B Island')
    end

    it 'does not return DOI values' do
      expect(helper.publisher_number_show(record)).not_to include('10.18574/9781479842865')
      expect(helper.publisher_number_show(record)).not_to include('doi')

    end
  end

  describe '.publisher_number_search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '024', subfields: { a: '602537854325', b: 'exclude' }),
        marc_field(tag: '024', subfields: { a: '10.18574/9781479842865', '2': 'doi' }),
        marc_field(tag: '028', subfields: { a: 'B002086600', b: 'Island Def Jam Music Group' })
      ]
    end

    it 'returns publisher numbers from 024/028 ǂa and DOI values in 024 ǂ2' do
      expect(helper.publisher_number_search(record)).to contain_exactly('10.18574/9781479842865', '602537854325',
                                                                        'B002086600')
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

  describe '.doi_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '024', indicator1: '7', subfields: { a: '10.1038/sdata.2016.18 ', '2': 'doi' }),
        marc_field(tag: '024', indicator1: '7', subfields: { a: '10.18574/9781479842865', '2': 'doi' }),
        marc_field(tag: '024', indicator1: '7',
                   subfields: { a: '10.1016.12.31/nature.S0735-1097(98)2000/12?/31/34:7-7', '2': 'doi' }),
        marc_field(tag: '024', indicator1: '7', subfields: { a: 'excluded', '2': 'non doi' }),
        marc_field(tag: '024', indicator1: '0', subfields: { a: 'excluded', '2': 'doi' })
      ]
    end

    it 'returns valid DOI values' do
      expect(helper.doi_show(record)).to contain_exactly('10.1016.12.31/nature.S0735-1097(98)2000/12?/31/34:7-7',
                                                         '10.1038/sdata.2016.18', '10.18574/9781479842865')
    end
  end
end