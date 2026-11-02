const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_verify = @import("../verify.zig");
const constant_table = @import("../constant_table.zig");
const encoding = @import("../../../mc/encoding.zig");
const elf = @import("../../../mc/elf.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const impl = @import("composed_selector_impl.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_cfg = @import("composed_selector_cfg.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");

const MachineFunction = impl.MachineFunction;
const ComposedBlockSelector = impl.ComposedBlockSelector;
const ValueLoc = selector_types.ValueLoc;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;

const floateidf_i56_fixture =
    \\define double @compiler_rt.floateidf.__floateidf(ptr nonnull readonly %p, i64 %bits) {
    \\Entry:
    \\  %cond = trunc i64 %bits to i16
    \\  switch i16 %cond, label %Default [
    \\    i16 0, label %Join
    \\    i16 1, label %Case1
    \\    i16 2, label %Case2
    \\    i16 3, label %Case3
    \\    i16 4, label %Case4
    \\  ]
    \\Case1:
    \\  %v1 = load i32, ptr %p, align 1
    \\  %r1 = sitofp i32 %v1 to double
    \\  br label %Join
    \\Case2:
    \\  %v2 = load i64, ptr %p, align 1
    \\  %r2 = sitofp i64 %v2 to double
    \\  br label %Join
    \\Case3:
    \\  %v3 = load i96, ptr %p, align 1
    \\  %r3 = sitofp i96 %v3 to double
    \\  br label %Join
    \\Case4:
    \\  %v4 = load i128, ptr %p, align 1
    \\  %r4 = sitofp i128 %v4 to double
    \\  br label %Join
    \\Default:
    \\  %v56 = load i56, ptr %p, align 1
    \\  %r56 = sitofp i56 %v56 to double
    \\  br label %Join
    \\Join:
    \\  %result = phi double [ 0.000000e+00, %Entry ], [ %r1, %Case1 ], [ %r2, %Case2 ], [ %r3, %Case3 ], [ %r4, %Case4 ], [ %r56, %Default ]
    \\  ret double %result
    \\}
    \\
;

test "migrated readonly i56 load keeps logical domain and records exact EFLAGS writes" {
    var module = try ir.Module.parse(std.testing.allocator, floateidf_i56_fixture);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("i56-load-binding", .{ .int = 56 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("p", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.function = &module.functions.items[0];
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 24;
    try selector.readonly_pointer_params.put("p", {});
    try selector_state.bindValueLoc(&selector, "p", .{ .arg64 = .rdi });
    try selector.eflags.apply(.definition);
    try selector.eflags.apply(.use);
    const semantics_before = selector.eflags_semantics.items.len;

    try std.testing.expect((try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .{ .int = 56 },
        .ptr = .{ .named = "p" },
    })) == null);

    const binding = selector.values.get("loaded").?;
    try std.testing.expectEqual(@as(u16, 64), binding.vreg.bits);
    try std.testing.expectEqual(ValueLoc.rax, binding.loc);
    try std.testing.expectEqual(@as(u16, 56), selector.accumulator_domain.occupantFor(.rax).?.logical_bits);
    try std.testing.expectEqual(@as(u16, 64), selector.accumulator_domain.defined_bits);
    try std.testing.expectEqual(semantics_before + 4, selector.eflags_semantics.items.len);
    try std.testing.expectEqual(
        selector_state.EflagsLiveness.Snapshot{ .status = .undefined, .definition_purpose = null },
        selector.eflags.snapshot(),
    );

    _ = selector_state.removeValueBinding(&selector, "p");
    try std.testing.expect((try selector_state.preserveLiveAccumulatorValue(&selector, "loaded")) == null);
    try std.testing.expectEqual(ValueLoc{ .scratch64 = .rdi }, selector.values.get("loaded").?.loc);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_rax_to_arg = .rdi }, machine.instructions.items[machine.instructions.items.len - 1]);
}

test "exact floateidf i56 path executes byte-six and maximal low-56-bit patterns" {
    var module = try ir.Module.parse(std.testing.allocator, floateidf_i56_fixture);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init(module.functions.items[0].name, .double);
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn ([*]const u8, usize) callconv(.c) f64 = @ptrCast(mapping.ptr);

    const byte_six_set = [_]u8{ 0, 0, 0, 0, 0, 0, 1 };
    const maximal_low_56: [7]u8 = @splat(0xff);
    try std.testing.expectEqual(@as(f64, 281_474_976_710_656), function(&byte_six_set, 56));
    try std.testing.expectEqual(@as(f64, -1), function(&maximal_low_56, 56));
}

test "migrated readonly pair loads retain post-staging chooser timing and limb widths" {
    const Case = struct {
        bits: u16,
        pointer: ValueLoc,
        expected: []const x86_64_machine.Instruction,
    };
    const cases = [_]Case{
        .{
            .bits = 96,
            .pointer = .{ .arg64 = .rcx },
            .expected = &.{
                .{ .mov_arg64_arg = .{ .dst = .rdi, .src = .rcx } },
                .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } },
                .{ .mov_rax_to_arg = .rcx },
                .{ .load_arg_ptr_disp8_eax = .{ .reg = .rdi, .offset = 8 } },
                .{ .mov_rax_to_arg = .rdx },
            },
        },
        .{
            .bits = 128,
            .pointer = .{ .spill64 = .slot3 },
            .expected = &.{
                .{ .reload_arg64_rsp = .{ .reg = .rdi, .frame_index = .slot3 } },
                .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 0 } },
                .{ .mov_rax_to_arg = .rcx },
                .{ .load_arg_ptr_disp8_rax = .{ .reg = .rdi, .offset = 8 } },
                .{ .mov_rax_to_arg = .rdx },
            },
        },
    };

    for (cases) |case| {
        var machine = MachineFunction.init("readonly-pair-production", .{ .int = case.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("p", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 64;
        try selector.readonly_pointer_params.put("p", {});
        try selector_state.bindValueLoc(&selector, "p", case.pointer);

        try std.testing.expect((try selector_memory.lowerLoad(&selector, "loaded", .{
            .ty = .{ .int = case.bits },
            .ptr = .{ .named = "p" },
        })) == null);

        try std.testing.expectEqualSlices(x86_64_machine.Instruction, case.expected, machine.instructions.items);
        try std.testing.expectEqual(ValueLoc{ .scratch128 = pair_a }, selector.values.get("loaded").?.loc);
    }
}

test "migrated readonly table i16 load retains register spill and R8 result forms" {
    const Case = struct {
        storage: selector_types.ReadOnlyTablePtrLoc.Storage,
        expected: []const x86_64_machine.Instruction,
    };
    const cases = [_]Case{
        .{
            .storage = .{ .reg = .rsi },
            .expected = &.{
                .{ .load_arg_ptr_disp8_u16_arg = .{ .base = .rsi, .dst = .r8, .offset = 0 } },
            },
        },
        .{
            .storage = .{ .spill = .slot2 },
            .expected = &.{
                .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
                .{ .load_arg_ptr_disp8_u16_arg = .{ .base = .rcx, .dst = .r8, .offset = 0 } },
            },
        },
    };

    for (cases) |case| {
        var machine = MachineFunction.init("readonly-table-i16-production", .{ .int = 16 });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("table", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        selector.stack_frame_bytes = 64;
        try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
            .storage = case.storage,
            .symbol = "@table",
            .shape = .i16_128,
        } });
        const saved_accumulator = selector.accumulator_domain;
        const saved_eflags = selector.eflags.snapshot();

        try std.testing.expect((try selector_memory.lowerLoad(&selector, "loaded", .{
            .ty = .{ .int = 16 },
            .ptr = .{ .named = "table" },
        })) == null);

        try std.testing.expectEqualSlices(x86_64_machine.Instruction, case.expected, machine.instructions.items);
        try std.testing.expectEqual(ValueLoc{ .scratch32 = .r8 }, selector.values.get("loaded").?.loc);
        try std.testing.expectEqual(saved_accumulator, selector.accumulator_domain);
        try selector.eflags.validateSnapshot(saved_eflags);
    }
}

test "readonly table double load remains on the direct O3 path instruction-identically" {
    var machine = MachineFunction.init("readonly-table-double-production", .double);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("table", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 64;
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot2 },
        .symbol = "@table",
        .shape = .f64_pair_128,
        .offset = 8,
    } });

    try std.testing.expect((try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .double,
        .ptr = .{ .named = "table" },
    })) == null);

    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
        .{ .load_arg_ptr_disp8_xmm = .{ .base = .rcx, .dst = .xmm0, .offset = 8 } },
    }, machine.instructions.items);
    try std.testing.expectEqual(
        ValueLoc{ .xmm = .{ .reg = .xmm0, .bits = 64 } },
        selector.values.get("loaded").?.loc,
    );
}

test "readonly table i16 rejected type preserves spill-before-type diagnostic precedence" {
    var machine = MachineFunction.init("readonly-table-i16-rejected-type", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("table", 2);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 64;
    try selector_state.bindValueLoc(&selector, "table", .{ .readonly_table_ptr = .{
        .storage = .{ .spill = .slot2 },
        .symbol = "@table",
        .shape = .i16_128,
    } });

    const diagnostic = (try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .{ .int = 32 },
        .ptr = .{ .named = "table" },
    })).?;
    try std.testing.expectEqualStrings(
        "composed-block-load-readonly-table-type",
        diagnostic.no_emitter,
    );
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot2 } },
    }, machine.instructions.items);
    try std.testing.expect(selector.values.get("loaded") == null);
}

test "migrated pointer load displaces one and multiple accumulator aliases instruction-identically" {
    inline for (.{ @as(usize, 1), @as(usize, 2) }) |alias_count| {
        var baseline_machine = MachineFunction.init("load-alias-baseline", .{ .int = 32 });
        defer baseline_machine.deinit(std.testing.allocator);
        var migrated_machine = MachineFunction.init("load-alias-migrated", .{ .int = 32 });
        defer migrated_machine.deinit(std.testing.allocator);
        var baseline_plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer baseline_plan.deinit();
        var migrated_plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer migrated_plan.deinit();
        try baseline_plan.interval_ends.put("eax_alias", 10);
        try migrated_plan.interval_ends.put("eax_alias", 10);
        try baseline_plan.interval_ends.put("ptr", 10);
        try migrated_plan.interval_ends.put("ptr", 10);
        if (alias_count == 2) {
            try baseline_plan.interval_ends.put("rax_alias", 10);
            try migrated_plan.interval_ends.put("rax_alias", 10);
        }

        var baseline = ComposedBlockSelector.init(std.testing.allocator, &baseline_machine);
        defer baseline.deinit();
        baseline.allocation_plan = &baseline_plan;
        baseline.stack_frame_bytes = 24;
        var migrated = ComposedBlockSelector.init(std.testing.allocator, &migrated_machine);
        defer migrated.deinit();
        migrated.allocation_plan = &migrated_plan;
        migrated.stack_frame_bytes = 24;

        inline for (.{ &baseline, &migrated }) |selector| {
            try selector_state.bindValueLoc(selector, "ptr", .{ .arg64 = .rdi });
            try selector_state.bindValueLoc(selector, "eax_alias", .eax);
            if (alias_count == 2) try selector_state.bindValueLoc(selector, "rax_alias", .rax);
        }

        try selector_state.clobberAccumulator(&baseline);
        try baseline.machine.instructions.append(std.testing.allocator, .{ .load_arg_ptr_eax = .rdi });
        try selector_state.bindEax(&baseline, "loaded");

        try std.testing.expect((try selector_memory.lowerLoad(&migrated, "loaded", .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "ptr" },
        })) == null);
        try std.testing.expectEqualSlices(
            x86_64_machine.Instruction,
            baseline_machine.instructions.items,
            migrated_machine.instructions.items,
        );
        try std.testing.expectEqual(selector_state.valueLoc(&baseline, "eax_alias"), selector_state.valueLoc(&migrated, "eax_alias"));
        if (alias_count == 2) try std.testing.expectEqual(selector_state.valueLoc(&baseline, "rax_alias"), selector_state.valueLoc(&migrated, "rax_alias"));
    }
}

test "migrated ordinary load maps only attributed closed variants to the four legacy i16 diagnostics" {
    const cases = [_]struct {
        name: []const u8,
        loc: ValueLoc,
        bits: u16 = 16,
        detail: []const u8,
    }{
        .{
            .name = "stack-scalar",
            .loc = .{ .stack_scalar = .{ .base_disp = 0, .bits = 8, .kind = .integer } },
            .detail = "composed-block-load-stack-width",
        },
        .{
            .name = "stack-array",
            .loc = .{ .stack_i32_array = .{ .base_disp = 0, .len = 4 } },
            .detail = "composed-block-load-stack-array-width",
        },
        .{
            .name = "stack-pointer",
            .loc = .{ .stack_i32_ptr = .{ .disp = 0 } },
            .detail = "composed-block-load-stack-array-width",
        },
        .{
            .name = "gpr-pointer",
            .loc = .{ .arg64 = .rdi },
            .bits = 128,
            .detail = "composed-block-load-ptr-width",
        },
        .{
            .name = "rejected-home",
            .loc = .{ .arg32 = .rdi },
            .detail = "composed-block-load-ptr",
        },
    };
    for (cases) |case| {
        var machine = MachineFunction.init(case.name, .{ .int = case.bits });
        defer machine.deinit(std.testing.allocator);
        var plan = SelectorAllocationPlan.init(std.testing.allocator);
        defer plan.deinit();
        try plan.interval_ends.put("pointer", 1);
        var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
        defer selector.deinit();
        selector.allocation_plan = &plan;
        try selector_state.bindValueLoc(&selector, "pointer", case.loc);

        const diagnostic = (try selector_memory.lowerLoad(&selector, "loaded", .{
            .ty = .{ .int = case.bits },
            .ptr = .{ .named = "pointer" },
        })).?;
        try std.testing.expectEqualStrings(case.detail, diagnostic.no_emitter);
        try std.testing.expectEqual(@as(usize, 0), machine.instructions.items.len);
        try std.testing.expect(selector.values.get("loaded") == null);
    }

    var unresolved_machine = MachineFunction.init("unresolved", .{ .int = 32 });
    defer unresolved_machine.deinit(std.testing.allocator);
    var unresolved = ComposedBlockSelector.init(std.testing.allocator, &unresolved_machine);
    defer unresolved.deinit();
    try std.testing.expectError(
        error.ValueUseForwardPlanMissing,
        selector_memory.lowerLoad(&unresolved, "loaded", .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "missing" },
        }),
    );
}

test "migrated ordinary load supports u16 pointer load" {
    var machine = MachineFunction.init("load-u16", .{ .int = 16 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("pointer", 1);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    try selector_state.bindValueLoc(&selector, "pointer", .{ .arg64 = .rdi });

    try std.testing.expect((try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .{ .int = 16 },
        .ptr = .{ .named = "pointer" },
    })) == null);
    try std.testing.expectEqualSlices(
        x86_64_machine.Instruction,
        &.{.{ .load_arg_ptr_disp8_u16_eax = .{ .reg = .rdi, .offset = 0 } }},
        machine.instructions.items,
    );
    try std.testing.expectEqual(ValueLoc.eax, selector.values.get("loaded").?.loc);
}

test "migrated load production rollback restores full state before and after partial emission" {
    var machine = MachineFunction.init("load-production-rollback", .{ .int = 32 });
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("old", 10);
    try plan.interval_ends.put("bad-index-ptr", 10);
    try plan.interval_ends.put("ptr", 10);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "ptr", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "occupied", .{ .scratch32 = .rsi });
    var seed = try selector_state.AccumulatorDefinitionTransaction.begin(&selector);
    _ = try seed.prepare(.preserve, .spill_live);
    try seed.define("old", .zeroExtending(32));
    try seed.commit();
    seed.deinit();
    try selector_state.bindValueLoc(&selector, "bad-index-ptr", .{ .stack_i32_ptr = .{
        .disp = 0,
        .index = .{ .reg = .rcx, .name = "missing-index" },
    } });
    try selector.spill_slots.put("seed", .{ .base = 0, .slots = 1 });
    selector.next_spill_slot = 1;
    try machine.instructions.append(std.testing.allocator, .{ .mov_imm_eax = 11 });
    try selector.eflags.apply(.definition);

    const ptr_binding = selector.values.get("ptr").?;
    const bad_ptr_binding = selector.values.get("bad-index-ptr").?;
    const occupied_binding = selector.values.get("occupied").?;
    const old_binding = selector.values.get("old").?;
    const saved_domain = selector.accumulator_domain;
    const saved_address_dependencies = selector.address_dependencies;
    const saved_eflags = selector.eflags.snapshot();
    const saved_next_virtual_reg = selector.next_virtual_reg;
    const saved_next_spill_slot = selector.next_spill_slot;

    try std.testing.expectError(
        error.AddressDependencyMissingBinding,
        selector_memory.lowerLoad(&selector, "before-emission", .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "bad-index-ptr" },
        }),
    );
    try expectLoadRollbackState(
        &selector,
        ptr_binding,
        bad_ptr_binding,
        occupied_binding,
        old_binding,
        saved_domain,
        saved_address_dependencies,
        saved_eflags,
        saved_next_virtual_reg,
        saved_next_spill_slot,
    );

    try selector_state.bindValueLoc(&selector, "bad-index-ptr", .{ .stack_i32_ptr = .{ .disp = 0 } });
    const repaired_bad_ptr_binding = selector.values.get("bad-index-ptr").?;
    const repaired_address_dependencies = selector.address_dependencies;

    try std.testing.expectError(
        error.AccumulatorDefinitionAlreadyBound,
        selector_memory.lowerLoad(&selector, "occupied", .{
            .ty = .{ .int = 32 },
            .ptr = .{ .named = "ptr" },
        }),
    );
    try expectLoadRollbackState(
        &selector,
        ptr_binding,
        repaired_bad_ptr_binding,
        occupied_binding,
        old_binding,
        saved_domain,
        repaired_address_dependencies,
        saved_eflags,
        saved_next_virtual_reg,
        saved_next_spill_slot,
    );
}

fn expectLoadRollbackState(
    selector: *const ComposedBlockSelector,
    ptr_binding: selector_types.ValueBinding,
    bad_ptr_binding: selector_types.ValueBinding,
    occupied_binding: selector_types.ValueBinding,
    old_binding: selector_types.ValueBinding,
    saved_domain: selector_types.AccumulatorDomain,
    saved_address_dependencies: selector_state.AddressDependencies,
    saved_eflags: selector_state.EflagsLiveness.Snapshot,
    saved_next_virtual_reg: usize,
    saved_next_spill_slot: usize,
) !void {
    try std.testing.expectEqual(@as(usize, 1), selector.machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_imm_eax = 11 }, selector.machine.instructions.items[0]);
    try std.testing.expectEqual(@as(usize, 4), selector.values.count());
    try std.testing.expectEqual(ptr_binding, selector.values.get("ptr").?);
    try std.testing.expectEqual(bad_ptr_binding, selector.values.get("bad-index-ptr").?);
    try std.testing.expectEqual(occupied_binding, selector.values.get("occupied").?);
    try std.testing.expectEqual(old_binding, selector.values.get("old").?);
    try std.testing.expectEqual(@as(usize, 1), selector.spill_slots.count());
    try std.testing.expect(selector.spill_slots.get("seed") != null);
    try std.testing.expectEqual(saved_next_virtual_reg, selector.next_virtual_reg);
    try std.testing.expectEqual(saved_next_spill_slot, selector.next_spill_slot);
    try std.testing.expectEqual(saved_domain, selector.accumulator_domain);
    try std.testing.expect(selector.address_dependencies.eql(&saved_address_dependencies));
    try selector.eflags.validateSnapshot(saved_eflags);
}

test "stack i32 loads preserve accumulator values used only by phi edges" {
    const input =
        \\define i64 @phi_edge_live_across_stack_load(i64 %m, i64 %n) {
        \\Entry:
        \\  %slot = alloca [1 x i32], align 4
        \\  store i32 -2147483648, ptr %slot, align 4
        \\  %difference = sub i64 %m, %n
        \\  %loaded = load i32, ptr %slot, align 4
        \\  br label %Join
        \\Join:
        \\  %result = phi i64 [ %difference, %Entry ]
        \\  ret i64 %result
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    var machine = MachineFunction.init("phi_edge_live_across_stack_load", .{ .int = 64 });
    defer machine.deinit(std.testing.allocator);
    try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, module.functions.items[0]));
    try x86_64_verify.verifyFunction(machine);

    const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
    defer std.testing.allocator.free(bytes);
    const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(mapping);
    @memcpy(mapping, bytes);
    const function: *const fn (u64, u64) callconv(.c) u64 = @ptrCast(mapping.ptr);
    try std.testing.expectEqual(@as(u64, 2), function(5, 3));
}

test "generic cfg selector stores i64 through a spilled pointer" {
    var machine = MachineFunction.init("store-i64-spilled-ptr", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    try plan.interval_ends.put("out", 1);
    try plan.interval_ends.put("value", 1);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.stack_frame_bytes = 16;
    try selector_state.bindValueLoc(&selector, "out", .{ .spill64 = .slot0 });
    try selector_state.bindValueLoc(&selector, "value", .{ .arg64 = .rdi });

    const diagnostic = try selector_memory.lowerStore(&selector, .{
        .ty = .{ .int = 64 },
        .value = .{ .named = "value" },
        .ptr = .{ .named = "out" },
    });
    try std.testing.expect(diagnostic == null);
    try std.testing.expectEqual(@as(usize, 3), machine.instructions.items.len);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .slot0 } }, machine.instructions.items[0]);
    try std.testing.expectEqual(x86_64_machine.Instruction{ .mov_arg_rax = .rdi }, machine.instructions.items[1]);
    try std.testing.expectEqual(x86_64_machine.Instruction.store_rax_rcx_ptr, machine.instructions.items[2]);
}

test "lowerStore delegates the exact inbox92 wide spill binding to transaction compatibility" {
    var machine = MachineFunction.init("inbox92-store-production-wide-spill", .void);
    defer machine.deinit(std.testing.allocator);
    var plan = SelectorAllocationPlan.init(std.testing.allocator);
    defer plan.deinit();
    inline for (&.{ "%236", "index", "addend", "%166" }) |name|
        try plan.interval_ends.put(name, 395);

    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.allocation_plan = &plan;
    selector.current_position = 395;
    selector.stack_frame_bytes = 8192;
    try selector_state.bindValueLoc(&selector, "%236", .{ .spill64 = .{ .slot = 380 } });
    try selector_state.bindValueLoc(&selector, "index", .{ .spill64 = .{ .slot = 486 } });
    try selector_state.bindValueLoc(&selector, "addend", .{ .spill64 = .{ .slot = 450 } });
    try selector_state.bindValueLoc(&selector, "%166", .{ .stack_i32_ptr = .{
        .disp = 0x1b94,
        .index = .{ .reg = .rcx, .name = "index", .addend_name = "addend" },
    } });
    const binding = selector.values.get("%236").?;
    try std.testing.expectEqual(selector_types.VirtualRegClass.gpr64, binding.vreg.class);
    try std.testing.expectEqual(@as(u8, 64), binding.vreg.bits);

    try std.testing.expect((try selector_memory.lowerStore(&selector, .{
        .ty = .{ .int = 32 },
        .value = .{ .named = "%236" },
        .ptr = .{ .named = "%166" },
    })) == null);

    try std.testing.expectEqual(binding, selector.values.get("%236").?);
    try std.testing.expectEqualSlices(x86_64_machine.Instruction, &.{
        .{ .reload_rsp_eax = .{ .slot = 380 } },
        .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = .{ .slot = 486 } } },
        .{ .reload_arg64_rsp = .{ .reg = .r8, .frame_index = .{ .slot = 450 } } },
        .add_r8_rcx,
        .{ .store_eax_stack_rcx4_disp32 = 0x1b94 },
    }, machine.instructions.items);
}

test "composed selector lowers typed float and double stack roundtrips" {
    const input =
        \\define float @roundtrip_f32(float %value) {
        \\entry:
        \\  %slot = alloca float, align 4
        \\  store float %value, ptr %slot, align 4
        \\  %loaded = load float, ptr %slot, align 4
        \\  ret float %loaded
        \\}
        \\define double @roundtrip_f64(double %value) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double %value, ptr %slot, align 8
        \\  %loaded = load double, ptr %slot, align 8
        \\  ret double %loaded
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));

        var saw_store = false;
        var saw_load = false;
        for (machine.instructions.items) |instruction| switch (instruction) {
            .spill_xmm32_rsp => if (index == 0) {
                saw_store = true;
            },
            .spill_xmm64_rsp => if (index == 1) {
                saw_store = true;
            },
            .load_stack_disp8_xmm0_f32, .load_stack_disp32_xmm0_f32 => if (index == 0) {
                saw_load = true;
            },
            .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => if (index == 1) {
                saw_load = true;
            },
            else => {},
        };
        try std.testing.expect(saw_store and saw_load);
        try x86_64_verify.verifyFunction(machine);

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const roundtrip: *const fn (f32) callconv(.c) f32 = @ptrCast(mapping.ptr);
            inline for (.{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0001), @as(u32, 0x807f_ffff), @as(u32, 0x7f80_0000), @as(u32, 0x7fc1_2345) }) |bits| {
                try std.testing.expectEqual(bits, @as(u32, @bitCast(roundtrip(@bitCast(bits)))));
            }
        } else {
            const roundtrip: *const fn (f64) callconv(.c) f64 = @ptrCast(mapping.ptr);
            inline for (.{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x800f_ffff_ffff_ffff), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff8_1234_5678_9abc) }) |bits| {
                try std.testing.expectEqual(bits, @as(u64, @bitCast(roundtrip(@bitCast(bits)))));
            }
        }
    }
}

test "composed selector stages a local FP out parameter and preserves live XMM" {
    const input =
        \\declare fastcc i32 @write_out(float, ptr)
        \\define double @caller(float %input, double %seed) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  store double %seed, ptr %slot, align 8
        \\  %live = fmul double %seed, 1.000000e+00
        \\  %code = call fastcc i32 @write_out(float %input, ptr nonnull align 8 %slot)
        \\  %reduced = and i32 %code, 1
        \\  %loaded = load double, ptr %slot, align 8
        \\  %result = fmul double %live, %loaded
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

    var call_index: ?usize = null;
    var saw_stack_pointer = false;
    var saw_live_spill = false;
    var saw_live_reload = false;
    var saw_out_load = false;
    var saw_reduced_result = false;
    for (machine.instructions.items, 0..) |instruction, index| switch (instruction) {
        .mov_rsp_arg64 => |reg| saw_stack_pointer = saw_stack_pointer or reg == .rdi,
        .direct_call => call_index = index,
        .spill_xmm64_rsp => if (call_index == null) {
            saw_live_spill = true;
        },
        .reload_xmm64_rsp => if (call_index) |at| {
            if (index > at) saw_live_reload = true;
        },
        .load_stack_disp8_xmm0, .load_stack_disp32_xmm0 => if (call_index != null) {
            saw_out_load = true;
        },
        .and_eax_imm32 => |imm| saw_reduced_result = saw_reduced_result or imm == 1,
        else => {},
    };
    try std.testing.expect(call_index != null and saw_stack_pointer and saw_live_spill and saw_live_reload and saw_out_load and saw_reduced_result);
    try x86_64_verify.verifyFunction(machine);
}

test "composed selector keeps unsupported FP memory fail closed" {
    var machine = MachineFunction.init("fp-memory-boundaries", .void);
    defer machine.deinit(std.testing.allocator);
    var selector = ComposedBlockSelector.init(std.testing.allocator, &machine);
    defer selector.deinit();
    selector.stack_frame_bytes = 24;
    try selector_state.bindValueLoc(&selector, "slot", .{ .stack_scalar = .{ .base_disp = 0, .bits = 64, .kind = .fp } });
    try selector_state.bindValueLoc(&selector, "external", .{ .arg64 = .rdi });
    try selector_state.bindValueLoc(&selector, "value", .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });

    const volatile_diagnostic = (try selector_memory.lowerLoad(&selector, "loaded", .{
        .ty = .double,
        .ptr = .{ .named = "slot" },
        .attrs = .{ .is_volatile = true },
    })).?;
    try std.testing.expectEqualStrings("composed-block-load-barrier", volatile_diagnostic.no_emitter);

    const external_diagnostic = (try selector_memory.lowerStore(&selector, .{
        .ty = .double,
        .value = .{ .named = "value" },
        .ptr = .{ .named = "external" },
    })).?;
    try std.testing.expectEqualStrings("composed-block-store-fp-ptr", external_diagnostic.no_emitter);
}

test "composed selector stores scalar FP values through proven pointer parameters" {
    const input =
        \\define void @store_f16_pair(half %value, ptr %out_a, ptr %out_b) {
        \\entry:
        \\  store half %value, ptr %out_a, align 2
        \\  store half %value, ptr %out_b, align 2
        \\  ret void
        \\}
        \\define void @store_f32(float %value, ptr %out) {
        \\entry:
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\define void @store_f64(double %value, ptr %out) {
        \\entry:
        \\  store double %value, ptr %out, align 8
        \\  ret void
        \\}
        \\define void @store_f32_framed(float %value, ptr %out) {
        \\entry:
        \\  %slot = alloca double, align 8
        \\  br label %body
        \\body:
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function));
        try x86_64_verify.verifyFunction(machine);
        if (index == 3) {
            var saw_fp_reload = false;
            var saw_pointer_reload = false;
            var saw_spilled_pointer_store = false;
            for (machine.instructions.items) |instruction| switch (instruction) {
                .reload_xmm32_rsp => saw_fp_reload = true,
                .reload_arg64_rsp => |reload| saw_pointer_reload = reload.reg == .rcx,
                .store_xmm0_f32_arg_ptr_disp8 => |store| saw_spilled_pointer_store = store.reg == .rcx and store.offset == 0,
                else => {},
            };
            try std.testing.expect(saw_fp_reload and saw_pointer_reload and saw_spilled_pointer_store);
        }

        const bytes = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(bytes);
        const mapping = try std.posix.mmap(null, bytes.len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memcpy(mapping, bytes);
        if (index == 0) {
            const store: *const fn (f16, *u16, *u16) callconv(.c) void = @ptrCast(mapping.ptr);
            inline for (.{ @as(u16, 0x0000), @as(u16, 0x8000), @as(u16, 0x0001), @as(u16, 0x3c00), @as(u16, 0x7c00), @as(u16, 0x7e55), @as(u16, 0x7d55) }) |bits| {
                var out_a: u16 = undefined;
                var out_b: u16 = undefined;
                store(@bitCast(bits), &out_a, &out_b);
                try std.testing.expectEqual(bits, out_a);
                try std.testing.expectEqual(bits, out_b);
            }
        } else if (index == 2) {
            const store: *const fn (f64, *f64) callconv(.c) void = @ptrCast(mapping.ptr);
            inline for (.{ @as(u64, 0x0000_0000_0000_0000), @as(u64, 0x8000_0000_0000_0000), @as(u64, 0x0000_0000_0000_0001), @as(u64, 0x7ff0_0000_0000_0000), @as(u64, 0x7ff8_1234_5678_9abc) }) |bits| {
                var out: f64 = undefined;
                store(@bitCast(bits), &out);
                try std.testing.expectEqual(bits, @as(u64, @bitCast(out)));
            }
        } else {
            const store: *const fn (f32, *f32) callconv(.c) void = @ptrCast(mapping.ptr);
            inline for (.{ @as(u32, 0x0000_0000), @as(u32, 0x8000_0000), @as(u32, 0x0000_0001), @as(u32, 0x7f80_0000), @as(u32, 0x7fc1_2345) }) |bits| {
                var out: f32 = undefined;
                store(@bitCast(bits), &out);
                try std.testing.expectEqual(bits, @as(u32, @bitCast(out)));
            }
        }
    }
}

test "composed selector rejects FP stores through derived pointers" {
    const input =
        \\define void @store_unproven(ptr %base, float %value) {
        \\entry:
        \\  %out = getelementptr i8, ptr %base, i64 4
        \\  store float %value, ptr %out, align 4
        \\  ret void
        \\}
        \\define void @store_unproven_half(ptr %base, half %value) {
        \\entry:
        \\  %out = getelementptr i8, ptr %base, i64 2
        \\  store half %value, ptr %out, align 2
        \\  ret void
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();

    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, .void);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfg(std.testing.allocator, &machine, function);
        switch (selection) {
            .unsupported => |diagnostic| try std.testing.expectEqualStrings("composed-block-store-fp-ptr", diagnostic.no_emitter),
            .selected => return error.TestUnexpectedResult,
        }
    }
}

test "constant table shapes execute first interior and last probes" {
    const input = try buildConstantTableModuleText(std.testing.allocator);
    defer std.testing.allocator.free(input);
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context: x86_64_machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };

    const Probe = struct {
        function_name: []const u8,
        symbol: []const u8,
        indexes: [3]u64,
        element_indexes: [3]usize,
        offset: usize,
        integer: bool = false,
    };
    const probes = [_]Probe{
        .{ .function_name = "probe_i16", .symbol = "table_i16", .indexes = .{ 0, 63, 127 }, .element_indexes = .{ 0, 63, 127 }, .offset = 0, .integer = true },
        .{ .function_name = "probe_f64_16", .symbol = "table_f64_16", .indexes = .{ 0, 7, 15 }, .element_indexes = .{ 0, 7, 15 }, .offset = 0 },
        .{ .function_name = "probe_f64_512_lo", .symbol = "table_f64_512", .indexes = .{ 0, 128, 255 }, .element_indexes = .{ 0, 256, 510 }, .offset = 0 },
        .{ .function_name = "probe_f64_512_hi", .symbol = "table_f64_512", .indexes = .{ 0, 128, 255 }, .element_indexes = .{ 1, 257, 511 }, .offset = 8 },
        .{ .function_name = "probe_pair_lo", .symbol = "table_pair", .indexes = .{ 0, 64, 127 }, .element_indexes = .{ 0, 128, 254 }, .offset = 0 },
        .{ .function_name = "probe_pair_hi", .symbol = "table_pair", .indexes = .{ 0, 64, 127 }, .element_indexes = .{ 1, 129, 255 }, .offset = 8 },
    };

    for (probes) |probe| {
        const function = findFunction(module, probe.function_name) orelse return error.TestUnexpectedResult;
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const selection = try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context);
        switch (selection) {
            .selected => {},
            .unsupported => |diagnostic| {
                std.debug.print("constant-table probe {s}: {any}\n", .{ probe.function_name, diagnostic });
                return error.TestUnexpectedResult;
            },
        }
        try x86_64_verify.verifyFunction(machine);
        const code = try encoding.encodeFunction(std.testing.allocator, machine);
        defer std.testing.allocator.free(code);
        var decoded = (try constant_table.decodeSymbol(std.testing.allocator, context, probe.symbol)).?;
        defer decoded.deinit(std.testing.allocator);

        const table_offset = std.mem.alignForward(usize, code.len, decoded.alignment);
        const mapping_len = table_offset + decoded.bytes.len;
        const mapping = try std.posix.mmap(null, mapping_len, .{ .READ = true, .WRITE = true, .EXEC = true }, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
        defer std.posix.munmap(mapping);
        @memset(mapping, 0);
        @memcpy(mapping[0..code.len], code);
        @memcpy(mapping[table_offset..][0..decoded.bytes.len], decoded.bytes);
        const relocation_offset = findLeaPc32Offset(mapping[0..code.len]) orelse return error.TestUnexpectedResult;
        const next_ip = relocation_offset + 4;
        const displacement: i32 = @intCast(@as(isize, @intCast(table_offset)) - @as(isize, @intCast(next_ip)));
        std.mem.writeInt(i32, mapping[relocation_offset..][0..4], displacement, .little);

        for (probe.indexes, probe.element_indexes) |index, element_index| {
            if (probe.integer) {
                const call: *const fn (u64) callconv(.c) u32 = @ptrCast(mapping.ptr);
                const expected = std.mem.readInt(u16, decoded.bytes[element_index * 2 ..][0..2], .little);
                try std.testing.expectEqual(@as(u32, expected), call(index));
            } else {
                const call: *const fn (u64) callconv(.c) f64 = @ptrCast(mapping.ptr);
                const expected = std.mem.readInt(u64, decoded.bytes[element_index * 8 ..][0..8], .little);
                try std.testing.expectEqual(expected, @as(u64, @bitCast(call(index))));
            }
        }
    }

    var machines: std.ArrayList(MachineFunction) = .empty;
    defer {
        for (machines.items) |*machine| machine.deinit(std.testing.allocator);
        machines.deinit(std.testing.allocator);
    }
    for (module.functions.items) |function| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        errdefer machine.deinit(std.testing.allocator);
        try std.testing.expectEqual(impl.SelectionResult.selected, try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context));
        try machines.append(std.testing.allocator, machine);
    }
    const object = try elf.buildObjectWithModuleContext(std.testing.allocator, machines.items, &.{}, context);
    defer std.testing.allocator.free(object);
    inline for (.{ "table_i16", "table_f64_16", "table_f64_512", "table_pair", ".rela.text" }) |needle| {
        try std.testing.expect(std.mem.indexOf(u8, object, needle) != null);
    }
}

test "constant table admission rejects unproved indexes and writable globals" {
    const input =
        \\target datalayout = "e-m:e-i64:64-n8:16:32:64-S128"
        \\@writable = internal global [16 x double] zeroinitializer, align 8
        \\@readonly = internal constant [16 x double] [double 1.0, double 2.0, double 3.0, double 4.0, double 5.0, double 6.0, double 7.0, double 8.0, double 9.0, double 10.0, double 11.0, double 12.0, double 13.0, double 14.0, double 15.0, double 16.0], align 8
        \\define double @unproved(i64 %index) {
        \\entry:
        \\  %ptr = getelementptr [8 x i8], ptr @readonly, i64 %index
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @writable_table(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 15
        \\  %ptr = getelementptr [8 x i8], ptr @writable, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\
    ;
    var module = try ir.Module.parse(std.testing.allocator, input);
    defer module.deinit();
    try module.verify();
    const context: x86_64_machine.ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };
    for (module.functions.items, 0..) |function, index| {
        var machine = MachineFunction.init(function.name, function.ret_ty);
        defer machine.deinit(std.testing.allocator);
        const result = try impl.tryLowerComposedCfgWithContext(std.testing.allocator, &machine, function, &context);
        switch (result) {
            .selected => return error.TestUnexpectedResult,
            .unsupported => |diagnostic| try std.testing.expectEqualStrings(
                if (index == 0) "composed-block-gep-readonly-table-range" else "composed-block-gep-readonly-table-global",
                diagnostic.no_emitter,
            ),
        }
    }
}

fn buildConstantTableModuleText(allocator: std.mem.Allocator) ![]u8 {
    var text: std.ArrayList(u8) = .empty;
    errdefer text.deinit(allocator);
    try text.appendSlice(allocator, "target datalayout = \"e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128\"\n");
    try text.appendSlice(allocator, "%pair = type { double, double }\n");
    try text.appendSlice(allocator, "@table_i16 = internal constant [128 x i16] [");
    for (0..128) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendFmt(&text, allocator, "i16 {}", .{1000 + index});
    }
    try text.appendSlice(allocator, "], align 2\n@table_f64_16 = internal constant [16 x double] [");
    for (0..16) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 1));
    }
    try text.appendSlice(allocator, "], align 8\n@table_f64_512 = internal constant [512 x double] [");
    for (0..512) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 100));
    }
    try text.appendSlice(allocator, "], align 8\n@table_pair = internal constant [128 x %pair] [");
    for (0..128) |index| {
        if (index != 0) try text.appendSlice(allocator, ", ");
        try text.appendSlice(allocator, "%pair { ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 1000));
        try text.appendSlice(allocator, ", ");
        try appendF64Literal(&text, allocator, @floatFromInt(index + 2000));
        try text.appendSlice(allocator, " }");
    }
    try text.appendSlice(allocator, "], align 8\n");
    try text.appendSlice(allocator,
        \\define i32 @probe_i16(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [2 x i8], ptr @table_i16, i64 %masked
        \\  %value = load i16, ptr %ptr, align 2
        \\  %wide = zext i16 %value to i32
        \\  ret i32 %wide
        \\}
        \\define double @probe_f64_16(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 15
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_16, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_f64_512_lo(i32 %index) {
        \\entry:
        \\  %shifted = shl i32 %index, 1
        \\  %masked = and i32 %shifted, 510
        \\  %wide = zext i32 %masked to i64
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_512, i64 %wide
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_f64_512_hi(i32 %index) {
        \\entry:
        \\  %shifted = shl i32 %index, 1
        \\  %masked = and i32 %shifted, 510
        \\  %wide = zext i32 %masked to i64
        \\  %ptr = getelementptr [8 x i8], ptr @table_f64_512, i64 %wide
        \\  %hi = getelementptr i8, ptr %ptr, i64 8
        \\  %value = load double, ptr %hi, align 8
        \\  ret double %value
        \\}
        \\define double @probe_pair_lo(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [16 x i8], ptr @table_pair, i64 %masked
        \\  %value = load double, ptr %ptr, align 8
        \\  ret double %value
        \\}
        \\define double @probe_pair_hi(i64 %index) {
        \\entry:
        \\  %masked = and i64 %index, 127
        \\  %ptr = getelementptr [16 x i8], ptr @table_pair, i64 %masked
        \\  %hi = getelementptr i8, ptr %ptr, i64 8
        \\  %value = load double, ptr %hi, align 8
        \\  ret double %value
        \\}
        \\
    );
    return text.toOwnedSlice(allocator);
}

fn appendF64Literal(text: *std.ArrayList(u8), allocator: std.mem.Allocator, value: f64) !void {
    try appendFmt(text, allocator, "double 0x{X:0>16}", .{@as(u64, @bitCast(value))});
}

fn appendFmt(text: *std.ArrayList(u8), allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) !void {
    const piece = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(piece);
    try text.appendSlice(allocator, piece);
}

fn findFunction(module: ir.Module, name: []const u8) ?ir.Function {
    for (module.functions.items) |function| if (std.mem.eql(u8, function.name, name)) return function;
    return null;
}

fn findLeaPc32Offset(code: []const u8) ?usize {
    var index: usize = 0;
    while (index + 7 <= code.len) : (index += 1) {
        if (code[index] == 0x48 and code[index + 1] == 0x8d and code[index + 2] == 0x0d) return index + 3;
    }
    return null;
}
