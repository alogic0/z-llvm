const std = @import("std");
const manifest_parser = @import("zig_ir_manifest.zig");

const usage =
    \\usage: zig run tools/lint_zig_ir_manifest.zig -- [manifest]
    \\
    \\Validate the Zig IR fixture manifest TSV.
    \\
;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const manifest = try parseManifestArg(allocator, io, init);
    defer if (manifest.owned) allocator.free(manifest.path);

    var parsed = manifest_parser.load(allocator, io, manifest.path, 64 * 1024 * 1024) catch |err| switch (err) {
        error.InvalidFieldCount => try reportInvalidFieldCount(allocator, io, manifest.path),
        else => try validationError(io, "{s}: {s}\n", .{ manifest.path, @errorName(err) }),
    };
    defer parsed.deinit(allocator);

    var accepted: usize = 0;
    for (parsed.rows) |row| {
        const source_path = row.sourcePath();
        const raw_ir_path = row.rawIrPath();
        const checked_ir_path = row.checkedIrPath();
        const inventory_links = row.inventoryLinks();

        if (std.mem.startsWith(u8, source_path, "test/zig/inputs/") and !try manifest_parser.fileExists(io, source_path)) {
            try validationError(io, "{s}:{} missing source path: {s}\n", .{ manifest.path, row.line_no, source_path });
        }

        if (checked_ir_path.len != 0 and !try manifest_parser.fileExists(io, checked_ir_path)) {
            try validationError(io, "{s}:{} missing checked IR path: {s}\n", .{ manifest.path, row.line_no, checked_ir_path });
        }

        if (std.mem.startsWith(u8, raw_ir_path, "test/zig/captured/") and !try manifest_parser.fileExists(io, raw_ir_path)) {
            try validationError(io, "{s}:{} missing captured raw IR path: {s}\n", .{ manifest.path, row.line_no, raw_ir_path });
        }

        if (row.hasClassification("unsupported") and row.hasClassification("optimizer-input")) {
            try validationError(io, "{s}:{} unsupported row cannot be optimizer-input: {s}\n", .{ manifest.path, row.line_no, row.id() });
        }

        if (row.hasClassification("optimizer-input")) {
            accepted += 1;
            if (checked_ir_path.len == 0) {
                try validationError(io, "{s}:{} optimizer-input row needs checked_ir_path: {s}\n", .{ manifest.path, row.line_no, row.id() });
            }
            if (!row.hasClassification("parse") or !row.hasClassification("verify")) {
                try validationError(io, "{s}:{} optimizer-input row must also be parse,verify: {s}\n", .{ manifest.path, row.line_no, row.id() });
            }
            if (std.mem.indexOf(u8, inventory_links, "local-pipeline=") == null) {
                try validationError(io, "{s}:{} optimizer-input row needs local-pipeline metadata: {s}\n", .{ manifest.path, row.line_no, row.id() });
            }
        }
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok manifest rows={} optimizer_input={}\n", .{ parsed.rows.len, accepted });
    try stdout_writer.interface.flush();
}

fn reportInvalidFieldCount(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !noreturn {
    var cwd = std.Io.Dir.cwd();
    const contents = cwd.readFileAlloc(io, path, allocator, .limited(64 * 1024 * 1024)) catch |err| {
        try validationError(io, "{s}: {s}\n", .{ path, @errorName(err) });
    };
    defer allocator.free(contents);

    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        const actual_fields = manifest_parser.fieldCount(line);
        if (actual_fields != manifest_parser.expected_fields) {
            try validationError(io, "{s}:{} expected {} TSV fields, found {}\n", .{
                path,
                line_no,
                manifest_parser.expected_fields,
                actual_fields,
            });
        }
    }
    try validationError(io, "{s}: invalid TSV field count\n", .{path});
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

fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}
