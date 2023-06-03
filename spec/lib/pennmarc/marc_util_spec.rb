# frozen_string_literal: true

describe 'PennMARC::Util' do
  subject(:util) do
    Class.new { extend PennMARC::Util }
  end

  describe '.join_subfields' do
    let(:field) do # TODO: add convenience method for building fragments to marc_spec_helpers.rb
      subfields = [MARC::Subfield.new('a', 'bad')]
      subfields << MARC::Subfield.new('1', 'join')
      subfields << MARC::Subfield.new('3', '')
      subfields << MARC::Subfield.new('9', 'subfields')
      MARC::DataField.new('TST', ' ', ' ', *subfields)
    end

    it 'joins subfield values after selecting values using a block' do
      subfield_numeric = ->(subfield) { subfield.code =~ /[0-9]/ }
      expect(util.join_subfields(field, &subfield_numeric)).to eq 'join subfields'
    end
  end
end