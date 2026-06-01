pub const Stub = struct {
    symbol: []const u8,
};

pub const Case = struct {
    id: []const u8,
    mode: []const u8,
    fixture: []const u8,
    harness: []const u8,
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
