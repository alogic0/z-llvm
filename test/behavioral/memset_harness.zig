const std = @import("std");
// Observe the intrinsic trap itself in every harness mode.
pub const std_options: std.Options = .{ .enable_segfault_handler = false };
extern fn family_memset([*]u8, u8, usize) callconv(.c) [*]u8;
extern fn family_checked([*]u8, u8, usize, usize) callconv(.c) [*]u8;
extern fn family_ssp([*]u8, u8, usize, usize) callconv(.c) [*]u8;
extern fn fill_offset([*]u8, u32, usize, usize) callconv(.c) [*]u8;
extern fn fill_pressure([*]u8, u32, usize, u64, u64, u64) callconv(.c) u64;
extern fn fill_constants([*]u8) callconv(.c) [*]u8;
extern fn fill_twice([*]u8, [*]u8, u32, usize) callconv(.c) [*]u8;
extern fn pointer_identity(?[*]u8) callconv(.c) ?[*]u8;
extern fn pointer_null() callconv(.c) ?[*]u8;

fn checkBytes(bytes: []const u8, offset: usize, len: usize, fill: u8) !void {
    for (bytes, 0..) |byte, index| {
        const expected: u8 = if (index >= offset and index < offset + len) fill else 0xa5;
        if (byte != expected) return error.WrongMemory;
    }
}

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next();
    if (args.next()) |which| {
        var bytes: [8]u8 = undefined;
        if (std.mem.eql(u8, which, "checked")) _ = family_checked(&bytes, 42, 9, 8) else if (std.mem.eql(u8, which, "ssp")) _ = family_ssp(&bytes, 42, 9, 8) else return error.UnknownCase;
        return error.MissingTrap;
    }
    var observations: usize = 0;
    var digest: u64 = 0;
    for ([_]usize{ 0, 1, 2, 7, 15, 16, 17, 31, 32, 63, 64, 127 }) |len| {
        for ([_]u8{ 0, 1, 127, 128, 255 }) |fill| {
            for ([_]usize{ 0, 1, 7, 16 }) |offset| {
                var bytes: [192]u8 = undefined;
                const start = 16 + offset;
                const dst = bytes[start..].ptr;
                inline for (0..3) |member| {
                    @memset(&bytes, 0xa5);
                    const result = switch (member) {
                        0 => family_memset(dst, fill, len),
                        1 => family_checked(dst, fill, len, len),
                        2 => family_ssp(dst, fill, len, 176 - offset),
                        else => unreachable,
                    };
                    if (result != dst) return error.WrongPointer;
                    try checkBytes(&bytes, start, len, fill);
                    observations += 1;
                }
                @memset(&bytes, 0xa5);
                if (fill_offset(bytes[16..].ptr, 0xaabbcc00 | @as(u32, fill), len, offset) != dst) return error.WrongPointer;
                try checkBytes(&bytes, start, len, fill);
                observations += 1;
                @memset(&bytes, 0xa5);
                const x: u64 = 0xdeadbeef12345678;
                const y: u64 = 0x7fffffffffffffff;
                const z: u64 = @as(u64, fill) << 48 | len;
                const expected = (((((x +% y) ^ z) +% len) ^ x) +% y) ^ z;
                const result = fill_pressure(dst, fill, len, x, y, z);
                if (result != expected) return error.WrongLiveValue;
                try checkBytes(&bytes, start, len, fill);
                digest +%= result;
                observations += 1;
                @memset(&bytes, 0xa5);
                var other: [192]u8 = @splat(0xa5);
                if (fill_twice(dst, other[start..].ptr, fill, len) != other[start..].ptr) return error.WrongPointer;
                try checkBytes(&bytes, start, len, 42);
                try checkBytes(&other, start, len, fill);
                observations += 1;
            }
        }
    }
    var bytes: [64]u8 = @splat(0xa5);
    if (fill_constants(bytes[3..].ptr) != bytes[3..].ptr) return error.WrongPointer;
    try checkBytes(&bytes, 3, 17, 255);
    if (pointer_identity(&bytes) != &bytes or pointer_identity(null) != null or pointer_null() != null) return error.WrongPointer;
    observations += 2;
    var buffer: [512]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try out.interface.print("memset observations={} digest={x} family_members=3 composition_functions=6\n", .{ observations, digest });
    try out.interface.flush();
}
