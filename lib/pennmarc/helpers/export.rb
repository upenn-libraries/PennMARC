# frozen_string_literal: true

# Export the record for citations: MLA, APA and Chicago

module PennMARC

  class Export < Helper
    class << self

      def mla_citation_text(record)
        text = ''
        authors_final = []

        # Authors
        authors = Creator.authors_list(record)
        unless authors.blank?
          if authors.length < 4
            authors.each do |l|
              if l == authors.first # first
                authors_final.push(l)
              elsif l == authors.last # last
                authors_final.push(", and #{name_reverse(l)}.")
              else # all others
                authors_final.push(", #{name_reverse(l)}")
              end
            end
            text += authors_final.join
            unless text.blank?
              text += text.last == '.' ? ' ' : '. '
            end
          else
            text += "#{authors.first}, et al. "
          end
        end

        # Title
        title = Title.show(record)
        text += "<i>#{title}</i> " unless title.nil?

        # Edition
        edition = Edition.values(record)
        text += "#{edition}. " unless edition.nil?

        # Publication
        publication = Production.publication_values(record)[0]
        text + publication.to_s unless publication.nil?
      end

      def apa_citation_text(record)
        text = ''
        authors_list_final = []

        # Authors with first name initial
        authors = Creator.authors_list(record, first_initial_only: true)
        authors.each do |l|
          if l == authors.first # first
            authors_list_final.push(l.strip)
          elsif l == authors.last # last
            authors_list_final.push(", &amp; #{l.strip}")
          else # all others
            authors_list_final.push(", #{l.strip}")
          end
        end
        text += authors_list_final.join
        unless text.blank?
          text += text.last == '.' ? ' ' : '. '
        end

        # Pub Date
        pub_date = Date.publication(record).year
        text += "(#{pub_date}). " unless pub_date.nil?

        # Title
        title = Title.show(record)
        text += "<i>#{title}</i> " unless title.nil?

        # Edition
        edition = Edition.values(record)
        text += "#{edition}. " unless edition.nil?

        # Publisher info
        publisher = Production.publication_values(record)[0]
        text += publisher.to_s unless publisher.nil?

        text
      end

      def chicago_citation_text(record)
        text = ''
        authors_final = []

        contributors = Creator.contributors_list(record, include_authors: true)

        authors = contributors['Author']
        translators = contributors['Translator']
        editors = contributors['Editor']
        compilers = contributors['Compiler']

        unless authors.blank?
          if authors.length < 4
            authors.each do |l|
              if l == authors.first # first
                authors_final.push(l)
              elsif l == authors.last # last
                authors_final.push(", and #{name_reverse(l)}.")
              else # all others
                authors_final.push(", #{name_reverse(l)}")
              end
            end
            text += authors_final.join
            unless text.blank?
              text += text.last == '.' ? ' ' : '. '
            end
          else
            text += "#{authors.first}, et al. "
          end
        end

        # Title
        title = Title.show(record).to_s
        text += "<i>#{title}</i> "

        additional_title = ''
        if !authors.blank? && (!translators.blank? || !editors.blank? || !compilers.blank?)
          additional_title += "Translated by #{translators.collect { |name| name_reverse(name) }.join(' and ')}. " unless translators.blank?
          additional_title += "Edited by #{editors.collect { |name| name_reverse(name) }.join(' and ')}. " unless editors.blank?
          additional_title += "Compiled by #{compilers.collect { |name| name_reverse(name) }.join(' and ')}. " unless compilers.blank?
        end

        text += additional_title unless additional_title.blank?

        # Edition
        edition = Edition.values(record)
        text += "#{edition}. " unless edition.nil?
        
        # Publication
        publication = Production.publication_values(record)[0]
        text + publication.to_s unless publication.nil?
      end

      private

      def name_reverse(name)
        name = clean_end_punctuation(name)
        return name if name == ', ' || !(name =~ /,/)

        temp_name = name.split(', ')
        "#{temp_name.last} #{temp_name.first}"
      end

      def clean_end_punctuation(text)
        return text[0, text.length - 1] if %w[. , : ; /].include? text[-1, 1]

        text
      end
    end
  end
end
