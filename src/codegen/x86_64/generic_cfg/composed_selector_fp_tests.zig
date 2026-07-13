const std = @import("std");
const ir = @import("../../../ir.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_impl = @import("composed_selector_impl.zig");
const selector_calls = @import("composed_selector_calls.zig");
const x86_64_machine = @import("../machine.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_fp = @import("composed_selector_fp.zig");
const state_data = @import("composed_selector_state_data.zig");
const stage2_planning = @import("stage2_planning.zig");

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
