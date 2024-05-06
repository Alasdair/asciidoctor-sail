# frozen_string_literal: true

require 'set'

module Asciidoctor
  module Sail
    module SourceMacro
      # Should match Docinfo.docinfo_version in Sail OCaml source
      VERSION = 1
      PLUGIN_NAME = 'Sail Asciidoc plugin'

      def get_sourcemap(doc, attrs)
        from = attrs.delete('from') { 'sail-doc' }
        source_map = doc.attr(from)
        if source_map.nil?
          raise "#{PLUGIN_NAME}: Document attribute :#{from}: does not exist, so we don't know where to find any sources"
        end
        ::Asciidoctor::Sail::Sources.register(from, source_map)
        json = ::Asciidoctor::Sail::Sources.get(from)
        if json['version'] != VERSION
          raise "#{PLUGIN_NAME}: Version does not match version in source map #{source_map}"
        end

        return json, from
      end

      def get_type(attrs)
        attrs.delete('type') { 'function' }
      end

      def get_part(attrs)
        attrs.delete('part') { 'source' }
      end

      def get_split(attrs)
        attrs.delete('split') { '' }
      end

      def read_source(json, part)
        source = ''

        if json.is_a? String
          source = json
        elsif json[part].is_a? String
          source = json[part]
        else
          path = json['file']

          if not File.exist?(path)
            raise "#{PLUGIN_NAME}: File #{path} does not exist"
          end

          file = File.read(path)
          loc = json[part]['loc']

          # Get the source code, adjusting for the indentation of the first line of the span
          indent = loc[2] - loc[1]

          source = file.byteslice(loc[2], loc[5] - loc[2])
          source = (' ' * indent) + source
        end

        source
      end

      def get_sail_object(json, target, attrs)
        type = get_type(attrs)
        json = json["#{type}s"]
        if json.nil?
          raise "#{PLUGIN_NAME}: No Sail objects of type #{type}"
        end
        json = json[target]
        if json.nil?
          raise "#{PLUGIN_NAME}: No Sail #{type} #{target} could be found" 
        end
        json = json[type]

        if attrs.key? 'clause'
          clause = attrs.delete('clause')
          json.each do |child|
            if match_clause(clause, child['pattern'])
              json = child
              break
            end
          end
        elsif attrs.key? 'left-clause'
          clause = attrs.delete('left-clause')
          json.each do |child|
            if match_clause(clause, child['left'])
              json = child
              break
            end
          end
        elsif attrs.key? 'right-clause'
          clause = attrs.delete('right-clause')
          json.each do |child|
            if match_clause(clause, child['right'])
              json = child
              break
            end
          end
        elsif attrs.key? 'grep'
          grep = attrs.delete('grep')
          json.each do |child|
            source = read_source(child, 'body')
            if source =~ Regexp.new(grep)
              json = child
            end
          end
        end

        return json, type
      end

      # Compute the minimum indentation for any line in a source block
      def minindent(tabwidth, source)
        indent = -1
        source.each_line do |line|
          line_indent = 0
          line.chars.each do |c|
            case c
            when ' '
              line_indent += 1
            when "\t"
              line_indent += tabwidth
            else
              break
            end
          end
          indent = line_indent if indent == -1 || line_indent < indent
        end
        indent
      end

      def get_source(doc, target, attrs)
        json, from = get_sourcemap doc, attrs
        json, type = get_sail_object json, target, attrs
        dedent = attrs.any? { |k, v| (k.is_a? Integer) && %w[dedent unindent].include?(v) }
        strip = attrs.any? { |k, v| (k.is_a? Integer) && %w[trim strip].include?(v) }

        part = get_part attrs
        split = get_split attrs

        source = ''
        if split != ''
          source = json['splits'][split]
        else
          source = read_source(json, part)
        end

        source.strip! if strip

        if dedent
          lines = ''
          min = minindent 4, source

          source.each_line do |line|
            lines += line[min..]
          end
          source = lines
        end

        return source, type, from
      end

      def match_clause(desc, json)
        if desc =~ /^([a-zA-Z_?][a-zA-Z0-9_?#]*)(\(.*\))$/
          return false unless json['type'] == 'app' && json['id'] == ::Regexp.last_match(1)

          patterns = json['patterns']
          if patterns.length == 1
            patterns = patterns[0]
          end

          match_clause ::Regexp.last_match(2), patterns
        elsif desc.length.positive? && desc[0] == '('
          tuples = nil
          if json.is_a? Array
            tuples = json
          elsif json['type'] == 'tuple'
            tuples = json['patterns']
          else
            tuples = [json]
          end

          results = []
          desc[1...-1].split(',').each_with_index do |desc, i|
            results.push(match_clause(desc.strip, tuples[i]))
          end
          results.all?
        elsif desc == '_'
          true
        elsif desc =~ /^([a-zA-Z_?][a-zA-Z0-9_?#]*)$/
          json['type'] == 'id' && json['id'] == ::Regexp.last_match(1)
        elsif desc =~ /^(0[bx][a-fA-F0-9]*)$/
          json['type'] == 'literal' && json['value'] == ::Regexp.last_match(1)
        else
          false
        end
      end
    end

    class SourceBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
      include SourceMacro

      use_dsl

      named :sail

      @@ids = Set.new()

      def process(parent, target, attrs)
        source, type, from = get_source parent.document, target, attrs

        if type == 'function' then
          id = "#{from}-#{target}"
        else
          id = "#{from}-#{type}-#{target}"
        end

        if not @@ids.member?(id) then
          @@ids.add(id)
          block = create_listing_block parent, source, { 'id' => id, 'style' => 'source', 'language' => 'sail' }
        else
          block = create_listing_block parent, source, { 'style' => 'source', 'language' => 'sail' }
        end

        block
      end
    end

    class SourceIncludeProcessor < ::Asciidoctor::Extensions::IncludeProcessor
      include SourceMacro

      def handles? target
        target.start_with? 'sail:'
      end

      def process doc, reader, target, attrs
        target.delete_prefix! 'sail:'

        source, type, from = get_source doc, target, attrs

        reader.push_include source, target, target, 1, {}
        reader
      end
    end

    class WavedromIncludeProcessor < ::Asciidoctor::Extensions::IncludeProcessor
      include SourceMacro

      def handles? target
        target.start_with? 'sailwavedrom:'
      end

      def process doc, reader, target, attrs
        target.delete_prefix! 'sailwavedrom:'
        json, from = get_sourcemap doc, attrs
        json, type = get_sail_object json, target, attrs

        key = 'wavedrom'
        if attrs.any? { |k, v| (k.is_a? Integer) && v == 'right' }
          key = 'right_wavedrom'
        elsif attrs.any? { |k, v| (k.is_a? Integer) && v == 'left' }
          key = 'left_wavedrom'
        end

        if attrs.any? { |k, v| (k.is_a? Integer) && v == 'raw' }
          diagram = json[key]
        else
          diagram = "[wavedrom, ,]\n....\n#{json[key]}\n...."
        end

        reader.push_include diagram, target, target, 1, {}
        reader
      end
    end

    class DocCommentIncludeProcessor < ::Asciidoctor::Extensions::IncludeProcessor
      include SourceMacro

      def handles? target
        target.start_with? 'sailcomment:'
      end

      def process doc, reader, target, attrs
        target.delete_prefix! 'sailcomment:'
        json, from = get_sourcemap doc, attrs
        json, type = get_sail_object json, target, attrs

        if json.nil? || json.is_a?(Array)
          raise "#{PLUGIN_NAME}: Could not find Sail object for #{target} when processing include::sailcomment. You may need to specify a clause."
        end

        comment = json['comment']
        if comment.nil?
          raise "#{PLUGIN_NAME}: No documentation comment for Sail object #{target}"
        end

        reader.push_include comment, target, target, 1, attrs
        reader
      end
    end
  end
end
