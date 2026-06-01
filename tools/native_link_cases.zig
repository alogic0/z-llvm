pub const Stub = struct {
    symbol: []const u8,
};

pub const Case = struct {
    id: []const u8,
    mode: []const u8,
    fixture: []const u8,
    harness: []const u8,
    link_math: bool = false,
    stubs: []const Stub = &.{},
};

pub const integer_overflow_stub: Stub = .{
    .symbol = "debug.FullPanic((function 'defaultPanic')).integerOverflow",
};

const releasefast_root = "test/distribution/releasefast_x86_64/inputs/";

pub const cases = [_]Case{
    .{
        .id = "releasefast_tiny_scalar",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "tiny_scalar.ll",
        .harness =
        \\extern void sideEffectFree(void);
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    sideEffectFree();
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_add_wrap",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "integers_add_wrap.ll",
        .harness =
        \\extern int add_wrap(int a, int b);
        \\int main(void) {
        \\    if (add_wrap(2147483647, 1) != -2147483648) return 1;
        \\    if (add_wrap(-5, 12) != 7) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_cmp_shift",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "integers_cmp_shift.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int cmp_select(int a, int b);
        \\extern int shift_mix(int value, int amount);
        \\static int expected_shift_mix(int value, int amount) {
        \\    uint32_t bits = (uint32_t)value;
        \\    uint32_t shift = (uint32_t)amount & 31u;
        \\    return (int)((bits << shift) ^ (bits >> shift));
        \\}
        \\int main(void) {
        \\    if (cmp_select(7, 3) != 3) return 1;
        \\    if (cmp_select(-4, 2) != -4) return 2;
        \\    if (shift_mix(0x12345678, 4) != expected_shift_mix(0x12345678, 4)) return 3;
        \\    if (shift_mix(-7, 35) != expected_shift_mix(-7, 35)) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_branch_mix",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "switch_control_branch_mix.ll",
        .harness =
        \\#include <stdbool.h>
        \\extern int branch_mix(int a, int b, bool flag);
        \\int main(void) {
        \\    if (branch_mix(10, 3, true) != 13) return 1;
        \\    if (branch_mix(10, 3, false) != 7) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_loop_sum",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "control_flow_calls_loop_sum.ll",
        .harness =
        \\extern int loop_sum(int count);
        \\int main(void) {
        \\    if (loop_sum(0) != 0) return 1;
        \\    if (loop_sum(5) != 10) return 2;
        \\    if (loop_sum(13) != 78) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_call_chain",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "control_flow_calls_call_chain.ll",
        .harness =
        \\extern int call_chain(int value);
        \\int main(void) {
        \\    if (call_chain(0) != 1) return 1;
        \\    if (call_chain(5) != 11) return 2;
        \\    if (call_chain(17) != 35) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_error_switch",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "error_switch_error_switch.ll",
        .harness =
        \\extern int error_switch(unsigned char tag);
        \\int main(void) {
        \\    if (error_switch(0) != 0) return 1;
        \\    if (error_switch(1) != -1) return 2;
        \\    if (error_switch(2) != -2) return 3;
        \\    if (error_switch(255) != -2) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_float_compare",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "float_compare_basic.ll",
        .harness =
        \\#include <stdbool.h>
        \\#include <math.h>
        \\extern double float_mul(double a, double b);
        \\extern bool float_less(float a, float b);
        \\static int close_to(double actual, double expected) {
        \\    double delta = actual - expected;
        \\    if (delta < 0.0) delta = -delta;
        \\    return delta < 0.000001;
        \\}
        \\int main(void) {
        \\    if (!close_to(float_mul(3.0, 2.5), 7.5)) return 1;
        \\    if (!close_to(float_mul(-4.0, 0.5), -2.0)) return 2;
        \\    if (!float_less(1.0f, 2.0f)) return 3;
        \\    if (float_less(2.0f, 1.0f)) return 4;
        \\    if (float_less(2.0f, 2.0f)) return 5;
        \\    if (float_less(NAN, 1.0f)) return 6;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_floats_math",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "floats_math_basic.ll",
        .harness =
        \\#include <stdbool.h>
        \\extern double float_select(double a, double b, bool pick_a);
        \\extern float float_add(float a, float b);
        \\static int close_to_double(double actual, double expected) {
        \\    double delta = actual - expected;
        \\    if (delta < 0.0) delta = -delta;
        \\    return delta < 0.000001;
        \\}
        \\static int close_to_float(float actual, float expected) {
        \\    float delta = actual - expected;
        \\    if (delta < 0.0f) delta = -delta;
        \\    return delta < 0.0001f;
        \\}
        \\int main(void) {
        \\    if (!close_to_double(float_select(1.25, 9.5, true), 1.25)) return 1;
        \\    if (!close_to_double(float_select(1.25, 9.5, false), 9.5)) return 2;
        \\    if (!close_to_float(float_add(1.5f, 2.25f), 3.75f)) return 3;
        \\    if (!close_to_float(float_add(-4.0f, 1.5f), -2.5f)) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_fp_constants",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "fp_constants_literals.ll",
        .harness =
        \\extern double double_literal(void);
        \\extern float float_literal(void);
        \\int main(void) {
        \\    if (double_literal() != 2.25) return 1;
        \\    if (float_literal() != 1.5f) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_fp_extended_ops",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "fp_extended_ops_basic.ll",
        .link_math = true,
        .harness =
        \\extern float float_rem(float a, float b);
        \\extern double double_div(double a, double b);
        \\extern float float_sub(float a, float b);
        \\static int close_to_double(double actual, double expected) {
        \\    double delta = actual - expected;
        \\    if (delta < 0.0) delta = -delta;
        \\    return delta < 0.000001;
        \\}
        \\static int close_to_float(float actual, float expected) {
        \\    float delta = actual - expected;
        \\    if (delta < 0.0f) delta = -delta;
        \\    return delta < 0.0001f;
        \\}
        \\int main(void) {
        \\    if (!close_to_float(float_rem(7.5f, 2.0f), 1.5f)) return 1;
        \\    if (!close_to_double(double_div(9.0, 4.0), 2.25)) return 2;
        \\    if (!close_to_float(float_sub(7.0f, 2.5f), 4.5f)) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_comptime_const",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "globals_comptime_const.ll",
        .harness =
        \\extern int comptime_const(int value);
        \\int main(void) {
        \\    if (comptime_const(7) != 35) return 1;
        \\    if (comptime_const(-3) != -15) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_globals_counter",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "globals_comptime_global_counter.ll",
        .harness =
        \\extern int update_global(int delta);
        \\extern int read_global(void);
        \\int main(void) {
        \\    if (read_global() != 3) return 1;
        \\    if (update_global(4) != 7) return 2;
        \\    if (read_global() != 7) return 3;
        \\    if (update_global(-2) != 5) return 4;
        \\    if (read_global() != 5) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_optional_ptr_value",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "optional_pointer_value.ll",
        .harness =
        \\#include <stddef.h>
        \\extern int optional_ptr_value(const int *value);
        \\int main(void) {
        \\    int positive = 42;
        \\    int negative = -9;
        \\    if (optional_ptr_value(&positive) != 42) return 1;
        \\    if (optional_ptr_value(&negative) != -9) return 2;
        \\    if (optional_ptr_value(NULL) != -1) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_packed_bits",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "packed_bits_basic.ll",
        .harness =
        \\#include <stdbool.h>
        \\extern unsigned char replace_low(unsigned char high, unsigned char low);
        \\extern bool read_flag(unsigned char value);
        \\int main(void) {
        \\    if (replace_low(0xf8, 0x05) != 0xfd) return 1;
        \\    if (replace_low(0xab, 0x02) != 0xaa) return 2;
        \\    if (read_flag(0x80) != true) return 3;
        \\    if (read_flag(0x7f) != false) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_pointers_memory",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "pointers_memory_basic.ll",
        .harness =
        \\extern int volatile_roundtrip(int *slot, int value);
        \\extern int load_store(const int *src, int *dst);
        \\int main(void) {
        \\    int slot = 0;
        \\    int src = 41;
        \\    int dst = 0;
        \\    if (volatile_roundtrip(&slot, 17) != 17) return 1;
        \\    if (slot != 17) return 2;
        \\    if (load_store(&src, &dst) != 42) return 3;
        \\    if (dst != 42) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_tls_concurrency",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "tls_concurrency_counter.ll",
        .harness =
        \\extern int bump_tls(int delta);
        \\extern int read_tls(void);
        \\int main(void) {
        \\    if (read_tls() != 1) return 1;
        \\    if (bump_tls(4) != 5) return 2;
        \\    if (read_tls() != 5) return 3;
        \\    if (bump_tls(-2) != 3) return 4;
        \\    if (read_tls() != 3) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_dense_switch",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "switch_control_dense_switch.ll",
        .harness =
        \\extern int dense_switch(unsigned char value);
        \\int main(void) {
        \\    if (dense_switch(0) != 11) return 1;
        \\    if (dense_switch(1) != 13) return 2;
        \\    if (dense_switch(2) != 17) return 3;
        \\    if (dense_switch(3) != 19) return 4;
        \\    if (dense_switch(5) != 19) return 5;
        \\    if (dense_switch(6) != 23) return 6;
        \\    if (dense_switch(255) != 23) return 7;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregate_abi_pair",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregate_abi_pair.ll",
        .harness =
        \\extern int pair_first(long long pair);
        \\extern long long make_pair(int first, int second);
        \\int main(void) {
        \\    if (pair_first(0x000000020000002aLL) != 42) return 1;
        \\    if (pair_first(-1LL) != -1) return 2;
        \\    if (make_pair(0x11223344, 0x55667788) != ((0x55667788LL << 32) | 0x11223344LL)) return 3;
        \\    if (make_pair(-1, 0) != 0x00000000ffffffffLL) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregates_error_union_payload",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregates_error_union_payload.ll",
        .harness =
        \\extern int error_union_payload(int tag);
        \\int main(void) {
        \\    if (error_union_payload(0) != 7) return 1;
        \\    if (error_union_payload(1) != -1) return 2;
        \\    if (error_union_payload(-3) != -1) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregates_optional_payload",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregates_optional_payload.ll",
        .harness =
        \\extern int optional_payload(int tag, int payload);
        \\int main(void) {
        \\    if (optional_payload(0, 99) != -1) return 1;
        \\    if (optional_payload(1, 99) != 99) return 2;
        \\    if (optional_payload(-3, -11) != -11) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregates_slice_sum",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregates_slice_sum.ll",
        .harness =
        \\extern int slice_sum(const int *values, long long len);
        \\int main(void) {
        \\    int values[] = { 4, -2, 9, 1 };
        \\    if (slice_sum(values, 0) != 0) return 1;
        \\    if (slice_sum(values, 1) != 4) return 2;
        \\    if (slice_sum(values, 3) != 11) return 3;
        \\    if (slice_sum(values, 4) != 12) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregates_struct_sum",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregates_struct_sum.ll",
        .harness =
        \\struct Pair {
        \\    int a;
        \\    int b;
        \\};
        \\extern int struct_sum(const struct Pair *pair);
        \\int main(void) {
        \\    struct Pair first = { 7, 11 };
        \\    struct Pair second = { -4, 9 };
        \\    if (struct_sum(&first) != 18) return 1;
        \\    if (struct_sum(&second) != 5) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_aggregates_array_sum",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "aggregates_array_sum.ll",
        .harness =
        \\extern int array_sum(int a, int b, int c);
        \\int main(void) {
        \\    if (array_sum(1, 2, 3) != 6) return 1;
        \\    if (array_sum(-4, 9, 5) != 10) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_atomics_debug_location",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "atomics_debug_location.ll",
        .harness =
        \\extern int debug_location(int value);
        \\int main(void) {
        \\    if (debug_location(0) != 1) return 1;
        \\    if (debug_location(41) != 42) return 2;
        \\    if (debug_location(-2) != -1) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_atomics_inline_asm_barrier",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "atomics_inline_asm_barrier.ll",
        .harness =
        \\extern int inline_asm_barrier(int value);
        \\int main(void) {
        \\    if (inline_asm_barrier(0) != 0) return 1;
        \\    if (inline_asm_barrier(42) != 42) return 2;
        \\    if (inline_asm_barrier(-7) != -7) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_atomics_atomic_add",
        .mode = "ReleaseFast",
        .fixture = releasefast_root ++ "atomics_atomic_add.ll",
        .harness =
        \\extern int atomic_add(int value);
        \\int main(void) {
        \\    if (atomic_add(5) != 0) return 1;
        \\    if (atomic_add(7) != 5) return 2;
        \\    if (atomic_add(-3) != 12) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_checked_add",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll",
        .stubs = &.{integer_overflow_stub},
        .harness =
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_aggregates_checked_sums",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll",
        .harness =
        \\#include <stdint.h>
        \\struct Pair { int32_t a; int32_t b; };
        \\extern int32_t slice_sum(const int32_t *values, int64_t len);
        \\extern int32_t struct_sum(const struct Pair *pair);
        \\extern int32_t array_sum(int32_t a, int32_t b, int32_t c);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    int32_t values[] = { 4, -2, 9, 1 };
        \\    struct Pair pair = { 7, 11 };
        \\    if (slice_sum(values, 0) != 0) return 1;
        \\    if (slice_sum(values, 4) != 12) return 2;
        \\    if (struct_sum(&pair) != 18) return 3;
        \\    if (array_sum(1, 2, 3) != 6) return 4;
        \\    if (array_sum(-4, 9, 5) != 10) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_atomics_debug_location_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t debug_location(int32_t value);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    if (debug_location(0) != 1) return 1;
        \\    if (debug_location(41) != 42) return 2;
        \\    if (debug_location(-2) != -1) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_control_flow_calls_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t loop_sum(uint32_t limit);
        \\extern int32_t call_chain(int32_t value);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\void panic_out_of_bounds_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOutOfBounds");
        \\void panic_out_of_bounds_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    if (loop_sum(0) != 0) return 1;
        \\    if (loop_sum(1) != 0) return 2;
        \\    if (loop_sum(5) != 10) return 3;
        \\    if (loop_sum(13) != 78) return 4;
        \\    if (call_chain(0) != 1) return 5;
        \\    if (call_chain(5) != 11) return 6;
        \\    if (call_chain(17) != 35) return 7;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_error_switch",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t error_switch(uint8_t tag);
        \\int main(void) {
        \\    if (error_switch(0) != 0) return 1;
        \\    if (error_switch(1) != -1) return 2;
        \\    if (error_switch(2) != -2) return 3;
        \\    if (error_switch(255) != -2) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_globals_comptime_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t comptime_const(int32_t value);
        \\extern int32_t update_global(int32_t value);
        \\extern int32_t read_global(void);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    if (comptime_const(0) != 0) return 1;
        \\    if (comptime_const(7) != 35) return 2;
        \\    if (comptime_const(-3) != -15) return 3;
        \\    if (read_global() != 3) return 4;
        \\    if (update_global(4) != 7) return 5;
        \\    if (read_global() != 7) return 6;
        \\    if (update_global(-2) != 5) return 7;
        \\    if (read_global() != 5) return 8;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_pointers_memory_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t load_store(const int32_t *input, int32_t *output);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    int32_t input = 41;
        \\    int32_t output = 0;
        \\    if (load_store(&input, &output) != 42) return 1;
        \\    if (output != 42) return 2;
        \\    input = -3;
        \\    if (load_store(&input, &output) != -2) return 3;
        \\    if (output != -2) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_branch_mix_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll",
        .harness =
        \\#include <stdbool.h>
        \\#include <stdint.h>
        \\extern int32_t branch_mix(int32_t base, int32_t delta, bool add);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    if (branch_mix(10, 4, true) != 14) return 1;
        \\    if (branch_mix(10, 4, false) != 6) return 2;
        \\    if (branch_mix(-7, 3, true) != -4) return 3;
        \\    if (branch_mix(-7, 3, false) != -10) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesafe_tls_concurrency_checked",
        .mode = "ReleaseSafe",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t bump_tls(int32_t delta);
        \\extern int32_t read_tls(void);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    if (read_tls() != 1) return 1;
        \\    if (bump_tls(4) != 5) return 2;
        \\    if (read_tls() != 5) return 3;
        \\    if (bump_tls(-2) != 3) return 4;
        \\    if (read_tls() != 3) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_i64_return",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int64_t entry(void);
        \\int main(void) {
        \\    return entry() == 4 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_unchecked_arith_i64",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int64_t entry(void);
        \\int main(void) {
        \\    return entry() == 0 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_hidden_access",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t getHidden(void);
        \\extern void updateHidden(int32_t value);
        \\int main(void) {
        \\    if (getHidden() != 0) return 1;
        \\    updateHidden(42);
        \\    if (getHidden() != 42) return 2;
        \\    updateHidden(-7);
        \\    if (getHidden() != -7) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_mix_c_files_add_zig",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t add_zig(int32_t value);
        \\__thread int32_t C_k = 7;
        \\int main(void) {
        \\    if (add_zig(10) != 18) return 1;
        \\    C_k = -3;
        \\    if (add_zig(10) != 8) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_mix_c_files_add_may_panic",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t add_may_panic(int32_t value);
        \\void panic_stub(const char *message, int64_t len) __asm__("debug.defaultPanic");
        \\void panic_stub(const char *message, int64_t len) {
        \\    (void)message;
        \\    (void)len;
        \\    __builtin_trap();
        \\}
        \\int main(void) {
        \\    if (add_may_panic(0) != 1) return 1;
        \\    if (add_may_panic(41) != 42) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_libfuzzer_runner_futex_wait",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll",
        .harness =
        \\#include <stdbool.h>
        \\#include <stdint.h>
        \\extern bool runner_futex_wait(const int32_t *address, int32_t expected);
        \\int main(void) {
        \\    int32_t value = 7;
        \\    return runner_futex_wait(&value, 7) ? 1 : 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_libfuzzer_runner_test_name",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll",
        .harness =
        \\#include <stdint.h>
        \\#include <string.h>
        \\struct Slice {
        \\    uintptr_t ptr;
        \\    uint64_t len;
        \\};
        \\extern struct Slice runner_test_name(int32_t index);
        \\int main(void) {
        \\    struct Slice name = runner_test_name(0);
        \\    if (name.len != 4) return 1;
        \\    if (memcmp((const void *)name.ptr, "test", 4) != 0) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_base64_table_lookup",
        .mode = "ReleaseSmall",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll",
        .harness =
        \\#include <stdint.h>
        \\extern int32_t base64_table_lookup(uint8_t index);
        \\int main(void) {
        \\    if (base64_table_lookup(0) != 0) return 1;
        \\    if (base64_table_lookup(1) != 4) return 2;
        \\    if (base64_table_lookup(3) != 12) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "debug_shared_library_mathtest_add_o0",
        .mode = "Debug",
        .fixture = "test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll",
        .stubs = &.{integer_overflow_stub},
        .harness =
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-7, 9) != 2) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
};
