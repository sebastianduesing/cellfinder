imports/cl_imports.owl: sources/cl.owl inputs/cl_input.txt imports/uberon_imports.owl
	robot extract --method MIREOT --input $< \
	--upper-term UBERON:0001062 \
	--lower-terms $(word 2,$^) \
	--lower-terms build/final_uberon.txt \
	--intermediates minimal \
	export --header IRI \
	--export build/mireot_cl.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_cl.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_cl.txt
imports/obi_imports.owl: sources/obi.owl inputs/obi_input.txt imports/uberon_imports.owl
	robot extract --method MIREOT --input $< \
	--upper-term UBERON:0001062 \
	--lower-terms $(word 2,$^) \
	--lower-terms build/final_uberon.txt \
	--intermediates minimal \
	export --header IRI \
	--export build/mireot_obi.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_obi.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--term RO:0001000 \
	--term OBI:9991118 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_obi.txt
imports/efo_imports.owl: sources/efo.owl inputs/efo_input.txt imports/uberon_imports.owl
	robot extract --method MIREOT --input $< \
	--upper-term CL:0000000 \
	--lower-terms $(word 2,$^) \
	--lower-terms build/final_uberon.txt \
	--intermediates minimal \
	remove \
	--term CL:0000000 \
	--select "self descendants" \
	--select complement \
	export --header IRI \
	--export build/mireot_efo.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_efo.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--term RO:0001000 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_efo.txt


IMPORT_FILES := $(wildcard imports/*_imports.owl)
.PHONY: imports
imports: $(IMPORT_FILES)


# Not currently in use. Working on CLO replacements for BTO terms
imports/bto_imports.owl: sources/bto.owl inputs/bto_input.txt imports/uberon_imports.owl
	robot extract --method MIREOT --input $< \
	--lower-terms $(word 2,$^) \
	--lower-terms build/final_uberon.txt \
	--intermediates minimal \
	remove \
	--term CL:0000000 \
	--select "self descendants" \
	--select complement \
	export --header IRI \
	--export build/mireot_bto.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_bto.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--term RO:0001000 \
	--term RO:0002202 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_bto.txt


build/%_import_source.owl:
	curl -sL http://purl.obolibrary.org/obo/$*.owl -o $@

build/%_parent.tsv: src/ontology/robot_inputs/%_input.tsv build/%_import_source.owl
	python3 src/scripts/import.py split $*

build/%_parent.owl: build/%_parent.tsv
	echo "" > $@
	robot merge \
	--input build/$*_import_source.owl \
	template \
	--template $< \
	annotate \
	--ontology-iri "http://github.com/sebastianduesing/cellfinder/dev/import/$*_parent.owl" \
	--output $@

src/ontology/robot_outputs/%_imports.owl: build/%_import_source.owl build/%_limit.txt build/%_import.txt build/%_ignore.txt build/%_parent.owl
	robot extract --method MIREOT --input $< \
	--upper-terms $(word 2,$^) \
	--lower-terms $(word 3,$^) \
	--intermediates minimal \
	--annotate-with-source true \
	export --header IRI --export build/mireot_$*.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_$*.txt \
	--term-file build/$*_relations.txt \
	--annotate-with-source true \
	remove --term-file $(word 4,$^) \
	reduce --reasoner ELK \
	merge --input $(word 5,$^) \
	annotate --ontology-iri "http://github.com/sebastianduesing/cellfinder/dev/import/$*_imports.owl" \
	convert -o $@


icf.owl: src/ontology/icf.tsv build/CLO_import_source.owl build/DOID_import_source.owl build/UBERON_import_source.owl
	python3 src/scripts/axiom_writer.py
	echo '' > $@
	robot --add-prefix "ICF: http://github.com/sebastianduesing/cellfinder/icf/icf#" \
	merge \
	--input src/ontology/robot_outputs/CLO_imports.owl \
	--input build/UBERON_import_source.owl \
	--input build/DOID_import_source.owl \
	template \
	--template $< \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/icf.owl \
	--output $@


build/merged.owl: icf.owl src/ontology/robot_outputs/cl_imports.owl src/ontology/robot_outputs/clo_imports.owl src/ontology/robot_outputs/efo_imports.owl src/ontology/robot_outputs/obi_imports.owl src/ontology/robot_outputs/uberon_imports.owl removed_terms.txt
	python3 src/scripts/clean_removed_terms.py
	robot --add-prefix "ICF: http://github.com/sebastianduesing/cellfinder/icf/icf#" \
	merge \
	--inputs "src/ontology/robot_outputs/*.owl" \
	--input icf.owl \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/merged.owl \
	reduce \
	--reasoner ELK \
	remove \
	--term-file removed_terms.txt \
	reduce \
	--reasoner ELK \
	--output build/merged.owl


.PHONY: imp
imp:
	make src/ontology/robot_outputs/CL_imports.owl
	make src/ontology/robot_outputs/CLO_imports.owl
	make src/ontology/robot_outputs/DOID_imports.owl
	make src/ontology/robot_outputs/OBI_imports.owl
	make src/ontology/robot_outputs/UBERON_imports.owl


src/ontology/cf-edit.owl: src/ontology/cf-edit.tsv
	echo '' > $@
	robot merge \
	--input build/merged.owl \
	template \
	--template $< \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/cf-edit.owl \
	--output $@


cellfinder.owl: build/merged.owl build/iedb_alternative_terms.owl src/ontology/cf-edit.owl
	robot --add-prefix "ICF: http://github.com/sebastianduesing/cellfinder/icf/icf#" \
	merge \
	--input $< \
	--input src/ontology/cf-edit.owl \
	remove \
	--term-file removed_terms.txt \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/cellfinder.owl \
	--output cellfinder.owl


build/cellfinder.tsv: cellfinder.owl
	robot export \
	--input $< \
	--header "ID|LABEL|comment|see also|alternative label|IEDB alternative term|has cross-reference|SubClass Of|Equivalent Class|definition|part of|derives from|has part|derives from patient having disease" \
	--export $@


.PHONY: merge
merge:
	robot merge \
	--inputs "imports/*.owl" \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/merged.owl \
	reduce \
	--reasoner ELK \
	--output build/merged.owl
	robot remove \
	--input build/merged.owl \
	--term-file removed_terms.txt \
	reduce \
	--reasoner ELK \
	--output build/merged.owl
