#!/usr/bin/env python3

from __future__ import annotations

import argparse
import csv
import shutil
from pathlib import Path

REQUIRED_COMMAND_FILES = (
    "COMMANDS.tsv",
    "COMMANDS_MOFA.tsv",
    "COMMANDS_ADVANCED.tsv",
)

REQUIRED_BIOMIX_PATHS = (
    "Converter_JSON.r",
    "Integration",
    "Transcriptomics",
    "Methylomics",
    "Metadata",
)

JSON_SOURCE_PATTERNS = (
    'jsonlite::fromJSON(txt = "COMBINED_COMMANDS.json")',
    'jsonlite::fromJSON(txt = "COMBINED_COMMANDS.json")',
    'fromJSON(txt = "COMBINED_COMMANDS.json")',
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Stage a non-interactive BiomiX workspace.")
    parser.add_argument("--source-root", required=True)
    parser.add_argument("--dest-root", required=True)
    parser.add_argument("--command-dir", required=True)
    parser.add_argument("--transcriptomics-matrix", required=True)
    parser.add_argument("--methylomics-matrix", default="")
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--transcriptomics-label", required=True)
    parser.add_argument("--methylomics-label", default="METHY")
    parser.add_argument("--output-dir", required=True)
    return parser.parse_args()


def copy_required_tree(source_root: Path, dest_root: Path) -> None:
    dest_root.mkdir(parents=True, exist_ok=True)

    for relative_path in REQUIRED_BIOMIX_PATHS:
        source_path = source_root / relative_path
        dest_path = dest_root / relative_path
        if source_path.is_dir():
            shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
        else:
            dest_path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, dest_path)


def copy_command_files(command_dir: Path, dest_root: Path) -> None:
    for filename in REQUIRED_COMMAND_FILES:
        source_path = command_dir / filename
        if not source_path.exists():
            raise FileNotFoundError(f"Missing required command file: {source_path}")
        shutil.copy2(source_path, dest_root / filename)


def patch_json_loading(dest_root: Path) -> None:
    replacement = 'jsonlite::fromJSON(txt = paste(readLines("COMBINED_COMMANDS.json", warn = FALSE), collapse = "\\n"))'
    for path in dest_root.rglob("*.r"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        updated = text
        for pattern in JSON_SOURCE_PATTERNS:
            updated = updated.replace(pattern, replacement)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def patch_commands(
    command_path: Path,
    transcriptomics_filename: str,
    transcriptomics_label: str,
    methylomics_filename: str,
    methylomics_label: str,
) -> None:
    with command_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        fieldnames = list(reader.fieldnames or [])
        commands = list(reader)

    if not fieldnames:
        raise ValueError(f"COMMANDS.tsv is empty: {command_path}")

    if fieldnames[0].startswith("Unnamed:"):
        old_name = fieldnames[0]
        fieldnames[0] = ""
        for row in commands:
            row[""] = row.pop(old_name)

    transcriptomics_rows = [
        row for row in commands if row.get("DATA_TYPE") == "Transcriptomics"
    ]
    if len(transcriptomics_rows) != 1:
        raise ValueError(
            "Expected exactly one Transcriptomics row in COMMANDS.tsv for the first workflow slice."
        )

    transcriptomics_rows[0]["DIRECTORIES"] = transcriptomics_filename
    transcriptomics_rows[0]["LABEL"] = transcriptomics_label

    methylomics_rows = [
        row for row in commands if row.get("DATA_TYPE") == "Methylomics"
    ]
    if methylomics_rows:
        if methylomics_filename:
            for row in methylomics_rows:
                row["DIRECTORIES"] = methylomics_filename
                row["LABEL"] = methylomics_label
                row["ANALYSIS"] = "YES"
        else:
            for row in methylomics_rows:
                row["ANALYSIS"] = "NO"
                row["INTEGRATION"] = "NO"

    for row in commands:
        row["PREVIEW"] = "NO"

    with command_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        writer.writerows(commands)


def main() -> None:
    args = parse_args()

    source_root = Path(args.source_root).resolve()
    dest_root = Path(args.dest_root).resolve()
    command_dir = Path(args.command_dir).resolve()
    transcriptomics_matrix = Path(args.transcriptomics_matrix).resolve()
    metadata = Path(args.metadata).resolve()
    output_dir = Path(args.output_dir).resolve()

    copy_required_tree(source_root, dest_root)
    copy_command_files(command_dir, dest_root)
    patch_json_loading(dest_root)
    patch_commands(
        dest_root / "COMMANDS.tsv",
        transcriptomics_matrix.name,
        args.transcriptomics_label,
        Path(args.methylomics_matrix).name if args.methylomics_matrix else "",
        args.methylomics_label,
    )

    transcriptomics_input_dir = dest_root / "Transcriptomics" / "INPUT"
    transcriptomics_input_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(transcriptomics_matrix, transcriptomics_input_dir / transcriptomics_matrix.name)

    if args.methylomics_matrix:
        methylomics_matrix = Path(args.methylomics_matrix).resolve()
        methylomics_input_dir = dest_root / "Methylomics" / "INPUT"
        methylomics_input_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(methylomics_matrix, methylomics_input_dir / methylomics_matrix.name)

    metadata_dir = dest_root / "Metadata"
    metadata_dir.mkdir(parents=True, exist_ok=True)
    staged_metadata = metadata_dir / metadata.name
    shutil.copy2(metadata, staged_metadata)

    (dest_root / "directory.txt").write_text(f"{staged_metadata}\n", encoding="utf-8")
    (dest_root / "directory_out.txt").write_text(f"{output_dir}\n", encoding="utf-8")


if __name__ == "__main__":
    main()
