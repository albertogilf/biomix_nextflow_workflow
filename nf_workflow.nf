#!/usr/bin/env nextflow
/*
 * BiomiX DSL2 workflow.
 *
 * Each process stages a non-interactive BiomiX workspace, runs one omics
 * module through a wrapper script, publishes the full BiomiX output tree, and
 * also publishes generated TSV files into an omics-specific review directory.
 */
nextflow.enable.dsl=2

params.publishdir = "$launchDir"
params.outdir = ""
params.biomix_root = "$moduleDir/bin/BiomiX2.5"
params.command_dir = ""
params.transcriptomics_matrix = ""
params.methylomics_matrix = ""
params.metabolomics_matrix = ""
params.metadata = ""
params.group_1 = ""
params.group_2 = ""
params.transcriptomics_label = "RNA"
params.methylomics_label = "METHY"
params.metabolomics_label = "Plasma"
params.run_transcriptomics = true
params.run_methylomics = false
params.run_metabolomics = false
params.run_mofa = false
params.compare_gold = false
params.gold_standard_dir = ""
params.gold_manifest = ""
params.gold_atol = 1e-4
params.gold_rtol = 1e-4

def parseBool(value) {
    if (value instanceof Boolean) {
        return value
    }
    value?.toString()?.trim()?.toLowerCase() in ['true', '1', 'yes', 'y']
}

process PREPARE_BIOMIX_WORKSPACE {
    /*
     * Copy the BiomiX checkout and selected fixture inputs into an isolated
     * task workspace. Wrapper-side patches are applied only to this staged copy;
     * files under bin/BiomiX2.5 are never modified by the workflow.
     */
    publishDir "${params.outdir ?: params.publishdir}/nf_output", mode: 'copy', pattern: 'biomix_workspace/COMBINED_COMMANDS.json'

    conda "${moduleDir}/bin/conda_biomix_transcriptomics.yml"

    input:
    path biomix_root
    path command_dir
    val transcriptomics_matrix
    val methylomics_matrix
    val metabolomics_matrix
    path metadata
    val transcriptomics_label
    val methylomics_label
    val metabolomics_label
    val group_1
    val group_2

    output:
    path "biomix_workspace", emit: workspace

    script:
    """
    python ${moduleDir}/bin/biomix_prepare_workspace.py \
      --source-root "$biomix_root" \
      --dest-root biomix_workspace \
      --command-dir "$command_dir" \
      --transcriptomics-matrix "${transcriptomics_matrix}" \
      --methylomics-matrix "${methylomics_matrix}" \
      --metabolomics-matrix "${metabolomics_matrix}" \
      --metadata "$metadata" \
      --transcriptomics-label "${transcriptomics_label}" \
      --methylomics-label "${methylomics_label}" \
      --metabolomics-label "${metabolomics_label}" \
      --output-dir "\$PWD/biomix_workspace"

    (
      cd biomix_workspace
      Rscript Converter_JSON.r "${group_1}" "${group_2}" "\$PWD"
    )
    """
}

process RUN_TRANSCRIPTOMICS {
    /*
     * Run the BiomiX transcriptomics module and publish all generated TSV files
     * separately under nf_tsv/transcriptomics for manual inspection.
     */
    publishDir "${params.outdir ?: params.publishdir}/nf_output", mode: 'copy'
    publishDir "${params.outdir ?: params.publishdir}/nf_tsv/transcriptomics", mode: 'copy', pattern: 'published_tsv/transcriptomics/**/*.tsv'

    conda "${moduleDir}/bin/conda_biomix_transcriptomics.yml"

    input:
    path biomix_workspace
    val transcriptomics_label
    val group_1
    val group_2

    output:
    path "biomix_workspace_post_transcriptomics", emit: workspace
    path "Transcriptomics", emit: transcriptomics
    path "Integration", emit: integration
    path "published_tsv/transcriptomics/**/*.tsv", emit: transcriptomics_tsv, optional: true

    script:
    """
    cp -r "$biomix_workspace" biomix_workspace_post_transcriptomics

    Rscript ${moduleDir}/bin/biomix_run_transcriptomics.R \
      --workspace "\$PWD/biomix_workspace_post_transcriptomics" \
      --group1 "${group_1}" \
      --group2 "${group_2}" \
      --label "${transcriptomics_label}"

    cp -r biomix_workspace_post_transcriptomics/Transcriptomics ./Transcriptomics
    cp -r biomix_workspace_post_transcriptomics/Integration ./Integration
    mkdir -p published_tsv/transcriptomics
    find Transcriptomics/OUTPUT -type f -name '*.tsv' -exec cp --parents {} published_tsv/transcriptomics \\;
    """
}

process RUN_METHYLOMICS {
    /*
     * Run the BiomiX methylomics module and publish all generated TSV files
     * separately under nf_tsv/methylomics for manual inspection.
     */
    publishDir "${params.outdir ?: params.publishdir}/nf_output", mode: 'copy'
    publishDir "${params.outdir ?: params.publishdir}/nf_tsv/methylomics", mode: 'copy', pattern: 'published_tsv/methylomics/**/*.tsv'

    conda "${moduleDir}/bin/conda_biomix_methylomics.yml"

    input:
    path biomix_workspace
    val methylomics_label
    val group_1
    val group_2

    output:
    path "biomix_workspace_post_methylomics", emit: workspace
    path "Methylomics", emit: methylomics
    path "Integration", emit: integration
    path "published_tsv/methylomics/**/*.tsv", emit: methylomics_tsv, optional: true

    script:
    """
    cp -r "$biomix_workspace" biomix_workspace_post_methylomics

    Rscript ${moduleDir}/bin/biomix_run_methylomics.R \
      --workspace "\$PWD/biomix_workspace_post_methylomics" \
      --group1 "${group_1}" \
      --group2 "${group_2}" \
      --label "${methylomics_label}"

    cp -r biomix_workspace_post_methylomics/Methylomics ./Methylomics
    cp -r biomix_workspace_post_methylomics/Integration ./Integration
    mkdir -p published_tsv/methylomics
    find Methylomics/OUTPUT -type f -name '*.tsv' -exec cp --parents {} published_tsv/methylomics \\;
    """
}

process RUN_METABOLOMICS {
    /*
     * Run the BiomiX metabolomics module and publish all generated TSV files
     * separately under nf_tsv/metabolomics for manual inspection.
     */
    publishDir "${params.outdir ?: params.publishdir}/nf_output", mode: 'copy'
    publishDir "${params.outdir ?: params.publishdir}/nf_tsv/metabolomics", mode: 'copy', pattern: 'published_tsv/metabolomics/**/*.tsv'

    conda "${moduleDir}/bin/conda_biomix_metabolomics.yml"

    input:
    path biomix_workspace
    val metabolomics_label
    val group_1
    val group_2

    output:
    path "biomix_workspace_post_metabolomics", emit: workspace
    path "Metabolomics", emit: metabolomics
    path "Integration", emit: integration
    path "published_tsv/metabolomics/**/*.tsv", emit: metabolomics_tsv, optional: true

    script:
    """
    cp -r "$biomix_workspace" biomix_workspace_post_metabolomics

    Rscript ${moduleDir}/bin/install_biomix_metabolomics_r_packages.R \
      ${moduleDir}/bin

    Rscript ${moduleDir}/bin/biomix_run_metabolomics.R \
      --workspace "\$PWD/biomix_workspace_post_metabolomics" \
      --group1 "${group_1}" \
      --group2 "${group_2}" \
      --label "${metabolomics_label}"

    cp -r biomix_workspace_post_metabolomics/Metabolomics ./Metabolomics
    cp -r biomix_workspace_post_metabolomics/Integration ./Integration
    mkdir -p published_tsv/metabolomics
    find Metabolomics/OUTPUT -type f -name '*.tsv' -exec cp --parents {} published_tsv/metabolomics \\;
    """
}

process RUN_MOFA {
    /*
     * Run the BiomiX MOFA integration module after one or more omics modules.
     */
    publishDir "${params.outdir ?: params.publishdir}/nf_output", mode: 'copy'

    conda "${moduleDir}/bin/conda_biomix_mofa.yml"

    input:
    path biomix_workspace
    val group_1
    val group_2

    output:
    path "biomix_workspace_post_mofa", emit: workspace
    path "Integration", emit: integration

    script:
    """
    cp -r "$biomix_workspace" biomix_workspace_post_mofa

    Rscript ${moduleDir}/bin/biomix_run_mofa.R \
      --workspace "\$PWD/biomix_workspace_post_mofa" \
      --group1 "${group_1}" \
      --group2 "${group_2}"

    cp -r biomix_workspace_post_mofa/Integration ./Integration
    """
}

process COMPARE_GOLD_STANDARD {
    /*
     * Compare generated TSV outputs against a manifest of BiomiX gold-standard
     * files. Numeric columns use configurable absolute and relative tolerances.
     */
    conda "${moduleDir}/bin/conda_biomix_test_gold_standards.yml"

    input:
    path actual_root
    path gold_root
    path manifest
    val gold_atol
    val gold_rtol

    output:
    path "gold_comparison_report.json", emit: report

    script:
    """
    python ${moduleDir}/bin/compare_biomix_gold.py \
      --actual-root "$actual_root" \
      --gold-root "$gold_root" \
      --manifest "$manifest" \
      --atol "${gold_atol}" \
      --rtol "${gold_rtol}" \
      --report gold_comparison_report.json
    """
}

workflow Main {
    /*
     * Compose the requested omics modules in sequence. active_workspace always
     * points to the latest staged BiomiX workspace emitted by the previous step.
     */
    take:
    input_map

    main:
    prepared_workspace = PREPARE_BIOMIX_WORKSPACE(
        input_map.biomix_root,
        input_map.command_dir,
        input_map.transcriptomics_matrix,
        input_map.methylomics_matrix,
        input_map.metabolomics_matrix,
        input_map.metadata,
        input_map.transcriptomics_label,
        input_map.methylomics_label,
        input_map.metabolomics_label,
        input_map.group_1,
        input_map.group_2
    )

    active_workspace = prepared_workspace.workspace
    transcriptomics_outputs = null
    methylomics_outputs = null
    metabolomics_outputs = null

    if (input_map.run_transcriptomics) {
        transcriptomics_outputs = RUN_TRANSCRIPTOMICS(
            active_workspace,
            input_map.transcriptomics_label,
            input_map.group_1,
            input_map.group_2
        )
        active_workspace = transcriptomics_outputs.workspace
    }

    if (input_map.run_methylomics) {
        methylomics_outputs = RUN_METHYLOMICS(
            active_workspace,
            input_map.methylomics_label,
            input_map.group_1,
            input_map.group_2
        )
        active_workspace = methylomics_outputs.workspace
    }

    if (input_map.run_metabolomics) {
        metabolomics_outputs = RUN_METABOLOMICS(
            active_workspace,
            input_map.metabolomics_label,
            input_map.group_1,
            input_map.group_2
        )
        active_workspace = metabolomics_outputs.workspace
    }

    if (input_map.run_mofa) {
        mofa_outputs = RUN_MOFA(
            active_workspace,
            input_map.group_1,
            input_map.group_2
        )
        active_workspace = mofa_outputs.workspace
    }

    if (input_map.compare_gold) {
        COMPARE_GOLD_STANDARD(
            active_workspace,
            input_map.gold_standard_dir,
            input_map.gold_manifest,
            input_map.gold_atol,
            input_map.gold_rtol
        )
    }

    emit:
    workspace = active_workspace
    transcriptomics = transcriptomics_outputs ? transcriptomics_outputs.transcriptomics : Channel.empty()
    methylomics = methylomics_outputs ? methylomics_outputs.methylomics : Channel.empty()
    metabolomics = metabolomics_outputs ? metabolomics_outputs.metabolomics : Channel.empty()
}

workflow {
    /*
     * Validate CLI parameters, convert paths to Nextflow file values, and
     * launch the reusable Main workflow.
     */
    run_transcriptomics = parseBool(params.run_transcriptomics)
    run_methylomics = parseBool(params.run_methylomics)
    run_metabolomics = parseBool(params.run_metabolomics)
    run_mofa = parseBool(params.run_mofa)
    compare_gold = parseBool(params.compare_gold)

    [
        biomix_root: params.biomix_root,
        command_dir: params.command_dir,
        metadata: params.metadata,
        group_1: params.group_1,
        group_2: params.group_2
    ].each { key, value ->
        if (!value?.toString()?.trim()) {
            error "Missing required parameter: --${key}"
        }
    }

    if (run_transcriptomics && !params.transcriptomics_matrix?.toString()?.trim()) {
        error "Missing required parameter: --transcriptomics_matrix"
    }
    if (run_methylomics && !params.methylomics_matrix?.toString()?.trim()) {
        error "Missing required parameter: --methylomics_matrix"
    }
    if (run_metabolomics && !params.metabolomics_matrix?.toString()?.trim()) {
        error "Missing required parameter: --metabolomics_matrix"
    }

    if (compare_gold) {
        if (!params.gold_standard_dir?.toString()?.trim()) {
            error "Missing required parameter: --gold_standard_dir"
        }
        if (!params.gold_manifest?.toString()?.trim()) {
            error "Missing required parameter: --gold_manifest"
        }
    }

    input_map = [
        biomix_root: file(params.biomix_root, checkIfExists: true),
        command_dir: file(params.command_dir, checkIfExists: true),
        transcriptomics_matrix: params.transcriptomics_matrix ? file(params.transcriptomics_matrix, checkIfExists: true) : "",
        methylomics_matrix: params.methylomics_matrix ? file(params.methylomics_matrix, checkIfExists: true) : "",
        metabolomics_matrix: params.metabolomics_matrix ? file(params.metabolomics_matrix, checkIfExists: true) : "",
        metadata: file(params.metadata, checkIfExists: true),
        group_1: params.group_1,
        group_2: params.group_2,
        transcriptomics_label: params.transcriptomics_label,
        methylomics_label: params.methylomics_label,
        metabolomics_label: params.metabolomics_label,
        run_mofa: run_mofa,
        run_transcriptomics: run_transcriptomics,
        run_methylomics: run_methylomics,
        run_metabolomics: run_metabolomics,
        compare_gold: compare_gold,
        gold_standard_dir: compare_gold ? file(params.gold_standard_dir, checkIfExists: true) : null,
        gold_manifest: compare_gold ? file(params.gold_manifest, checkIfExists: true) : null,
        gold_atol: params.gold_atol,
        gold_rtol: params.gold_rtol
    ]

    Main(input_map)
}
