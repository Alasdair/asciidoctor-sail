
%.pdf: %.sail %.adoc
	sail -doc $(basename $@).sail -o $(basename $@)_doc -doc_file $(basename $@).sail -doc_embed plain
	asciidoctor-pdf -r ../sail.rb -r asciidoctor-diagram $(basename $@).adoc --trace
