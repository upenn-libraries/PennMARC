# frozen_string_literal: true

describe 'PennMARC::HeadingControl' do
  let(:replace_term) { PennMARC::Mappers.heading_overrides.keys[2] }
  let(:replaced_term) { PennMARC::Mappers.heading_overrides.values[2] }
  let(:remove_term) { PennMARC::Mappers.headings_to_remove.first }

  describe '.process' do
    context 'with a term for removal' do
      it 'removes the term if found in isolation' do
        values = [remove_term]
        expect(PennMARC::HeadingControl.term_override(values)).to eq []
      end

      it 'removes the term regardless of case' do
        values = [remove_term.downcase]
        expect(PennMARC::HeadingControl.term_override(values)).to eq []
      end

      it 'removes the term if it is included as a substring' do
        values = ["#{remove_term}--History"]
        expect(PennMARC::HeadingControl.term_override(values)).to eq []
      end
    end

    PennMARC::Mappers.heading_overrides.each do |target, replacement|
      context "with the \"#{target}\" term" do
        it 'replaces the term in isolation' do
          values = [target]
          expect(PennMARC::HeadingControl.term_override(values)).to eq [replacement]
        end

        it 'replaces the term when used with other headings' do
          values = ["#{target}--History"]
          expect(PennMARC::HeadingControl.term_override(values)).to eq ["#{replacement}--History"]
        end

        it 'replaces the term regardless of case' do
          values = ["#{target.downcase}--History"]
          expect(PennMARC::HeadingControl.term_override(values)).to eq ["#{replacement}--History"]
        end
      end
    end

    context 'with a variety of terms' do
      it 'removes and replaces terms as needed' do
        values = [remove_term, replace_term, 'History']
        expect(PennMARC::HeadingControl.term_override(values)).to contain_exactly 'History', replaced_term
      end
    end
  end
end
