#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-docs/fixtures/zig_ir/manifest.tsv}"
passes="${PASSES:-verify,instcombine,dce}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

has_classification() {
  local classes=",$1,"
  local needle=",$2,"
  [[ "$classes" == *"$needle"* ]]
}

split_tsv_line() {
  local line="$1"
  local expected_fields="$2"
  local -n out_fields="$3"
  local rest="$line"

  out_fields=()
  for ((field_index = 1; field_index < expected_fields; field_index += 1)); do
    if [[ "$rest" == *$'\t'* ]]; then
      out_fields+=("${rest%%$'\t'*}")
      rest="${rest#*$'\t'}"
    else
      out_fields+=("$rest")
      rest=""
    fi
  done
  out_fields+=("$rest")
}

while IFS= read -r line; do
  fields=()
  split_tsv_line "$line" 14 fields

  id="${fields[0]}"
  group="${fields[1]}"
  optimize_mode="${fields[7]}"
  checked_ir_path="${fields[10]}"
  classification="${fields[11]}"

  if [[ -z "${id:-}" || "$id" == \#* ]]; then
    continue
  fi
  if [[ -z "${checked_ir_path:-}" ]]; then
    continue
  fi
  if has_classification "$classification" "unsupported"; then
    continue
  fi
  if ! has_classification "$classification" "parse"; then
    continue
  fi
  if ! has_classification "$classification" "verify"; then
    continue
  fi
  if ! has_classification "$classification" "optimizer-input"; then
    continue
  fi

  output="$tmp_dir/$id.ll"
  zig build run -- --passes="$passes" "$checked_ir_path" > "$output"
  zig run src/normalize_cli.zig -- "$output" > /dev/null
  printf 'ok %s [%s %s: %s]\n' "$id" "$group" "$optimize_mode" "$passes"
done < "$manifest"
