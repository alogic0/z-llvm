const std = @import("std");
const ir = @import("ir.zig");

pub fn llvmCompatibleIr(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    const filtered = try stripComparisonNoise(allocator, text);
    defer allocator.free(filtered);

    var module = try ir.Module.parse(allocator, filtered);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    try module.print(&output.writer);
    return try allocator.dupe(u8, output.writer.buffered());
}

pub fn stripComparisonNoise(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw_line| {
        const line = trimRight(raw_line, " \t\r");
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) {
            try output.writer.writeByte('\n');
            continue;
        }
        if (std.mem.startsWith(u8, trimmed, "source_filename = ")) continue;
        if (std.mem.startsWith(u8, trimmed, "target datalayout = ")) continue;
        if (std.mem.startsWith(u8, trimmed, "target triple = ")) continue;

        try writeWithoutSimpleAlign(&output.writer, line);
        try output.writer.writeByte('\n');
    }

    return try allocator.dupe(u8, output.writer.buffered());
}

fn writeWithoutSimpleAlign(writer: anytype, line: []const u8) !void {
    const align_index = std.mem.indexOf(u8, line, ", align ") orelse {
        try writer.writeAll(line);
        return;
    };
    const suffix = line[align_index + ", align ".len ..];
    if (!isDecimal(suffix)) {
        try writer.writeAll(line);
        return;
    }
    try writer.writeAll(line[0..align_index]);
}

fn trimRight(text: []const u8, cutset: []const u8) []const u8 {
    var end = text.len;
    while (end > 0 and std.mem.indexOfScalar(u8, cutset, text[end - 1]) != null) {
        end -= 1;
    }
    return text[0..end];
}

fn isDecimal(text: []const u8) bool {
    if (text.len == 0) return false;
    for (text) |byte| {
        if (byte < '0' or byte > '9') return false;
    }
    return true;
}
