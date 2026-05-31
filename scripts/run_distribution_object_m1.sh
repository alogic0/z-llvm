#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-test/distribution/releasefast_x86_64/manifest.tsv}"
target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

tail -n +2 "$manifest" | while IFS=$'\t' read -r id input validation expected_status source_row shape public_symbol; do
  case "$validation" in
    object-readelf)
      object="$tmp_dir/$id.o"
      summary="$tmp_dir/$id.readelf.txt"
      zig build run -- --emit=obj --target="$target" "$input" > "$object"
      readelf -W -h -S -s -r "$object" > "$summary"
      rg -q 'Type:[[:space:]]+REL' "$summary"
      rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$summary"
      rg -q '\.text' "$summary"
      rg -q '\.symtab' "$summary"
      if [[ -n "${public_symbol:-}" ]]; then
        rg -q "[[:space:]]${public_symbol}$" "$summary"
      fi
      if [[ "$id" == "atomics_atomic_add" ]]; then
        rg -q '\.data' "$summary"
        rg -q '\.rela\.text' "$summary"
        rg -q '[[:space:]]atomics_inline_asm_debug\.atomic_counter$' "$summary"
        rg -q 'R_X86_64_PC32.*atomics_inline_asm_debug\.atomic_counter - 4' "$summary"
      fi
      if [[ "$id" == "tls_concurrency_bump_tls" || "$id" == "tls_concurrency_read_tls" ]]; then
        rg -q '\.tdata' "$summary"
        rg -q 'TLS[[:space:]]+GLOBAL.*tls_concurrency\.tls_counter' "$summary"
        rg -q 'R_X86_64_TPOFF32.*tls_concurrency\.tls_counter' "$summary"
      fi
      printf 'ok distribution object %s [%s]\n' "$id" "$shape"
      ;;
    known-blocker)
      log="$tmp_dir/$id.stderr.txt"
      if zig build run -- --emit=obj --target="$target" "$input" > "$tmp_dir/$id.o" 2> "$log"; then
        printf 'unexpected object success for blocker %s [%s]\n' "$id" "$shape" >&2
        exit 1
      fi
      rg -q "$expected_status" "$log"
      printf 'ok distribution blocker %s [%s]\n' "$id" "$expected_status"
      ;;
    *)
      printf 'unknown validation type for %s: %s\n' "$id" "$validation" >&2
      exit 2
      ;;
  esac
done
