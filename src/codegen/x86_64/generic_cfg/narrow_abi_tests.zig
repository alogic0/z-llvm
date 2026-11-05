const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const verify = @import("../verify.zig");
const selector = @import("../generic_cfg_selector.zig");
const encoding = @import("../../../mc/encoding.zig");
const legalization = @import("narrow_abi.zig");

fn compile(module: ir.Module) ![]align(std.heap.page_size_min) u8 {
    const function = module.functions.items[0];
    var output = machine.MachineFunction.init(function.name, function.ret_ty);
    defer output.deinit(std.testing.allocator);
    const selected = try selector.tryLower(std.testing.allocator, &output, function);
    if (selected == .unsupported) std.debug.print("narrow ABI: {s} {s}\n", .{ selected.unsupported.tagName(), selected.unsupported.detail() });
    try std.testing.expectEqual(selector.SelectionResult.selected, selected);
    try verify.verifyFunction(output);
    const bytes = try encoding.encodeFunction(std.testing.allocator, output);
    defer std.testing.allocator.free(bytes);
    const executable = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(executable[0..bytes.len], bytes);
    return executable;
}

test "narrow ABI entry normalizes dirty register bits at widths one through sixteen" {
    for (1..17) |bits| {
        const text = try std.fmt.allocPrint(std.testing.allocator,
            \\define i64 @narrow_entry(i{d} %input, i64 %take) {{
            \\entry:
            \\  %condition = icmp ne i64 %take, 0
            \\  br i1 %condition, label %yes, label %no
            \\yes:
            \\  %result = zext i{d} %input to i64
            \\  ret i64 %result
            \\no:
            \\  ret i64 55
            \\}}
        , .{ bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const executable = try compile(module);
        defer std.posix.munmap(executable);
        const run: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
        const mask: u64 = (@as(u64, 1) << @intCast(bits)) - 1;
        for ([_]u64{ 0, 1, mask, mask + 1, 0xdeadbeefcafe0000, 0x123456789abcdef0, std.math.maxInt(u64) }) |input| {
            try std.testing.expectEqual(input & mask, run(input, 1));
            try std.testing.expectEqual(@as(u64, 55), run(input, 0));
        }
        try std.testing.expectEqual(bits, module.functions.items[0].params.items[0].ty.int);
        try std.testing.expectEqualStrings("input", module.functions.items[0].params.items[0].name);
    }
}

test "narrow ABI boolean xor branches on the defined low bit" {
    const text =
        \\define i32 @boolean(i1 %input) {
        \\entry:
        \\  %negated = xor i1 %input, 1
        \\  br i1 %negated, label %yes, label %no
        \\yes:
        \\  ret i32 7
        \\no:
        \\  ret i32 11
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (u64) callconv(.c) u32 = @ptrCast(executable.ptr);
    for ([_]u64{ 0, 1, 2, 3, 0xdeadbeefcafe0000, 0xdeadbeefcafe0001, std.math.maxInt(u64) }) |input|
        try std.testing.expectEqual(@as(u32, if (input & 1 == 0) 7 else 11), run(input));
}

test "narrow ABI private carrier copies operands and avoids generated name collisions" {
    const text =
        \\declare fastcc i16 @callee(i3)
        \\define fastcc i16 @caller(i3 %__zllvm_narrow_0) {
        \\__zllvm_narrow_1:
        \\  %__zllvm_narrow_2 = call fastcc i16 @callee(i3 %__zllvm_narrow_0)
        \\  ret i16 %__zllvm_narrow_2
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const original = module.functions.items[0];
    const view = (try legalization.legalize(arena.allocator(), original)).?;
    try std.testing.expectEqualStrings("__zllvm_narrow_3", view.params.items[0].name);
    try std.testing.expectEqual(@as(u16, 32), view.ret_ty.int);
    try std.testing.expectEqual(@as(u16, 16), original.ret_ty.int);
    const call = original.blocks.items[0].instructions.items[0].kind.call;
    try std.testing.expectEqual(@as(u16, 16), call.ret_ty.int);
    try std.testing.expectEqual(@as(u16, 3), call.args.items[0].ty.int);
    try std.testing.expectEqualStrings("__zllvm_narrow_0", call.args.items[0].value.named);
    try std.testing.expect((try legalization.legalize(arena.allocator(), view)) == null);
    try module.verify();
}

test "narrow ABI mixed parameters survive normalization and direct boolean branching" {
    const text =
        \\define i64 @mixed(i1 %flag, i3 %a, i8 %b, i16 %c, i64 %live) {
        \\entry:
        \\  br i1 %flag, label %yes, label %no
        \\yes:
        \\  %aw = zext i3 %a to i32
        \\  %bw = zext i8 %b to i32
        \\  %ab = add i32 %aw, %bw
        \\  %cw = zext i16 %c to i32
        \\  %abc = add i32 %ab, %cw
        \\  %wide = zext i32 %abc to i64
        \\  %result = xor i64 %wide, %live
        \\  ret i64 %result
        \\no:
        \\  ret i64 %live
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    const executable = try compile(module);
    defer std.posix.munmap(executable);
    const run: *const fn (u64, u64, u64, u64, u64) callconv(.c) u64 = @ptrCast(executable.ptr);
    const values = [_]u64{ 0, 1, 0xdeadbeefcafe1234, std.math.maxInt(u64) };
    const live: u64 = 0x123456789abcdef0;
    for (values) |flag| for (values) |a| for (values) |b| for (values) |c| {
        const payload = (a & 7) + (b & 255) + (c & 65535);
        try std.testing.expectEqual(if (flag & 1 == 0) live else live ^ payload, run(flag, a, b, c, live));
    };
}

test "narrow ABI retains unsupported extension call convention and intrinsic boundaries" {
    const calls = [_][]const u8{
        "%result = call signext i8 @callee()",
        "%result = call zeroext i8 @callee()",
        "%result = call coldcc i8 @callee()",
        "%result = musttail call i8 @callee()",
        "%result = call i8 (i32, ...) @callee(i32 1)",
        "%result = call i8 @callee(i8 signext 1)",
        "%result = call i8 @callee(i8 zeroext 1)",
        "%result = call i17 @callee()",
        "%result = call i8 @llvm.unknown.i8()",
    };
    for (calls) |call| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i32 @caller() {{\nentry:\n  {s}\n  ret i32 0\n}}\n", .{call});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        try std.testing.expect((try legalization.legalize(arena.allocator(), module.functions.items[0])) == null);
    }
}
