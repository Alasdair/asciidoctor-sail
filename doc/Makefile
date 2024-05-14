
ALL_EXAMPLES = examples/wavedrom.json examples/function_body.json examples/clauses.json examples/mapping_clauses.json \
               examples/anchor.json examples/split.json examples/span.json examples/xref.json

DOC_SAIL = doc.sail jal.sail

default: sail_to_asciidoc.pdf

examples/%.json: examples/%.sail
	sail -doc $< -o examples -doc_bundle $(basename $(notdir $@)).json -doc_file $< -doc_embed plain -doc_embed_with_location

sail_to_asciidoc.pdf: sail_to_asciidoc.adoc examples/*.adoc $(DOC_SAIL) $(ALL_EXAMPLES)
	sail -doc doc.sail -doc_file doc.sail -doc_file jal.sail -doc_embed plain
	asciidoctor-pdf --trace --verbose -r ../lib/asciidoctor-sail.rb -r asciidoctor-diagram sail_to_asciidoc.adoc

sail_to_asciidoc.html: sail_to_asciidoc.adoc examples/*.adoc $(DOC_SAIL) $(ALL_EXAMPLES)
	sail -doc doc.sail -doc_file doc.sail -doc_file jal.sail -doc_embed plain
	asciidoctor --trace --verbose -r ../lib/asciidoctor-sail.rb -r asciidoctor-diagram sail_to_asciidoc.adoc

clean:
	-rm -f sail_to_asciidoc.pdf
	-rm -f examples/*.json
	-rm -f *.svg
