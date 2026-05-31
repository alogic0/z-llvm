#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

add_wrap_fixture="test/distribution/releasefast_x86_64/inputs/integers_add_wrap.ll"
add_wrap_object="$tmp_dir/integers_add_wrap.o"
add_wrap_harness="$tmp_dir/add_wrap_harness.c"
add_wrap_exe="$tmp_dir/add_wrap_harness"

zig build run -- --emit=obj --target="$target" "$add_wrap_fixture" > "$add_wrap_object"

cat > "$add_wrap_harness" <<'C'
extern int add_wrap(int a, int b);

int main(void) {
    if (add_wrap(40, 2) != 42) return 1;
    if (add_wrap(-1, 1) != 0) return 2;
    if (add_wrap(2147483647, 1) != -2147483648) return 3;
    return 0;
}
C

zig cc "$add_wrap_harness" "$add_wrap_object" -o "$add_wrap_exe"
"$add_wrap_exe"
printf 'ok distribution executable add_wrap\n'

branch_mix_fixture="test/distribution/releasefast_x86_64/inputs/switch_control_branch_mix.ll"
branch_mix_object="$tmp_dir/switch_control_branch_mix.o"
branch_mix_harness="$tmp_dir/branch_mix_harness.c"
branch_mix_exe="$tmp_dir/branch_mix_harness"

zig build run -- --emit=obj --target="$target" "$branch_mix_fixture" > "$branch_mix_object"

cat > "$branch_mix_harness" <<'C'
#include <stdbool.h>

extern int branch_mix(int a, int b, bool flag);

int main(void) {
    if (branch_mix(10, 3, true) != 13) return 1;
    if (branch_mix(10, 3, false) != 7) return 2;
    if (branch_mix(-2, 5, true) != 3) return 3;
    if (branch_mix(-2, 5, false) != -7) return 4;
    return 0;
}
C

zig cc "$branch_mix_harness" "$branch_mix_object" -o "$branch_mix_exe"
"$branch_mix_exe"
printf 'ok distribution executable branch_mix\n'
