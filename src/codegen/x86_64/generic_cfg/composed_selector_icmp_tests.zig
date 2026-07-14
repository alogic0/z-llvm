const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_types = @import("selector_types.zig");
const impl = @import("composed_selector_impl.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_icmp = @import("composed_selector_icmp.zig");

const MachineFunction = impl.MachineFunction;
const ComposedBlockSelector = impl.ComposedBlockSelector;
const ValueLoc = selector_types.ValueLoc;

test "generic cfg selector executes signed i16 less-than zero" {
    const input =
        \\define i32 @is_negative(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i16
        \\  %negative = icmp slt i16 %value, 0
        \\  %result = zext i1 %negative to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("is_negative", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const is_negative: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);

    inline for (.{
        .{ @as(u32, 0xffff_8000), @as(u32, 1) },
        .{ @as(u32, 0x1234_ffff), @as(u32, 1) },
        .{ @as(u32, 0xffff_0000), @as(u32, 0) },
        .{ @as(u32, 0xabcd_0001), @as(u32, 0) },
        .{ @as(u32, 0xffff_7fff), @as(u32, 0) },
    }) |case| try std.testing.expectEqual(case[1], is_negative(case[0]));
}

test "generic cfg selector normalizes i6 and i7 before samesign unsigned immediate comparisons" {
    const Case = struct {
        predicate: ir.IcmpPredicate,
        bits: u16,
        imm: i128,
        mask: i32,
    };
    inline for ([_]Case{
        .{ .predicate = .ult, .bits = 6, .imm = 11, .mask = 63 },
        .{ .predicate = .ugt, .bits = 6, .imm = 15, .mask = 63 },
        .{ .predicate = .ult, .bits = 7, .imm = 24, .mask = 127 },
        .{ .predicate = .ugt, .bits = 7, .imm = 53, .mask = 127 },
    }) |case| {
        var machine = MachineFunction.init("samesign-narrow-unsigned-imm", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });

        const diagnostic = try selector_icmp.lowerIcmp(&selector, "cmp", .{
            .predicate = case.predicate,
            .samesign = true,
            .operand_ty = .{ .int = case.bits },
            .lhs = .{ .named = "value" },
            .rhs = .{ .int = case.imm },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_eax = .rdi },
            .{ .and_eax_imm32 = case.mask },
            .{ .cmp_eax_imm32 = @intCast(case.imm) },
            if (case.predicate == .ult) .setb_eax else .seta_eax,
        }, machine.instructions.items);
    }
}

test "generic cfg selector keeps other narrow unsigned comparison forms fail closed" {
    const cases = [_]ir.IcmpInst{
        .{ .predicate = .ult, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .uge, .samesign = true, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ult, .samesign = true, .operand_ty = .{ .int = 5 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ugt, .samesign = true, .operand_ty = .{ .int = 8 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ult, .samesign = true, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 64 } },
        .{ .predicate = .ugt, .samesign = true, .operand_ty = .{ .int = 7 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 128 } },
        .{ .predicate = .ult, .samesign = true, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .named = "rhs" } },
    };

    for (cases) |icmp| {
        var machine = MachineFunction.init("narrow-icmp-near-miss", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

        const diagnostic = (try selector_icmp.lowerIcmp(&selector, "cmp", icmp)).?;
        try std.testing.expect(std.mem.startsWith(u8, diagnostic.detail(), "composed-block-icmp-"));
    }
}

test "generic cfg selector executes normalized i6 and i7 samesign unsigned comparisons" {
    const input =
        \\define i32 @ult_i6_11(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i6
        \\  %comparison = icmp samesign ult i6 %value, 11
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
        \\define i32 @ugt_i6_15(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i6
        \\  %comparison = icmp samesign ugt i6 %value, 15
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
        \\define i32 @ult_i7_24(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i7
        \\  %comparison = icmp samesign ult i7 %value, 24
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
        \\define i32 @ugt_i7_53(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i7
        \\  %comparison = icmp samesign ugt i7 %value, 53
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function_ir, function_index| {
        var machine = MachineFunction.init(function_ir.name, .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const function: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);

        const cases = switch (function_index) {
            0 => [_][2]u32{ .{ 0, 1 }, .{ 10, 1 }, .{ 11, 0 }, .{ 12, 0 }, .{ 0xffff_ffca, 1 } },
            1 => [_][2]u32{ .{ 14, 0 }, .{ 15, 0 }, .{ 16, 1 }, .{ 31, 1 }, .{ 0xffff_ffd0, 1 } },
            2 => [_][2]u32{ .{ 0, 1 }, .{ 23, 1 }, .{ 24, 0 }, .{ 25, 0 }, .{ 0xffff_ff97, 1 } },
            3 => [_][2]u32{ .{ 52, 0 }, .{ 53, 0 }, .{ 54, 1 }, .{ 63, 1 }, .{ 0xffff_ffb6, 1 } },
            else => unreachable,
        };
        for (cases) |case| try std.testing.expectEqual(case[1], function(case[0]));
    }
}
