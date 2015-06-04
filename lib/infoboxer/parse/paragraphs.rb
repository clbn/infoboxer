# encoding: utf-8
require_relative 'table'

module Infoboxer
  module Parse
    class ParagraphsParser
      def initialize(text, context)
        @context = context
        @text = text.gsub(/<!--.+?-->/m, '') # FIXME: will also kill comments inside <nowiki> tag
        @lines = @text.split(/\r?\n/m)
        @nodes = Nodes.new
      end

      def parse
        until @lines.empty?
          current = @lines.shift

          case current
          when /^={2,}/
            heading(current)
          when /^\s*{\|/
            @lines.unshift(current)
            table # it will parse lines, including current
          when /^[\*\#:;]./
            list(current)
          when /^-{4,}/
            node(HR)
          when /^\s+$/.guard{@nodes.empty? || @nodes.last.closed? || !@nodes.last.is_a?(Pre)}
            # either space between paragraphs/lists, or empty line inside pre
            @nodes.empty? or @nodes.last.closed!
          when /^ /
            pre(current)
          when '' # blank line = space between paragraphs/lists
            @nodes.empty? or @nodes.last.closed!
          else
            para(current)
          end
        end

        merge_nodes!
        flatten_templates!

        @nodes
      end

      private

        # Paragraph-level nodes DSL --------------------------------------
        def para(str)
          node(Paragraph, inline(str))
        end

        def heading(str)
          level, text = str.scan(/^(={2,})\s*(.+?)(?:\s*=+)?$/).flatten
          node(Heading, inline(text), level.length)
        end

        # http://en.wikipedia.org/wiki/Help:List
        def list(str)
          marker, text = str.scan(/^([*\#:;]+)\s*(.+?)$/).flatten
          @nodes << List.construct(marker.chars.to_a, inline(text))
        end

        def pre(str)
          node(Pre, [Text.new(str.sub(/^ /, ''))])
        end

        def table
          @nodes << TableParser.parse(@lines, @context)
        end

        # Post-processing --------------------------------------------------
        def merge_nodes!
          return if @nodes.count < 2
          
          merged = [@nodes.first]

          @nodes[1..-1].each do |node|
            if merged.last.can_merge?(node)
              merged.last.merge!(node)
            else
              merged << node
            end
          end

          @nodes.replace(merged)
        end

        # If we have paragraph, which consists of templates only,
        # this paragraph should be REPLACED with templates.
        # This way, we get rid of situation, when first 3-5 paragraphs of
        # document is infoboxes, disambig marks and so on.
        #
        # FIXME: not sure, if this method is smart enough.
        def flatten_templates!
          flat = @nodes.map do |node|
            
            if node.is_a?(Paragraph) &&
              node.children.all?{|c| c.is_a?(Template) || c.matches?(Text, text: /^\s*$/)}

              node.children
            else
              node
            end
          end.flatten(1)

          @nodes.replace(flat)
        end

        # Basic internals --------------------------------------------------
        def inline(str)
          Parse.inline(str, @context.merge(next_lines: @lines))
        end
        
        def node(klass, *arg)
          @nodes << klass.new(*arg)
        end
    end
  end
end