# frozen_string_literal: true

describe 'PennMARC::Format' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Format }

  describe '.other_show' do
    let(:record) do
      marc_record fields: [marc_field(tag: '776', subfields: {
                                        i: 'Online edition', a: 'Author, Name', t: 'Title', b: 'First Edition',
                                        d: 'Some Publisher', w: '(OCoLC)12345'
                                      }),
                           marc_field(tag: '880', subfields: {
                                        '6': '776', i: 'Alt. Online Edition', t: 'Alt. Title'
                                      })]
    end

    it 'returns other format information for display, with data from only ǂi, ǂa, ǂs, ǂt and ǂo' do
      expect(helper.other_show(record)).to contain_exactly 'Online edition Author, Name Title',
                                                           'Alt. Online Edition Alt. Title'
    end
  end
end
