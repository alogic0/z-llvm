#!/usr/bin/env bash
set -euo pipefail

target="${TARGET:-x86_64-unknown-linux-gnu}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

tiny_scalar_fixture="test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll"
tiny_scalar_object="$tmp_dir/tiny_scalar.o"
tiny_scalar_harness="$tmp_dir/tiny_scalar_harness.c"
tiny_scalar_exe="$tmp_dir/tiny_scalar_harness"

zig build run -- --emit=obj --target="$target" "$tiny_scalar_fixture" > "$tiny_scalar_object"

cat > "$tiny_scalar_harness" <<'C'
extern void sideEffectFree(void);
extern int add(int a, int b);

int main(void) {
    sideEffectFree();
    if (add(40, 2) != 42) return 1;
    if (add(-5, 8) != 3) return 2;
    return 0;
}
C

zig cc "$tiny_scalar_harness" "$tiny_scalar_object" -o "$tiny_scalar_exe"
"$tiny_scalar_exe"
printf 'ok distribution executable tiny_scalar\n'

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

dense_switch_fixture="test/distribution/releasefast_x86_64/inputs/switch_control_dense_switch.ll"
dense_switch_object="$tmp_dir/switch_control_dense_switch.o"
dense_switch_harness="$tmp_dir/dense_switch_harness.c"
dense_switch_exe="$tmp_dir/dense_switch_harness"

zig build run -- --emit=obj --target="$target" "$dense_switch_fixture" > "$dense_switch_object"

cat > "$dense_switch_harness" <<'C'
extern int dense_switch(unsigned char value);

int main(void) {
    if (dense_switch(0) != 11) return 1;
    if (dense_switch(1) != 13) return 2;
    if (dense_switch(2) != 17) return 3;
    if (dense_switch(3) != 19) return 4;
    if (dense_switch(5) != 19) return 5;
    if (dense_switch(6) != 23) return 6;
    if (dense_switch(255) != 23) return 7;
    return 0;
}
C

zig cc "$dense_switch_harness" "$dense_switch_object" -o "$dense_switch_exe"
"$dense_switch_exe"
printf 'ok distribution executable dense_switch\n'

aggregate_abi_fixture="test/distribution/releasefast_x86_64/inputs/aggregate_abi_pair.ll"
aggregate_abi_object="$tmp_dir/aggregate_abi_pair.o"
aggregate_abi_harness="$tmp_dir/aggregate_abi_harness.c"
aggregate_abi_exe="$tmp_dir/aggregate_abi_harness"

zig build run -- --emit=obj --target="$target" "$aggregate_abi_fixture" > "$aggregate_abi_object"

cat > "$aggregate_abi_harness" <<'C'
extern int pair_first(long long pair);
extern long long make_pair(int first, int second);

int main(void) {
    if (pair_first(0x000000020000002aLL) != 42) return 1;
    if (pair_first(-1LL) != -1) return 2;
    if (make_pair(0x11223344, 0x55667788) != ((0x55667788LL << 32) | 0x11223344LL)) return 3;
    if (make_pair(-1, 0) != 0x00000000ffffffffLL) return 4;
    return 0;
}
C

zig cc "$aggregate_abi_harness" "$aggregate_abi_object" -o "$aggregate_abi_exe"
"$aggregate_abi_exe"
printf 'ok distribution executable aggregate_abi_pair\n'

aggregates_error_fixture="test/distribution/releasefast_x86_64/inputs/aggregates_error_union_payload.ll"
aggregates_error_object="$tmp_dir/aggregates_error_union_payload.o"
aggregates_error_harness="$tmp_dir/aggregates_error_union_payload_harness.c"
aggregates_error_exe="$tmp_dir/aggregates_error_union_payload_harness"

zig build run -- --emit=obj --target="$target" "$aggregates_error_fixture" > "$aggregates_error_object"

cat > "$aggregates_error_harness" <<'C'
extern int error_union_payload(int tag);

int main(void) {
    if (error_union_payload(0) != 7) return 1;
    if (error_union_payload(1) != -1) return 2;
    if (error_union_payload(-3) != -1) return 3;
    return 0;
}
C

zig cc "$aggregates_error_harness" "$aggregates_error_object" -o "$aggregates_error_exe"
"$aggregates_error_exe"
printf 'ok distribution executable aggregates_error_union_payload\n'

aggregates_optional_fixture="test/distribution/releasefast_x86_64/inputs/aggregates_optional_payload.ll"
aggregates_optional_object="$tmp_dir/aggregates_optional_payload.o"
aggregates_optional_harness="$tmp_dir/aggregates_optional_payload_harness.c"
aggregates_optional_exe="$tmp_dir/aggregates_optional_payload_harness"

zig build run -- --emit=obj --target="$target" "$aggregates_optional_fixture" > "$aggregates_optional_object"

cat > "$aggregates_optional_harness" <<'C'
extern int optional_payload(int tag, int payload);

int main(void) {
    if (optional_payload(0, 99) != -1) return 1;
    if (optional_payload(1, 99) != 99) return 2;
    if (optional_payload(-3, -11) != -11) return 3;
    return 0;
}
C

zig cc "$aggregates_optional_harness" "$aggregates_optional_object" -o "$aggregates_optional_exe"
"$aggregates_optional_exe"
printf 'ok distribution executable aggregates_optional_payload\n'

aggregates_slice_fixture="test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll"
aggregates_slice_object="$tmp_dir/aggregates_slice_sum.o"
aggregates_slice_harness="$tmp_dir/aggregates_slice_sum_harness.c"
aggregates_slice_exe="$tmp_dir/aggregates_slice_sum_harness"

zig build run -- --emit=obj --target="$target" "$aggregates_slice_fixture" > "$aggregates_slice_object"

cat > "$aggregates_slice_harness" <<'C'
#include <stddef.h>

extern int slice_sum(const int *values, long long len);

int main(void) {
    int values[] = { 4, -2, 9, 1 };
    if (slice_sum(values, 0) != 0) return 1;
    if (slice_sum(values, 1) != 4) return 2;
    if (slice_sum(values, 3) != 11) return 3;
    if (slice_sum(values, 4) != 12) return 4;
    return 0;
}
C

zig cc "$aggregates_slice_harness" "$aggregates_slice_object" -o "$aggregates_slice_exe"
"$aggregates_slice_exe"
printf 'ok distribution executable aggregates_slice_sum\n'

aggregates_struct_fixture="test/distribution/releasefast_x86_64/inputs/aggregates_struct_sum.ll"
aggregates_struct_object="$tmp_dir/aggregates_struct_sum.o"
aggregates_struct_harness="$tmp_dir/aggregates_struct_sum_harness.c"
aggregates_struct_exe="$tmp_dir/aggregates_struct_sum_harness"

zig build run -- --emit=obj --target="$target" "$aggregates_struct_fixture" > "$aggregates_struct_object"

cat > "$aggregates_struct_harness" <<'C'
struct Pair {
    int a;
    int b;
};

extern int struct_sum(const struct Pair *pair);

int main(void) {
    struct Pair first = { 7, 11 };
    struct Pair second = { -4, 9 };
    if (struct_sum(&first) != 18) return 1;
    if (struct_sum(&second) != 5) return 2;
    return 0;
}
C

zig cc "$aggregates_struct_harness" "$aggregates_struct_object" -o "$aggregates_struct_exe"
"$aggregates_struct_exe"
printf 'ok distribution executable aggregates_struct_sum\n'
