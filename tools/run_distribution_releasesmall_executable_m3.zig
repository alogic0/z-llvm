const std = @import("std");
const common = @import("tool_common.zig");

const ExecCase = struct {
    id: []const u8,
    fixture: []const u8,
    harness: []const u8,
};

const cases = [_]ExecCase{
    .{
        .id = "inherit_want_safety_i64_return",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll",
        .harness =
        \\#include <stdint.h>
        \\
        \\extern int64_t entry(void);
        \\
        \\int main(void) {
        \\    return entry() == 4 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "no_compile_panic_for_unchecked_arith_umul_fix_sat_i64",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll",
        .harness =
        \\#include <stdint.h>
        \\
        \\extern int64_t entry(void);
        \\
        \\int main(void) {
        \\    return entry() == 0 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "standalone_extern_exports_hidden_access",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll",
        .harness =
        \\#include <stdint.h>
        \\
        \\extern int32_t getHidden(void);
        \\extern void updateHidden(int32_t value);
        \\
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
        .id = "standalone_mix_c_files_add_zig",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll",
        .harness =
        \\#include <stdint.h>
        \\
        \\extern int32_t add_zig(int32_t value);
        \\__thread int32_t C_k = 7;
        \\
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
        .id = "standalone_mix_c_files_add_may_panic",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll",
        .harness =
        \\#include <stdint.h>
        \\
        \\extern int32_t add_may_panic(int32_t value);
        \\
        \\void panic_stub(const char *message, int64_t len) __asm__("debug.defaultPanic");
        \\void panic_stub(const char *message, int64_t len) {
        \\    (void)message;
        \\    (void)len;
        \\    __builtin_trap();
        \\}
        \\
        \\int main(void) {
        \\    if (add_may_panic(0) != 1) return 1;
        \\    if (add_may_panic(41) != 42) return 2;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "standalone_libfuzzer_runner_futex_wait",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_futex_wait.ll",
        .harness =
        \\#include <stdbool.h>
        \\#include <stdint.h>
        \\
        \\extern bool runner_futex_wait(const int32_t *address, int32_t expected);
        \\
        \\int main(void) {
        \\    int32_t value = 7;
        \\    return runner_futex_wait(&value, 7) ? 1 : 0;
        \\}
        \\
        ,
    },
    .{
        .id = "standalone_libfuzzer_runner_test_name",
        .fixture = "test/distribution/releasesmall_x86_64/inputs/standalone_libfuzzer_runner_test_name.ll",
        .harness =
        \\#include <stdint.h>
        \\#include <string.h>
        \\
        \\struct Slice {
        \\    uintptr_t ptr;
        \\    uint64_t len;
        \\};
        \\
        \\extern struct Slice runner_test_name(int32_t index);
        \\
        \\int main(void) {
        \\    struct Slice name = runner_test_name(0);
        \\    if (name.len != 4) return 1;
        \\    if (memcmp((const void *)name.ptr, "test", 4) != 0) return 2;
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

    const temp = try common.TempDir.init(allocator, io, "releasesmall_executable_m3");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [512]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    for (cases) |case| {
        try runCase(allocator, io, temp, target, cc_target, case);
        try stdout_writer.interface.print("ok distribution releasesmall executable {s}\n", .{case.id});
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
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness, .data = case.harness });

    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, harness, object, "-o", exe };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc");
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
