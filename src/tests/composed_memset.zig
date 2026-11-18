const std = @import("std");
const ir = @import("../ir.zig");
const impl = @import("../codegen/x86_64/generic_cfg/composed_selector_impl.zig");
const verify = @import("../codegen/x86_64/verify.zig");
const encoding = @import("../mc/encoding.zig");

fn check(source: []const u8, expected: ?[]const u8) !void {
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const function = module.functions.items[0];
    var machine = impl.MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    const result = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
    if (expected) |detail| {
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqualStrings(detail, result.unsupported.detail());
    } else {
        try std.testing.expect(result == .selected);
        try verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(bytes.len > 0);
    }
}

test "composed memset accepts named byte fill and pointer return" {
    try check(
        \\define ptr @fill(ptr %p, i8 zeroext %v, i64 %n) {
        \\entry:
        \\ call void @llvm.memset.p0.i64(ptr align 1 %p, i8 %v, i64 %n, i1 false)
        \\ ret ptr %p
        \\}
    , null);
}

test "composed memset bounds unaligned word stores to ordinary dynamic lengths" {
    const a = std.testing.allocator;
    const cases = [_]struct { intrinsic: []const u8, length: []const u8, dynamic: bool }{
        .{ .intrinsic = "llvm.memset.p0.i64", .length = "%n", .dynamic = true },
        .{ .intrinsic = "llvm.memset.p0.i64", .length = "8", .dynamic = false },
        .{ .intrinsic = "llvm.memset.inline.p0.i64", .length = "8", .dynamic = false },
    };
    for (cases) |case| {
        const source = try std.fmt.allocPrint(a,
            \\define ptr @fill(ptr %p, i32 %v, i64 %n) {{
            \\entry:
            \\  %byte = trunc i32 %v to i8
            \\  call void @{s}(ptr align 1 %p, i8 %byte, i64 {s}, i1 false)
            \\  ret ptr %p
            \\}}
        , .{ case.intrinsic, case.length });
        defer a.free(source);
        var module = try ir.Module.parse(a, source);
        defer module.deinit();
        const function = module.functions.items[0];
        var machine = impl.MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(a);
        try std.testing.expect(try impl.tryLowerComposedCfg(a, &machine, function) == .selected);
        var fills: usize = 0;
        for (machine.instructions.items) |inst| {
            if (inst != .memset_rdi_sil_rdx_rax) continue;
            fills += 1;
            try std.testing.expectEqual(case.dynamic, inst.memset_rdi_sil_rdx_rax == .bounded_8_to_16);
        }
        try std.testing.expectEqual(@as(usize, 1), fills);
        const bytes = try encoding.encodeFunction(a, machine);
        defer a.free(bytes);
        if (@import("builtin").target.cpu.arch != .x86_64 or @import("builtin").os.tag != .linux) continue;
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const fill: *const fn ([*]u8, u32, usize) callconv(.c) [*]u8 = @ptrCast(mapping.ptr);
        for (0..34) |length| {
            for ([_]u32{ 0xcafe0000, 0xdead0080, 0xbeef00ff }) |value| {
                var actual: [48]u8 = @splat(0xa5);
                var expected = actual;
                const dst = actual[7..].ptr;
                @memset(expected[7..][0..if (case.dynamic) length else 8], @truncate(value));
                try std.testing.expect(fill(dst, value, length) == dst);
                try std.testing.expectEqualSlices(u8, &expected, &actual);
            }
        }
    }
}

test "composed memset accepts immediate byte and zero length" {
    try check(
        \\define ptr @fill(ptr %p) {
        \\entry:
        \\ call void @llvm.memset.p0.i64(ptr %p, i8 -1, i64 0, i1 false)
        \\ ret ptr %p
        \\}
    , null);
}

test "composed memset rejects volatile and neighboring intrinsic signatures" {
    const variants = [_]struct { call: []const u8, detail: []const u8 }{
        .{ .call = "call void @llvm.memset.p0.i64(ptr %p, i8 0, i64 1, i1 true)", .detail = "composed-block-memset-args" },
        .{ .call = "call void @llvm.memset.p0.i64(ptr %p, i8 0, i64 %n, i1 true)", .detail = "composed-block-memset-args" },
        .{ .call = "call void @llvm.memset.inline.p0.i64(ptr %p, i8 0, i64 %n, i1 false)", .detail = "composed-block-memset-inline-length" },
        .{ .call = "call void @llvm.memset.p0.i64(ptr %p, i32 0, i64 1, i1 false)", .detail = "composed-block-memset-args" },
        .{ .call = "call void @llvm.memset.p0.i32(ptr %p, i8 0, i32 1, i1 false)", .detail = "composed-block-llvm-intrinsic" },
        .{ .call = "call void @llvm.memset.p1.i64(ptr addrspace(1) %p, i8 0, i64 1, i1 false)", .detail = "composed-block-llvm-intrinsic" },
        .{ .call = "musttail call void @llvm.memset.p0.i64(ptr %p, i8 0, i64 1, i1 false)", .detail = "composed-block-memset-tail-kind" },
        .{ .call = "call void @llvm.memset.p0.i64(ptr %p, i8 poison, i64 1, i1 false)", .detail = "composed-block-memset-value" },
    };
    for (variants) |variant| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define ptr @fill(ptr %p, i64 %n) {{\nentry:\n {s}\n ret ptr %p\n}}\n", .{variant.call});
        defer std.testing.allocator.free(text);
        try check(text, variant.detail);
    }
}

test "composed memset rejects i8 entry without zero extension" {
    try check(
        \\define ptr @fill(ptr %p, i8 %v, i64 %n) {
        \\entry:
        \\ call void @llvm.memset.p0.i64(ptr %p, i8 %v, i64 %n, i1 false)
        \\ ret ptr %p
        \\}
    , "composed-block-param-i8-extension");
}

test "composed memset pointer returns include null and reject poison" {
    try check("define ptr @null_ptr() {\nentry:\n ret ptr null\n}\n", null);
    try check("define ptr @bad_ptr() {\nentry:\n ret ptr poison\n}\n", "composed-block-pointer-ret-value");
}

test "composed memset repeated fills preserve both pointers" {
    try check(
        \\define ptr @fill_twice(ptr %dst, ptr %other, i32 %value, i64 %len) {
        \\entry:
        \\  %byte = trunc i32 %value to i8
        \\  call void @llvm.memset.p0.i64(ptr %other, i8 %byte, i64 %len, i1 false)
        \\  call void @llvm.memset.p0.i64(ptr %dst, i8 42, i64 %len, i1 false)
        \\  ret ptr %other
        \\}
    , null);
}

test "composed memset reserves staging for an accumulator dying at a void fill" {
    try check(
        \\define void @fill(ptr %p, i32 %v, i64 %n) {
        \\entry:
        \\ %byte = trunc i32 %v to i8
        \\ call void @llvm.memset.p0.i64(ptr %p, i8 %byte, i64 %n, i1 false)
        \\ ret void
        \\}
    , null);
}

test "composed memset pointer returns reject nondefault address spaces" {
    try check(
        \\define ptr addrspace(270) @return_other_space(ptr addrspace(270) %p) {
        \\entry:
        \\ ret ptr addrspace(270) %p
        \\}
    , "composed-block-pointer-ret-addrspace");
}
