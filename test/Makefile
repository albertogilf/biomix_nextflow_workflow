attach:
	docker exec -it test_docker /bin/bash

attach-gnps2:
	docker exec -it test_docker_gnps2 /bin/bash

server-compose:
	docker compose down
	docker compose up --build

test-biomix-transcriptomics-gold:
	nextflow run ../nf_workflow.nf \
		--biomix_root ../bin/BiomiX2.5 \
		--command_dir ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
		--transcriptomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
		--metadata ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
		--group_1 mutated \
		--group_2 unmutated \
		--transcriptomics_label RNA \
		--compare_gold true \
		--gold_standard_dir ../bin/BiomiX2.5 \
		--gold_manifest ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest_transcriptomics.json

test-biomix-methylomics-gold:
	conda run -n biomix_methylomics --no-capture-output \
		nextflow run ../nf_workflow.nf -resume -c ../nextflow_no_conda.config \
		--biomix_root ../bin/BiomiX2.5 \
		--command_dir ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
		--transcriptomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
		--methylomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Methylomics/EGAS00001001746_methylomics.tsv \
		--metadata ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
		--group_1 mutated \
		--group_2 unmutated \
		--transcriptomics_label RNA \
		--methylomics_label METHY \
		--run_transcriptomics false \
		--run_methylomics true \
		--compare_gold true \
		--gold_standard_dir ../bin/BiomiX2.5 \
		--gold_manifest ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest_methylomics.json

test-biomix-mofa-gold:
	nextflow run ../nf_workflow.nf \
		--biomix_root ../bin/BiomiX2.5 \
		--command_dir ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
		--transcriptomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
		--methylomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Methylomics/EGAS00001001746_methylomics.tsv \
		--metadata ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
		--group_1 mutated \
		--group_2 unmutated \
		--transcriptomics_label RNA \
		--methylomics_label METHY \
		--run_methylomics true \
		--run_mofa true \
		--compare_gold true \
		--gold_standard_dir ../bin/BiomiX2.5 \
		--gold_manifest ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest.json
