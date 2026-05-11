#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-docs/fixtures/zig_ir/manifest.tsv}"
expected_fields=14

split_tsv_line() {
  local line="$1"
  local -n out_fields="$2"
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

field_count() {
  local line="$1"
  local without_tabs="${line//$'\t'/}"
  printf '%d\n' "$(( ${#line} - ${#without_tabs} + 1 ))"
}

has_classification() {
  local classes=",$1,"
  local needle=",$2,"
  [[ "$classes" == *"$needle"* ]]
}

line_no=0
rows=0
accepted=0

while IFS= read -r line; do
  line_no=$((line_no + 1))
  if [[ -z "$line" ]]; then
    continue
  fi
  if [[ "$line" == \#* ]]; then
    continue
  fi

  actual_fields="$(field_count "$line")"
  if [[ "$actual_fields" -ne "$expected_fields" ]]; then
    printf '%s:%d expected %d TSV fields, found %d\n' "$manifest" "$line_no" "$expected_fields" "$actual_fields" >&2
    exit 1
  fi

  fields=()
  split_tsv_line "$line" fields

  id="${fields[0]}"
  if [[ -z "${id:-}" ]]; then
    continue
  fi

  rows=$((rows + 1))
  source_path="${fields[2]}"
  raw_ir_path="${fields[9]}"
  checked_ir_path="${fields[10]}"
  classification="${fields[11]}"
  inventory_links="${fields[12]}"

  if [[ "$source_path" == test/zig/inputs/* && ! -f "$source_path" ]]; then
    printf '%s:%d missing source path: %s\n' "$manifest" "$line_no" "$source_path" >&2
    exit 1
  fi

  if [[ -n "$checked_ir_path" && ! -f "$checked_ir_path" ]]; then
    printf '%s:%d missing checked IR path: %s\n' "$manifest" "$line_no" "$checked_ir_path" >&2
    exit 1
  fi

  if [[ "$raw_ir_path" == test/zig/captured/* && ! -f "$raw_ir_path" ]]; then
    printf '%s:%d missing captured raw IR path: %s\n' "$manifest" "$line_no" "$raw_ir_path" >&2
    exit 1
  fi

  if has_classification "$classification" "unsupported" && has_classification "$classification" "optimizer-input"; then
    printf '%s:%d unsupported row cannot be optimizer-input: %s\n' "$manifest" "$line_no" "$id" >&2
    exit 1
  fi

  if has_classification "$classification" "optimizer-input"; then
    accepted=$((accepted + 1))
    if [[ -z "$checked_ir_path" ]]; then
      printf '%s:%d optimizer-input row needs checked_ir_path: %s\n' "$manifest" "$line_no" "$id" >&2
      exit 1
    fi
    if ! has_classification "$classification" "parse" || ! has_classification "$classification" "verify"; then
      printf '%s:%d optimizer-input row must also be parse,verify: %s\n' "$manifest" "$line_no" "$id" >&2
      exit 1
    fi
    if [[ "$inventory_links" != *"local-pipeline="* ]]; then
      printf '%s:%d optimizer-input row needs local-pipeline metadata: %s\n' "$manifest" "$line_no" "$id" >&2
      exit 1
    fi
  fi
done < "$manifest"

printf 'ok manifest rows=%d optimizer_input=%d\n' "$rows" "$accepted"
