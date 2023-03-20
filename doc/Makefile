
sail_to_asciidoc.pdf: doc.sail jal.sail sail_to_asciidoc.adoc
	sail -doc doc.sail -doc_file doc.sail -doc_file jal.sail -doc_embed plain
	asciidoctor-pdf -r ../sail.rb -r asciidoctor-diagram sail_to_asciidoc.adoc
