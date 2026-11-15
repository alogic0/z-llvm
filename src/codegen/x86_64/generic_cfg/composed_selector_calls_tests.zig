const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const encoding = @import("../../../mc/encoding.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const impl = @import("composed_selector_impl.zig");
const selector_calls = @import("composed_selector_calls.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_cfg = @import("composed_selector_cfg.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");

const MachineFunction = impl.MachineFunction;
const ComposedBlockSelector = impl.ComposedBlockSelector;
const ValueLoc = selector_types.ValueLoc;
const ValueUseTransaction = value_use.ValueUseTransaction;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;

fn appendInlineMemcpyArgs(
    call: *ir.CallInst,
    destination: ir.Value,
    source: ir.Value,
    length: ir.Value,
    is_volatile: ir.Value,
) !void {
    try call.args.append(std.testing.allocator, .{ .ty = .ptr, .value = destination });
    try call.args.append(std.testing.allocator, .{ .ty = .ptr, .value = source });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = length });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = is_volatile });
}

const MissingMemcpyOperand = enum { destination, source, length };

fn expectUnresolvedInlineMemcpyDiagnostic(
    missing: MissingMemcpyOperand,
    expected_detail: []const u8,
) !void {
    var machine = MachineFunction.init("inline-memcpy-unresolved-production", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try plan.interval_ends.put(name, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "len", .rax);

    var call = ir.CallInst{ .ret_ty = .void, .callee = "llvm.memcpy.inline.p0.p0.i64", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try appendInlineMemcpyArgs(
        &call,
        .{ .named = if (missing == .destination) "missing-dst" else "dst" },
        .{ .named = if (missing == .source) "missing-src" else "src" },
        .{ .named = if (missing == .length) "missing-len" else "len" },
        .{ .int = 0 },
    );
    const diagnostic = (try selector_calls.lowerInlineMemcpy(&selector, null, call)).?;
    try std.testing.expectEqualStrings(expected_detail, diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
}

test "inline memset rejects dynamic length volatile and malformed envelopes before mutation" {
    for (0..6) |boundary| {
        var machine = MachineFunction.init("inline-memset-closed", .void);
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "out", .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "byte", .{ .arg64 = .rsi });
        try selector_state.bindValueLoc(&selector, "length", .{ .arg64 = .rdx });
        var call: ir.CallInst = .{ .ret_ty = .void, .callee = "llvm.memset.inline.p0.i64", .args = .empty };
        defer call.deinit(std.testing.allocator);
        try call.args.appendSlice(std.testing.allocator, &.{
            .{ .ty = .ptr, .value = .{ .named = "out" } },
            .{ .ty = .{ .int = 8 }, .value = .{ .named = "byte" } },
            .{ .ty = .{ .int = 64 }, .value = .{ .int = 16 } },
            .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } },
        });
        switch (boundary) {
            0 => call.args.items[2].value = .{ .named = "length" },
            1 => call.args.items[3].value = .{ .int = 1 },
            2 => call.args.items[0].attrs = "addrspace(1)",
            3 => call.args.items[2].value = .{ .int = -1 },
            4 => call.args.items[1].ty = .{ .int = 32 },
            5 => call.tail_kind = "musttail",
            else => unreachable,
        }
        try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = null, .kind = .{ .call = call } })) != null);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
    }
}

test "generic cfg selector lowers lifetime markers as checked no-ops" {
    var machine = MachineFunction.init("lifetime-markers", .void);
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{ .base_disp = 0, .bits = 8 } });

    inline for (.{ "llvm.lifetime.start.p0", "llvm.lifetime.end.p0" }) |callee| {
        var call = ir.CallInst{
            .ret_ty = .void,
            .callee = callee,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .ptr, .value = .{ .named = "slot" } });
        try std.testing.expect((try impl.lowerInstruction(&selector, .{ .result = null, .kind = .{ .call = call } })) == null);
    }

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "production inline memcpy transaction preserves exact staging and call clobber" {
    var machine = MachineFunction.init("inline-memcpy-production", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try plan.interval_ends.put(name, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .spill64 = .slot3 });
    try selector_state.bindValueLoc(&selector, "len", .rax);

    var call = ir.CallInst{
        .ret_ty = .void,
        .callee = "llvm.memcpy.inline.p0.p0.i64",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try appendInlineMemcpyArgs(
        &call,
        .{ .named = "dst" },
        .{ .named = "src" },
        .{ .named = "len" },
        .{ .int = 0 },
    );
    try std.testing.expect((try selector_calls.lowerInlineMemcpy(&selector, null, call)) == null);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .spill_rax_rsp = .slot0 },
        .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .r8 } },
        .{ .reload_arg64_rsp = .{ .reg = .rsi, .frame_index = .slot3 } },
        .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = .slot0 } },
        .memcpy_rdi_rsi_rdx_rax,
    }, machine.instructions.items);
    try std.testing.expectEqual(@as(usize, 1), selector.eflags_semantics.items.len);
    try std.testing.expectEqual(selector_state.EflagsEffect.clobber, selector.eflags_semantics.items[0].effect);
}

test "production inline memcpy maps unresolved destination through request provenance" {
    try expectUnresolvedInlineMemcpyDiagnostic(.destination, "composed-block-memcpy-dst");
}

test "ordinary memory copies reject malformed and ABI attributes before mutating selection" {
    for ([_][]const u8{ "llvm.memcpy.p0.p0.i64", "llvm.memmove.p0.p0.i64" }) |callee| {
        for ([_][]const u8{ "align 3", "align", "noundef noundef", "captures(unknown)", "byval(i64)", "sret(i64)", "addrspace(1)", "zeroext", "initializes(bad)", "range(i32 0, 65)", "range(i64 1, 1)", "range(i64 0, bad)", "range(i64 0, 65, 66)" }) |attrs| {
            var machine = MachineFunction.init("copy-attributes", .void);
            defer machine.deinit(std.testing.allocator);
            var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
            defer selector.deinit();
            var call: ir.CallInst = .{ .ret_ty = .void, .callee = callee, .args = .empty };
            defer call.deinit(std.testing.allocator);
            try appendInlineMemcpyArgs(&call, .{ .named = "dst" }, .{ .named = "src" }, .{ .int = 4 }, .{ .int = 0 });
            for (0..3) |index| {
                call.args.items[index].attrs = attrs;
                const diagnostic = if (std.mem.eql(u8, callee, "llvm.memcpy.p0.p0.i64"))
                    (try selector_calls.lowerInlineMemcpy(&selector, null, call)).?
                else
                    (try selector_calls.lowerInlineMemmove(&selector, null, call)).?;
                try std.testing.expectEqualStrings(if (std.mem.eql(u8, callee, "llvm.memcpy.p0.p0.i64")) "composed-block-memcpy-attrs" else "composed-block-memmove-attrs", diagnostic.detail());
                try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
                try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
                call.args.items[index].attrs = null;
            }
        }
    }
}

test "production inline memcpy maps unresolved source through request provenance" {
    try expectUnresolvedInlineMemcpyDiagnostic(.source, "composed-block-memcpy-src");
}

test "production inline memcpy maps unresolved length through request provenance" {
    try expectUnresolvedInlineMemcpyDiagnostic(.length, "composed-block-memcpy-len");
}

test "production inline memcpy preserves cycles and rejects unsupported operand forms" {
    var machine = MachineFunction.init("inline-memcpy-production-negative", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try plan.interval_ends.put(name, 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 128;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .rsi });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "len", .{ .arg64 = .rdx });

    var cycle = ir.CallInst{ .ret_ty = .void, .callee = "llvm.memcpy.inline.p0.p0.i64", .args = .empty };
    defer cycle.deinit(std.testing.allocator);
    try appendInlineMemcpyArgs(&cycle, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" }, .{ .int = 0 });

    const bad_operands = [_]struct { dst: ir.Value, src: ir.Value, len: ir.Value, detail: []const u8 }{
        .{ .dst = .null_value, .src = .{ .named = "src" }, .len = .{ .named = "len" }, .detail = "composed-block-memcpy-dst" },
        .{ .dst = .{ .named = "dst" }, .src = .null_value, .len = .{ .named = "len" }, .detail = "composed-block-memcpy-src" },
        .{ .dst = .{ .named = "dst" }, .src = .{ .named = "missing-src" }, .len = .{ .named = "len" }, .detail = "composed-block-memcpy-src" },
        .{ .dst = .{ .named = "dst" }, .src = .{ .named = "src" }, .len = .{ .int = -1 }, .detail = "composed-block-memcpy-len" },
    };
    for (bad_operands) |case| {
        var call = ir.CallInst{ .ret_ty = .void, .callee = "llvm.memcpy.inline.p0.p0.i64", .args = .empty };
        defer call.deinit(std.testing.allocator);
        try appendInlineMemcpyArgs(&call, case.dst, case.src, case.len, .{ .int = 0 });
        const diagnostic = (try selector_calls.lowerInlineMemcpy(&selector, null, call)).?;
        try std.testing.expectEqualStrings(case.detail, diagnostic.detail());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
    try std.testing.expect((try selector_calls.lowerInlineMemcpy(&selector, null, cycle)) == null);
    try std.testing.expect(machine.instructions.items.len > 0);
}

test "production inline memcpy preserves pre-transaction diagnostics and rolls back preservation" {
    var machine = MachineFunction.init("inline-memcpy-production-rollback", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();

    var volatile_call = ir.CallInst{ .ret_ty = .void, .callee = "llvm.memcpy.inline.p0.p0.i64", .args = .empty };
    defer volatile_call.deinit(std.testing.allocator);
    try appendInlineMemcpyArgs(
        &volatile_call,
        .{ .named = "dst" },
        .{ .named = "src" },
        .{ .named = "len" },
        .{ .int = 1 },
    );
    const volatile_diagnostic = (try selector_calls.lowerInlineMemcpy(&selector, null, volatile_call)).?;
    try std.testing.expectEqualStrings("composed-block-memcpy-args", volatile_diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);

    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "dst", "src", "len" }) |name| try plan.interval_ends.put(name, 1);
    try plan.interval_ends.put("live-rcx", 10);
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "dst", .{ .arg64 = .r8 });
    try selector_state.bindValueLoc(&selector, "src", .{ .arg64 = .r9 });
    try selector_state.bindValueLoc(&selector, "len", .rax);
    try selector_state.bindValueLoc(&selector, "live-rcx", .{ .arg64 = .rcx });
    const dst_before = selector.values.get("dst").?;
    const src_before = selector.values.get("src").?;
    const len_before = selector.values.get("len").?;
    const live_before = selector.values.get("live-rcx").?;

    var call = ir.CallInst{ .ret_ty = .void, .callee = "llvm.memcpy.inline.p0.p0.i64", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try appendInlineMemcpyArgs(&call, .{ .named = "dst" }, .{ .named = "src" }, .{ .named = "len" }, .{ .int = 0 });
    const diagnostic = (try selector_calls.lowerInlineMemcpy(&selector, null, call)).?;
    try std.testing.expectEqualStrings("composed-block-spill-frame", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(dst_before, selector.values.get("dst").?);
    try std.testing.expectEqual(src_before, selector.values.get("src").?);
    try std.testing.expectEqual(len_before, selector.values.get("len").?);
    try std.testing.expectEqual(live_before, selector.values.get("live-rcx").?);
    try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
    try std.testing.expectEqual(@as(usize, 0), selector.eflags_semantics.items.len);
}

test "generic cfg selector lowers exact i64 unsigned saturating subtraction" {
    var machine = MachineFunction.init("usub-sat-i64", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });

    var call = ir.CallInst{
        .ret_ty = .{ .int = 64 },
        .callee = "llvm.usub.sat.i64",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 55 } });

    try std.testing.expect((try selector_calls.lowerCall(&selector, "difference", call)) == null);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "difference").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_arg_rax = .rdi },
        .{ .mov_imm_rcx = 55 },
        .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } },
    }, machine.instructions.items[0..3]);
    try std.testing.expectEqualStrings("__zllvm_edge_0", machine.instructions.items[3].jae);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_rax = 0 }, machine.instructions.items[4]);
    try std.testing.expectEqualStrings("__zllvm_edge_0", machine.instructions.items[5].label);

    var bad = ir.CallInst{
        .ret_ty = .{ .int = 64 },
        .callee = "llvm.usub.sat.i64",
        .args = .empty,
    };
    defer bad.deinit(std.testing.allocator);
    try bad.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
    try bad.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "other" } });
    const diagnostic = (try selector_calls.lowerCall(&selector, "bad", bad)).?;
    try std.testing.expectEqualStrings("composed-block-usub-sat-args", diagnostic.detail());
}

test "generic cfg selector usub sat reuses a dead accumulator lhs" {
    var machine = MachineFunction.init("usub-sat-dead-rax", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "source", .rax);

    var call = ir.CallInst{
        .ret_ty = .{ .int = 64 },
        .callee = "llvm.usub.sat.i64",
        .tail_kind = "tail",
        .args = .empty,
    };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "source" } });
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 55 } });

    try std.testing.expect((try selector_calls.lowerCall(&selector, "difference", call)) == null);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "source").?);
    try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "difference").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .mov_imm_rcx = 55 },
        .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } },
    }, machine.instructions.items[0..2]);
}

test "generic cfg selector normalizes narrow intByteSize call results" {
    const input =
        \\declare fastcc i16 @zig.target.intByteSize(i16)
        \\declare void @llvm.assume(i1)
        \\define i64 @limb_count(i64 %wide_bits) {
        \\entry:
        \\  %bounded = icmp ult i64 %wide_bits, 65536
        \\  call void @llvm.assume(i1 %bounded)
        \\  %bits = trunc i64 %wide_bits to i16
        \\  %bytes = tail call fastcc i16 @zig.target.intByteSize(i16 %bits)
        \\  %limbs = lshr i16 %bytes, 2
        \\  %result = zext i16 %limbs to i64
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("limb_count", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    var saw_compare = false;
    var saw_setcc = false;
    var saw_call = false;
    var saw_mask_after_call = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .cmp_arg64_imm64 => saw_compare = true,
        .setb_eax => saw_setcc = saw_compare,
        .direct_call => saw_call = saw_setcc,
        .and_eax_imm32 => |mask| saw_mask_after_call = saw_call and mask == 0xffff,
        .spill_eax_rsp, .spill_rax_rsp => return error.UnexpectedExpiredAccumulatorSpill,
        else => {},
    };
    try std.testing.expect(saw_compare and saw_setcc and saw_call and saw_mask_after_call);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);

    const stub = [_]u8{ 0xb8, 0x20, 0x00, 0xad, 0xde, 0xc3 };
    const mapping = try std.posix.mmap(null, bytes.len + stub.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping[0..bytes.len], bytes);
    @memcpy(mapping[bytes.len..], &stub);

    var offset: usize = 0;
    for (machine.instructions.items) |instruction| {
        if (instruction == .direct_call) {
            const next_ip = @intFromPtr(mapping.ptr) + offset + 5;
            const displacement: i32 = @intCast(@intFromPtr(mapping.ptr + bytes.len) - next_ip);
            std.mem.writeInt(i32, mapping[offset + 1 ..][0..4], displacement, .little);
        }
        offset += encoding.instructionSize(instruction);
    }
    const limb_count: *const fn (u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 8), limb_count(129));
}

test "generic cfg selector lowers i16 count-leading-zeros" {
    inline for (.{ 0, 1 }) |zero_is_poison| {
        var machine = MachineFunction.init("ctlz-i16", .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);

        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 16 },
            .callee = "llvm.ctlz.i16",
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 16 }, .value = .{ .named = "value" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = zero_is_poison } });

        try std.testing.expect((try selector_calls.lowerCtlzI16(&selector, "count", call)) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "count").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_eax = .rsi },
            .{ .and_eax_imm32 = 0xffff },
            .{ .mov_eax_to_arg = .rdi },
            .clz_i32_edi_eax,
            .{ .add_eax_imm32 = -16 },
        }, machine.instructions.items);
    }
}

test "generic cfg selector lowers only exact i32 count-trailing-zeros forms" {
    inline for (.{ 0, 1 }) |zero_is_poison| {
        var machine = MachineFunction.init("cttz-i32", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);

        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg32 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 32 },
            .callee = "llvm.cttz.i32",
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "value" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = zero_is_poison } });

        try std.testing.expect((try selector_calls.lowerCttzI32(&selector, "count", call)) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "count").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg_arg = .{ .dst = .rdi, .src = .rsi } },
            .ctz_i32_edi_eax,
        }, machine.instructions.items);
    }

    var bad_machine = MachineFunction.init("bad-cttz", .{ .int = 32 });
    defer bad_machine.deinit(std.testing.allocator);
    var bad_selector = ComposedBlockSelector.init(std.testing.allocator, &bad_machine);
    defer bad_selector.deinit();
    try selector_state.bindValueLoc(&bad_selector, "value", .{ .arg32 = .rdi });
    var bad_call = ir.CallInst{
        .ret_ty = .{ .int = 32 },
        .callee = "llvm.cttz.i32",
        .args = .empty,
    };
    defer bad_call.deinit(std.testing.allocator);
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "value" } });
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 2 } });
    const diagnostic = (try selector_calls.lowerCttzI32(&bad_selector, "count", bad_call)).?;
    try std.testing.expectEqualStrings("composed-block-cttz-args", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), bad_machine.instructions.items.len);
}

test "fixed unary composite authority rolls back before and after subordinate finalization" {
    inline for (.{ false, true }) |after_finalization| {
        var machine = MachineFunction.init("fixed-unary-combined-rollback", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rsi });
        const saved_binding = selector.values.get("value").?;
        const saved_dependencies = selector.address_dependencies;
        const saved_domain = selector.accumulator_domain;
        const saved_eflags = selector.eflags.snapshot();
        const saved_semantics = selector.eflags_semantics.items.len;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;
        const saved_edge_labels = selector.edge_label_count;
        const saved_owned_labels = machine.owned_labels.items.len;

        var transaction = try ValueUseTransaction.begin(&selector);
        _ = try transaction.register(.{
            .source = .{ .named = "value" },
            .expected = .{ .ty = .{ .int = 64 }, .register_class = .gpr64 },
            .form = .gpr64,
            .destination = .{ .gpr64 = .rdi },
        });
        try transaction.seal();
        const accumulator = try transaction.beginAccumulatorSession();
        try transaction.prepare();
        try transaction.materializeAll();
        try std.testing.expect((try transaction.prepareAccumulator(
            accumulator,
            .clobber,
            .spill_live,
        )) == null);
        try selector_state.emitEflagsInstruction(&selector, .clz_i64_rdi_eax, .clobber);
        try transaction.defineAccumulatorResult(accumulator, "result", .fullRax());
        if (after_finalization) try transaction.finalizeAccumulatorResult(accumulator);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } },
            .clz_i64_rdi_eax,
        }, machine.instructions.items);
        transaction.deinit();

        try std.testing.expectEqual(@as(usize, 1), selector.values.count());
        try std.testing.expectEqual(saved_binding, selector.values.get("value").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expectEqual(saved_edge_labels, selector.edge_label_count);
        try std.testing.expectEqual(saved_owned_labels, machine.owned_labels.items.len);
        try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
        try std.testing.expect(selector.address_dependencies.eql(&saved_dependencies));
        try selector.eflags.validateSnapshot(saved_eflags);
        try std.testing.expectEqual(saved_semantics, selector.eflags_semantics.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }
}

test "generic cfg selector lowers only exact i64 count-leading-zeros forms" {
    inline for (.{ 0, 1 }) |zero_is_poison| {
        var machine = MachineFunction.init("ctlz-i64", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);

        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 64 },
            .callee = "llvm.ctlz.i64",
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = zero_is_poison } });

        try std.testing.expect((try selector_calls.lowerCtlzI64(&selector, "count", call)) == null);
        try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "count").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } },
            .clz_i64_rdi_eax,
        }, machine.instructions.items);
    }

    var bad_machine = MachineFunction.init("bad-ctlz-i64", .{ .int = 64 });
    defer bad_machine.deinit(std.testing.allocator);
    var bad_selector = ComposedBlockSelector.init(std.testing.allocator, &bad_machine);
    defer bad_selector.deinit();
    try selector_state.bindValueLoc(&bad_selector, "value", .{ .arg64 = .rdi });
    var bad_call = ir.CallInst{
        .ret_ty = .{ .int = 64 },
        .callee = "llvm.ctlz.i64",
        .args = .empty,
    };
    defer bad_call.deinit(std.testing.allocator);
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "value" } });
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 0 } });
    const diagnostic = (try selector_calls.lowerCtlzI64(&bad_selector, "count", bad_call)).?;
    try std.testing.expectEqualStrings("composed-block-ctlz-args", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), bad_machine.instructions.items.len);
}

test "generic cfg selector lowers only exact i64 count-trailing-zeros forms" {
    inline for (.{ 0, 1 }) |zero_is_poison| {
        var machine = MachineFunction.init("cttz-i64", .{ .int = 64 });
        defer machine.deinit(std.testing.allocator);

        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("value", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 64 },
            .callee = "llvm.cttz.i64",
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = zero_is_poison } });

        try std.testing.expect((try selector_calls.lowerCttzI64(&selector, "count", call)) == null);
        try std.testing.expectEqual(ValueLoc.rax, selector_state.valueLoc(&selector, "count").?);
        try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
            .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rsi } },
            .ctz_i64_rdi_eax,
        }, machine.instructions.items);
    }

    var bad_machine = MachineFunction.init("bad-cttz-i64", .{ .int = 64 });
    defer bad_machine.deinit(std.testing.allocator);
    var bad_selector = ComposedBlockSelector.init(std.testing.allocator, &bad_machine);
    defer bad_selector.deinit();
    try selector_state.bindValueLoc(&bad_selector, "value", .{ .arg64 = .rdi });
    var bad_call = ir.CallInst{
        .ret_ty = .{ .int = 64 },
        .callee = "llvm.cttz.i64",
        .args = .empty,
    };
    defer bad_call.deinit(std.testing.allocator);
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
    try bad_call.args.append(std.testing.allocator, .{ .ty = .{ .int = 1 }, .value = .{ .int = 2 } });
    const diagnostic = (try selector_calls.lowerCttzI64(&bad_selector, "count", bad_call)).?;
    try std.testing.expectEqualStrings("composed-block-cttz-args", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), bad_machine.instructions.items.len);
}

test "generic cfg selector executes zero-defined i64 count-leading-zeros" {
    const input =
        \\declare i64 @llvm.ctlz.i64(i64, i1 immarg)
        \\define i64 @ctlz_defined(i64 %value) {
        \\entry:
        \\  %count = call i64 @llvm.ctlz.i64(i64 %value, i1 false)
        \\  ret i64 %count
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("ctlz_defined", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const ctlz: *const fn (u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u64, 0), @as(u64, 64) },
        .{ @as(u64, 1), @as(u64, 63) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 0) },
        .{ @as(u64, 0x0000_0001_0000_0000), @as(u64, 31) },
        .{ @as(u64, 0xffff_ffff_ffff_ffff), @as(u64, 0) },
    }) |case| try std.testing.expectEqual(case[1], ctlz(case[0]));
}

test "generic cfg selector executes zero-defined i32 count-trailing-zeros" {
    const input =
        \\declare i32 @llvm.cttz.i32(i32, i1 immarg)
        \\define i32 @cttz_defined(i32 %value) {
        \\entry:
        \\  %count = call i32 @llvm.cttz.i32(i32 %value, i1 false)
        \\  ret i32 %count
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("cttz_defined", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const cttz: *const fn (u32) callconv(.c) u32 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u32, 0), @as(u32, 32) },
        .{ @as(u32, 1), @as(u32, 0) },
        .{ @as(u32, 0x8000_0000), @as(u32, 31) },
        .{ @as(u32, 0x0001_0000), @as(u32, 16) },
        .{ @as(u32, 0xffff_ffff), @as(u32, 0) },
    }) |case| try std.testing.expectEqual(case[1], cttz(case[0]));
}

test "generic cfg selector executes zero-defined i64 count-trailing-zeros" {
    const input =
        \\declare i64 @llvm.cttz.i64(i64, i1 immarg)
        \\define i64 @cttz_defined(i64 %value) {
        \\entry:
        \\  %count = call i64 @llvm.cttz.i64(i64 %value, i1 false)
        \\  ret i64 %count
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("cttz_defined", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const cttz: *const fn (u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    inline for (.{
        .{ @as(u64, 0), @as(u64, 64) },
        .{ @as(u64, 1), @as(u64, 0) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 63) },
        .{ @as(u64, 0x0000_0001_0000_0000), @as(u64, 32) },
        .{ @as(u64, 0xffff_ffff_ffff_ffff), @as(u64, 0) },
    }) |case| try std.testing.expectEqual(case[1], cttz(case[0]));
}

test "composed selector stages swapped scalar SSE call arguments" {
    const input =
        \\declare float @callee(float, float)
        \\define float @caller(float %a, float %b) {
        \\entry:
        \\  %result = call float @callee(float %b, float %a)
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var spilled_xmm0 = false;
    var spilled_xmm1 = false;
    var reloaded_xmm0 = false;
    var reloaded_xmm1 = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_xmm32_rsp => |spill| {
            spilled_xmm0 = spilled_xmm0 or spill.reg == .xmm0;
            spilled_xmm1 = spilled_xmm1 or spill.reg == .xmm1;
        },
        .reload_xmm32_rsp => |reload| {
            reloaded_xmm0 = reloaded_xmm0 or reload.reg == .xmm0;
            reloaded_xmm1 = reloaded_xmm1 or reload.reg == .xmm1;
        },
        else => {},
    };
    try std.testing.expect(spilled_xmm0 and spilled_xmm1 and reloaded_xmm0 and reloaded_xmm1);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector numbers mixed GPR and SSE call arguments independently" {
    const input =
        \\declare double @callee(i32, double, i64, float)
        \\define double @caller(i32 %a, float %x, i64 %b, double %y) {
        \\entry:
        \\  %result = call double @callee(i32 %a, double %y, i64 %b, float %x)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var reloaded_xmm0 = false;
    var reloaded_xmm1 = false;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .reload_xmm64_rsp => |reload| reloaded_xmm0 = reloaded_xmm0 or reload.reg == .xmm0,
        .reload_xmm32_rsp => |reload| reloaded_xmm1 = reloaded_xmm1 or reload.reg == .xmm1,
        else => {},
    };
    try std.testing.expect(reloaded_xmm0 and reloaded_xmm1);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector preserves a live XMM value across a direct call" {
    const input =
        \\declare float @callee(float)
        \\define float @caller(float %a, float %b, float %c) {
        \\entry:
        \\  %sum = fadd float %a, %b
        \\  %called = call float @callee(float %c)
        \\  %result = fadd float %sum, %called
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("caller", .float);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));

    var call_index: ?usize = null;
    var spill_before_call = false;
    var reload_after_call = false;
    for (machine.instructions.items, 0..) |instruction, index| switch (instruction) {
        .direct_call => call_index = index,
        .spill_xmm32_rsp => if (call_index == null) {
            spill_before_call = true;
        },
        .reload_xmm32_rsp => if (call_index) |at| {
            if (index > at) reload_after_call = true;
        },
        else => {},
    };
    try std.testing.expect(call_index != null and spill_before_call and reload_after_call);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector binds half float and double direct call results in XMM0" {
    const input =
        \\declare half @half_callee(half)
        \\declare float @float_callee(float)
        \\declare double @double_callee(double)
        \\define half @half_caller(half %value) {
        \\entry:
        \\  %result = call half @half_callee(half %value)
        \\  ret half %result
        \\}
        \\define float @float_caller(float %value) {
        \\entry:
        \\  %result = call float @float_callee(float %value)
        \\  ret float %result
        \\}
        \\define double @double_caller(double %value) {
        \\entry:
        \\  %result = call double @double_callee(double %value)
        \\  ret double %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);
    }
}

test "composed selector transaction binds direct i32 i64 pointer and mixed SSE GPR call results" {
    inline for (.{
        .{ .ty = ir.Type{ .int = 32 }, .loc = ValueLoc.eax },
        .{ .ty = ir.Type{ .int = 64 }, .loc = ValueLoc.rax },
        .{ .ty = ir.Type.ptr, .loc = ValueLoc.rax },
    }) |case| {
        var machine = MachineFunction.init("direct-gpr-result", case.ty);
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        var call = ir.CallInst{ .ret_ty = case.ty, .callee = "callee", .args = .empty };
        defer call.deinit(std.testing.allocator);
        try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
        try std.testing.expectEqual(case.loc, selector_state.valueLoc(&selector, "result").?);
        try std.testing.expectEqual(@as(usize, 1), machine.instructions.items.len);
        try std.testing.expect(machine.instructions.items[0] == .direct_call);
    }

    const mixed_input =
        \\declare i64 @mixed(double, i32)
        \\define i64 @caller(double %fp, i32 %integer) {
        \\entry:
        \\  %result = call i64 @mixed(double %fp, i32 %integer)
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, mixed_input);
    defer module.deinit();
    try module.verify();
    var mixed_machine = MachineFunction.init("caller", .{ .int = 64 });
    defer mixed_machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &mixed_machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(mixed_machine);
}

test "composed selector call result rejects live EFLAGS before any call mutation" {
    var machine = MachineFunction.init("call-flags-reject", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.emitEflagsInstruction(&selector, .{ .cmp_eax_imm32 = 0 }, .definition);
    const saved_len = machine.instructions.items.len;
    const saved_flags = selector.eflags.snapshot();
    var call = ir.CallInst{ .ret_ty = .{ .int = 32 }, .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try std.testing.expectError(error.EflagsClobberedWhileLive, selector_calls.lowerCall(&selector, "result", call));
    try std.testing.expectEqual(saved_len, machine.instructions.items.len);
    try std.testing.expect(selector_state.valueLoc(&selector, "result") == null);
    try selector.eflags.validateSnapshot(saved_flags);
}

test "composed selector call transaction rolls back every call-sequence checkpoint" {
    inline for (0..6) |checkpoint| {
        var machine = MachineFunction.init("call-checkpoint-rollback", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("live", 10);
        try plan.interval_ends.put("dead", 0);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = stage2SpillReservedBytes();
        var seed = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
        _ = try seed.prepare(.preserve, .spill_live);
        try seed.define("live", .zeroExtending(32));
        try seed.commit();
        seed.deinit();
        try selector_state.bindValueLoc(&selector, "dead", .eax);
        const live_binding = selector.values.get("live").?;
        const dead_binding = selector.values.get("dead").?;
        const saved_domain = selector.accumulator_domain;
        const saved_next_vreg = selector.next_virtual_reg;
        const saved_next_spill = selector.next_spill_slot;

        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
        defer transaction.deinit();
        _ = try transaction.prepareCallBeforeArguments(.clobber);
        if (checkpoint >= 1) try machine.instructions.append(std.testing.allocator, .{ .mov_imm_rdi = 7 });
        if (checkpoint >= 2) try transaction.finishCallPreparationAfterArguments();
        if (checkpoint >= 3) try selector_state.emitEflagsInstruction(&selector, .sub_rsp_8, .write);
        if (checkpoint >= 4) try selector_state.emitEflagsInstruction(&selector, .{ .direct_call = .{ .symbol = "callee", .ret_ty = .{ .int = 32 } } }, .clobber);
        if (checkpoint >= 5) try transaction.define("result", .zeroExtending(32));
        try transaction.rollback();

        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 2), selector.values.count());
        try std.testing.expectEqual(live_binding, selector.values.get("live").?);
        try std.testing.expectEqual(dead_binding, selector.values.get("dead").?);
        try std.testing.expect(selector.values.get("result") == null);
        try std.testing.expectEqual(@as(usize, 0), selector.spill_slots.count());
        try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
        try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
        try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    }
}

test "composed selector stages a dead accumulator argument before dropping its binding" {
    var machine = MachineFunction.init("dead-accumulator-call-argument", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("argument", 0);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    var seed = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    _ = try seed.prepare(.preserve, .spill_live);
    try seed.define("argument", .zeroExtending(32));
    try seed.commit();
    seed.deinit();

    var call = ir.CallInst{ .ret_ty = .{ .int = 32 }, .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .named = "argument" } });
    try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
    try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "result").?);
    try std.testing.expect(selector_state.valueLoc(&selector, "argument") == null);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_eax_to_arg = .rdi }, machine.instructions.items[0]);
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_eax_rsp, .spill_rax_rsp => return error.UnexpectedDeadArgumentSpill,
        else => {},
    };
}

test "composed selector spills a live accumulator call value exactly once" {
    var machine = MachineFunction.init("live-accumulator-call-value", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("live", 10);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "live", .eax);

    var call = ir.CallInst{ .ret_ty = .{ .int = 32 }, .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "live").?);
    var spill_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_eax_rsp, .spill_rax_rsp => spill_count += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), spill_count);
}

test "composed selector preserves a protected accumulator PHI across a call" {
    var machine = MachineFunction.init("protected-phi-call", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("phi", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "phi", .eax);
    try selector.phi_results.put("phi", {});

    var call = ir.CallInst{ .ret_ty = .{ .int = 32 }, .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "phi").?);
    var spill_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_eax_rsp, .spill_rax_rsp => spill_count += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), spill_count);
}

test "composed selector separates dead and live accumulator aliases at a call" {
    var machine = MachineFunction.init("call-accumulator-aliases", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("dead", 0);
    try plan.interval_ends.put("live", 10);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "dead", .eax);
    try selector_state.bindValueLoc(&selector, "live", .rax);

    var call = ir.CallInst{ .ret_ty = .{ .int = 64 }, .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
    try std.testing.expect(selector_state.valueLoc(&selector, "dead") == null);
    try std.testing.expectEqual(ValueLoc{ .spill64 = .slot0 }, selector_state.valueLoc(&selector, "live").?);
    var spill_count: usize = 0;
    for (machine.instructions.items) |instruction| switch (instruction) {
        .spill_eax_rsp, .spill_rax_rsp => spill_count += 1,
        else => {},
    };
    try std.testing.expectEqual(@as(usize, 1), spill_count);
}

test "call preparation failure after expired drop restores full state" {
    var machine = MachineFunction.init("call-drop-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("dead", 0);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = stage2SpillReservedBytes();
    try selector_state.bindValueLoc(&selector, "dead", .eax);
    try selector_state.bindValueLoc(&selector, "occupied", .{ .scratch32 = .r9 });
    try selector.spill_slots.put("seed", .{ .base = 0, .slots = 1 });
    selector.next_spill_slot = 1;
    const dead_binding = selector.values.get("dead").?;
    const occupied_binding = selector.values.get("occupied").?;
    const saved_domain = selector.accumulator_domain;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_vreg = selector.next_virtual_reg;
    const saved_next_spill = selector.next_spill_slot;

    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    defer transaction.deinit();
    _ = try transaction.prepareCallBeforeArguments(.clobber);
    try machine.instructions.append(std.testing.allocator, .{ .mov_eax_to_arg = .rdi });
    try transaction.finishCallPreparationAfterArguments();
    try std.testing.expect(selector_state.valueLoc(&selector, "dead") == null);
    try std.testing.expectError(error.AccumulatorDefinitionAlreadyBound, transaction.define("occupied", .zeroExtending(32)));
    try transaction.rollback();

    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(dead_binding, selector.values.get("dead").?);
    try std.testing.expectEqual(occupied_binding, selector.values.get("occupied").?);
    try std.testing.expectEqual(@as(usize, 1), selector.spill_slots.count());
    try std.testing.expectEqual(saved_next_vreg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill, selector.next_spill_slot);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "composed selector leaves generic narrow returns and unsupported return attributes rejected" {
    inline for (.{ @as(u16, 8), @as(u16, 16) }) |bits| {
        var machine = MachineFunction.init("narrow-return", .{ .int = bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        var call = ir.CallInst{ .ret_ty = .{ .int = bits }, .callee = "callee", .args = .empty };
        defer call.deinit(std.testing.allocator);
        const diagnostic = (try selector_calls.lowerCall(&selector, "result", call)).?;
        try std.testing.expectEqualStrings("composed-block-call-ret-width", diagnostic.detail());
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    }

    var machine = MachineFunction.init("return-attributes", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    var call = ir.CallInst{ .ret_ty = .{ .int = 32 }, .ret_attrs = "zeroext", .callee = "callee", .args = .empty };
    defer call.deinit(std.testing.allocator);
    const diagnostic = (try selector_calls.lowerCall(&selector, "result", call)).?;
    try std.testing.expectEqualStrings("composed-block-call-form", diagnostic.detail());
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
}

test "composed boolean calls route default ccc and fastcc through typed arguments" {
    const cases = [_]struct { ty: ir.Type, loc: ValueLoc }{
        .{ .ty = .{ .int = 32 }, .loc = .{ .spill64 = .slot3 } },
        .{ .ty = .{ .int = 64 }, .loc = .{ .spill64 = .slot3 } },
        .{ .ty = .ptr, .loc = .{ .stack_scalar = .{ .base_disp = 24, .bits = 64 } } },
        .{ .ty = .ptr, .loc = .{ .stack128 = 32 } },
    };
    for ([_]?[]const u8{ null, "ccc", "fastcc" }) |convention| for ([_]?[]const u8{ null, "zeroext", "noundef zeroext" }) |ret_attrs| {
        for (cases) |case| {
            for ([_]usize{ 0, 1, 6 }) |count| {
                var machine = MachineFunction.init("boolean-call-arguments", .{ .int = 1 });
                defer machine.deinit(std.testing.allocator);
                var plan = SelectorAllocationPlan.init(std.testing.allocator);
                defer plan.deinit();
                try plan.interval_ends.put("argument", 1);
                var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
                defer selector.deinit();
                selector.allocation_plan = &plan;
                selector.stack_frame_bytes = 128;
                try selector_state.bindValueLoc(&selector, "argument", case.loc);
                var call = ir.CallInst{ .ret_ty = .{ .int = 1 }, .ret_attrs = ret_attrs, .callee = "callee", .calling_conv = convention, .args = .empty };
                defer call.deinit(std.testing.allocator);
                for (0..count) |_| try call.args.append(std.testing.allocator, .{
                    .ty = case.ty,
                    .value = .{ .named = "argument" },
                    .attrs = if (case.ty == .ptr) "noundef nonnull align 8" else "noundef",
                });
                try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) == null);
                try std.testing.expectEqual(ValueLoc.eax, selector.values.get("result").?.loc);
                try std.testing.expectEqual(@as(u16, 1), selector.accumulator_domain.occupant.?.logical_bits);
            }
        }
    };
}

test "composed boolean calls retain the bounded argument and call envelope" {
    const cases = [_]struct {
        calling_conv: ?[]const u8 = null,
        ret_attrs: ?[]const u8 = null,
        tail_kind: ?[]const u8 = null,
        function_ty: ?[]const u8 = null,
        indirect: bool = false,
        argument: ?ir.CallArg = null,
        count: usize = 1,
        diagnostic: ?[]const u8 = null,
        failure: ?anyerror = null,
    }{
        .{ .ret_attrs = "zeroext zeroext", .diagnostic = "composed-block-call-form" },
        .{ .ret_attrs = "signext", .diagnostic = "composed-block-call-form" },
        .{ .calling_conv = "coldcc", .diagnostic = "composed-block-call-form" },
        .{ .indirect = true, .diagnostic = "composed-block-indirect-call" },
        .{ .tail_kind = "musttail", .failure = error.UnsupportedTailCallAbi },
        .{ .function_ty = "i1 (i64, ...)", .failure = error.UnsupportedVarargsAbi },
        .{ .argument = .{ .ty = .{ .int = 8 }, .value = .{ .named = "argument" } }, .diagnostic = "composed-block-boolean-call-arg-type" },
        .{ .argument = .{ .ty = .{ .int = 64 }, .value = .{ .int = 1 } }, .diagnostic = "composed-block-boolean-call-arg-value" },
        .{ .argument = .{ .ty = .ptr, .value = .{ .named = "@global" } }, .diagnostic = "composed-block-boolean-call-arg-value" },
        .{ .argument = .{ .ty = .{ .int = 64 }, .attrs = "zeroext", .value = .{ .named = "argument" } }, .failure = error.UnsupportedCallAttributeAbi },
        .{ .argument = .{ .ty = .{ .int = 64 }, .value = .{ .named = "argument" } }, .count = 7, .diagnostic = "composed-block-boolean-call-arg-count" },
    };
    for (cases) |case| {
        var machine = MachineFunction.init("boolean-call-boundary", .{ .int = 1 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        const saved_flags = selector.eflags.snapshot();
        var call = ir.CallInst{
            .ret_ty = .{ .int = 1 },
            .callee = "callee",
            .args = .empty,
            .ret_attrs = case.ret_attrs,
            .calling_conv = case.calling_conv,
            .tail_kind = case.tail_kind,
            .callee_function_ty = case.function_ty,
            .callee_value = if (case.indirect) .{ .named = "callee" } else null,
        };
        defer call.deinit(std.testing.allocator);
        if (case.argument) |argument| for (0..case.count) |_| {
            try call.args.append(std.testing.allocator, argument);
        };
        if (case.failure) |failure| {
            try std.testing.expectError(failure, selector_calls.lowerCall(&selector, "result", call));
        } else {
            const diagnostic = (try selector_calls.lowerCall(&selector, "result", call)).?;
            try std.testing.expectEqualStrings(case.diagnostic.?, diagnostic.detail());
        }
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expectEqual(@as(usize, 0), machine.owned_labels.items.len);
        try std.testing.expectEqual(@as(usize, 0), selector.values.count());
        try selector.eflags.validateSnapshot(saved_flags);
    }
}

test "composed selector lowers tail and notail calls ordinarily and rejects musttail" {
    const input =
        \\declare float @callee(float)
        \\define float @tail_caller(float %value) {
        \\entry:
        \\  %result = tail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\define float @notail_caller(float %value) {
        \\entry:
        \\  %result = notail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\define float @musttail_caller(float %value) {
        \\entry:
        \\  %result = musttail call float @callee(float %value)
        \\  ret float %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    for (module.functions.items[0..2]) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        var saw_call = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .direct_call => saw_call = true,
            .direct_jump => return error.UnexpectedTailJump,
            else => {},
        };
        try std.testing.expect(saw_call);
    }
    var musttail_machine = MachineFunction.init("musttail_caller", .float);
    defer musttail_machine.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnsupportedTailCallAbi, impl.tryLowerComposedCfg(std.testing.allocator, &musttail_machine, module.functions.items[2]));
}

test "machine verifier assigns direct call results to their ABI register class" {
    var fp_machine = MachineFunction.init("fp", .float);
    defer fp_machine.deinit(std.testing.allocator);
    try fp_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "callee", .ret_ty = .float } },
        .add_rsp_8,
        .ret,
    });
    try x86_64_verify.verifyFunction(fp_machine);

    var integer_machine = MachineFunction.init("integer", .{ .int = 32 });
    defer integer_machine.deinit(std.testing.allocator);
    try integer_machine.instructions.appendSlice(std.testing.allocator, &.{
        .sub_rsp_8,
        .{ .direct_call = .{ .symbol = "callee", .ret_ty = .float } },
        .add_rsp_8,
        .ret,
    });
    try std.testing.expectError(error.ReturnRegisterUndefined, x86_64_verify.verifyFunction(integer_machine));
}

test "generic cfg selector lowers exact i128 comparison intrinsics" {
    inline for (.{
        .{ .callee = "llvm.ucmp.i32.i128", .signed = false },
        .{ .callee = "llvm.scmp.i32.i128", .signed = true },
    }) |case| {
        var machine = MachineFunction.init("i128-compare", .{ .int = 32 });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } });
        try selector_state.bindValueLoc(&selector, "rhs", .{ .arg128 = .{ .lo = .rdx, .hi = .rcx } });

        var call = ir.CallInst{
            .ret_ty = .{ .int = 32 },
            .callee = case.callee,
            .tail_kind = "tail",
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 128 }, .value = .{ .named = "lhs" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 128 }, .value = .{ .named = "rhs" } });

        try std.testing.expect((try selector_calls.lowerCall(&selector, "comparison", call)) == null);
        try std.testing.expectEqual(ValueLoc.eax, selector_state.valueLoc(&selector, "comparison").?);
        const expected_tags = [_]std.meta.Tag(x86_64_machine.Instruction){
            .cmp_rcx_arg64,
            .jne,
            .cmp_rdx_rdi,
            .jne,
            .mov_imm_eax,
            .jmp,
            .label,
            if (case.signed) .setg_eax else .seta_eax,
            .shl_eax_imm5,
            .add_eax_imm32,
            .jmp,
            .label,
            .setb_eax,
            .shl_eax_imm5,
            .add_eax_imm32,
            .label,
        };
        try std.testing.expectEqual(expected_tags.len, machine.instructions.items.len);
        for (machine.instructions.items, expected_tags) |instruction, expected_tag| {
            try std.testing.expectEqual(expected_tag, std.meta.activeTag(instruction));
        }
        try std.testing.expectEqualStrings("__zllvm_edge_0", machine.instructions.items[1].jne);
        try std.testing.expectEqualStrings("__zllvm_edge_1", machine.instructions.items[3].jne);
        try std.testing.expectEqualStrings("__zllvm_edge_2_generic_cfg_select_end", machine.instructions.items[5].jmp);
        try std.testing.expectEqualStrings("__zllvm_edge_0", machine.instructions.items[6].label);
        try std.testing.expectEqualStrings("__zllvm_edge_2_generic_cfg_select_end", machine.instructions.items[10].jmp);
        try std.testing.expectEqualStrings("__zllvm_edge_1", machine.instructions.items[11].label);
        try std.testing.expectEqualStrings("__zllvm_edge_2_generic_cfg_select_end", machine.instructions.items[15].label);
    }
}

test "generic cfg selector keeps other integer comparison intrinsics fail closed" {
    inline for (.{
        .{ .callee = "llvm.ucmp.i32.i64", .ret_bits = 32, .arg_bits = 64 },
        .{ .callee = "llvm.scmp.i32.i64", .ret_bits = 32, .arg_bits = 64 },
        .{ .callee = "llvm.ucmp.i32.i128", .ret_bits = 64, .arg_bits = 128 },
    }) |case| {
        var machine = MachineFunction.init("i128-compare-near-miss", .{ .int = case.ret_bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "lhs", if (case.arg_bits == 128)
            .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } }
        else
            .{ .arg64 = .rdi });
        try selector_state.bindValueLoc(&selector, "rhs", if (case.arg_bits == 128)
            .{ .arg128 = .{ .lo = .rdx, .hi = .rcx } }
        else
            .{ .arg64 = .rsi });

        var call = ir.CallInst{
            .ret_ty = .{ .int = case.ret_bits },
            .callee = case.callee,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = case.arg_bits }, .value = .{ .named = "lhs" } });
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = case.arg_bits }, .value = .{ .named = "rhs" } });

        const diagnostic = (try selector_calls.lowerCall(&selector, "comparison", call)).?;
        try std.testing.expect(std.mem.startsWith(u8, diagnostic.detail(), "composed-block-"));
    }
}

test "generic cfg selector executes signed and unsigned i128 comparisons" {
    const input =
        \\declare i32 @llvm.ucmp.i32.i128(i128, i128)
        \\declare i32 @llvm.scmp.i32.i128(i128, i128)
        \\define i32 @unsigned_compare(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %comparison = call i32 @llvm.ucmp.i32.i128(i128 %lhs, i128 %rhs)
        \\  ret i32 %comparison
        \\}
        \\define i32 @signed_compare(i128 %lhs, i128 %rhs) {
        \\entry:
        \\  %comparison = call i32 @llvm.scmp.i32.i128(i128 %lhs, i128 %rhs)
        \\  ret i32 %comparison
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var mappings: [2]?[]align(std.heap.page_size_min) u8 = .{ null, null };
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

    const unsigned_compare: *const fn (u128, u128) callconv(.c) i32 = @ptrCast(mappings[0].?.ptr);
    const signed_compare: *const fn (i128, i128) callconv(.c) i32 = @ptrCast(mappings[1].?.ptr);
    const cases = [_]struct {
        lhs: u128,
        rhs: u128,
        unsigned: i32,
        signed: i32,
    }{
        .{ .lhs = 0, .rhs = 0, .unsigned = 0, .signed = 0 },
        .{ .lhs = 1, .rhs = 0, .unsigned = 1, .signed = 1 },
        .{ .lhs = 0, .rhs = 1, .unsigned = -1, .signed = -1 },
        .{ .lhs = 0xffff_ffff_ffff_ffff, .rhs = 0xffff_ffff_ffff_fffe, .unsigned = 1, .signed = 1 },
        .{ .lhs = 0xffff_ffff_ffff_fffe, .rhs = 0xffff_ffff_ffff_ffff, .unsigned = -1, .signed = -1 },
        .{ .lhs = std.math.maxInt(u128), .rhs = 0, .unsigned = 1, .signed = -1 },
        .{ .lhs = @as(u128, 1) << 127, .rhs = 0, .unsigned = 1, .signed = -1 },
        .{ .lhs = (@as(u128, 1) << 127) - 1, .rhs = @as(u128, 1) << 127, .unsigned = -1, .signed = 1 },
        .{ .lhs = (@as(u128, 7) << 64) | 3, .rhs = (@as(u128, 7) << 64) | 4, .unsigned = -1, .signed = -1 },
        .{ .lhs = (@as(u128, 7) << 64) | 4, .rhs = (@as(u128, 7) << 64) | 3, .unsigned = 1, .signed = 1 },
    };
    for (cases) |case| {
        try std.testing.expectEqual(case.unsigned, unsigned_compare(case.lhs, case.rhs));
        try std.testing.expectEqual(case.signed, signed_compare(@bitCast(case.lhs), @bitCast(case.rhs)));
    }
}

test "generic cfg selector keeps bit permutation near misses fail closed" {
    inline for (.{
        .{ .callee = "llvm.bswap.i128", .ret_bits = 64, .arg_bits = 128, .tail_kind = @as(?[]const u8, null) },
        .{ .callee = "llvm.bitreverse.i64", .ret_bits = 64, .arg_bits = 32, .tail_kind = @as(?[]const u8, null) },
        .{ .callee = "llvm.bitreverse.i128", .ret_bits = 128, .arg_bits = 128, .tail_kind = @as(?[]const u8, "musttail") },
        .{ .callee = "llvm.bswap.i64", .ret_bits = 64, .arg_bits = 64, .tail_kind = @as(?[]const u8, null) },
    }) |case| {
        var machine = MachineFunction.init("bit-permutation-near-miss", .{ .int = case.ret_bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        var call = ir.CallInst{
            .ret_ty = .{ .int = case.ret_bits },
            .callee = case.callee,
            .tail_kind = case.tail_kind,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = case.arg_bits }, .value = .{ .named = "value" } });
        try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) != null);
    }
}

test "generic cfg selector executes exact i64 and i128 bit permutations" {
    const input =
        \\declare i128 @llvm.bswap.i128(i128)
        \\declare i64 @llvm.bitreverse.i64(i64)
        \\declare i128 @llvm.bitreverse.i128(i128)
        \\define i128 @byte_swap_i128(i128 %value) {
        \\entry:
        \\  %result = tail call i128 @llvm.bswap.i128(i128 %value)
        \\  ret i128 %result
        \\}
        \\define i64 @bit_reverse_i64(i64 %value) {
        \\entry:
        \\  %result = tail call i64 @llvm.bitreverse.i64(i64 %value)
        \\  ret i64 %result
        \\}
        \\define i128 @bit_reverse_i128(i128 %value) {
        \\entry:
        \\  %result = tail call i128 @llvm.bitreverse.i128(i128 %value)
        \\  ret i128 %result
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
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        mappings[index] = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mappings[index].?, bytes);
    }

    const byte_swap_i128: *const fn (u128) callconv(.c) u128 = @ptrCast(mappings[0].?.ptr);
    const bit_reverse_i64: *const fn (u64) callconv(.c) u64 = @ptrCast(mappings[1].?.ptr);
    const bit_reverse_i128: *const fn (u128) callconv(.c) u128 = @ptrCast(mappings[2].?.ptr);
    inline for (.{
        .{ @as(u64, 0), @as(u64, 0) },
        .{ @as(u64, 1), @as(u64, 0x8000_0000_0000_0000) },
        .{ @as(u64, 0x8000_0000_0000_0000), @as(u64, 1) },
        .{ @as(u64, 0x0123_4567_89ab_cdef), @as(u64, 0xf7b3_d591_e6a2_c480) },
        .{ std.math.maxInt(u64), std.math.maxInt(u64) },
    }) |case| try std.testing.expectEqual(case[1], bit_reverse_i64(case[0]));
    inline for (.{
        .{ @as(u128, 0), @as(u128, 0) },
        .{ @as(u128, 1), @as(u128, 1) << 120 },
        .{
            @as(u128, 0x0123_4567_89ab_cdef_fedc_ba98_7654_3210),
            @as(u128, 0x1032_5476_98ba_dcfe_efcd_ab89_6745_2301),
        },
    }) |case| try std.testing.expectEqual(case[1], byte_swap_i128(case[0]));
    inline for (.{
        .{ @as(u128, 0), @as(u128, 0) },
        .{ @as(u128, 1), @as(u128, 1) << 127 },
        .{ @as(u128, 1) << 127, @as(u128, 1) },
        .{
            @as(u128, 0x0123_4567_89ab_cdef_fedc_ba98_7654_3210),
            @as(u128, 0x084c_2a6e_195d_3b7f_f7b3_d591_e6a2_c480),
        },
        .{ std.math.maxInt(u128), std.math.maxInt(u128) },
    }) |case| try std.testing.expectEqual(case[1], bit_reverse_i128(case[0]));
}

test "generic cfg selector executes boolean calls with loaded and live pointer arguments" {
    for ([_]bool{ false, true }) |loaded| {
        const input = try std.fmt.allocPrint(std.testing.allocator, "declare fastcc i1 @read_boolean(ptr)\ndefine i64 @probe(ptr %input, i64 %salt) {{\nentry:\n{s}  %tag = add i64 %salt, 17\n  %flag = call fastcc i1 @read_boolean(ptr {s})\n  %wide = zext i1 %flag to i64\n  %after = load i64, ptr %input, align 8\n  %both = xor i64 %after, %tag\n  %result = xor i64 %both, %wide\n  ret i64 %result\n}}\n", .{ if (loaded) "  %slot = alloca ptr, align 8\n  store ptr %input, ptr %slot, align 8\n  %pointer = load ptr, ptr %slot, align 8\n" else "", if (loaded) "%pointer" else "%input" });
        defer std.testing.allocator.free(input);
        var module = try ir.Module.parse(std.testing.allocator, input);
        defer module.deinit();
        try module.verify();
        const function = module.functions.items[0];
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try @import("../generic_cfg_selector.zig").tryLower(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        // Read *RDI, return a valid AL with dirty upper bits, and clobber all
        // volatile integer argument registers as an ordinary callee may.
        const stub = [_]u8{
            0x48, 0x8b, 0x07, 0x83, 0xe0, 0x01,
            0x49, 0xba, 0x00, 0x00, 0xfe, 0xca,
            0xef, 0xbe, 0xad, 0xde, 0x4c, 0x09,
            0xd0, 0x31, 0xff, 0x31, 0xf6, 0x31,
            0xd2, 0x31, 0xc9, 0x45, 0x31, 0xc0,
            0x45, 0x31, 0xc9, 0x45, 0x31, 0xd2,
            0x45, 0x31, 0xdb, 0xc3,
        };
        const mapping = try std.posix.mmap(null, bytes.len + stub.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping[0..bytes.len], bytes);
        @memcpy(mapping[bytes.len..][0..stub.len], &stub);
        var offset: usize = 0;
        var calls: usize = 0;
        for (machine.instructions.items) |instruction| {
            if (instruction == .direct_call) {
                try std.testing.expectEqualStrings("read_boolean", instruction.direct_call.symbol);
                std.mem.writeInt(i32, mapping[offset + 1 ..][0..4], @intCast(bytes.len - (offset + 5)), .little);
                calls += 1;
            }
            offset += encoding.instructionSize(instruction);
        }
        try std.testing.expectEqual(@as(usize, 1), calls);
        const run: *const fn (*const u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
        for ([_]u64{ 0, 1, 2, 3, 0xdead_beef_cafe_0123, std.math.maxInt(u64) }) |value| for ([_]u64{ 0, 1, 0x1234_5678_9abc_def0, std.math.maxInt(u64) }) |salt| {
            try std.testing.expectEqual(value ^ (salt +% 17) ^ (value & 1), run(&value, salt));
        };
    }
}

test "generic cfg selector keeps range-attributed popcount near misses fail closed" {
    inline for (.{
        .{ .callee = "llvm.ctpop.i64", .ret_bits = 64, .arg_bits = 64, .ret_attrs = @as(?[]const u8, "range(i64 1, 1)"), .tail_kind = @as(?[]const u8, "tail") },
        .{ .callee = "llvm.ctpop.i64", .ret_bits = 64, .arg_bits = 64, .ret_attrs = @as(?[]const u8, "range(i32 0, 65)"), .tail_kind = @as(?[]const u8, "tail") },
        .{ .callee = "llvm.ctpop.i64", .ret_bits = 64, .arg_bits = 64, .ret_attrs = @as(?[]const u8, "range(i64 0, 65), zeroext"), .tail_kind = @as(?[]const u8, "tail") },
        .{ .callee = "llvm.ctpop.i64", .ret_bits = 64, .arg_bits = 32, .ret_attrs = @as(?[]const u8, "range(i64 0, 65)"), .tail_kind = @as(?[]const u8, "tail") },
        .{ .callee = "llvm.ctpop.i128", .ret_bits = 128, .arg_bits = 128, .ret_attrs = @as(?[]const u8, "range(i128 0, 129)"), .tail_kind = @as(?[]const u8, "musttail") },
        .{ .callee = "llvm.ctpop.i32", .ret_bits = 32, .arg_bits = 32, .ret_attrs = @as(?[]const u8, "range(i32 0, 33)"), .tail_kind = @as(?[]const u8, "tail") },
    }) |case| {
        var machine = MachineFunction.init("ctpop-near-miss", .{ .int = case.ret_bits });
        defer machine.deinit(std.testing.allocator);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        try selector_state.bindValueLoc(&selector, "value", if (case.arg_bits == 128) .{ .arg128 = .{ .lo = .rdi, .hi = .rsi } } else .{ .arg64 = .rdi });
        var call = ir.CallInst{
            .ret_ty = .{ .int = case.ret_bits },
            .callee = case.callee,
            .ret_attrs = case.ret_attrs,
            .tail_kind = case.tail_kind,
            .args = .empty,
        };
        defer call.deinit(std.testing.allocator);
        try call.args.append(std.testing.allocator, .{ .ty = .{ .int = case.arg_bits }, .value = .{ .named = "value" } });
        try std.testing.expect((try selector_calls.lowerCall(&selector, "result", call)) != null);
    }
}

test "generic cfg selector executes i64 and i128 popcount with optional range attributes" {
    const input =
        \\declare i64 @llvm.ctpop.i64(i64)
        \\declare i128 @llvm.ctpop.i128(i128)
        \\define i64 @popcount_i64(i64 %value) {
        \\entry:
        \\  %result = tail call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %value)
        \\  ret i64 %result
        \\}
        \\define i128 @popcount_i128(i128 %value) {
        \\entry:
        \\  %result = notail call range(i128 0, 129) i128 @llvm.ctpop.i128(i128 %value)
        \\  ret i128 %result
        \\}
        \\define i64 @plain_popcount_i64(i64 %value) {
        \\entry:
        \\  %result = call i64 @llvm.ctpop.i64(i64 %value)
        \\  ret i64 %result
        \\}
        \\define i128 @plain_popcount_i128(i128 %value) {
        \\entry:
        \\  %result = call i128 @llvm.ctpop.i128(i128 %value)
        \\  ret i128 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var mappings: [4]?[]align(std.heap.page_size_min) u8 = @splat(null);
    defer for (mappings) |mapping| if (mapping) |bytes| std.posix.munmap(bytes);
    for (module.functions.items, 0..) |function_ir, index| {
        var machine = MachineFunction.init(function_ir.name, function_ir.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function_ir));
        try x86_64_verify.verifyFunction(machine);
        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        try std.testing.expect(std.mem.indexOf(u8, bytes, &.{ 0xf3, 0x48, 0x0f, 0xb8 }) == null);
        mappings[index] = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        @memcpy(mappings[index].?, bytes);
    }

    const popcount_i64: *const fn (u64) callconv(.c) u64 = @ptrCast(mappings[0].?.ptr);
    const popcount_i128: *const fn (u128) callconv(.c) u128 = @ptrCast(mappings[1].?.ptr);
    inline for (.{
        .{ @as(u64, 0), @as(u64, 0) },
        .{ @as(u64, 1), @as(u64, 1) },
        .{ @as(u64, 0x8000_0000_0000_0001), @as(u64, 2) },
        .{ @as(u64, 0x0123_4567_89ab_cdef), @as(u64, 32) },
        .{ std.math.maxInt(u64), @as(u64, 64) },
    }) |case| {
        try std.testing.expectEqual(case[1], popcount_i64(case[0]));
        const plain: *const fn (u64) callconv(.c) u64 = @ptrCast(mappings[2].?.ptr);
        try std.testing.expectEqual(case[1], plain(case[0]));
    }
    inline for (.{
        .{ @as(u128, 0), @as(u128, 0) },
        .{ @as(u128, 1), @as(u128, 1) },
        .{ @as(u128, 1) << 127, @as(u128, 1) },
        .{ (@as(u128, 1) << 127) | 1, @as(u128, 2) },
        .{ @as(u128, 0x0123_4567_89ab_cdef_fedc_ba98_7654_3210), @as(u128, 64) },
        .{ std.math.maxInt(u128), @as(u128, 128) },
    }) |case| {
        try std.testing.expectEqual(case[1], popcount_i128(case[0]));
        const plain: *const fn (u128) callconv(.c) u128 = @ptrCast(mappings[3].?.ptr);
        try std.testing.expectEqual(case[1], plain(case[0]));
    }
}

test "native ctpop preserves fastcc intrinsic admission" {
    const input =
        \\declare fastcc i64 @llvm.ctpop.i64(i64)
        \\define i64 @fastcc_popcount(i64 %value) {
        \\entry:
        \\  %result = call fastcc i64 @llvm.ctpop.i64(i64 %value)
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const function = module.functions.items[0];
    var machine = MachineFunction.init(function.name, function.ret_ty);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const run: *const fn (u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 32), run(0x0123456789abcdef));
}

test "destructive intrinsic preserves a live accumulator input" {
    const input =
        \\declare i64 @llvm.ctpop.i64(i64)
        \\define i64 @live_count(i16 %raw) {
        \\entry:
        \\  %value = zext i16 %raw to i64
        \\  %count = call range(i64 0, 65) i64 @llvm.ctpop.i64(i64 %value)
        \\  %sum = add i64 %value, 9
        \\  %negative = sub i64 0, %value
        \\  %aligned = and i64 %sum, %negative
        \\  %result = add i64 %aligned, %count
        \\  ret i64 %result
        \\}
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    var machine = MachineFunction.init("live_count", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);
    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const run: *const fn (u16) callconv(.c) u64 = @ptrCast(mapping.ptr);
    for ([_]u16{ 0, 1, 2, 4, 8, 16, 32, 64, 80, 128, 255, 256, 1024, 32768, 65535 }) |raw| {
        const value: u64 = raw;
        try std.testing.expectEqual(((value + 9) & (0 -% value)) + @popCount(value), run(raw));
    }
}

test "destructive intrinsic keeps canonical liveness failure closed" {
    var machine = MachineFunction.init("invalid-live-count", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "value", .rax);
    try selector.address_dependencies.replaceAddress("owner", &.{
        .{ .name = "value", .identity_type = .integer, .role = .index },
    });
    var call = ir.CallInst{ .ret_ty = .{ .int = 64 }, .callee = "llvm.ctpop.i64", .args = .empty };
    defer call.deinit(std.testing.allocator);
    try call.args.append(std.testing.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = "value" } });
    const original_binding = selector.values.get("value").?;
    try std.testing.expectError(error.AddressDependencyMissingPlan, selector_calls.lowerCall(&selector, "result", call));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(original_binding, selector.values.get("value").?);
    try std.testing.expect(!selector.values.contains("result"));
    try selector.phi_results.put("value", {});
    try std.testing.expectError(error.AddressDependencyMissingPlan, selector_calls.lowerCall(&selector, "result", call));
    try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
    try std.testing.expectEqual(original_binding, selector.values.get("value").?);
    try std.testing.expect(!selector.values.contains("result"));
}
