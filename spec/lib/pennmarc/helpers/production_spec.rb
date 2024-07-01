# frozen_string_literal: true

describe 'PennMARC::Production' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Production }

  describe '.show' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [
        marc_field(tag: '264', subfields: { a: 'Marabella, Trinidad, West Indies',
                                            b: 'Queen Bishop Productions Limited',
                                            c: '2016' }, indicator2: '0'),
        marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Productions', c: '2019' }, indicator2: '0'),
        marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1'),
        marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Productions', c: '880', '6': '264' },
                   indicator2: '0')
      ]
    end

    let(:values) { helper.show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly(
        'Marabella, Trinidad, West Indies Queen Bishop Productions Limited 2016',
        'Leeds Peepal Tree Productions 2019',
        'Linked Alternate Productions 880'
      )
    end
  end

  describe '.distribution_show' do
    let(:record) { marc_record fields: fields }
    let(:fields) do
      [
        marc_field(tag: '264', subfields: { a: 'Marabella, Trinidad, West Indies',
                                            b: 'Queen Bishop Distributors Limited',
                                            c: '2016' }, indicator2: '2'),
        marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Distributors', c: '2019' }, indicator2: '2'),
        marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1'),
        marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Distributors', c: '880', '6': '264' },
                   indicator2: '2')
      ]
    end
    let(:values) { helper.distribution_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly(
        'Marabella, Trinidad, West Indies Queen Bishop Distributors Limited 2016',
        'Leeds Peepal Tree Distributors 2019',
        'Linked Alternate Distributors 880'
      )
    end
  end

  describe '.manufacture_show' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [
        marc_field(tag: '264', subfields: { a: 'Marabella, Trinidad, West Indies',
                                            b: 'Queen Bishop Manufacturers Limited',
                                            c: '2016' }, indicator2: '3'),
        marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Manufacturers', c: '2019' }, indicator2: '3'),
        marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1'),
        marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Manufacturers', c: '880', '6': '264' },
                   indicator2: '3')
      ]
    end

    let(:values) { helper.manufacture_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly(
        'Marabella, Trinidad, West Indies Queen Bishop Manufacturers Limited 2016',
        'Leeds Peepal Tree Manufacturers 2019',
        'Linked Alternate Manufacturers 880'
      )
    end
  end

  describe '.publication_values' do
    context 'with date in 245 ǂf' do
      let(:record) { marc_record fields: fields }

      let(:fields) do
        [
          marc_field(tag: '245', subfields: { f: '1869-1941' }),
          marc_field(tag: '264', subfields: { a: 'Marabella, Trinidad, West Indies',
                                              b: 'Queen Bishop Publishing Limited',
                                              c: '1920' }, indicator2: '1')
        ]
      end

      let(:values) { helper.publication_values(record) }

      it 'returns expected values' do
        expect(values).to contain_exactly('1869-1941',
                                          'Marabella, Trinidad, West Indies Queen Bishop Publishing Limited 1920')
      end
    end

    context 'with 260, 261, or 262 fields' do
      let(:record) { marc_record fields: fields }

      let(:fields) do
        [
          marc_field(tag: '260', subfields: { a: ' Burnt Mill, Harlow, Essex, England', b: 'Longman',
                                              c: '1985, c1956.' }),
          marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishers', c: '1999' }, indicator2: '1')
        ]
      end

      let(:values) { helper.publication_values(record) }

      it 'returns expected values' do
        expect(values).to contain_exactly('Burnt Mill, Harlow, Essex, England Longman 1985, c1956.')
      end
    end

    context 'without 260, 261, or 262 fields' do
      let(:record) { marc_record fields: fields }

      let(:fields) do
        [
          marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishers', c: '1999' }, indicator2: '1'),
          marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Productions', c: '2019' }, indicator2: '0'),
          marc_field(tag: '264', subfields: { c: ' c2016' }, indicator2: '4')
        ]
      end

      let(:values) { helper.publication_values(record) }

      it 'returns publication values from field 264' do
        expect(values).to contain_exactly('Nowhere Wasteland Publishers 1999 ,  c2016')
      end
    end
  end

  describe '.publication_show' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [marc_field(tag: '245', subfields: { f: 'between 1800-1850' }),
       marc_field(tag: '260', subfields: { a: ' Burnt Mill, Harlow, Essex, England', b: 'Longman',
                                           c: '1985, c1956.' }),
       marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Press', c: '2019' }, indicator2: '1'),
       marc_field(tag: '880', subfields: { f: 'Alternate 1800-1850', '6': '245' }),
       marc_field(tag: '880',
                  subfields: { a: 'Alternate England', b: 'Alternate Longman', c: 'Alternate 1985, c1956.',
                               '6': '260' }),
       marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Publishers', c: '880', '6': '264' },
                  indicator2: '1')]
    end

    let(:values) { helper.publication_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly('between 1800-1850',
                                        'Burnt Mill, Harlow, Essex, England Longman 1985, c1956.',
                                        'Leeds Peepal Tree Press 2019',
                                        'Alternate 1800-1850',
                                        'Alternate England Alternate Longman Alternate 1985, c1956.',
                                        'Linked Alternate Publishers 880')
    end
  end

  describe '.publication_citation_show' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [marc_field(tag: '245', subfields: { f: 'between 1800-1850' }),
       marc_field(tag: '260', subfields: { a: ' Burnt Mill, Harlow, Essex, England', b: 'Longman',
                                           c: '1985, c1956.' }),
       marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Press', c: '2019' }, indicator2: '1'),
       marc_field(tag: '880', subfields: { f: 'Alternate 1800-1850', '6': '245' }),
       marc_field(tag: '880',
                  subfields: { a: 'Alternate England', b: 'Alternate Longman', c: 'Alternate 1985, c1956.',
                               '6': '260' }),
       marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Publishers', c: '880', '6': '264' },
                  indicator2: '1')]
    end

    let(:values) { helper.publication_citation_show(record) }
    let(:values_no_year) { helper.publication_citation_show(record, with_year: false) }

    it 'returns publication citation values' do
      expect(values).to contain_exactly('between 1800-1850',
                                        'Burnt Mill, Harlow, Essex, England Longman 1985, c1956.',
                                        'Leeds Peepal Tree Press 2019')
    end

    it 'returns publication citation values without year' do
      expect(values_no_year).to contain_exactly('between 1800-1850',
                                                'Burnt Mill, Harlow, Essex, England Longman',
                                                'Leeds Peepal Tree Press')
    end
  end

  describe 'place_of_publication_show' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [marc_field(tag: '752', subfields: { a: 'United States', b: 'California', c: 'Los Angeles (County)',
                                           d: 'Los Angeles', e: 'publication place', f: 'Little Tokyo',
                                           g: 'North America',  h: 'Earth' }),
       marc_field(tag: '880', subfields: { a: 'US', b: 'Cali',
                                           c: 'LA (County)', d: 'LA',
                                           e: 'Alt publication place',
                                           f: 'Alt Tokyo', g: 'NA',
                                           h: 'Alt Earth', '6': '752' })]
    end

    let(:values) { helper.place_of_publication_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly(
        'United States California Los Angeles (County) Los Angeles Little Tokyo North America Earth publication place',
        'US Cali LA (County) LA Alt Tokyo NA Alt Earth Alt publication place'
      )
    end
  end

  describe 'publication_ris_place_of_pub' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [marc_field(tag: '245', subfields: { f: 'between 1800-1850' }),
       marc_field(tag: '260', subfields: { a: ' Burnt Mill, Harlow, Essex, England', b: 'Longman',
                                           c: '1985, c1956.' }),
       marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Press', c: '2019' }, indicator2: '1'),
       marc_field(tag: '880', subfields: { f: 'Alternate 1800-1850', '6': '245' }),
       marc_field(tag: '880',
                  subfields: { a: 'Alternate England', b: 'Alternate Longman', c: 'Alternate 1985, c1956.',
                               '6': '260' }),
       marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Publishers', c: '880', '6': '264' },
                  indicator2: '1')]
    end

    let(:values) { helper.publication_ris_place_of_pub(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly('between 1800-1850', 'Burnt Mill, Harlow, Essex, England', 'Leeds')
    end
  end

  describe 'publication_ris_publisher' do
    let(:record) { marc_record fields: fields }

    let(:fields) do
      [marc_field(tag: '245', subfields: { f: 'between 1800-1850' }),
       marc_field(tag: '260', subfields: { a: ' Burnt Mill, Harlow, Essex, England', b: 'Longman',
                                           c: '1985, c1956.' }),
       marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Press', c: '2019' }, indicator2: '1'),
       marc_field(tag: '880', subfields: { f: 'Alternate 1800-1850', '6': '245' }),
       marc_field(tag: '880',
                  subfields: { a: 'Alternate England', b: 'Alternate Longman', c: 'Alternate 1985, c1956.',
                               '6': '260' }),
       marc_field(tag: '880', subfields: { a: 'Linked', b: 'Alternate Publishers', c: '880', '6': '264' },
                  indicator2: '1')]
    end

    let(:values) { helper.publication_ris_publisher(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly('between 1800-1850', 'Longman', 'Peepal Tree Press')
    end
  end
end
