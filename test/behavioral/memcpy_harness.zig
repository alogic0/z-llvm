const std = @import("std");
pub const std_options: std.Options = .{ .enable_segfault_handler = false };
extern fn family_memcpy_checked([*]u8, [*]const u8, usize, usize) callconv(.c) [*]u8;
extern fn family_memcpy_fast([*]u8, [*]const u8, usize) callconv(.c) [*]u8;
extern fn copy_plain([*]u8, [*]const u8, usize) callconv(.c) [*]u8;
extern fn copy_offset([*]u8, [*]const u8, usize, usize) callconv(.c) [*]u8;
extern fn copy_pressure([*]u8, [*]const u8, usize, u64, u64, u64) callconv(.c) u64;
extern fn copy_twice([*]u8, [*]const u8, [*]u8, usize) callconv(.c) [*]u8;
extern fn copy_byte([*]u8, [*]const u8) callconv(.c) u32;
extern fn copy_vector([*]u8, [*]const u8) callconv(.c) [*]u8;
extern fn copy_alignment([*]const u8) callconv(.c) u64;

fn checkCopy(dst: []const u8, src: []const u8, start: usize, source_start: usize, len: usize) !void {
    for (dst, 0..) |byte, i| {
        const expected: u8 = if (i >= start and i < start + len) src[source_start + i - start] else 0xa5;
        if (byte != expected) return error.WrongMemory;
    }
}

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next();
    if (args.next()) |which| {
        var dst: [8]u8 = @splat(0xa5);
        const src: [8]u8 = @splat(42);
        if (std.mem.eql(u8, which, "checked")) _ = family_memcpy_checked(&dst, &src, 8, 7) else if (std.mem.eql(u8, which, "huge")) _ = family_memcpy_checked(&dst, &src, std.math.maxInt(usize), 8) else return error.UnknownCase;
        return error.MissingTrap;
    }
    var source: [2048]u8 align(16) = undefined;
    for (&source, 0..) |*byte, i| byte.* = @truncate(i * 37 + 131);
    const saved_source = source;
    var observations: usize = 0;
    var digest: u64 = 0;
    const offsets = [_]usize{ 0, 1, 3, 7, 15, 16, 31 };
    for ([_]usize{ 0, 1, 2, 3, 4, 7, 8, 15, 16, 17, 31, 32, 33, 47, 48, 63, 64, 65, 95, 96, 127, 128, 129, 255, 256, 257, 511, 512, 513, 1024 }) |len| {
        for (offsets) |dst_offset| for (offsets) |src_offset| {
            const start = 16 + dst_offset;
            const source_start = 16 + src_offset;
            var bytes: [2048]u8 align(16) = @splat(0xa5);
            const dst = bytes[start..].ptr;
            const src = source[source_start..].ptr;
            if (family_memcpy_checked(dst, src, len, len) != dst) return error.WrongFamilyPointer;
            try checkCopy(&bytes, &source, start, source_start, len);
            observations += 1;
            @memset(&bytes, 0xa5);
            if (family_memcpy_fast(dst, src, len) != dst) return error.WrongFastPointer;
            try checkCopy(&bytes, &source, start, source_start, len);
            observations += 1;
            @memset(&bytes, 0xa5);
            if (copy_plain(dst, src, len) != dst) return error.WrongPlainPointer;
            try checkCopy(&bytes, &source, start, source_start, len);
            observations += 1;
            @memset(&bytes, 0xa5);
            if (copy_offset(dst, src, len, 3) != dst + 3) return error.WrongOffsetPointer;
            try checkCopy(&bytes, &source, start + 3, source_start + 3, len);
            observations += 1;
            @memset(&bytes, 0xa5);
            var other: [2048]u8 align(16) = @splat(0xa5);
            if (copy_twice(dst, src, other[start..].ptr, len) != other[start..].ptr) return error.WrongTwicePointer;
            try checkCopy(&bytes, &source, start, source_start, len);
            try checkCopy(&other, &source, start, source_start, len);
            observations += 1;
            @memset(&bytes, 0xa5);
            const x: u64 = 0xdeadbeef12345678;
            const y: u64 = 0x7fffffffffffffff;
            const z: u64 = src_offset << 48 | len;
            const expected = (((((x +% y) ^ z) +% len) ^ x) +% y) ^ z;
            const result = copy_pressure(dst, src, len, x, y, z);
            if (result != expected) return error.WrongLiveValue;
            for (bytes, 0..) |byte, i| {
                const want: u8 = if (i >= start and i < start + len) source[source_start + i - start] else if (i >= start + len and i < start + len + 16) source[source_start + i - start - len] else 0xa5;
                if (byte != want) return error.WrongLiveVector;
            }
            digest +%= result;
            observations += 1;
        };
    }
    for (offsets) |dst_offset| for (offsets) |src_offset| {
        const start = 16 + dst_offset;
        const source_start = 16 + src_offset;
        var bytes: [2048]u8 align(16) = @splat(0xa5);
        const dst = bytes[start..].ptr;
        const src = source[source_start..].ptr;
        if (copy_byte(dst, src) != src[0]) return error.WrongByte;
        try checkCopy(&bytes, &source, start, source_start, 1);
        @memset(&bytes, 0xa5);
        if (copy_vector(dst, src) != dst) return error.WrongVectorPointer;
        try checkCopy(&bytes, &source, start, source_start, 16);
        if (copy_alignment(src) != (@intFromPtr(src) & 15)) return error.WrongAlignment;
        observations += 3;
    };
    if (!std.mem.eql(u8, &source, &saved_source)) return error.SourceModified;
    if (observations != 8967) return error.WrongObservationCount;
    var buffer: [256]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try out.interface.print("memcpy observations={} digest={x} family_members=2 composition_functions=7\n", .{ observations, digest });
    try out.interface.flush();
}
