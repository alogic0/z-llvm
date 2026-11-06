const std = @import("std");
const ir = @import("../ir.zig");
const compilation = @import("../compilation.zig");

test "compilation preparation makes optimization explicit and honors pass limits" {
    const source =
        \\define i32 @answer() {
        \\entry:
        \\ %v = add i32 40, 2
        \\ ret i32 %v
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var diagnostic = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer diagnostic.deinit();
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{});
    try std.testing.expectEqual(@as(usize, 1), module.functions.items[0].blocks.items[0].instructions.items.len);
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{
        .optimization = "instcombine,dce",
        .passes = .{ .pass_limit = 0 },
    });
    try std.testing.expectEqual(@as(usize, 1), module.functions.items[0].blocks.items[0].instructions.items.len);
    try compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{
        .optimization = "instcombine,dce",
        .passes = .{ .trace = true },
    });
    try std.testing.expectEqual(@as(i128, 42), module.functions.items[0].blocks.items[0].terminator.?.ret.value.?.int);
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.written(), "; before instcombine") != null);
    try std.testing.expectError(error.UnknownPass, compilation.prepare(std.testing.allocator, null, &module, &diagnostic.writer, .{ .optimization = "not-a-pass" }));
}
