#!/usr/bin/env bash
set -euo pipefail

opt_bin="${OPT_BIN:-opt-22}"
metadata="${1:-test/opt/fixtures.tsv}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

while IFS=$'\t' read -r id z_pass llvm_pass input_path expected_path fixture_kind inventory_passes notes; do
  if [[ -z "${id:-}" || "$id" == \#* ]]; then
    continue
  fi

  z_raw="$tmp_dir/$id.z.raw.ll"
  z_norm="$tmp_dir/$id.z.norm.ll"
  expected_norm="$tmp_dir/$id.expected.norm.ll"
  zig build run -- --passes="$z_pass" "$input_path" > "$z_raw"

  zig run src/normalize_cli.zig -- "$z_raw" > "$z_norm"
  zig run src/normalize_cli.zig -- "$expected_path" > "$expected_norm"

  diff -u "$expected_norm" "$z_norm"

  case "$fixture_kind" in
    opt-equivalent)
      llvm_raw="$tmp_dir/$id.llvm.raw.ll"
      llvm_norm="$tmp_dir/$id.llvm.norm.ll"
      "$opt_bin" -passes="$llvm_pass" "$input_path" -S -o "$llvm_raw"
      zig run src/normalize_cli.zig -- "$llvm_raw" > "$llvm_norm"
      diff -u "$llvm_norm" "$z_norm"
      ;;
    local-conservative|parse-preserve-only)
      ;;
    *)
      printf 'unknown fixture kind for %s: %s\n' "$id" "$fixture_kind" >&2
      exit 1
      ;;
  esac

  printf 'ok %s [%s: %s] (%s)\n' "$id" "$fixture_kind" "$inventory_passes" "$notes"
done < "$metadata"
