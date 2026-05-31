#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="${FIXTURE:-test/zig/expected/debug_metadata.reduced.ll}"
object="$tmp_dir/debug_metadata_boundary.o"
summary="$tmp_dir/debug_metadata_boundary.readelf.txt"

zig build run -- --emit=obj --target="$target" --input-limit=67108864 "$fixture" > "$object"
readelf -W -S "$object" > "$summary"

rg -q '\.text' "$summary"
if rg -q '\.(debug|eh_frame)' "$summary"; then
    printf 'error: debug/unwind sections are outside the selected object boundary\n' >&2
    exit 1
fi

printf 'ok distribution debug unwind boundary target=%s [no-dwarf-or-unwind-sections]\n' "$target"
