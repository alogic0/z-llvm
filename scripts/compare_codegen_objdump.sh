#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

for input in test/codegen/inputs/*.ll; do
  id="$(basename "$input" .ll)"
  expected="test/codegen/expected/objdump/$id.txt"
  if [[ ! -f "$expected" ]]; then
    continue
  fi

  object="$tmp_dir/$id.o"
  actual="$tmp_dir/$id.objdump.txt"
  zig build run -- --emit=obj --target="$target" "$input" > "$object"
  objdump -dr "$object" | sed -n '/Disassembly of section .text:/,$p' > "$actual"
  diff -u "$expected" "$actual"
  printf 'ok codegen objdump %s\n' "$id"
done
