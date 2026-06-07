const std = @import("std");
const common = @import("tool_common.zig");
const native_cases = @import("native_link_cases.zig");
const source_owned = @import("run_distribution_zig_integrated_object.zig");
const source_handoff = @import("source_owned_handoff.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const filters = try parseFilters(allocator, io, init);
    defer filters.deinit(allocator);

    const target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target_env) |value| allocator.free(value);
    const cc_target_env = try common.getEnvOwnedOrNull(allocator, init.minimal.environ, "CC_TARGET");
    defer if (cc_target_env) |value| allocator.free(value);
    const target = if (filters.release_source_owned) source_handoff.normalizeZigTarget(target_env orelse "x86_64-linux-gnu") else target_env orelse "x86_64-unknown-linux-gnu";
    const cc_target = cc_target_env orelse defaultCcTarget(target);
    const source_context = if (filters.release_source_owned) try source_handoff.Context.init(allocator, io, init, target) else null;
    defer if (source_context) |context| context.deinit(allocator);

    const temp = try common.TempDir.init(allocator, io, "native_linker_probe");
    defer temp.deinit(allocator, io);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var accepted: usize = 0;
    var selected: usize = 0;
    if (filters.release_source_owned) {
        const context = source_context.?;
        var runtime_boundary_rows: usize = 0;
        var unsupported_zig_linker_feature_rows: usize = 0;
        for (source_owned.cases) |case| {
            if (!source_owned.isReleaseSourceOwnedCase(case) or !filters.matchesSourceOwned(case)) continue;
            selected += 1;
            const result = try probeSourceOwnedCase(allocator, io, temp, context, target, case);
            switch (result) {
                .accepted => {
                    accepted += 1;
                    try stdout_writer.interface.print("ok native-link probe source-owned {s} [{s}: accepted]\n", .{ case.id, case.mode });
                },
                .runtime_boundary => {
                    runtime_boundary_rows += 1;
                    try stdout_writer.interface.print("boundary native-link probe source-owned {s} [{s}: runtime/compiler-rt/libc-boundary]\n", .{ case.id, case.mode });
                },
                .unsupported_zig_linker_feature => {
                    unsupported_zig_linker_feature_rows += 1;
                    try common.validationError(io, "source-owned native-link probe {s} hit unsupported Zig linker feature\n", .{case.id});
                },
            }
            try stdout_writer.interface.flush();
        }
        if (selected == 0) {
            try common.validationError(io, "no source-owned native-link probe cases selected for filters\n", .{});
        }
        if (filters.mode == null and filters.case_id == null and selected != source_handoff.expected_release_source_owned_rows) {
            try common.validationError(io, "release source-owned native-link probe requires selected={} rows; selected={}\n", .{ source_handoff.expected_release_source_owned_rows, selected });
        }
        const mode_label = filters.mode orelse "all";
        const case_label = filters.case_id orelse "all";
        try stdout_writer.interface.print("summary native-link-probe inventory=release-source-owned target={s} mode={s} case={s} linker=zig build-exe -fno-lld accepted={} runtime_compiler_rt_libc_boundary_rows={} unsupported_zig_linker_feature_rows={} local_object_codegen_failures=0 failed=0\n", .{ target, mode_label, case_label, accepted, runtime_boundary_rows, unsupported_zig_linker_feature_rows });
        try stdout_writer.interface.flush();
    } else {
        for (native_cases.cases) |case| {
            if (!filters.matchesNative(case)) continue;
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
            try common.validationError(io, "no native-link probe cases selected for filters\n", .{});
        }

        const mode_label = filters.mode orelse "all";
        try stdout_writer.interface.print("summary native-link-probe target={s} mode={s} linker=zig build-exe -fno-lld accepted={} failed=0\n", .{ target, mode_label, accepted });
        try stdout_writer.interface.flush();
    }
}

const Filters = struct {
    mode: ?[]const u8 = null,
    case_id: ?[]const u8 = null,
    release_source_owned: bool = false,

    fn deinit(filters: Filters, allocator: std.mem.Allocator) void {
        if (filters.mode) |mode| allocator.free(mode);
        if (filters.case_id) |case_id| allocator.free(case_id);
    }

    fn matchesNative(filters: Filters, case: native_cases.Case) bool {
        if (!modeMatches(filters.mode, case.mode)) return false;
        if (filters.case_id) |case_id| {
            if (!std.mem.eql(u8, case_id, case.id)) return false;
        }
        return true;
    }

    fn matchesSourceOwned(filters: Filters, case: source_owned.Case) bool {
        if (!modeMatches(filters.mode, case.mode)) return false;
        if (filters.case_id) |case_id| {
            if (!std.mem.eql(u8, case_id, case.id)) return false;
        }
        return true;
    }
};

fn parseFilters(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Filters {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    var filters: Filters = .{};
    errdefer filters.deinit(allocator);
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stdout_buffer: [512]u8 = undefined;
            var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
            try stdout_writer.interface.writeAll("usage: zig build probe-native-linker -- [--release-source-owned] [--mode=ReleaseFast|ReleaseSafe|ReleaseSmall|Debug] [--case=<case-id>]\n");
            try stdout_writer.interface.flush();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--release-source-owned")) {
            filters.release_source_owned = true;
        } else if (std.mem.startsWith(u8, arg, "--mode=")) {
            if (filters.mode != null) try common.validationError(io, "duplicate --mode argument\n", .{});
            const value = arg["--mode=".len..];
            if (!isKnownMode(value)) try common.validationError(io, "unknown native-link probe mode: {s}\n", .{value});
            filters.mode = try allocator.dupe(u8, value);
        } else if (std.mem.startsWith(u8, arg, "--case=")) {
            if (filters.case_id != null) try common.validationError(io, "duplicate --case argument\n", .{});
            filters.case_id = try allocator.dupe(u8, arg["--case=".len..]);
        } else {
            try common.validationError(io, "unexpected native-link probe argument: {s}\n", .{arg});
        }
    }

    return filters;
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

const SourceOwnedProbeResult = enum {
    accepted,
    runtime_boundary,
    unsupported_zig_linker_feature,
};

fn probeSourceOwnedCase(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    context: source_handoff.Context,
    target: []const u8,
    case: source_owned.Case,
) !SourceOwnedProbeResult {
    const object = try common.allocTempFile(allocator, temp, case.id, ".o");
    defer allocator.free(object);
    const marker = try common.allocTempFile(allocator, temp, case.id, "_zllvm_marker.txt");
    defer allocator.free(marker);
    const ir_path = try common.allocTempFile(allocator, temp, case.id, ".external.ll");
    defer allocator.free(ir_path);
    const descriptor_path = try common.allocTempFile(allocator, temp, case.id, ".semantic_descriptor");
    defer allocator.free(descriptor_path);
    const exe = try common.allocTempFile(allocator, temp, case.id, "_source_owned_native_link_probe");
    defer allocator.free(exe);

    try source_handoff.emitObject(allocator, io, context, case, object, marker, ir_path, descriptor_path);
    const result = try source_handoff.probeLinkObject(allocator, io, target, object, exe);
    switch (result) {
        .accepted => return .accepted,
        .failed => |failure| {
            defer allocator.free(failure.stderr);
            if (source_handoff.isGenericFailureCategory(failure.category)) {
                try common.validationError(io, "source-owned native-link probe row {s} used forbidden generic failure bucket: {s}\n", .{ case.id, failure.category });
            }
            if (std.mem.eql(u8, failure.category, "runtime/compiler-rt/libc-boundary")) return .runtime_boundary;
            if (std.mem.eql(u8, failure.category, "zig-linker-bug-or-unsupported-feature")) return .unsupported_zig_linker_feature;
            try common.validationError(io, "source-owned native-link probe row {s} failed with category={s}\n{s}\n", .{ case.id, failure.category, failure.stderr });
        },
    }
}

fn classifyFailure(stderr: []const u8) []const u8 {
    if (std.mem.indexOf(u8, stderr, "undefined symbol") != null or
        std.mem.indexOf(u8, stderr, "undefined reference") != null)
    {
        if (std.mem.indexOf(u8, stderr, "compiler_rt") != null or std.mem.indexOf(u8, stderr, "libc") != null) return "runtime/compiler-rt/libc-boundary";
        return "bad-symbol-binding-type";
    }
    if (std.mem.indexOf(u8, stderr, "relocation") != null) return "missing-relocation-support";
    if (std.mem.indexOf(u8, stderr, "section") != null) return "section-flag-alignment";
    if (std.mem.indexOf(u8, stderr, "TLS") != null or std.mem.indexOf(u8, stderr, "thread-local") != null) return "tls-model";
    if (std.mem.indexOf(u8, stderr, "COMDAT") != null or std.mem.indexOf(u8, stderr, "comdat") != null) return "comdat";
    if (std.mem.indexOf(u8, stderr, "align") != null) return "section-flag-alignment";
    if (std.mem.indexOf(u8, stderr, "ABI") != null or std.mem.indexOf(u8, stderr, "calling convention") != null) return "abi";
    return "zig-linker-bug-or-unsupported-feature";
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
