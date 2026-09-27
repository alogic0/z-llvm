const std = @import("std");
extern fn probe(i32, i32) callconv(.c) i32;

pub fn main(init: std.process.Init) !void {
    const edges = [_]i32{ std.math.minInt(i32), -1025, -257, -17, -9, -1, 0, 1, 7, 8, 17, 255, std.math.maxInt(i32) };
    var inputs: [272][2]i32 = undefined;
    var index: usize = 0;
    for (edges) |x| for (0..16) |y| {
        inputs[index] = .{ x, @intCast(y) };
        index += 1;
    };
    var seed: u32 = 0x5eed1234;
    for (inputs[208..]) |*input| {
        seed = seed *% 1664525 +% 1013904223;
        input.* = .{ @bitCast(seed), @intCast((seed >> 16) & 15) };
    }
    var digest: u64 = 0;
    // Separate object linking, without LTO, keeps every external call observable.
    for (0..131072) |_| for (inputs) |input| {
        digest +%= @as(u32, @bitCast(probe(input[0], input[1])));
    };
    var buffer: [128]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try out.interface.print("calls=35651584 digest={x}\n", .{digest});
    try out.interface.flush();
}
