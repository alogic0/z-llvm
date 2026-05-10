#!/usr/bin/env bash
set -euo pipefail

opt_bin="${OPT_BIN:-opt-22}"
metadata="${1:-test/opt/fixtures.tsv}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

while IFS=$'\t' read -r id z_pass llvm_pass input_path expected_path notes; do
  if [[ -z "${id:-}" || "$id" == \#* ]]; then
    continue
  fi

  z_raw="$tmp_dir/$id.z.raw.ll"
  z_norm="$tmp_dir/$id.z.norm.ll"
  expected_norm="$tmp_dir/$id.expected.norm.ll"
  llvm_raw="$tmp_dir/$id.llvm.raw.ll"
  llvm_norm="$tmp_dir/$id.llvm.norm.ll"

  zig build run -- --passes="$z_pass" "$input_path" > "$z_raw"
  "$opt_bin" -passes="$llvm_pass" "$input_path" -S -o "$llvm_raw"

  zig run src/normalize_cli.zig -- "$z_raw" > "$z_norm"
  zig run src/normalize_cli.zig -- "$expected_path" > "$expected_norm"
  zig run src/normalize_cli.zig -- "$llvm_raw" > "$llvm_norm"

  diff -u "$expected_norm" "$z_norm"
  diff -u "$llvm_norm" "$z_norm"
  printf 'ok %s (%s)\n' "$id" "$notes"
done < "$metadata"
