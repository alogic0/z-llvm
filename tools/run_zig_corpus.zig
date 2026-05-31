const std = @import("std");
const manifest_parser = @import("zig_ir_manifest.zig");

const usage =
    \\usage: zig run tools/run_zig_corpus.zig -- [manifest]
    \\
    \\Run accepted Zig IR corpus rows through the local pipeline.
    \\Set PASSES to override each row's local-pipeline metadata.
    \\
;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const manifest_arg = try parseManifestArg(allocator, io, init);
    defer if (manifest_arg.owned) allocator.free(manifest_arg.path);

    const passes_override = try getEnvOwnedOrNull(allocator, init.minimal.environ, "PASSES");
    defer if (passes_override) |passes| allocator.free(passes);

    var manifest = manifest_parser.load(allocator, io, manifest_arg.path, 64 * 1024 * 1024) catch |err| switch (err) {
        error.InvalidFieldCount => try validationError(io, "{s}: invalid TSV field count\n", .{manifest_arg.path}),
        else => try validationError(io, "{s}: {s}\n", .{ manifest_arg.path, @errorName(err) }),
    };
    defer manifest.deinit(allocator);

    const tmp_dir = try makeTempDir(allocator, io);
    defer {
        std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
        allocator.free(tmp_dir);
    }

    var accepted_rows: usize = 0;
    var unsupported_rows: usize = 0;
    var future_rows: usize = 0;
    var debug_only_rows: usize = 0;

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);

    for (manifest.rows) |row| {
        if (row.hasClassification("unsupported")) unsupported_rows += 1;
        if (row.hasClassification("future")) future_rows += 1;
        if (row.hasClassification("debug-info-only")) debug_only_rows += 1;

        const checked_ir_path = row.checkedIrPath();
        if (checked_ir_path.len == 0) continue;
        if (row.hasClassification("unsupported")) continue;
        if (!row.hasClassification("parse")) continue;
        if (!row.hasClassification("verify")) continue;
        if (!row.hasClassification("optimizer-input")) continue;

        const passes = passes_override orelse row.metadataValue("local-pipeline") orelse {
            try validationError(io, "missing local-pipeline metadata for accepted row {s}\n", .{row.id()});
        };

        const output_path = try tempOutputPath(allocator, tmp_dir, row.id());
        defer allocator.free(output_path);

        try runLocalPipeline(allocator, io, passes, checked_ir_path, output_path);
        try runNormalize(allocator, io, output_path);

        accepted_rows += 1;
        try stdout_writer.interface.print("ok {s} [{s} {s}: {s}]\n", .{
            row.id(),
            row.group(),
            row.optimizeMode(),
            passes,
        });
        try stdout_writer.interface.flush();
    }

    try stdout_writer.interface.print("summary accepted={} unsupported={} future={} debug-info-only={}\n", .{
        accepted_rows,
        unsupported_rows,
        future_rows,
        debug_only_rows,
    });
    try stdout_writer.interface.flush();
}

const ManifestArg = struct {
    path: []const u8,
    owned: bool = false,
};

fn parseManifestArg(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !ManifestArg {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();
    _ = args.next();

    const first = args.next() orelse return .{ .path = manifest_parser.default_path };
    if (std.mem.eql(u8, first, "--help") or std.mem.eql(u8, first, "-h")) {
        var stdout_buffer: [512]u8 = undefined;
        var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
        try stdout_writer.interface.writeAll(usage);
        try stdout_writer.interface.flush();
        std.process.exit(0);
    }
    if (args.next()) |extra| {
        try validationError(io, "unexpected argument: {s}\n{s}", .{ extra, usage });
    }
    return .{ .path = try allocator.dupe(u8, first), .owned = true };
}

fn getEnvOwnedOrNull(allocator: std.mem.Allocator, environ: std.process.Environ, name: []const u8) !?[]const u8 {
    return environ.getAlloc(allocator, name) catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => err,
    };
}

fn makeTempDir(allocator: std.mem.Allocator, io: std.Io) ![]const u8 {
    var cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, "tmp");
    const path = try std.fmt.allocPrint(allocator, "tmp/run_zig_corpus_{}", .{std.os.linux.getpid()});
    errdefer allocator.free(path);
    cwd.deleteTree(io, path) catch {};
    try cwd.createDirPath(io, path);
    return path;
}

fn tempOutputPath(allocator: std.mem.Allocator, tmp_dir: []const u8, id: []const u8) ![]const u8 {
    const stem = try safeStem(allocator, id);
    defer allocator.free(stem);
    const file = try std.fmt.allocPrint(allocator, "{s}.ll", .{stem});
    defer allocator.free(file);
    return std.fs.path.join(allocator, &.{ tmp_dir, file });
}

fn safeStem(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    const stem = try allocator.dupe(u8, text);
    for (stem) |*byte| {
        if (!std.ascii.isAlphanumeric(byte.*) and byte.* != '_' and byte.* != '.' and byte.* != '-') {
            byte.* = '_';
        }
    }
    return stem;
}

fn runLocalPipeline(
    allocator: std.mem.Allocator,
    io: std.Io,
    passes: []const u8,
    checked_ir_path: []const u8,
    output_path: []const u8,
) !void {
    const passes_arg = try std.fmt.allocPrint(allocator, "--passes={s}", .{passes});
    defer allocator.free(passes_arg);
    const argv = [_][]const u8{ "zig", "build", "run", "--", passes_arg, checked_ir_path };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    if (!termOk(result.term)) {
        try forwardCommandFailure(io, "zig build run", result);
    }
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = output_path, .data = result.stdout });
}

fn runNormalize(allocator: std.mem.Allocator, io: std.Io, output_path: []const u8) !void {
    const argv = [_][]const u8{ "zig", "run", "src/normalize_cli.zig", "--", output_path };
    const result = try std.process.run(allocator, io, .{
        .argv = &argv,
        .stdout_limit = .limited(128 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    defer freeRunResult(allocator, result);
    if (!termOk(result.term)) {
        try forwardCommandFailure(io, "zig run src/normalize_cli.zig", result);
    }
}

fn freeRunResult(allocator: std.mem.Allocator, result: std.process.RunResult) void {
    allocator.free(result.stdout);
    allocator.free(result.stderr);
}

fn termOk(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn forwardCommandFailure(io: std.Io, label: []const u8, result: std.process.RunResult) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print("{s} failed\n", .{label});
    if (result.stderr.len != 0) {
        try stderr_writer.interface.writeAll(result.stderr);
    } else {
        try stderr_writer.interface.writeAll(result.stdout);
    }
    try stderr_writer.interface.flush();
    std.process.exit(1);
}

fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}
