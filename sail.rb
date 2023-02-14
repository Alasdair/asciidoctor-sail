# frozen_string_literal: true

require 'asciidoctor/extensions'

require_relative 'sail/sources'
require_relative 'sail/block_macro'
require_relative 'sail/highlighter'

Asciidoctor::Extensions.register do
  block_macro Asciidoctor::Sail::FunctionBlockMacro
end
