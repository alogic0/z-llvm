#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="${FIXTURE:-test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll}"
target="${TARGET:-aarch64-unknown-linux-gnu}"
out="$tmp_dir/aarch64_object_boundary.out"
err="$tmp_dir/aarch64_object_boundary.err"

zig build >/dev/null

if zig-out/bin/z_llvm --emit=obj --target="$target" "$fixture" > "$out" 2> "$err"; then
    printf 'error: expected non-x86_64 object emission to remain outside the local boundary\n' >&2
    exit 1
fi

rg -q "unsupported codegen target: $target; supported target subset is x86_64-linux" "$err"
printf 'ok distribution aarch64 object boundary target=%s [unsupported-codegen-target]\n' "$target"
