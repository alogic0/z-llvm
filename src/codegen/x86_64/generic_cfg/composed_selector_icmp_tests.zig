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

test "generic cfg selector normalizes i6 before samesign unsigned immediate comparison" {
    var machine = MachineFunction.init("samesign-ult-i6-imm", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rdi });

    const diagnostic = try selector_icmp.lowerIcmp(&selector, "cmp", .{
        .predicate = .ult,
        .samesign = true,
        .operand_ty = .{ .int = 6 },
        .lhs = .{ .named = "value" },
        .rhs = .{ .int = 24 },
    });

    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_eax = .rdi },
        .{ .and_eax_imm32 = 63 },
        .{ .cmp_eax_imm32 = 24 },
        .setb_eax,
    }, machine.instructions.items);
}

test "generic cfg selector keeps other narrow unsigned comparison forms fail closed" {
    const cases = [_]ir.IcmpInst{
        .{ .predicate = .ult, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ugt, .samesign = true, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ult, .samesign = true, .operand_ty = .{ .int = 7 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 24 } },
        .{ .predicate = .ult, .samesign = true, .operand_ty = .{ .int = 6 }, .lhs = .{ .named = "value" }, .rhs = .{ .int = 64 } },
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

test "generic cfg selector executes normalized i6 samesign unsigned comparisons" {
    const input =
        \\define i32 @compare_positive(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i6
        \\  %comparison = icmp samesign ult i6 %value, 24
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
        \\define i32 @compare_negative(i32 %raw) {
        \\entry:
        \\  %value = trunc i32 %raw to i6
        \\  %comparison = icmp samesign ult i6 %value, 63
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

        if (function_index == 0) {
            for ([_]struct { input: u32, expected: u32 }{
                .{ .input = 0, .expected = 1 },
                .{ .input = 23, .expected = 1 },
                .{ .input = 24, .expected = 0 },
                .{ .input = 25, .expected = 0 },
                .{ .input = 0xffff_ffd7, .expected = 1 },
            }) |case| try std.testing.expectEqual(case.expected, function(case.input));
        } else {
            for ([_]struct { input: u32, expected: u32 }{
                .{ .input = 62, .expected = 1 },
                .{ .input = 63, .expected = 0 },
                .{ .input = 0xffff_ffff, .expected = 0 },
            }) |case| try std.testing.expectEqual(case.expected, function(case.input));
        }
    }
}
