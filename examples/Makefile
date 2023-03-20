.PHONY: all clean

default: all

%.pdf: %.sail %.adoc
	sail -doc $(basename $@).sail -o $(basename $@)_doc -doc_file $(basename $@).sail -doc_embed plain
	asciidoctor-pdf -r ../sail.rb -r asciidoctor-diagram $(basename $@).adoc --trace

all: wavedrom.pdf function_body.pdf clauses.pdf mapping_clauses.pdf anchor.pdf

update_built: all
	mkdir -p built
	cp wavedrom.pdf built/
	cp function_body.pdf built/
	cp clauses.pdf built/
	cp mapping_clauses.pdf built/
	cp anchor.pdf built/

clean:
	rm *.pdf
	rm *.svg
