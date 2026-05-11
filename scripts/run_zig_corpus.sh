#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-docs/fixtures/zig_ir/manifest.tsv}"
passes_override="${PASSES:-}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

has_classification() {
  local classes=",$1,"
  local needle=",$2,"
  [[ "$classes" == *"$needle"* ]]
}

metadata_value() {
  local metadata="$1"
  local key="$2"
  local token
  local -a tokens
  IFS=';' read -r -a tokens <<< "$metadata"
  for token in "${tokens[@]}"; do
    if [[ "$token" == "$key="* ]]; then
      printf '%s\n' "${token#*=}"
      return 0
    fi
  done
  return 1
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

accepted_rows=0
unsupported_rows=0
future_rows=0
debug_only_rows=0

while IFS= read -r line; do
  fields=()
  split_tsv_line "$line" 14 fields

  id="${fields[0]}"
  group="${fields[1]}"
  optimize_mode="${fields[7]}"
  checked_ir_path="${fields[10]}"
  classification="${fields[11]}"
  inventory_links="${fields[12]}"

  if [[ -z "${id:-}" || "$id" == \#* ]]; then
    continue
  fi
  if has_classification "$classification" "unsupported"; then
    unsupported_rows=$((unsupported_rows + 1))
  fi
  if has_classification "$classification" "future"; then
    future_rows=$((future_rows + 1))
  fi
  if has_classification "$classification" "debug-info-only"; then
    debug_only_rows=$((debug_only_rows + 1))
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

  passes="$passes_override"
  if [[ -z "$passes" ]]; then
    passes="$(metadata_value "$inventory_links" "local-pipeline" || true)"
  fi
  if [[ -z "$passes" ]]; then
    printf 'missing local-pipeline metadata for accepted row %s\n' "$id" >&2
    exit 1
  fi

  output="$tmp_dir/$id.ll"
  zig build run -- --passes="$passes" "$checked_ir_path" > "$output"
  zig run src/normalize_cli.zig -- "$output" > /dev/null
  accepted_rows=$((accepted_rows + 1))
  printf 'ok %s [%s %s: %s]\n' "$id" "$group" "$optimize_mode" "$passes"
done < "$manifest"

printf 'summary accepted=%d unsupported=%d future=%d debug-info-only=%d\n' \
  "$accepted_rows" "$unsupported_rows" "$future_rows" "$debug_only_rows"
