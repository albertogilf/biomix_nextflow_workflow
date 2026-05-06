#!/usr/bin/env python3
"""Compare generated BiomiX TSV outputs with gold-standard files.

The manifest lists paths relative to a BiomiX workspace root. Each listed file
is parsed as tab-separated text, optionally aligned by ``ID`` or an unnamed R
row-name column, and compared with numeric tolerances for floating-point output.
If a file has a ``.tsv`` suffix but is not text, the comparator falls back to
byte-for-byte comparison so mislabelled BiomiX artifacts can still be tested.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
from pathlib import Path


def parse_args() -> argparse.Namespace:
    """Parse command-line arguments for a gold-standard comparison run."""
    parser = argparse.ArgumentParser(description="Compare workflow outputs against a BiomiX gold standard.")
    parser.add_argument("--actual-root", required=True)
    parser.add_argument("--gold-root", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--atol", type=float, default=1e-4)
    parser.add_argument("--rtol", type=float, default=1e-4)
    return parser.parse_args()


def read_tsv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    """Read a TSV file and preserve an unnamed leading R row-name column."""
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle, delimiter="\t")
        try:
            fieldnames = next(reader)
        except StopIteration:
            return [], []

        rows = []
        for values in reader:
            row = {}
            if len(values) == len(fieldnames) + 1:
                row["__index__"] = values[0]
                values = values[1:]
            for name, value in zip(fieldnames, values):
                row[name] = value
            rows.append(row)

    return fieldnames, rows


def parse_float(value: str) -> float | None:
    """Return a float for numeric-like text, NaN for missing text, or None."""
    if value in {"", "NA", "NaN", "nan"}:
        return math.nan
    try:
        return float(value)
    except ValueError:
        return None


def numeric_values_close(actual: str, gold: str, atol: float, rtol: float) -> bool:
    """Compare two numeric text values with absolute and relative tolerances."""
    actual_float = parse_float(actual)
    gold_float = parse_float(gold)

    if actual_float is None or gold_float is None:
        return False
    if math.isnan(actual_float) and math.isnan(gold_float):
        return True
    return math.isclose(actual_float, gold_float, abs_tol=atol, rel_tol=rtol)


def compare_frames(
    actual: tuple[list[str], list[dict[str, str]]],
    gold: tuple[list[str], list[dict[str, str]]],
    atol: float,
    rtol: float,
) -> list[str]:
    """Return human-readable differences between two parsed TSV frames."""
    errors: list[str] = []
    actual_columns, actual_rows = actual
    gold_columns, gold_rows = gold

    if actual_columns != gold_columns:
        errors.append("Column names differ.")
        return errors

    # BiomiX output tables can be identical up to row ordering, so align by
    # row identifier before comparing values.
    if "ID" in actual_columns:
        actual_rows = sorted(actual_rows, key=lambda row: row.get("ID") or "")
        gold_rows = sorted(gold_rows, key=lambda row: row.get("ID") or "")
    elif any("__index__" in row for row in actual_rows + gold_rows):
        actual_rows = sorted(actual_rows, key=lambda row: row.get("__index__") or "")
        gold_rows = sorted(gold_rows, key=lambda row: row.get("__index__") or "")

    actual_shape = (len(actual_rows), len(actual_columns))
    gold_shape = (len(gold_rows), len(gold_columns))
    if actual_shape != gold_shape:
        errors.append(f"Shape differs: actual={actual_shape}, gold={gold_shape}.")
        return errors

    for column in actual_columns:
        actual_values = [row.get(column, "") for row in actual_rows]
        gold_values = [row.get(column, "") for row in gold_rows]
        numeric_actual = [parse_float(value) for value in actual_values]
        numeric_gold = [parse_float(value) for value in gold_values]

        if all(value is not None for value in numeric_actual) and all(
            value is not None for value in numeric_gold
        ):
            if not all(
                numeric_values_close(actual_value, gold_value, atol, rtol)
                for actual_value, gold_value in zip(actual_values, gold_values)
            ):
                errors.append(f"Numeric values differ in column '{column}'.")
        elif actual_values != gold_values:
            errors.append(f"String values differ in column '{column}'.")

    return errors


def compare_manifest_file(actual_path: Path, gold_path: Path, atol: float, rtol: float) -> list[str]:
    """Compare one manifest file as TSV text or, for non-text files, as bytes."""
    try:
        actual_frame = read_tsv(actual_path)
        gold_frame = read_tsv(gold_path)
    except UnicodeDecodeError:
        if actual_path.read_bytes() != gold_path.read_bytes():
            return ["Binary file bytes differ."]
        return []

    return compare_frames(actual_frame, gold_frame, atol, rtol)


def main() -> None:
    """Load the manifest, compare each listed TSV, and write a JSON report."""
    args = parse_args()

    actual_root = Path(args.actual_root).resolve()
    gold_root = Path(args.gold_root).resolve()
    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))

    results = []

    for entry in manifest["files"]:
        relative_path = Path(entry["relative_path"])
        actual_path = actual_root / relative_path
        gold_path = gold_root / relative_path

        file_result = {
            "relative_path": str(relative_path),
            "actual_exists": actual_path.exists(),
            "gold_exists": gold_path.exists(),
            "passed": False,
            "errors": [],
        }

        if not actual_path.exists():
            file_result["errors"].append("Actual file is missing.")
        if not gold_path.exists():
            file_result["errors"].append("Gold file is missing.")

        if file_result["errors"]:
            results.append(file_result)
            continue

        file_result["errors"] = compare_manifest_file(actual_path, gold_path, args.atol, args.rtol)
        file_result["passed"] = not file_result["errors"]
        results.append(file_result)

    failed = [result for result in results if not result["passed"]]
    report = {
        "passed": not failed,
        "files": results,
    }

    Path(args.report).write_text(json.dumps(report, indent=2), encoding="utf-8")

    if failed:
        raise SystemExit("Gold-standard comparison failed.")


if __name__ == "__main__":
    main()
