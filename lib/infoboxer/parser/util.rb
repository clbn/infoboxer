# encoding: utf-8
module Infoboxer
  class Parser
    module Util
      attr_reader :re

      FORMATTING = /(
        '{2,5}        |     # bold, italic
        \[\[          |     # link
        {{            |     # template
        \[[a-z]+:\/\/ |     # external link
        <nowiki[^>]*> |     # reference
        <ref[^>]*>    |     # nowiki
        <                   # HTML tag
      )/x

      INLINE_EOL = %r[(?=   # if we have ahead... (not scanned, just checked
        </ref>        |     # <ref> closed
        }}                  # or template closed
      )]x


      def make_regexps
        {
          file_prefix: /(#{@context.traits.file_prefix.join('|')}):/,
          formatting: FORMATTING,
          inline_until_cache: Hash.new{|h, r|
            h[r] = Regexp.union(*[r, FORMATTING, /$/].compact.uniq)
          },
          short_inline_until_cache: Hash.new{|h, r|
            h[r] = Regexp.union(*[r, INLINE_EOL, FORMATTING, /$/].compact.uniq)
          }
        }
      end

      def parse_params(str)
        return {} unless str
        
        scan = StringScanner.new(str)
        params = {}
        loop do
          scan.skip(/\s*/)
          name = scan.scan(/[^ \t=]+/) or break
          scan.skip(/\s*/)
          if scan.peek(1) == '='
            scan.skip(/=\s*/)
            q = scan.scan(/['"]/)
            if q
              value = scan.scan_until(/#{q}/).sub(q, '')
            else
              value = scan.scan_until(/\s|$/)
            end
            params[name.to_sym] = value
          else
            params[name.to_sym] = name
          end
        end
        params
      end

      def guarded_loop
        loop do
          pos_before = @context.lineno, @context.colno
          yield
          pos_after = @context.lineno, @context.colno
          pos_after == pos_before and
            @context.fail!("Infinite loop on position #{pos_after.last}")
        end
      end

    end
  end
end
