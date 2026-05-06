# BiomiX workflow tests

This directory contains local and Docker-based tests for the BiomiX Nextflow
workflow.

## How to run

From the repository root, initialize the BiomiX submodule if it is not already
available:

```bash
git submodule update --init --recursive
```

From the repository root, make sure Java 21 is selected if your default Java is
newer than Nextflow supports:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 # SET your JAVA_HOME as necessary
export JAVA_CMD=/usr/lib/jvm/java-21-openjdk-amd64/bin/java # SET your JAVA_CMD as necessary
```

Run the transcriptomics example with the existing `biomix_transcriptomics`
environment:

```bash
conda run -n biomix_transcriptomics --no-capture-output \
  nextflow run ./nf_workflow.nf -c nextflow_no_conda.config \
  --biomix_root ./bin/BiomiX2.5 \
  --command_dir ./test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
  --transcriptomics_matrix ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
  --metadata ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
  --group_1 mutated \
  --group_2 unmutated \
  --transcriptomics_label RNA
```

## Transcriptomics gold-standard test

Run the transcriptomics workflow and compare the selected TSV outputs against
the bundled BiomiX gold standard:

```bash
conda run -n biomix_transcriptomics --no-capture-output \
  nextflow run ./nf_workflow.nf -c nextflow_no_conda.config \
  --biomix_root ./bin/BiomiX2.5 \
  --command_dir ./test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
  --transcriptomics_matrix ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
  --metadata ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
  --group_1 mutated \
  --group_2 unmutated \
  --transcriptomics_label RNA \
  --compare_gold true \
  --gold_standard_dir ./bin/BiomiX2.5 \
  --gold_manifest ./test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest_transcriptomics.json
```

A successful run finishes with `Succeeded: 3`.

## Methylomics gold-standard test

Create the methylomics environment from the repository root if needed:

```bash
mamba env create -f bin/conda_biomix_methylomics.yml
```

Run the methylomics workflow and compare the selected TSV outputs against the
bundled BiomiX methylomics gold standard:

```bash
conda run -n biomix_methylomics --no-capture-output \
  nextflow run ./nf_workflow.nf -c nextflow_no_conda.config \
  --biomix_root ./bin/BiomiX2.5 \
  --command_dir ./test/fixtures/egas_transcriptomics_mutated_vs_unmutated \
  --transcriptomics_matrix ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv \
  --methylomics_matrix ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/Methylomics/EGAS00001001746_methylomics.tsv \
  --metadata ./bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv \
  --group_1 mutated \
  --group_2 unmutated \
  --transcriptomics_label RNA \
  --methylomics_label METHY \
  --run_transcriptomics false \
  --run_methylomics true \
  --compare_gold true \
  --gold_standard_dir ./bin/BiomiX2.5 \
  --gold_manifest ./test/fixtures/egas_transcriptomics_mutated_vs_unmutated/gold_manifest_methylomics.json
```

A successful run finishes with `Succeeded: 3`.

## Metabolomics gold-standard test

Create the metabolomics environment from the repository root if needed:

```bash
mamba env create -f bin/conda_biomix_metabolomics.yml
conda run -n biomix_metabolomics --no-capture-output \
  Rscript bin/install_biomix_metabolomics_r_packages.R bin
```

The helper installs `cmmr`, `metid`, and `metpath`, which are not all available
from conda-forge/bioconda with the BiomiX versions. If you have the exact
BiomiX source tarballs, pass their directory as the script argument.

Run the metabolomics workflow and compare the selected TSV outputs against the
bundled BiomiX metabolomics gold standard:

```bash
conda run -n biomix_metabolomics --no-capture-output \
  nextflow run ./nf_workflow.nf -c nextflow_no_conda.config \
  --biomix_root ./bin/BiomiX2.5 \
  --command_dir ./test/fixtures/biomix_metabolomics_ptb_vs_hc \
  --metabolomics_matrix ./bin/BiomiX2.5/Metabolomics/INPUT/MTBLS7623_positive_mode_annotated_HMDB.tsv \
  --metadata ./bin/BiomiX2.5/Metadata/MTBLS7623_Metadata.tsv \
  --group_1 PTB \
  --group_2 HC \
  --metabolomics_label Plasma \
  --run_transcriptomics false \
  --run_metabolomics true \
  --compare_gold true \
  --gold_standard_dir ./bin/BiomiX2.5 \
  --gold_manifest ./test/fixtures/biomix_metabolomics_ptb_vs_hc/gold_manifest_metabolomics.json
```

A successful run finishes with `Succeeded: 3`.

The workflow publishes TSV outputs for manual inspection under:

- `test/nf_tsv/transcriptomics`
- `test/nf_tsv/methylomics`
- `test/nf_tsv/metabolomics`

## Docker testing

```
docker compose up
```

```
make attach
```

```
cd /test
make run
```

## Makefile gold-standard tests

The transcriptomics and MOFA targets use Nextflow's normal Conda integration,
which may create cached Conda environments under `work/conda`. The methylomics
target uses the existing `biomix_methylomics` environment through
`nextflow_no_conda.config`.

Transcriptomics-only:

```
make test-biomix-transcriptomics-gold
```

Methylomics-only:

```
make test-biomix-methylomics-gold
```

Metabolomics-only:

```
make test-biomix-metabolomics-gold
```

Transcriptomics + methylomics + MOFA:

```
make test-biomix-mofa-gold
```
