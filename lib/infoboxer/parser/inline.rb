# encoding: utf-8
require_relative './image'
require_relative './template'

# http://www.mediawiki.org/wiki/Help:Formatting
module Infoboxer
  class Parser
    class InlineParser
      def self.parse(*arg)
        new(*arg).parse
      end

      def self.try_parse(str)
        new(str).parse
      rescue ParseError => e
        Nodes.new([Parser::Text.new(str)]) # TODO: Parser::Unparsed.new(str)
      end
      
      def initialize(str, next_lines = [])
        @str, @next_lines = str, next_lines

        @scanner = StringScanner.new(str)
        @nodes = Nodes.new
      end

      def parse
        @text = ''
        formatting_start = /('{2,5}|\[\[|{{|{\||\[|<)/
        until scanner.eos?
          str = scanner.scan_until(formatting_start)
          @text << str.sub(scanner.matched, '') if str

          match = scanner.matched
          case match
          when "'''''"
            node(BoldItalic, inline(scan_simple(/'''''/)))
          when "'''"
            node(Bold, inline(scan_simple(/'''/)))
          when "''"
            node(Italic, inline(scan_simple(/''/)))
          when '[['.matchish.guard{ scanner.check(/(Image|File):/) }
            image(scan(/\[\[/, /\]\]/))
          when '[['
            wikilink(scan(/\[\[/, /\]\]/))
          when '['
            external_link(scan(/\[/, /\]/))
          when '{{'
            template(scan(/{{/, /}}/))
          when '<'
            try_html ||
              @text << match # it was not HTML, just accidental <
          when nil
            @text << scanner.rest
            break
          end        
        end
        ensure_text!
        @nodes
      rescue => e
        raise e.exception("Error while parsing #{@str}: #{e.message}").
          tap{|e_| e_.set_backtrace(e.backtrace)}
      end

      private

      def inline(str)
        InlineParser.new(str, @next_lines).parse
      end

      # simple scan: just text until pattern
      def scan_simple(after)
        scanner.scan_until(after).tap{|res|
          res or fail(ParseError, "#{after} not found in #{scanner.rest}")
        }.sub(after, '')
      end

      include Commons

      def scan(before, after)
        scan_continued(scanner, before, after, @next_lines)
      end

      def image(str)
        node(Image, *ImageParser.new(str).parse)
      end

      def template(str)
        node(Template, *TemplateParser.new(str).parse)
      end

      # http://en.wikipedia.org/wiki/Help:Link#Wikilinks
      # [[abc]]
      # [[a|b]]
      def wikilink(str)
        link, label = str.split('|', 2)
        node(Wikilink, link || str, label)
      end

      # http://en.wikipedia.org/wiki/Help:Link#External_links
      # [http://www.example.org]
      # [http://www.example.org link name]
      def external_link(str)
        link, label = str.split(/\s+/, 2)
        node(ExternalLink, link || str, label)
      end

      def try_html
        case
        when scanner.check(/\/[a-z]+>/)
          # lonely closing tag
          scanner.skip(/\//)
          tag = scanner.scan(/[a-z]+/)
          scanner.skip(/>/)
          node(HTMLClosingTag, tag)

        when scanner.check(/[a-z]+[^>]+\/>/)
          # auto-closing tag
          tag = scanner.scan(/[a-z]+/)
          arguments = scanner.scan(/[^>]+/)
          scanner.skip(/\/>/)
          node(HTMLTag, tag, arguments)

        when scanner.check(/[a-z]+[^>\/]+>/)
          # opening tag
          tag = scanner.scan(/[a-z]+/)
          arguments = scanner.scan(/[^>]+/)
          scanner.skip(/>/)
          if (contents = scanner.scan_until(/<\/#{tag}>/))
            node(HTMLTag, tag, arguments, inline(contents.sub("</#{tag}>", '')))
          else
            node(HTMLOpeningTag, tag, arguments)
          end
        else
          # not an HTML tag at all!
          return false
        end

        true
      end

      attr_reader :scanner

      def node(klass, *arg)
        ensure_text!
        @nodes.push(klass.new(*arg))
      end

      def ensure_text!
        unless @text.empty?
          @nodes.push(Text.new(@text))
          @text = ''
        end
      end
    end
  end
end
