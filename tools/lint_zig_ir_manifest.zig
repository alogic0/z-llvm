const std = @import("std");

const expected_fields = 14;
const default_manifest = "docs/fixtures/zig_ir/manifest.tsv";

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

    var cwd = std.Io.Dir.cwd();
    const contents = cwd.readFileAlloc(io, manifest.path, allocator, .limited(64 * 1024 * 1024)) catch |err| {
        try validationError(io, "{s}: {s}\n", .{ manifest.path, @errorName(err) });
    };
    defer allocator.free(contents);

    var rows: usize = 0;
    var accepted: usize = 0;
    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');

    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        const actual_fields = fieldCount(line);
        if (actual_fields != expected_fields) {
            try validationError(io, "{s}:{} expected {} TSV fields, found {}\n", .{
                manifest.path,
                line_no,
                expected_fields,
                actual_fields,
            });
        }

        const fields = splitTsvLine(line);
        const id = fields[0];
        if (id.len == 0) continue;

        rows += 1;
        const source_path = fields[2];
        const raw_ir_path = fields[9];
        const checked_ir_path = fields[10];
        const classification = fields[11];
        const inventory_links = fields[12];

        if (std.mem.startsWith(u8, source_path, "test/zig/inputs/") and !try fileExists(io, source_path)) {
            try validationError(io, "{s}:{} missing source path: {s}\n", .{ manifest.path, line_no, source_path });
        }

        if (checked_ir_path.len != 0 and !try fileExists(io, checked_ir_path)) {
            try validationError(io, "{s}:{} missing checked IR path: {s}\n", .{ manifest.path, line_no, checked_ir_path });
        }

        if (std.mem.startsWith(u8, raw_ir_path, "test/zig/captured/") and !try fileExists(io, raw_ir_path)) {
            try validationError(io, "{s}:{} missing captured raw IR path: {s}\n", .{ manifest.path, line_no, raw_ir_path });
        }

        if (hasClassification(classification, "unsupported") and hasClassification(classification, "optimizer-input")) {
            try validationError(io, "{s}:{} unsupported row cannot be optimizer-input: {s}\n", .{ manifest.path, line_no, id });
        }

        if (hasClassification(classification, "optimizer-input")) {
            accepted += 1;
            if (checked_ir_path.len == 0) {
                try validationError(io, "{s}:{} optimizer-input row needs checked_ir_path: {s}\n", .{ manifest.path, line_no, id });
            }
            if (!hasClassification(classification, "parse") or !hasClassification(classification, "verify")) {
                try validationError(io, "{s}:{} optimizer-input row must also be parse,verify: {s}\n", .{ manifest.path, line_no, id });
            }
            if (std.mem.indexOf(u8, inventory_links, "local-pipeline=") == null) {
                try validationError(io, "{s}:{} optimizer-input row needs local-pipeline metadata: {s}\n", .{ manifest.path, line_no, id });
            }
        }
    }

    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    try stdout_writer.interface.print("ok manifest rows={} optimizer_input={}\n", .{ rows, accepted });
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

    const first = args.next() orelse return .{ .path = default_manifest };
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

fn fieldCount(line: []const u8) usize {
    var count: usize = 1;
    for (line) |byte| {
        if (byte == '\t') count += 1;
    }
    return count;
}

fn splitTsvLine(line: []const u8) [expected_fields][]const u8 {
    var fields: [expected_fields][]const u8 = undefined;
    var rest = line;
    var field_index: usize = 0;
    while (field_index + 1 < expected_fields) : (field_index += 1) {
        if (std.mem.indexOfScalar(u8, rest, '\t')) |split| {
            fields[field_index] = rest[0..split];
            rest = rest[split + 1 ..];
        } else {
            fields[field_index] = rest;
            rest = "";
        }
    }
    fields[field_index] = rest;
    return fields;
}

fn hasClassification(classes: []const u8, needle: []const u8) bool {
    var rest = classes;
    while (true) {
        if (std.mem.indexOfScalar(u8, rest, ',')) |split| {
            if (std.mem.eql(u8, rest[0..split], needle)) return true;
            rest = rest[split + 1 ..];
        } else {
            return std.mem.eql(u8, rest, needle);
        }
    }
}

fn fileExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}

fn validationError(io: std.Io, comptime fmt: []const u8, args: anytype) !noreturn {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
    try stderr_writer.interface.print(fmt, args);
    try stderr_writer.interface.flush();
    std.process.exit(1);
}
