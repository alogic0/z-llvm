const std = @import("std");
const ir = @import("ir.zig");

pub fn llvmCompatibleIr(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var module = try ir.Module.parse(allocator, text);
    defer module.deinit();
    try module.verify();

    var output: std.Io.Writer.Allocating = .init(allocator);
    defer output.deinit();

    try module.print(&output.writer);
    return try allocator.dupe(u8, output.writer.buffered());
}
