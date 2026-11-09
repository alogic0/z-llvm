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

test "narrow freeze aliases every 32-bit carrier without mutation or flag writes" {
    const locations = [_]types.ValueLoc{ .{ .arg32 = .rdi }, .{ .scratch32 = .rcx }, .eax, .{ .spill64 = .slot2 } };
    for (1..33) |width| for (locations) |loc| {
        var output = machine.MachineFunction.init("aliases", .{ .int = 32 });
        defer output.deinit(std.testing.allocator);
        var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer current.deinit();
        try state.bindValueLoc(&current, "input", loc);
        const binding = current.values.get("input").?;
        try current.eflags.apply(.definition);
        const flags = current.eflags.snapshot();
        try std.testing.expectEqual(null, try scalar.lowerFreeze(&current, "frozen", .{ .ty = .{ .int = @intCast(width) }, .value = .{ .named = "input" } }));
        try std.testing.expectEqual(binding, current.values.get("input").?);
        try std.testing.expectEqual(loc, current.values.get("frozen").?.loc);
        try std.testing.expectEqual(flags, current.eflags.snapshot());
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), current.next_spill_slot);
    };
}

test "narrow freeze executes dirty upper bits and preserves wider register aliases" {
    for ([_]u16{ 1, 3, 8, 10, 16, 31, 32 }) |bits| for ([_]bool{ false, true }) |accumulator| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "define i64 @identity(i64 %input) {{\nentry:\n" ++
            " %wide = {s}\n %narrow = trunc i64 %wide to i{d}\n" ++
            " %frozen = freeze i{d} %narrow\n %again = freeze i{d} %frozen\n" ++
            " %extended = zext i{d} %again to i64\n %result = xor i64 %wide, %extended\n ret i64 %result\n}}\n", .{ if (accumulator) "add i64 %input, 7" else "freeze i64 %input", bits, bits, bits, bits });
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        var output = machine.MachineFunction.init("identity", .{ .int = 64 });
        defer output.deinit(std.testing.allocator);
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        if (result == .unsupported) std.debug.print("freeze i{d}: {s}\n", .{ bits, result.unsupported.detail() });
        try std.testing.expect(result == .selected);
        const code = try executable(output);
        defer std.posix.munmap(code);
        const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
        const mask = (@as(u64, 1) << @intCast(bits)) - 1;
        for ([_]u64{ 0, 1, 2, 0x123456789abcdef0, 0x8000000080000000, std.math.maxInt(u64) }) |input| {
            const wide = input +% @as(u64, if (accumulator) 7 else 0);
            try std.testing.expectEqual(wide ^ (wide & mask), run(input));
        }
    };
}

test "narrow freeze boolean branches ignore dirty upper bits" {
    const text =
        \\define i64 @branch(i64 %input) {
        \\entry:
        \\ %low = trunc i64 %input to i1
        \\ %flag = freeze i1 %low
        \\ br i1 %flag, label %yes, label %no
        \\yes:
        \\ ret i64 %input
        \\no:
        \\ %other = xor i64 %input, 17
        \\ ret i64 %other
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("branch", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector.SelectionResult.selected, try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]));
    const code = try executable(output);
    defer std.posix.munmap(code);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(code.ptr);
    for ([_]u64{ 0, 1, 2, 3, 0xabcdef0000000000, 0xabcdef0000000001, std.math.maxInt(u64) }) |input|
        try std.testing.expectEqual(if (input & 1 != 0) input else input ^ 17, run(input));
}

test "narrow freeze retains unsupported widths carriers and non-named boundaries" {
    const cases = [_]struct { ty: ir.Type, loc: types.ValueLoc, value: ir.Value = .{ .named = "input" }, detail: []const u8 }{
        .{ .ty = .{ .int = 0 }, .loc = .eax, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 33 }, .loc = .rax, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 63 }, .loc = .rax, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 65 }, .loc = .{ .spill64 = .slot0 }, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 8 }, .loc = .rax, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 64 }, .loc = .eax, .detail = "composed-block-freeze-width" },
        .{ .ty = .{ .int = 8 }, .loc = .{ .stack128_value = 0 }, .detail = "composed-block-freeze-width" },
        .{ .ty = .float, .loc = .eax, .detail = "composed-block-freeze-type" },
        .{ .ty = .{ .int = 8 }, .loc = .eax, .value = .undef, .detail = "composed-block-unknown-freeze" },
        .{ .ty = .{ .int = 8 }, .loc = .eax, .value = .poison, .detail = "composed-block-unknown-freeze" },
        .{ .ty = .{ .int = 8 }, .loc = .eax, .value = .{ .int = 7 }, .detail = "composed-block-unknown-freeze" },
    };
    for (cases) |case| {
        var output = machine.MachineFunction.init("rejected", .{ .int = 32 });
        defer output.deinit(std.testing.allocator);
        var current = state.ComposedBlockSelector.init(std.testing.allocator, &output);
        defer current.deinit();
        try state.bindValueLoc(&current, "input", case.loc);
        const diagnostic = (try scalar.lowerFreeze(&current, "frozen", .{ .ty = case.ty, .value = case.value })).?;
        try std.testing.expectEqualStrings(case.detail, diagnostic.detail());
        try std.testing.expect(current.values.get("frozen") == null);
        try std.testing.expectEqual(@as(usize, 0), output.instructions.items.len);
    }
}

test "narrow freeze late rejection rolls back aliases instructions and owned labels" {
    const text =
        \\declare void @llvm.unimplemented.freeze.test()
        \\define i64 @rejected(i64 %input) {
        \\entry:
        \\ %narrow = trunc i64 %input to i8
        \\ %frozen = freeze i8 %narrow
        \\ %wide = zext i8 %frozen to i64
        \\ br label %body
        \\body:
        \\ call void @llvm.unimplemented.freeze.test()
        \\ ret i64 %wide
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, text);
    defer module.deinit();
    try module.verify();
    var output = machine.MachineFunction.init("original", .{ .int = 64 });
    defer output.deinit(std.testing.allocator);
    try output.instructions.append(std.testing.allocator, .{ .mov_imm_rax = 91 });
    for (0..2) |_| {
        const result = try selector.tryLower(std.testing.allocator, &output, module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqualStrings("composed-block-llvm-intrinsic", result.unsupported.detail());
        try std.testing.expectEqualSlices(machine.Instruction, &.{.{ .mov_imm_rax = 91 }}, output.instructions.items);
        try std.testing.expectEqual(@as(usize, 0), output.owned_labels.items.len);
        try std.testing.expectEqual(machine.SelectionOwner.unassigned, output.selection_owner);
        try std.testing.expectEqualStrings("original", output.name);
    }
}
