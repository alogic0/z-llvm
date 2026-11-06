const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const encoding = @import("../../../mc/encoding.zig");
const inspection = @import("inspection.zig");
const selector_state = @import("composed_selector_state.zig");
const state_data = @import("composed_selector_state_data.zig");
const selector_types = @import("selector_types.zig");
const selector_vector = @import("composed_selector_vector.zig");
const selector_impl = @import("composed_selector_impl.zig");

test "generic cfg selector encodes bounded packed double operations" {
    var machine = x86_64_machine.MachineFunction.init("packed-ops", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.append(std.testing.allocator, .{ .addpd_xmm = .{ .dst = .xmm2, .src = .xmm3 } });
    try machine.instructions.append(std.testing.allocator, .{ .subpd_xmm = .{ .dst = .xmm6, .src = .xmm7 } });
    try machine.instructions.append(std.testing.allocator, .{ .mulpd_xmm = .{ .dst = .xmm4, .src = .xmm5 } });
    try machine.instructions.append(std.testing.allocator, .{ .movsd_xmm = .{ .dst = .xmm6, .src = .xmm7 } });
    try machine.instructions.append(std.testing.allocator, .{ .unpcklpd_xmm = .{ .dst = .xmm1, .src = .xmm2 } });
    try machine.instructions.append(std.testing.allocator, .{ .unpckhpd_xmm = .{ .dst = .xmm3, .src = .xmm4 } });
    try machine.instructions.append(std.testing.allocator, .{ .shufpd_xmm = .{ .dst = .xmm2, .src = .xmm5, .imm = 2 } });
    try machine.instructions.append(std.testing.allocator, .{ .shufpd_xmm = .{ .dst = .xmm6, .src = .xmm6, .imm = 1 } });
    try machine.instructions.append(std.testing.allocator, .{ .shufpd_xmm = .{ .dst = .xmm7, .src = .xmm7, .imm = 3 } });
    try machine.instructions.append(std.testing.allocator, .{ .addps_xmm = .{ .dst = .xmm2, .src = .xmm3 } });
    try machine.instructions.append(std.testing.allocator, .{ .subps_xmm = .{ .dst = .xmm6, .src = .xmm7 } });
    try machine.instructions.append(std.testing.allocator, .{ .mulps_xmm = .{ .dst = .xmm4, .src = .xmm5 } });
    try machine.instructions.append(std.testing.allocator, .{ .movss_xmm = .{ .dst = .xmm6, .src = .xmm7 } });
    try machine.instructions.append(std.testing.allocator, .{ .unpcklps_xmm = .{ .dst = .xmm1, .src = .xmm2 } });
    try machine.instructions.append(std.testing.allocator, .{ .shufps_high_f32_to_low = .xmm3 });
    try machine.instructions.append(std.testing.allocator, .{ .shufps_xmm = .{ .dst = .xmm5, .src = .xmm2, .imm = 0x14 } });
    try machine.instructions.append(std.testing.allocator, .ret);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x66, 0x0f, 0x58, 0xd3,
        0x66, 0x0f, 0x5c, 0xf7,
        0x66, 0x0f, 0x59, 0xe5,
        0xf2, 0x0f, 0x10, 0xf7,
        0x66, 0x0f, 0x14, 0xca,
        0x66, 0x0f, 0x15, 0xdc,
        0x66, 0x0f, 0xc6, 0xd5,
        0x02, 0x66, 0x0f, 0xc6,
        0xf6, 0x01, 0x66, 0x0f,
        0xc6, 0xff, 0x03, 0x0f,
        0x58, 0xd3, 0x0f, 0x5c,
        0xf7, 0x0f, 0x59, 0xe5,
        0xf3, 0x0f, 0x10, 0xf7,
        0x0f, 0x14, 0xca, 0x0f,
        0xc6, 0xdb, 0x55, 0x0f,
        0xc6, 0xea, 0x14, 0xc3,
    }, bytes);

    var spill_machine = x86_64_machine.MachineFunction.init("packed-spill", .void);
    defer spill_machine.deinit(std.testing.allocator);
    try spill_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_24,
        .{ .spill_xmm128_rsp = .{ .reg = .xmm2, .frame_index = .slot0 } },
        .{ .reload_xmm128_rsp = .{ .reg = .xmm3, .frame_index = .slot0 } },
        .add_rsp_24,
        .ret,
    });
    const spill_bytes = try encoding.encodeFunction(std.testing.allocator, spill_machine);
    defer std.testing.allocator.free(spill_bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x18,
        0x66, 0x0f, 0x11, 0x14,
        0x24, 0x66, 0x0f, 0x10,
        0x1c, 0x24, 0x48, 0x83,
        0xc4, 0x18, 0xc3,
    }, spill_bytes);

    var float_spill_machine = x86_64_machine.MachineFunction.init("packed-float-spill", .void);
    defer float_spill_machine.deinit(std.testing.allocator);
    try float_spill_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_24,
        .{ .spill_xmm128ps_rsp = .{ .reg = .xmm2, .frame_index = .slot0 } },
        .{ .reload_xmm128ps_rsp = .{ .reg = .xmm3, .frame_index = .slot0 } },
        .add_rsp_24,
        .ret,
    });
    const float_spill_bytes = try encoding.encodeFunction(std.testing.allocator, float_spill_machine);
    defer std.testing.allocator.free(float_spill_bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x48, 0x83, 0xec, 0x18,
        0x0f, 0x11, 0x14, 0x24,
        0x0f, 0x10, 0x1c, 0x24,
        0x48, 0x83, 0xc4, 0x18,
        0xc3,
    }, float_spill_bytes);
}

test "generic cfg selector encodes canonical vector mask operations" {
    var machine = x86_64_machine.MachineFunction.init("mask-ops", .void);
    defer machine.deinit(std.testing.allocator);
    try machine.instructions.appendSlice(std.testing.allocator, &.{
        .{ .andps_xmm = .{ .dst = .xmm2, .src = .xmm3 } },
        .{ .pxor_xmm = .{ .dst = .xmm6, .src = .xmm7 } },
        .{ .pcmpgtd_xmm = .{ .dst = .xmm4, .src = .xmm5 } },
        .{ .cmpeqps_xmm = .{ .dst = .xmm2, .src = .xmm3 } },
        .{ .cmpeqpd_xmm = .{ .dst = .xmm6, .src = .xmm7 } },
        .{ .movmskps_xmm_eax = .xmm4 },
        .{ .movmskpd_xmm_eax = .xmm5 },
        .ret,
    });
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x0f, 0x54, 0xd3,
        0x66, 0x0f, 0xef,
        0xf7, 0x66, 0x0f,
        0x66, 0xe5, 0x0f,
        0xc2, 0xd3, 0x00,
        0x66, 0x0f, 0xc2,
        0xf7, 0x00, 0x0f,
        0x50, 0xc4, 0x66,
        0x0f, 0x50, 0xc5,
        0xc3,
    }, bytes);
}

test "generic cfg selector lowers the bounded packed double shape" {
    const input =
        \\define double @packed(double %low, double %high) {
        \\entry:
        \\  %v0 = insertelement <2 x double> poison, double %low, i64 0
        \\  %v1 = insertelement <2 x double> %v0, double %high, i64 1
        \\  %sum = fadd <2 x double> %v1, <double 1.000000e+00, double 2.000000e+00>
        \\  %product = fmul <2 x double> %sum, <double 2.000000e+00, double 3.000000e+00>
        \\  %result = extractelement <2 x double> %product, i64 1
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("packed", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
}

test "generic cfg selector tracks defined packed double lanes and pair spill ownership" {
    var machine = x86_64_machine.MachineFunction.init("vector-shape", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 32;
    try selector_state.bindValueLoc(&selector, "low", .{ .xmm = .{ .reg = .xmm2, .bits = 64 } });

    try std.testing.expect((try selector_vector.lowerInsertElement(&selector, "lane1", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .vector = .poison,
        .value_ty = .double,
        .value = .{ .fp = "2.000000e+00" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 1 },
    })) == null);
    const lane1_shape = selector_state.valueLoc(&selector, "lane1").?.xmm.vectorShape().?;
    try std.testing.expectEqual(@as(u4, 0b10), lane1_shape.defined_lanes);

    try std.testing.expect((try selector_vector.lowerInsertElement(&selector, "pair", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .vector = .{ .named = "lane1" },
        .value_ty = .double,
        .value = .{ .named = "low" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 0 },
    })) == null);
    const pair_shape = selector_state.valueLoc(&selector, "pair").?.xmm.vectorShape().?;
    try std.testing.expectEqual(@as(u4, 0b11), pair_shape.defined_lanes);
    try std.testing.expect((try selector_vector.lowerBinary(&selector, "masked", .{
        .op = .fsub,
        .ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .lhs = .{ .named = "pair" },
        .rhs = .{ .vector = "<double 1.000000e+00, double poison>" },
    })) == null);
    const masked_shape = selector_state.valueLoc(&selector, "masked").?.xmm.vectorShape().?;
    try std.testing.expectEqual(@as(u4, 0b01), masked_shape.defined_lanes);
    const masked_reg = selector_state.valueLoc(&selector, "masked").?.xmm.reg;

    try std.testing.expect((try selector_state.spillValue(&selector, "masked")) == null);
    const spill = selector_state.valueLoc(&selector, "masked").?.spill_vector;
    try std.testing.expectEqual(selector_types.PairSpillLoc{ .lo = .slot0, .hi = .slot2 }, spill.frames);
    try std.testing.expectEqual(@as(usize, 2), selector.next_spill_slot);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_xmm128_rsp = .{ .frame_index = .slot0, .reg = masked_reg } }, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector records canonical mask definedness through pair spills" {
    var machine = x86_64_machine.MachineFunction.init("mask-shape", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 32;
    try selector_state.bindValueLoc(&selector, "lhs", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b01) },
    } });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b11) },
    } });
    try std.testing.expect((try selector_vector.lowerFcmp(&selector, "mask", .{
        .predicate = .oeq,
        .operand_ty = .{ .vector = .{ .len = 2, .elem_ty = .float } },
        .lhs = .{ .named = "lhs" },
        .rhs = .{ .named = "rhs" },
    })) == null);
    const shape = selector_state.valueLoc(&selector, "mask").?.xmm.vectorShape().?;
    try std.testing.expectEqual(selector_types.VectorShape.Kind.canonical_mask, shape.kind);
    try std.testing.expectEqual(@as(u16, 32), shape.lane_bits);
    try std.testing.expectEqual(@as(u4, 0b01), shape.defined_lanes);

    try std.testing.expect((try selector_vector.lowerExtractElement(&selector, "poisoned", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 1 } } },
        .vector = .{ .named = "mask" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 1 },
    })) != null);
    try std.testing.expect((try selector_state.spillValue(&selector, "mask")) == null);
    const spill = selector_state.valueLoc(&selector, "mask").?.spill_vector;
    try std.testing.expectEqual(selector_types.VectorShape.Kind.canonical_mask, spill.shape.kind);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_xmm128ps_rsp = .{ .frame_index = .slot0, .reg = .xmm2 } }, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector executes exact i64x2 constant lane extraction" {
    const input =
        \\define i64 @lane0(double %low, double %high) {
        \\entry:
        \\  %v0 = insertelement <2 x double> poison, double %low, i64 0
        \\  %v1 = insertelement <2 x double> %v0, double %high, i64 1
        \\  %bits = bitcast <2 x double> %v1 to <2 x i64>
        \\  %result = extractelement <2 x i64> %bits, i64 0
        \\  ret i64 %result
        \\}
        \\define i64 @lane1(double %low, double %high) {
        \\entry:
        \\  %v0 = insertelement <2 x double> poison, double %low, i64 0
        \\  %v1 = insertelement <2 x double> %v0, double %high, i64 1
        \\  %bits = bitcast <2 x double> %v1 to <2 x i64>
        \\  %result = extractelement <2 x i64> %bits, i64 1
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var mappings: [2]?[]align(std.heap.page_size_min) u8 = .{ null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (module.functions.items, 0..) |function_ir, index| {
        var machine = x86_64_machine.MachineFunction.init(function_ir.name, function_ir.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        mappings[index] = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mappings[index].?, bytes);
    }

    const lane0: *const fn (f64, f64) callconv(.c) u64 = @ptrCast(mappings[0].?.ptr);
    const lane1: *const fn (f64, f64) callconv(.c) u64 = @ptrCast(mappings[1].?.ptr);
    const cases = [_][2]u64{
        .{ 0, 0x8000_0000_0000_0000 },
        .{ 0x0000_0000_0000_0001, 0x000f_ffff_ffff_ffff },
        .{ 0x7ff0_0000_0000_0000, 0xfff0_0000_0000_0000 },
        .{ 0x7ff8_1234_5678_9abc, 0xfff0_0000_0000_0042 },
    };
    for (cases) |case| {
        const low: f64 = @bitCast(case[0]);
        const high: f64 = @bitCast(case[1]);
        try std.testing.expectEqual(case[0], lane0(low, high));
        try std.testing.expectEqual(case[1], lane1(low, high));
    }
}

test "generic cfg selector keeps partial and non-i64x2 extraction fail closed" {
    var machine = x86_64_machine.MachineFunction.init("i64x2-extract-near-miss", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "partial", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.i64x2(0b01) },
    } });
    try std.testing.expect((try selector_vector.lowerExtractElement(&selector, "partial-result", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } },
        .vector = .{ .named = "partial" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 0 },
    })) != null);
    try std.testing.expect((try selector_vector.lowerExtractElement(&selector, "dynamic-result", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } },
        .vector = .{ .named = "partial" },
        .index_ty = .{ .int = 64 },
        .index = .{ .named = "lane" },
    })) != null);
    try std.testing.expect((try selector_vector.lowerExtractElement(&selector, "wrong-width-result", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } },
        .vector = .{ .named = "partial" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 0 },
    })) != null);

    selector.stack_frame_bytes = 32;
    try selector_state.bindValueLoc(&selector, "spilled", .{ .spill_vector = .{
        .frames = .{ .lo = .slot0, .hi = .slot2 },
        .shape = selector_types.VectorShape.i64x2(0b11),
    } });
    try std.testing.expect((try selector_vector.lowerExtractElement(&selector, "spilled-result", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 64 } } },
        .vector = .{ .named = "spilled" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 1 },
    })) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_xmm128_rsp = .{ .frame_index = .slot0, .reg = .xmm1 } },
        .{ .unpckhpd_xmm = .{ .dst = .xmm1, .src = .xmm1 } },
        .{ .movq_xmm_rax = .xmm1 },
    }, machine.instructions.items[machine.instructions.items.len - 3 ..]);
}

test "generic cfg selector executes packed unsigned less-than without signed substitution" {
    const input =
        \\define i32 @packed_ult(i32 %lhs, i32 %rhs) {
        \\entry:
        \\  %lhs.fp = bitcast i32 %lhs to float
        \\  %lhs.seed = insertelement <2 x float> poison, float %lhs.fp, i64 0
        \\  %lhs.float-pair = insertelement <2 x float> %lhs.seed, float 0.000000e+00, i64 1
        \\  %lhs.pair = bitcast <2 x float> %lhs.float-pair to <2 x i32>
        \\  %rhs.fp = bitcast i32 %rhs to float
        \\  %rhs.seed = insertelement <2 x float> poison, float %rhs.fp, i64 0
        \\  %rhs.float-pair = insertelement <2 x float> %rhs.seed, float 0.000000e+00, i64 1
        \\  %rhs.pair = bitcast <2 x float> %rhs.float-pair to <2 x i32>
        \\  %mask = icmp samesign ult <2 x i32> %lhs.pair, %rhs.pair
        \\  %result = extractelement <2 x i1> %mask, i64 0
        \\  %wide = zext i1 %result to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("packed_ult", .{ .int = 1 });
    defer machine.deinit(std.testing.allocator);
    switch (try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0])) {
        .selected => {},
        .unsupported => |diagnostic| {
            std.debug.print("packed ult canary: {s}/{s}\n", .{ diagnostic.tagName(), diagnostic.detail() });
            return error.TestUnexpectedResult;
        },
    }
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const packed_ult: *const fn (u32, u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u32, 1), packed_ult(0, 1));
    try std.testing.expectEqual(@as(u32, 0), packed_ult(1, 0));
    try std.testing.expectEqual(@as(u32, 1), packed_ult(0x7fff_ffff, 0x8000_0000));
    try std.testing.expectEqual(@as(u32, 1), packed_ult(0x8000_0000, 0xffff_ffff));
    try std.testing.expectEqual(@as(u32, 0), packed_ult(0xffff_ffff, 0));
}

test "generic cfg selector propagates lane-shift definedness" {
    var machine = x86_64_machine.MachineFunction.init("vector-lane-shift", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "pair", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b11) },
    } });
    try selector_state.bindValueLoc(&selector, "lane0_only", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b01) },
    } });

    const lane_shift: ir.ShuffleVectorInst = .{
        .lhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .lhs = .{ .named = "pair" },
        .rhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .rhs = .poison,
        .mask_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } },
        .mask = .{ .vector = "<i32 1, i32 poison>" },
    };
    try std.testing.expect((try selector_vector.lowerShuffleVector(&selector, "shifted", lane_shift)) == null);
    const shifted = selector_state.valueLoc(&selector, "shifted").?.xmm;
    try std.testing.expectEqual(@as(u4, 0b01), shifted.vectorShape().?.defined_lanes);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .unpckhpd_xmm = .{ .dst = shifted.reg, .src = shifted.reg } }, machine.instructions.items[machine.instructions.items.len - 1]);

    var poisoned_shift = lane_shift;
    poisoned_shift.lhs = .{ .named = "lane0_only" };
    try std.testing.expect((try selector_vector.lowerShuffleVector(&selector, "poisoned_shift", poisoned_shift)) == null);
    try std.testing.expectEqual(@as(u4, 0), selector_state.valueLoc(&selector, "poisoned_shift").?.xmm.vectorShape().?.defined_lanes);
}

test "generic cfg selector lowers exact f64x2 lane zero-three shuffle" {
    var machine = x86_64_machine.MachineFunction.init("vector-cross-shuffle", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "lhs", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b01) },
    } });
    try selector_state.bindValueLoc(&selector, "rhs", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b10) },
    } });

    const shuffle: ir.ShuffleVectorInst = .{
        .lhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .lhs = .{ .named = "lhs" },
        .rhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .rhs = .{ .named = "rhs" },
        .mask_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } },
        .mask = .{ .vector = "<i32 0, i32 3>" },
    };
    try std.testing.expect((try selector_vector.lowerShuffleVector(&selector, "cross", shuffle)) == null);
    const cross = selector_state.valueLoc(&selector, "cross").?.xmm;
    try std.testing.expectEqual(@as(u4, 0b11), cross.vectorShape().?.defined_lanes);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .shufpd_xmm = .{ .dst = cross.reg, .src = .xmm3, .imm = 2 } }, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector propagates exact f64x2 self-shuffle lanes" {
    const Case = struct {
        mask: []const u8,
        expected_lanes: u4,
        immediate: u8,
    };
    inline for ([_]Case{
        .{ .mask = "<i32 1, i32 0>", .expected_lanes = 0b01, .immediate = 1 },
        .{ .mask = "<i32 1, i32 1>", .expected_lanes = 0b11, .immediate = 3 },
    }) |case| {
        var machine = x86_64_machine.MachineFunction.init("vector-self-shuffle", .void);
        defer machine.deinit(std.testing.allocator);
        var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "source", .{ .xmm = .{
            .reg = .xmm2,
            .bits = 128,
            .shape = .{ .vector = selector_types.VectorShape.f64x2(0b10) },
        } });
        const shuffle: ir.ShuffleVectorInst = .{
            .lhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
            .lhs = .{ .named = "source" },
            .rhs_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
            .rhs = .poison,
            .mask_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 32 } } },
            .mask = .{ .vector = case.mask },
        };
        try std.testing.expect((try selector_vector.lowerShuffleVector(&selector, "result", shuffle)) == null);
        const result = selector_state.valueLoc(&selector, "result").?.xmm;
        try std.testing.expectEqual(case.expected_lanes, result.vectorShape().?.defined_lanes);
        try std.testing.expectEqual(
            x86_64_machine.Instruction{ .shufpd_xmm = .{ .dst = result.reg, .src = result.reg, .imm = case.immediate } },
            machine.instructions.items[machine.instructions.items.len - 1],
        );
    }
}

test "generic cfg selector executes exact f64x2 lane zero-three shuffle bit exactly" {
    const input =
        \\define double @cross_shuffle_low(double %a0, double %a1, double %b0, double %b1) {
        \\entry:
        \\  %a.seed = insertelement <2 x double> poison, double %a0, i64 0
        \\  %a = insertelement <2 x double> %a.seed, double %a1, i64 1
        \\  %b.seed = insertelement <2 x double> poison, double %b0, i64 0
        \\  %b = insertelement <2 x double> %b.seed, double %b1, i64 1
        \\  %cross = shufflevector <2 x double> %a, <2 x double> %b, <2 x i32> <i32 0, i32 3>
        \\  %low = extractelement <2 x double> %cross, i64 0
        \\  ret double %low
        \\}
        \\define double @cross_shuffle_high(double %a0, double %a1, double %b0, double %b1) {
        \\entry:
        \\  %a.seed = insertelement <2 x double> poison, double %a0, i64 0
        \\  %a = insertelement <2 x double> %a.seed, double %a1, i64 1
        \\  %b.seed = insertelement <2 x double> poison, double %b0, i64 0
        \\  %b = insertelement <2 x double> %b.seed, double %b1, i64 1
        \\  %cross = shufflevector <2 x double> %a, <2 x double> %b, <2 x i32> <i32 0, i32 3>
        \\  %high = extractelement <2 x double> %cross, i64 1
        \\  ret double %high
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [2]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("cross_shuffle_low", .double),
        x86_64_machine.MachineFunction.init("cross_shuffle_high", .double),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [2]?[]align(std.heap.page_size_min) u8 = .{ null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const low: *const fn (f64, f64, f64, f64) callconv(.c) f64 = @ptrCast(mappings[0].?.ptr);
    const high: *const fn (f64, f64, f64, f64) callconv(.c) f64 = @ptrCast(mappings[1].?.ptr);

    inline for (.{
        .{ @as(u64, 0), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x3ff0_0000_0000_0000), @as(u64, 0xbff0_0000_0000_0000) },
        .{ @as(u64, 1), @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0xfff0_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0xfff8_9876_5432_1abc), @as(u64, 0x7ff0_0000_0000_0001), @as(u64, 0xfff0_0000_0000_0042) },
    }) |case| {
        const args: [4]f64 = .{ @bitCast(case[0]), @bitCast(case[1]), @bitCast(case[2]), @bitCast(case[3]) };
        try std.testing.expectEqual(case[0], @as(u64, @bitCast(low(args[0], args[1], args[2], args[3]))));
        try std.testing.expectEqual(case[3], @as(u64, @bitCast(high(args[0], args[1], args[2], args[3]))));
    }
}

test "generic cfg selector executes packed double construction and pressure spills bit exactly" {
    const input =
        \\define void @vector_canary(ptr %out, double %low, double %high) {
        \\entry:
        \\  %seed = insertelement <2 x double> poison, double %low, i64 0
        \\  %splat = shufflevector <2 x double> %seed, <2 x double> poison, <2 x i32> zeroinitializer
        \\  %pair = insertelement <2 x double> %seed, double %high, i64 1
        \\  %shift = shufflevector <2 x double> %pair, <2 x double> poison, <2 x i32> <i32 1, i32 poison>
        \\  %copy0 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy1 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy2 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy3 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy4 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy5 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy6 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %copy7 = insertelement <2 x double> %pair, double %high, i64 1
        \\  %sum = fadd <2 x double> %pair, <double 0.000000e+00, double 0.000000e+00>
        \\  %product = fmul <2 x double> %pair, <double 1.000000e+00, double 1.000000e+00>
        \\  %forward = fsub <2 x double> %pair, <double 0.000000e+00, double 0.000000e+00>
        \\  %reverse = fsub <2 x double> <double 0.000000e+00, double 0.000000e+00>, %pair
        \\  %s0 = extractelement <2 x double> %splat, i64 0
        \\  %s1 = extractelement <2 x double> %splat, i64 1
        \\  %p0 = extractelement <2 x double> %pair, i64 0
        \\  %p1 = extractelement <2 x double> %pair, i64 1
        \\  %a0 = extractelement <2 x double> %sum, i64 0
        \\  %a1 = extractelement <2 x double> %sum, i64 1
        \\  %m0 = extractelement <2 x double> %product, i64 0
        \\  %m1 = extractelement <2 x double> %product, i64 1
        \\  %c0 = extractelement <2 x double> %copy0, i64 0
        \\  %c1 = extractelement <2 x double> %copy1, i64 1
        \\  %c2 = extractelement <2 x double> %copy2, i64 0
        \\  %c3 = extractelement <2 x double> %copy3, i64 1
        \\  %c4 = extractelement <2 x double> %copy4, i64 0
        \\  %c5 = extractelement <2 x double> %copy5, i64 1
        \\  %c6 = extractelement <2 x double> %copy6, i64 0
        \\  %c7 = extractelement <2 x double> %copy7, i64 1
        \\  %h0 = extractelement <2 x double> %shift, i64 0
        \\  %f0 = extractelement <2 x double> %forward, i64 0
        \\  %f1 = extractelement <2 x double> %forward, i64 1
        \\  %r0 = extractelement <2 x double> %reverse, i64 0
        \\  %r1 = extractelement <2 x double> %reverse, i64 1
        \\  %b0 = bitcast double %s0 to i64
        \\  %b1 = bitcast double %s1 to i64
        \\  %b2 = bitcast double %p0 to i64
        \\  %b3 = bitcast double %p1 to i64
        \\  %b4 = bitcast double %a0 to i64
        \\  %b5 = bitcast double %a1 to i64
        \\  %b6 = bitcast double %m0 to i64
        \\  %b7 = bitcast double %m1 to i64
        \\  %b8 = bitcast double %c0 to i64
        \\  %b9 = bitcast double %c1 to i64
        \\  %b10 = bitcast double %c2 to i64
        \\  %b11 = bitcast double %c3 to i64
        \\  %b12 = bitcast double %c4 to i64
        \\  %b13 = bitcast double %c5 to i64
        \\  %b14 = bitcast double %c6 to i64
        \\  %b15 = bitcast double %c7 to i64
        \\  %b16 = bitcast double %h0 to i64
        \\  %b17 = bitcast double %f0 to i64
        \\  %b18 = bitcast double %f1 to i64
        \\  %b19 = bitcast double %r0 to i64
        \\  %b20 = bitcast double %r1 to i64
        \\  store i64 %b0, ptr %out, align 8
        \\  %o1 = getelementptr i8, ptr %out, i64 8
        \\  store i64 %b1, ptr %o1, align 8
        \\  %o2 = getelementptr i8, ptr %out, i64 16
        \\  store i64 %b2, ptr %o2, align 8
        \\  %o3 = getelementptr i8, ptr %out, i64 24
        \\  store i64 %b3, ptr %o3, align 8
        \\  %o4 = getelementptr i8, ptr %out, i64 32
        \\  store i64 %b4, ptr %o4, align 8
        \\  %o5 = getelementptr i8, ptr %out, i64 40
        \\  store i64 %b5, ptr %o5, align 8
        \\  %o6 = getelementptr i8, ptr %out, i64 48
        \\  store i64 %b6, ptr %o6, align 8
        \\  %o7 = getelementptr i8, ptr %out, i64 56
        \\  store i64 %b7, ptr %o7, align 8
        \\  %o8 = getelementptr i8, ptr %out, i64 64
        \\  store i64 %b8, ptr %o8, align 8
        \\  %o9 = getelementptr i8, ptr %out, i64 72
        \\  store i64 %b9, ptr %o9, align 8
        \\  %o10 = getelementptr i8, ptr %out, i64 80
        \\  store i64 %b10, ptr %o10, align 8
        \\  %o11 = getelementptr i8, ptr %out, i64 88
        \\  store i64 %b11, ptr %o11, align 8
        \\  %o12 = getelementptr i8, ptr %out, i64 96
        \\  store i64 %b12, ptr %o12, align 8
        \\  %o13 = getelementptr i8, ptr %out, i64 104
        \\  store i64 %b13, ptr %o13, align 8
        \\  %o14 = getelementptr i8, ptr %out, i64 112
        \\  store i64 %b14, ptr %o14, align 8
        \\  %o15 = getelementptr i8, ptr %out, i64 120
        \\  store i64 %b15, ptr %o15, align 8
        \\  %o16 = getelementptr i8, ptr %out, i64 128
        \\  store i64 %b16, ptr %o16, align 8
        \\  %o17 = getelementptr i8, ptr %out, i64 136
        \\  store i64 %b17, ptr %o17, align 8
        \\  %o18 = getelementptr i8, ptr %out, i64 144
        \\  store i64 %b18, ptr %o18, align 8
        \\  %o19 = getelementptr i8, ptr %out, i64 152
        \\  store i64 %b19, ptr %o19, align 8
        \\  %o20 = getelementptr i8, ptr %out, i64 160
        \\  store i64 %b20, ptr %o20, align 8
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("vector_canary", .void);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var saw_spill = false;
    var saw_reload = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm128_rsp => saw_spill = true,
        .reload_xmm128_rsp => saw_reload = true,
        else => {},
    };
    try std.testing.expect(saw_spill);
    try std.testing.expect(saw_reload);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const canary: *const fn (*[21]u64, f64, f64) callconv(.c) void = @ptrCast(mapping.ptr);

    inline for (.{
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0000) },
        .{ @as(u64, 0x3ff8_0000_0000_0000), @as(u64, 0xc002_0000_0000_0000), @as(u64, 0x3ff8_0000_0000_0000), @as(u64, 0xc002_0000_0000_0000), @as(u64, 0xbff8_0000_0000_0000), @as(u64, 0x4002_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x8000_0000_0000_0001), @as(u64, 0x0000_0000_0000_0001) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0xfff0_0000_0000_0000), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0xfff0_0000_0000_0000), @as(u64, 0xfff0_0000_0000_0000), @as(u64, 0x7ff0_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0xfff8_9876_5432_1abc), @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0xfff8_9876_5432_1abc), @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0xfff8_9876_5432_1abc) },
    }) |case| {
        const low: f64 = @bitCast(case[0]);
        const high: f64 = @bitCast(case[1]);
        var output: [21]u64 = undefined;
        canary(&output, low, high);
        const expected = [21]u64{
            case[0],             case[0],              case[0],             case[1],
            @bitCast(low + 0.0), @bitCast(high + 0.0), @bitCast(low * 1.0), @bitCast(high * 1.0),
            case[0],             case[1],              case[0],             case[1],
            case[0],             case[1],              case[0],             case[1],
            case[1],             case[2],              case[3],             case[4],
            case[5],
        };
        try std.testing.expectEqualSlices(u64, &expected, &output);
    }
}

test "generic cfg selector executes packed float construction and movups pressure spills bit exactly" {
    const input =
        \\define void @vector_f32_canary(ptr %out, float %low, float %high) {
        \\entry:
        \\  %seed = insertelement <2 x float> poison, float %low, i64 0
        \\  %splat = shufflevector <2 x float> %seed, <2 x float> poison, <2 x i32> zeroinitializer
        \\  %pair = insertelement <2 x float> %seed, float %high, i64 1
        \\  %shift = shufflevector <2 x float> %pair, <2 x float> poison, <2 x i32> <i32 1, i32 poison>
        \\  %copy0 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy1 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy2 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy3 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy4 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy5 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy6 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %copy7 = insertelement <2 x float> %pair, float %high, i64 1
        \\  %sum = fadd <2 x float> %pair, <float 0.000000e+00, float 0.000000e+00>
        \\  %product = fmul <2 x float> %pair, <float 1.000000e+00, float 1.000000e+00>
        \\  %forward = fsub <2 x float> %pair, <float 0.000000e+00, float 0.000000e+00>
        \\  %reverse = fsub <2 x float> <float 0.000000e+00, float 0.000000e+00>, %pair
        \\  %s0 = extractelement <2 x float> %splat, i64 0
        \\  %s1 = extractelement <2 x float> %splat, i64 1
        \\  %p0 = extractelement <2 x float> %pair, i64 0
        \\  %p1 = extractelement <2 x float> %pair, i64 1
        \\  %a0 = extractelement <2 x float> %sum, i64 0
        \\  %a1 = extractelement <2 x float> %sum, i64 1
        \\  %m0 = extractelement <2 x float> %product, i64 0
        \\  %m1 = extractelement <2 x float> %product, i64 1
        \\  %c0 = extractelement <2 x float> %copy0, i64 0
        \\  %c1 = extractelement <2 x float> %copy1, i64 1
        \\  %c2 = extractelement <2 x float> %copy2, i64 0
        \\  %c3 = extractelement <2 x float> %copy3, i64 1
        \\  %c4 = extractelement <2 x float> %copy4, i64 0
        \\  %c5 = extractelement <2 x float> %copy5, i64 1
        \\  %c6 = extractelement <2 x float> %copy6, i64 0
        \\  %c7 = extractelement <2 x float> %copy7, i64 1
        \\  %h0 = extractelement <2 x float> %shift, i64 0
        \\  %f0 = extractelement <2 x float> %forward, i64 0
        \\  %f1 = extractelement <2 x float> %forward, i64 1
        \\  %r0 = extractelement <2 x float> %reverse, i64 0
        \\  %r1 = extractelement <2 x float> %reverse, i64 1
        \\  %b0 = bitcast float %s0 to i32
        \\  %b1 = bitcast float %s1 to i32
        \\  %b2 = bitcast float %p0 to i32
        \\  %b3 = bitcast float %p1 to i32
        \\  %b4 = bitcast float %a0 to i32
        \\  %b5 = bitcast float %a1 to i32
        \\  %b6 = bitcast float %m0 to i32
        \\  %b7 = bitcast float %m1 to i32
        \\  %b8 = bitcast float %c0 to i32
        \\  %b9 = bitcast float %c1 to i32
        \\  %b10 = bitcast float %c2 to i32
        \\  %b11 = bitcast float %c3 to i32
        \\  %b12 = bitcast float %c4 to i32
        \\  %b13 = bitcast float %c5 to i32
        \\  %b14 = bitcast float %c6 to i32
        \\  %b15 = bitcast float %c7 to i32
        \\  %b16 = bitcast float %h0 to i32
        \\  %b17 = bitcast float %f0 to i32
        \\  %b18 = bitcast float %f1 to i32
        \\  %b19 = bitcast float %r0 to i32
        \\  %b20 = bitcast float %r1 to i32
        \\  store i32 %b0, ptr %out, align 4
        \\  %o1 = getelementptr i8, ptr %out, i64 4
        \\  store i32 %b1, ptr %o1, align 4
        \\  %o2 = getelementptr i8, ptr %out, i64 8
        \\  store i32 %b2, ptr %o2, align 4
        \\  %o3 = getelementptr i8, ptr %out, i64 12
        \\  store i32 %b3, ptr %o3, align 4
        \\  %o4 = getelementptr i8, ptr %out, i64 16
        \\  store i32 %b4, ptr %o4, align 4
        \\  %o5 = getelementptr i8, ptr %out, i64 20
        \\  store i32 %b5, ptr %o5, align 4
        \\  %o6 = getelementptr i8, ptr %out, i64 24
        \\  store i32 %b6, ptr %o6, align 4
        \\  %o7 = getelementptr i8, ptr %out, i64 28
        \\  store i32 %b7, ptr %o7, align 4
        \\  %o8 = getelementptr i8, ptr %out, i64 32
        \\  store i32 %b8, ptr %o8, align 4
        \\  %o9 = getelementptr i8, ptr %out, i64 36
        \\  store i32 %b9, ptr %o9, align 4
        \\  %o10 = getelementptr i8, ptr %out, i64 40
        \\  store i32 %b10, ptr %o10, align 4
        \\  %o11 = getelementptr i8, ptr %out, i64 44
        \\  store i32 %b11, ptr %o11, align 4
        \\  %o12 = getelementptr i8, ptr %out, i64 48
        \\  store i32 %b12, ptr %o12, align 4
        \\  %o13 = getelementptr i8, ptr %out, i64 52
        \\  store i32 %b13, ptr %o13, align 4
        \\  %o14 = getelementptr i8, ptr %out, i64 56
        \\  store i32 %b14, ptr %o14, align 4
        \\  %o15 = getelementptr i8, ptr %out, i64 60
        \\  store i32 %b15, ptr %o15, align 4
        \\  %o16 = getelementptr i8, ptr %out, i64 64
        \\  store i32 %b16, ptr %o16, align 4
        \\  %o17 = getelementptr i8, ptr %out, i64 68
        \\  store i32 %b17, ptr %o17, align 4
        \\  %o18 = getelementptr i8, ptr %out, i64 72
        \\  store i32 %b18, ptr %o18, align 4
        \\  %o19 = getelementptr i8, ptr %out, i64 76
        \\  store i32 %b19, ptr %o19, align 4
        \\  %o20 = getelementptr i8, ptr %out, i64 80
        \\  store i32 %b20, ptr %o20, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = x86_64_machine.MachineFunction.init("vector_f32_canary", .void);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var saw_spill = false;
    var saw_reload = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm128ps_rsp => saw_spill = true,
        .reload_xmm128ps_rsp => saw_reload = true,
        else => {},
    };
    try std.testing.expect(saw_spill);
    try std.testing.expect(saw_reload);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const canary: *const fn (*[21]u32, f32, f32) callconv(.c) void = @ptrCast(mapping.ptr);

    inline for (.{
        .{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0000), @as(u32, 0x0000_0000) },
        .{ @as(u32, 0x3fc0_0000), @as(u32, 0xc010_0000), @as(u32, 0x3fc0_0000), @as(u32, 0xc010_0000), @as(u32, 0xbfc0_0000), @as(u32, 0x4010_0000) },
        .{ @as(u32, 0x0000_0001), @as(u32, 0x8000_0001), @as(u32, 0x0000_0001), @as(u32, 0x8000_0001), @as(u32, 0x8000_0001), @as(u32, 0x0000_0001) },
        .{ @as(u32, 0x7f80_0000), @as(u32, 0xff80_0000), @as(u32, 0x7f80_0000), @as(u32, 0xff80_0000), @as(u32, 0xff80_0000), @as(u32, 0x7f80_0000) },
        .{ @as(u32, 0x7fc1_2345), @as(u32, 0xffc5_4321), @as(u32, 0x7fc1_2345), @as(u32, 0xffc5_4321), @as(u32, 0x7fc1_2345), @as(u32, 0xffc5_4321) },
    }) |case| {
        const low: f32 = @bitCast(case[0]);
        const high: f32 = @bitCast(case[1]);
        var output: [21]u32 = undefined;
        canary(&output, low, high);
        const expected = [21]u32{
            case[0],             case[0],              case[0],             case[1],
            @bitCast(low + 0.0), @bitCast(high + 0.0), @bitCast(low * 1.0), @bitCast(high * 1.0),
            case[0],             case[1],              case[0],             case[1],
            case[0],             case[1],              case[0],             case[1],
            case[1],             case[2],              case[3],             case[4],
            case[5],
        };
        try std.testing.expectEqualSlices(u32, &expected, &output);
    }
}

test "generic cfg selector executes canonical mask slice and unordsf2 bit exactly" {
    const input =
        \\declare <2 x float> @llvm.fabs.v2f32(<2 x float>)
        \\define i32 @unordsf2(float %a, float %b) {
        \\entry:
        \\  %seed = insertelement <2 x float> poison, float %b, i64 0
        \\  %pair = insertelement <2 x float> %seed, float %a, i64 1
        \\  %absolute = tail call <2 x float> @llvm.fabs.v2f32(<2 x float> %pair)
        \\  %bits = bitcast <2 x float> %absolute to <2 x i32>
        \\  %unordered = icmp samesign ugt <2 x i32> %bits, splat (i32 2139095040)
        \\  %lane0 = extractelement <2 x i1> %unordered, i64 0
        \\  %lane1 = extractelement <2 x i1> %unordered, i64 1
        \\  %either = select i1 %lane1, i1 true, i1 %lane0
        \\  %result = zext i1 %either to i32
        \\  ret i32 %result
        \\}
        \\define i32 @fabs_lane0_bits(float %a, float %b) {
        \\entry:
        \\  %seed = insertelement <2 x float> poison, float %a, i64 0
        \\  %pair = insertelement <2 x float> %seed, float %b, i64 1
        \\  %absolute = call <2 x float> @llvm.fabs.v2f32(<2 x float> %pair)
        \\  %lane = extractelement <2 x float> %absolute, i64 0
        \\  %bits = bitcast float %lane to i32
        \\  ret i32 %bits
        \\}
        \\define i32 @fabs_lane1_bits(float %a, float %b) {
        \\entry:
        \\  %seed = insertelement <2 x float> poison, float %a, i64 0
        \\  %pair = insertelement <2 x float> %seed, float %b, i64 1
        \\  %absolute = call <2 x float> @llvm.fabs.v2f32(<2 x float> %pair)
        \\  %lane = extractelement <2 x float> %absolute, i64 1
        \\  %bits = bitcast float %lane to i32
        \\  ret i32 %bits
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [3]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("unordsf2", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("fabs_lane0_bits", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("fabs_lane1_bits", .{ .int = 32 }),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [3]?[]align(std.heap.page_size_min) u8 = .{ null, null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const unordsf2: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[0].?.ptr);
    const fabs_lane0: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[1].?.ptr);
    const fabs_lane1: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[2].?.ptr);

    const Cases = [_]struct { a: u32, b: u32, expected: u32 }{
        .{ .a = 0x0000_0000, .b = 0x8000_0000, .expected = 0 },
        .{ .a = 0x0000_0001, .b = 0x807f_ffff, .expected = 0 },
        .{ .a = 0x3f80_0000, .b = 0xc020_0000, .expected = 0 },
        .{ .a = 0x7f80_0000, .b = 0xff80_0000, .expected = 0 },
        .{ .a = 0x7fc1_2345, .b = 0x3f80_0000, .expected = 1 },
        .{ .a = 0x3f80_0000, .b = 0xffc5_4321, .expected = 1 },
        .{ .a = 0x7f80_0001, .b = 0xff80_0042, .expected = 1 },
        .{ .a = 0xffc1_2345, .b = 0x7fc5_4321, .expected = 1 },
    };
    for (Cases) |case| {
        const a: f32 = @bitCast(case.a);
        const b: f32 = @bitCast(case.b);
        try std.testing.expectEqual(case.expected, unordsf2(a, b));
        try std.testing.expectEqual(case.a & 0x7fff_ffff, fabs_lane0(a, b));
        try std.testing.expectEqual(case.b & 0x7fff_ffff, fabs_lane1(a, b));
    }
}

test "generic cfg selector executes packed oeq masks at both admitted lane widths" {
    const input =
        \\define i32 @oeq_f32(float %a, float %b) {
        \\entry:
        \\  %va = insertelement <2 x float> poison, float %a, i64 0
        \\  %vb = insertelement <2 x float> poison, float %b, i64 0
        \\  %mask = fcmp oeq <2 x float> %va, %vb
        \\  %result = extractelement <2 x i1> %mask, i64 0
        \\  %wide = zext i1 %result to i32
        \\  ret i32 %wide
        \\}
        \\define i32 @oeq_f64(double %a, double %b) {
        \\entry:
        \\  %va = insertelement <2 x double> poison, double %a, i64 0
        \\  %vb = insertelement <2 x double> poison, double %b, i64 0
        \\  %mask = fcmp oeq <2 x double> %va, %vb
        \\  %result = extractelement <2 x i1> %mask, i64 0
        \\  %wide = zext i1 %result to i32
        \\  ret i32 %wide
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [2]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("oeq_f32", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("oeq_f64", .{ .int = 32 }),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [2]?[]align(std.heap.page_size_min) u8 = .{ null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        try std.testing.expectEqual(selector_impl.SelectionResult.selected, try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function));
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const oeq_f32: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[0].?.ptr);
    const oeq_f64: *const fn (f64, f64) callconv(.c) u32 = @ptrCast(mappings[1].?.ptr);
    try std.testing.expectEqual(@as(u32, 1), oeq_f32(0.0, -0.0));
    try std.testing.expectEqual(@as(u32, 0), oeq_f32(1.0, 2.0));
    try std.testing.expectEqual(@as(u32, 0), oeq_f32(@bitCast(@as(u32, 0x7fc1_2345)), @bitCast(@as(u32, 0x7fc1_2345))));
    try std.testing.expectEqual(@as(u32, 1), oeq_f64(0.0, -0.0));
    try std.testing.expectEqual(@as(u32, 0), oeq_f64(1.0, 2.0));
    try std.testing.expectEqual(@as(u32, 0), oeq_f64(@bitCast(@as(u64, 0x7ff8_1234_5678_9abc)), @bitCast(@as(u64, 0x7ff8_1234_5678_9abc))));
}

test "generic cfg selector executes the complete f32x4 mulsc3 vector slice bit exactly" {
    const input =
        \\declare <4 x float> @llvm.fabs.v4f32(<4 x float>)
        \\declare float @llvm.copysign.f32(float, float)
        \\define i32 @arithmetic(float %a, float %b, float %c, float %d) {
        \\entry:
        \\  %a0 = insertelement <4 x float> poison, float %a, i64 0
        \\  %a1 = insertelement <4 x float> %a0, float %b, i64 1
        \\  %left = shufflevector <4 x float> %a1, <4 x float> poison, <4 x i32> <i32 0, i32 1, i32 1, i32 0>
        \\  %b0 = insertelement <4 x float> poison, float %c, i64 0
        \\  %b1 = insertelement <4 x float> %b0, float %d, i64 1
        \\  %right = shufflevector <4 x float> %b1, <4 x float> poison, <4 x i32> <i32 0, i32 1, i32 0, i32 1>
        \\  %products = fmul <4 x float> %left, %right
        \\  %lane1 = shufflevector <4 x float> %products, <4 x float> poison, <4 x i32> <i32 1, i32 poison, i32 poison, i32 poison>
        \\  %difference = fsub <4 x float> %products, %lane1
        \\  %real = extractelement <4 x float> %difference, i64 0
        \\  %lane3 = shufflevector <4 x float> %products, <4 x float> poison, <4 x i32> <i32 poison, i32 poison, i32 3, i32 poison>
        \\  %sum = fadd <4 x float> %products, %lane3
        \\  %imaginary = extractelement <4 x float> %sum, i64 2
        \\  %combined = fadd float %real, %imaginary
        \\  %bits = bitcast float %combined to i32
        \\  ret i32 %bits
        \\}
        \\define i32 @infinity_mask(float %a, float %b) {
        \\entry:
        \\  %seed = insertelement <4 x float> poison, float %a, i64 0
        \\  %pair = insertelement <4 x float> %seed, float %b, i64 1
        \\  %lanes = shufflevector <4 x float> %pair, <4 x float> poison, <4 x i32> <i32 0, i32 1, i32 1, i32 0>
        \\  %absolute = call <4 x float> @llvm.fabs.v4f32(<4 x float> %lanes)
        \\  %infinite = fcmp oeq <4 x float> %absolute, splat (float 0x7FF0000000000000)
        \\  %bits = bitcast <4 x i1> %infinite to i4
        \\  %wide = zext i4 %bits to i32
        \\  ret i32 %wide
        \\}
        \\define i32 @copysign_bits(float %magnitude, float %sign) {
        \\entry:
        \\  %value = tail call float @llvm.copysign.f32(float %magnitude, float %sign)
        \\  %bits = bitcast float %value to i32
        \\  ret i32 %bits
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [3]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("arithmetic", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("infinity_mask", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("copysign_bits", .{ .int = 32 }),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [3]?[]align(std.heap.page_size_min) u8 = .{ null, null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        switch (try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("f32x4 canary {s}: {s}/{s}\n", .{ function.name, diagnostic.tagName(), diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const arithmetic: *const fn (f32, f32, f32, f32) callconv(.c) u32 = @ptrCast(mappings[0].?.ptr);
    const infinity_mask: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[1].?.ptr);
    const copysign_bits: *const fn (f32, f32) callconv(.c) u32 = @ptrCast(mappings[2].?.ptr);

    try std.testing.expectEqual(@as(u32, 0x4190_0000), arithmetic(2.0, 3.0, 5.0, 7.0));
    try std.testing.expectEqual(@as(u32, 0), arithmetic(0.0, -0.0, 1.0, 1.0));
    try std.testing.expectEqual(@as(u32, 0b1001), infinity_mask(std.math.inf(f32), 1.0));
    try std.testing.expectEqual(@as(u32, 0b0110), infinity_mask(1.0, -std.math.inf(f32)));
    try std.testing.expectEqual(@as(u32, 0), infinity_mask(@bitCast(@as(u32, 0x7fc1_2345)), 1.0));

    const CopySignCase = struct { magnitude: u32, sign: u32, expected: u32 };
    const copy_sign_cases = [_]CopySignCase{
        .{ .magnitude = 0x0000_0000, .sign = 0x8000_0000, .expected = 0x8000_0000 },
        .{ .magnitude = 0x8000_0001, .sign = 0x0000_0000, .expected = 0x0000_0001 },
        .{ .magnitude = 0x7f80_0000, .sign = 0xff80_0000, .expected = 0xff80_0000 },
        .{ .magnitude = 0xffc1_2345, .sign = 0x3f80_0000, .expected = 0x7fc1_2345 },
        .{ .magnitude = 0x7f80_0042, .sign = 0xbf80_0000, .expected = 0xff80_0042 },
    };
    for (copy_sign_cases) |case| {
        try std.testing.expectEqual(case.expected, copysign_bits(@bitCast(case.magnitude), @bitCast(case.sign)));
    }
}

test "generic cfg selector executes canonical f32x2 select and copysign bit exactly" {
    const input =
        \\declare <2 x float> @llvm.copysign.v2f32(<2 x float>, <2 x float>)
        \\define i32 @lane0(float %ca0, float %ca1, float %cb0, float %cb1, float %m0, float %m1, float %s0, float %s1) {
        \\entry:
        \\  %ca.seed = insertelement <2 x float> poison, float %ca0, i64 0
        \\  %ca = insertelement <2 x float> %ca.seed, float %ca1, i64 1
        \\  %cb.seed = insertelement <2 x float> poison, float %cb0, i64 0
        \\  %cb = insertelement <2 x float> %cb.seed, float %cb1, i64 1
        \\  %mask = fcmp oeq <2 x float> %ca, %cb
        \\  %m.seed = insertelement <2 x float> poison, float %m0, i64 0
        \\  %m = insertelement <2 x float> %m.seed, float %m1, i64 1
        \\  %selected = select <2 x i1> %mask, <2 x float> %m, <2 x float> splat (float 1.000000e+00)
        \\  %s.seed = insertelement <2 x float> poison, float %s0, i64 0
        \\  %s = insertelement <2 x float> %s.seed, float %s1, i64 1
        \\  %signed = call <2 x float> @llvm.copysign.v2f32(<2 x float> %selected, <2 x float> %s)
        \\  %lane = extractelement <2 x float> %signed, i64 0
        \\  %bits = bitcast float %lane to i32
        \\  ret i32 %bits
        \\}
        \\define i32 @lane1(float %ca0, float %ca1, float %cb0, float %cb1, float %m0, float %m1, float %s0, float %s1) {
        \\entry:
        \\  %ca.seed = insertelement <2 x float> poison, float %ca0, i64 0
        \\  %ca = insertelement <2 x float> %ca.seed, float %ca1, i64 1
        \\  %cb.seed = insertelement <2 x float> poison, float %cb0, i64 0
        \\  %cb = insertelement <2 x float> %cb.seed, float %cb1, i64 1
        \\  %mask = fcmp oeq <2 x float> %ca, %cb
        \\  %m.seed = insertelement <2 x float> poison, float %m0, i64 0
        \\  %m = insertelement <2 x float> %m.seed, float %m1, i64 1
        \\  %selected = select <2 x i1> %mask, <2 x float> %m, <2 x float> splat (float 1.000000e+00)
        \\  %s.seed = insertelement <2 x float> poison, float %s0, i64 0
        \\  %s = insertelement <2 x float> %s.seed, float %s1, i64 1
        \\  %signed = tail call <2 x float> @llvm.copysign.v2f32(<2 x float> %selected, <2 x float> %s)
        \\  %lane = extractelement <2 x float> %signed, i64 1
        \\  %bits = bitcast float %lane to i32
        \\  ret i32 %bits
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [2]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("lane0", .{ .int = 32 }),
        x86_64_machine.MachineFunction.init("lane1", .{ .int = 32 }),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [2]?[]align(std.heap.page_size_min) u8 = .{ null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        switch (try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("f32x2 select/copysign canary {s}: {s}/{s}\n", .{ function.name, diagnostic.tagName(), diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const Fn = *const fn (f32, f32, f32, f32, f32, f32, f32, f32) callconv(.c) u32;
    const lane0: Fn = @ptrCast(mappings[0].?.ptr);
    const lane1: Fn = @ptrCast(mappings[1].?.ptr);

    const Case = struct {
        equal0: bool,
        equal1: bool,
        magnitude0: u32,
        magnitude1: u32,
        sign0: u32,
        sign1: u32,
    };
    const cases = [_]Case{
        .{ .equal0 = false, .equal1 = false, .magnitude0 = 0, .magnitude1 = 0x8000_0001, .sign0 = 0x8000_0000, .sign1 = 0 },
        .{ .equal0 = true, .equal1 = false, .magnitude0 = 0x0000_0001, .magnitude1 = 0x7f80_0000, .sign0 = 0x8000_0000, .sign1 = 0xff80_0000 },
        .{ .equal0 = false, .equal1 = true, .magnitude0 = 0xff80_0000, .magnitude1 = 0xffc1_2345, .sign0 = 0, .sign1 = 0x3f80_0000 },
        .{ .equal0 = true, .equal1 = true, .magnitude0 = 0x7f80_0042, .magnitude1 = 0xff80_0042, .sign0 = 0xbf80_0000, .sign1 = 0 },
    };
    for (cases) |case| {
        const ca0: f32 = 2.0;
        const ca1: f32 = 3.0;
        const cb0: f32 = if (case.equal0) ca0 else 4.0;
        const cb1: f32 = if (case.equal1) ca1 else 5.0;
        const m0: f32 = @bitCast(case.magnitude0);
        const m1: f32 = @bitCast(case.magnitude1);
        const s0: f32 = @bitCast(case.sign0);
        const s1: f32 = @bitCast(case.sign1);
        const selected0 = if (case.equal0) case.magnitude0 else @as(u32, 0x3f80_0000);
        const selected1 = if (case.equal1) case.magnitude1 else @as(u32, 0x3f80_0000);
        try std.testing.expectEqual((selected0 & 0x7fff_ffff) | (case.sign0 & 0x8000_0000), lane0(ca0, ca1, cb0, cb1, m0, m1, s0, s1));
        try std.testing.expectEqual((selected1 & 0x7fff_ffff) | (case.sign1 & 0x8000_0000), lane1(ca0, ca1, cb0, cb1, m0, m1, s0, s1));
    }
}

test "generic cfg selector executes f64x2 parity operations bit exactly" {
    const input =
        \\declare <2 x double> @llvm.fabs.v2f64(<2 x double>)
        \\declare <2 x double> @llvm.copysign.v2f64(<2 x double>, <2 x double>)
        \\declare double @llvm.copysign.f64(double, double)
        \\define i64 @swap_low(double %ca0, double %ca1, double %cb0, double %cb1, double %m0, double %m1, double %s0, double %s1) {
        \\entry:
        \\  %ca.seed = insertelement <2 x double> poison, double %ca0, i64 0
        \\  %ca = insertelement <2 x double> %ca.seed, double %ca1, i64 1
        \\  %cb.seed = insertelement <2 x double> poison, double %cb0, i64 0
        \\  %cb = insertelement <2 x double> %cb.seed, double %cb1, i64 1
        \\  %mask = fcmp oeq <2 x double> %ca, %cb
        \\  %m.seed = insertelement <2 x double> poison, double %m0, i64 0
        \\  %m = insertelement <2 x double> %m.seed, double %m1, i64 1
        \\  %selected = select <2 x i1> %mask, <2 x double> %m, <2 x double> splat (double 1.000000e+00)
        \\  %absolute = call <2 x double> @llvm.fabs.v2f64(<2 x double> %selected)
        \\  %s.seed = insertelement <2 x double> poison, double %s0, i64 0
        \\  %s = insertelement <2 x double> %s.seed, double %s1, i64 1
        \\  %signed = tail call <2 x double> @llvm.copysign.v2f64(<2 x double> %absolute, <2 x double> %s)
        \\  %swap = shufflevector <2 x double> %signed, <2 x double> poison, <2 x i32> <i32 1, i32 0>
        \\  %lane = extractelement <2 x double> %swap, i64 0
        \\  %bits = bitcast double %lane to i64
        \\  ret i64 %bits
        \\}
        \\define i64 @swap_high(double %ca0, double %ca1, double %cb0, double %cb1, double %m0, double %m1, double %s0, double %s1) {
        \\entry:
        \\  %ca.seed = insertelement <2 x double> poison, double %ca0, i64 0
        \\  %ca = insertelement <2 x double> %ca.seed, double %ca1, i64 1
        \\  %cb.seed = insertelement <2 x double> poison, double %cb0, i64 0
        \\  %cb = insertelement <2 x double> %cb.seed, double %cb1, i64 1
        \\  %mask = fcmp oeq <2 x double> %ca, %cb
        \\  %m.seed = insertelement <2 x double> poison, double %m0, i64 0
        \\  %m = insertelement <2 x double> %m.seed, double %m1, i64 1
        \\  %selected = select <2 x i1> %mask, <2 x double> %m, <2 x double> splat (double 1.000000e+00)
        \\  %absolute = call <2 x double> @llvm.fabs.v2f64(<2 x double> %selected)
        \\  %s.seed = insertelement <2 x double> poison, double %s0, i64 0
        \\  %s = insertelement <2 x double> %s.seed, double %s1, i64 1
        \\  %signed = tail call <2 x double> @llvm.copysign.v2f64(<2 x double> %absolute, <2 x double> %s)
        \\  %swap = shufflevector <2 x double> %signed, <2 x double> poison, <2 x i32> <i32 1, i32 0>
        \\  %lane = extractelement <2 x double> %swap, i64 1
        \\  %bits = bitcast double %lane to i64
        \\  ret i64 %bits
        \\}
        \\define i64 @splat_high(double %ca0, double %ca1, double %cb0, double %cb1, double %m0, double %m1, double %s0, double %s1) {
        \\entry:
        \\  %ca.seed = insertelement <2 x double> poison, double %ca0, i64 0
        \\  %ca = insertelement <2 x double> %ca.seed, double %ca1, i64 1
        \\  %cb.seed = insertelement <2 x double> poison, double %cb0, i64 0
        \\  %cb = insertelement <2 x double> %cb.seed, double %cb1, i64 1
        \\  %mask = fcmp oeq <2 x double> %ca, %cb
        \\  %m.seed = insertelement <2 x double> poison, double %m0, i64 0
        \\  %m = insertelement <2 x double> %m.seed, double %m1, i64 1
        \\  %selected = select <2 x i1> %mask, <2 x double> %m, <2 x double> splat (double 1.000000e+00)
        \\  %absolute = call <2 x double> @llvm.fabs.v2f64(<2 x double> %selected)
        \\  %s.seed = insertelement <2 x double> poison, double %s0, i64 0
        \\  %s = insertelement <2 x double> %s.seed, double %s1, i64 1
        \\  %signed = tail call <2 x double> @llvm.copysign.v2f64(<2 x double> %absolute, <2 x double> %s)
        \\  %splat = shufflevector <2 x double> %signed, <2 x double> poison, <2 x i32> <i32 1, i32 1>
        \\  %lane = extractelement <2 x double> %splat, i64 1
        \\  %bits = bitcast double %lane to i64
        \\  ret i64 %bits
        \\}
        \\define i64 @scalar(double %magnitude, double %sign) {
        \\entry:
        \\  %value = tail call double @llvm.copysign.f64(double %magnitude, double %sign)
        \\  %bits = bitcast double %value to i64
        \\  ret i64 %bits
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machines: [4]x86_64_machine.MachineFunction = .{
        x86_64_machine.MachineFunction.init("swap_low", .{ .int = 64 }),
        x86_64_machine.MachineFunction.init("swap_high", .{ .int = 64 }),
        x86_64_machine.MachineFunction.init("splat_high", .{ .int = 64 }),
        x86_64_machine.MachineFunction.init("scalar", .{ .int = 64 }),
    };
    defer for (&machines) |*machine| machine.deinit(std.testing.allocator);
    var mappings: [4]?[]align(std.heap.page_size_min) u8 = .{ null, null, null, null };
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (&machines, module.functions.items, &mappings) |*machine, function, *mapping| {
        switch (try selector_impl.tryLowerComposedCfg(std.testing.allocator, machine, function)) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("f64x2 parity canary {s}: {s}/{s}\n", .{ function.name, diagnostic.tagName(), diagnostic.detail() });
                return error.TestUnexpectedResult;
            },
        }
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine.*);
        defer std.testing.allocator.free(bytes);
        mapping.* = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mapping.*.?, bytes);
    }
    const VectorFn = *const fn (f64, f64, f64, f64, f64, f64, f64, f64) callconv(.c) u64;
    const swap_low: VectorFn = @ptrCast(mappings[0].?.ptr);
    const swap_high: VectorFn = @ptrCast(mappings[1].?.ptr);
    const splat_high: VectorFn = @ptrCast(mappings[2].?.ptr);
    const scalar: *const fn (f64, f64) callconv(.c) u64 = @ptrCast(mappings[3].?.ptr);

    const Case = struct {
        equal0: bool,
        equal1: bool,
        magnitude0: u64,
        magnitude1: u64,
        sign0: u64,
        sign1: u64,
    };
    const cases = [_]Case{
        .{ .equal0 = false, .equal1 = false, .magnitude0 = 0x8000_0000_0000_0000, .magnitude1 = 0x8000_0000_0000_0001, .sign0 = 0x8000_0000_0000_0000, .sign1 = 0 },
        .{ .equal0 = true, .equal1 = false, .magnitude0 = 0x8000_0000_0000_0001, .magnitude1 = 0x7ff0_0000_0000_0000, .sign0 = 0x8000_0000_0000_0000, .sign1 = 0xfff0_0000_0000_0000 },
        .{ .equal0 = false, .equal1 = true, .magnitude0 = 0xfff0_0000_0000_0000, .magnitude1 = 0xfff8_1234_5678_9abc, .sign0 = 0, .sign1 = 0x3ff0_0000_0000_0000 },
        .{ .equal0 = true, .equal1 = true, .magnitude0 = 0x7ff0_0000_0000_0042, .magnitude1 = 0xfff0_0000_0000_0042, .sign0 = 0xbff0_0000_0000_0000, .sign1 = 0 },
    };
    for (cases) |case| {
        const ca0: f64 = 2.0;
        const ca1: f64 = 3.0;
        const cb0: f64 = if (case.equal0) ca0 else 4.0;
        const cb1: f64 = if (case.equal1) ca1 else 5.0;
        const args: [8]f64 = .{ ca0, ca1, cb0, cb1, @bitCast(case.magnitude0), @bitCast(case.magnitude1), @bitCast(case.sign0), @bitCast(case.sign1) };
        const selected0 = if (case.equal0) case.magnitude0 else @as(u64, 0x3ff0_0000_0000_0000);
        const selected1 = if (case.equal1) case.magnitude1 else @as(u64, 0x3ff0_0000_0000_0000);
        const expected0 = (selected0 & 0x7fff_ffff_ffff_ffff) | (case.sign0 & 0x8000_0000_0000_0000);
        const expected1 = (selected1 & 0x7fff_ffff_ffff_ffff) | (case.sign1 & 0x8000_0000_0000_0000);
        try std.testing.expectEqual(expected1, swap_low(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
        try std.testing.expectEqual(expected0, swap_high(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
        try std.testing.expectEqual(expected1, splat_high(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]));
    }

    inline for ([_]struct { magnitude: u64, sign: u64, expected: u64 }{
        .{ .magnitude = 0x8000_0000_0000_0000, .sign = 0, .expected = 0 },
        .{ .magnitude = 1, .sign = 0x8000_0000_0000_0000, .expected = 0x8000_0000_0000_0001 },
        .{ .magnitude = 0x7ff0_0000_0000_0000, .sign = 0xfff0_0000_0000_0000, .expected = 0xfff0_0000_0000_0000 },
        .{ .magnitude = 0xfff8_1234_5678_9abc, .sign = 0x3ff0_0000_0000_0000, .expected = 0x7ff8_1234_5678_9abc },
        .{ .magnitude = 0x7ff0_0000_0000_0042, .sign = 0xbff0_0000_0000_0000, .expected = 0xfff0_0000_0000_0042 },
    }) |case| {
        try std.testing.expectEqual(case.expected, scalar(@bitCast(case.magnitude), @bitCast(case.sign)));
    }
}

test "generic cfg selector rejects partial and noncanonical f32x2 selects" {
    var machine = x86_64_machine.MachineFunction.init("bad-vector-select", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = state_data.ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "mask", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.mask32x2(0b01) },
    } });
    try selector_state.bindValueLoc(&selector, "true", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b11) },
    } });
    try selector_state.bindValueLoc(&selector, "false", .{ .xmm = .{
        .reg = .xmm4,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b11) },
    } });
    var select: ir.SelectInst = .{
        .cond_ty = .{ .vector = .{ .len = 2, .elem_ty = .{ .int = 1 } } },
        .cond = .{ .named = "mask" },
        .ty = .{ .vector = .{ .len = 2, .elem_ty = .float } },
        .true_value = .{ .named = "true" },
        .false_value = .{ .named = "false" },
    };
    try std.testing.expect((try selector_vector.lowerSelect(&selector, "partial-mask", select)) != null);

    try selector_state.bindValueLoc(&selector, "mask", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.i32x2(0b11) },
    } });
    try std.testing.expect((try selector_vector.lowerSelect(&selector, "data-mask", select)) != null);

    try selector_state.bindValueLoc(&selector, "mask", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.mask32x2(0b11) },
    } });
    try selector_state.bindValueLoc(&selector, "true", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b01) },
    } });
    try std.testing.expect((try selector_vector.lowerSelect(&selector, "partial-data", select)) != null);

    select.ty = .{ .vector = .{ .len = 2, .elem_ty = .double } };
    try selector_state.bindValueLoc(&selector, "mask", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.mask64x2(0b01) },
    } });
    try selector_state.bindValueLoc(&selector, "true", .{ .xmm = .{
        .reg = .xmm3,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b11) },
    } });
    try selector_state.bindValueLoc(&selector, "false", .{ .xmm = .{
        .reg = .xmm4,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f64x2(0b11) },
    } });
    try std.testing.expect((try selector_vector.lowerSelect(&selector, "partial-f64-mask", select)) != null);

    try selector_state.bindValueLoc(&selector, "mask", .{ .xmm = .{
        .reg = .xmm2,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.mask32x2(0b11) },
    } });
    try std.testing.expect((try selector_vector.lowerSelect(&selector, "wrong-f64-mask-width", select)) != null);
}

test "generic cfg selector fails closed outside the bounded vector slice" {
    const Case = struct { ir_text: []const u8, tag: std.meta.Tag(inspection.Diagnostic), detail: []const u8 };
    const cases = [_]Case{
        .{ .ir_text =
        \\define double @bad(double %x, i64 %lane) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 %lane
        \\  %r = extractelement <2 x double> %v, i64 0
        \\  ret double %r
        \\}
        , .tag = .unsupported_instruction, .detail = "insertelement-dynamic-index" },
        .{ .ir_text =
        \\define double @bad(double %x, i64 %lane) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = extractelement <2 x double> %v, i64 %lane
        \\  ret double %r
        \\}
        , .tag = .unsupported_instruction, .detail = "extractelement-dynamic-index" },
        .{ .ir_text =
        \\define float @bad(float %x) {
        \\entry:
        \\  %v = insertelement <4 x float> poison, float %x, i64 2
        \\  %e = extractelement <4 x float> %v, i64 2
        \\  ret float %e
        \\}
        , .tag = .unsupported_instruction, .detail = "insertelement-index" },
        .{ .ir_text =
        \\define float @bad(float %x) {
        \\entry:
        \\  %v = insertelement <4 x float> poison, float %x, i64 0
        \\  %r = shufflevector <4 x float> %v, <4 x float> poison, <4 x i32> <i32 0, i32 0, i32 0, i32 0>
        \\  %e = extractelement <4 x float> %r, i64 0
        \\  ret float %e
        \\}
        , .tag = .unsupported_instruction, .detail = "shufflevector-mask" },
        .{ .ir_text =
        \\define double @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = fdiv <2 x double> %v, %v
        \\  %e = extractelement <2 x double> %r, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_instruction, .detail = "fdiv" },
        .{ .ir_text =
        \\define double @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 0, i32 1>
        \\  %e = extractelement <2 x double> %r, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_instruction, .detail = "shufflevector-mask" },
        .{ .ir_text =
        \\define float @bad(float %x) {
        \\entry:
        \\  %v = insertelement <2 x float> poison, float %x, i64 0
        \\  %r = shufflevector <2 x float> %v, <2 x float> poison, <2 x i32> <i32 1, i32 undef>
        \\  %e = extractelement <2 x float> %r, i64 0
        \\  ret float %e
        \\}
        , .tag = .unsupported_instruction, .detail = "shufflevector-mask" },
        .{ .ir_text =
        \\define double @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = shufflevector <2 x double> %v, <2 x double> poison, <2 x i32> <i32 0, i32 2>
        \\  %e = extractelement <2 x double> %r, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_instruction, .detail = "shufflevector-mask" },
        .{ .ir_text =
        \\define float @bad(float %x) {
        \\entry:
        \\  %v = insertelement <2 x float> poison, float %x, i64 0
        \\  %r = frem <2 x float> %v, %v
        \\  %e = extractelement <2 x float> %r, i64 0
        \\  ret float %e
        \\}
        , .tag = .unsupported_instruction, .detail = "frem" },
        .{ .ir_text =
        \\define i1 @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = fcmp olt <2 x double> %v, %v
        \\  %e = extractelement <2 x i1> %r, i64 0
        \\  ret i1 %e
        \\}
        , .tag = .unsupported_type, .detail = "fcmp" },
        .{ .ir_text =
        \\define i1 @bad(float %a, float %b, i64 %lane) {
        \\entry:
        \\  %va = insertelement <2 x float> poison, float %a, i64 0
        \\  %vb = insertelement <2 x float> poison, float %b, i64 0
        \\  %mask = fcmp oeq <2 x float> %va, %vb
        \\  %result = extractelement <2 x i1> %mask, i64 %lane
        \\  ret i1 %result
        \\}
        , .tag = .unsupported_instruction, .detail = "extractelement-dynamic-index" },
        .{ .ir_text =
        \\define float @bad(float %a, float %b) {
        \\entry:
        \\  %va = insertelement <4 x float> poison, float %a, i64 0
        \\  %vb = insertelement <4 x float> poison, float %b, i64 0
        \\  %mask = fcmp oeq <4 x float> %va, %vb
        \\  %selected = select <4 x i1> %mask, <4 x float> %va, <4 x float> %vb
        \\  %result = extractelement <4 x float> %selected, i64 0
        \\  ret float %result
        \\}
        , .tag = .unsupported_type, .detail = "select" },
        .{ .ir_text =
        \\define i8 @bad() {
        \\entry:
        \\  %result = bitcast <8 x i1> <i1 1, i1 0, i1 1, i1 0, i1 1, i1 0, i1 1, i1 0> to i8
        \\  ret i8 %result
        \\}
        , .tag = .unsupported_type, .detail = "cast" },
        .{ .ir_text =
        \\define double @bad(ptr %p) {
        \\entry:
        \\  %v = load <2 x double>, ptr %p
        \\  %e = extractelement <2 x double> %v, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_type, .detail = "load" },
        .{ .ir_text =
        \\define void @bad(ptr %p, double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  store <2 x double> %v, ptr %p
        \\  ret void
        \\}
        , .tag = .unsupported_type, .detail = "store" },
        .{ .ir_text =
        \\define double @bad(double %x) {
        \\entry:
        \\  %v = insertelement <4 x double> poison, double %x, i64 0
        \\  %e = extractelement <4 x double> %v, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_type, .detail = "insertelement" },
        .{ .ir_text =
        \\define <4 x double> @bad(<4 x double> %x) {
        \\entry:
        \\  ret <4 x double> %x
        \\}
        , .tag = .unsupported_type, .detail = "unsupported-return-type" },
    };

    for (cases) |case| {
        var module = try ir.Module.parse(std.testing.allocator, case.ir_text);
        defer module.deinit();
        try module.verify();
        const result = inspection.inspectFunction(module.functions.items[0]);
        try std.testing.expect(result == .unsupported);
        try std.testing.expectEqual(case.tag, std.meta.activeTag(result.unsupported));
        try std.testing.expectEqualStrings(case.detail, result.unsupported.detail());
    }
}
