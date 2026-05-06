attach:
	docker exec -it test_docker /bin/bash

attach-gnps2:
	docker exec -it test_docker_gnps2 /bin/bash

setup-biomix-metabolomics-env:
	mamba env create -f ../bin/conda_biomix_metabolomics.yml
	conda run -n biomix_metabolomics --no-capture-output \
		Rscript ../bin/install_biomix_metabolomics_r_packages.R ../bin

server-compose:
	docker compose down
	docker compose up --build

test-biomix-transcriptomics-gold:
	conda run -n biomix_transcriptomics --no-capture-output \
		nextflow run ../nf_workflow.nf -c ../nextflow_no_conda.config \
		--biomix_root ../bin/BiomiX2.5 \
		--command_dir ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
		--transcriptomics_matrix ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
		--metadata ../bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
		--group_1 mutated \
		--group_2 unmutated \
		--transcriptomics_label RNA \
		--run_transcriptomics true \
		--compare_gold true \
		--gold_standard_dir ../bin/BiomiX2.5 \
		--gold_manifest ../test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest_transcriptomics.json

test-biomix-methylomics-gold:
	conda run -n biomix_methylomics --no-capture-output \
		nextflow run ../nf_workflow.nf -c ../nextflow_no_conda.config \
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

test-biomix-metabolomics-gold:
	conda run -n biomix_metabolomics --no-capture-output \
		nextflow run ../nf_workflow.nf -c ../nextflow_no_conda.config \
		--biomix_root ../bin/BiomiX2.5 \
		--command_dir ../test/fixtures/biomix_metabolomics_ptb_vs_hc \
		--metabolomics_matrix ../bin/BiomiX2.5/Metabolomics/INPUT/MTBLS7623_positive_mode_annotated_HMDB.tsv \
		--metadata ../bin/BiomiX2.5/Metadata/MTBLS7623_Metadata.tsv \
		--group_1 PTB \
		--group_2 HC \
		--metabolomics_label Plasma \
		--run_transcriptomics false \
		--run_metabolomics true \
		--compare_gold true \
		--gold_standard_dir ../bin/BiomiX2.5 \
		--gold_manifest ../test/fixtures/biomix_metabolomics_ptb_vs_hc/gold_manifest_metabolomics.json

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
