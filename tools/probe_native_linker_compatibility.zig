const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const mode_filter = try parseModeFilter(allocator, io, init);
    defer if (mode_filter.owned) allocator.free(mode_filter.mode.?);

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
    var selected: usize = 0;
    for (native_cases.cases) |case| {
        if (!modeMatches(mode_filter.mode, case.mode)) continue;
        selected += 1;
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

    if (selected == 0) {
        try common.validationError(io, "no native-link probe cases selected for mode filter\n", .{});
    }

    const mode_label = mode_filter.mode orelse "all";
    try stdout_writer.interface.print("summary native-link-probe target={s} mode={s} linker=zig build-exe -fno-lld accepted={} failed=0\n", .{ target, mode_label, accepted });
    try stdout_writer.interface.flush();
}

const ModeFilter = struct {
    mode: ?[]const u8,
    owned: bool = false,
};

fn parseModeFilter(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !ModeFilter {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var mode: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll("usage: zig build probe-native-linker -- [--mode=ReleaseFast|ReleaseSafe|ReleaseSmall|Debug]\n");
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            if (mode != null) try common.validationError(io, "duplicate --mode argument\n", .{});
            const value = arg["--mode=".len..];
            if (!isKnownMode(value)) try common.validationError(io, "unknown native-link probe mode: {s}\n", .{value});
            mode = try allocator.dupe(u8, value);
        } else {
            try common.validationError(io, "unexpected native-link probe argument: {s}\n", .{arg});
        }
    }

    return .{ .mode = mode, .owned = mode != null };
}

fn modeMatches(filter: ?[]const u8, mode: []const u8) bool {
    return filter == null or std.mem.eql(u8, filter.?, mode);
}

fn isKnownMode(mode: []const u8) bool {
    return std.mem.eql(u8, mode, "ReleaseFast") or
        std.mem.eql(u8, mode, "ReleaseSafe") or
        std.mem.eql(u8, mode, "ReleaseSmall") or
        std.mem.eql(u8, mode, "Debug");
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

    if (case.link_math) try link_args.append(allocator, "-lm");
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
