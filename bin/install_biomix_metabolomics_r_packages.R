#!/usr/bin/env Rscript

# Install R packages required by the BiomiX metabolomics wrapper.
#
# Conda provides most runtime dependencies, but cmmr, metid, and metpath are
# installed from their upstream Git repositories when local source tarballs are
# not provided. Bioconductor packages already present in the Conda environment
# are accepted to avoid unnecessary source compilation.

args <- commandArgs(trailingOnly = TRUE)
package_dir <- if (length(args) >= 1) normalizePath(args[[1]], mustWork = FALSE) else getwd()

# Install a package from a local tarball when available, otherwise from GitHub or
# GitLab. Existing exact-version installs are reused.
install_local_or_remote <- function(package, version, local_filename, remote, remote_type = c("github", "gitlab", "git")) {
  remote_type <- match.arg(remote_type)

  if (requireNamespace(package, quietly = TRUE)) {
    installed_version <- as.character(utils::packageVersion(package))
    if (identical(installed_version, version)) {
      message(sprintf("%s %s already installed.", package, version))
      return(invisible(TRUE))
    }
  }

  local_path <- file.path(package_dir, local_filename)
  if (file.exists(local_path)) {
    message(sprintf("Installing %s from %s", package, local_path))
    utils::install.packages(local_path, repos = NULL, type = "source")
    return(invisible(TRUE))
  }

  message(sprintf(
    "Installing %s from %s. Requested version %s is not available from conda; use %s for an exact local install.",
    package,
    remote,
    version,
    local_filename
  ))

  if (remote_type == "github") {
    remotes::install_github(remote, dependencies = TRUE, upgrade = "never")
  } else {
    if (remote_type == "gitlab") {
      remotes::install_gitlab(remote, dependencies = TRUE, upgrade = "never")
    } else {
      remotes::install_git(remote, dependencies = TRUE, upgrade = "never")
    }
  }

  invisible(TRUE)
}

# Ensure a Bioconductor package is available. Conda-installed builds are
# accepted even when their version differs from the historical BiomiX version.
install_bioconductor_package <- function(package, version, bioc_version) {
  if (requireNamespace(package, quietly = TRUE)) {
    installed_version <- as.character(utils::packageVersion(package))
    message(sprintf("%s %s already installed; expected %s.", package, installed_version, version))
    return(invisible(TRUE))
  }

  message(sprintf("Installing %s %s from Bioconductor %s", package, version, bioc_version))
  BiocManager::install(version = bioc_version, ask = FALSE, update = FALSE)
  BiocManager::install(package, ask = FALSE, update = FALSE)

  installed_version <- as.character(utils::packageVersion(package))
  if (!identical(installed_version, version)) {
    stop(sprintf(
      "Installed %s %s, but BiomiX metabolomics expects %s.",
      package,
      installed_version,
      version
    ), call. = FALSE)
  }

  invisible(TRUE)
}

install_bioconductor_package("ComplexHeatmap", "2.20.0", "3.19")
install_local_or_remote("cmmr", "1.0.5", "cmmr_1.0.5.tar.gz", "https://github.com/lzyacht/cmmr.git", "git")
install_local_or_remote("metid", "1.2.35", "metid_1.2.35.tar.gz", "https://gitlab.com/tidymass/metid.git", "git")
install_local_or_remote("metpath", "1.0.8", "metpath_1.0.8.tar.gz", "https://gitlab.com/tidymass/metpath.git", "git")
