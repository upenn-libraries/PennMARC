# frozen_string_literal: true

describe 'PennMARC::Creator' do
  let(:helper) { PennMARC::Creator }
  let(:mapping) { { aut: 'Author' } }

  describe '.search' do
    let(:record) { marc_record fields: fields }

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name,', '0': 'http://cool.uri/12345',
                                             e: 'author', d: '1900-2000' }),
         marc_field(tag: '880', subfields: { a: 'Surname, Alternative,', '6': '100' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Third', e: 'author.', '6': '100' })]
      end

      it 'contains the expected search field values for a single author work' do
        expect(helper.search(record, relator_map: mapping)).to contain_exactly(
          'Name Surname http://cool.uri/12345 1900-2000, author.',
          'Surname, Name http://cool.uri/12345 1900-2000, author.',
          'Alternative Surname',
          'Third Surname'
        )
      end
    end

    context 'with a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })]
      end

      it 'contains the expected search field values for a corporate author work' do
        expect(helper.search(record, relator_map: mapping)).to contain_exactly(
          'Group of People Annual Meeting, Author.',
          'Alt. Group Name Alt. Annual Meeting'
        )
      end
    end
  end

  describe '.search_aux' do
    let(:record) { marc_record fields: fields }

    context 'with a record that has an added name in the 7xx field' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Author', c: 'Fancy', d: 'active 24th century AD', '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Author, Added' }),
         marc_field(tag: '880', subfields: { '6': '100', a: 'Alt Author', c: 'Alt Fanciness' }),
         marc_field(tag: '880', subfields: { '6': '700', a: 'Alt Added Author' })]
      end

      it 'contains the expected search_aux field values for a single author work' do
        expect(helper.search_aux(record, relator_map: mapping)).to contain_exactly(
          'Author Fancy active 24th century AD, Author.',
          'Author, Added',
          'Added Author',
          'Alt Author Alt Fanciness',
          'Alt Added Author'
        )
      end
    end
  end

  describe '.show' do
    let(:record) { marc_record fields: fields }

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '880', subfields: { a: 'Surname, Alternative', '6': '100' })]
      end

      it 'returns single author values with no URIs anywhere' do
        values = helper.show(record)
        expect(values).to contain_exactly 'Surname, Name 1900-2000, author.', 'Surname, Alternative'
        expect(values.join.downcase).not_to include 'http'
      end
    end

    context 'with a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })]
      end

      it 'returns corporate author values with no URIs anywhere' do
        values = helper.show(record, relator_map: mapping)
        expect(values).to contain_exactly 'Alt. Group Name Alt. Annual Meeting',
                                          'Group of People Annual Meeting, Author.'
        expect(values.join.downcase).not_to include 'http'
      end
    end
  end

  describe '.extended_show' do
    let(:record) { marc_record fields: fields }

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '880', subfields: { a: 'Surname, Alternative', e: 'author', '6': '100' })]
      end

      it 'returns single author values and linked alternate with no URIs anywhere (the same as show)' do
        values = helper.extended_show(record)
        expect(values).to contain_exactly 'Surname, Name 1900-2000, author.', 'Surname, Alternative, author.'
        expect(values.join.downcase).not_to include 'http'
      end
    end

    context 'with author records in 100 and 700' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Alternative', '6': '100', '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Third', e: 'author.', '6': '100' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Ignore', e: 'editor.', '6': '100' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Not Included', '6': '100', '4': 'edt' })]
      end

      it 'returns three authors' do
        values = helper.extended_show(record)
        expect(values).to contain_exactly 'Surname, Name 1900-2000, author.',
                                          'Surname, Alternative, Author.', 'Surname, Third, author.'
        expect(values.join.downcase).not_to include 'http'
      end
    end

    context 'with no 100 or 700 fields' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '110', a: 'Alt. Group Name', b: 'Alt. Annual Meeting' })]
      end

      it 'returns empty' do
        values = helper.extended_show(record, relator_map: mapping)
        expect(values).to be_empty
        expect(values.join.downcase).not_to include 'http'
      end
    end
  end

  describe '.authors_list' do
    let(:record) { marc_record fields: fields }

    context 'with two author records' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '700', subfields: { a: 'Surname, Alternative', '6': '100', d: '1970-' })]
      end

      it 'returns single author values with no URIs anywhere' do
        values = helper.authors_list(record)
        expect(values).to contain_exactly 'Surname, Name', 'Surname, Alternative'
      end
    end

    context 'with five author records - abbreviated names' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Alex, ', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '110', subfields: { a: 'Second, NameX,  ', '0': 'http://cool.uri/12345', d: '1901-2010',
                                             e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
         marc_field(tag: '700', subfields: { a: 'Alt, Alternative', '6': '100', d: '1970-' }),
         marc_field(tag: '100', subfields: { a: 'Name with no comma', e: 'author' }),
         marc_field(tag: '100', subfields: { a: 'Name ends with comma,', e: 'author' })]
      end

      it 'returns single author values with no URIs anywhere' do
        values = helper.authors_list(record, first_initial_only: true)
        expect(values).to contain_exactly 'Surname, A.', 'Second, N.', 'Alt, A.',
                                          'Name ends with comma', 'Name with no comma'
      end
    end
  end

  describe '.contributors_list' do
    let(:record) { marc_record fields: fields }

    context 'with two authors and four contributors records, names only' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Hamilton, Alex', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.' }),
         marc_field(tag: '100', subfields: { a: 'Lincoln, Abraham,   ', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                             j: 'pseud', q: 'Fuller Name,  ', u: 'affiliation', '3': 'materials',
                                             '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Einstein, Albert', '6': '100', d: '1970-', '4': 'trl',
                                             e: 'translator' }),
         marc_field(tag: '700', subfields: { a: 'Franklin, Ben', '6': '100', d: '1970-', '4': 'edt' }),
         marc_field(tag: '710', subfields: { a: 'Jefferson, Thomas', '6': '100', d: '1870-', '4': 'edt' }),
         marc_field(tag: '700', subfields: { a: 'Dickens, Charles, ', '6': '100', d: '1970-', '4': 'com' })]
      end

      it 'returns two authors and four contributors' do
        values = helper.contributors_list(record)
        expect(values).to contain_exactly ['Author', ['Hamilton, Alex', 'Lincoln, Abraham']],
                                          ['Compiler', ['Dickens, Charles']],
                                          ['Editor', ['Franklin, Ben', 'Jefferson, Thomas']],
                                          ['Translator', ['Einstein, Albert']]
      end
    end

    context 'with two authors and four contributors records, with full information and relator' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Hamilton, Alex,  ', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'aut' }),
         marc_field(tag: '100', subfields: { a: 'Lincoln, Abraham', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                             j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                             '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Einstein, Albert', '6': '100', d: '1970-', '4': 'trl',
                                             e: 'translator' }),
         marc_field(tag: '700', subfields: { a: 'Franklin, Ben', '6': '100', d: '1970-', '4': 'edt' }),
         marc_field(tag: '710', subfields: { a: 'Jefferson, Thomas', '6': '100', d: '1870-', '4': 'edt' }),
         marc_field(tag: '700', subfields: { a: 'Dickens, Charles', '6': '100', d: '1970-', '4': 'com' }),
         marc_field(tag: '880', subfields: { a: '狄更斯', '6': '700', d: '1970-', '4': 'com' }),
         marc_field(tag: '700', subfields: { a: 'Twain, Mark,', '6': '100', d: '1870-' })]
      end

      it 'returns four contributors' do
        values = helper.contributors_list(record, include_authors: false, name_only: false, vernacular: true)
        expect(values).to contain_exactly ['Compiler', ['Dickens, Charles 1970-, Compiler', '狄更斯 1970-, Compiler']],
                                          ['Contributor', ['Twain, Mark 1870-, Contributor']],
                                          ['Editor',
                                           ['Franklin, Ben 1970-, Editor', 'Jefferson, Thomas 1870-, Editor']],
                                          ['Translator', ['Einstein, Albert 1970-, Translator']]
      end
    end
  end

  describe '.show_facet_map' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                            e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
        marc_field(tag: '110', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
        marc_field(tag: '880', subfields: { a: 'Ignore', '6': '100' })
      ]
    end

    it 'returns expected hash' do
      values = helper.show_facet_map(record, relator_map: mapping)
      expect(values).to eq({ 'Surname, Name 1900-2000, author.' => 'Surname, Name 1900-2000',
                             'Group of People Annual Meeting, Author.' => 'Group of People Annual Meeting' })
    end
  end

  describe '.extended_show_facet_map' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345', d: '1900-2000',
                                            e: 'author.', '4': 'http://cool.uri/vocabulary/relators/aut' }),
        marc_field(tag: '700', subfields: { a: 'Group of People', b: 'Annual Meeting', '4': 'aut' }),
        marc_field(tag: '700', subfields: { a: 'Second Group of People', b: 'Meeting', '4': 'aut' }),
        marc_field(tag: '700', subfields: { a: 'Ignore (not author)', '4': 'edt' }),
        marc_field(tag: '880', subfields: { a: 'Ignore', '6': '100' })
      ]
    end

    it 'returns expected hash' do
      values = helper.extended_show_facet_map(record, relator_map: mapping)
      expect(values).to eq({ 'Surname, Name 1900-2000, author.' => 'Surname, Name 1900-2000',
                             'Group of People Annual Meeting, Author.' => 'Group of People Annual Meeting',
                             'Second Group of People Meeting, Author.' => 'Second Group of People Meeting' })
    end
  end

  describe '.show_aux' do
    let(:record) { marc_record fields: fields }

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Person', c: 'Loquacious', d: 'active 24th century AD', '4': 'aut' }),
         marc_field(tag: '880', subfields: { '6': '100', a: 'Alt Author', c: 'Alt Fanciness' })]
      end

      it 'returns mapped relator code from ǂ4 at the end with a terminal period' do
        expect(helper.show_aux(record, relator_map: mapping).first).to end_with ', Author.'
      end

      it 'does not include linked 880 field' do
        expect(helper.show_aux(record, relator_map: mapping).join(' ')).not_to include 'Alt'
      end
    end

    context 'with a corporate author record' do
      let(:fields) do
        [marc_field(tag: '110', subfields: { a: 'Annual Report', b: 'Leader', e: 'author', '4': 'aut' })]
      end

      it 'returns values for the corporate author, including mapped relator code from ǂ4' do
        expect(helper.show_aux(record, relator_map: mapping)).to contain_exactly(
          'Annual Report Leader, Author.'
        )
      end
    end

    context 'with relator term and translatable relator code' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Person', c: 'Loquacious', d: 'active 24th century AD', e: 'Ignore',
                                             '4': 'aut' })]
      end

      it 'only appends translatable relator' do
        expect(helper.show_aux(record, relator_map: mapping)).to contain_exactly(
          'Person Loquacious active 24th century AD, Author.'
        )
      end
    end

    context 'with multiple translatable relator codes' do
      let(:mapping) { { aut: 'Author', stl: 'Storyteller' } }
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Person', c: 'Loquacious', d: 'active 24th century AD',
                                             '4': %w[aut stl] })]
      end

      it 'appends all translatable relators' do
        expect(helper.show_aux(record, relator_map: mapping)).to contain_exactly(
          'Person Loquacious active 24th century AD, Author, Storyteller.'
        )
      end
    end

    context 'without translatable relator code' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Person', c: 'Loquacious', d: 'active 24th century AD',
                                             e: 'author' })]
      end

      it 'appends all translatable relators' do
        expect(helper.show_aux(record)).to contain_exactly('Person Loquacious active 24th century AD, author.')
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

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Author, Great', d: '1900-2000' }),
         marc_field(tag: '700', subfields: { a: 'Co-Author, Great', d: '1900-2000' }),
         marc_field(tag: '800', subfields: { a: 'Author, Added' })]
      end

      it 'includes corporate author and creator values from allowed subfields' do
        expect(values).to contain_exactly 'Author, Added', 'Author, Great 1900-2000', 'Co-Author, Great 1900-2000'
      end
    end

    context 'with a corporate author record' do
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

    context 'with a meeting author record' do
      let(:fields) do
        [marc_field(tag: '111', subfields: { a: 'Conference on Things', c: 'Earth' }),
         marc_field(tag: '711', subfields: { a: 'Thing Institute', j: 'sponsoring body' }),
         marc_field(tag: '811', subfields: { a: 'Series of Things', c: 'Earth' })]
      end

      it 'includes corporate author and creator values from allowed subfields' do
        expect(values).to contain_exactly 'Conference on Things Earth', 'Series of Things Earth',
                                          'Thing Institute'
      end
    end
  end

  describe '.conference_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'MARC History Symposium', '0': 'http://cool.uri/12345', '4': 'aut' }),
        marc_field(tag: '880', subfields: { a: 'Alt. MARC History Symposium', '6': '111' })
      ]
    end

    it 'returns conference name information for display, ignoring any linked 880 fields' do
      expect(helper.conference_show(record, relator_map: mapping)).to eq ['MARC History Symposium, Author.']
    end
  end

  describe '.conference_detail_show' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'MARC History Symposium', e: 'Advisory Committee', c: 'Moscow',
                                            j: 'author', '4': 'aut' }),
        marc_field(tag: '711', subfields: { a: 'Russian Library Conference', j: 'author' }),
        marc_field(tag: '711', indicator2: '1', subfields: { a: 'Ignored Entry', j: 'author' }),
        marc_field(tag: '880', subfields: { a: 'Proceedings', '6': '111' }),
        marc_field(tag: '880', subfields: { a: 'Opening Remarks', j: 'author', '4': 'aut', '6': '711' }),
        marc_field(tag: '880', subfields: { a: 'Not Included', i: 'something', '6': '111' })
      ]
    end

    it 'returns detailed conference name information for display, including linked 880 fields without ǂi, and ignoring
        any 111 or 711 with a defined indicator 2 value' do
      expect(helper.conference_detail_show(record, relator_map: mapping)).to contain_exactly(
        'MARC History Symposium Moscow Advisory Committee, Author.',
        'Russian Library Conference, author.', 'Proceedings', 'Opening Remarks, Author.'
      )
    end
  end

  describe '.conference_detail_show_facet_map' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'Council of Trent', d: '(1545-1563 :', c: 'Trento, Italy)' }),
        marc_field(tag: '711', subfields: { a: 'Code4Lib', n: '(18th :', d: '2024 :', c: 'Ann Arbor, MI)' }),
        marc_field(tag: '880', subfields: { a: 'Alt Ignore', '6': '111' })
      ]
    end

    it 'returns the expected hash' do
      value = helper.conference_detail_show_facet_map(record)
      expect(value).to eq({ 'Council of Trent (1545-1563 : Trento, Italy)' => 'Council of Trent Trento, Italy)',
                            'Code4Lib (18th : 2024 : Ann Arbor, MI)' => 'Code4Lib (18th : Ann Arbor, MI)' })
    end
  end

  describe '.conference_search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '111', subfields: { a: 'MARC History Symposium', c: 'Moscow', '4': 'aut' })
      ]
    end

    it 'returns conference name information for searching without relator value' do
      expect(helper.conference_search(record)).to eq ['MARC History Symposium Moscow']
    end
  end

  describe '.corporate_search' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '110', subfields: { a: 'Penn Libraries', b: 'Digital Library Development' }),
        marc_field(tag: '710', subfields: { a: 'Working Group on Digital Repository Infrastructure' }),
        marc_field(tag: '810', subfields: { a: 'Constellation of Repositories Strategic Team' })
      ]
    end

    it 'returns expected values' do
      expect(helper.corporate_search(record)).to contain_exactly(
        'Constellation of Repositories Strategic Team',
        'Penn Libraries Digital Library Development',
        'Working Group on Digital Repository Infrastructure'
      )
    end
  end

  describe '.contributor_show' do
    let(:record) { marc_record fields: fields }

    context 'when indicator2 is "1"' do
      let(:fields) do
        [marc_field(tag: '700', subfields: { a: 'Ignore' }, indicator2: '1')]
      end

      it 'ignores the field' do
        values = helper.contributor_show(record, relator_map: mapping)
        expect(values).to be_empty
      end
    end

    context 'with subfield "i"' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { i: 'Ignore' }),
          marc_field(tag: '880', subfields: { i: 'Ignore', '6': '700' })
        ]
      end

      it 'ignores the field' do
        values = helper.contributor_show(record, relator_map: mapping)
        expect(values).to be_empty
      end
    end

    context 'with a single contributor and linked alternate' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { a: 'Name', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'aut' }),
          marc_field(tag: '880', subfields: {  '6': '700', a: 'Alt Name', b: 'Alt num', c: 'Alt title',
                                               d: 'Alt date', e: 'Alt relator', j: 'Alt qualifier',
                                               q: 'Alt Fuller Name', u: 'Alt affiliation', '3': 'Alt material' })
        ]
      end

      it 'returns expected contributor values' do
        values = helper.contributor_show(record, relator_map: mapping)
        expect(values).to contain_exactly(
          'Name I laureate 1968 pseud Fuller Name affiliation materials, Author.',
          'Alt Name Alt num Alt title Alt date Alt qualifier Alt Fuller Name Alt affiliation Alt material, Alt relator.'
        )
      end

      it 'returns contributor name only when called with name_only as true' do
        values = helper.contributor_show(record, relator_map: mapping, name_only: true)
        expect(values).to contain_exactly('Name, Author.', 'Alt Name, Alt relator.')
      end

      it 'returns contributor values without alternatives when called with vernacular as false' do
        values = helper.contributor_show(record, relator_map: mapping, vernacular: false)
        expect(values).to contain_exactly('Name I laureate 1968 pseud Fuller Name affiliation materials, Author.')
      end
    end

    context 'with a corporate contributor and linked alternate' do
      let(:fields) do
        [
          marc_field(tag: '710', subfields: { a: 'Corporation', b: 'A division', c: 'Office', d: '1968', e: 'author',
                                              u: 'affiliation', '3': 'materials', '4': 'aut' }),
          marc_field(tag: '880', subfields: { '6': '710', a: 'Alt Corp Name', b: 'Alt unit', c: 'Alt location',
                                              d: 'Alt date', e: ['Alt relator', 'another'], u: 'Alt Affiliation',
                                              '3': 'Alt materials' })
        ]
      end

      it 'returns expected contributor values' do
        values = helper.contributor_show(record)
        expect(values).to contain_exactly(
          'Corporation A division Office 1968 affiliation materials, Author.',
          'Alt Corp Name Alt unit Alt location Alt date Alt Affiliation Alt materials, Alt relator, another.'
        )
      end
    end
  end

  describe '.contributor_noauthor_show' do
    let(:record) { marc_record fields: fields }

    context 'when indicator2 is "1"' do
      let(:fields) do
        [marc_field(tag: '700', subfields: { a: 'Ignore' }, indicator2: '1')]
      end

      it 'ignores the field' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping)
        expect(values).to be_empty
      end
    end

    context 'with subfield "i"' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { i: 'Ignore', e: 'author' }),
          marc_field(tag: '880', subfields: { i: 'Ignore', '6': '700' })
        ]
      end

      it 'ignores the field' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping)
        expect(values).to be_empty
      end
    end

    context 'with a single contributor and linked alternate' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { a: 'Name', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'aut' }),
          marc_field(tag: '880', subfields: {  '6': '700', a: 'Alt Name', b: 'Alt num', c: 'Alt title',
                                               d: 'Alt date', e: 'Alt relator', j: 'Alt qualifier',
                                               q: 'Alt Fuller Name', u: 'Alt affiliation', '3': 'Alt material' })
        ]
      end

      it 'returns the non-author contributor only' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping)
        expect(values).to contain_exactly(
          'Alt Name Alt num Alt title Alt date Alt qualifier Alt Fuller Name Alt affiliation Alt material, Alt relator.'
        )
      end

      it 'returns the non-author contributor name only when called with name_only as true' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, name_only: true)
        expect(values).to contain_exactly 'Alt Name, Alt relator.'
      end

      it 'returns empty when called with vernacular as false' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, vernacular: false)
        expect(values).to be_empty
      end
    end

    context 'with four contributors two of which are authors' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { a: '01 (Ignore)', b: 'I', c: 'laureate',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'aut', '6': '880-01' }),
          marc_field(tag: '700', subfields: { a: '02 (Ignore)', d: '1968', e: 'author',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '6': '880-02' }),
          marc_field(tag: '700', subfields: { a: '03 (Show)', b: 'J', c: 'laureate',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'edt', '6': '880-03' }),
          marc_field(tag: '700', subfields: { a: '04 (Show)', d: '1968', e: 'editor',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '6': '880-04' })
        ]
      end

      it 'returns two non-author contributors' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping)
        expect(values).to contain_exactly(
          '03 (Show) J laureate pseud Fuller Name affiliation materials',
          '04 (Show) 1968 pseud Fuller Name affiliation materials, editor.'
        )
      end

      it 'returns contributor name only when called with name_only as true' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, name_only: true)
        expect(values).to contain_exactly('03 (Show)', '04 (Show), editor.')
      end

      it 'returns contributor values without alternatives when called with vernacular as false' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, vernacular: false)
        expect(values).to contain_exactly(
          '03 (Show) J laureate pseud Fuller Name affiliation materials',
          '04 (Show) 1968 pseud Fuller Name affiliation materials, editor.'
        )
      end
    end

    context 'with four contributors having respective alternatives, two of the contributors are authors' do
      let(:fields) do
        [
          marc_field(tag: '700', subfields: { a: '01 (Ignore)', b: 'I', c: 'laureate',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'aut', '6': '880-01' }),
          marc_field(tag: '700', subfields: { a: '02 (Ignore)', d: '1968', e: 'author',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '6': '880-02' }),
          marc_field(tag: '700', subfields: { a: '03 (Show)', b: 'J', c: 'laureate',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '4': 'edt', '6': '880-03' }),
          marc_field(tag: '700', subfields: { a: '04 (Show)', d: '1968', e: 'editor',
                                              j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                              '6': '880-04' }),
          marc_field(tag: '880', subfields: { a: 'Alt Name 01 (Ignore)', '6': '700-01', b: 'Alt num 01',
                                              c: 'Alt title 01', d: 'Alt date 01', e: 'Alt relator 01',
                                              j: 'Alt qualifier 01', q: 'Alt Fuller Name 01', u: 'Alt affiliation 01',
                                              '3': 'Alt material 01' }),
          marc_field(tag: '880', subfields: { a: 'Alt Name 02 (Ignore)', '6': '700-02', b: 'Alt num 02',
                                              c: 'Alt title 02', d: 'Alt date 02', e: 'Alt relator 02',
                                              j: 'Alt qualifier 02', q: 'Alt Fuller Name 02', u: 'Alt affiliation 02',
                                              '3': 'Alt material 02' }),
          marc_field(tag: '880', subfields: { a: 'Alt Name 03 (Show)', '6': '700-03', b: 'Alt num 03',
                                              c: 'Alt title 03', d: 'Alt date 03', e: 'Alt relator 03',
                                              j: 'Alt qualifier 03', q: 'Alt Fuller Name 03', u: 'Alt affiliation 03',
                                              '3': 'Alt material 03' }),
          marc_field(tag: '880', subfields: { a: 'Alt Name 04 (Show)', '6': '700-04', b: 'Alt num 04',
                                              c: 'Alt title 04', d: 'Alt date 04', e: 'Alt relator 04',
                                              j: 'Alt qualifier 04', q: 'Alt Fuller Name 04', u: 'Alt affiliation 04',
                                              '3': 'Alt material 04' })
        ]
      end

      it 'returns two non-author contributors with their alternatives' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping)
        expect(values).to contain_exactly(
          '03 (Show) J laureate pseud Fuller Name affiliation materials',
          '04 (Show) 1968 pseud Fuller Name affiliation materials, editor.',
          'Alt Name 03 (Show) Alt num 03 Alt title 03 Alt date 03 Alt qualifier 03 Alt Fuller Name 03 '\
            'Alt affiliation 03 Alt material 03, Alt relator 03.',
          'Alt Name 04 (Show) Alt num 04 Alt title 04 Alt date 04 Alt qualifier 04 Alt Fuller Name 04 '\
            'Alt affiliation 04 Alt material 04, Alt relator 04.'
        )
      end

      it 'returns two non-author contributors name and alternative names only when called with name_only as true' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, name_only: true)
        expect(values).to contain_exactly('03 (Show)', 'Alt Name 03 (Show), Alt relator 03.',
                                          '04 (Show), editor.', 'Alt Name 04 (Show), Alt relator 04.')
      end

      it 'returns two non-author contributors without alternatives when called with vernacular as false' do
        values = helper.contributor_noauthor_show(record, relator_map: mapping, vernacular: false)
        expect(values).to contain_exactly(
          '03 (Show) J laureate pseud Fuller Name affiliation materials',
          '04 (Show) 1968 pseud Fuller Name affiliation materials, editor.'
        )
      end
    end

    context 'with a corporate contributor and linked alternate' do
      let(:fields) do
        [
          marc_field(tag: '710', subfields: { a: 'Corporation', b: 'A division', c: 'Office', d: '1968', e: 'author',
                                              u: 'affiliation', '3': 'materials', '4': 'aut' }),
          marc_field(tag: '880', subfields: { '6': '710', a: 'Alt Corp Name', b: 'Alt unit', c: 'Alt location',
                                              d: 'Alt date', e: ['Alt relator', 'another'], u: 'Alt Affiliation',
                                              '3': 'Alt materials' })
        ]
      end

      it 'returns expected contributor values' do
        values = helper.contributor_noauthor_show(record)
        expect(values).to contain_exactly(
          'Corporation A division Office 1968 affiliation materials, Author.',
          'Alt Corp Name Alt unit Alt location Alt date Alt Affiliation Alt materials, Alt relator, another.'
        )
      end
    end
  end
end
