# frozen_string_literal: true

describe 'PennMARC::HeadingControl' do
  let(:replace_term) { PennMARC::Mappers.heading_overrides.keys[2] }
  let(:replaced_term) { PennMARC::Mappers.heading_overrides.values[2] }
  let(:remove_term) { PennMARC::Mappers.headings_to_remove.first }

  describe '.process' do
    context 'with a term for removal' do
      it 'removes the term if found in isolation' do
        expect(PennMARC::HeadingControl.term_override(remove_term)).to be_nil
      end

      it 'removes the term regardless of case' do
        expect(PennMARC::HeadingControl.term_override(remove_term.downcase)).to be_nil
      end

      it 'removes the term if it is included as a substring' do
        value = "#{remove_term}--History"
        expect(PennMARC::HeadingControl.term_override(value)).to be_nil
      end
    end

    PennMARC::Mappers.heading_overrides.each do |target, replacement|
      context "with the \"#{target}\" term" do
        it 'replaces the term in isolation' do
          expect(PennMARC::HeadingControl.term_override(target)).to eq replacement
        end

        it 'replaces the term when used with other headings' do
          value = "#{target}--History"
          expect(PennMARC::HeadingControl.term_override(value)).to eq "#{replacement}--History"
        end

        it 'replaces the term regardless of case' do
          value = "#{target.titleize}--History"
          expect(PennMARC::HeadingControl.term_override(value)).to eq "#{replacement}--History"
        end
      end
    end
  end
end
