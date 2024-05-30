# frozen_string_literal: true

module PennMARC
  # Export the record for citations: MLA, APA and Chicago
  class Export < Helper
    class << self
      def mla_citation_text(record)
        text = ''

        # Authors
        text += format_authors(Creator.authors_list(record))

        # Title
        title = Title.show(record)
        text += "<i>#{title}</i> " unless title.nil?

        # Edition
        edition = Edition.show(record).join
        text += "#{edition}. " unless edition.nil?

        # Publication
        publication = Production.publication_show(record).join
        text + publication.to_s unless publication.nil?
      end

      def apa_citation_text(record)
        text = ''
        authors_list_final = []

        # Authors with first name initial
        authors = Creator.authors_list(record, first_initial_only: true)
        authors.each do |l|
          author_text = if l == authors.first # first
                          l.strip
                        elsif l == authors.last # last
                          ", &amp; #{l.strip}"
                        else # all others
                          ", #{l.strip}"
                        end
          authors_list_final.push(author_text)
        end
        text += authors_list_final.join
        unless text.blank?
          text += text.last == '.' ? ' ' : '. '
        end

        # Publisher info
        publisher = Production.publication_show(record).join

        # if it ends with a year, try to remove it, and use the year for publication year
        publication_parts = publisher.split
        pub_year = publication_parts.last

        int_pub_year = nil
        if !pub_year.nil? && pub_year.length == 4
          int_pub_year = begin
            Integer pub_year
          rescue StandardError
            nil
          end
        end

        if int_pub_year.nil?
          pub_year = Date.publication(record).year
        else
          publication_parts.pop
          publisher = publication_parts.join(' ')
        end

        # Pub Date
        text += "(#{pub_year}). " unless pub_year.nil?

        # Title
        title = Title.show(record)
        text += "<i>#{title}</i> " unless title.nil?

        # Edition
        edition = Edition.show(record).join
        text += "#{edition}. " unless edition.nil?

        text + publisher.to_s unless publisher.nil?
      end

      def chicago_citation_text(record)
        text = ''

        contributors = Creator.contributors_list(record, include_authors: true)

        authors = contributors['Author']
        translators = contributors['Translator']
        editors = contributors['Editor']
        compilers = contributors['Compiler']

        text += format_authors(authors)

        # Title
        title = Title.show(record).to_s
        text += "<i>#{title}</i> "

        additional_title = ''
        if !authors.blank? && (!translators.blank? || !editors.blank? || !compilers.blank?)
          unless translators.blank?
            additional_title += "Translated by #{translators.collect { |name|
                                                   name_reverse(name)
                                                 }.join(' and ')}. "
          end
          unless editors.blank?
            additional_title += "Edited by #{editors.collect { |name|
                                               name_reverse(name)
                                             }.join(' and ')}. "
          end
          unless compilers.blank?
            additional_title += "Compiled by #{compilers.collect { |name|
                                                 name_reverse(name)
                                               }.join(' and ')}. "
          end
        end

        text += additional_title unless additional_title.blank?

        # Edition
        edition = Edition.show(record).join
        text += "#{edition}. " unless edition.nil?

        # Publication
        publication = Production.publication_show(record).join
        text + publication.to_s unless publication.nil?
      end

      private

      def format_authors(authors)
        text = ''
        authors_final = []

        if authors.length >= 4
          text += "#{authors.first}, et al. "
        else
          authors.each do |aut|
            author_text = if aut == authors.first # first
                            aut
                          elsif aut == authors.last # last
                            ", and #{name_reverse(aut)}."
                          else # all others
                            ", #{name_reverse(aut)}"
                          end
            authors_final.push(author_text)
          end
          text += authors_final.join
          unless text.blank?
            text += text.last == '.' ? ' ' : '. '
          end
        end

        text
      end

      def name_reverse(name)
        name = clean_end_punctuation(name)
        return name if name == ', ' || !name.include?(',')

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
