#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for input in test/codegen/inputs/*.ll; do
  id="$(basename "$input" .ll)"
  expected="test/codegen/expected/asm/$id.s"
  if [[ ! -f "$expected" ]]; then
    continue
  fi

  actual="$tmp_dir/$id.s"
  zig build run -- --emit=asm --target="$target" "$input" > "$actual"
  diff -u "$expected" "$actual"
  printf 'ok codegen asm %s\n' "$id"
done
