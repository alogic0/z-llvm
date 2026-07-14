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

test "generic cfg selector lowers exact named i16 comparisons" {
    inline for (.{ ir.IcmpPredicate.slt, ir.IcmpPredicate.sgt, ir.IcmpPredicate.ne }) |predicate| {
        var machine = MachineFunction.init("named-i16", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

        const diagnostic = try selector_icmp.lowerIcmp(&selector, "cmp", .{
            .predicate = predicate,
            .operand_ty = .{ .int = 16 },
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        });

        try std.testing.expect(diagnostic == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "cmp").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rcx, .src = .rdi } },
            .{ .mov_arg_arg = .{ .dst = .r8, .src = .rsi } },
            .{ .shl_rcx_imm6 = 48 },
            .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 48 } },
            .{ .shl_r8_imm6 = 48 },
            .{ .sar_arg64_imm6 = .{ .reg = .r8, .amount = 48 } },
            .{ .cmp_ecx_arg32 = .r8 },
            switch (predicate) {
                .slt => .setg_eax,
                .sgt => .setl_eax,
                .ne => .setne_eax,
                else => unreachable,
            },
        }, machine.instructions.items);
    }
}

test "generic cfg selector keeps neighboring named integer comparison widths fail closed" {
    inline for (.{ ir.IcmpPredicate.slt, ir.IcmpPredicate.sgt, ir.IcmpPredicate.ne }) |predicate| {
        inline for (.{ 15, 17 }) |bits| {
            var machine = MachineFunction.init("named-i16-near-miss", .{ .int = 1 });
            defer machine.deinit(std.testing.allocator);
            var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
            defer selector.deinit();
            try selector_state.bindValueLoc(&selector, "lhs", .{ .arg32 = .rdi });
            try selector_state.bindValueLoc(&selector, "rhs", .{ .arg32 = .rsi });

            const diagnostic = (try selector_icmp.lowerIcmp(&selector, "cmp", .{
                .predicate = predicate,
                .operand_ty = .{ .int = bits },
                .lhs = .{ .named = "lhs" },
                .rhs = .{ .named = "rhs" },
            })).?;
            try std.testing.expectEqualStrings("composed-block-icmp-form", diagnostic.detail());
        }
    }
}

test "generic cfg selector executes named i16 comparisons over raw half bits" {
    const input =
        \\define i32 @less(i32 %lhs_raw, i32 %rhs_raw) {
        \\entry:
        \\  %lhs = trunc i32 %lhs_raw to i16
        \\  %rhs = trunc i32 %rhs_raw to i16
        \\  %comparison = icmp slt i16 %lhs, %rhs
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\define i32 @greater(i32 %lhs_raw, i32 %rhs_raw) {
        \\entry:
        \\  %lhs = trunc i32 %lhs_raw to i16
        \\  %rhs = trunc i32 %rhs_raw to i16
        \\  %comparison = icmp sgt i16 %lhs, %rhs
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\define i32 @unequal(i32 %lhs_raw, i32 %rhs_raw) {
        \\entry:
        \\  %lhs = trunc i32 %lhs_raw to i16
        \\  %rhs = trunc i32 %rhs_raw to i16
        \\  %comparison = icmp ne i16 %lhs, %rhs
        \\  %result = zext i1 %comparison to i32
        \\  ret i32 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var mappings: [3]?[]align(std.heap.page_size_min) u8 = .{ null, null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (module.functions.items, 0..) |function_ir, index| {
        var machine = MachineFunction.init(function_ir.name, function_ir.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        mappings[index] = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mappings[index].?, bytes);
    }

    const less: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mappings[0].?.ptr);
    const greater: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mappings[1].?.ptr);
    const unequal: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mappings[2].?.ptr);
    const cases = [_]struct {
        lhs: u16,
        rhs: u16,
        less: u32,
        greater: u32,
        unequal: u32,
    }{
        .{ .lhs = 0x0000, .rhs = 0x8000, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0x8000, .rhs = 0x0000, .less = 1, .greater = 0, .unequal = 1 },
        .{ .lhs = 0x0001, .rhs = 0x8001, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0x8001, .rhs = 0x0001, .less = 1, .greater = 0, .unequal = 1 },
        .{ .lhs = 0x3c00, .rhs = 0xbc00, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0xbc00, .rhs = 0x3c00, .less = 1, .greater = 0, .unequal = 1 },
        .{ .lhs = 0x7c00, .rhs = 0xfc00, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0xfc00, .rhs = 0x7c00, .less = 1, .greater = 0, .unequal = 1 },
        .{ .lhs = 0x7e01, .rhs = 0x7d01, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0xfe01, .rhs = 0xfd01, .less = 0, .greater = 1, .unequal = 1 },
        .{ .lhs = 0x7e01, .rhs = 0x7e01, .less = 0, .greater = 0, .unequal = 0 },
        .{ .lhs = 0xfd01, .rhs = 0xfd01, .less = 0, .greater = 0, .unequal = 0 },
    };
    for (cases) |case| {
        try std.testing.expectEqual(case.less, less(case.lhs, case.rhs));
        try std.testing.expectEqual(case.greater, greater(case.lhs, case.rhs));
        try std.testing.expectEqual(case.unequal, unequal(case.lhs, case.rhs));
    }
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
