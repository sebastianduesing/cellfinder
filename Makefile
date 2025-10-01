IMPORT_NAMES := DOID\
 OBI\
 UCC
IMPORT_FILES := $(foreach x,$(IMPORT_NAMES),src/ontology/robot_outputs/$(x)_imports.owl)

build/%_import_source.owl:
	curl -sL http://purl.obolibrary.org/obo/$*.owl -o $@

build/UCC_import_source.owl: build/CL_import_source.owl build/CLO_import_source.owl build/UBERON_import_source.owl
	robot merge \
	--input $< \
	--input $(word 2,$^) \
	--input $(word 3,$^) \
	--output $@

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


icf.owl: src/ontology/icf.tsv $(IMPORT_FILES)
	$(eval INPUTS := $(foreach x,$(IMPORT_FILES),--input $(x) ))
	python3 src/scripts/axiom_writer.py
	echo '' > $@
	robot --add-prefix "ICF: http://github.com/sebastianduesing/cellfinder/icf/icf#" \
	merge \
	$(INPUTS) \
	template \
	--template $< \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/icf.owl \
	--output $@


build/merged.owl: icf.owl $(IMPORT_FILES) removed_terms.txt
	$(eval INPUTS := $(foreach x,$(IMPORT_FILES),--input $(x) ))
	python3 src/scripts/clean_removed_terms.py
	robot --add-prefix "ICF: http://github.com/sebastianduesing/cellfinder/icf/icf#" \
	merge \
	$(INPUTS) \
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
