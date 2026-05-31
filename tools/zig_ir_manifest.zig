const std = @import("std");

pub const expected_fields = 14;
pub const default_path = "docs/fixtures/zig_ir/manifest.tsv";

pub const Row = struct {
    line_no: usize,
    fields: [expected_fields][]const u8,

    pub fn id(row: Row) []const u8 {
        return row.fields[0];
    }

    pub fn group(row: Row) []const u8 {
        return row.fields[1];
    }

    pub fn sourcePath(row: Row) []const u8 {
        return row.fields[2];
    }

    pub fn optimizeMode(row: Row) []const u8 {
        return row.fields[7];
    }

    pub fn rawIrPath(row: Row) []const u8 {
        return row.fields[9];
    }

    pub fn checkedIrPath(row: Row) []const u8 {
        return row.fields[10];
    }

    pub fn classification(row: Row) []const u8 {
        return row.fields[11];
    }

    pub fn inventoryLinks(row: Row) []const u8 {
        return row.fields[12];
    }

    pub fn hasClassification(row: Row, needle: []const u8) bool {
        return hasToken(row.classification(), ',', needle);
    }

    pub fn metadataValue(row: Row, key: []const u8) ?[]const u8 {
        var rest = row.inventoryLinks();
        while (true) {
            const token = if (std.mem.indexOfScalar(u8, rest, ';')) |split| token: {
                const value = rest[0..split];
                rest = rest[split + 1 ..];
                break :token value;
            } else rest;

            if (std.mem.startsWith(u8, token, key) and token.len > key.len and token[key.len] == '=') {
                return token[key.len + 1 ..];
            }

            if (token.ptr == rest.ptr and token.len == rest.len) return null;
        }
    }
};

pub const Manifest = struct {
    path: []const u8,
    contents: []u8,
    rows: []Row,

    pub fn deinit(manifest: *Manifest, allocator: std.mem.Allocator) void {
        allocator.free(manifest.rows);
        allocator.free(manifest.contents);
    }
};

pub const LoadError = error{
    InvalidFieldCount,
} || std.mem.Allocator.Error || std.Io.Dir.ReadFileAllocError;

pub fn load(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    max_bytes: usize,
) LoadError!Manifest {
    var cwd = std.Io.Dir.cwd();
    const contents = try cwd.readFileAlloc(io, path, allocator, .limited(max_bytes));
    errdefer allocator.free(contents);

    var rows: std.ArrayList(Row) = .empty;
    errdefer rows.deinit(allocator);

    var line_no: usize = 0;
    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |raw_line| {
        line_no += 1;
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        if (fieldCount(line) != expected_fields) return error.InvalidFieldCount;
        const fields = splitTsvLine(line);
        if (fields[0].len == 0) continue;
        try rows.append(allocator, .{ .line_no = line_no, .fields = fields });
    }

    return .{
        .path = path,
        .contents = contents,
        .rows = try rows.toOwnedSlice(allocator),
    };
}

pub fn fieldCount(line: []const u8) usize {
    var count: usize = 1;
    for (line) |byte| {
        if (byte == '\t') count += 1;
    }
    return count;
}

pub fn splitTsvLine(line: []const u8) [expected_fields][]const u8 {
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

pub fn hasToken(list: []const u8, delimiter: u8, needle: []const u8) bool {
    var rest = list;
    while (true) {
        if (std.mem.indexOfScalar(u8, rest, delimiter)) |split| {
            if (std.mem.eql(u8, rest[0..split], needle)) return true;
            rest = rest[split + 1 ..];
        } else {
            return std.mem.eql(u8, rest, needle);
        }
    }
}

pub fn fileExists(io: std.Io, path: []const u8) !bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => return err,
    };
    return true;
}
