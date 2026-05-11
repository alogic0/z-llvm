#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-docs/fixtures/zig_ir/manifest.tsv}"
passes="${PASSES:-verify,instcombine,dce}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

while IFS=$'\t' read -r id group source zig_emitter zig_source_revision target_arg emitted_target_triple optimize_mode command raw_ir_path checked_ir_path classification inventory_links notes; do
  if [[ -z "${id:-}" || "$id" == \#* ]]; then
    continue
  fi
  if [[ -z "${checked_ir_path:-}" ]]; then
    continue
  fi
  if [[ ",${classification}," != *",optimizer-input,"* ]]; then
    continue
  fi

  output="$tmp_dir/$id.ll"
  zig build run -- --passes="$passes" "$checked_ir_path" > "$output"
  zig run src/normalize_cli.zig -- "$output" > /dev/null
  printf 'ok %s [%s %s: %s]\n' "$id" "$group" "$optimize_mode" "$passes"
done < "$manifest"
