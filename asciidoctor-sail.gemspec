
Gem::Specification.new do |s|
  s.name = 'asciidoctor-sail'
  s.version = '0.2'
  s.authors = ['Alasdair Armstrong']
  s.email = ['alasdair.armstrong@cl.cam.ac.uk']
  s.description = %q{Asciidoctor extension for documenting Sail models}
  s.summary = %q{An Asciidoctor extension that supports including formatted Sail source in ISA manuals}
  s.homepage = 'https://github.com/Alasdair/asciidoctor-sail'
  s.license = 'MIT'

  s.files = [
    'lib/asciidoctor-sail.rb',
    'lib/asciidoctor-sail/macros.rb',
    'lib/asciidoctor-sail/highlighter.rb',
    'lib/asciidoctor-sail/sources.rb',
    'README.adoc',
    'LICENSE',
  ]
end
