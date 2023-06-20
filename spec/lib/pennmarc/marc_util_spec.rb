# frozen_string_literal: true

describe 'PennMARC::Util' do
  include MarcSpecHelpers

  subject(:util) do
    Class.new { extend PennMARC::Util }
  end

  describe '.join_subfields' do
    let(:field) do
      marc_field subfields: { a: 'bad', '1': 'join', '3': '', '9': 'subfields' }
    end

    it 'joins subfield values after selecting values using a block' do
      subfield_numeric = ->(subfield) { subfield.code =~ /[0-9]/ }
      expect(util.join_subfields(field, &subfield_numeric)).to eq 'join subfields'
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
