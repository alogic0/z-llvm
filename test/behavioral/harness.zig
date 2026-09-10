const std = @import("std");
extern fn probe(i32, i32) callconv(.c) i32;
pub fn main(init: std.process.Init) !void {
    var buffer: [4096]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    // Fixed seed and explicit boundary values. y bounds the loop to 0..15.
    const edges = [_]i32{ std.math.minInt(i32), -1025, -257, -17, -9, -1, 0, 1, 7, 8, 17, 255, std.math.maxInt(i32) };
    for (edges) |x| for (0..16) |y| try out.interface.print("{}\n", .{probe(x, @intCast(y))});
    var seed: u32 = 0x5eed1234;
    for (0..64) |_| {
        seed = seed *% 1664525 +% 1013904223;
        try out.interface.print("{}\n", .{probe(@bitCast(seed), @intCast((seed >> 16) & 15))});
    }
    try out.interface.flush();
}
