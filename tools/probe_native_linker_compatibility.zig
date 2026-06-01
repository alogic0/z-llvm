const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const target = target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);

    const temp = try common.TempDir.init(allocator, io, "native_linker_probe");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var accepted: usize = 0;
    for (native_cases.cases) |case| {
        const result = try probeCase(allocator, io, temp, target, cc_target, case);
        switch (result) {
            .accepted => {
                accepted += 1;
                try stdout_writer.interface.print("ok native-link probe {s} [{s}: accepted]\n", .{ case.id, case.mode });
            },
            .failed => |failure| {
                defer allocator.free(failure.stderr);
                try stdout_writer.interface.print("fail native-link probe {s} [{s}: {s}]\n", .{ case.id, case.mode, failure.category });
                try stdout_writer.interface.writeAll(failure.stderr);
                try stdout_writer.interface.flush();
                std.process.exit(1);
            },
        }
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.print("summary native-link-probe target={s} linker=zig build-exe -fno-lld accepted={} failed=0\n", .{ target, accepted });
    try stdout_writer.interface.flush();
}

const ProbeResult = union(enum) {
    accepted,
    failed: Failure,
};

const Failure = struct {
    category: []const u8,
    stderr: []u8,
};

fn probeCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    cc_target: []const u8,
    case: native_cases.Case,
) !ProbeResult {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const harness_c = try common.allocTempFile(allocator, temp, case.id, "_harness.c");
    defer allocator.free(harness_c);
    const harness_o = try common.allocTempFile(allocator, temp, case.id, "_harness.o");
    defer allocator.free(harness_o);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_native_link_probe");
    defer allocator.free(exe);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const emit_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, "--input-limit=67108864", case.fixture };
    try common.runToFile(allocator, io, &emit_argv, "zig build run", object);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = harness_c, .data = case.harness });
    const cc_argv = [_][]const u8{ "zig", "cc", "-target", cc_target, "-c", harness_c, "-o", harness_o };
    const cc_result = try common.runCapture(allocator, io, &cc_argv, "zig cc -c native-link probe harness");
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
        const asm_result = try common.runCapture(allocator, io, &asm_argv, "zig cc -c native-link probe stubs");
        common.freeRunResult(allocator, asm_result);
        try link_args.append(allocator, stub_object);
    }

    try link_args.appendSlice(allocator, &.{ "-lc", emit_bin_arg });
    const link_result = try std.process.run(allocator, io, .{
        .argv = link_args.items,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer allocator.free(link_result.stdout);

    if (common.termOk(link_result.term)) {
        allocator.free(link_result.stderr);
        return .accepted;
    }

    const category = classifyFailure(link_result.stderr);
    return .{ .failed = .{
        .category = category,
        .stderr = link_result.stderr,
    } };
}

fn classifyFailure(stderr: []const u8) []const u8 {
    if (std.mem.indexOf(u8, stderr, "undefined symbol") != null or
        std.mem.indexOf(u8, stderr, "undefined reference") != null)
    {
        return "symbol";
    }
    if (std.mem.indexOf(u8, stderr, "relocation") != null) return "relocation";
    if (std.mem.indexOf(u8, stderr, "section") != null) return "section";
    if (std.mem.indexOf(u8, stderr, "TLS") != null or std.mem.indexOf(u8, stderr, "thread-local") != null) return "tls-model";
    if (std.mem.indexOf(u8, stderr, "COMDAT") != null or std.mem.indexOf(u8, stderr, "comdat") != null) return "comdat";
    if (std.mem.indexOf(u8, stderr, "align") != null) return "alignment";
    if (std.mem.indexOf(u8, stderr, "ABI") != null or std.mem.indexOf(u8, stderr, "calling convention") != null) return "abi";
    return "unknown-linker-compatibility";
}

fn defaultCcTarget(target: []const u8) []const u8 {
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-gnu")) return "x86_64-linux-gnu";
    if (std.mem.eql(u8, target, "x86_64-unknown-linux-musl")) return "x86_64-linux-musl";
    return target;
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
