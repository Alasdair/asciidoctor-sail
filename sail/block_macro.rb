
module Asciidoctor
  module Sail
    module SourceMacro
      # Should match Docinfo.docinfo_version in Sail OCaml source
      Version = 1
      
      def get_sourcemap parent, attrs
        from = attrs.delete('from') { 'sail-doc' }
        source_map = parent.document.attr(from)
        ::Asciidoctor::Sail::Sources.register(from, source_map)
        json = ::Asciidoctor::Sail::Sources.get(from)
        if json['version'] != Version then
          raise "Sail Asciidoc plugin version does not match version in source map #{source_map}"
        end
        json
      end

      def get_type attrs
        attrs.delete('type') { 'function' }
      end

      def get_part attrs
        attrs.delete('part') { 'source' }
      end
      
      # Compute the minimum indentation for any line in a source block
      def minindent tabwidth, source
         indent = -1
         source.each_line do |line|
           line_indent = 0
           line.chars.each do |c|
             if c == ' ' then
               line_indent += 1
             elsif c == '\t' then
               line_indent += tabwidth
             else
               break
             end
           end
           indent = (indent == -1 || line_indent < indent) ? line_indent : indent
         end
         indent
      end
    end
    
    class FunctionBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
      include SourceMacro
      
      use_dsl

      named :sail
      
      def process parent, target, attrs
        # Get the revelant option from the attrs
        json = get_sourcemap parent, attrs
        type = get_type attrs
        part = get_part attrs
        dedent = attrs.any? {|k, v| (k.is_a? Integer) && (v == 'dedent' || v == 'unindent')}
        strip = attrs.any? {|k, v| (k.is_a? Integer) && (v == 'trim' || v == 'strip')}

        json = json[type + 's'][target][type]
        file = File.read(json['source']['file'])
        loc = json[part]['loc']

        # Get the source code, adjusting for the indentation of the first line of the span
        indent = loc[2] - loc[1]
        source = file[loc[2] .. loc[5]]
        source = (' ' * indent) + source

        if strip then
          source.strip!
        end
        
        if dedent then
          lines = ''
          min = minindent 4, source
          
          source.each_line do |line|
            lines += line[min..-1]
          end
          source = lines
        end
 
        create_listing_block parent, source, { 'style' => 'source', 'language' => 'sail' }
      end
    end
  end
end
