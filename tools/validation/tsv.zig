//! Quoted TSV compatible with csv.DictReader/DictWriter (newline terminator).
const std = @import("std");
const u = @import("common.zig");
pub const Table = struct { header: []const []const u8, rows: []const []const []const u8 };

pub fn parse(a: std.mem.Allocator, data: []const u8) !Table {
    var rows: std.ArrayList([]const []const u8) = .empty;
    var cells: std.ArrayList([]const u8) = .empty;
    var offset: usize = 0;
    while (offset < data.len) {
        var cell: std.Io.Writer.Allocating = .init(a);
        if (data[offset] == '"') {
            offset += 1;
            while (true) {
                if (offset == data.len) return error.UnterminatedQuotedField;
                const ch = data[offset];
                offset += 1;
                if (ch != '"') {
                    try cell.writer.writeByte(ch);
                    continue;
                }
                if (offset < data.len and data[offset] == '"') {
                    offset += 1;
                    try cell.writer.writeByte('"');
                    continue;
                }
                break;
            }
            if (offset < data.len and !u.contains(&.{ "\t", "\n", "\r" }, data[offset .. offset + 1])) return error.TrailingQuotedFieldData;
        } else {
            const start = offset;
            while (offset < data.len and data[offset] != '\t' and data[offset] != '\n' and data[offset] != '\r') : (offset += 1) {}
            try cell.writer.writeAll(data[start..offset]);
        }
        try cells.append(a, try a.dupe(u8, cell.written()));
        cell.deinit();
        if (offset < data.len and data[offset] == '\t') {
            offset += 1;
            if (offset == data.len) try cells.append(a, "") else continue;
        } else if (offset < data.len) {
            const ch = data[offset];
            offset += 1;
            if (ch == '\r' and offset < data.len and data[offset] == '\n') offset += 1;
        }
        if (cells.items.len != 1 or cells.items[0].len != 0) try rows.append(a, try cells.toOwnedSlice(a)) else cells.clearRetainingCapacity();
    }
    if (rows.items.len == 0) return error.EmptyTable;
    const header = rows.items[0];
    var keys = std.StringHashMap(void).init(a);
    for (header) |key| {
        if (key.len == 0 or keys.contains(key)) return error.InvalidTableHeader;
        try keys.put(key, {});
    }
    for (rows.items[1..]) |record| if (record.len != header.len) return error.InvalidTableWidth;
    return .{ .header = header, .rows = rows.items[1..] };
}
pub fn column(table: Table, key: []const u8) !usize {
    for (table.header, 0..) |name, i| if (std.mem.eql(u8, name, key)) return i;
    return error.MissingTableColumn;
}
pub fn field(writer: *std.Io.Writer, text: []const u8) !void {
    // Python's lineterminator is '\n'; a lone '\r' does not trigger quoting.
    const quoted = std.mem.indexOfAny(u8, text, "\t\n\"") != null;
    if (quoted) try writer.writeByte('"');
    for (text) |ch| {
        if (ch == '"') try writer.writeByte('"');
        try writer.writeByte(ch);
    }
    if (quoted) try writer.writeByte('"');
}
pub fn row(writer: *std.Io.Writer, cells: []const []const u8) !void {
    for (cells, 0..) |cell, i| {
        if (i > 0) try writer.writeByte('\t');
        try field(writer, cell);
    }
    try writer.writeByte('\n');
}
