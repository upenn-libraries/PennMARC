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

  describe '.subfield_value?' do
    let(:field) { marc_field subfields: { a: '123' } }

    it 'returns true if the specified subfield value matches the regex' do
      expect(util.subfield_value?(field, 'a', /123/)).to be_truthy
    end

    it 'returns false if the subfield value does not mach he regex' do
      expect(util.subfield_value?(field, 'a', /\D/)).to be_falsey
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
end
