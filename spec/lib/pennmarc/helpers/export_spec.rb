describe 'PennMARC::Creator' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Export }
  let(:mapping) { { aut: 'Author' } }

  describe '.mla_citation_text' do

    let(:record) { marc_record fields: fields }

    context 'with a single author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345',
                                             e: 'author', d: '1900-2000', '4': 'aut' }),
         marc_field(tag: '100', subfields: { a: 'Hamilton, Alex', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Lincoln, Abraham', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                             j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                             '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Einstein, Albert', '6': '100', d: '1970-', '4': 'trl',
                                             e: 'translator' }),
         marc_field(tag: '700', subfields: { a: 'Franklin, Ben', '6': '100', d: '1970-', '4': 'edt' }),
         marc_field(tag: '710', subfields: { a: 'Jefferson, Thomas', '6': '100', d: '1870-', '4': 'edt' }),
         marc_field(tag: '700', subfields: { a: 'Dickens, Charles', '6': '100', d: '1970-', '4': 'com' }),
         marc_field(tag: '250', subfields: { a: '5th Edition', b: 'Remastered' }),
         marc_control_field(tag: '008', value: '130827s2010 nyu o 000 1 eng d'),
         marc_field(tag: '245', subfields: { a: 'Title', b: 'Subtitle', c: 'Responsibility', h: 'Medium' }),
         marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Productions', c: '2019' }, indicator2: '0'),
         marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1')]
      end

      it 'contains the expected search field values for a single author work' do
        values = helper.mla_citation_text(record)
        expect(values).to include('Surname, Name, et al.',
                                  '<i>Title Subtitle</i>',
                                  '5th Edition Remastered.',
                                  'Nowhere Wasteland Publishing 1999')
      end
    end
  end

  describe '.apa_citation_text' do

    let(:record) { marc_record fields: fields }

    context 'with multiple author record' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345',
                                             e: 'author', d: '1900-2000', '4': 'aut' }),
         marc_field(tag: '100', subfields: { a: 'Hamilton, Alex', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Lincoln, Abraham', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                             j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                             '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Einstein, Albert', '6': '100', d: '1970-', '4': 'trl',
                                             e: 'translator' }),
         marc_field(tag: '700', subfields: { a: 'Franklin, Ben', '6': '100', d: '1970-', '4': 'edt' }),
         marc_field(tag: '710', subfields: { a: 'Jefferson, Thomas', '6': '100', d: '1870-', '4': 'edt' }),
         marc_field(tag: '700', subfields: { a: 'Dickens, Charles', '6': '100', d: '1970-', '4': 'com' }),
         marc_field(tag: '250', subfields: { a: '5th Edition', b: 'Remastered' }),
         marc_control_field(tag: '008', value: '130827s2010 nyu o 000 1 eng d'),
         marc_field(tag: '245', subfields: { a: 'Title', b: 'Subtitle', c: 'Responsibility', h: 'Medium' }),
         marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Productions', c: '2019' }, indicator2: '0'),
         marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1')]
      end

      it 'contains the expected search field values for a single author work' do
        values = helper.apa_citation_text(record)
        expect(values).to include('Surname, N., Hamilton, A., Lincoln, A., Einstein, A., Franklin, B., &amp; Dickens, C.',
                                  '(2010).',
                                  '<i>Title Subtitle</i>',
                                  '5th Edition Remastered.',
                                  'Nowhere Wasteland Publishing 1999')
      end
    end
  end

  describe '.chicago_citation_text' do

    let(:record) { marc_record fields: fields }

    context 'with multiple author records' do
      let(:fields) do
        [marc_field(tag: '100', subfields: { a: 'Surname, Name', '0': 'http://cool.uri/12345',
                                             e: 'author', d: '1900-2000', '4': 'aut' }),
         marc_field(tag: '100', subfields: { a: 'Hamilton, Alex', '0': 'http://cool.uri/12345', d: '1900-2000',
                                             e: 'author.', '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Lincoln, Abraham', b: 'I', c: 'laureate', d: '1968', e: 'author',
                                             j: 'pseud', q: 'Fuller Name', u: 'affiliation', '3': 'materials',
                                             '4': 'aut' }),
         marc_field(tag: '700', subfields: { a: 'Einstein, Albert', '6': '100', d: '1970-', '4': 'trl',
                                             e: 'translator' }),
         marc_field(tag: '700', subfields: { a: 'Franklin, Ben', '6': '100', d: '1970-', '4': 'edt' }),
         marc_field(tag: '700', subfields: { a: 'Dickens, Charles', '6': '100', d: '1970-', '4': 'com' }),
         marc_field(tag: '250', subfields: { a: '5th Edition', b: 'Remastered' }),
         marc_control_field(tag: '008', value: '130827s2010 nyu o 000 1 eng d'),
         marc_field(tag: '245', subfields: { a: 'Title', b: 'Subtitle', c: 'Responsibility', h: 'Medium' }),
         marc_field(tag: '264', subfields: { a: 'Leeds', b: 'Peepal Tree Productions', c: '2019' }, indicator2: '0'),
         marc_field(tag: '264', subfields: { a: 'Nowhere', b: 'Wasteland Publishing', c: '1999' }, indicator2: '1')]
      end

      it 'contains the expected search field values for a single author work' do
        expect(helper.chicago_citation_text(record)).to include('Surname, Name, Alex Hamilton, and Abraham Lincoln.',
                                                                '<i>Title Subtitle</i>',
                                                                'Translated by Albert Einstein',
                                                                'Edited by Ben Franklin',
                                                                'Compiled by Charles Dickens.',
                                                                '5th Edition Remastered.',
                                                                'Nowhere Wasteland Publishing 1999')
      end
    end
  end
end


