const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");

const Validation = enum {
    executable,
    link_only,
};

const Case = struct {
    id: []const u8,
    source: []const u8,
    mode: []const u8,
    validation: Validation,
    harness: []const u8,
    stubs: []const native_cases.Stub = &.{},
    link_math: bool = false,
    fallback: []const u8 = "ir-emission:stage4-llvm-ir",
};

const cases = [_]Case{
    .{
        .id = "releasefast_tiny_scalar",
        .source = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
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
        .id = "releasefast_integers",
        .source = "test/zig/inputs/integers.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .harness =
        \\#include <stdint.h>
        \\extern int add_wrap(int a, int b);
        \\extern int cmp_select(int a, int b);
        \\extern int shift_mix(int value, int amount);
        \\static int expected_shift_mix(int value, int amount) {
        \\    uint32_t bits = (uint32_t)value;
        \\    uint32_t shift = (uint32_t)amount & 31u;
        \\    return (int)((bits << shift) ^ (bits >> shift));
        \\}
        \\int main(void) {
        \\    if (add_wrap(2147483647, 1) != -2147483648) return 1;
        \\    if (cmp_select(7, 3) != 3) return 2;
        \\    if (cmp_select(-4, 2) != -4) return 3;
        \\    if (shift_mix(0x12345678, 4) != expected_shift_mix(0x12345678, 4)) return 4;
        \\    if (shift_mix(-7, 35) != expected_shift_mix(-7, 35)) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_control_flow_calls",
        .source = "test/zig/inputs/control_flow_calls.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .harness =
        \\extern int loop_sum(int count);
        \\extern int call_chain(int value);
        \\int main(void) {
        \\    if (loop_sum(0) != 0) return 1;
        \\    if (loop_sum(5) != 10) return 2;
        \\    if (loop_sum(13) != 78) return 3;
        \\    if (call_chain(0) != 1) return 4;
        \\    if (call_chain(17) != 35) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_globals_comptime",
        .source = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
        .harness =
        \\extern int comptime_const(int value);
        \\extern int update_global(int delta);
        \\extern int read_global(void);
        \\int main(void) {
        \\    if (comptime_const(7) != 35) return 1;
        \\    if (read_global() != 3) return 2;
        \\    if (update_global(4) != 7) return 3;
        \\    if (read_global() != 7) return 4;
        \\    if (update_global(-2) != 5) return 5;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasefast_error_switch",
        .source = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseFast",
        .validation = .executable,
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
        .id = "releasesafe_error_switch",
        .source = "test/zig/inputs/error_switch.zig",
        .mode = "ReleaseSafe",
        .validation = .executable,
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
        .id = "releasesafe_tiny_scalar_runtime_boundary",
        .source = "test/zig/inputs/tiny_scalar.zig",
        .mode = "ReleaseSafe",
        .validation = .link_only,
        .stubs = &.{native_cases.integer_overflow_stub},
        .fallback = "ir-emission:stage4-llvm-ir;boundary:zig-panic-runtime",
        .harness =
        \\extern void sideEffectFree(void);
        \\extern int add(int a, int b);
        \\int main(void) {
        \\    sideEffectFree();
        \\    return add(1, 2) == 3 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_globals_comptime",
        .source = "test/zig/inputs/globals_comptime.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .harness =
        \\extern int comptime_const(int value);
        \\extern int update_global(int delta);
        \\extern int read_global(void);
        \\int main(void) {
        \\    if (comptime_const(-3) != -15) return 1;
        \\    if (read_global() != 3) return 2;
        \\    if (update_global(4) != 7) return 3;
        \\    return 0;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_i64_arithmetic",
        .source = "test/zig/inputs/i64_arithmetic.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .harness =
        \\#include <stdint.h>
        \\extern int64_t i64_value(void);
        \\int main(void) {
        \\    return i64_value() == 4 ? 0 : 1;
        \\}
        \\
        ,
    },
    .{
        .id = "releasesmall_base64_table_lookup",
        .source = "test/zig/inputs/base64_table_lookup.zig",
        .mode = "ReleaseSmall",
        .validation = .executable,
        .harness =
        \\#include <stdint.h>
        \\extern int32_t base64_table_lookup(uint8_t index);
        \\int main(void) {
        \\    if (base64_table_lookup(0) != 0) return 1;
        \\    if (base64_table_lookup(1) != 4) return 2;
        \\    if (base64_table_lookup(3) != 12) return 3;
        \\    if (base64_table_lookup(7) != 12) return 4;
        \\    return 0;
        \\}
        \\
        ,
    },
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const zig_source_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_SOURCE_DIR");
    defer if (zig_source_env) |value| allocator.free(value);
    const zig_emitter_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "ZIG_EMITTER");
    defer if (zig_emitter_env) |value| allocator.free(value);

    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);
    const zig_source_dir = zig_source_env orelse "../ziglang";
    const default_zig_emitter = try std.fs.path.join(allocator, &.{ zig_source_dir, "build/stage4/bin/zig" });
    defer allocator.free(default_zig_emitter);
    const zig_emitter = zig_emitter_env orelse default_zig_emitter;

    const check_argv = [_][]const u8{ "zig", "run", "tools/check_zig_stage4_emitter.zig" };
    const check_result = try common.runCapture(allocator, io, &check_argv, "tools/check_zig_stage4_emitter.zig");
    common.freeRunResult(allocator, check_result);

    const build_argv = [_][]const u8{ "zig", "build" };
    const build_result = try common.runCapture(allocator, io, &build_argv, "zig build");
    common.freeRunResult(allocator, build_result);

    const temp = try common.TempDir.init(allocator, io, "zig_source_native_link");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("zig-source native-link target={s} cc_target={s} linker=zig build-exe -fno-lld\n", .{ target, cc_target });
    try stdout_writer.interface.flush();

    var executable_ok: usize = 0;
    var link_only_ok: usize = 0;
    for (cases) |case| {
        try runCase(allocator, io, temp, zig_emitter, target, cc_target, case);
        switch (case.validation) {
            .executable => executable_ok += 1,
            .link_only => link_only_ok += 1,
        }
        try stdout_writer.interface.print("ok zig-source-native-link {s} [{s} {s}] fallback={s}\n", .{ case.id, case.mode, validationName(case.validation), case.fallback });
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.print("summary zig-source-native-link total={} executable_ok={} link_only_ok={} local_fail=0\n", .{ cases.len, executable_ok, link_only_ok });
    try stdout_writer.interface.flush();
}

fn runCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    zig_emitter: []const u8,
    target: []const u8,
    cc_target: []const u8,
    case: Case,
) !void {
    const ir_path = try common.allocTempFile(allocator, temp, case.id, ".ll");
    defer allocator.free(ir_path);
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const harness_c = try common.allocTempFile(allocator, temp, case.id, "_harness.c");
    defer allocator.free(harness_c);
    const harness_o = try common.allocTempFile(allocator, temp, case.id, "_harness.o");
    defer allocator.free(harness_o);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_native_link");
    defer allocator.free(exe);

    try emitZigIr(allocator, io, zig_emitter, cc_target, ir_path, case);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_object_argv = [_][]const u8{ "zig-out/bin/z_llvm", "--emit=obj", target_arg, "--input-limit=67108864", ir_path };
    try common.runToFile(allocator, io, &emit_object_argv, "z_llvm --emit=obj", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = case.harness });
    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, "-c", harness_c, "-o", harness_o };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc -c");
    common.freeRunResult(allocator, cc_result);

    var link_args: std.ArrayList([]const u8) = .empty;
    defer link_args.deinit(allocator);
    const emit_bin_arg = try std.fmt.allocPrint(allocator, "-femit-bin={s}", .{exe});
    defer allocator.free(emit_bin_arg);
    try link_args.appendSlice(allocator, &.{ "zig", "build-exe", "-target", cc_target, "-fno-lld", harness_o, object });

    var stub_o: ?[]const u8 = null;
    defer if (stub_o) |path| allocator.free(path);
    if (case.stubs.len != 0) {
        const stub_s = try common.allocTempFile(allocator, temp, case.id, "_stubs.s");
        defer allocator.free(stub_s);
        const stub_object = try common.allocTempFile(allocator, temp, case.id, "_stubs.o");
        stub_o = stub_object;
        try writeStubAsm(allocator, io, stub_s, case.stubs);
        const asm_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, "-c", stub_s, "-o", stub_object };
        const asm_result = try common.runCapture(allocator, io, &asm_argv, "zig cc -c native-link stubs");
        common.freeRunResult(allocator, asm_result);
        try link_args.append(allocator, stub_object);
    }

    if (case.link_math) try link_args.append(allocator, "-lm");
    try link_args.appendSlice(allocator, &.{ "-lc", emit_bin_arg });

    const link_result = try common.runCapture(allocator, io, link_args.items, "zig build-exe -fno-lld");
    common.freeRunResult(allocator, link_result);

    if (case.validation == .executable) {
        const run_argv = [_][]const u8{exe};
        const run_result = try common.runCapture(allocator, io, &run_argv, exe);
        common.freeRunResult(allocator, run_result);
    }
}

fn emitZigIr(
    allocator: std.mem.Allocator,
    io: std.Io,
    zig_emitter: []const u8,
    cc_target: []const u8,
    output_path: []const u8,
    case: Case,
) !void {
    const emit_arg = try std.fmt.allocPrint(allocator, "-femit-llvm-ir={s}", .{output_path});
    defer allocator.free(emit_arg);

    var argv: std.ArrayList([]const u8) = .empty;
    defer argv.deinit(allocator);
    try argv.appendSlice(allocator, &.{
        zig_emitter,
        "build-obj",
        "-fllvm",
        "-flibllvm",
    });
    if (shouldStrip(case.mode)) try argv.append(allocator, "-fstrip");
    try argv.appendSlice(allocator, &.{
        "-fno-emit-bin",
        emit_arg,
        "-O",
        case.mode,
        "-target",
        cc_target,
        case.source,
    });

    const result = try common.runCapture(allocator, io, argv.items, "stage4 Zig LLVM IR capture");
    common.freeRunResult(allocator, result);
}

fn writeStubAsm(allocator: std.mem.Allocator, io: std.Io, path: []const u8, stubs: []const native_cases.Stub) !void {
    var text: std.ArrayList(u8) = .empty;
    defer text.deinit(allocator);

    for (stubs) |stub| {
        const block = try std.fmt.allocPrint(allocator,
            \\.text
            \\.globl "{s}"
            \\.type "{s}", @function
            \\"{s}":
            \\  ud2
            \\
        , .{ stub.symbol, stub.symbol, stub.symbol });
        defer allocator.free(block);
        try text.appendSlice(allocator, block);
    }

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = text.items });
}

fn shouldStrip(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or std.mem.eql(u8, mode, "ReleaseSmall");
}

fn defaultCcTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
}

fn validationName(validation: Validation) []const u8 {
    return switch (validation) {
        .executable => "executable",
        .link_only => "link-only",
    };
}
