# frozen_string_literal: true

describe 'PennMARC::Link' do
  include MarcSpecHelpers

  let(:helper) { PennMARC::Link }

  describe '.full_text_link' do
    let(:record) do
      marc_record fields: [marc_field(tag: '856', subfields: { '3': 'Materials specified',
                                                               z: 'Public note',
                                                               y: 'Link text',
                                                               u: 'https://www.test-uri.com/' },
                                      indicator1: '4', indicator2: '0')]
    end

    it 'returns full text link text and url' do
      expect(helper.full_text_links(record)).to contain_exactly({ link_text: 'Materials specified Public note',
                                                                 link_url: 'https://www.test-uri.com/' })
    end
  end

  describe '.web_link' do
    let(:record) do
      marc_record fields: [marc_field(tag: '856', subfields: { '3': 'Materials specified',
                                                               z: 'Public note',
                                                               y: 'Link text',
                                                               u: 'https://www.test-uri.com/' },
                                      indicator1: '4', indicator2: '')]
    end

    it 'returns web link text and url' do
      expect(helper.web_links(record)).to contain_exactly({ link_text: 'Materials specified Public note',
                                                           link_url: 'https://www.test-uri.com/' })
    end
  end
end
