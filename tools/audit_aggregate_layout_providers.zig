const std = @import("std");

const generated_examples = [_][]const u8{};

const ProviderRow = struct {
    name: []const u8,
    aggregate_text: []const u8,
};

const Options = struct {
    air_paths: []const []const u8 = &.{},

    fn deinit(options: Options, allocator: std.mem.Allocator) void {
        for (options.air_paths) |path| allocator.free(path);
        allocator.free(options.air_paths);
    }
};

const exported_sidecar_paths = [_][]const u8{
    "test/zig/inputs/aggregate_layout_facts.sidecar",
    "test/zig/integrated/aggregate_layout_facts.sidecar",
    "test/zig/expanded/aggregate_layout_facts.sidecar",
    "test/zig/frontier/aggregate_layout_facts.sidecar",
};

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const options = try parseArgs(allocator, io, init);
    defer options.deinit(allocator);

    const fact_rows = try readProviderRows(allocator, io, "src/zig_air_aggregate_layout_facts.zig");
    defer freeProviderRows(allocator, fact_rows);
    const boundary_rows = try readProviderRows(allocator, io, "src/zig_air_aggregate_layout_boundaries.zig");
    defer freeProviderRows(allocator, boundary_rows);
    const exported_rows = try readSidecarRows(allocator, io, &exported_sidecar_paths);
    defer freeProviderRows(allocator, exported_rows);
    const descriptor_rows = try readDescriptorRows(allocator, io, options.air_paths);
    defer freeProviderRows(allocator, descriptor_rows);

    const total_exported_facts = exported_rows.len + descriptor_rows.len;

    try stdout.print(
        "summary aggregate-layout-provider-audit exported_facts={d} static_source_facts={d} boundary_provider={d} generated_examples={d} sidecar_exported_facts={d} descriptor_exported_facts={d}\n",
        .{
            total_exported_facts,
            fact_rows.len,
            boundary_rows.len,
            generated_examples.len,
            exported_rows.len,
            descriptor_rows.len,
        },
    );

    for (exported_rows) |row| {
        try stdout.print(
            "layout provider=sidecar_exported_aggregate_facts name={s} aggregate={s}\n",
            .{ row.name, row.aggregate_text },
        );
    }

    for (descriptor_rows) |row| {
        try stdout.print(
            "layout provider=descriptor_exported_aggregate_facts name={s} aggregate={s}\n",
            .{ row.name, row.aggregate_text },
        );
    }

    for (fact_rows) |row| {
        try stdout.print(
            "layout provider=static_source_facts name={s} aggregate={s}\n",
            .{ row.name, row.aggregate_text },
        );
    }

    for (generated_examples) |nominal| {
        try stdout.print(
            "layout provider=generated_inference name={s} aggregate=generated\n",
            .{nominal},
        );
    }

    for (boundary_rows) |row| {
        try stdout.print(
            "layout provider=boundary_provider name={s} aggregate={s}\n",
            .{ row.name, row.aggregate_text },
        );
    }

    try stdout.flush();
}

fn parseArgs(allocator: std.mem.Allocator, io: std.Io, init: std.process.Init) !Options {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer args.deinit();

    _ = args.next();
    var air_paths: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (air_paths.items) |path| allocator.free(path);
        air_paths.deinit(allocator);
    }

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            var stderr_buffer: [1024]u8 = undefined;
            var stderr_writer = std.Io.File.stderr().writer(io, &stderr_buffer);
            const stderr = &stderr_writer.interface;
            try stderr.writeAll(
                "usage: zig run tools/audit_aggregate_layout_providers.zig -- [--from-air=<descriptor.air> ...]\n",
            );
            try stderr.flush();
            std.process.exit(0);
        } else if (std.mem.startsWith(u8, arg, "--from-air=")) {
            const path = arg["--from-air=".len..];
            if (path.len == 0) return error.MissingAggregateLayoutDescriptorPath;
            try air_paths.append(allocator, try allocator.dupe(u8, path));
        } else {
            return error.UnknownAggregateLayoutAuditArgument;
        }
    }

    return .{ .air_paths = try air_paths.toOwnedSlice(allocator) };
}

fn readProviderRows(allocator: std.mem.Allocator, io: std.Io, path: []const u8) ![]ProviderRow {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(contents);

    var rows: std.ArrayList(ProviderRow) = .empty;
    errdefer rows.deinit(allocator);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const name = extractQuotedField(line, ".name = ") orelse continue;
        const aggregate_text = extractQuotedField(line, ".aggregate_text = ") orelse continue;
        try rows.append(allocator, .{
            .name = try allocator.dupe(u8, name),
            .aggregate_text = try allocator.dupe(u8, aggregate_text),
        });
    }

    return rows.toOwnedSlice(allocator);
}

fn readDescriptorRows(allocator: std.mem.Allocator, io: std.Io, paths: []const []const u8) ![]ProviderRow {
    var rows: std.ArrayList(ProviderRow) = .empty;
    errdefer {
        for (rows.items) |row| {
            allocator.free(row.name);
            allocator.free(row.aggregate_text);
        }
        rows.deinit(allocator);
    }

    for (paths) |path| {
        try appendDescriptorRows(allocator, io, &rows, path);
    }

    return rows.toOwnedSlice(allocator);
}

fn appendDescriptorRows(
    allocator: std.mem.Allocator,
    io: std.Io,
    rows: *std.ArrayList(ProviderRow),
    path: []const u8,
) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(32 * 1024 * 1024));
    defer allocator.free(contents);

    var saw_header = false;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (!saw_header) {
            if (std.mem.eql(u8, line, "zllvm-aggregate-layout-facts-v1")) {
                saw_header = true;
            }
            continue;
        }
        if (line.len == 0 or line[0] == '#') continue;
        if (!std.mem.startsWith(u8, line, "fact ")) break;
        const name = extractQuotedField(line, "nominal=") orelse return error.InvalidAggregateLayoutFactDescriptor;
        const aggregate_text = extractQuotedField(line, "aggregate=") orelse return error.InvalidAggregateLayoutFactDescriptor;
        try rows.append(allocator, .{
            .name = try allocator.dupe(u8, name),
            .aggregate_text = try allocator.dupe(u8, aggregate_text),
        });
    }
    if (!saw_header) return error.MissingAggregateLayoutFactDescriptor;
}

fn readSidecarRows(allocator: std.mem.Allocator, io: std.Io, paths: []const []const u8) ![]ProviderRow {
    var rows: std.ArrayList(ProviderRow) = .empty;
    errdefer {
        for (rows.items) |row| {
            allocator.free(row.name);
            allocator.free(row.aggregate_text);
        }
        rows.deinit(allocator);
    }

    for (paths) |path| {
        try appendSidecarRows(allocator, io, &rows, path);
    }

    return rows.toOwnedSlice(allocator);
}

fn appendSidecarRows(
    allocator: std.mem.Allocator,
    io: std.Io,
    rows: *std.ArrayList(ProviderRow),
    path: []const u8,
) !void {
    const contents = try std.Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(1024 * 1024));
    defer allocator.free(contents);

    var saw_header = false;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        if (!saw_header) {
            if (!std.mem.eql(u8, line, "zllvm-aggregate-layout-facts-v1")) return error.InvalidAggregateLayoutFactSidecar;
            saw_header = true;
            continue;
        }
        if (!std.mem.startsWith(u8, line, "fact ")) return error.InvalidAggregateLayoutFactSidecar;
        const name = extractQuotedField(line, "nominal=") orelse return error.InvalidAggregateLayoutFactSidecar;
        const aggregate_text = extractQuotedField(line, "aggregate=") orelse return error.InvalidAggregateLayoutFactSidecar;
        try rows.append(allocator, .{
            .name = try allocator.dupe(u8, name),
            .aggregate_text = try allocator.dupe(u8, aggregate_text),
        });
    }
    if (!saw_header) return error.InvalidAggregateLayoutFactSidecar;
}

fn freeProviderRows(allocator: std.mem.Allocator, rows: []const ProviderRow) void {
    for (rows) |row| {
        allocator.free(row.name);
        allocator.free(row.aggregate_text);
    }
    allocator.free(rows);
}

fn extractQuotedField(line: []const u8, marker: []const u8) ?[]const u8 {
    const marker_index = std.mem.indexOf(u8, line, marker) orelse return null;
    const after_marker = line[marker_index + marker.len ..];
    const quote_start = std.mem.indexOfScalar(u8, after_marker, '"') orelse return null;
    const after_quote = after_marker[quote_start + 1 ..];
    const quote_end = std.mem.indexOfScalar(u8, after_quote, '"') orelse return null;
    return after_quote[0..quote_end];
}
