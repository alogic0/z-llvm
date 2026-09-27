const std = @import("std");
pub const std_options: std.Options = .{ .enable_segfault_handler = false };
extern fn family_strncpy_checked([*]u8, [*]const u8, usize, usize) callconv(.c) [*]u8;
extern fn family_bcmp([*]const u8, [*]const u8, usize) callconv(.c) i32;
extern fn family_memcmp([*]const u8, [*]const u8, usize) callconv(.c) i32;
extern fn byte_copy_loop([*]u8, [*]const u8, usize) callconv(.c) usize;
extern fn byte_sum_loop([*]const u8, usize, u64) callconv(.c) u64;
extern fn byte_find_zero([*]const u8, usize) callconv(.c) usize;
extern fn byte_fill_loop([*]u8, usize) callconv(.c) void;

fn checkStrncpy(dst: []const u8, src: []const u8, start: usize, len: usize, zero: usize) !void {
    for (dst, 0..) |byte, i| {
        const expected: u8 = if (i < start or i >= start + len) 0xa5 else if (i - start >= zero) 0 else src[i - start];
        if (byte != expected) return error.WrongStrncpyBytes;
    }
}

fn checkComparisons(a: []const u8, b: []const u8, len: usize) !void {
    var expected: i32 = 0;
    for (a[0..len], b[0..len]) |x, y| {
        if (x != y) {
            expected = @as(i32, x) - @as(i32, y);
            break;
        }
    }
    if (family_bcmp(a.ptr, b.ptr, len) != @intFromBool(expected != 0)) return error.WrongBcmp;
    if (family_memcmp(a.ptr, b.ptr, len) != expected) return error.WrongMemcmp;
}

// Put the last readable source byte directly before a protected page. This
// catches reading past the first terminator or beyond an unterminated n bytes.
fn checkGuardPages() !usize {
    const linux = std.os.linux;
    const page = std.heap.pageSize();
    const raw = linux.mmap(null, page * 2, .{ .READ = true, .WRITE = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    if (linux.errno(raw) != .SUCCESS) return error.MapFailed;
    const mapping: [*]u8 = @ptrFromInt(raw);
    defer _ = linux.munmap(mapping, page * 2);
    if (linux.errno(linux.mprotect(mapping + page, page, .{})) != .SUCCESS) return error.ProtectFailed;
    var dst: [160]u8 = @splat(0xa5);
    mapping[page - 1] = 0;
    if (family_strncpy_checked(&dst, mapping + page - 1, 128, 128) != &dst) return error.WrongGuardPointer;
    for (dst[0..128]) |v| if (v != 0) return error.WrongGuardPadding;
    for (dst[128..]) |v| if (v != 0xa5) return error.GuardOverwrite;
    @memset(&dst, 0xa5);
    @memset(mapping[page - 127 .. page], 0xff);
    if (family_strncpy_checked(&dst, mapping + page - 127, 127, 127) != &dst) return error.WrongGuardPointer;
    for (dst[0..127]) |v| if (v != 0xff) return error.WrongGuardCopy;
    for (dst[127..]) |v| if (v != 0xa5) return error.GuardOverwrite;
    if (family_strncpy_checked(&dst, mapping + page, 0, 0) != &dst) return error.WrongZeroPointer;
    if (family_bcmp(mapping + page, mapping + page, 0) != 0 or family_memcmp(mapping + page, mapping + page, 0) != 0) return error.ZeroRead;
    try checkComparisons(mapping[page - 127 .. page], mapping[page - 127 .. page], 127);
    if (byte_find_zero(mapping + page, 0) != 0) return error.ZeroRead;
    return 8;
}

pub fn main(init: std.process.Init) !void {
    var args = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer args.deinit();
    _ = args.next();
    if (args.next()) |which| {
        var dst: [8]u8 = @splat(0xa5);
        const src: [8]u8 = @splat(42);
        if (std.mem.eql(u8, which, "checked")) _ = family_strncpy_checked(&dst, &src, 8, 7) else if (std.mem.eql(u8, which, "huge")) _ = family_strncpy_checked(&dst, &src, std.math.maxInt(usize), 8) else return error.UnknownCase;
        return error.MissingTrap;
    }
    var observations: usize = 0;
    var digest: u64 = 0;
    const lengths = [_]usize{ 0, 1, 2, 3, 7, 8, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 255, 256, 512 };
    const offsets = [_]usize{ 0, 1, 7, 15 };
    for (lengths) |len| for (offsets) |dst_offset| for (offsets) |src_offset| {
        const start = 16 + dst_offset;
        const source_start = 16 + src_offset;
        for ([_]usize{ 0, 1, len / 2, len -| 1, len, len + 1 }) |zero| {
            var source: [1024]u8 = undefined;
            for (&source, 0..) |*v, i| v.* = @intCast(1 + (i * 37 + 130) % 255);
            source[source_start + zero] = 0;
            const original = source;
            const src = source[source_start..];
            var dst: [1024]u8 = @splat(0xa5);
            for ([_]usize{ len, len + 17 }) |capacity| {
                if (family_strncpy_checked(dst[start..].ptr, src.ptr, len, capacity) != dst[start..].ptr) return error.WrongPointer;
                try checkStrncpy(&dst, src, start, len, zero);
                @memset(&dst, 0xa5);
                observations += 1;
            }
            if (byte_copy_loop(dst[start..].ptr, src.ptr, len) != len) return error.WrongCopyCount;
            for (dst, 0..) |v, i| {
                const expected: u8 = if (i >= start and i < start + len) src[i - start] else 0xa5;
                if (v != expected) return error.WrongCopy;
            }
            const seed: u64 = 0xffffffffffffff00;
            var sum = seed;
            for (src[0..len]) |v| sum +%= v;
            const actual = byte_sum_loop(src.ptr, len, seed);
            if (actual != sum) return error.WrongSum;
            digest +%= actual;
            if (byte_find_zero(src.ptr, len) != @min(len, zero)) return error.WrongEarlyExit;
            @memset(&dst, 0xa5);
            byte_fill_loop(dst[start..].ptr, len);
            for (dst, 0..) |v, i| {
                const expected: u8 = if (i >= start and i < start + len) 231 else 0xa5;
                if (v != expected) return error.WrongFill;
            }
            if (!std.mem.eql(u8, &source, &original)) return error.SourceModified;
            observations += 4;
        }
        var a: [1024]u8 = @splat(0x80);
        var b: [1024]u8 = @splat(0x80);
        const aa = a[source_start..];
        const bb = b[start..];
        try checkComparisons(aa, bb, len);
        observations += 2;
        for ([_]usize{ 0, len / 2, len -| 1, len }) |position| {
            for ([_]u8{ 0, 0x7f, 0x81, 0xff }) |value| {
                bb[position] = value;
                try checkComparisons(aa, bb, len);
                try checkComparisons(bb, aa, len);
                bb[position] = 0x80;
                observations += 4;
            }
        }
    };
    observations += try checkGuardPages();
    if (observations != 32648) return error.WrongObservationCount;
    var buffer: [256]u8 = undefined;
    var out = std.Io.File.stdout().writer(init.io, &buffer);
    try out.interface.print("byte-loops observations={} digest={x} family_members=3 composition_functions=4\n", .{ observations, digest });
    try out.interface.flush();
}
