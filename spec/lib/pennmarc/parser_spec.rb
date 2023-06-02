# frozen_string_literal: true

describe PennMARC::Parser do
  include MarcSpecHelpers

  let(:record) { record_from 'test.xml' }

  # TODO: use a double as a helper and check received messages?

  subject(:parser) { described_class.new(mappings: []) }

  it 'delegates to helper modules properly' do
    expect(parser.title_show(record)).to eq 'The Coopers & Lybrand guide to business tax strategies and planning / by the partners of Coopers & Lybrand.'
  end
end
