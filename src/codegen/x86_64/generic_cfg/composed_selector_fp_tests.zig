const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_impl = @import("composed_selector_impl.zig");
const selector_calls = @import("composed_selector_calls.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_fp = @import("composed_selector_fp.zig");
const state_data = @import("composed_selector_state_data.zig");
const stage2_planning = @import("stage2_planning.zig");

const scalar_fcmp_predicates = [_]ir.FcmpPredicate{
    .false, .oeq, .ogt, .oge, .olt, .ole, .one, .ord,
    .uno,   .ueq, .ugt, .uge, .ult, .ule, .une, .true,
};

fn expectedFcmp(predicate: ir.FcmpPredicate, lhs: anytype, rhs: @TypeOf(lhs)) bool {
    const unordered = std.math.isNan(lhs) or std.math.isNan(rhs);
    return switch (predicate) {
        .false => false,
        .oeq => !unordered and lhs == rhs,
        .ogt => !unordered and lhs > rhs,
        .oge => !unordered and lhs >= rhs,
        .olt => !unordered and lhs < rhs,
        .ole => !unordered and lhs <= rhs,
        .one => !unordered and lhs != rhs,
        .ord => !unordered,
        .uno => unordered,
        .ueq => unordered or lhs == rhs,
        .ugt => unordered or lhs > rhs,
        .uge => unordered or lhs >= rhs,
        .ult => unordered or lhs < rhs,
        .ule => unordered or lhs <= rhs,
        .une => unordered or lhs != rhs,
        .true => true,
    };
}

fn extendHalfForFcmpTest(value: f16) callconv(.c) f32 {
    return value;
}

fn truncateFloatForFaddTest(value: f32) callconv(.c) f16 {
    return @floatCast(value);
}

fn writeAbsoluteJump(stub: []u8, target: usize) void {
    stub[0] = 0x48;
    stub[1] = 0xb8;
    std.mem.writeInt(u64, stub[2..10], target, .little);
    stub[10] = 0xff;
    stub[11] = 0xe0;
}

fn executeHalfFcmpPredicate(predicate: ir.FcmpPredicate) !void {
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\define i32 @compare(half %lhs, half %rhs) {{
        \\entry:
        \\  %condition = fcmp {s} half %lhs, %rhs
        \\  %result = zext i1 %condition to i32
        \\  ret i32 %result
        \\}}
        \\
    , .{@tagName(predicate)});
    defer std.testing.allocator.free(input);
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = x86_64_machine.MachineFunction.init("compare", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);

    const stub_len = 12;
    const mapping = try std.posix.mmap(null, bytes.len + stub_len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping[0..bytes.len], bytes);
    const stub = mapping[bytes.len..][0..stub_len];
    stub[0] = 0x48;
    stub[1] = 0xb8;
    std.mem.writeInt(u64, stub[2..10], @intFromPtr(&extendHalfForFcmpTest), .little);
    stub[10] = 0xff;
    stub[11] = 0xe0;

    var offset: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .direct_call) {
            const next_ip = @intFromPtr(mapping.ptr) + offset + 5;
            const displacement: i32 = @intCast(@intFromPtr(mapping.ptr + bytes.len) - next_ip);
            std.mem.writeInt(i32, mapping[offset + 1 ..][0..4], displacement, .little);
        }
        offset += encoding.instructionSize(instruction);
    }
    const compare: *const fn (f16, f16) callconv(.c) u32 = @ptrCast(mapping.ptr);
    for ([_][2]u16{
        .{ 0x7e01, 0x3c00 },
        .{ 0x3c00, 0xfe55 },
        .{ 0x7d01, 0x3c00 },
        .{ 0x3c00, 0xfd55 },
        .{ 0x3c00, 0x4000 },
        .{ 0x4000, 0x3c00 },
        .{ 0x0000, 0x8000 },
        .{ 0x8000, 0x0000 },
        .{ 0x0001, 0x0002 },
        .{ 0x8002, 0x8001 },
    }) |case| {
        const lhs: f16 = @bitCast(case[0]);
        const rhs: f16 = @bitCast(case[1]);
        const expected = expectedFcmp(predicate, @as(f32, lhs), @as(f32, rhs));
        try std.testing.expectEqual(@as(u32, @intFromBool(expected)), compare(lhs, rhs));
    }
}

fn executeFloatFcmpPredicate(predicate: ir.FcmpPredicate) !void {
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\define i32 @compare(float %lhs, float %rhs) {{
        \\entry:
        \\  %result = fcmp {s} float %lhs, %rhs
        \\  %wide = zext i1 %result to i32
        \\  ret i32 %wide
        \\}}
        \\
    , .{@tagName(predicate)});
    defer std.testing.allocator.free(input);
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("compare", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const compare: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    for ([_][2]u32{
        .{ 0x3f80_0000, 0x4000_0000 },
        .{ 0x8000_0000, 0x0000_0000 },
        .{ 0x4040_0000, 0x4000_0000 },
        .{ 0x7fc1_2345, 0x3f80_0000 },
        .{ 0x3f80_0000, 0x7fc5_4321 },
        .{ 0xff80_0000, 0x7f80_0000 },
    }) |case| {
        const lhs: f32 = @bitCast(case[0]);
        const rhs: f32 = @bitCast(case[1]);
        try std.testing.expectEqual(@as(u32, @intFromBool(expectedFcmp(predicate, lhs, rhs))), compare(lhs, rhs));
    }
}

fn executeDoubleFcmpPredicate(predicate: ir.FcmpPredicate) !void {
    const input = try std.fmt.allocPrint(std.testing.allocator,
        \\define i32 @compare(double %lhs, double %rhs) {{
        \\entry:
        \\  %result = fcmp {s} double %lhs, %rhs
        \\  %wide = zext i1 %result to i32
        \\  ret i32 %wide
        \\}}
        \\
    , .{@tagName(predicate)});
    defer std.testing.allocator.free(input);
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("compare", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const compare: *const fn (f64, f64) callconv(.c) u32 = @ptrCast(mapping.ptr);
    for ([_][2]u64{
        .{ 0x3ff0_0000_0000_0000, 0x4000_0000_0000_0000 },
        .{ 0x8000_0000_0000_0000, 0x0000_0000_0000_0000 },
        .{ 0x4008_0000_0000_0000, 0x4000_0000_0000_0000 },
        .{ 0x7ff8_1234_5678_9abc, 0x3ff0_0000_0000_0000 },
        .{ 0x3ff0_0000_0000_0000, 0x7ff8_9876_5432_1abc },
        .{ 0xfff0_0000_0000_0000, 0x7ff0_0000_0000_0000 },
    }) |case| {
        const lhs: f64 = @bitCast(case[0]);
        const rhs: f64 = @bitCast(case[1]);
        try std.testing.expectEqual(@as(u32, @intFromBool(expectedFcmp(predicate, lhs, rhs))), compare(lhs, rhs));
    }
}

test "generic cfg selector legalizes fpext half to float through nonrecursive libcall" {
    var machine = x86_64_machine.MachineFunction.init("extend-half", .float);
    defer machine.deinit(std.testing.allocator);
    var plan = stage2_planning.SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("input", 3);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 1;
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "input", .{ .xmm = .{ .reg = .xmm0, .bits = 16 } });

    try std.testing.expect((try selector_fp.lowerFpCast(&selector, "wide", .{
        .op = .fpext,
        .from_ty = .half,
        .value = .{ .named = "input" },
        .to_ty = .float,
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_xmm32_rsp = .{ .frame_index = .slot0, .reg = .xmm0 } },
        .{ .reload_xmm32_rsp = .{ .frame_index = .slot0, .reg = .xmm0 } },
        .{ .direct_call = .{ .symbol = "__extendhfsf2", .ret_ty = .float } },
    }, machine.instructions.items);
    try std.testing.expectEqual(@as(u16, 32), selector_state.valueLoc(&selector, "wide").?.xmm.bits);
}

test "generic cfg selector aligns frameless half extension calls" {
    var machine = x86_64_machine.MachineFunction.init("extend-half-frameless", .float);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "input", .{ .xmm = .{ .reg = .xmm0, .bits = 16 } });

    try std.testing.expect((try selector_fp.lowerFpCast(&selector, "wide", .{
        .op = .fpext,
        .from_ty = .half,
        .value = .{ .named = "input" },
        .to_ty = .float,
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "__extendhfsf2", .ret_ty = .float } },
        .add_rsp_8,
    }, machine.instructions.items);
}

test "generic cfg selector composes half to double extension" {
    var machine = x86_64_machine.MachineFunction.init("extend-half-double", .double);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "input", .{ .xmm = .{ .reg = .xmm2, .bits = 16 } });

    try std.testing.expect((try selector_fp.lowerFpCast(&selector, "wide", .{
        .op = .fpext,
        .from_ty = .half,
        .value = .{ .named = "input" },
        .to_ty = .double,
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm2 } },
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "__extendhfsf2", .ret_ty = .float } },
        .add_rsp_8,
        .{ .cvtss2sd_xmm = .{ .dst = .xmm0, .src = .xmm0 } },
    }, machine.instructions.items);
    try std.testing.expectEqual(@as(u16, 64), selector_state.valueLoc(&selector, "wide").?.xmm.bits);
}

test "generic cfg selector reserves call spills for composed half extensions" {
    const input =
        \\define double @extend_three(half %x, half %y, half %z) {
        \\entry:
        \\  %wide_x = fpext half %x to double
        \\  %wide_y = fpext half %y to double
        \\  %sum = fadd double %wide_x, %wide_y
        \\  %wide_z = fpext half %z to double
        \\  %result = fadd double %sum, %wide_z
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = x86_64_machine.MachineFunction.init("extend_three", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    try std.testing.expect(switch (machine.instructions.items[0]) {
        .sub_rsp_imm8, .sub_rsp_imm32, .sub_rsp_24, .sub_rsp_40, .sub_rsp_56 => true,
        else => false,
    });
}

test "generic cfg selector legalizes fptrunc float to half through nonrecursive libcall" {
    var machine = x86_64_machine.MachineFunction.init("truncate-float", .half);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "input", .{ .xmm = .{ .reg = .xmm2, .bits = 32 } });

    try std.testing.expect((try selector_fp.lowerFpCast(&selector, "narrow", .{
        .op = .fptrunc,
        .from_ty = .float,
        .value = .{ .named = "input" },
        .to_ty = .half,
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .movapd_xmm = .{ .dst = .xmm0, .src = .xmm2 } },
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "__truncsfhf2", .ret_ty = .half } },
        .add_rsp_8,
    }, machine.instructions.items);
    try std.testing.expectEqual(@as(u16, 16), selector_state.valueLoc(&selector, "narrow").?.xmm.bits);
}

test "generic cfg selector uses parametric registers for scalar FP casts and multiply" {
    var machine = x86_64_machine.MachineFunction.init("parametric-fp", .double);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "float_value", .{ .xmm = .{ .reg = .xmm3, .bits = 32 } });
    try selector_state.bindValueLoc(&selector, "double_rhs", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });

    try std.testing.expect((try selector_fp.lowerFpCast(&selector, "wide", .{
        .op = .fpext,
        .from_ty = .float,
        .value = .{ .named = "float_value" },
        .to_ty = .double,
    })) == null);
    try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "product", .{
        .op = .fmul,
        .ty = .double,
        .lhs = .{ .named = "wide" },
        .rhs = .{ .named = "double_rhs" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .cvtss2sd_xmm = .{ .dst = .xmm3, .src = .xmm3 } },
        .{ .mulsd_xmm = .{ .dst = .xmm3, .src = .xmm0 } },
    }, machine.instructions.items);
    try std.testing.expectEqual(@as(u16, 64), selector_state.valueLoc(&selector, "product").?.xmm.bits);
}

test "generic cfg selector handles spilled constant and identical scalar FP multiply operands" {
    var machine = x86_64_machine.MachineFunction.init("fp-operands", .float);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    try selector_state.bindValueLoc(&selector, "spilled", .{ .spill_fp = .{ .frame_index = .slot0, .bits = 32 } });

    try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "constant_product", .{
        .op = .fmul,
        .ty = .float,
        .lhs = .{ .named = "spilled" },
        .rhs = .{ .fp = "2.000000e+00" },
    })) == null);
    try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "square", .{
        .op = .fmul,
        .ty = .float,
        .lhs = .{ .named = "constant_product" },
        .rhs = .{ .named = "constant_product" },
    })) == null);

    var saw_reload = false;
    var saw_constant = false;
    var saw_identical = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .reload_xmm32_rsp => |reload| saw_reload = reload.reg == .xmm0 and reload.frame_index.eql(.slot0),
        .mov_imm32_xmm => |load| saw_constant = load.reg == .xmm1 and load.bits == 0x4000_0000,
        .mulss_xmm => |mul| saw_identical = saw_identical or mul.dst == mul.src,
        else => {},
    };
    try std.testing.expect(saw_reload and saw_constant and saw_identical);
}

test "generic cfg selector preserves scalar FP subtraction and division operand order" {
    {
        var machine = x86_64_machine.MachineFunction.init("fp-named-order", .float);
        defer machine.deinit(std.testing.allocator);
        var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", .{ .xmm = .{ .reg = .xmm3, .bits = 32 } });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .xmm = .{ .reg = .xmm0, .bits = 32 } });

        try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "difference", .{
            .op = .fsub,
            .ty = .float,
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        })) == null);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .subss_xmm = .{ .dst = .xmm3, .src = .xmm0 } },
        }, machine.instructions.items);
    }

    {
        var machine = x86_64_machine.MachineFunction.init("fp-spilled-lhs", .float);
        defer machine.deinit(std.testing.allocator);
        var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.stack_frame_bytes = 16;
        try selector_state.bindValueLoc(&selector, "lhs", .{ .spill_fp = .{ .frame_index = .slot0, .bits = 32 } });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .xmm = .{ .reg = .xmm0, .bits = 32 } });

        try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "quotient", .{
            .op = .fdiv,
            .ty = .float,
            .lhs = .{ .named = "lhs" },
            .rhs = .{ .named = "rhs" },
        })) == null);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .reload_xmm32_rsp = .{ .frame_index = .slot0, .reg = .xmm1 } },
            .{ .divss_xmm = .{ .dst = .xmm1, .src = .xmm0 } },
        }, machine.instructions.items);
    }

    {
        var machine = x86_64_machine.MachineFunction.init("fp-spilled-rhs", .double);
        defer machine.deinit(std.testing.allocator);
        var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.stack_frame_bytes = 16;
        try selector_state.bindValueLoc(&selector, "rhs", .{ .spill_fp = .{ .frame_index = .slot0, .bits = 64 } });

        try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "difference", .{
            .op = .fsub,
            .ty = .double,
            .lhs = .{ .fp = "8.000000e+00" },
            .rhs = .{ .named = "rhs" },
        })) == null);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_imm64_xmm = .{ .reg = .xmm0, .bits = 0x4020_0000_0000_0000 } },
            .{ .reload_xmm64_rsp = .{ .frame_index = .slot0, .reg = .xmm1 } },
            .{ .subsd_xmm = .{ .dst = .xmm0, .src = .xmm1 } },
        }, machine.instructions.items);
    }

    {
        var machine = x86_64_machine.MachineFunction.init("fp-identical", .double);
        defer machine.deinit(std.testing.allocator);
        var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm2, .bits = 64 } });

        try std.testing.expect((try selector_fp.lowerFpBinary(&selector, "quotient", .{
            .op = .fdiv,
            .ty = .double,
            .lhs = .{ .named = "value" },
            .rhs = .{ .named = "value" },
        })) == null);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .divsd_xmm = .{ .dst = .xmm2, .src = .xmm2 } },
        }, machine.instructions.items);
    }
}

test "generic cfg selector preserves scalar fneg bits" {
    const input =
        \\define float @neg_f32(float %value) {
        \\entry:
        \\  %result = fneg float %value
        \\  ret float %result
        \\}
        \\define double @neg_f64(double %value) {
        \\entry:
        \\  %result = fneg double %value
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    const f32_cases = [_]u32{
        0x0000_0000, 0x8000_0000, 0x0000_0001, 0x3f80_0000,
        0x7f80_0000, 0x7fc1_2345, 0x7f81_2345,
    };
    const f64_cases = [_]u64{
        0x0000_0000_0000_0000, 0x8000_0000_0000_0000,
        0x0000_0000_0000_0001, 0x3ff0_0000_0000_0000,
        0x7ff0_0000_0000_0000, 0x7ff8_1234_5678_9abc,
        0x7ff0_1234_5678_9abc,
    };

    for (module.functions.items, 0..) |function, index| {
        var machine = x86_64_machine.MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);

        var saw_bitwise_negation = false;
        var saw_arithmetic_subtraction = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .pxor_xmm => saw_bitwise_negation = true,
            .subss_xmm, .subsd_xmm => saw_arithmetic_subtraction = true,
            else => {},
        };
        try std.testing.expect(saw_bitwise_negation);
        try std.testing.expect(!saw_arithmetic_subtraction);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const negate: *const fn (f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
            for (f32_cases) |bits| try std.testing.expectEqual(bits ^ 0x8000_0000, @as(u32, @bitCast(negate(@bitCast(bits)))));
        } else {
            const negate: *const fn (f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            for (f64_cases) |bits| try std.testing.expectEqual(bits ^ 0x8000_0000_0000_0000, @as(u64, @bitCast(negate(@bitCast(bits)))));
        }
    }
}

test "generic cfg selector materializes scalar FP compare operands without clobbering" {
    var machine = x86_64_machine.MachineFunction.init("fp-compare-operands", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 16;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .spill_fp = .{ .frame_index = .slot0, .bits = 64 } });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });

    try std.testing.expect((try selector_fp.lowerFcmp(&selector, "ordered_less", .{
        .predicate = .olt,
        .operand_ty = .double,
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_xmm64_rsp = .{ .frame_index = .slot0, .reg = .xmm1 } },
        .{ .ucomisd = .{ .dst = .xmm1, .src = .xmm0 } },
        .{ .set_fcmp_eax = .olt },
    }, machine.instructions.items);

    machine.instructions.clearRetainingCapacity();
    try selector_state.bindValueLoc(&selector, "same", .{ .xmm = .{ .reg = .xmm3, .bits = 32 } });
    try std.testing.expect((try selector_fp.lowerFcmp(&selector, "unordered_equal", .{
        .predicate = .ueq,
        .operand_ty = .float,
        .lhs = .{ .named = "same" },
        .rhs = .{ .named = "same" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .ucomiss = .{ .dst = .xmm3, .src = .xmm3 } },
        .{ .set_fcmp_eax = .ueq },
    }, machine.instructions.items);

    machine.instructions.clearRetainingCapacity();
    try std.testing.expect((try selector_fp.lowerFcmp(&selector, "constant_true", .{
        .predicate = .true,
        .operand_ty = .float,
        .lhs = .{ .fp = "nan" },
        .rhs = .{ .fp = "0.000000e+00" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .set_fcmp_eax = .true },
    }, machine.instructions.items);
}

test "generic cfg selector executes every scalar float and double fcmp predicate" {
    for (scalar_fcmp_predicates) |predicate| {
        try executeFloatFcmpPredicate(predicate);
        try executeDoubleFcmpPredicate(predicate);
    }
}

test "generic cfg selector lowers only half oeq against literal zero as a bit test" {
    var machine = x86_64_machine.MachineFunction.init("half-zero", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm2, .bits = 16 } });
    try selector_state.bindValueLoc(&selector, "other", .{ .xmm = .{ .reg = .xmm3, .bits = 16 } });

    try std.testing.expect((try selector_fp.lowerFcmp(&selector, "positive", .{
        .predicate = .oeq,
        .operand_ty = .half,
        .lhs = .{ .named = "value" },
        .rhs = .{ .fp = "0xH0000" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .movd_xmm_eax = .xmm2 },
        .{ .and_eax_imm32 = 0x7fff },
        .test_eax_eax,
        .sete_eax,
    }, machine.instructions.items);

    machine.instructions.clearRetainingCapacity();
    try std.testing.expect((try selector_fp.lowerFcmp(&selector, "negative_reversed", .{
        .predicate = .oeq,
        .operand_ty = .half,
        .lhs = .{ .fp = "0xH8000" },
        .rhs = .{ .named = "value" },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .movd_xmm_eax = .xmm2 },
        .{ .and_eax_imm32 = 0x7fff },
        .test_eax_eax,
        .sete_eax,
    }, machine.instructions.items);

    for ([_]ir.FcmpInst{
        .{ .predicate = .ogt, .operand_ty = .half, .lhs = .{ .named = "value" }, .rhs = .{ .fp = "0xH0000" } },
        .{ .predicate = .uno, .operand_ty = .half, .lhs = .{ .named = "value" }, .rhs = .{ .fp = "0xH3c00" } },
        .{ .predicate = .oeq, .operand_ty = .half, .lhs = .{ .named = "value" }, .rhs = .{ .fp = "0xH3c00" } },
        .{ .predicate = .oeq, .operand_ty = .half, .lhs = .{ .named = "value" }, .rhs = .{ .named = "other" } },
    }) |near_miss| {
        machine.instructions.clearRetainingCapacity();
        const diagnostic = (try selector_fp.lowerFcmp(&selector, "near_miss", near_miss)).?;
        try std.testing.expect(std.mem.startsWith(u8, diagnostic.no_emitter, "composed-block-half-fcmp-"));
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "generic cfg selector executes half zero bit tests in both operand orders" {
    const input =
        \\define i32 @zero_rhs(half %value) {
        \\entry:
        \\  %is_zero = fcmp oeq half %value, 0xH0000
        \\  %wide = zext i1 %is_zero to i32
        \\  ret i32 %wide
        \\}
        \\define i32 @zero_lhs(half %value) {
        \\entry:
        \\  %is_zero = fcmp oeq half 0xH8000, %value
        \\  %wide = zext i1 %is_zero to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    inline for (.{ 0, 1 }) |index| {
        var machine = x86_64_machine.MachineFunction.init(module.functions.items[index].name, .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[index]));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        const is_zero: *const fn (f16) callconv(.c) u32 = @ptrCast(mapping.ptr);
        inline for (.{
            .{ @as(u16, 0x0000), @as(u32, 1) },
            .{ @as(u16, 0x8000), @as(u32, 1) },
            .{ @as(u16, 0x0001), @as(u32, 0) },
            .{ @as(u16, 0x8001), @as(u32, 0) },
            .{ @as(u16, 0x3c00), @as(u32, 0) },
            .{ @as(u16, 0xbc00), @as(u32, 0) },
            .{ @as(u16, 0x7c00), @as(u32, 0) },
            .{ @as(u16, 0xfc00), @as(u32, 0) },
            .{ @as(u16, 0x7e01), @as(u32, 0) },
            .{ @as(u16, 0xfe55), @as(u32, 0) },
            .{ @as(u16, 0x7d01), @as(u32, 0) },
            .{ @as(u16, 0xfd55), @as(u32, 0) },
        }) |case| try std.testing.expectEqual(case[1], is_zero(@bitCast(case[0])));
    }
}

test "generic cfg selector executes widened half uno and olt predicates" {
    try executeHalfFcmpPredicate(.uno);
    try executeHalfFcmpPredicate(.olt);
}

test "generic cfg selector executes bit-exact scalar FP widening and narrowing" {
    const input =
        \\define double @widen(float %value) {
        \\entry:
        \\  %result = fpext float %value to double
        \\  ret double %result
        \\}
        \\define float @narrow(double %value) {
        \\entry:
        \\  %result = fptrunc double %value to float
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var widen_machine = x86_64_machine.MachineFunction.init("widen", .double);
    defer widen_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &widen_machine, module.functions.items[0]));
    const widen_bytes = try encoding.encodeFunction(std.testing.allocator, widen_machine);
    defer std.testing.allocator.free(widen_bytes);
    const widen_mapping = try std.posix.mmap(null, widen_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(widen_mapping);
    @memcpy(widen_mapping, widen_bytes);
    const widen: *const fn (f32) callconv(.c) f64 = @ptrCast(widen_mapping.ptr);
    inline for (.{
        @as(u32, 0x0000_0000),
        @as(u32, 0x8000_0000),
        @as(u32, 0x3fc0_0000),
        @as(u32, 0xc020_0000),
        @as(u32, 0x0000_0001),
        @as(u32, 0x8000_0001),
        @as(u32, 0x7f80_0000),
        @as(u32, 0xff80_0000),
        @as(u32, 0x7fc1_2345),
    }) |bits| {
        const value: f32 = @bitCast(bits);
        const expected: f64 = value;
        try std.testing.expectEqual(@as(u64, @bitCast(expected)), @as(u64, @bitCast(widen(value))));
    }

    var narrow_machine = x86_64_machine.MachineFunction.init("narrow", .float);
    defer narrow_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &narrow_machine, module.functions.items[1]));
    const narrow_bytes = try encoding.encodeFunction(std.testing.allocator, narrow_machine);
    defer std.testing.allocator.free(narrow_bytes);
    const narrow_mapping = try std.posix.mmap(null, narrow_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(narrow_mapping);
    @memcpy(narrow_mapping, narrow_bytes);
    const narrow: *const fn (f64) callconv(.c) f32 = @ptrCast(narrow_mapping.ptr);
    inline for (.{
        @as(u64, 0x0000_0000_0000_0000),
        @as(u64, 0x8000_0000_0000_0000),
        @as(u64, 0x3ff0_0000_0000_0000),
        @as(u64, 0xbff0_0000_0000_0000),
        @as(u64, 0x3ff0_0000_0fff_ffff),
        @as(u64, 0x3ff0_0000_1000_0000),
        @as(u64, 0x3ff0_0000_1000_0001),
        @as(u64, 0x36a0_0000_0000_0000),
        @as(u64, 0x7ff0_0000_0000_0000),
        @as(u64, 0xfff0_0000_0000_0000),
        @as(u64, 0x7ff8_1234_5678_9abc),
    }) |bits| {
        const value: f64 = @bitCast(bits);
        const expected: f32 = @floatCast(value);
        try std.testing.expectEqual(@as(u32, @bitCast(expected)), @as(u32, @bitCast(narrow(value))));
    }
}

test "generic cfg selector executes bit-exact scalar float and double multiplication" {
    const input =
        \\define float @mul_float(float %lhs, float %rhs) {
        \\entry:
        \\  %result = fmul float %lhs, %rhs
        \\  ret float %result
        \\}
        \\define double @mul_double(double %lhs, double %rhs) {
        \\entry:
        \\  %result = fmul double %lhs, %rhs
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var float_machine = x86_64_machine.MachineFunction.init("mul_float", .float);
    defer float_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &float_machine, module.functions.items[0]));
    const float_bytes = try encoding.encodeFunction(std.testing.allocator, float_machine);
    defer std.testing.allocator.free(float_bytes);
    const float_mapping = try std.posix.mmap(null, float_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(float_mapping);
    @memcpy(float_mapping, float_bytes);
    const mul_float: *const fn (f32, f32) callconv(.c) f32 = @ptrCast(float_mapping.ptr);
    inline for (.{
        .{ @as(u32, 0x0000_0000), @as(u32, 0xc040_0000) },
        .{ @as(u32, 0x8000_0000), @as(u32, 0xc040_0000) },
        .{ @as(u32, 0x3fc0_0000), @as(u32, 0xc000_0000) },
        .{ @as(u32, 0x0000_0001), @as(u32, 0x3f80_0000) },
        .{ @as(u32, 0x7f7f_ffff), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x0080_0000), @as(u32, 0x3f00_0000) },
        .{ @as(u32, 0x0000_0001), @as(u32, 0x3f00_0000) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0xc000_0000) },
        .{ @as(u32, 0x7fc1_2345), @as(u32, 0x3f80_0000) },
    }) |case| {
        const lhs: f32 = @bitCast(case[0]);
        const rhs: f32 = @bitCast(case[1]);
        const expected = lhs * rhs;
        try std.testing.expectEqual(@as(u32, @bitCast(expected)), @as(u32, @bitCast(mul_float(lhs, rhs))));
    }

    var double_machine = x86_64_machine.MachineFunction.init("mul_double", .double);
    defer double_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &double_machine, module.functions.items[1]));
    const double_bytes = try encoding.encodeFunction(std.testing.allocator, double_machine);
    defer std.testing.allocator.free(double_bytes);
    const double_mapping = try std.posix.mmap(null, double_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(double_mapping);
    @memcpy(double_mapping, double_bytes);
    const mul_double: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(double_mapping.ptr);
    inline for (.{
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0xc008_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0xc008_0000_0000_0000) },
        .{ @as(u64, 0x3ff8_0000_0000_0000), @as(u64, 0xc000_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x3ff0_0000_0000_0000) },
        .{ @as(u64, 0x7fef_ffff_ffff_ffff), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x0010_0000_0000_0000), @as(u64, 0x3fe0_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x3fe0_0000_0000_0000) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0xc000_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0x3ff0_0000_0000_0000) },
    }) |case| {
        const lhs: f64 = @bitCast(case[0]);
        const rhs: f64 = @bitCast(case[1]);
        const expected = lhs * rhs;
        try std.testing.expectEqual(@as(u64, @bitCast(expected)), @as(u64, @bitCast(mul_double(lhs, rhs))));
    }
}

test "generic cfg selector executes bit-exact scalar float subtraction and division" {
    const input =
        \\define float @sub_float(float %lhs, float %rhs) {
        \\entry:
        \\  %result = fsub float %lhs, %rhs
        \\  ret float %result
        \\}
        \\define float @div_float(float %lhs, float %rhs) {
        \\entry:
        \\  %result = fdiv float %lhs, %rhs
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var sub_machine = x86_64_machine.MachineFunction.init("sub_float", .float);
    defer sub_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &sub_machine, module.functions.items[0]));
    const sub_bytes = try encoding.encodeFunction(std.testing.allocator, sub_machine);
    defer std.testing.allocator.free(sub_bytes);
    const sub_mapping = try std.posix.mmap(null, sub_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(sub_mapping);
    @memcpy(sub_mapping, sub_bytes);
    const sub_float: *const fn (f32, f32) callconv(.c) f32 = @ptrCast(sub_mapping.ptr);
    inline for (.{
        .{ @as(u32, 0x3fc0_0000), @as(u32, 0x4010_0000) },
        .{ @as(u32, 0x3f80_0000), @as(u32, 0x3f80_0000) },
        .{ @as(u32, 0x8000_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000) },
        .{ @as(u32, 0x0080_0000), @as(u32, 0x007f_ffff) },
        .{ @as(u32, 0x7f7f_ffff), @as(u32, 0xff7f_ffff) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0x3f80_0000) },
        .{ @as(u32, 0xff80_0000), @as(u32, 0xbf80_0000) },
        .{ @as(u32, 0x7fc1_2345), @as(u32, 0x3f80_0000) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0x7f80_0000) },
    }) |case| {
        const lhs: f32 = @bitCast(case[0]);
        const rhs: f32 = @bitCast(case[1]);
        const expected = lhs - rhs;
        try std.testing.expectEqual(@as(u32, @bitCast(expected)), @as(u32, @bitCast(sub_float(lhs, rhs))));
    }

    var div_machine = x86_64_machine.MachineFunction.init("div_float", .float);
    defer div_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &div_machine, module.functions.items[1]));
    const div_bytes = try encoding.encodeFunction(std.testing.allocator, div_machine);
    defer std.testing.allocator.free(div_bytes);
    const div_mapping = try std.posix.mmap(null, div_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(div_mapping);
    @memcpy(div_mapping, div_bytes);
    const div_float: *const fn (f32, f32) callconv(.c) f32 = @ptrCast(div_mapping.ptr);
    inline for (.{
        .{ @as(u32, 0x40c0_0000), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x4000_0000), @as(u32, 0x40c0_0000) },
        .{ @as(u32, 0x3f80_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0xbf80_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x3f80_0000), @as(u32, 0x8000_0000) },
        .{ @as(u32, 0x0000_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0x7f80_0000) },
        .{ @as(u32, 0x0080_0000), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x7f7f_ffff), @as(u32, 0x0080_0000) },
        .{ @as(u32, 0x0000_0001), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x8000_0001), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x7fc1_2345), @as(u32, 0x3f80_0000) },
    }) |case| {
        const lhs: f32 = @bitCast(case[0]);
        const rhs: f32 = @bitCast(case[1]);
        const expected = lhs / rhs;
        try std.testing.expectEqual(@as(u32, @bitCast(expected)), @as(u32, @bitCast(div_float(lhs, rhs))));
    }
}

test "generic cfg selector executes bit-exact scalar double subtraction and division" {
    const input =
        \\define double @sub_double(double %lhs, double %rhs) {
        \\entry:
        \\  %result = fsub double %lhs, %rhs
        \\  ret double %result
        \\}
        \\define double @div_double(double %lhs, double %rhs) {
        \\entry:
        \\  %result = fdiv double %lhs, %rhs
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var sub_machine = x86_64_machine.MachineFunction.init("sub_double", .double);
    defer sub_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &sub_machine, module.functions.items[0]));
    const sub_bytes = try encoding.encodeFunction(std.testing.allocator, sub_machine);
    defer std.testing.allocator.free(sub_bytes);
    const sub_mapping = try std.posix.mmap(null, sub_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(sub_mapping);
    @memcpy(sub_mapping, sub_bytes);
    const sub_double: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(sub_mapping.ptr);
    inline for (.{
        .{ @as(u64, 0x3ff8_0000_0000_0000), @as(u64, 0x4002_0000_0000_0000) },
        .{ @as(u64, 0x3ff0_0000_0000_0000), @as(u64, 0x3ff0_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000) },
        .{ @as(u64, 0x0010_0000_0000_0000), @as(u64, 0x000f_ffff_ffff_ffff) },
        .{ @as(u64, 0x7fef_ffff_ffff_ffff), @as(u64, 0xffef_ffff_ffff_ffff) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x3ff0_0000_0000_0000) },
        .{ @as(u64, 0xfff0_0000_0000_0000), @as(u64, 0xbff0_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0x3ff0_0000_0000_0000) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff0_0000_0000_0000) },
    }) |case| {
        const lhs: f64 = @bitCast(case[0]);
        const rhs: f64 = @bitCast(case[1]);
        const expected = lhs - rhs;
        try std.testing.expectEqual(@as(u64, @bitCast(expected)), @as(u64, @bitCast(sub_double(lhs, rhs))));
    }

    var div_machine = x86_64_machine.MachineFunction.init("div_double", .double);
    defer div_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &div_machine, module.functions.items[1]));
    const div_bytes = try encoding.encodeFunction(std.testing.allocator, div_machine);
    defer std.testing.allocator.free(div_bytes);
    const div_mapping = try std.posix.mmap(null, div_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(div_mapping);
    @memcpy(div_mapping, div_bytes);
    const div_double: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(div_mapping.ptr);
    inline for (.{
        .{ @as(u64, 0x4018_0000_0000_0000), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x4000_0000_0000_0000), @as(u64, 0x4018_0000_0000_0000) },
        .{ @as(u64, 0x3ff0_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0xbff0_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x3ff0_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff0_0000_0000_0000) },
        .{ @as(u64, 0x0010_0000_0000_0000), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x7fef_ffff_ffff_ffff), @as(u64, 0x0010_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0x3ff0_0000_0000_0000) },
    }) |case| {
        const lhs: f64 = @bitCast(case[0]);
        const rhs: f64 = @bitCast(case[1]);
        const expected = lhs / rhs;
        try std.testing.expectEqual(@as(u64, @bitCast(expected)), @as(u64, @bitCast(div_double(lhs, rhs))));
    }
}

test "generic cfg selector executes type-driven scalar float addition" {
    const input =
        \\define float @add(float %lhs, float %rhs) {
        \\entry:
        \\  %sum = fadd float %lhs, %rhs
        \\  ret float %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("add", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const add: *const fn (f32, f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u32, @bitCast(@as(f32, 3.75))), @as(u32, @bitCast(add(1.5, 2.25))));
    try std.testing.expectEqual(@as(u32, 0x8000_0000), @as(u32, @bitCast(add(-0.0, -0.0))));
    try std.testing.expectEqual(std.math.inf(f32), add(std.math.inf(f32), 1.0));
}

test "generic cfg selector executes type-driven scalar double addition" {
    const input =
        \\define double @add(double %lhs, double %rhs) {
        \\entry:
        \\  %sum = fadd double %lhs, %rhs
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("add", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    var saw_addsd = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .addsd_xmm => saw_addsd = true,
        else => {},
    };
    try std.testing.expect(saw_addsd);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const add: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, @bitCast(@as(f64, 3.75))), @as(u64, @bitCast(add(1.5, 2.25))));
    try std.testing.expectEqual(@as(u64, 0x8000_0000_0000_0000), @as(u64, @bitCast(add(-0.0, -0.0))));
    try std.testing.expectEqual(std.math.inf(f64), add(std.math.inf(f64), 1.0));
}

test "generic cfg selector executes bit-exact widened half addition" {
    const input =
        \\define half @add(half %lhs, half %rhs) {
        \\entry:
        \\  %sum = fadd half %lhs, %rhs
        \\  ret half %sum
        \\}
        \\define half @add_inf(half %value) {
        \\entry:
        \\  %pointer_slot = alloca ptr, align 8
        \\  %value_slot = alloca half, align 2
        \\  %sum = fadd half %value, 0xH7C00
        \\  store half %sum, ptr %value_slot, align 2
        \\  store ptr %value_slot, ptr %pointer_slot, align 8
        \\  call void asm sideeffect "", "m,~{memory},~{dirflag},~{fpsr},~{flags}"(ptr %pointer_slot)
        \\  ret half %sum
        \\}
        \\define half @reject_sub(half %lhs, half %rhs) {
        \\entry:
        \\  %difference = fsub half %lhs, %rhs
        \\  ret half %difference
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items[0..2]) |function| {
        var machine = x86_64_machine.MachineFunction.init(function.name, .half);
        defer machine.deinit(std.testing.allocator);
        const selection = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
        switch (selection) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("half add diagnostic={s}\n", .{diagnostic.detail()});
                return error.TestUnexpectedResult;
            },
        }
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);

        const stub_len = 12;
        const mapping = try std.posix.mmap(null, bytes.len + 2 * stub_len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping[0..bytes.len], bytes);
        writeAbsoluteJump(mapping[bytes.len..][0..stub_len], @intFromPtr(&extendHalfForFcmpTest));
        writeAbsoluteJump(mapping[bytes.len + stub_len ..][0..stub_len], @intFromPtr(&truncateFloatForFaddTest));

        var offset: usize = 0;
        for (machine.instructions.items) |instruction| {
            if (instruction == .direct_call) {
                const target_offset = if (std.mem.eql(u8, instruction.direct_call.symbol, "__extendhfsf2")) bytes.len else bytes.len + stub_len;
                const next_ip = @intFromPtr(mapping.ptr) + offset + 5;
                const displacement: i32 = @intCast(@intFromPtr(mapping.ptr + target_offset) - next_ip);
                std.mem.writeInt(i32, mapping[offset + 1 ..][0..4], displacement, .little);
            }
            offset += encoding.instructionSize(instruction);
        }

        if (std.mem.eql(u8, function.name, "add")) {
            const add: *const fn (f16, f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
            for ([_][2]u16{
                .{ 0x0000, 0x8000 }, .{ 0x8000, 0x8000 }, .{ 0x0001, 0x0001 },
                .{ 0x03ff, 0x0001 }, .{ 0x3c00, 0x1000 }, .{ 0x3c00, 0x1001 },
                .{ 0x3c00, 0x9400 }, .{ 0x7bff, 0x7bff }, .{ 0x7c00, 0xfc00 },
                .{ 0x7e45, 0x3c00 }, .{ 0x7d01, 0x3c00 },
            }) |case| {
                const lhs: f16 = @bitCast(case[0]);
                const rhs: f16 = @bitCast(case[1]);
                const expected: f16 = lhs + rhs;
                const actual = add(lhs, rhs);
                if (std.math.isNan(expected)) {
                    try std.testing.expect(std.math.isNan(actual));
                } else {
                    try std.testing.expectEqual(@as(u16, @bitCast(expected)), @as(u16, @bitCast(actual)));
                }
            }
        } else {
            const add_inf: *const fn (f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
            inline for (.{ @as(u16, 0x0000), @as(u16, 0x8001), @as(u16, 0x3c00), @as(u16, 0x7bff), @as(u16, 0x7c00), @as(u16, 0xfc00), @as(u16, 0x7e45), @as(u16, 0x7d01) }) |bits| {
                const value: f16 = @bitCast(bits);
                const expected: f16 = value + std.math.inf(f16);
                const actual = add_inf(value);
                if (std.math.isNan(expected)) {
                    try std.testing.expect(std.math.isNan(actual));
                } else {
                    try std.testing.expectEqual(@as(u16, @bitCast(expected)), @as(u16, @bitCast(actual)));
                }
            }
        }
    }

    var rejected = x86_64_machine.MachineFunction.init("reject_sub", .half);
    defer rejected.deinit(std.testing.allocator);
    const result = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &rejected, module.functions.items[2]);
    try std.testing.expect(result == .unsupported);
}

test "generic cfg selector preserves an fadd lhs resident in XMM1" {
    const input =
        \\define double @add_xmm1_lhs(float %skip, double %lhs) {
        \\entry:
        \\  %sum = fadd double %lhs, 1.000000e+00
        \\  ret double %sum
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("add_xmm1_lhs", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const add: *const fn (f32, f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 0x400c_0000_0000_0000), @as(u64, @bitCast(add(0.0, 2.5))));
}

test "generic cfg selector validates empty side-effect FP barriers" {
    var machine = x86_64_machine.MachineFunction.init("fp-barrier", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm2, .bits = 32 } });
    var args: std.ArrayList(ir.CallArg) = .empty;
    defer args.deinit(std.testing.allocator);
    try args.append(std.testing.allocator, .{ .ty = .float, .value = .{ .named = "value" } });

    try std.testing.expect((try selector_calls.lowerCall(&selector, null, .{
        .ret_ty = .void,
        .callee = "",
        .inline_asm = .{
            .template = "",
            .constraints = "rm,~{dirflag},~{fpsr},~{flags}",
            .sideeffect = true,
            .may_load = true,
        },
        .args = args,
    })) == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    try selector_state.bindValueLoc(&selector, "wide", .{ .xmm = .{ .reg = .xmm3, .bits = 64 } });
    args.clearRetainingCapacity();
    try args.append(std.testing.allocator, .{ .ty = .double, .value = .{ .named = "wide" } });
    try std.testing.expect((try selector_calls.lowerCall(&selector, null, .{
        .ret_ty = .void,
        .callee = "",
        .inline_asm = .{
            .template = "",
            .constraints = "rm,~{dirflag},~{fpsr},~{flags}",
            .sideeffect = true,
            .may_load = true,
        },
        .args = args,
    })) == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    try selector_state.bindValueLoc(&selector, "stack_pointer", .{ .stack_scalar = .{ .base_disp = 8, .bits = 64 } });
    args.clearRetainingCapacity();
    try args.append(std.testing.allocator, .{ .ty = .ptr, .value = .{ .named = "stack_pointer" } });
    try std.testing.expect((try selector_calls.lowerCall(&selector, null, .{
        .ret_ty = .void,
        .callee = "",
        .inline_asm = .{
            .template = "",
            .constraints = "m,~{memory},~{dirflag},~{fpsr},~{flags}",
            .sideeffect = true,
            .has_memory_clobber = true,
            .may_load = true,
        },
        .args = args,
    })) == null);
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "generic cfg selector preserves exact float bitcasts" {
    const input =
        \\define i32 @to_bits(float %value) {
        \\entry:
        \\  %bits = bitcast float %value to i32
        \\  ret i32 %bits
        \\}
        \\define float @from_bits(i32 %bits) {
        \\entry:
        \\  %value = bitcast i32 %bits to float
        \\  ret float %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    inline for (.{ 0, 1 }) |index| {
        var machine = x86_64_machine.MachineFunction.init(module.functions.items[index].name, module.functions.items[index].ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[index]));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        inline for (.{ @as(u32, 0x8000_0000), @as(u32, 0x7fc1_2345), @as(u32, 0x0000_0001) }) |bits| {
            if (index == 0) {
                const function: *const fn (f32) callconv(.c) u32 = @ptrCast(mapping.ptr);
                try std.testing.expectEqual(bits, function(@bitCast(bits)));
            } else {
                const function: *const fn (u32) callconv(.c) f32 = @ptrCast(mapping.ptr);
                try std.testing.expectEqual(bits, @as(u32, @bitCast(function(bits))));
            }
        }
    }
}

test "generic cfg selector preserves exact double bitcasts" {
    const input =
        \\define i64 @to_bits(double %value) {
        \\entry:
        \\  %bits = bitcast double %value to i64
        \\  ret i64 %bits
        \\}
        \\define double @from_bits(i64 %bits) {
        \\entry:
        \\  %value = bitcast i64 %bits to double
        \\  ret double %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    inline for (.{ 0, 1 }) |index| {
        var machine = x86_64_machine.MachineFunction.init(module.functions.items[index].name, module.functions.items[index].ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[index]));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        inline for (.{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0x0000_0000_0000_0001) }) |bits| {
            if (index == 0) {
                const function: *const fn (f64) callconv(.c) u64 = @ptrCast(mapping.ptr);
                try std.testing.expectEqual(bits, function(@bitCast(bits)));
            } else {
                const function: *const fn (u64) callconv(.c) f64 = @ptrCast(mapping.ptr);
                try std.testing.expectEqual(bits, @as(u64, @bitCast(function(bits))));
            }
        }
    }
}

test "generic cfg selector preserves exact fabs payload bits" {
    const input =
        \\declare half @llvm.fabs.f16(half)
        \\define half @abs_half(half %value) {
        \\entry:
        \\  %absolute = call half @llvm.fabs.f16(half %value)
        \\  ret half %absolute
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("abs_half", .half);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (f16) callconv(.c) f16 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u16, 0x8000), @as(u16, 0x0000) },
        .{ @as(u16, 0xfe55), @as(u16, 0x7e55) },
        .{ @as(u16, 0x8001), @as(u16, 0x0001) },
    }) |case| try std.testing.expectEqual(case[1], @as(u16, @bitCast(function(@bitCast(case[0])))));
}

test "generic cfg selector preserves exact double fabs payload bits" {
    const input =
        \\declare double @llvm.fabs.f64(double)
        \\define double @abs_double(double %value) {
        \\entry:
        \\  %absolute = call double @llvm.fabs.f64(double %value)
        \\  ret double %absolute
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("abs_double", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0xfff8_1234_5678_9abc), @as(u64, 0x7ff8_1234_5678_9abc) },
        .{ @as(u64, 0xfff0_0000_0000_0042), @as(u64, 0x7ff0_0000_0000_0042) },
        .{ @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x0000_0000_0000_0001) },
    }) |case| try std.testing.expectEqual(case[1], @as(u64, @bitCast(function(@bitCast(case[0])))));
}

test "generic cfg selector executes exact scalar maxnum semantics" {
    const input =
        \\declare float @llvm.maxnum.f32(float, float)
        \\declare double @llvm.maxnum.f64(double, double)
        \\define float @max_float(float %lhs, float %rhs) {
        \\entry:
        \\  %result = tail call float @llvm.maxnum.f32(float %lhs, float %rhs)
        \\  ret float %result
        \\}
        \\define double @max_double(double %lhs, double %rhs) {
        \\entry:
        \\  %result = tail call double @llvm.maxnum.f64(double %lhs, double %rhs)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var float_machine = x86_64_machine.MachineFunction.init("max_float", .float);
    defer float_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &float_machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(float_machine);
    const float_bytes = try encoding.encodeFunction(std.testing.allocator, float_machine);
    defer std.testing.allocator.free(float_bytes);
    const float_mapping = try std.posix.mmap(null, float_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(float_mapping);
    @memcpy(float_mapping, float_bytes);
    const max_float: *const fn (f32, f32) callconv(.c) f32 = @ptrCast(float_mapping.ptr);
    inline for (.{
        .{ @as(u32, 0x3f80_0000), @as(u32, 0x4000_0000), @as(u32, 0x4000_0000) },
        .{ @as(u32, 0x4040_0000), @as(u32, 0xc080_0000), @as(u32, 0x4040_0000) },
        .{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x8000_0000), @as(u32, 0x0000_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x8000_0000), @as(u32, 0x8000_0000), @as(u32, 0x8000_0000) },
        .{ @as(u32, 0x7fc1_2345), @as(u32, 0x8000_0001), @as(u32, 0x8000_0001) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0x7f81_2345), @as(u32, 0x7f80_0000) },
    }) |case| {
        try std.testing.expectEqual(case[2], @as(u32, @bitCast(max_float(@bitCast(case[0]), @bitCast(case[1])))));
    }

    var double_machine = x86_64_machine.MachineFunction.init("max_double", .double);
    defer double_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &double_machine, module.functions.items[1]));
    try x86_64_verify.verifyFunction(double_machine);
    const double_bytes = try encoding.encodeFunction(std.testing.allocator, double_machine);
    defer std.testing.allocator.free(double_bytes);
    const double_mapping = try std.posix.mmap(null, double_bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(double_mapping);
    @memcpy(double_mapping, double_bytes);
    const max_double: *const fn (f64, f64) callconv(.c) f64 = @ptrCast(double_mapping.ptr);
    inline for (.{
        .{ @as(u64, 0x3ff0_0000_0000_0000), @as(u64, 0x4000_0000_0000_0000), @as(u64, 0x4000_0000_0000_0000) },
        .{ @as(u64, 0x4008_0000_0000_0000), @as(u64, 0xc010_0000_0000_0000), @as(u64, 0x4008_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x8000_0000_0000_0001) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff0_1234_5678_9abc), @as(u64, 0x7ff0_0000_0000_0000) },
    }) |case| {
        try std.testing.expectEqual(case[2], @as(u64, @bitCast(max_double(@bitCast(case[0]), @bitCast(case[1])))));
    }
}

test "generic cfg selector keeps scalar minnum fail closed" {
    const input =
        \\declare float @llvm.minnum.f32(float, float)
        \\define float @min_float(float %lhs, float %rhs) {
        \\entry:
        \\  %result = call float @llvm.minnum.f32(float %lhs, float %rhs)
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("min_float", .float);
    defer machine.deinit(std.testing.allocator);
    const result = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expect(result == .unsupported);
    try std.testing.expectEqualStrings("composed-block-llvm-intrinsic", result.unsupported.detail());
}

test "generic cfg selector rejects unknown llvm intrinsics before direct calls" {
    const input =
        \\declare double @llvm.sqrt.f64(double)
        \\define double @bad(double %value) {
        \\entry:
        \\  %result = call double @llvm.sqrt.f64(double %value)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("bad", .double);
    defer machine.deinit(std.testing.allocator);
    const result = try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]);
    try std.testing.expect(result == .unsupported);
    try std.testing.expectEqualStrings("composed-block-llvm-intrinsic", result.unsupported.detail());
}

test "generic cfg selector executes float phi edges exactly" {
    const input =
        \\define float @choose(float %lhs, float %rhs, i32 %pick) {
        \\entry:
        \\  %condition = icmp ne i32 %pick, 0
        \\  br i1 %condition, label %left, label %right
        \\left:
        \\  br label %merge
        \\right:
        \\  br label %merge
        \\merge:
        \\  %value = phi float [ %lhs, %left ], [ %rhs, %right ]
        \\  ret float %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("choose", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (f32, f32, u32) callconv(.c) f32 = @ptrCast(mapping.ptr);
    const lhs_bits: u32 = 0x8000_0000;
    const rhs_bits: u32 = 0x7fc1_2345;
    try std.testing.expectEqual(lhs_bits, @as(u32, @bitCast(function(@bitCast(lhs_bits), @bitCast(rhs_bits), 1))));
    try std.testing.expectEqual(rhs_bits, @as(u32, @bitCast(function(@bitCast(lhs_bits), @bitCast(rhs_bits), 0))));
}
