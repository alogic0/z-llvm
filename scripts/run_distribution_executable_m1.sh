#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture="test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll"
object="$tmp_dir/integers_add_wrap.o"
harness="$tmp_dir/add_wrap_harness.c"
exe="$tmp_dir/add_wrap_harness"

zig build run -- --emit=obj --target="$target" "$fixture" > "$object"

cat > "$harness" <<'C'
extern int add_wrap(int a, int b);

int main(void) {
    if (add_wrap(40, 2) != 42) return 1;
    if (add_wrap(-1, 1) != 0) return 2;
    if (add_wrap(2147483647, 1) != -2147483648) return 3;
    return 0;
}
C

zig cc "$harness" "$object" -o "$exe"
"$exe"
printf 'ok distribution executable add_wrap\n'
