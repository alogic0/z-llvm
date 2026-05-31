#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

help_out="$tmp_dir/help.txt"
exe_out="$tmp_dir/emit_exe.out"
exe_err="$tmp_dir/emit_exe.err"
fixture="test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll"

zig build run -- --help > "$help_out"
rg -q 'usage: z_llvm \[--emit=ir\|asm\|obj\]' "$help_out"

if zig build run -- --emit=exe --target=x86_64-unknown-linux-gnu "$fixture" > "$exe_out" 2> "$exe_err"; then
    printf 'error: expected --emit=exe to remain outside the local distribution boundary\n' >&2
    exit 1
fi

rg -q 'UnsupportedEmitMode' "$exe_err"
rg -q 'zig cc -target "\$cc_target"' scripts/run_distribution_executable_m1.sh
rg -q 'zig cc -target "\$cc_target"' scripts/run_distribution_releasesafe_object_m2.sh
rg -q 'zig cc -target "\$cc_target"' scripts/run_distribution_releasesmall_executable_m3.sh
rg -q 'zig cc -target "\$cc_target"' scripts/run_distribution_debug_executable_m4.sh

printf 'ok distribution linker boundary [local emit=ir/asm/obj, executable handoff=zig cc]\n'
