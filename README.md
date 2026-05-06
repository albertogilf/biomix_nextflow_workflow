# BiomiX Nextflow Workflow

This repository adapts the GNPS2 Nextflow template to run parts of the
BiomiX 2.5 pipeline in a non-interactive way.

The current primary use case is the transcriptomics workflow:

1. Stage a temporary BiomiX workspace
2. Load BiomiX `COMMANDS*.tsv` configuration files
3. Run the BiomiX transcriptomics module without the GUI
4. Write the generated BiomiX outputs into the Nextflow output directory

The repository also contains scaffolding for methylomics, MOFA, and
gold-standard comparisons, but the transcriptomics path is the one you should
treat as the main entry point while iterating.

## Quick start

Clone the repository with submodules:

```bash
git clone --recurse-submodules <repo-url>
cd biomix_nextflow_workflow
```

If you already cloned the repository without submodules, initialize them before
running the workflow:

```bash
git submodule update --init --recursive
```

To check which BiomiX version is currently pinned by this workflow:

```bash
git submodule status --recursive
```

To update initialized submodules to the commits pinned by the current workflow
checkout:

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

To update the BiomiX 2.5 submodule to the latest commit on its tracked upstream
branch, run:

```bash
git submodule update --remote --merge bin/BiomiX2.5
git status
```

If the submodule commit changed, commit both `.gitmodules` if it changed and
the `bin/BiomiX2.5` pointer in this repository:

```bash
git add .gitmodules bin/BiomiX2.5
git commit -m "Update BiomiX 2.5 submodule"
```

The bundled example in this repository uses `./bin/BiomiX2.5` and the
`biomix_transcriptomics` Conda environment.

If your default Java is newer than Nextflow supports, point this shell at Java
21 before running:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export JAVA_CMD=/usr/lib/jvm/java-21-openjdk-amd64/bin/java
```

Run the bundled transcriptomics example:

```bash
make run
```

Or run it explicitly with the existing `biomix_transcriptomics` environment:

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

`nextflow.config` lets Nextflow create a cached Conda environment from
`bin/conda_biomix_transcriptomics.yml`. `nextflow_no_conda.config` disables
that cache and uses the already-installed `biomix_transcriptomics` environment
from the command above.

## Requirements

You need:

- Nextflow
- Java supported by your Nextflow version
- Conda or Mamba
- The `biomix_transcriptomics` Conda environment, or network access so Nextflow
  can build its cached environment from `bin/conda_biomix_transcriptomics.yml`
- Initialized Git submodules
- Write permission in this repository, especially for `.nextflow/`, `work/`,
  and `nf_output/`

If you previously ran Nextflow with `sudo`, fix ownership before running again:

```bash
sudo chown -R "$USER:$USER" .nextflow work nf_output
```

## Transcriptomics inputs

The transcriptomics workflow needs these inputs:

- `--biomix_root`
  Path to the BiomiX 2.5 checkout used by the workflow.
  In this repo that is normally:
  `./bin/BiomiX2.5`

- `--command_dir`
  Directory containing:
  `COMMANDS.tsv`, `COMMANDS_MOFA.tsv`, and `COMMANDS_ADVANCED.tsv`

  These are BiomiX-style parameter files. The workflow copies them into a
  staged workspace and patches the transcriptomics input path to match the file
  passed to `--transcriptomics_matrix`.

- `--transcriptomics_matrix`
  The transcriptomics expression/count matrix to analyse.
  Expected format is the same format accepted by BiomiX itself:
  first column `ID`, remaining columns sample IDs.

- `--metadata`
  Metadata table used by BiomiX to match sample IDs and conditions.
  It must contain at least an `ID` column and a `CONDITION` column.

- `--group_1`
  Name of the case condition to compare.
  Example: `mutated`

- `--group_2`
  Name of the reference/control condition to compare.
  Example: `unmutated`

## Parameters

These are the main workflow parameters relevant to transcriptomics:

- `--biomix_root`
  Root of the BiomiX 2.5 code used by the wrappers.

- `--command_dir`
  Folder with the BiomiX command tables.

- `--transcriptomics_matrix`
  Transcriptomics matrix file to analyse.

- `--metadata`
  Metadata table.

- `--group_1`
  First comparison group.

- `--group_2`
  Second comparison group.

- `--transcriptomics_label`
  BiomiX label for the transcriptomics dataset.
  Default: `RNA`

- `--publishdir`
  Base output location.
  Default: launch directory.

- `--outdir`
  Optional explicit output directory. If set, it overrides `publishdir`.

The workflow also exposes parameters for methylomics, MOFA, and gold-standard
comparison:

- `--methylomics_matrix`
- `--methylomics_label`
- `--run_methylomics true`
- `--run_mofa true`
- `--compare_gold true`
- `--gold_standard_dir`
- `--gold_manifest`

Those are optional for the transcriptomics-only run.

## Transcriptomics gold-standard test

The transcriptomics gold-standard test runs the bundled CLL example and compares
the generated TSV outputs against reference files committed under
`./bin/BiomiX2.5`.

Use this command when you want to test with the current
`biomix_transcriptomics` environment:

```bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export JAVA_CMD=/usr/lib/jvm/java-21-openjdk-amd64/bin/java

conda run -n biomix_transcriptomics --no-capture-output \
  nextflow run ./nf_workflow.nf -resume -c nextflow_no_conda.config \
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

A successful run ends with:

```text
PREPARE_BIOMIX_WORKSPACE | 1 of 1 ✔
RUN_TRANSCRIPTOMICS      | 1 of 1 ✔
COMPARE_GOLD_STANDARD    | 1 of 1 ✔
Succeeded                : 3
```

The comparison report is written in the `COMPARE_GOLD_STANDARD` process work
directory as `gold_comparison_report.json`.

## What `make run` uses

The default `make run` target is configured for the bundled BiomiX CLL example:

- BiomiX root:
  `./bin/BiomiX2.5`
- Commands:
  `./test/fixtures/egas_transcriptomics_mutated_vs_unmutated`
- Transcriptomics matrix:
  `./bin/BiomiX2.5/Example_dataset/EGAS00001001746/RNA_seq/EGAS00001001746_transcriptomics.tsv`
- Metadata:
  `./bin/BiomiX2.5/Example_dataset/EGAS00001001746/Metadata/EGAS00001001746_metadata_CLL.tsv`
- Groups:
  `mutated` vs `unmutated`

## Output layout

By default, outputs are published into:

```text
nf_output/
```

inside the directory where you launched Nextflow, unless `--outdir` is set.

For the transcriptomics workflow, the most important published results are
copied from the staged BiomiX workspace and follow the BiomiX directory layout.

Typical output paths include:

```text
nf_output/Transcriptomics/OUTPUT/RNA_<group_1>_vs_<group_2>/
nf_output/Integration/INPUT/RNA_<group_1>_vs_<group_2>/
```

For the bundled example, expect paths like:

```text
nf_output/Transcriptomics/OUTPUT/RNA_mutated_vs_unmutated/
nf_output/Integration/INPUT/RNA_mutated_vs_unmutated/
```

Inside the transcriptomics output directory, BiomiX usually writes files such
as:

- differential expression tables
- upregulated/downregulated gene tables
- heatmaps
- pathway analysis files
- metadata exports
- MOFA-preparation files under `Integration/INPUT`

## Important working directories

Nextflow also uses internal working directories during execution:

- `.nextflow/`
  Nextflow state and history
- `work/`
  Per-process work directories
- `work/conda/`
  Cached Conda environments

If dependency changes do not seem to take effect, rebuild the cached env:

```bash
rm -rf work/conda
```

If you need a completely fresh run:

```bash
nextflow clean -f
rm -rf work
make run
```

## Running a custom transcriptomics dataset

You can run your own transcriptomics dataset by providing your own matrix,
metadata, and BiomiX command files:

```bash
nextflow run ./nf_workflow.nf -c nextflow.config \
  --biomix_root /path/to/BiomiX2.5 \
  --command_dir /path/to/command_dir \
  --transcriptomics_matrix /path/to/transcriptomics.tsv \
  --metadata /path/to/metadata.tsv \
  --group_1 CASE \
  --group_2 CONTROL
```

Notes:

- `COMMANDS.tsv` must contain a transcriptomics row.
- The workflow rewrites the transcriptomics input file path during staging, so
  the exact original path stored inside `COMMANDS.tsv` is not important.
- The metadata sample IDs must match the matrix column names expected by BiomiX.

## Testing

There are three test targets under [test/Makefile](test/Makefile):

- `make -C test test-biomix-transcriptomics-gold`
  Runs the transcriptomics example and compares selected TSV outputs against the
  bundled BiomiX gold standard. This target uses Nextflow's normal Conda
  integration. If you want to force the current `biomix_transcriptomics`
  environment, use the explicit command in
  [Transcriptomics gold-standard test](#transcriptomics-gold-standard-test).

- `make -C test test-biomix-methylomics-gold`
  Runs the methylomics example with `biomix_methylomics`, skips transcriptomics,
  and compares selected methylomics TSV outputs against
  `bin/BiomiX2.5/Methylomics/OUTPUT`.

- `make -C test test-biomix-mofa-gold`
  Runs the larger transcriptomics+methylomics+MOFA flow and compares selected
  outputs against BiomiX reference files.

## Current status

The workflow is still being integrated with BiomiX’s original R code, which was
written for a GUI-driven execution model. The wrappers in `bin/` bridge that
gap by preparing the globals and working directory structure that BiomiX expects.

That means:

- transcriptomics is the best-supported path right now
- methylomics and MOFA are available but still more fragile
- when debugging, the most useful files are:
  `nf_workflow.nf`, the wrapper scripts in `bin/`, and `.nextflow.log`
