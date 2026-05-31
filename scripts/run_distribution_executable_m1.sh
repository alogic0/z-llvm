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

call_chain_fixture="test/distribution/releasefast_x86_64/inputs/control_flow_calls_call_chain.ll"
call_chain_object="$tmp_dir/control_flow_calls_call_chain.o"
call_chain_harness="$tmp_dir/call_chain_harness.c"
call_chain_exe="$tmp_dir/call_chain_harness"

zig build run -- --emit=obj --target="$target" "$call_chain_fixture" > "$call_chain_object"

cat > "$call_chain_harness" <<'C'
extern int call_chain(int value);

int main(void) {
    if (call_chain(0) != 1) return 1;
    if (call_chain(5) != 11) return 2;
    if (call_chain(17) != 35) return 3;
    return 0;
}
C

zig cc "$call_chain_harness" "$call_chain_object" -o "$call_chain_exe"
"$call_chain_exe"
printf 'ok distribution executable call_chain\n'

comptime_const_fixture="test/distribution/releasefast_x86_64/inputs/globals_comptime_const.ll"
comptime_const_object="$tmp_dir/globals_comptime_const.o"
comptime_const_harness="$tmp_dir/comptime_const_harness.c"
comptime_const_exe="$tmp_dir/comptime_const_harness"

zig build run -- --emit=obj --target="$target" "$comptime_const_fixture" > "$comptime_const_object"

cat > "$comptime_const_harness" <<'C'
extern int comptime_const(int value);

int main(void) {
    if (comptime_const(0) != 0) return 1;
    if (comptime_const(7) != 35) return 2;
    if (comptime_const(-3) != -15) return 3;
    return 0;
}
C

zig cc "$comptime_const_harness" "$comptime_const_object" -o "$comptime_const_exe"
"$comptime_const_exe"
printf 'ok distribution executable comptime_const\n'

optional_ptr_fixture="test/distribution/releasefast_x86_64/inputs/optional_pointer_value.ll"
optional_ptr_object="$tmp_dir/optional_pointer_value.o"
optional_ptr_harness="$tmp_dir/optional_ptr_harness.c"
optional_ptr_exe="$tmp_dir/optional_ptr_harness"

zig build run -- --emit=obj --target="$target" "$optional_ptr_fixture" > "$optional_ptr_object"

cat > "$optional_ptr_harness" <<'C'
#include <stddef.h>

extern int optional_ptr_value(const int *value);

int main(void) {
    int positive = 42;
    int negative = -9;
    if (optional_ptr_value(&positive) != 42) return 1;
    if (optional_ptr_value(&negative) != -9) return 2;
    if (optional_ptr_value(NULL) != -1) return 3;
    return 0;
}
C

zig cc "$optional_ptr_harness" "$optional_ptr_object" -o "$optional_ptr_exe"
"$optional_ptr_exe"
printf 'ok distribution executable optional_ptr_value\n'
