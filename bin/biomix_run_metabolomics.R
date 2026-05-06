#!/usr/bin/env Rscript

# BiomiX metabolomics wrapper for non-interactive Nextflow execution.
#
# The script prepares the global variables expected by the upstream BiomiX
# metabolomics module and sources the staged BiomiX R code from the task
# workspace. It is intentionally thin so the BiomiX source tree remains
# unchanged and workflow-specific behavior stays in wrappers.

cli_args <- commandArgs(trailingOnly = TRUE)

# Return the value following a required command-line flag.
parse_arg <- function(flag) {
  position <- match(flag, cli_args)
  if (is.na(position) || position == length(cli_args)) {
    stop(sprintf("Missing required argument: %s", flag), call. = FALSE)
  }
  cli_args[[position + 1]]
}

workspace <- normalizePath(parse_arg("--workspace"), winslash = "/", mustWork = TRUE)
group1 <- parse_arg("--group1")
group2 <- parse_arg("--group2")
label <- parse_arg("--label")

setwd(workspace)
combined_json <- jsonlite::fromJSON(
  txt = paste(readLines(file.path(workspace, "COMBINED_COMMANDS.json"), warn = FALSE), collapse = "\n")
)

commands <- read.delim(
  file.path(workspace, "COMMANDS.tsv"),
  sep = "\t",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

target_rows <- which(commands$DATA_TYPE == "Metabolomics" & commands$ANALYSIS == "YES")
if (nzchar(label)) {
  target_rows <- target_rows[commands$LABEL[target_rows] == label]
}

if (length(target_rows) != 1) {
  stop("Expected exactly one active metabolomics command row.", call. = FALSE)
}

assign("args", as.list(c(group1, group2, workspace)), envir = .GlobalEnv)
assign("directory", workspace, envir = .GlobalEnv)
assign("i", target_rows[[1]], envir = .GlobalEnv)
assign("iterations", 1, envir = .GlobalEnv)
assign("selection_samples", commands$SELECTION[[target_rows[[1]]]], envir = .GlobalEnv)
assign("Cell_type", commands$LABEL[[target_rows[[1]]]], envir = .GlobalEnv)
assign("STATISTICS", "YES", envir = .GlobalEnv)
assign("combined_json", combined_json, envir = .GlobalEnv)
assign("COMMAND", combined_json[["COMMANDS"]], envir = .GlobalEnv)
assign("COMMAND_MOFA", combined_json[["COMMANDS_MOFA"]], envir = .GlobalEnv)
assign("COMMAND_ADVANCED", combined_json[["COMMANDS_ADVANCED"]], envir = .GlobalEnv)
assign("DIR_METADATA", combined_json[["DIRECTORY_INFO"]][["METADATA_DIR"]], envir = .GlobalEnv)
assign("DIR_METADATA_output", combined_json[["DIRECTORY_INFO"]][["OUTPUT_DIR"]], envir = .GlobalEnv)

source(file.path(workspace, "Metabolomics", "BiomiX_DMA.r"), local = globalenv())
