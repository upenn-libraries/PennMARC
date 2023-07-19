# frozen_string_literal: true

describe 'PennMARC::Creator' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Creator }
  let(:mapping) { { aut: 'Author' } }

  describe '.search' do
    let(:record) { marc_record fields: fields }

    context 'for a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345',
                                             e: 'author', d: '1900-2000' }),
         marc_field(tag: '880', subfields: { a: 'Surname, Alternative', '6': '100' })]
      end

      it 'contains the expected search field values for a single author work' do
        expect(helper.search(record, mapping)).to eq ['Name Surname http://cool.uri/12345 author 1900-2000.',
                                                      'Surname, Name http://cool.uri/12345 author 1900-2000.',
                                                      'Alternative Surname']
      end
    end

    context 'for a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })]
      end

      it 'contains the expected search field values for a corporate author work' do
        expect(helper.search(record, mapping)).to eq ['Group of People Annual Meeting Author.',
                                                      'Alt. Group Name Alt. Annual Meeting']
      end
    end
  end

  describe '.values' do
    let(:record) { marc_record fields: fields }

    context 'for a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Author', c: 'Fancy', d: 'active 24th century AD', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '100', a: 'Alt Author', c: 'Alt Fanciness' })]
      end

      it 'returns values for the author, including mapped relator code from ǂ4' do
        values = helper.values(record, mapping)
        expect(values).to contain_exactly 'Author Fancy active 24th century AD, Author.'
        expect(values.join.downcase).not_to include 'alt'
      end
    end

    context 'for a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Annual Report', b: 'Leader', e: 'author', '4': 'aut' })]
      end

      it 'returns values for the corporate author, including mapped relator code from ǂ4' do
        expect(helper.values(record, mapping)).to contain_exactly 'Annual Report Leader author, Author.'
      end
    end
  end

  describe '.show' do
    let(:record) { marc_record fields: fields }

    context 'for a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '880', subfields: { a: 'Surname, Alternative', '6': '100' })]
      end
      it 'returns single author values with no URIs anywhere' do
        values = helper.show(record)
        expect(values).to contain_exactly 'Surname, Name 1900-2000', 'Surname, Alternative'
        expect(values.join.downcase).not_to include 'http'
      end
    end

    context 'for a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })]
      end
      it 'returns corporate author values with no URIs anywhere' do
        values = helper.show(record)
        expect(values).to contain_exactly 'Alt. Group Name Alt. Annual Meeting', 'Group of People Annual Meeting'
        expect(values.join.downcase).not_to include 'http'
      end
    end
  end

  describe '.sort' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '100', subfields: { a: 'Sort, Value,', d: '1900-2000', e: 'Composer',
                                            '0': 'http://cool.uri/12345', '4': 'aut' })
      ]
    end

    it 'returns single value with no content from ǂ1, ǂ4, ǂ6, ǂ8 or ǂe' do
      expect(helper.sort(record)).to eq 'Sort, Value, 1900-2000 http://cool.uri/12345'
      expect(helper.sort(record)).not_to include 'aut'
    end
  end

  describe '.facet' do
    let(:record) { marc_record fields: fields }
    let(:values) { helper.facet(record) }

    context 'for a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Author, Great', d: '1900-2000' }),
         marc_field(tag: '700', subfields: { a: 'Co-Author, Great', d: '1900-2000' }),
         marc_field(tag: '800', subfields: { a: 'Author, Added' })]
      end

      it 'includes corporate author and creator values from allowed subfields' do
        expect(values).to contain_exactly 'Author, Added', 'Author, Great 1900-2000', 'Co-Author, Great 1900-2000'
      end
    end
    context 'for a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting' }),
         marc_field(tag: '710', subfields: { a: 'A Publisher', e: 'publisher' }),
         marc_field(tag: '710', subfields: { a: 'A Sponsor', e: 'sponsoring body' }),
         marc_field(tag: '810', subfields: { a: 'A Series Entity', t: 'Some Series' })]
      end

      it 'includes corporate author and creator values from allowed subfields' do
        expect(values).to contain_exactly 'A Publisher', 'A Series Entity', 'A Sponsor',
                                          'Group of People Annual Meeting'
      end
    end
    context 'for a meeting author record' do
      let(:fields) do
        [marc_field(tag: '111', subfields: { a: 'Conference on Things', c: 'Earth' }),
         marc_field(tag: '711', subfields: { a: 'Thing Institute', j: 'sponsoring body' }),
         marc_field(tag: '811', subfields: { a: 'Series of Things', c: 'Earth' })]
      end

      it 'includes corporate author and creator values from allowed subfields' do
        expect(values).to contain_exactly 'Conference on Things Earth', 'Series of Things Earth', 'Thing Institute'
      end
    end
  end

  describe '.conference_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'MARC History Symposium', '4': 'aut' }),
        marc_field(tag: '880', subfields: { a: 'Alt. MARC History Symposium', '6': '111' })
      ]
    end

    it 'returns conference name information for display, ignoring any linked 880 fields' do
      expect(helper.conference_show(record, mapping)).to eq ['MARC History Symposium, Author.']
    end
  end

  describe '.conference_detail_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'MARC History Symposium', c: 'Moscow' }),
        marc_field(tag: '711', subfields: { a: 'Russian Library Conference', j: 'author' }),
        marc_field(tag: '711', indicator2: '1', subfields: { a: 'Ignored Entry', j: 'author' }),
        marc_field(tag: '880', subfields: { a: 'Proceedings', '6': '111' }),
        marc_field(tag: '880', subfields: { a: 'Not Included', i: 'something', '6': '111' })
      ]
    end

    it 'returns detailed conference name information for display, including linked 880 fields without ǂi, and ignoring
        any 111 or 711 with a defined indicator 2 value' do
      expect(helper.conference_detail_show(record)).to eq ['MARC History Symposium Moscow',
                                                           'Russian Library Conference author', 'Proceedings']
    end
  end

  describe '.contributor_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '700', subfields: { a: 'Name', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                            j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                            '4': 'aut' }),
        marc_field(tag: '700', subfields: { a: 'Ignore' }, indicator2: '1'),
        marc_field(tag: '700', subfields: { i: 'Ignore' }),
        marc_field(tag: '710', subfields: { a: 'Corporation', b: 'A division', c: 'Office', d: '1968', e: 'author',
                                            u: 'affiliation', '3': 'materials',
                                            '4': 'aut' }),
        marc_field(tag: '880', subfields: {  '6': '700', a: 'Alt Name', b: 'Alt num', c: 'Alt title',
                                             d: 'Alt date', e: 'Alt relator', j: 'Alt qualifier', q: 'Alt Fuller Name',
                                             u: 'Alt affiliation', '3': 'Alt materials' }),
        marc_field(tag: '880', subfields: { '6': '710', a: 'Alt Corp Name', b: 'Alt unit', c: 'Alt location', d: 'Alt date',
                                            e: 'Alt relator', u: 'Alt Affiliation', '3': 'Alt materials' }),
        marc_field(tag: '880', subfields: { i: 'Ignore', '6': '700' })
      ]
    end

    it 'returns expected contributor values' do
      expect(helper.contributor_show(record, mapping)).to contain_exactly(
        'Name I laureate 1968 pseud Fuller Name  author affiliation materials, Author',
        'Corporation A division Office 1968  author affiliation materials, Author',
        'Alt Name Alt num Alt title Alt date Alt qualifier Alt Fuller Name Alt relator Alt affiliation Alt materials',
        'Alt Corp Name Alt unit Alt location Alt date Alt relator Alt Affiliation Alt materials')
    end
  end

  xdescribe '.conference_search'
  xdescribe '.search_aux'
end
