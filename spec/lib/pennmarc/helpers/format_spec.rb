# frozen_string_literal: true

describe 'PennMARC::Format' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Format }

  describe '.facet' do
    let(:formats) { helper.facet(record) }

    context 'with an "Archive"' do
      context 'with an 852 field' do
        let(:record) do
          marc_record fields: [marc_field(tag: '852', subfields: { c: 'archarch' })]
        end

        it 'returns format values of "Archive"' do
          expect(formats).to include 'Archive'
        end
      end

      context 'with publishing enriched fields' do
        let(:record) do
          marc_record fields: [marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG, subfields: { g: 'archarch' })]
        end

        it 'returns format values of "Archive"' do
          expect(formats).to include 'Archive'
        end
      end

      context 'without encoded archive location' do
        let(:record) do
          marc_record fields: [marc_field(tag: '852', subfields: { c: 'notanarchive' }),
                               marc_field(tag: PennMARC::Enriched::Pub::ITEM_TAG, subfields: { g: 'notanarchive' })]
        end

        it 'does not return format values of "Archive"' do
          expect(formats).not_to include 'Archive'
        end
      end
    end

    context 'with a "Newspaper"' do
      let(:record) do
        marc_record leader: '      as',
                    fields: [marc_control_field(tag: '008', value: '                     n')]
      end

      it 'returns a facet value including "Newspaper" and "Journal/Periodical"' do
        expect(formats).to eq %w[Newspaper Journal/Periodical]
      end
    end

    context 'with a "Thesis" on "Microfilm"' do
      let(:record) do
        marc_record leader: '      tm',
                    fields: [
                      marc_field(tag: '245', subfields: { h: '[microfilm]' }),
                      marc_field(tag: '502', subfields: { a: 'Ed.D. Thesis' })
                    ]
      end

      it 'returns all format values that meet the format facet encoding rules' do
        expect(formats).to contain_exactly('Manuscript', 'Microformat', 'Thesis/Dissertation', 'Book')
      end
    end

    context 'with Microformats as determined by the holding call numbers' do
      context 'with API enriched fields' do
        let(:record) do
          marc_record fields: [
            marc_field(tag: PennMARC::Enriched::Api::PHYS_INVENTORY_TAG, subfields: {
                         :h => 'AB123',
                         PennMARC::Enriched::Api::PHYS_CALL_NUMBER_TYPE => '.456 Microfilm'
                       })
          ]
        end

        it 'returns a facet value of "Microformat"' do
          expect(formats).to eq ['Microformat']
        end
      end

      context 'with publishing enriched fields' do
        let(:record) do
          marc_record fields: [
            marc_field(tag: PennMARC::Enriched::Pub::PHYS_INVENTORY_TAG,
                       subfields: { :h => 'AB123',
                                    PennMARC::Enriched::Pub::ITEM_CALL_NUMBER_TYPE => '.456 Microfilm' })
          ]
        end

        it 'returns a facet value of "Microformat"' do
          expect(formats).to eq ['Microformat']
        end
      end
    end

    context 'with Microformats as determined by MARC control fields' do
      context 'with 007 field' do
        let(:record) do
          marc_record fields: [marc_control_field(tag: '007', value: 'h')]
        end

        it 'returns "Microformat"' do
          expect(formats).to contain_exactly('Microformat')
        end
      end

      context 'with 008 field and valid value at position 23' do
        let(:record) do
          marc_record fields: [
            marc_control_field(tag: '008', value: '                       a')
          ]
        end

        it 'returns "Microformat"' do
          expect(formats).to contain_exactly('Microformat')
        end
      end

      context 'with 008 field and valid value at position 29' do
        let(:record) do
          marc_record fields: [
            marc_control_field(tag: '008', value: '                             a')
          ]
        end

        it 'returns "Microformat"' do
          expect(formats).to contain_exactly('Microformat')
        end
      end
    end

    context 'with Microformats as determined by title medium' do
      let(:record) do
        marc_record(fields: [marc_field(tag: '245', subfields: { h: 'micro' })])
      end

      it 'returns "Microformat"' do
        expect(formats).to contain_exactly('Microformat')
      end
    end

    context 'with Microformats as determined by media type' do
      let(:record) do
        marc_record(fields: [marc_field(tag: '337', subfields: { a: 'microform' })])
      end

      it 'returns "Microformat"' do
        expect(formats).to contain_exactly('Microformat')
      end
    end

    context 'with "Manuscript"' do
      context 'with valid manuscript format code in leader' do
        let(:record) do
          marc_record(leader: '      t')
        end

        it 'returns "Manuscript"' do
          expect(formats).to contain_exactly('Manuscript')
        end
      end

      context 'without valid manuscript format code in leader' do
        let(:record) do
          marc_record(leader: '      a')
        end

        it 'does not return "Manuscript"' do
          expect(formats).not_to include('Manuscript')
        end
      end
    end

    context 'with a "Book"' do
      let(:record) do
        marc_record leader: '      aa',
                    fields: [marc_field(tag: '245', subfields: { k: 'blah' })]
      end

      it 'returns a facet value including only "Book"' do
        expect(formats).to eq ['Book']
      end

      context 'with a media type that contains "micro"' do
        let(:record) do
          marc_record leader: '      aa',
                      fields: [
                        marc_field(tag: '245', subfields: { k: 'blah' }),
                        marc_field(tag: '337', subfields: { a: 'microform' })
                      ]
        end

        it 'does not return a facet value including "Book"' do
          expect(formats).not_to include('Book')
        end
      end

      context 'with a 245 $k value of "kit"' do
        let(:record) do
          marc_record leader: '      tm',
                      fields: [
                        marc_field(tag: '245', subfields: { k: 'kit' })
                      ]
        end

        it 'does not return a facet value including "Book"' do
          expect(formats).not_to include('Book')
        end
      end
    end

    context 'with a "Projected Graphic"' do
      let(:record) do
        marc_record leader: '      gm',
                    fields: [marc_control_field(tag: '007', value: 'go hkaaa ')]
      end

      it 'returns a facet value including only "Projected graphic"' do
        expect(formats).to eq ['Projected graphic']
      end
    end

    context 'with a "Curated Format" set' do
      let(:record) do
        marc_record fields: [marc_field(tag: '944', subfields: { a: subfield_a_value })]
      end

      context 'with a format explicitly specified in 944 ǂa' do
        let(:subfield_a_value) { 'Book' }

        it 'returns a facet value including a curated format of "Book"' do
          expect(formats).to eq ['Book']
        end
      end

      context 'with a number in 944 ǂa' do
        let(:subfield_a_value) { '123' }

        it 'returns no content from 944 ǂa' do
          expect(formats).to eq ['Other']
        end
      end
    end

    context 'with Other' do
      context 'with another facet applied' do
        let(:record) do
          marc_record(leader: '      t')
        end

        it 'does not return "Other"' do
          expect(formats).not_to include 'Other'
        end
      end

      context 'without another facet applied' do
        let(:record) do
          marc_record(leader: '      z')
        end

        it 'returns "Other"' do
          expect(formats).to contain_exactly 'Other'
        end
      end
    end
  end

  describe '.show' do
    let(:record) { marc_record fields: fields }

    context 'with entry in the 300 field' do
      let(:fields) do
        [marc_field(tag: '300', subfields: { a: '1 volume', b: 'illustration, maps', c: '12cm', '3': 'excluded' }),
         marc_field(tag: '880', subfields: { '6': '300', a: 'Alt. Extent' })]
      end

      it 'returns the expected format values' do
        value = helper.show(record)
        expect(value).to contain_exactly '1 volume illustration, maps 12cm', 'Alt. Extent'
        expect(value.join(' ')).not_to include 'excluded'
      end
    end

    context 'with entry in the 255 field' do
      let(:fields) do
        [marc_field(tag: '255', subfields: { a: 'Scale 1:24,000', b: 'Mercator projection',
                                             c: '(W 150°--W 30°/N 70°--N 40°)' }),
         marc_field(tag: '880', subfields: { '6': '255', a: 'Alt. Scale', b: 'Alt. Projection' })]
      end

      it 'returns the expected format values' do
        expect(helper.show(record)).to contain_exactly 'Alt. Scale Alt. Projection',
                                                       'Scale 1:24,000 Mercator projection (W 150°--W 30°/N 70°--N 40°)'
      end
    end

    context 'with entries in the 340' do
      let(:fields) do
        [marc_field(tag: '340', subfields: { a: 'cassette tape', b: '90 min', '0': 'excluded' }),
         marc_field(tag: '880', subfields: { '6': '340', a: 'alt. extent' })]
      end

      it 'returns the expected format values' do
        value = helper.show(record)
        expect(value).to contain_exactly 'cassette tape 90 min', 'alt. extent'
        expect(value.join(' ')).not_to include 'excluded'
      end
    end

    context 'with an unrelated linked alternate' do
      let(:fields) do
        [marc_field(tag: '300', subfields: { a: '96 pages ;', c: '23 cm ' }),
         marc_field(tag: '880', subfields: { '6': '700', a: 'Schweizer, Shlomo,', d: '1903-',
                                             '0': 'https://id.loc.gov/authorities/names/no95018724' })]
      end

      it 'returns the expected format values' do
        value = helper.show(record)
        expect(value).to contain_exactly '96 pages ; 23 cm'
        expect(value.join(' ')).not_to include 'https://id.loc.gov/authorities/names/no95018724'
      end
    end
  end

  describe '.other_show' do
    let(:record) do
      marc_record fields: [marc_field(tag: '776', subfields: {
                                        i: 'Online edition', a: 'Author, Name', t: 'Title', b: 'First Edition',
                                        d: 'Some Publisher', w: '(OCoLC)12345', s: 'Uniform Title', o: '12345'
                                      }),
                           marc_field(tag: '880', subfields: {
                                        '6': '776', i: 'Alt. Online Edition', t: 'Alt. Title'
                                      })]
    end

    it 'returns other format information for display, with data from only ǂi, ǂa, ǂs, ǂt and ǂo' do
      expect(helper.other_show(record)).to contain_exactly 'Alt. Online Edition Alt. Title',
                                                           'Online edition Author, Name Title Uniform Title 12345'
    end
  end

  describe 'cartographic_show' do
    let(:record) do
      marc_record fields: [marc_field(tag: '255', subfields: {
                                        a: ' Scale 1:2,534,400. 40 mi. to an in.', b: 'polyconic projection',
                                        c: '(E 74⁰--E 84⁰/N 20⁰--N 12⁰).', d: 'Declination +90° to -90°',
                                        e: 'equinox 1950, epoch 1949-1958'
                                      }),
                           marc_field(tag: '342', subfields: { a: 'Polyconic', g: '0.9996', h: '0', i: '500,000',
                                                               j: '0' })]
    end

    it 'returns expected cartographic values' do
      expect(helper.cartographic_show(record)).to contain_exactly(
        'Polyconic 0.9996 0 500,000 0',
        'Scale 1:2,534,400. 40 mi. to an in. polyconic projection (E 74⁰--E 84⁰/N 20⁰--N 12⁰). Declination +90° to
         -90° equinox 1950, epoch 1949-1958'.squish
      )
    end
  end

  describe '.includes_manuscript?' do
    context 'with a valid manuscript format code' do
      let(:format_code) { 't' }

      it 'returns true' do
        expect(helper.include_manuscripts?(format_code)).to be true
      end
    end

    context 'without a valid manuscript format code' do
      let(:format_code) { 'at' }

      it 'returns false' do
        expect(helper.include_manuscripts?(format_code)).to be false
      end
    end
  end
end
