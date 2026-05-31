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

integers_cmp_shift_fixture="test/distribution/releasefast_x86_64/inputs/integers_cmp_shift.ll"
integers_cmp_shift_object="$tmp_dir/integers_cmp_shift.o"
integers_cmp_shift_harness="$tmp_dir/integers_cmp_shift_harness.c"
integers_cmp_shift_exe="$tmp_dir/integers_cmp_shift_harness"

zig build run -- --emit=obj --target="$target" "$integers_cmp_shift_fixture" > "$integers_cmp_shift_object"

cat > "$integers_cmp_shift_harness" <<'C'
#include <stdint.h>

extern int cmp_select(int a, int b);
extern int shift_mix(int value, int amount);

static int expected_shift_mix(int value, int amount) {
    uint32_t bits = (uint32_t)value;
    uint32_t shift = (uint32_t)amount & 31u;
    return (int)((bits << shift) ^ (bits >> shift));
}

int main(void) {
    if (cmp_select(7, 3) != 3) return 1;
    if (cmp_select(-4, 2) != -4) return 2;
    if (cmp_select(-1, -9) != -9) return 3;
    if (shift_mix(0x12345678, 4) != expected_shift_mix(0x12345678, 4)) return 4;
    if (shift_mix(-7, 35) != expected_shift_mix(-7, 35)) return 5;
    return 0;
}
C

zig cc "$integers_cmp_shift_harness" "$integers_cmp_shift_object" -o "$integers_cmp_shift_exe"
"$integers_cmp_shift_exe"
printf 'ok distribution executable integers_cmp_shift\n'

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

loop_sum_fixture="test/distribution/releasefast_x86_64/inputs/control_flow_calls_loop_sum.ll"
loop_sum_object="$tmp_dir/control_flow_calls_loop_sum.o"
loop_sum_harness="$tmp_dir/loop_sum_harness.c"
loop_sum_exe="$tmp_dir/loop_sum_harness"

zig build run -- --emit=obj --target="$target" "$loop_sum_fixture" > "$loop_sum_object"

cat > "$loop_sum_harness" <<'C'
extern int loop_sum(int count);

int main(void) {
    if (loop_sum(0) != 0) return 1;
    if (loop_sum(1) != 0) return 2;
    if (loop_sum(5) != 10) return 3;
    if (loop_sum(8) != 28) return 4;
    if (loop_sum(13) != 78) return 5;
    return 0;
}
C

zig cc "$loop_sum_harness" "$loop_sum_object" -o "$loop_sum_exe"
"$loop_sum_exe"
printf 'ok distribution executable loop_sum\n'

error_switch_fixture="test/distribution/releasefast_x86_64/inputs/error_switch_error_switch.ll"
error_switch_object="$tmp_dir/error_switch_error_switch.o"
error_switch_harness="$tmp_dir/error_switch_harness.c"
error_switch_exe="$tmp_dir/error_switch_harness"

zig build run -- --emit=obj --target="$target" "$error_switch_fixture" > "$error_switch_object"

cat > "$error_switch_harness" <<'C'
extern int error_switch(unsigned char tag);

int main(void) {
    if (error_switch(0) != 0) return 1;
    if (error_switch(1) != -1) return 2;
    if (error_switch(2) != -2) return 3;
    if (error_switch(255) != -2) return 4;
    return 0;
}
C

zig cc "$error_switch_harness" "$error_switch_object" -o "$error_switch_exe"
"$error_switch_exe"
printf 'ok distribution executable error_switch\n'

float_compare_fixture="test/distribution/releasefast_x86_64/inputs/float_compare_basic.ll"
float_compare_object="$tmp_dir/float_compare_basic.o"
float_compare_harness="$tmp_dir/float_compare_harness.c"
float_compare_exe="$tmp_dir/float_compare_harness"

zig build run -- --emit=obj --target="$target" "$float_compare_fixture" > "$float_compare_object"

cat > "$float_compare_harness" <<'C'
#include <stdbool.h>
#include <math.h>

extern double float_mul(double a, double b);
extern bool float_less(float a, float b);

static int close_to(double actual, double expected) {
    double delta = actual - expected;
    if (delta < 0.0) delta = -delta;
    return delta < 0.000001;
}

int main(void) {
    if (!close_to(float_mul(3.0, 2.5), 7.5)) return 1;
    if (!close_to(float_mul(-4.0, 0.5), -2.0)) return 2;
    if (!float_less(1.0f, 2.0f)) return 3;
    if (float_less(2.0f, 1.0f)) return 4;
    if (float_less(2.0f, 2.0f)) return 5;
    if (float_less(NAN, 1.0f)) return 6;
    return 0;
}
C

zig cc "$float_compare_harness" "$float_compare_object" -o "$float_compare_exe"
"$float_compare_exe"
printf 'ok distribution executable float_compare\n'

floats_math_fixture="test/distribution/releasefast_x86_64/inputs/floats_math_basic.ll"
floats_math_object="$tmp_dir/floats_math_basic.o"
floats_math_harness="$tmp_dir/floats_math_harness.c"
floats_math_exe="$tmp_dir/floats_math_harness"

zig build run -- --emit=obj --target="$target" "$floats_math_fixture" > "$floats_math_object"

cat > "$floats_math_harness" <<'C'
#include <stdbool.h>

extern double float_select(double a, double b, bool pick_a);
extern float float_add(float a, float b);

static int close_to_double(double actual, double expected) {
    double delta = actual - expected;
    if (delta < 0.0) delta = -delta;
    return delta < 0.000001;
}

static int close_to_float(float actual, float expected) {
    float delta = actual - expected;
    if (delta < 0.0f) delta = -delta;
    return delta < 0.0001f;
}

int main(void) {
    if (!close_to_double(float_select(1.25, 9.5, true), 1.25)) return 1;
    if (!close_to_double(float_select(1.25, 9.5, false), 9.5)) return 2;
    if (!close_to_float(float_add(1.5f, 2.25f), 3.75f)) return 3;
    if (!close_to_float(float_add(-4.0f, 1.5f), -2.5f)) return 4;
    return 0;
}
C

zig cc "$floats_math_harness" "$floats_math_object" -o "$floats_math_exe"
"$floats_math_exe"
printf 'ok distribution executable floats_math\n'

fp_constants_fixture="test/distribution/releasefast_x86_64/inputs/fp_constants_literals.ll"
fp_constants_object="$tmp_dir/fp_constants_literals.o"
fp_constants_harness="$tmp_dir/fp_constants_harness.c"
fp_constants_exe="$tmp_dir/fp_constants_harness"

zig build run -- --emit=obj --target="$target" "$fp_constants_fixture" > "$fp_constants_object"

cat > "$fp_constants_harness" <<'C'
extern double double_literal(void);
extern float float_literal(void);

int main(void) {
    if (double_literal() != 2.25) return 1;
    if (float_literal() != 1.5f) return 2;
    return 0;
}
C

zig cc "$fp_constants_harness" "$fp_constants_object" -o "$fp_constants_exe"
"$fp_constants_exe"
printf 'ok distribution executable fp_constants\n'

fp_extended_fixture="test/distribution/releasefast_x86_64/inputs/fp_extended_ops_basic.ll"
fp_extended_object="$tmp_dir/fp_extended_ops_basic.o"
fp_extended_harness="$tmp_dir/fp_extended_ops_harness.c"
fp_extended_exe="$tmp_dir/fp_extended_ops_harness"

zig build run -- --emit=obj --target="$target" "$fp_extended_fixture" > "$fp_extended_object"

cat > "$fp_extended_harness" <<'C'
extern float float_rem(float a, float b);
extern double double_div(double a, double b);
extern float float_sub(float a, float b);

static int close_to_double(double actual, double expected) {
    double delta = actual - expected;
    if (delta < 0.0) delta = -delta;
    return delta < 0.000001;
}

static int close_to_float(float actual, float expected) {
    float delta = actual - expected;
    if (delta < 0.0f) delta = -delta;
    return delta < 0.0001f;
}

int main(void) {
    if (!close_to_float(float_rem(7.5f, 2.0f), 1.5f)) return 1;
    if (!close_to_double(double_div(9.0, 4.0), 2.25)) return 2;
    if (!close_to_float(float_sub(7.0f, 2.5f), 4.5f)) return 3;
    return 0;
}
C

zig cc "$fp_extended_harness" "$fp_extended_object" -lm -o "$fp_extended_exe"
"$fp_extended_exe"
printf 'ok distribution executable fp_extended_ops\n'

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

globals_counter_fixture="test/distribution/releasefast_x86_64/inputs/globals_comptime_global_counter.ll"
globals_counter_object="$tmp_dir/globals_comptime_global_counter.o"
globals_counter_harness="$tmp_dir/globals_comptime_global_counter_harness.c"
globals_counter_exe="$tmp_dir/globals_comptime_global_counter_harness"

zig build run -- --emit=obj --target="$target" "$globals_counter_fixture" > "$globals_counter_object"

cat > "$globals_counter_harness" <<'C'
extern int update_global(int delta);
extern int read_global(void);

int main(void) {
    if (read_global() != 3) return 1;
    if (update_global(4) != 7) return 2;
    if (read_global() != 7) return 3;
    if (update_global(-2) != 5) return 4;
    if (read_global() != 5) return 5;
    return 0;
}
C

zig cc "$globals_counter_harness" "$globals_counter_object" -o "$globals_counter_exe"
"$globals_counter_exe"
printf 'ok distribution executable globals_comptime_counter\n'

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

packed_bits_fixture="test/distribution/releasefast_x86_64/inputs/packed_bits_basic.ll"
packed_bits_object="$tmp_dir/packed_bits_basic.o"
packed_bits_harness="$tmp_dir/packed_bits_harness.c"
packed_bits_exe="$tmp_dir/packed_bits_harness"

zig build run -- --emit=obj --target="$target" "$packed_bits_fixture" > "$packed_bits_object"

cat > "$packed_bits_harness" <<'C'
#include <stdbool.h>

extern unsigned char replace_low(unsigned char high, unsigned char low);
extern bool read_flag(unsigned char value);

int main(void) {
    if (replace_low(0xf8, 0x05) != 0xfd) return 1;
    if (replace_low(0xab, 0x02) != 0xaa) return 2;
    if (read_flag(0x80) != true) return 3;
    if (read_flag(0x7f) != false) return 4;
    return 0;
}
C

zig cc "$packed_bits_harness" "$packed_bits_object" -o "$packed_bits_exe"
"$packed_bits_exe"
printf 'ok distribution executable packed_bits\n'

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

aggregates_array_fixture="test/distribution/releasefast_x86_64/inputs/aggregates_array_sum.ll"
aggregates_array_object="$tmp_dir/aggregates_array_sum.o"
aggregates_array_harness="$tmp_dir/aggregates_array_sum_harness.c"
aggregates_array_exe="$tmp_dir/aggregates_array_sum_harness"

zig build run -- --emit=obj --target="$target" "$aggregates_array_fixture" > "$aggregates_array_object"

cat > "$aggregates_array_harness" <<'C'
extern int array_sum(int a, int b, int c);

int main(void) {
    if (array_sum(1, 2, 3) != 6) return 1;
    if (array_sum(-4, 9, 5) != 10) return 2;
    return 0;
}
C

zig cc "$aggregates_array_harness" "$aggregates_array_object" -o "$aggregates_array_exe"
"$aggregates_array_exe"
printf 'ok distribution executable aggregates_array_sum\n'

atomics_debug_fixture="test/distribution/releasefast_x86_64/inputs/atomics_debug_location.ll"
atomics_debug_object="$tmp_dir/atomics_debug_location.o"
atomics_debug_harness="$tmp_dir/atomics_debug_location_harness.c"
atomics_debug_exe="$tmp_dir/atomics_debug_location_harness"

zig build run -- --emit=obj --target="$target" "$atomics_debug_fixture" > "$atomics_debug_object"

cat > "$atomics_debug_harness" <<'C'
extern int debug_location(int value);

int main(void) {
    if (debug_location(0) != 1) return 1;
    if (debug_location(41) != 42) return 2;
    if (debug_location(-2) != -1) return 3;
    return 0;
}
C

zig cc "$atomics_debug_harness" "$atomics_debug_object" -o "$atomics_debug_exe"
"$atomics_debug_exe"
printf 'ok distribution executable atomics_debug_location\n'

atomics_barrier_fixture="test/distribution/releasefast_x86_64/inputs/atomics_inline_asm_barrier.ll"
atomics_barrier_object="$tmp_dir/atomics_inline_asm_barrier.o"
atomics_barrier_harness="$tmp_dir/atomics_inline_asm_barrier_harness.c"
atomics_barrier_exe="$tmp_dir/atomics_inline_asm_barrier_harness"

zig build run -- --emit=obj --target="$target" "$atomics_barrier_fixture" > "$atomics_barrier_object"

cat > "$atomics_barrier_harness" <<'C'
extern int inline_asm_barrier(int value);

int main(void) {
    if (inline_asm_barrier(0) != 0) return 1;
    if (inline_asm_barrier(42) != 42) return 2;
    if (inline_asm_barrier(-7) != -7) return 3;
    return 0;
}
C

zig cc "$atomics_barrier_harness" "$atomics_barrier_object" -o "$atomics_barrier_exe"
"$atomics_barrier_exe"
printf 'ok distribution executable atomics_inline_asm_barrier\n'

atomics_add_fixture="test/distribution/releasefast_x86_64/inputs/atomics_atomic_add.ll"
atomics_add_object="$tmp_dir/atomics_atomic_add.o"
atomics_add_harness="$tmp_dir/atomics_atomic_add_harness.c"
atomics_add_exe="$tmp_dir/atomics_atomic_add_harness"

zig build run -- --emit=obj --target="$target" "$atomics_add_fixture" > "$atomics_add_object"

cat > "$atomics_add_harness" <<'C'
extern int atomic_add(int value);

int main(void) {
    if (atomic_add(5) != 0) return 1;
    if (atomic_add(7) != 5) return 2;
    if (atomic_add(-3) != 12) return 3;
    return 0;
}
C

zig cc "$atomics_add_harness" "$atomics_add_object" -o "$atomics_add_exe"
"$atomics_add_exe"
printf 'ok distribution executable atomics_atomic_add\n'
