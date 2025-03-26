imports/uberon_imports.owl: sources/uberon.owl inputs/uberon_input.txt
	robot extract --method MIREOT --input $< \
	--upper-term UBERON:0001062 \
	--lower-terms $(word 2,$^) \
	--intermediates minimal \
	export --header IRI \
	--export build/mireot_uberon.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_uberon.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_uberon.txt
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
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_obi.txt
imports/clo_imports.owl: sources/clo.owl inputs/clo_input.txt imports/uberon_imports.owl
	robot extract --method MIREOT --input $< \
	--upper-term BFO:0000004 \
	--lower-terms $(word 2,$^) \
	--lower-terms build/final_uberon.txt \
	--intermediates minimal \
	export --header IRI \
	--export build/mireot_clo.txt
	robot extract --method subset --input $< \
	--term-file build/mireot_clo.txt \
	--term BFO:0000050 \
	--term BFO:0000051 \
	--term RO:0001000 \
	--output $@
	robot export --input $@ \
	--header IRI \
	--export build/final_clo.txt
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


merged.owl: imports/cl_imports.owl imports/clo_imports.owl imports/efo_imports.owl imports/obi_imports.owl imports/uberon_imports.owl
	robot merge \
	--inputs "imports/*.owl" \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/merged.owl \
	reduce \
	--reasoner ELK \
	remove \
	--term_file removed_terms.txt \
	reduce \
	--reasoner ELK \
	--output merged.owl


build/merged_template.tsv: merged.owl
	robot export \
	--input $< \
	--header "ID|LABEL|SubClass Of|Equivalent Class|definition|part of|derives from|has part" \
	--export $@


.PHONY: merge
merge:
	robot merge \
	--inputs "imports/*.owl" \
	annotate \
	--ontology-iri https://github.com/sebastianduesing/cellfinder/merged.owl \
	reduce \
	--reasoner ELK \
	--output merged.owl
	robot remove \
	--input merged.owl \
	--term-file removed_terms.txt \
	reduce \
	--reasoner ELK \
	--output merged.owl
