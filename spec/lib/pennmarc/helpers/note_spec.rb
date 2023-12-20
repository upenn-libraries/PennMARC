# frozen_string_literal: true

describe 'PennMARC::Note' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Note }

  describe '.notes_show' do
    let(:record) { marc_record(fields: fields) }
    let(:fields) do
      [
        marc_field(tag: '500',
                   subfields: { a: 'Gift of R. Winthrop, 1883', '3': 'Abstracts', '4': 'From Winthrop papers' }),
        marc_field(tag: '502', subfields: { b: 'PhD', c: 'University of Pennsylvania', d: '2021' }),
        marc_field(tag: '504', subfields: { a: 'Includes bibliographical references (pages 329-[342]) and index.' }),
        marc_field(tag: '533',
                   subfields: { '3': 'Archives', '5': 'LoC', a: 'Microfilm',
                                b: 'UK', c: 'Historical Association',
                                d: '1917', e: '434 reels',
                                f: '(Seized records)' }),
        marc_field(tag: '540', subfields: { a: 'Restricted: Copying allowed only for nonprofit organizations' }),
        marc_field(tag: '588', subfields: { a: 'Print version record', '5': 'LoC' }),
        marc_field(tag: '880', subfields: { b: 'Alt PhD', c: 'Alt UPenn', d: 'Alt 2021', '6': '502' }),
        marc_field(tag: '880', subfields: { b: 'Ignore Note', '6': '501' })

      ]
    end

    let(:values) { helper.notes_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly('Gift of R. Winthrop, 1883 Abstracts From Winthrop papers',
                                        'PhD University of Pennsylvania 2021',
                                        'Includes bibliographical references (pages 329-[342]) and index.',
                                        'Archives Microfilm UK Historical Association 1917 434 reels (Seized records)',
                                        'Restricted: Copying allowed only for nonprofit organizations',
                                        'Print version record', 'Alt PhD Alt UPenn Alt 2021')
    end
  end

  describe '.local_notes_show' do
    let(:record) { marc_record(fields: fields) }
    let(:fields) do
      [
        marc_field(tag: '561', subfields: { a: 'Athenaeum copy: ', u: 'No URI' }),
        marc_field(tag: '561', subfields: { a: 'Ignored' }),
        marc_field(tag: '562', subfields: { a: 'Torn cover', b: 'desk copy', c: '3rd edition',
                                            d: 'intended for reading',
                                            e: '2 copies',
                                            '3': 'parchment',
                                            '5': 'LoC' }),
        marc_field(tag: '590', subfields: { a: 'local note', '3': 'local paper' }),
        marc_field(tag: '880', subfields: { a: 'alt cover', b: 'alt copy', c: 'alt edition',
                                            d: 'alt presentation', e: 'alt number of copies',
                                            '3': 'alt materials',
                                            '5': 'LoC', '6': '562' }),
        marc_field(tag: '880', subfields: { a: 'alt note', '3': 'alt paper', '6': '590' })
      ]
    end

    let(:values) { helper.local_notes_show(record) }

    it 'returns expected values' do
      expect(values).to contain_exactly(
        'Athenaeum copy:',
        'Torn cover desk copy 3rd edition intended for reading 2 copies parchment',
        'local note local paper',
        'alt cover alt copy alt edition alt presentation alt number of copies alt materials',
        'alt note alt paper'
      )
    end

    it 'ignores non Athenaeum copies' do
      expect(values).not_to include('Ignored')
    end
  end

  describe '.provenance_show' do
    let(:record) { marc_record(fields: fields) }
    let(:fields) do
      [
        marc_field(tag: '561', subfields: { a: 'Not Athenaeum copy: ', u: 'No URI' }, indicator1: '1', indicator2: ' '),
        marc_field(tag: '561', subfields: { a: 'Ignore', u: 'No URI' }, indicator1: 'Wrong Indicator'),
        marc_field(tag: '561', subfields: { a: 'Ignore', u: 'No URI' }, indicator2: 'Wrong Indicator'),
        marc_field(tag: '561', subfields: { a: 'Athenaeum copy: ', u: 'No URI' }),
        marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Heading' }),
        marc_field(tag: '650', indicator2: '4', subfields: { a: 'Regular Local Heading' }),
        marc_field(tag: '650', indicator2: '1', subfields: { a: 'LoC Heading' }),
        marc_field(tag: '880', indicator2: '4', subfields: { '6': '650', a: 'PRO Alt Heading' }),
        marc_field(tag: '880', indicator2: '4', subfields: { '6': '650', a: 'Alt LoC Heading' }),
        marc_field(tag: '880', subfields: { a: 'Alt Provenance', u: 'Alt URI', '6': '561' })
      ]
    end

    let(:values) { helper.provenance_show(record) }

    it 'returns expected data from 561, 650, and linked alternates, removing PRO prefix and ignoring Athenaeum copy' do
      expect(values).to contain_exactly('Not Athenaeum copy:', 'Heading', 'Alt Provenance', 'Alt Heading')
    end
  end

  describe '.contents_show' do
    let(:record) { marc_record(fields: fields) }
    let(:fields) do
      [
        marc_field(tag: '505', subfields: { a: 'Formatted content notes', g: 'Misc Info', r: 'Responsible Agent',
                                            t: 'A Title', u: 'URI' }),
        marc_field(tag: '880', subfields: { a: 'Alt Formatted content notes', g: ' Alt Misc Info',
                                            r: 'Alt Responsible Agent', t: 'Alt Title', u: 'Alt URI', '6': '505' })
      ]
    end

    let(:values) { helper.contents_show(record) }

    it 'returns expected values from 505 and its linked alternate' do
      expect(values).to contain_exactly(
        'Formatted content notes Misc Info Responsible Agent A Title URI',
        'Alt Formatted content notes Alt Misc Info Alt Responsible Agent Alt Title Alt URI'
      )
    end
  end

  describe '.access_restriction_show' do
    let(:record) { marc_record(fields: fields) }
    let(:fields) do
      [
        marc_field(tag: '506', subfields: { a: 'Open to users with valid PennKey', b: 'Donor', c: 'Appointment Only',
                                            d: 'estate executors', e: 'Some Policy', f: 'No online access',
                                            g: '20300101', q: 'Van Pelt', u: 'URI', '2': 'star' })
      ]
    end

    let(:values) { helper.access_restriction_show(record) }

    it 'returns expected values from 506' do
      expect(values).to contain_exactly(
        'Open to users with valid PennKey Donor Appointment Only estate executors Some Policy No online access
20300101 Van Pelt URI star'.squish
      )
    end
  end

  describe '.finding_aid_show' do
    let(:record) { marc_record(fields: fields) }

    let(:fields) do
      [
        marc_field(tag: '555', subfields: { a: 'Finding aid', b: 'Source', c: 'Item level control',
                                            d: 'citation', u: 'URI', '3': 'Materials' }),
        marc_field(tag: '880', subfields: { a: 'Alt Finding aid', b: 'Alt Source', c: 'Alt Item level control',
                                            d: 'Alt citation', u: 'Alt URI', '3': 'Alt Materials', '6': '555' })
      ]
    end

    let(:values) { helper.finding_aid_show(record) }

    it 'returns expected values from 555 and its linked alternate' do
      expect(values).to contain_exactly(
        'Finding aid Source Item level control citation URI Materials',
        'Alt Finding aid Alt Source Alt Item level control Alt citation Alt URI Alt Materials'
      )
    end
  end

  describe '.participant_show' do
    let(:record) { marc_record(fields: fields) }

    let(:fields) do
      [
        marc_field(tag: '511', subfields: { a: 'Narrator: Some Dev' }),
        marc_field(tag: '880', subfields: { a: 'Alt Participant', '6': '511' })
      ]
    end

    let(:values) { helper.participant_show(record) }

    it 'returns expected values from 511 and its linked alternate' do
      expect(values).to contain_exactly('Narrator: Some Dev', 'Alt Participant')
    end
  end

  describe '.credits_show' do
    let(:record) { marc_record(fields: fields) }

    let(:fields) do
      [
        marc_field(tag: '508', subfields: { a: 'Music: Some Dev' }),
        marc_field(tag: '880', subfields: { a: 'Alt Credits', '6': '508' })
      ]
    end

    let(:values) { helper.credits_show(record) }

    it 'returns expected values from 508 and its linked alternate' do
      expect(values).to contain_exactly('Music: Some Dev', 'Alt Credits')
    end
  end

  describe '.biography_show' do
    let(:record) { marc_record(fields: fields) }

    let(:fields) do
      [
        marc_field(tag: '545', subfields: { a: 'A Creator', b: 'Additional Info', u: 'URI' }),
        marc_field(tag: '880', subfields: { a: 'Alt Bio', b: 'Alt Info', u: 'Alt URI', '6': '545' })
      ]
    end

    let(:values) { helper.biography_show(record) }

    it 'returns expected values from 545 and its linked alternate' do
      expect(values).to contain_exactly('A Creator Additional Info URI',
                                        'Alt Bio Alt Info Alt URI')
    end
  end

  describe '.summary_show' do
    let(:record) { marc_record(fields: fields) }

    let(:fields) do
      [
        marc_field(tag: '520', subfields: { a: 'An Abstract', b: 'Additional Summary', c: 'ProQuest' }),
        marc_field(tag: '880', subfields: { a: 'Alt Abstract', b: 'Alt Additional Summary', c: 'Alt ProQuest',
                                            '6': '520' })
      ]
    end

    let(:values) { helper.summary_show(record) }

    it 'returns expected values from 520 and its linked alternate' do
      expect(values).to contain_exactly('An Abstract Additional Summary ProQuest',
                                        'Alt Abstract Alt Additional Summary Alt ProQuest')
    end

    describe '.arrangement_show' do
      let(:record) { marc_record(fields: fields) }

      let(:fields) do
        [
          marc_field(tag: '351', subfields: { a: 'Organized into five subseries', b: 'Arrangement pattern', c: 'Series',
                                              '3': 'materials' }),
          marc_field(tag: '880', subfields: { a: 'Alt organization', b: 'Alt arrangement', c: 'Alt hierarchical level',
                                              '3': 'Alt materials', '6': '351' })
        ]
      end

      let(:values) { helper.arrangement_show(record) }

      it 'returns expected values from 351 and its linked alternate' do
        expect(values).to contain_exactly('Organized into five subseries Arrangement pattern Series materials',
                                          'Alt organization Alt arrangement Alt hierarchical level Alt materials')
      end
    end

    describe '.system_details_show' do
      let(:record) { marc_record(fields: fields) }

      let(:fields) do
        [
          marc_field(tag: '538', subfields: { a: 'Blu-ray, region A, 1080p High Definition, full screen (1.33:1)',
                                              i: 'display text for URI', u: 'http://www.universal.resource/locator ',
                                              '3': ['Blu-ray disc.', '2015'] }),
          marc_field(tag: '344', subfields: { a: 'digital', b: 'optical', c: '1.4 m/s', g: 'stereo',
                                              h: 'digital recording', '3': 'audio disc' }),
          marc_field(tag: '345', subfields: { a: '1 film reel (25 min.)', b: '24 fps', '3': 'Polyester print' }),
          marc_field(tag: '346', subfields: { a: 'VHS', b: 'NTSC', '3': 'original videocassette' }),
          marc_field(tag: '347', subfields: { a: 'video file', b: 'DVD video', e: 'region', '3': 'DVD' }),
          marc_field(tag: '880', subfields: { a: 'Alt system details', i: 'Alternative display text', u: 'Alt URI',
                                              '3': 'Alt materials.', '6': '538' }),
          marc_field(tag: '880', subfields: { a: 'Alt recording', b: 'Alt medium', c: 'Alt playing speed',
                                              g: 'Alt channel',
                                              h: 'Alt characteristic', '3': 'Alt materials.',
                                              '6': '344' }),
          marc_field(tag: '880', subfields: { a: 'Alt presentation format', b: 'Alt projection speed',
                                              '3': 'Alt materials.', '6': '345' }),
          marc_field(tag: '880', subfields: { a: 'Alt video format', b: 'Alt broadcast', '3': 'Alt materials.',
                                              '6': '346' }),
          marc_field(tag: '880', subfields: { a: 'Alt file type', b: 'Alt encoding', '3': 'Alt materials.',
                                              '6': 'Alt region' })

        ]
      end

      let(:values) { helper.system_details_show(record) }

      it 'returns expected from 5xx and 3xx fields and their linked alternates' do
        expect(values).to contain_exactly(
          'Blu-ray disc: 2015 Blu-ray, region A, 1080p High Definition, full screen (1.33:1) display
text for URI http://www.universal.resource/locator'.squish,
          'audio disc digital optical 1.4 m/s stereo digital recording', 'Polyester print 1 film reel (25 min.) 24 fps',
          'original videocassette VHS NTSC', 'DVD video file DVD video region',
          'Alt materials Alt system details Alternative display text Alt URI',
          'Alt materials Alt recording Alt medium Alt playing speed Alt channel Alt characteristic',
          'Alt materials Alt presentation format Alt projection speed',
          'Alt materials Alt video format Alt broadcast'
        )
      end
    end
  end
end
