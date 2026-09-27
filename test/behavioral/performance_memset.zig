const std = @import("std");
extern fn family_memset([*]u8, u8, usize) callconv(.c) [*]u8;
extern fn family_checked([*]u8, u8, usize, usize) callconv(.c) [*]u8;
extern fn family_ssp([*]u8, u8, usize, usize) callconv(.c) [*]u8;
extern fn fill_offset([*]u8, u32, usize, usize) callconv(.c) [*]u8;
extern fn fill_pressure([*]u8, u32, usize, u64, u64, u64) callconv(.c) u64;
extern fn fill_constants([*]u8) callconv(.c) [*]u8;
extern fn fill_twice([*]u8, [*]u8, u32, usize) callconv(.c) [*]u8;
extern fn pointer_identity(?[*]u8) callconv(.c) ?[*]u8;
extern fn pointer_null() callconv(.c) ?[*]u8;

pub fn main(init: std.process.Init) !void {
    var bytes: [192]u8 = @splat(0xa5);
    var other: [192]u8 = @splat(0xa5);
    var digest: u64 = 0;
    for (0..4096) |_| {
        for ([_]usize{ 0, 1, 2, 7, 15, 16, 17, 31, 32, 63, 64, 127 }) |len| {
            for ([_]u8{ 0, 1, 127, 128, 255 }) |fill| {
                for ([_]usize{ 0, 1, 7, 16 }) |offset| {
                    const start = 16 + offset;
                    const dst = bytes[start..].ptr;
                    if (family_memset(dst, fill, len) != dst) return error.WrongPointer;
                    if (family_checked(dst, fill, len, len) != dst) return error.WrongPointer;
                    if (family_ssp(dst, fill, len, 176 - offset) != dst) return error.WrongPointer;
                    if (fill_offset(bytes[16..].ptr, 0xaabbcc00 | @as(u32, fill), len, offset) != dst) return error.WrongPointer;
                    digest +%= fill_pressure(dst, fill, len, 0xdeadbeef12345678, 0x7fffffffffffffff, @as(u64, fill) << 48 | len);
                    if (fill_twice(dst, other[start..].ptr, fill, len) != other[start..].ptr) return error.WrongPointer;
                    // Observe the fill buffers without timing the full semantic oracle.
                    digest +%= bytes[start] + @as(u64, other[start]);
                }
            }
        }
        if (fill_constants(bytes[3..].ptr) != bytes[3..].ptr) return error.WrongPointer;
        if (pointer_identity(&bytes) != &bytes or pointer_identity(null) != null or pointer_null() != null) return error.WrongPointer;
        digest +%= bytes[3];
    }
    var buffer: [128]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try out.interface.print("rounds=4096 calls=5914624 digest={x}\n", .{digest});
    try out.interface.flush();
}
