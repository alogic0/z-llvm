const std = @import("std");
const common = @import("tool_common.zig");

const ExecCase = struct {
    id: []const u8,
    fixture: []const u8,
    harness: []const u8,
    link_math: bool = false,
};

const root = "test/distribution/releasefast_x86_64/inputs/";

const cases = [_]ExecCase{
    .{
        .id = "tiny_scalar",
        .fixture = root ++ "tiny_scalar.ll",
        .harness =
        \\extern void sideEffectFree(void);
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    sideEffectFree();
        \\    if (add(40, 2) != 42) return 1;
        \\    if (add(-5, 8) != 3) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "add_wrap",
        .fixture = root ++ "integers_add_wrap.ll",
        .harness =
        \\extern int add_wrap(int a, int b);
        \\int main(void) {
        \\    if (add_wrap(40, 2) != 42) return 1;
        \\    if (add_wrap(-1, 1) != 0) return 2;
        \\    if (add_wrap(2147483647, 1) != -2147483648) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "integers_cmp_shift",
        .fixture = root ++ "integers_cmp_shift.ll",
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
        \\    if (cmp_select(-1, -9) != -9) return 3;
        \\    if (shift_mix(0x12345678, 4) != expected_shift_mix(0x12345678, 4)) return 4;
        \\    if (shift_mix(-7, 35) != expected_shift_mix(-7, 35)) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "branch_mix",
        .fixture = root ++ "switch_control_branch_mix.ll",
        .harness =
        \\#include <stdbool.h>
        \\extern int branch_mix(int a, int b, bool flag);
        \\int main(void) {
        \\    if (branch_mix(10, 3, true) != 13) return 1;
        \\    if (branch_mix(10, 3, false) != 7) return 2;
        \\    if (branch_mix(-2, 5, true) != 3) return 3;
        \\    if (branch_mix(-2, 5, false) != -7) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "call_chain",
        .fixture = root ++ "control_flow_calls_call_chain.ll",
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
        .id = "loop_sum",
        .fixture = root ++ "control_flow_calls_loop_sum.ll",
        .harness =
        \\extern int loop_sum(int count);
        \\int main(void) {
        \\    if (loop_sum(0) != 0) return 1;
        \\    if (loop_sum(1) != 0) return 2;
        \\    if (loop_sum(5) != 10) return 3;
        \\    if (loop_sum(8) != 28) return 4;
        \\    if (loop_sum(13) != 78) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "error_switch",
        .fixture = root ++ "error_switch_error_switch.ll",
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
        .id = "float_compare",
        .fixture = root ++ "float_compare_basic.ll",
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
        .id = "floats_math",
        .fixture = root ++ "floats_math_basic.ll",
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
        .id = "fp_constants",
        .fixture = root ++ "fp_constants_literals.ll",
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
        .id = "fp_extended_ops",
        .fixture = root ++ "fp_extended_ops_basic.ll",
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
        .id = "comptime_const",
        .fixture = root ++ "globals_comptime_const.ll",
        .harness =
        \\extern int comptime_const(int value);
        \\int main(void) {
        \\    if (comptime_const(0) != 0) return 1;
        \\    if (comptime_const(7) != 35) return 2;
        \\    if (comptime_const(-3) != -15) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "globals_comptime_counter",
        .fixture = root ++ "globals_comptime_global_counter.ll",
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
        .id = "optional_ptr_value",
        .fixture = root ++ "optional_pointer_value.ll",
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
        .id = "packed_bits",
        .fixture = root ++ "packed_bits_basic.ll",
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
        .id = "pointers_memory",
        .fixture = root ++ "pointers_memory_basic.ll",
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
        .id = "tls_concurrency",
        .fixture = root ++ "tls_concurrency_counter.ll",
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
        .id = "dense_switch",
        .fixture = root ++ "switch_control_dense_switch.ll",
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
        .id = "aggregate_abi_pair",
        .fixture = root ++ "aggregate_abi_pair.ll",
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
        .id = "aggregates_error_union_payload",
        .fixture = root ++ "aggregates_error_union_payload.ll",
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
        .id = "aggregates_optional_payload",
        .fixture = root ++ "aggregates_optional_payload.ll",
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
        .id = "aggregates_slice_sum",
        .fixture = root ++ "aggregates_slice_sum.ll",
        .harness =
        \\#include <stddef.h>
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
        .id = "aggregates_struct_sum",
        .fixture = root ++ "aggregates_struct_sum.ll",
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
        .id = "aggregates_array_sum",
        .fixture = root ++ "aggregates_array_sum.ll",
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
        .id = "atomics_debug_location",
        .fixture = root ++ "atomics_debug_location.ll",
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
        .id = "atomics_inline_asm_barrier",
        .fixture = root ++ "atomics_inline_asm_barrier.ll",
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
        .id = "atomics_atomic_add",
        .fixture = root ++ "atomics_atomic_add.ll",
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
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);

    const temp = try common.TempDir.init(allocator, io, "distribution_executable_m1");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, cc_target, case);
        try stdout_writer.interface.print("ok distribution executable {s}\n", .{case.id});
        try stdout_writer.interface.flush();
    }
}

fn runCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    cc_target: []const u8,
    case: ExecCase,
) !void {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const harness = try common.allocTempFile(allocator, temp, case.id, "_harness.c");
    defer allocator.free(harness);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_harness");
    defer allocator.free(exe);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness, .data = case.harness });

    var cc_args: std.ArrayList([]const u8) = .empty;
    defer cc_args.deinit(allocator);
    try cc_args.appendSlice(allocator, &.{ "zig", "cc", "-target", cc_target, harness, object });
    if (case.link_math) try cc_args.append(allocator, "-lm");
    try cc_args.appendSlice(allocator, &.{ "-o", exe });

    const cc_result = try common.runCapture(allocator, io, cc_args.items, "zig cc");
    common.freeRunResult(allocator, cc_result);

    const run_argv = [_][]const u8{exe};
    const run_result = try common.runCapture(allocator, io, &run_argv, exe);
    common.freeRunResult(allocator, run_result);
}

fn defaultCcTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}
