# frozen_string_literal: true

describe 'PennMARC::Util' do
  include MarcSpecHelpers

  subject(:util) do
    Class.new { extend PennMARC::Util }
  end

  describe '.field_defined?' do
    let(:record) { marc_record fields: [marc_field(tag: '100')] }

    it 'returns true if the field is present in the record' do
      expect(util.field_defined?(record, '100')).to be true
    end

    it 'returns false if the field is not present in the record' do
      expect(util.field_defined?(record, '101')).to be false
    end
  end

  describe '.join_subfields' do
    let(:field) { marc_field subfields: { a: 'bad', '1': 'join', '3': '', '9': 'subfields' } }

    it 'joins subfield values after selecting values using a block' do
      subfield_numeric = ->(subfield) { subfield.code =~ /[0-9]/ }
      expect(util.join_subfields(field, &subfield_numeric)).to eq 'join subfields'
    end
  end

  describe '.subfield_value?' do
    let(:field) { marc_field subfields: { a: '123' } }

    it 'returns true if the specified subfield value matches the regex' do
      expect(util).to be_subfield_value(field, 'a', /123/)
    end

    it 'returns false if the subfield value does not match the regex' do
      expect(util).not_to be_subfield_value(field, 'a', /\D/)
    end
  end

  describe '.subfield_value_in?' do
    let(:field) { marc_field subfields: { a: '123' } }

    it 'returns true if value is in array' do
      expect(util.subfield_value_in?(field, 'a', ['123'])).to be true
    end
  end

  describe '.subfield_in?' do
    it 'returns a lambda that checks if a subfield code is a member of the array' do
      array = %w[a b c]
      subfield_in = util.subfield_in?(array)

      subfield = marc_subfield('a', 'Value')
      expect(subfield_in.call(subfield)).to be_truthy

      subfield = marc_subfield('d', 'Value')
      expect(subfield_in.call(subfield)).to be_falsey
    end
  end

  describe '#subfield_not_in?' do
    it 'returns a lambda that checks if a subfield code is not a member of the array' do
      array = %w[a b c]
      subfield_not_in = util.subfield_not_in?(array)

      subfield = marc_subfield('a', 'Value')
      expect(subfield_not_in.call(subfield)).to be_falsey

      subfield = marc_subfield('d', 'Value')
      expect(subfield_not_in.call(subfield)).to be_truthy
    end
  end

  describe '.subfield_defined?' do
    let(:field) { marc_field subfields: { a: 'Defined' } }

    it 'returns true if subfield is present on a field' do
      expect(util).to be_subfield_defined(field, :a)
      expect(util).to be_subfield_defined(field, 'a')
    end

    it 'returns false if a subfield is not present on a field' do
      expect(util).not_to be_subfield_defined(field, :b)
    end
  end

  describe '.subfield_undefined?' do
    let(:field) { marc_field subfields: { a: 'Defined' } }

    it 'returns true if subfield is not present on a field' do
      expect(util).to be_subfield_undefined(field, :b)
      expect(util).to be_subfield_undefined(field, 'b')
    end

    it 'returns false if a subfield is present on a field' do
      expect(util).not_to be_subfield_undefined(field, :a)
    end
  end

  describe '.subfield_values' do
    let(:field) { marc_field subfields: { a: %w[A B C], b: 'Not Included' } }

    it 'returns subfield values from a given field' do
      expect(util.subfield_values(field, :a)).to eq %w[A B C]
    end
  end

  describe '.subfield_values_for' do
    let(:record) do
      marc_record fields: [marc_field(tag: '123', subfields: { a: %w[A B C], b: 'Not Included' }),
                           marc_field(tag: '123', subfields: { a: 'D' }),
                           marc_field(tag: '333', subfields: { a: 'Maybe', b: 'Nope' })]
    end

    it 'returns subfield values from only the specified tag and subfield' do
      expect(util.subfield_values_for(tag: '123', subfield: :a, record: record)).to eq %w[A B C D]
    end

    it 'returns subfield values from only the specified tags and subfield' do
      expect(util.subfield_values_for(tag: %w[123 333], subfield: :a, record: record)).to eq %w[A B C D Maybe]
    end
  end

  describe '.trim_trailing' do
    it 'trims the specified trailer from the string' do
      expect(util.trim_trailing(:semicolon, 'Hello, world!  ;')).to eq('Hello, world!')
    end
  end

  describe '.linked_alternate' do
    let(:record) do
      marc_record fields: [marc_field(tag: '254', subfields: { a: 'The Bible', b: 'Test' }),
                           marc_field(tag: '880', subfields: { '6': '254', a: 'La Biblia', b: 'Prueba' })]
    end

    it 'returns the linked alternate' do
      expect(util.linked_alternate(record, '254', &util.subfield_in?(%w[a b]))).to contain_exactly('La Biblia Prueba')
    end
  end

  describe '.linked_alternate_not_6_or_8' do
    let(:record) do
      marc_record fields: [marc_field(tag: '510', subfields: { a: 'Perkins', b: 'Test' }),
                           marc_field(tag: '880', subfields: { '6': '510', '8': 'Ignore', a: 'Snikrep', b: 'Tset' })]
    end

    it 'returns the linked alternate without 6 or 8' do
      expect(util.linked_alternate_not_6_or_8(record, '510')).to contain_exactly('Snikrep Tset')
    end
  end

  describe '.datafield_and_linked_alternate' do
    let(:record) do
      marc_record fields: [marc_field(tag: '510', subfields: { a: 'Perkins' }),
                           marc_field(tag: '880', subfields: { '6': '510', a: 'Snikrep' })]
    end

    it 'returns the datafield and linked alternate' do
      expect(util.datafield_and_linked_alternate(record, '510')).to contain_exactly('Perkins', 'Snikrep')
    end
  end

  describe '.substring_before' do
    it 'returns the entire substring after the first occurrence of the target' do
      string = 'string.with.periods'
      expect(util.substring_before(string, '.')).to eq 'string'
    end
  end

  describe '.substring_after' do
    it 'returns the entire substring after the first occurrence of the target' do
      string = 'string.with.periods'
      expect(util.substring_after(string, '.')).to eq 'with.periods'
    end
  end

  describe '.join_and_squish' do
    it 'joins and squishes' do
      expect(util.join_and_squish(['ruby   ', '   is', '  cool  '])).to eq 'ruby is cool'
    end
  end

  describe '.remove_paren_value_from_subfield_i' do
    let(:field) { marc_field(tag: '666', subfields: { i: 'Test(Remove).' }) }

    it 'removes the parentheses value from subfield i' do
      expect(util.remove_paren_value_from_subfield_i(field)).to eq('Test')
    end
  end

  describe '.translate_relator' do
    let(:mapping) { { aut: 'Author' } }

    it 'translates the code into the relator' do
      expect(util.translate_relator(:aut, mapping)).to eq('Author')
    end
  end

  describe '.prefixed_subject_and_alternate' do
    let(:record) do
      marc_record fields: [
        marc_field(tag: '650', indicator2: '4', subfields: { a: 'PRO Heading' }),
        marc_field(tag: '650', indicator2: '4', subfields: { a: 'Regular Local Heading' }),
        marc_field(tag: '650', indicator2: '1', subfields: { a: 'LoC Heading' }),
        marc_field(tag: '880', indicator2: '4', subfields: { '6': '650', a: 'PRO Alt. Heading' }),
        marc_field(tag: '880', indicator2: '4', subfields: { '6': '999', a: 'Another Alt.' })
      ]
    end

    it 'only includes valid headings' do
      values = util.prefixed_subject_and_alternate(record, 'PRO')
      expect(values).to include 'Heading', 'Alt. Heading'
      expect(values).not_to include 'Regular Local Heading', 'LoC Heading', 'Another Alt.'
    end
  end

  describe '.field_or_its_linked_alternate?' do
    let(:field) { marc_field(tag: '100', subfields: { a: 'Sylvia Wynter' }) }
    let(:linked_alternate) { marc_field(tag: '880', subfields: { '6': '100' }) }

    it "returns true when tags include the field's tag" do
      expect(util.field_or_its_linked_alternate?(field, %w[100 200])).to be true
    end

    it "returns true when tags include linked alternate's $6 value" do
      expect(util.field_or_its_linked_alternate?(linked_alternate, %w[100 200])).to be true
    end

    it "returns false when tags exclude the field's tag" do
      expect(util.field_or_its_linked_alternate?(field, %w[200 300])).to be false
    end

    it "returns false when tags exclude the linked alternate's $6 value" do
      expect(util.field_or_its_linked_alternate?(linked_alternate, %w[200 300])).to be false
    end
  end

  describe '.relator_join_separator' do
    it 'returns a space when string ends with an open date' do
      expect(util.relator_join_separator('Nalo Hopkinson 1960-')).to be ' '
    end

    it 'returns a comma and a space (", ") when string does not end with an open date' do
      expect(util.relator_join_separator('Audre Lorde 1934-1992')).to be ', '
    end

    context 'when a word character precedes the open date' do
      it 'returns a comma and a space (", ")' do
        expect(util.relator_join_separator('word120-')).to be ', '
      end
    end
  end

  describe '.relator_term_subfield' do
    context 'with a field that uses $j for relator term' do
      let(:field) { marc_field(tag: '111', subfields: { a: 'Code4Lib' }) }

      it 'returns "j"' do
        expect(util.relator_term_subfield(field)).to eq 'j'
      end
    end

    context 'with any field that does not use $j for relator term' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'J.R.R. Tolkien' }) }

      it 'defaults to "e"' do
        expect(util.relator_term_subfield(field)).to eq 'e'
      end
    end
  end

  describe '.append_relator' do
    let(:joined_subfields) { field.subfields.first.value }
    let(:relator_map) { { aut: 'Author', ill: 'Illustrator' } }
    let(:result) { util.append_relator(field: field, joined_subfields: joined_subfields, relator_map: relator_map) }

    context 'when joined subfield values ends with a a comma' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex,', '4': 'aut' }) }

      it 'removes the trailing comma before joining the relator' do
        expect(result).to eq 'Capus, Alex, Author.'
      end
    end

    context 'with relator term and translatable relator code' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex', e: 'editor', '4': 'aut' }) }

      it 'only appends translatable relator' do
        expect(result).to eq 'Capus, Alex, Author.'
      end
    end

    context 'with multiple translatable relator codes' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex', e: 'editor', '4': %w[aut ill doi] }) }

      it 'appends all translatable relators with expected punctuation' do
        expect(result).to eq 'Capus, Alex, Author, Illustrator.'
      end
    end

    context 'with multiple relator terms' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex', e: %w[author illustrator] }) }

      it 'appends all translatable relators with expected punctuation' do
        expect(result).to eq 'Capus, Alex, author, illustrator.'
      end
    end

    context 'without translatable relator code' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex,', e: %w[author illustrator], '4': 'doi' }) }

      it 'appends relator term' do
        expect(result).to eq 'Capus, Alex, author, illustrator.'
      end
    end

    context 'when relator term has trailing period' do
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex,', e: 'author.' }) }

      it 'punctuates the value as expected' do
        expect(result).to eq 'Capus, Alex, author.'
      end
    end

    context 'when joined subfield values ends with an open date' do
      let(:joined_subfields) { [field.subfields.first.value, field.subfields.second.value].join(' ') }
      let(:field) { marc_field(tag: '100', subfields: { a: 'Capus, Alex,', d: '1808-', '4': %w[aut ill] }) }

      it 'uses a space when appending the relator' do
        expect(result).to eq 'Capus, Alex, 1808- Author, Illustrator.'
      end
    end
  end
end
