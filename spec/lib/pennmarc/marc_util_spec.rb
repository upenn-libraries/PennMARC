# frozen_string_literal: true

describe 'PennMARC::Util' do
  include MarcSpecHelpers

  subject(:util) do
    Class.new { extend PennMARC::Util }
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
      expect(util.subfield_value?(field, 'a', /123/)).to be_truthy
    end

    it 'returns false if the subfield value does not match the regex' do
      expect(util.subfield_value?(field, 'a', /\D/)).to be_falsey
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
      expect(util.subfield_defined?(field, :a)).to be_truthy
      expect(util.subfield_defined?(field, 'a')).to be_truthy
    end

    it 'returns false if a subfield is not present on a field' do
      expect(util.subfield_defined?(field, :b)).to be_falsey
    end
  end

  describe '.subfield_undefined?' do
    let(:field) { marc_field subfields: { a: 'Defined' } }

    it 'returns true if subfield is not present on a field' do
      expect(util.subfield_undefined?(field, :b)).to be_truthy
      expect(util.subfield_undefined?(field, 'b')).to be_truthy
    end

    it 'returns false if a subfield is present on a field' do
      expect(util.subfield_undefined?(field, :a)).to be_falsey
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
    it 'removes the parantheses value from subfield i' do
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
end
