# frozen_string_literal: true

describe PennMARC::Parser do
  include MarcSpecHelpers

  subject(:parser) { described_class.new }

  let(:record) { record_from 'test.xml' }

  it 'delegates to helper modules properly' do
    expect { parser.title_show(record) }.not_to raise_exception
  end
end
