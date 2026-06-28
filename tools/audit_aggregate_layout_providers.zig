const std = @import("std");

const generated_examples = [_][]const u8{};

const ProviderRow = struct {
    name: []const u8,
    aggregate_text: []const u8,
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

    const fact_rows = try readProviderRows(allocator, io, "src/zig_air_aggregate_layout_facts.zig");
    defer freeProviderRows(allocator, fact_rows);
    const boundary_rows = try readProviderRows(allocator, io, "src/zig_air_aggregate_layout_boundaries.zig");
    defer freeProviderRows(allocator, boundary_rows);
    const exported_rows = try readSidecarRows(allocator, io, &exported_sidecar_paths);
    defer freeProviderRows(allocator, exported_rows);

    try stdout.print(
        "summary aggregate-layout-provider-audit exported_facts={d} static_source_facts={d} boundary_provider={d} generated_examples={d}\n",
        .{ exported_rows.len, fact_rows.len, boundary_rows.len, generated_examples.len },
    );

    for (exported_rows) |row| {
        try stdout.print(
            "layout provider=exported_aggregate_facts name={s} aggregate={s}\n",
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
