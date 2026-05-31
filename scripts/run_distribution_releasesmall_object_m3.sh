#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="test/distribution/releasesmall_x86_64/inputs/export_keyword_vram_store.ll"
object="$tmp_dir/export_keyword_vram_store.o"
summary="$tmp_dir/export_keyword_vram_store.readelf.txt"
dump="$tmp_dir/export_keyword_vram_store.objdump.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$object"
readelf -W -h -S -s -r "$object" > "$summary"
objdump -dr "$object" > "$dump"

rg -q 'Type:[[:space:]]+REL' "$summary"
rg -q 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$summary"
rg -q '[[:space:]]testPackedStuff$' "$summary"
rg -q '[[:space:]]writeToVRam$' "$summary"
rg -q 'movb[[:space:]]+\$0x58,0x20000000' "$dump"

printf 'ok distribution releasesmall object export_keyword_vram_store\n'
