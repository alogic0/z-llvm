const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const selector = @import("../generic_cfg_selector.zig");
const state = @import("composed_selector_state.zig");
const scalar = @import("composed_selector_scalar.zig");
const types = @import("selector_types.zig");
const verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");

fn executable(function: machine.MachineFunction) ![]align(std.heap.page_size_min) u8 {
    try verify.verifyFunction(function);
    const bytes = try encoding.encodeFunction(std.testing.allocator, function);
    defer std.testing.allocator.free(bytes);
    const code = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    @memcpy(code[0..bytes.len], bytes);
    return code;
}

test "pointer freeze retains scalar locations flags and original bindings" {
    for ([_]types.ValueLoc{ .{ .arg64 = .rdi }, .{ .scratch64 = .rcx }, .rax, .{ .spill64 = .slot2 } }) |loc| {
        var output = machine.MachineFunction.init("pointer-alias", .ptr);
        defer output.deinit(std.testing.allocator);
        var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer current.deinit();
        try state.bindValueLoc(&current, "input", loc);
        const original = current.values.get("input").?;
        try current.eflags.apply(.definition);
        const flags = current.eflags.snapshot();
        try std.testing.expectEqual(null, try scalar.lowerFreeze(&current, "alias", .{ .ty = .ptr, .value = .{ .named = "input" } }));
        try std.testing.expectEqual(original, current.values.get("input").?);
        try std.testing.expectEqual(loc, current.values.get("alias").?.loc);
        try std.testing.expectEqual(flags, current.eflags.snapshot());
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), current.next_spill_slot);
    }
}

test "pointer freeze returns exact pointer bits including null" {
    const text =
        \\define ptr @identity(ptr %input) {
        \\entry:
        \\ %first = freeze ptr %input
        \\ %second = freeze ptr %first
        \\ ret ptr %second
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("identity", .ptr);
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
    const code = try executable(output);
    defer std.posix.munmap(code);
    const run: *const fn (?*const u64) callconv(.c) ?*const u64 = @ptrCast(code.ptr);
    var words = [_]u64{ 0, 0xfedcba9876543210 };
    for ([_]?*const u64{ null, &words[0], &words[1] }) |input| try std.testing.expectEqual(input, run(input));
}

test "pointer freeze preserves stack scalar and derived array addresses" {
    const sources = [_][]const u8{
        \\define i64 @stack(i32 %input) {
        \\entry:
        \\ %slot = alloca i32, align 4
        \\ store i32 %input, ptr %slot, align 4
        \\ %frozen = freeze ptr %slot
        \\ %loaded = load i32, ptr %frozen, align 4
        \\ %result = zext i32 %loaded to i64
        \\ ret i64 %result
        \\}
        ,
        \\define i64 @stack(i32 %input) {
        \\entry:
        \\ %array = alloca [4 x i32], align 16
        \\ %slot = getelementptr [4 x i32], ptr %array, i64 0, i64 2
        \\ store i32 %input, ptr %slot, align 4
        \\ %frozen = freeze ptr %slot
        \\ %loaded = load i32, ptr %frozen, align 4
        \\ %result = zext i32 %loaded to i64
        \\ ret i64 %result
        \\}
        ,
    };
    for (sources) |text| {
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("stack", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (result == .unsupported) std.debug.print("pointer freeze stack: {s}\n", .{result.unsupported.detail()});
        try std.testing.expect(result == .selected);
        const code = try executable(output);
        defer std.posix.munmap(code);
        const run: *const fn (u32) callconv(.c) u64 = @ptrCast(code.ptr);
        for ([_]u32{ 0, 1, 0x80000000, std.math.maxInt(u32) }) |input| try std.testing.expectEqual(@as(u64, input), run(input));
    }
}

test "pointer freeze rejects incompatible and unresolved locations without mutation" {
    for ([_]types.ValueLoc{ .eax, .{ .arg32 = .rdi }, .{ .stack128_value = 0 } }) |loc| {
        var output = machine.MachineFunction.init("rejected", .ptr);
        defer output.deinit(std.testing.allocator);
        var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer current.deinit();
        try state.bindValueLoc(&current, "input", loc);
        try std.testing.expectEqualStrings("composed-block-freeze-loc", (try scalar.lowerFreeze(&current, "frozen", .{ .ty = .ptr, .value = .{ .named = "input" } })).?.detail());
        for ([_]ir.Value{ .undef, .poison, .null_value }) |value|
            try std.testing.expectEqualStrings("composed-block-unknown-freeze", (try scalar.lowerFreeze(&current, "frozen", .{ .ty = .ptr, .value = value })).?.detail());
        try std.testing.expect(current.values.get("frozen") == null);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}
