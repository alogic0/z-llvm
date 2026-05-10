#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for input in test/codegen/inputs/call_*.ll; do
  id="$(basename "$input" .ll)"
  object="$tmp_dir/$id.o"
  actual="$tmp_dir/$id.readelf.txt"
  zig build run -- --emit=obj --target="$target" "$input" > "$object"
  readelf -r -s "$object" > "$actual"
  rg -q "R_X86_64_PLT32" "$actual"
  rg -q "callee" "$actual"
  printf 'ok codegen readelf %s\n' "$id"
done
