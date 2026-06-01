const std = @import("std");
const common = @import("tool_common.zig");

const Case = struct {
    id: []const u8,
    fixture: []const u8,
    summary_patterns: []const []const u8,
    dump_patterns: []const []const u8,
    harness: []const u8,
};

const panic_overflow = "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOverflow - 4";

const cases = [_]Case{
    .{
        .id = "aggregates_checked_sums",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll",
        .summary_patterns = &.{ "[[:space:]]slice_sum$", "[[:space:]]struct_sum$", "[[:space:]]array_sum$", panic_overflow },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
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
        .id = "atomics_debug_location_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll",
        .summary_patterns = &.{ "[[:space:]]debug_location$", panic_overflow },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
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
        .id = "control_flow_calls_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll",
        .summary_patterns = &.{ "[[:space:]]loop_sum$", "[[:space:]]call_chain$", panic_overflow, "R_X86_64_PLT32.*debug.FullPanic\\(\\(function 'defaultPanic'\\)\\)\\.integerOutOfBounds - 4" },
        .dump_patterns = &.{ "[[:space:]]jo[[:space:]]", "[[:space:]]js[[:space:]]" },
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
        .id = "error_switch_select",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/error_switch_select.ll",
        .summary_patterns = &.{"[[:space:]]error_switch$"},
        .dump_patterns = &.{ "cmp[[:space:]].*0x0", "cmp[[:space:]].*0x1" },
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
        .id = "globals_comptime_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll",
        .summary_patterns = &.{ "[[:space:]]comptime_const$", "[[:space:]]update_global$", "[[:space:]]read_global$", "[[:space:]]globals_comptime\\.global_counter$", panic_overflow, "R_X86_64_PC32.*globals_comptime\\.global_counter - 4" },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
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
        .id = "pointers_memory_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll",
        .summary_patterns = &.{ "[[:space:]]load_store$", panic_overflow },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
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
        .id = "switch_control_branch_mix_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll",
        .summary_patterns = &.{ "[[:space:]]branch_mix$", panic_overflow },
        .dump_patterns = &.{ "[[:space:]]jo[[:space:]]", "[[:space:]]je[[:space:]]" },
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
        .id = "tiny_scalar_checked_add",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll",
        .summary_patterns = &.{ "[[:space:]]sideEffectFree$", "[[:space:]]add$", panic_overflow },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
        .harness =
        \\#include <stdint.h>
        \\extern void sideEffectFree(void);
        \\extern int32_t add(int32_t lhs, int32_t rhs);
        \\void panic_overflow_stub(void) __asm__("debug.FullPanic((function 'defaultPanic')).integerOverflow");
        \\void panic_overflow_stub(void) { __builtin_trap(); }
        \\int main(void) {
        \\    sideEffectFree();
        \\    if (add(1, 2) != 3) return 1;
        \\    if (add(-7, 2) != -5) return 2;
        \\    if (add(1000, -250) != 750) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "tls_concurrency_checked",
        .fixture = "test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll",
        .summary_patterns = &.{ "[[:space:]]bump_tls$", "[[:space:]]read_tls$", "\\.tdata", "TLS[[:space:]]+GLOBAL.*tls_concurrency\\.tls_counter", "R_X86_64_TPOFF32.*tls_concurrency\\.tls_counter", panic_overflow },
        .dump_patterns = &.{"[[:space:]]jo[[:space:]]"},
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

    const temp = try common.TempDir.init(allocator, io, "releasesafe_object_m2");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, cc_target, case);
        try stdout_writer.interface.print("ok distribution releasesafe object {s}\n", .{case.id});
        try stdout_writer.interface.flush();
    }
}

fn runCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    cc_target: []const u8,
    case: Case,
) !void {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const summary = try common.allocTempFile(allocator, temp, case.id, ".readelf.txt");
    defer allocator.free(summary);
    const dump = try common.allocTempFile(allocator, temp, case.id, ".objdump.txt");
    defer allocator.free(dump);
    const harness = try common.allocTempFile(allocator, temp, case.id, "_harness.c");
    defer allocator.free(harness);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_harness");
    defer allocator.free(exe);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", summary);
    const objdump_argv = [_][]const u8{ "objdump", "-dr", object };
    try common.runToFile(allocator, io, &objdump_argv, "objdump", dump);

    try expectRegex(allocator, io, summary, "Type:[[:space:]]+REL");
    try expectRegex(allocator, io, summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    for (case.summary_patterns) |pattern| try expectRegex(allocator, io, summary, pattern);
    for (case.dump_patterns) |pattern| try expectRegex(allocator, io, dump, pattern);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness, .data = case.harness });
    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, harness, object, "-o", exe };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc");
    common.freeRunResult(allocator, cc_result);
    const run_argv = [_][]const u8{exe};
    const run_result = try common.runCapture(allocator, io, &run_argv, exe);
    common.freeRunResult(allocator, run_result);
}

fn expectRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    try common.expectRegex(allocator, io, path, pattern);
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
