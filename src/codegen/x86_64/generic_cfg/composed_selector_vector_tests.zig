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
    try machine.instructions.append(std.testing.allocator, .{ .mulpd_xmm = .{ .dst = .xmm4, .src = .xmm5 } });
    try machine.instructions.append(std.testing.allocator, .{ .movsd_xmm = .{ .dst = .xmm6, .src = .xmm7 } });
    try machine.instructions.append(std.testing.allocator, .{ .unpcklpd_xmm = .{ .dst = .xmm1, .src = .xmm2 } });
    try machine.instructions.append(std.testing.allocator, .{ .unpckhpd_xmm = .{ .dst = .xmm3, .src = .xmm4 } });
    try machine.instructions.append(std.testing.allocator, .ret);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    try std.testing.expectEqualSlices(u8, &.{
        0x66, 0x0f, 0x58, 0xd3,
        0x66, 0x0f, 0x59, 0xe5,
        0xf2, 0x0f, 0x10, 0xf7,
        0x66, 0x0f, 0x14, 0xca,
        0x66, 0x0f, 0x15, 0xdc,
        0xc3,
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
    try std.testing.expectEqual(@as(u2, 0b10), lane1_shape.defined_lanes);

    try std.testing.expect((try selector_vector.lowerInsertElement(&selector, "pair", .{
        .vector_ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .vector = .{ .named = "lane1" },
        .value_ty = .double,
        .value = .{ .named = "low" },
        .index_ty = .{ .int = 64 },
        .index = .{ .int = 0 },
    })) == null);
    const pair_shape = selector_state.valueLoc(&selector, "pair").?.xmm.vectorShape().?;
    try std.testing.expectEqual(@as(u2, 0b11), pair_shape.defined_lanes);
    try std.testing.expect((try selector_vector.lowerBinary(&selector, "masked", .{
        .op = .fadd,
        .ty = .{ .vector = .{ .len = 2, .elem_ty = .double } },
        .lhs = .{ .named = "pair" },
        .rhs = .{ .vector = "<double 1.000000e+00, double poison>" },
    })) == null);
    const masked_shape = selector_state.valueLoc(&selector, "masked").?.xmm.vectorShape().?;
    try std.testing.expectEqual(@as(u2, 0b01), masked_shape.defined_lanes);
    const masked_reg = selector_state.valueLoc(&selector, "masked").?.xmm.reg;

    try std.testing.expect((try selector_state.spillValue(&selector, "masked")) == null);
    const spill = selector_state.valueLoc(&selector, "masked").?.spill_vector;
    try std.testing.expectEqual(selector_types.PairSpillLoc{ .lo = .slot0, .hi = .slot2 }, spill.frames);
    try std.testing.expectEqual(@as(usize, 2), selector.next_spill_slot);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .spill_xmm128_rsp = .{ .frame_index = .slot0, .reg = masked_reg } }, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "generic cfg selector executes packed double construction and pressure spills bit exactly" {
    const input =
        \\define void @vector_canary(ptr %out, double %low, double %high) {
        \\entry:
        \\  %seed = insertelement <2 x double> poison, double %low, i64 0
        \\  %splat = shufflevector <2 x double> %seed, <2 x double> poison, <2 x i32> zeroinitializer
        \\  %pair = insertelement <2 x double> %seed, double %high, i64 1
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
    const canary: *const fn (*[16]u64, f64, f64) callconv(.c) void = @ptrCast(mapping.ptr);

    inline for (.{
        .{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000) },
        .{ @as(u64, 0x3ff8_0000_0000_0000), @as(u64, 0xc002_0000_0000_0000) },
        .{ @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x8000_0000_0000_0001) },
        .{ @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0xfff0_0000_0000_0000) },
        .{ @as(u64, 0x7ff8_1234_5678_9abc), @as(u64, 0xfff8_9876_5432_1abc) },
    }) |case| {
        const low: f64 = @bitCast(case[0]);
        const high: f64 = @bitCast(case[1]);
        var output: [16]u64 = undefined;
        canary(&output, low, high);
        const expected = [16]u64{
            case[0],             case[0],              case[0],             case[1],
            @bitCast(low + 0.0), @bitCast(high + 0.0), @bitCast(low * 1.0), @bitCast(high * 1.0),
            case[0],             case[1],              case[0],             case[1],
            case[0],             case[1],              case[0],             case[1],
        };
        try std.testing.expectEqualSlices(u64, &expected, &output);
    }
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
        \\define double @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = fsub <2 x double> %v, %v
        \\  %e = extractelement <2 x double> %r, i64 0
        \\  ret double %e
        \\}
        , .tag = .unsupported_instruction, .detail = "fsub" },
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
        \\define i1 @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  %r = fcmp oeq <2 x double> %v, %v
        \\  %e = extractelement <2 x i1> %r, i64 0
        \\  ret i1 %e
        \\}
        , .tag = .unsupported_type, .detail = "fcmp" },
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
        \\define float @bad(float %x) {
        \\entry:
        \\  %v = insertelement <4 x float> poison, float %x, i64 0
        \\  %e = extractelement <4 x float> %v, i64 0
        \\  ret float %e
        \\}
        , .tag = .unsupported_type, .detail = "insertelement" },
        .{ .ir_text =
        \\define <2 x double> @bad(double %x) {
        \\entry:
        \\  %v = insertelement <2 x double> poison, double %x, i64 0
        \\  ret <2 x double> %v
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
