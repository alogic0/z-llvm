const std = @import("std");
const common = @import("tool_common.zig");

const default_manifest = "test/distribution/releasefast_x86_64/manifest.tsv";

const Row = struct {
    id: []const u8,
    input: []const u8,
    validation: []const u8,
    expected_status: []const u8,
    source_row: []const u8,
    shape: []const u8,
    public_symbol: []const u8,
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const manifest_arg = try parseManifestArg(allocator, io, init);
    defer if (manifest_arg.owned) allocator.free(manifest_arg.path);

    const target = try getEnvOwnedOrNull(allocator, init.minimal.environ, "TARGET");
    defer if (target) |value| allocator.free(value);

    const temp = try common.TempDir.init(allocator, io, "distribution_object_m1");
    defer temp.deinit(allocator, io);

    const contents = std.Io.Dir.cwd().readFileAlloc(io, manifest_arg.path, allocator, .limited(64 * 1024 * 1024)) catch |err| {
        try common.validationError(io, "{s}: {s}\n", .{ manifest_arg.path, @errorName(err) });
    };
    defer allocator.free(contents);

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line_no == 1 or line.len == 0) continue;

        const row = parseRow(line) orelse {
            try common.validationError(io, "{s}:{} invalid manifest row\n", .{ manifest_arg.path, line_no });
        };

        if (std.mem.eql(u8, row.validation, "object-readelf")) {
            try runObjectReadelf(allocator, io, temp, target orelse "x86_64-unknown-linux-gnu", row);
            try stdout_writer.interface.print("ok distribution object {s} [{s}]\n", .{ row.id, row.shape });
            try stdout_writer.interface.flush();
        } else if (std.mem.eql(u8, row.validation, "known-blocker")) {
            try runKnownBlocker(allocator, io, temp, target orelse "x86_64-unknown-linux-gnu", row);
            try stdout_writer.interface.print("ok distribution blocker {s} [{s}]\n", .{ row.id, row.expected_status });
            try stdout_writer.interface.flush();
        } else {
            try common.validationError(io, "unknown validation type for {s}: {s}\n", .{ row.id, row.validation });
        }
    }
}

const ManifestArg = struct {
    path: []const u8,
    owned: bool = false,
};

fn parseManifestArg(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !ManifestArg {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    const first = args.next() orelse return .{ .path = default_manifest };
    if (std.mem.eql(u8, first, "--help") or std.mem.eql(u8, first, "-h")) {
        var stdout_buffer: [512]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        try stdout_writer.interface.writeAll("usage: zig run tools/run_distribution_object_m1.zig -- [manifest]\n");
        try stdout_writer.interface.flush();
        std.process.exit(0);
    }
    if (args.next()) |extra| {
        try common.validationError(io, "unexpected argument: {s}\n", .{extra});
    }
    return .{ .path = try allocator.dupe(u8, first), .owned = true };
}

fn parseRow(line: []const u8) ?Row {
    var fields: [7][]const u8 = undefined;
    var rest = line;
    var index: usize = 0;
    while (index + 1 < fields.len) : (index += 1) {
        const split = std.mem.indexOfScalar(u8, rest, '\t') orelse return null;
        fields[index] = rest[0..split];
        rest = rest[split + 1 ..];
    }
    fields[index] = rest;
    if (fields[0].len == 0) return null;
    return .{
        .id = fields[0],
        .input = fields[1],
        .validation = fields[2],
        .expected_status = fields[3],
        .source_row = fields[4],
        .shape = fields[5],
        .public_symbol = fields[6],
    };
}

fn runObjectReadelf(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    row: Row,
) !void {
    _ = row.source_row;
    const object = try common.allocTempFile(allocator, temp, row.id, ".o");
    defer allocator.free(object);
    const summary = try common.allocTempFile(allocator, temp, row.id, ".readelf.txt");
    defer allocator.free(summary);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const obj_argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, row.input };
    try common.runToFile(allocator, io, &obj_argv, "zig build run", object);

    const readelf_argv = [_][]const u8{ "readelf", "-W", "-h", "-S", "-s", "-r", object };
    try common.runToFile(allocator, io, &readelf_argv, "readelf", summary);
    try expectRegex(allocator, io, summary, "Type:[[:space:]]+REL");
    try expectRegex(allocator, io, summary, "Machine:[[:space:]]+Advanced Micro Devices X86-64");
    try expectRegex(allocator, io, summary, "\\.text");
    try expectRegex(allocator, io, summary, "\\.symtab");
    if (row.public_symbol.len != 0) {
        const pattern = try std.fmt.allocPrint(allocator, "[[:space:]]{s}$", .{row.public_symbol});
        defer allocator.free(pattern);
        try expectRegex(allocator, io, summary, pattern);
    }
    if (std.mem.eql(u8, row.id, "atomics_atomic_add")) {
        try expectRegex(allocator, io, summary, "\\.data");
        try expectRegex(allocator, io, summary, "\\.rela\\.text");
        try expectRegex(allocator, io, summary, "[[:space:]]atomics_inline_asm_debug\\.atomic_counter$");
        try expectRegex(allocator, io, summary, "R_X86_64_PC32.*atomics_inline_asm_debug\\.atomic_counter - 4");
    }
    if (std.mem.eql(u8, row.id, "tls_concurrency_bump_tls") or std.mem.eql(u8, row.id, "tls_concurrency_read_tls")) {
        try expectRegex(allocator, io, summary, "\\.tdata");
        try expectRegex(allocator, io, summary, "TLS[[:space:]]+GLOBAL.*tls_concurrency\\.tls_counter");
        try expectRegex(allocator, io, summary, "R_X86_64_TPOFF32.*tls_concurrency\\.tls_counter");
    }
}

fn runKnownBlocker(
    allocator: std.mem.Allocator,
    io: std.Io,
    temp: common.TempDir,
    target: []const u8,
    row: Row,
) !void {
    const object = try common.allocTempFile(allocator, temp, row.id, ".o");
    defer allocator.free(object);
    const log = try common.allocTempFile(allocator, temp, row.id, ".stderr.txt");
    defer allocator.free(log);

    const target_arg = try std.fmt.allocPrint(allocator, "--target={s}", .{target});
    defer allocator.free(target_arg);
    const argv = [_][]const u8{ "zig", "build", "run", "--", "--emit=obj", target_arg, row.input };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(32 * 1024 * 1024),
    });
    defer common.freeRunResult(allocator, result);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = object, .data = result.stdout });
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = log, .data = result.stderr });

    if (common.termOk(result.term)) {
        try common.validationError(io, "unexpected object success for blocker {s} [{s}]\n", .{ row.id, row.shape });
    }
    try expectRegex(allocator, io, log, row.expected_status);
}

fn expectRegex(allocator: std.mem.Allocator, io: std.Io, path: []const u8, pattern: []const u8) !void {
    const argv = [_][]const u8{ "rg", "-q", pattern, path };
    const result = try common.runCapture(allocator, io, &argv, "rg");
    common.freeRunResult(allocator, result);
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}
