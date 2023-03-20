# frozen_string_literal: true

module Asciidoctor
  module Sail
    module SourceMacro
      # Should match Docinfo.docinfo_version in Sail OCaml source
      VERSION = 1
      PLUGIN_NAME = 'Sail Asciidoc plugin'

      def get_sourcemap(doc, attrs)
        from = attrs.delete('from') { 'sail-doc' }
        source_map = doc.attr(from)
        ::Asciidoctor::Sail::Sources.register(from, source_map)
        json = ::Asciidoctor::Sail::Sources.get(from)
        if json['version'] != VERSION
          raise "#{PLUGIN_NAME}: Version does not match version in source map #{source_map}"
        end

        json
      end

      def get_type(attrs)
        attrs.delete('type') { 'function' }
      end

      def get_part(attrs)
        attrs.delete('part') { 'source' }
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
        end

        json
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
            return false
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

    class FunctionBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
      include SourceMacro

      use_dsl

      named :sail

      def process(parent, target, attrs)
        # Get the revelant option from the attrs
        json = get_sourcemap parent.document, attrs
        json = get_sail_object json, target, attrs
        dedent = attrs.any? { |k, v| (k.is_a? Integer) && %w[dedent unindent].include?(v) }
        strip = attrs.any? { |k, v| (k.is_a? Integer) && %w[trim strip].include?(v) }

        part = get_part attrs

        source = ""
        if json['source'].is_a? String
          source = json[part]
        else
          file = File.read(json['file'])
          loc = json[part]['loc']

          # Get the source code, adjusting for the indentation of the first line of the span
          indent = loc[2] - loc[1]

          source = file.byteslice(loc[2], loc[5] - loc[2])
          source = (' ' * indent) + source
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

        create_listing_block parent, source, { 'style' => 'source', 'language' => 'sail' }
      end
    end

    class WavedromIncludeProcessor < ::Asciidoctor::Extensions::IncludeProcessor
      include SourceMacro

      def handles? target
        target.start_with? 'sailwavedrom:'
      end

      def process doc, reader, target, attrs
        target.delete_prefix! 'sailwavedrom:'
        json = get_sourcemap doc, attrs
        json = get_sail_object json, target, attrs
        
        key = 'wavedrom'
        if attrs.any? { |k, v| (k.is_a? Integer) && v == 'right' }
          key = 'right_wavedrom'
        elsif attrs.any? { |k, v| (k.is_a? Integer) && v == 'left' }
          key = 'left_wavedrom'
        end

        diagram = "[wavedrom, , svg]\n....\n#{json[key]}\n...."
 
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
        json = get_sourcemap doc, attrs
        json = get_sail_object json, target, attrs

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
