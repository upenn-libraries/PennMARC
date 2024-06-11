# frozen_string_literal: true

module PennMARC
  # Export the record for citations: MLA, APA and Chicago
  class Export < Helper
    class << self
      # Returns the MLA citation text of the given record
      # @param [MARC::Record] record
      # @return [String]
      def mla_citation_text(record)
        text = ''

        # Authors
        text += format_authors(Creator.authors_list(record))

        # Title
        title = Title.show(record)
        unless title.blank?
          title += title.ends_with?('.') ? ' ' : '. '
          text += "<i>#{title}</i>"
        end

        # Edition
        edition = Edition.show(record, with_alternate: false).join
        text += "#{edition}. " unless edition.blank?

        # Publication
        publication = Production.publication_citation_show(record).join
        text + publication.to_s unless publication.blank?
      end

      # Returns the APA citation text of the given record
      # @param [MARC::Record] record
      # @return [String]
      def apa_citation_text(record)
        text = ''
        authors_list_final = []

        # Authors with first name initial
        authors = Creator.authors_list(record, first_initial_only: true)
        authors.each_with_index do |aut, idx |
          aut = aut.strip
          aut = aut.chop if aut.ends_with?(',')

          author_text = if idx.zero? # first
                          aut
                        elsif idx == authors.length - 1 # last
                          ", &amp; #{aut}"
                        else # all others
                          ", #{aut}"
                        end
          authors_list_final.push(author_text)
        end
        text += authors_list_final.join
        unless text.blank?
          text += text.last == '.' ? ' ' : '. '
        end

        # Pub Date
        pub_year = Date.publication(record).year
        text += "(#{pub_year}). " unless pub_year.blank?

        # Title
        title = Title.show(record)
        unless title.blank?
          title += title.ends_with?('.') ? ' ' : '. '
          text += "<i>#{title}</i>"
        end

        # Edition
        edition = Edition.show(record, with_alternate: false).join
        text += "#{edition}. " unless edition.blank?

        # Publisher info
        publisher = Production.publication_citation_show(record, with_year: false).join
        unless publisher.blank?
          # if ends with ',' remove it
          publisher.chop! if publisher.ends_with?(',')
          text += "#{publisher}."
        end

        text
      end

      # Returns the Chicago citation text of the given record
      # @param [MARC::Record] record
      # @return [String]
      def chicago_citation_text(record)
        text = ''

        contributors = Creator.contributors_list(record, include_authors: true)

        authors = contributors['Author']
        translators = contributors['Translator']
        editors = contributors['Editor']
        compilers = contributors['Compiler']

        text += format_authors(authors) unless authors.blank?

        # Title
        title = Title.show(record)
        unless title.blank?
          title += title.ends_with?('.') ? ' ' : '. '
          text += "<i>#{title}</i>"
        end

        additional_title = ''
        unless translators.blank?
          additional_title += "Translated by #{translators.collect { |name|
                                                 convert_name_order(name)
                                               }.join(' and ')}. "
        end
        unless editors.blank?
          additional_title += "Edited by #{editors.collect { |name|
                                             convert_name_order(name)
                                           }.join(' and ')}. "
        end
        unless compilers.blank?
          additional_title += "Compiled by #{compilers.collect { |name|
                                               convert_name_order(name)
                                             }.join(' and ')}. "
        end

        text += additional_title unless additional_title.blank?

        # Edition
        edition = Edition.show(record, with_alternate: false).join
        text += "#{edition}. " unless edition.blank?

        # Publication
        publication = Production.publication_citation_show(record).join
        text + publication.to_s unless publication.blank?
      end

      private

      # Format the author names text based on the total number of authors
      # @param [Array<string>] authors: array of the author names
      # @return [String]
      def format_authors(authors)
        text = ''
        authors_final = []

        if authors.length >= 4
          text += "#{authors.first}, et al. "
        else
          authors.each_with_index do |aut, idx|
            aut = aut.strip
            aut = aut.chop if aut.ends_with?(',')

            author_text = if idx.zero? # first
                            aut
                          elsif idx == authors.length - 1 # last
                            ", and #{convert_name_order(aut)}."
                          else # all others
                            ", #{convert_name_order(aut)}"
                          end
            authors_final.push(author_text)
          end
        end
        text += authors_final.join
        unless text.blank?
          text += text.last == '.' ? ' ' : '. '
        end

        text
      end

      # Convert "Lastname, First" to "First Lastname"
      # @param [String] name value for processing
      # @return [String]
      def convert_name_order(name)
        return name unless name.include? ','

        after_comma = join_and_squish([trim_trailing(:comma, substring_after(name, ', '))])
        before_comma = substring_before(name, ', ')
        "#{after_comma} #{before_comma}".squish
      end

    end
  end
end
