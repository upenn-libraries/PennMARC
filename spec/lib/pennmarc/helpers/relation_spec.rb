# frozen_string_literal: true

describe 'PennMARC::Relation' do
  let(:helper) { PennMARC::Relation }
  let(:record) { marc_record fields: fields }
  let(:relator_map) { { aut: 'Author', trl: 'Translator' } }

  describe '.contained_in_show' do
    let(:fields) do
      [marc_field(tag: '773', subfields: { i: 'Contained in (work):', t: 'National geographic magazine',
                                           w: '(OCoLC)12345' })]
    end

    it 'returns only the specified subfields' do
      expect(helper.contained_in_show(record)).to eq ['Contained in (work): National geographic magazine']
    end
  end

  describe '.related_collections_show' do
    let(:fields) do
      [marc_field(tag: '544', subfields: { d: 'Penn Papers', c: 'USA' }),
       marc_field(tag: '880', subfields: { '6': '544', d: 'Penn Papers Alt.' })]
    end

    it 'returns all expected subfield data for field and linked alternate' do
      expect(helper.related_collections_show(record)).to eq ['Penn Papers USA', 'Penn Papers Alt.']
    end
  end

  describe '.publications_about_show' do
    let(:fields) do
      [marc_field(tag: '581', subfields: { '3': 'Preliminary Report', a: '"Super Important Research Topic", 1977' }),
       marc_field(tag: '880', subfields: { '6': '581', '3': 'Alt. Preliminary Report' })]
    end

    it 'returns all expected subfield data for field and linked alternate' do
      expect(helper.publications_about_show(record)).to eq ['Preliminary Report "Super Important Research Topic", 1977',
                                                            'Alt. Preliminary Report']
    end
  end

  describe 'related_work_show' do
    let(:fields) do
      [marc_field(tag: '700', indicator2: '', subfields: { i: 'Translation of (work):', a: 'Some Author',
                                                           t: 'Aphorisms', '4': 'trl' }),
       marc_field(tag: '700', indicator2: '2', subfields: { i: 'Adaptation of (work):', t: 'Ignored' }),
       marc_field(tag: '880', indicator2: '', subfields: { i: 'Alt. Prefix:', a: 'Alt. Author', t: 'Alt. Aphorisms',
                                                           '6': '700' })]
    end

    it 'returns specified subfield values from specified field with blank indicator2' do
      values = helper.related_work_show record, relator_map: relator_map
      expect(values).to contain_exactly 'Translation of: Some Author Aphorisms, Translator.',
                                        'Alt. Prefix: Alt. Author Alt. Aphorisms'
      expect(values).not_to include 'Ignored'
    end

    context 'with a translatable relator code in a 711 field and its linked alternate' do
      let(:fields) do
        [marc_field(tag: '711', indicator2: '', subfields: { i: 'Index to (work):', a: 'The Law of Outer Space',
                                                             e: 'Advisory Board', j: 'author', t: 'Proceedings' }),
         marc_field(tag: '880', indicator2: '', subfields: { i: 'Alt. Prefix:', a: 'Alt. Name', j: 'author',
                                                             t: 'Alt. Title', '6': '711' })]
      end

      it 'appends relator term found in $j' do
        values = helper.related_work_show(record, relator_map: relator_map)
        expect(values).to contain_exactly('Index to: The Law of Outer Space Advisory Board Proceedings, author.',
                                          'Alt. Prefix: Alt. Name Alt. Title, author.')
      end
    end
  end

  describe '.contains_show' do
    let(:fields) do
      [marc_field(tag: '700', indicator2: '2', subfields: { i: 'Container of (work):', a: 'Some Author', t: 'Works',
                                                            '4': 'aut' }),
       marc_field(tag: '700', indicator2: '', subfields: { i: 'Adaptation of (work):', t: 'Ignored' }),
       marc_field(tag: '880', indicator2: '2', subfields: { i: 'Alt. Prefix:', a: 'Alt. Name', e: 'Alt relator',
                                                            '6': '700' })]
    end

    it "returns specified subfield values from specified field with '2' in indicator2" do
      values = helper.contains_show record, relator_map: relator_map
      expect(values).to contain_exactly 'Alt. Prefix: Alt. Name, Alt relator.',
                                        'Container of: Some Author Works, Author.'
      expect(values).not_to include 'Ignored'
    end

    context 'with a translatable relator code in a 711 field and its linked alternate' do
      let(:fields) do
        [marc_field(tag: '711', indicator2: '2', subfields: { i: 'Index to (work):', a: 'The Law of Outer Space',
                                                              e: 'Advisory Board', j: 'author', t: 'Proceedings' }),
         marc_field(tag: '880', indicator2: '2', subfields: { i: 'Alt. Prefix:', a: 'Alt. Name', j: 'author',
                                                              t: 'Alt. Title', '6': '711' })]
      end

      it 'appends relator term found in $j' do
        values = helper.contains_show(record, relator_map: relator_map)
        expect(values).to contain_exactly('Index to: The Law of Outer Space Advisory Board Proceedings, author.',
                                          'Alt. Prefix: Alt. Name Alt. Title, author.')
      end
    end

    context 'with translatable relator codes in a linked alternate' do
      let(:fields) do
        [marc_field(tag: '880', indicator2: '2', subfields: { i: 'Alt. Prefix:', a: 'Alt. Name', '4': 'aut',
                                                              '6': '700' })]
      end

      it 'appends translatable relator codes' do
        values = helper.contains_show record, relator_map: relator_map
        expect(values).to contain_exactly 'Alt. Prefix: Alt. Name, Author.'
      end
    end
  end

  describe '.constituent_unit_show' do
    let(:fields) do
      [marc_field(tag: '774', subfields: { i: 'Container of (manifestation)', a: 'Person, Some',
                                           t: 'Private Correspondences', w: '(OCoLC)12345' }),
       marc_field(tag: '880', subfields: { '6': '774', a: 'Alt. Person', t: 'Alt. Title' })]
    end

    it 'returns specified subfield values from fields and linked alternate' do
      expect(helper.constituent_unit_show(record)).to(
        contain_exactly('Alt. Person Alt. Title',
                        'Container of (manifestation) Person, Some Private Correspondences')
      )
    end
  end

  describe '.has_supplement_show' do
    let(:fields) do
      [marc_field(tag: '770', subfields: { i: 'Supplement (work)', a: 'Person, Some',
                                           t: 'Diaries, errata', w: '(OCoLC)12345' }),
       marc_field(tag: '880', subfields: { '6': '770', a: 'Alt. Person', t: 'Alt. Title' })]
    end

    it 'return all subfield values for the field and linked alternate' do
      expect(helper.has_supplement_show(record)).to(
        contain_exactly(
          'Alt. Person Alt. Title', 'Supplement (work) Person, Some Diaries, errata (OCoLC)12345'
        )
      )
    end
  end
end
