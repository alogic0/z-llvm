const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const state_data = @import("composed_selector_state_data.zig");
const eflags = @import("composed_selector_eflags.zig");
const address_dependencies = @import("composed_selector_address_dependencies.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const XmmReg = x86_64_types.XmmReg;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const AccumulatorDomain = selector_types.AccumulatorDomain;
const PairSpillLoc = selector_types.PairSpillLoc;
const RegPair = selector_types.RegPair;
const StackArrayLoc = selector_types.StackArrayLoc;
const StackPtrLoc = selector_types.StackPtrLoc;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const VectorShape = selector_types.VectorShape;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const selector_allocatable_xmm_regs = selector_types.selector_allocatable_xmm_regs;
const argRegIndex = selector_types.argRegIndex;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;

const NameSet = stage2_planning.NameSet;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const allocateSelectorIntervals = stage2_planning.allocateSelectorIntervals;
const analyzeStageTwoNoSpillEnvelope = stage2_planning.analyzeStageTwoNoSpillEnvelope;
const buildSelectorAllocationPlan = stage2_planning.buildSelectorAllocationPlan;
const namedValue = stage2_planning.namedValue;
const selectorValueMetadata = stage2_planning.selectorValueMetadata;
const stage2SpillReservedBytes = stage2_planning.stage2SpillReservedBytes;
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
const stage2_spill_slots = stage2_planning.stage2_spill_slots;
const phi_regs = [_]ArgReg{ .r8, .r9, .rcx };

const blockHasPhiIncomingFrom = composed_helpers.blockHasPhiIncomingFrom;
const phiIncomingFrom = composed_helpers.phiIncomingFrom;
const canUseExpiredPlanRegisterReuse = composed_helpers.canUseExpiredPlanRegisterReuse;
const machineBinaryOp = composed_helpers.machineBinaryOp;
const isCommutative = composed_helpers.isCommutative;
const locIsAccumulator = composed_helpers.locIsAccumulator;
const valueLocEql = composed_helpers.valueLocEql;
const locContainsReg = composed_helpers.locContainsReg;
const valueIsInt = composed_helpers.valueIsInt;
const intBits = composed_helpers.intBits;
const callArgRegisterCount = composed_helpers.callArgRegisterCount;
const isDefaultOrFastcc = composed_helpers.isDefaultOrFastcc;
const parseI32ArrayType = composed_helpers.parseI32ArrayType;
const alignedCallFrameBytes = composed_helpers.alignedCallFrameBytes;
const stack128FrameBytes = composed_helpers.stack128FrameBytes;
const isComposedReturnType = composed_helpers.isComposedReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub const ComposedBlockSelector = state_data.ComposedBlockSelector;
pub const EflagsEffect = eflags.Effect;
pub const EflagsLiveness = eflags.Liveness;
pub const EflagsDefinitionPurpose = eflags.DefinitionPurpose;
pub const AddressDependencies = AddressDependencyDomain;

pub const AccumulatorPreparationEffect = enum {
    preserve,
    clobber,

    fn eflagsEffect(effect: AccumulatorPreparationEffect) EflagsEffect {
        return switch (effect) {
            .preserve => .preserve,
            .clobber => .clobber,
        };
    }
};

pub const AccumulatorDisplacementPolicy = union(enum) {
    /// Reproduce clobberAccumulator: every live accumulator alias is assigned
    /// its deterministic spill home, even when a scratch register is free.
    spill_live,
    /// Reproduce an accepted spill-current-source path before a destructive
    /// definition. Only this source identity is pinned until it is spilled;
    /// no general current-position protection is enabled.
    spill_source: []const u8,
    /// Reproduce preserveLiveAccumulatorValue: prefer the deterministic
    /// scratch register and fall back to the deterministic spill home.
    scratch_preferred,
    /// Retain a source already resident in EAX/RAX for an in-place definition.
    /// Other live aliases are displaced by the transaction authority.
    reuse_source: []const u8,
};

pub const AccumulatorDefinition = struct {
    logical_bits: u16,
    upper_bits: UpperBits,

    pub const UpperBits = enum {
        zero_extend,
        fully_defined,
        preserve,
    };

    pub fn zeroExtending(logical_bits: u16) AccumulatorDefinition {
        return .{ .logical_bits = logical_bits, .upper_bits = .zero_extend };
    }

    pub fn fullRax() AccumulatorDefinition {
        return .{ .logical_bits = 64, .upper_bits = .fully_defined };
    }

    /// A producer-specific proof that a logical 33-63-bit result defines the
    /// complete physical RAX value with zeroes above its logical domain.
    pub fn zeroExtendedRax(logical_bits: u16) AccumulatorDefinition {
        return .{ .logical_bits = logical_bits, .upper_bits = .fully_defined };
    }

    pub fn preserving(logical_bits: u16) AccumulatorDefinition {
        return .{ .logical_bits = logical_bits, .upper_bits = .preserve };
    }

    fn validate(definition: AccumulatorDefinition) !void {
        if (definition.logical_bits == 0 or definition.logical_bits > 64)
            return error.InvalidAccumulatorDefinitionWidth;
        if (definition.logical_bits <= 32) {
            if (definition.upper_bits != .zero_extend) return error.AccumulatorStaleUpperBits;
        } else if (definition.upper_bits != .fully_defined) return error.AccumulatorStaleUpperBits;
    }

    fn physicalLoc(definition: AccumulatorDefinition) ValueLoc {
        return if (definition.logical_bits > 32) .rax else .eax;
    }

    pub fn bindingBits(definition: AccumulatorDefinition) u16 {
        return switch (definition.physicalLoc()) {
            .eax => 32,
            .rax => 64,
            else => unreachable,
        };
    }

    fn virtualRegClass(definition: AccumulatorDefinition) VirtualRegClass {
        return if (definition.logical_bits > 32) .gpr64 else .gpr32;
    }
};

/// Snapshot-free EAX/RAX state-transition core. A standalone O1 transaction
/// wraps this session in its historical snapshot; an O1/O2 composition stores
/// it under the ValueUseTransaction snapshot. The session never owns rollback
/// and cannot independently commit selector state.
pub const AccumulatorDefinitionSession = struct {
    pub const snapshot_copies: usize = 0;
    pub const address_domain_snapshot_copies: usize = 0;

    selector: *ComposedBlockSelector,
    phase: Phase = .begun,
    pending: ?PendingDefinition = null,
    reused_source: ?[]const u8 = null,

    const Phase = enum {
        begun,
        preparing_call,
        prepared,
        defined,
        finalized,
    };

    const PendingDefinition = struct {
        name: []const u8,
        definition: AccumulatorDefinition,
        binding: ValueBinding,
    };

    pub fn init(selector: *ComposedBlockSelector) AccumulatorDefinitionSession {
        return .{ .selector = selector };
    }

    pub fn prepare(
        session: *AccumulatorDefinitionSession,
        effect: AccumulatorPreparationEffect,
        displacement: AccumulatorDisplacementPolicy,
    ) !?Diagnostic {
        try session.beginPreparation(effect);
        if (try session.applyDisplacement(displacement)) |diagnostic| return diagnostic;
        try session.finishPreparation();
        return null;
    }

    pub fn prepareCallBeforeArguments(
        session: *AccumulatorDefinitionSession,
        effect: AccumulatorPreparationEffect,
    ) !?Diagnostic {
        if (effect != .clobber) return error.AccumulatorCallMustClobberEflags;
        try session.beginPreparation(effect);
        if (try spillLiveCallerClobbersForCall(session.selector)) |diagnostic| return diagnostic;
        session.phase = .preparing_call;
        return null;
    }

    pub fn finishCallPreparationAfterArguments(session: *AccumulatorDefinitionSession) !void {
        if (session.phase != .preparing_call) return error.AccumulatorCallPreparationOrder;
        try dropExpiredAccumulatorBindings(session.selector);
        try session.requireAccumulatorUnbound();
        session.selector.accumulator_domain.invalidate();
        session.phase = .prepared;
    }

    pub fn materialize(
        session: *AccumulatorDefinitionSession,
        source: ir.Value,
        definition: AccumulatorDefinition,
    ) !void {
        try session.requirePrepared();
        try definition.validate();
        try session.materializeValidated(source, definition);
    }

    pub fn spill(session: *AccumulatorDefinitionSession, name: []const u8) !void {
        try session.requirePrepared();
        if (try spillValue(session.selector, name)) |_| return error.AccumulatorSpillUnsupported;
    }

    pub fn define(
        session: *AccumulatorDefinitionSession,
        name: []const u8,
        definition: AccumulatorDefinition,
    ) !void {
        switch (session.phase) {
            .begun, .preparing_call => return error.AccumulatorTransactionNotPrepared,
            .prepared => {},
            .defined => return error.AccumulatorAlreadyDefined,
            .finalized => return error.AccumulatorTransactionClosed,
        }
        try definition.validate();
        if (session.selector.values.contains(name)) return error.AccumulatorDefinitionAlreadyBound;

        const vreg: VirtualReg = .{
            .index = session.selector.next_virtual_reg,
            .class = definition.virtualRegClass(),
            .bits = definition.bindingBits(),
        };
        session.selector.next_virtual_reg += 1;
        session.pending = .{
            .name = name,
            .definition = definition,
            .binding = .{ .vreg = vreg, .loc = definition.physicalLoc() },
        };
        session.phase = .defined;
    }

    pub fn finalize(session: *AccumulatorDefinitionSession) !void {
        try session.requireDefinition();
        try session.finalizeValidated();
    }

    pub fn isPrepared(session: *const AccumulatorDefinitionSession) bool {
        return session.phase == .prepared;
    }

    pub fn isFinalized(session: *const AccumulatorDefinitionSession) bool {
        return session.phase == .finalized;
    }

    fn beginPreparation(
        session: *AccumulatorDefinitionSession,
        effect: AccumulatorPreparationEffect,
    ) !void {
        switch (session.phase) {
            .begun => {},
            .preparing_call, .prepared, .defined => return error.AccumulatorTransactionAlreadyPrepared,
            .finalized => return error.AccumulatorTransactionClosed,
        }

        var next_eflags = session.selector.eflags;
        try next_eflags.apply(effect.eflagsEffect());
        session.selector.eflags = next_eflags;
    }

    fn applyDisplacement(
        session: *AccumulatorDefinitionSession,
        displacement: AccumulatorDisplacementPolicy,
    ) !?Diagnostic {
        switch (displacement) {
            .spill_live => try clobberAccumulator(session.selector),
            .spill_source => |source_name| {
                const source = session.selector.values.get(source_name) orelse
                    return error.AccumulatorSpillSourceUnknown;
                switch (source.loc) {
                    .eax, .rax => {},
                    else => return error.AccumulatorSpillSourceNotResident,
                }
                try spillValueOrError(session.selector, source_name);
                try clobberAccumulator(session.selector);
            },
            .scratch_preferred => {
                while (try liveAccumulatorNameAfterCurrent(session.selector)) |live_name| {
                    if (try preserveLiveAccumulatorValue(session.selector, live_name)) |diagnostic|
                        return diagnostic;
                }
                try dropExpiredAccumulatorBindings(session.selector);
            },
            .reuse_source => |source_name| {
                const source = session.selector.values.get(source_name) orelse
                    return error.AccumulatorReuseSourceUnknown;
                switch (source.loc) {
                    .eax, .rax => {},
                    else => return error.AccumulatorReuseSourceNotResident,
                }
                try spillAccumulatorAliasesExcept(session.selector, .{ .named = source_name });
                try dropExpiredAccumulatorBindingsExcept(session.selector, source_name);
                session.reused_source = source_name;
            },
        }
        return null;
    }

    fn finishPreparation(session: *AccumulatorDefinitionSession) !void {
        try session.requireAccumulatorReadyForCommit();
        if (session.reused_source == null) session.selector.accumulator_domain.invalidate();
        session.phase = .prepared;
    }

    fn requirePrepared(session: *const AccumulatorDefinitionSession) !void {
        switch (session.phase) {
            .prepared => {},
            .begun, .preparing_call => return error.AccumulatorTransactionNotPrepared,
            .defined => return error.AccumulatorAlreadyDefined,
            .finalized => return error.AccumulatorTransactionClosed,
        }
    }

    fn requireDefinition(session: *const AccumulatorDefinitionSession) !void {
        switch (session.phase) {
            .begun, .preparing_call, .prepared => return error.AccumulatorCommitWithoutDefinition,
            .defined => {},
            .finalized => return error.AccumulatorTransactionClosed,
        }
    }

    fn requireAccumulatorReadyForCommit(session: *const AccumulatorDefinitionSession) !void {
        const reused_source = session.reused_source;
        var it = session.selector.values.iterator();
        while (it.next()) |entry| switch (entry.value_ptr.loc) {
            .eax, .rax => if (reused_source == null or
                !std.mem.eql(u8, entry.key_ptr.*, reused_source.?))
            {
                return error.AccumulatorAliasConflict;
            },
            else => {},
        };
    }

    fn requireAccumulatorUnbound(session: *const AccumulatorDefinitionSession) !void {
        var it = session.selector.values.iterator();
        while (it.next()) |entry| switch (entry.value_ptr.loc) {
            .eax, .rax => return error.AccumulatorAliasConflict,
            else => {},
        };
    }

    fn materializeValidated(
        session: *AccumulatorDefinitionSession,
        source: ir.Value,
        definition: AccumulatorDefinition,
    ) !void {
        switch (source) {
            .named => {
                const current = resolveValue(session.selector, source) orelse
                    return error.UnsupportedCodegenValue;
                try session.materializeCurrentLocIntoAccumulator(current, definition);
            },
            .int => |int| try session.selector.machine.instructions.append(
                session.selector.allocator,
                switch (definition.physicalLoc()) {
                    .eax => .{ .mov_imm_eax = try composed_helpers.i32BitPattern(int) },
                    .rax => .{ .mov_imm_rax = try i64Value(int) },
                    else => unreachable,
                },
            ),
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn materializeCurrentLocIntoAccumulator(
        session: *AccumulatorDefinitionSession,
        source: ValueLoc,
        definition: AccumulatorDefinition,
    ) !void {
        const selector = session.selector;
        switch (definition.physicalLoc()) {
            .eax => switch (source) {
                .arg32, .scratch32, .arg64, .scratch64 => |reg| try selector.machine.instructions.append(
                    selector.allocator,
                    .{ .mov_arg_eax = reg },
                ),
                .spill64 => |frame_index| try selector.machine.instructions.append(
                    selector.allocator,
                    .{ .reload_rsp_eax = frame_index },
                ),
                .eax, .rax => {},
                else => return error.UnsupportedCodegenValue,
            },
            .rax => switch (source) {
                .arg64, .scratch64 => |reg| try selector.machine.instructions.append(
                    selector.allocator,
                    .{ .mov_arg_rax = reg },
                ),
                .spill64 => |frame_index| try selector.machine.instructions.append(
                    selector.allocator,
                    .{ .reload_rsp_rax = frame_index },
                ),
                .eax, .rax => {},
                else => return error.UnsupportedCodegenValue,
            },
            else => unreachable,
        }
    }

    fn finalizeValidated(session: *AccumulatorDefinitionSession) !void {
        try session.requireAccumulatorReadyForCommit();
        const pending = session.pending.?;
        const physical = pending.definition.physicalLoc();
        const target = plannedResultLoc(session.selector, pending.name, physical) orelse physical;
        if (!valueLocEql(physical, target)) {
            try materializeLocIntoLocWithBits(
                session.selector,
                physical,
                target,
                pending.definition.bindingBits(),
            );
        }
        try putValueBinding(session.selector, pending.name, .{
            .vreg = pending.binding.vreg,
            .loc = target,
        });

        if (locIsAccumulator(target)) {
            const binding = session.selector.values.get(pending.name).?;
            session.selector.accumulator_domain = .{
                .occupant = .{
                    .binding = binding,
                    .logical_bits = pending.definition.logical_bits,
                },
                .defined_bits = 64,
            };
        } else {
            session.selector.accumulator_domain.invalidate();
        }
        session.phase = .finalized;
    }

    fn reset(session: *AccumulatorDefinitionSession) void {
        session.phase = .begun;
        session.pending = null;
        session.reused_source = null;
    }
};

/// Standalone O1 authority. Its public lifecycle and snapshot semantics remain
/// unchanged while the state-transition core is shared with O1/O2 composition.
pub const AccumulatorDefinitionTransaction = struct {
    selector: *ComposedBlockSelector,
    instruction_len: usize,
    values: []ValueEntry,
    spill_slots: []SpillSlotSnapshotEntry,
    next_virtual_reg: usize,
    next_spill_slot: usize,
    accumulator_domain: AccumulatorDomain,
    address_dependencies: AddressDependencyDomain,
    eflags_snapshot: EflagsLiveness.Snapshot,
    eflags_semantics_len: usize,
    session: AccumulatorDefinitionSession,
    lifecycle: Lifecycle = .active,

    const Lifecycle = enum { active, committed, rolled_back };

    const ValueEntry = struct {
        name: []const u8,
        binding: ValueBinding,
    };

    pub fn begin(selector: *ComposedBlockSelector) !AccumulatorDefinitionTransaction {
        const values = try selector.allocator.alloc(ValueEntry, selector.values.count());
        errdefer selector.allocator.free(values);
        const spill_slots = try selector.allocator.alloc(SpillSlotSnapshotEntry, selector.spill_slots.count());
        errdefer selector.allocator.free(spill_slots);

        var value_index: usize = 0;
        var value_it = selector.values.iterator();
        while (value_it.next()) |entry| : (value_index += 1)
            values[value_index] = .{ .name = entry.key_ptr.*, .binding = entry.value_ptr.* };
        var spill_index: usize = 0;
        var spill_it = selector.spill_slots.iterator();
        while (spill_it.next()) |entry| : (spill_index += 1)
            spill_slots[spill_index] = .{ .name = entry.key_ptr.*, .assignment = entry.value_ptr.* };

        return .{
            .selector = selector,
            .instruction_len = selector.machine.instructions.items.len,
            .values = values,
            .spill_slots = spill_slots,
            .next_virtual_reg = selector.next_virtual_reg,
            .next_spill_slot = selector.next_spill_slot,
            .accumulator_domain = selector.accumulator_domain,
            .address_dependencies = selector.address_dependencies,
            .eflags_snapshot = selector.eflags.snapshot(),
            .eflags_semantics_len = selector.eflags_semantics.items.len,
            .session = AccumulatorDefinitionSession.init(selector),
        };
    }

    pub fn deinit(transaction: *AccumulatorDefinitionTransaction) void {
        if (transaction.lifecycle == .active) transaction.restore(.rolled_back);
        transaction.selector.allocator.free(transaction.spill_slots);
        transaction.selector.allocator.free(transaction.values);
    }

    pub fn prepare(
        transaction: *AccumulatorDefinitionTransaction,
        effect: AccumulatorPreparationEffect,
        displacement: AccumulatorDisplacementPolicy,
    ) !?Diagnostic {
        try transaction.requireActive();
        try transaction.session.beginPreparation(effect);
        errdefer transaction.restore(.rolled_back);
        if (try transaction.session.applyDisplacement(displacement)) |diagnostic| {
            transaction.restore(.rolled_back);
            return diagnostic;
        }
        try transaction.session.finishPreparation();
        return null;
    }

    pub fn prepareCallBeforeArguments(
        transaction: *AccumulatorDefinitionTransaction,
        effect: AccumulatorPreparationEffect,
    ) !?Diagnostic {
        if (effect != .clobber) return error.AccumulatorCallMustClobberEflags;
        try transaction.requireActive();
        try transaction.session.beginPreparation(effect);
        errdefer transaction.restore(.rolled_back);
        if (try spillLiveCallerClobbersForCall(transaction.selector)) |diagnostic| {
            transaction.restore(.rolled_back);
            return diagnostic;
        }
        transaction.session.phase = .preparing_call;
        return null;
    }

    pub fn finishCallPreparationAfterArguments(transaction: *AccumulatorDefinitionTransaction) !void {
        if (transaction.session.phase != .preparing_call) return error.AccumulatorCallPreparationOrder;
        try transaction.requireActive();
        errdefer transaction.restore(.rolled_back);
        try transaction.session.finishCallPreparationAfterArguments();
    }

    pub fn materialize(
        transaction: *AccumulatorDefinitionTransaction,
        source: ir.Value,
        definition: AccumulatorDefinition,
    ) !void {
        try transaction.requireActive();
        try transaction.session.requirePrepared();
        try definition.validate();
        errdefer transaction.restore(.rolled_back);
        try transaction.session.materializeValidated(source, definition);
    }

    pub fn spill(transaction: *AccumulatorDefinitionTransaction, name: []const u8) !void {
        try transaction.requireActive();
        try transaction.session.requirePrepared();
        errdefer transaction.restore(.rolled_back);
        if (try spillValue(transaction.selector, name)) |_| return error.AccumulatorSpillUnsupported;
    }

    pub fn define(
        transaction: *AccumulatorDefinitionTransaction,
        name: []const u8,
        definition: AccumulatorDefinition,
    ) !void {
        try transaction.requireActive();
        try transaction.session.define(name, definition);
    }

    pub fn commit(transaction: *AccumulatorDefinitionTransaction) !void {
        try transaction.requireActive();
        try transaction.session.requireDefinition();
        errdefer transaction.restore(.rolled_back);
        try transaction.session.finalizeValidated();
        transaction.lifecycle = .committed;
    }

    pub fn rollback(transaction: *AccumulatorDefinitionTransaction) !void {
        try transaction.requireActive();
        transaction.restore(.rolled_back);
    }

    pub fn isPrepared(transaction: *const AccumulatorDefinitionTransaction) bool {
        return transaction.lifecycle == .active and transaction.session.isPrepared();
    }

    fn requireActive(transaction: *const AccumulatorDefinitionTransaction) !void {
        if (transaction.lifecycle != .active) return error.AccumulatorTransactionClosed;
    }

    fn restore(transaction: *AccumulatorDefinitionTransaction, lifecycle: Lifecycle) void {
        transaction.selector.machine.instructions.items.len = transaction.instruction_len;
        transaction.selector.values.clearRetainingCapacity();
        for (transaction.values) |entry|
            transaction.selector.values.putAssumeCapacity(entry.name, entry.binding);
        restoreSpillSlots(transaction.selector, transaction.spill_slots);
        transaction.selector.next_virtual_reg = transaction.next_virtual_reg;
        transaction.selector.next_spill_slot = transaction.next_spill_slot;
        transaction.selector.accumulator_domain = transaction.accumulator_domain;
        transaction.selector.address_dependencies = transaction.address_dependencies;
        transaction.selector.eflags.restore(transaction.eflags_snapshot);
        transaction.selector.eflags_semantics.items.len = transaction.eflags_semantics_len;
        transaction.session.reset();
        transaction.lifecycle = lifecycle;
    }
};

pub fn eflagsInstructionEffect(instruction: x86_64_machine.Instruction) EflagsEffect {
    return eflags.instructionEffect(instruction);
}

/// The sole production append authority for instructions that participate in
/// EFLAGS liveness. The semantic effect is validated and applied before the
/// instruction becomes externally visible; allocation failure restores the
/// exact prior flags state.
pub fn emitEflagsInstruction(
    selector: *ComposedBlockSelector,
    instruction: x86_64_machine.Instruction,
    semantic_effect: EflagsEffect,
) !void {
    try eflags.validateSemanticEffect(eflags.instructionEffect(instruction), semantic_effect);
    try selector.machine.instructions.ensureUnusedCapacity(selector.allocator, 1);
    try selector.eflags_semantics.ensureUnusedCapacity(selector.allocator, 1);
    const saved = selector.eflags.snapshot();
    switch (semantic_effect) {
        .definition => try selector.eflags.defineFor(.comparison),
        .use => try selector.eflags.useFor(eflags.consumerPurpose(instruction) orelse return error.EflagsConsumerPurposeMissing, false),
        .use_and_definition => try selector.eflags.carryLink(false),
        .use_and_clobber => if (eflags.consumerPurpose(instruction)) |purpose|
            try selector.eflags.useFor(purpose, true)
        else
            try selector.eflags.carryLink(true),
        .preserve, .write, .clobber => try selector.eflags.apply(semantic_effect),
    }
    errdefer selector.eflags.restore(saved);
    selector.machine.instructions.appendAssumeCapacity(instruction);
    selector.eflags_semantics.appendAssumeCapacity(.{
        .instruction_index = selector.machine.instructions.items.len - 1,
        .effect = semantic_effect,
    });
}

pub fn emitEflagsDefinition(
    selector: *ComposedBlockSelector,
    instruction: x86_64_machine.Instruction,
    purpose: EflagsDefinitionPurpose,
) !void {
    try eflags.validateSemanticEffect(eflags.instructionEffect(instruction), .definition);
    try selector.machine.instructions.ensureUnusedCapacity(selector.allocator, 1);
    try selector.eflags_semantics.ensureUnusedCapacity(selector.allocator, 1);
    const saved = selector.eflags.snapshot();
    try selector.eflags.defineFor(purpose);
    errdefer selector.eflags.restore(saved);
    selector.machine.instructions.appendAssumeCapacity(instruction);
    selector.eflags_semantics.appendAssumeCapacity(.{
        .instruction_index = selector.machine.instructions.items.len - 1,
        .effect = .definition,
    });
}

pub fn validateEflagsInstructions(
    selector: *const ComposedBlockSelector,
    instructions: []const x86_64_machine.Instruction,
    start_index: usize,
) !void {
    const saved = selector.eflags.snapshot();
    const effects = try selector.allocator.alloc(EflagsEffect, instructions.len);
    defer selector.allocator.free(effects);
    for (instructions, effects) |instruction, *effect| effect.* = eflags.instructionEffect(instruction);
    for (selector.eflags_semantics.items) |record| {
        if (record.instruction_index < start_index or record.instruction_index >= start_index + instructions.len) continue;
        effects[record.instruction_index - start_index] = record.effect;
    }
    try eflags.validateInstructionsWithEffects(selector.allocator, instructions, effects);
    try selector.eflags.validateSnapshot(saved);
}

fn scratch64RegForUseAvoiding(selector: *const ComposedBlockSelector, avoid: ?ArgReg) !?ArgReg {
    for (selector_allocatable_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (try scratch64RegIsAvailableForUse(selector, reg)) return reg;
    }
    return null;
}

fn scratch64RegIsAvailableForUse(selector: *const ComposedBlockSelector, reg: ArgReg) !bool {
    const status = regConflictStatus(selector, reg) orelse return true;
    return status;
}

fn loadStackU64IntoArg(selector: *ComposedBlockSelector, reg: ArgReg, disp: u32) !void {
    try clobberArgReg(selector, reg);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
    }
}

fn loadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    try clobberAccumulator(selector);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp });
    }
}

pub fn allocateEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_edge_{d}", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    selector.edge_label_count += 1;
    return label;
}

pub fn allocateEaxJoinLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_edge_{d}_generic_cfg_select_end", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    selector.edge_label_count += 1;
    return label;
}

pub fn bindValueLoc(selector: *ComposedBlockSelector, name: []const u8, loc: ValueLoc) !void {
    const vreg = if (selector.values.get(name)) |binding|
        binding.vreg
    else blk: {
        const metadata = virtualRegMetadata(loc);
        const vreg: VirtualReg = .{
            .index = selector.next_virtual_reg,
            .class = metadata.class,
            .bits = metadata.bits,
        };
        selector.next_virtual_reg += 1;
        break :blk vreg;
    };
    try putValueBinding(selector, name, .{ .vreg = vreg, .loc = loc });
}

pub fn bindResultLoc(selector: *ComposedBlockSelector, name: []const u8, actual: ValueLoc) !void {
    const target = plannedResultLoc(selector, name, actual) orelse actual;
    const vreg = if (selector.values.get(name)) |binding|
        binding.vreg
    else blk: {
        const metadata = virtualRegMetadata(actual);
        const created: VirtualReg = .{
            .index = selector.next_virtual_reg,
            .class = metadata.class,
            .bits = metadata.bits,
        };
        selector.next_virtual_reg += 1;
        break :blk created;
    };
    if (!valueLocEql(actual, target)) try materializeLocIntoLocWithBits(selector, actual, target, vreg.bits);
    try putValueBinding(selector, name, .{ .vreg = vreg, .loc = target });
}

fn putValueBinding(
    selector: *ComposedBlockSelector,
    name: []const u8,
    binding: ValueBinding,
) !void {
    var next_dependencies = selector.address_dependencies;
    try updateAddressDependenciesForBinding(&next_dependencies, name, binding.loc);
    try selector.values.ensureUnusedCapacity(1);
    selector.values.putAssumeCapacity(name, binding);
    selector.address_dependencies = next_dependencies;
}

pub fn removeValueBinding(selector: *ComposedBlockSelector, name: []const u8) bool {
    var next_dependencies = selector.address_dependencies;
    next_dependencies.removeOwner(name);
    const removed = selector.values.remove(name);
    selector.address_dependencies = next_dependencies;
    return removed;
}

fn updateAddressDependenciesForBinding(
    domain: *AddressDependencyDomain,
    owner_name: []const u8,
    loc: ValueLoc,
) !void {
    const stack_ptr = switch (loc) {
        .stack_i32_ptr => |stack_ptr| stack_ptr,
        else => {
            domain.removeOwner(owner_name);
            return;
        },
    };
    const index = stack_ptr.index orelse {
        domain.removeOwner(owner_name);
        return;
    };
    var dependencies: [AddressDependencyDomain.max_dependencies_per_owner]AddressDependencyDomain.DependencySpec = undefined;
    var count: usize = 0;
    dependencies[count] = .{
        .name = index.name,
        .identity_type = .integer,
        .role = .index,
    };
    count += 1;
    if (index.addend_name) |addend_name| {
        dependencies[count] = .{
            .name = addend_name,
            .identity_type = .integer,
            .role = .addend,
        };
        count += 1;
    }
    try domain.replaceAddress(owner_name, dependencies[0..count]);
}

pub fn prepareFixedProductDefs(selector: *ComposedBlockSelector) !void {
    try clobberAccumulator(selector);
    try clobberArgReg(selector, .rdx);
}

pub fn bindFixedProductResult(selector: *ComposedBlockSelector, name: []const u8) !void {
    const plan = selector.allocation_plan orelse return error.UnsupportedCodegenValue;
    const assignment = plan.assignment(name) orelse {
        const spill = allocatePairSpillSlots(selector, name) orelse return error.UnsupportedCodegenValue;
        try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = .rdx } });
        try bindValueLoc(selector, name, .{ .spill128 = spill });
        return;
    };
    switch (assignment) {
        .gpr128 => |pair| {
            try clobberArgReg(selector, pair.lo);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair.lo });
            if (pair.hi != .rdx) {
                try clobberArgReg(selector, pair.hi);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = pair.hi, .src = .rdx } });
            }
            try bindValueLoc(selector, name, .{ .scratch128 = pair });
        },
        .spill => |index| {
            const spill = pairSpillFrameIndexMaybe(index) orelse return error.UnsupportedCodegenValue;
            if (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi)) return error.UnsupportedCodegenValue;
            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = .rdx } });
            try bindValueLoc(selector, name, .{ .spill128 = spill });
        },
        .gpr32, .gpr64, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer => return error.UnsupportedCodegenValue,
    }
}

pub fn plannedResultLoc(selector: *const ComposedBlockSelector, name: []const u8, actual: ValueLoc) ?ValueLoc {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(name) orelse return null;
    const planned: ?ValueLoc = switch (assignment) {
        .gpr32 => |reg| switch (actual) {
            .arg32, .scratch32, .eax, .spill64 => .{ .scratch32 = reg },
            else => null,
        },
        .gpr64 => |reg| switch (actual) {
            .arg64, .scratch64, .rax, .spill64 => .{ .scratch64 = reg },
            else => null,
        },
        .gpr128 => |pair| switch (actual) {
            .arg128, .scratch128, .spill128, .stack128_value => .{ .scratch128 = pair },
            else => null,
        },
        .fp16 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else null,
            .spill_fp => |fp| if (fp.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else null,
            else => null,
        },
        .fp32 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else null,
            .spill_fp => |fp| if (fp.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else null,
            else => null,
        },
        .fp64 => |reg| switch (actual) {
            .xmm => |fp| if (fp.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else null,
            .spill_fp => |fp| if (fp.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else null,
            else => null,
        },
        .vector_xmm => |reg| switch (actual) {
            .xmm => |fp| if (fp.vectorShape()) |shape| .{ .xmm = .{ .reg = reg, .bits = 128, .shape = .{ .vector = shape } } } else null,
            .spill_vector => |vector| .{ .xmm = .{ .reg = reg, .bits = 128, .shape = .{ .vector = vector.shape } } },
            else => null,
        },
        .stack_object, .stack_pointer => actual,
        .spill => |index| switch (actual) {
            .arg32, .scratch32, .eax => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg64, .scratch64, .rax, .spill64 => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg128, .scratch128, .spill128 => if (pairSpillFrameIndexMaybe(index)) |spill| if (frameIndexFitsFrame(selector, spill.lo) and frameIndexFitsFrame(selector, spill.hi)) .{ .spill128 = spill } else null else null,
            .xmm => |fp| if (fp.vectorShape()) |shape|
                if (pairSpillFrameIndexMaybe(index)) |frames|
                    if (frameIndexFitsFrame(selector, frames.lo) and frameIndexFitsFrame(selector, frames.hi)) .{ .spill_vector = .{ .frames = frames, .shape = shape } } else null
                else
                    null
            else if (spillFrameIndexMaybe(index)) |frame_index|
                if (frameIndexFitsFrame(selector, frame_index)) .{ .spill_fp = .{ .frame_index = frame_index, .bits = fp.bits } } else null
            else
                null,
            .spill_fp => actual,
            .spill_vector => actual,
            else => null,
        },
    };
    const target = planned orelse return null;
    if (plan.forwardValue(name) != null) return target;
    if (std.meta.activeTag(target) == .spill64 or std.meta.activeTag(target) == .spill128 or std.meta.activeTag(target) == .spill_fp or std.meta.activeTag(target) == .spill_vector) return target;
    if (valueLocEql(actual, target)) return target;
    return if (selector.enable_expired_plan_register_reuse and selector.expired_binding_this_position and targetLocHasOnlyExpiredConflicts(selector, target)) target else null;
}

pub fn targetLocHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, target: ValueLoc) bool {
    return switch (target) {
        .scratch32, .scratch64 => |reg| regHasOnlyExpiredConflicts(selector, reg),
        .scratch128 => |pair| blk: {
            var saw_conflict = false;
            if (regConflictStatus(selector, pair.lo)) |expired| {
                if (!expired) break :blk false;
                saw_conflict = true;
            }
            if (regConflictStatus(selector, pair.hi)) |expired| {
                if (!expired) break :blk false;
                saw_conflict = true;
            }
            break :blk saw_conflict;
        },
        .arg32, .arg64, .arg128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => false,
    };
}

pub fn regHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var saw_conflict = false;
    if (regConflictStatus(selector, reg)) |expired| {
        if (!expired) return false;
        saw_conflict = true;
    }
    return saw_conflict;
}

pub fn regConflictStatus(selector: *const ComposedBlockSelector, reg: ArgReg) ?bool {
    const plan = selector.allocation_plan orelse return null;
    var saw_conflict = false;
    var all_expired = true;

    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
        saw_conflict = true;
        const end = plan.intervalEnd(entry.key_ptr.*) orelse {
            all_expired = false;
            continue;
        };
        if (end >= selector.current_position) all_expired = false;
    }

    return if (saw_conflict) all_expired else null;
}

pub fn expireExpiredBindings(selector: *ComposedBlockSelector) !void {
    selector.expired_binding_this_position = false;
    const plan = selector.allocation_plan orelse return;

    var it = selector.values.iterator();
    while (it.next()) |entry| {
        const end = plan.intervalEnd(entry.key_ptr.*) orelse continue;
        if (end < selector.current_position) selector.expired_binding_this_position = true;
    }
}

pub fn materializeLocIntoLoc(selector: *ComposedBlockSelector, actual: ValueLoc, target: ValueLoc) !void {
    switch (target) {
        .scratch32 => |dst| switch (actual) {
            .arg32, .scratch32, .arg64, .scratch64 => |src| {
                if (src != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                }
            },
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = pair.lo } });
                }
            },
            .eax, .rax => {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
            },
            .spill64 => |frame_index| {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = dst, .frame_index = frame_index } });
            },
            .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .xmm => |dst| switch (actual) {
            .xmm => |src| {
                if (!src.shapeEql(dst)) return error.UnsupportedCodegenValue;
                if (src.reg != dst.reg) {
                    try clobberXmmReg(selector, dst.reg);
                    try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = dst.reg, .src = src.reg } });
                }
            },
            .spill_fp => |src| {
                if (src.bits != dst.bits) return error.UnsupportedCodegenValue;
                try clobberXmmReg(selector, dst.reg);
                if (dst.bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm64_rsp = .{ .frame_index = src.frame_index, .reg = dst.reg } });
                } else if (dst.bits == 16 or dst.bits == 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm32_rsp = .{ .frame_index = src.frame_index, .reg = dst.reg } });
                } else return error.UnsupportedCodegenValue;
            },
            .spill_vector => |src| {
                const dst_shape = dst.vectorShape() orelse return error.UnsupportedCodegenValue;
                if (!src.shape.eql(dst_shape) or !frameIndexFitsFrame(selector, src.frames.lo) or !frameIndexFitsFrame(selector, src.frames.hi)) return error.UnsupportedCodegenValue;
                try clobberXmmReg(selector, dst.reg);
                try selector.machine.instructions.append(selector.allocator, switch (src.shape.lane_type) {
                    .float => .{ .reload_xmm128ps_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                    .double => .{ .reload_xmm128_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                    .integer => if (src.shape.lane_bits == 32)
                        .{ .reload_xmm128ps_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } }
                    else
                        .{ .reload_xmm128_rsp = .{ .frame_index = src.frames.lo, .reg = dst.reg } },
                });
            },
            else => return error.UnsupportedCodegenValue,
        },
        .spill_fp => |dst| switch (actual) {
            .xmm => |src| {
                if (src.bits != dst.bits or !frameIndexFitsFrame(selector, dst.frame_index)) return error.UnsupportedCodegenValue;
                if (dst.bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = dst.frame_index, .reg = src.reg } });
                } else if (dst.bits == 16 or dst.bits == 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = dst.frame_index, .reg = src.reg } });
                } else return error.UnsupportedCodegenValue;
            },
            .spill_fp => |src| {
                if (src.bits != dst.bits) return error.UnsupportedCodegenValue;
                if (!src.frame_index.eql(dst.frame_index)) {
                    try clobberXmmReg(selector, .xmm0);
                    try materializeLocIntoLoc(selector, actual, .{ .xmm = .{ .reg = .xmm0, .bits = src.bits } });
                    try materializeLocIntoLoc(selector, .{ .xmm = .{ .reg = .xmm0, .bits = src.bits } }, target);
                }
            },
            else => return error.UnsupportedCodegenValue,
        },
        .spill_vector => |dst| switch (actual) {
            .xmm => |src| {
                const src_shape = src.vectorShape() orelse return error.UnsupportedCodegenValue;
                if (!src_shape.eql(dst.shape) or !frameIndexFitsFrame(selector, dst.frames.lo) or !frameIndexFitsFrame(selector, dst.frames.hi)) return error.UnsupportedCodegenValue;
                try selector.machine.instructions.append(selector.allocator, switch (src_shape.lane_type) {
                    .float => .{ .spill_xmm128ps_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                    .double => .{ .spill_xmm128_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                    .integer => if (src_shape.lane_bits == 32)
                        .{ .spill_xmm128ps_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } }
                    else
                        .{ .spill_xmm128_rsp = .{ .frame_index = dst.frames.lo, .reg = src.reg } },
                });
            },
            .spill_vector => |src| {
                if (!src.shape.eql(dst.shape)) return error.UnsupportedCodegenValue;
                if (!src.frames.lo.eql(dst.frames.lo)) {
                    const scratch: ValueLoc = .{ .xmm = .{ .reg = .xmm0, .bits = 128, .shape = .{ .vector = src.shape } } };
                    try materializeLocIntoLoc(selector, actual, scratch);
                    try materializeLocIntoLoc(selector, scratch, target);
                }
            },
            else => return error.UnsupportedCodegenValue,
        },
        .scratch64 => |dst| switch (actual) {
            .arg64, .scratch64 => |src| {
                if (src != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                }
            },
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
                }
            },
            .rax => {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
            },
            .spill64 => |frame_index| {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
            },
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |src| {
                    if (src != dst) {
                        try clobberArgReg(selector, dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                    }
                },
                .spill => |frame_index| {
                    try clobberArgReg(selector, dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
                },
            },
            .stack_f32_pair_ptr => |ptr| {
                try clobberArgReg(selector, dst);
                try emitStackF32PairPointerIntoReg(selector, ptr, dst);
            },
            .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .scratch128 => |dst| switch (actual) {
            .arg128, .scratch128 => |src| try emitPairIntoScratch(selector, src, dst),
            .spill128 => |spill| {
                try clobberAccumulator(selector);
                try clobberArgReg(selector, dst.lo);
                try clobberArgReg(selector, dst.hi);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
            },
            .stack128_value => |disp| {
                try loadStackU64IntoArg(selector, dst.lo, disp);
                try loadStackU64IntoArg(selector, dst.hi, disp + 8);
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
        },
        .spill64 => |frame_index| {
            if (!frameIndexFitsFrame(selector, frame_index)) return error.UnsupportedCodegenValue;
            switch (actual) {
                .arg32, .scratch32 => |src| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg_rsp = .{ .frame_index = frame_index, .reg = src } });
                },
                .arg64, .scratch64 => |src| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = src } });
                },
                .eax => {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
                },
                .rax => {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                },
                .spill64 => |source| if (!source.eql(frame_index)) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                },
                .stack_f32_pair_ptr => |ptr| {
                    try clobberArgReg(selector, .rcx);
                    try emitStackF32PairPointerIntoReg(selector, ptr, .rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = .rcx } });
                },
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .spill128 => |spill| {
            if (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi)) return error.UnsupportedCodegenValue;
            switch (actual) {
                .arg128, .scratch128 => |pair| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
                },
                .spill128 => |source| {
                    if (source.lo.eql(spill.lo) and source.hi.eql(spill.hi)) return;
                    try clobberAccumulator(selector);
                    if (source.hi.eql(spill.lo)) {
                        if (!source.hi.eql(spill.hi)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.hi });
                        }
                        if (!source.lo.eql(spill.lo)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
                        }
                    } else {
                        if (!source.lo.eql(spill.lo)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
                        }
                        if (!source.hi.eql(spill.hi)) {
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
                            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.hi });
                        }
                    }
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .arg32, .arg64, .arg128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

fn emitStackF32PairPointerIntoReg(selector: *ComposedBlockSelector, ptr: selector_types.StackF32PairPtrLoc, reg: ArgReg) !void {
    const disp = std.math.cast(i32, ptr.disp) orelse return error.UnsupportedCodegenValue;
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = reg });
    if (disp != 0) try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = reg, .imm = disp } });
}

pub fn materializeLocIntoLocWithBits(selector: *ComposedBlockSelector, actual: ValueLoc, target: ValueLoc, bits: u16) !void {
    const target_frame = switch (target) {
        .spill64 => |frame_index| frame_index,
        else => return materializeLocIntoLoc(selector, actual, target),
    };
    const actual_frame = switch (actual) {
        .spill64 => |frame_index| frame_index,
        else => return materializeLocIntoLoc(selector, actual, target),
    };
    if (bits > 32 or actual_frame.eql(target_frame)) return materializeLocIntoLoc(selector, actual, target);
    if (!frameIndexFitsFrame(selector, target_frame)) return error.UnsupportedCodegenValue;
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = actual_frame });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = target_frame });
}

pub fn frameIndexFitsFrame(selector: *const ComposedBlockSelector, frame_index: FrameIndex) bool {
    const offset = frame_index.byteOffset() catch return false;
    const end = std.math.add(u32, offset, 8) catch return false;
    return end <= selector.stack_frame_bytes;
}

pub fn valueLoc(selector: *const ComposedBlockSelector, name: []const u8) ?ValueLoc {
    const binding = selector.values.get(name) orelse return null;
    return binding.loc;
}

pub fn valueBits(selector: *const ComposedBlockSelector, name: []const u8) ?u16 {
    const binding = selector.values.get(name) orelse return null;
    return binding.vreg.bits;
}

/// Returns only the typed register-class contract needed to register a
/// ValueUseTransaction request. No physical ValueLoc escapes the state
/// authority, and consumers must still let the transaction resolve the
/// canonical current home after preparation.
pub fn valueRegisterClass(selector: *const ComposedBlockSelector, value: ir.Value) ?VirtualRegClass {
    const name = switch (value) {
        .named => |name| name,
        else => return null,
    };
    const binding = selector.values.get(name) orelse return null;
    return binding.vreg.class;
}

/// Read-only diagnostic classification for store consumers. This preserves
/// the accepted diagnostic vocabulary without exposing a physical ValueLoc or
/// permitting a consumer to make materialization decisions from it.
pub const StoreValueDiagnosticClass = enum {
    argument,
    scratch,
    accumulator,
    spill,
    other,
};

pub fn storeValueDiagnosticClass(selector: *const ComposedBlockSelector, value: ir.Value) ?StoreValueDiagnosticClass {
    const name = switch (value) {
        .named => |name| name,
        else => return .other,
    };
    const binding = selector.values.get(name) orelse return null;
    return switch (binding.loc) {
        .arg32, .arg64 => .argument,
        .scratch32, .scratch64 => .scratch,
        .eax, .rax => .accumulator,
        .spill64 => .spill,
        .arg128,
        .scratch128,
        .xmm,
        .stack_scalar,
        .stack128,
        .stack128_value,
        .stack_i32_array,
        .stack_i32_ptr,
        .stack_f32_pair_ptr,
        .readonly_table_ptr,
        .spill128,
        .spill_fp,
        .spill_vector,
        .aggregate_sse,
        => .other,
    };
}

/// Semantic store-pointer shape used only to retain legacy diagnostic
/// boundaries. Register identities, spill slots, and address descriptors stay
/// private to the value-use transaction.
pub const StorePointerDiagnosticClass = union(enum) {
    stack_scalar: struct { bits: u16, kind: selector_types.StackScalarLoc.Kind },
    register64,
    spill64,
    stack_i32_ptr,
    stack_i32_array,
    readonly_table,
    other,
};

pub fn storePointerDiagnosticClass(selector: *const ComposedBlockSelector, value: ir.Value) ?StorePointerDiagnosticClass {
    const name = switch (value) {
        .named => |name| name,
        else => return null,
    };
    const binding = selector.values.get(name) orelse return null;
    return switch (binding.loc) {
        .stack_scalar => |stack| .{ .stack_scalar = .{ .bits = stack.bits, .kind = stack.kind } },
        .arg64, .scratch64, .rax => .register64,
        .spill64 => .spill64,
        .stack_i32_ptr => .stack_i32_ptr,
        .stack_i32_array => .stack_i32_array,
        .readonly_table_ptr => .readonly_table,
        else => .other,
    };
}

pub const Scratch64InPlaceSource = struct {
    name: []const u8,
    reg: ArgReg,
};

pub fn reusableScratch64RegForInPlace(selector: *const ComposedBlockSelector, value: ir.Value) ?ArgReg {
    const source = scratch64InPlaceSource(selector, value) orelse return null;
    const plan = selector.allocation_plan orelse return null;
    const end = plan.intervalEnd(source.name) orelse return null;
    if (end > selector.current_position) return null;
    if (!scratch64SourceHasNoLiveAliases(selector, source, plan)) return null;
    return source.reg;
}

pub fn spillScratch64SourceForInPlace(selector: *const ComposedBlockSelector, value: ir.Value) ?Scratch64InPlaceSource {
    const source = scratch64InPlaceSource(selector, value) orelse return null;
    const plan = selector.allocation_plan orelse return null;
    _ = plan.intervalEnd(source.name) orelse return null;
    if (!scratch64SourceHasNoLiveAliases(selector, source, plan)) return null;
    return source;
}

pub fn xmmRegAvailable(selector: *const ComposedBlockSelector, reg: XmmReg) !bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| switch (entry.value_ptr.loc) {
        .xmm => |xmm| if (xmm.reg == reg and try valueMustSurviveClobber(selector, entry.key_ptr.*)) return false,
        else => {},
    };
    return true;
}

fn scratch64InPlaceSource(selector: *const ComposedBlockSelector, value: ir.Value) ?Scratch64InPlaceSource {
    const name = namedValue(value) orelse return null;
    const loc = resolveValue(selector, value) orelse return null;
    const reg = switch (loc) {
        .scratch64 => |reg| reg,
        else => return null,
    };
    return .{ .name = name, .reg = reg };
}

fn scratch64SourceHasNoLiveAliases(
    selector: *const ComposedBlockSelector,
    source: Scratch64InPlaceSource,
    plan: *const SelectorAllocationPlan,
) bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!locContainsReg(entry.value_ptr.loc, source.reg)) continue;
        if (std.mem.eql(u8, entry.key_ptr.*, source.name)) continue;
        const other_end = plan.intervalEnd(entry.key_ptr.*) orelse return false;
        if (other_end >= selector.current_position) return false;
    }
    return true;
}

pub fn virtualRegMetadata(loc: ValueLoc) VirtualRegMetadata {
    return switch (loc) {
        .arg32, .scratch32, .eax => .{ .class = .gpr32, .bits = 32 },
        .arg64, .scratch64, .rax, .spill64 => .{ .class = .gpr64, .bits = 64 },
        .arg128, .scratch128, .spill128, .stack128_value => .{ .class = .gpr128, .bits = 128 },
        .xmm => |fp| .{ .class = switch (fp.bits) {
            16 => .fp16,
            32 => .fp32,
            64 => .fp64,
            128 => if (fp.vectorShape() != null) .vector_xmm else unreachable,
            else => unreachable,
        }, .bits = fp.bits },
        .spill_fp => |fp| .{ .class = switch (fp.bits) {
            16 => .fp16,
            32 => .fp32,
            64 => .fp64,
            else => unreachable,
        }, .bits = fp.bits },
        .spill_vector => .{ .class = .vector_xmm, .bits = 128 },
        .stack_scalar, .stack128, .stack_i32_array => .{ .class = .stack_object, .bits = 0 },
        .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr => .{ .class = .stack_pointer, .bits = 64 },
        .aggregate_sse => .{ .class = .aggregate_sse, .bits = 128 },
    };
}

pub fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .eax);
}

pub fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .rax);
}

/// A global load has no SSA address operand. Keep its accumulator definition
/// in the state authority, including preservation of previous live values.
pub fn defineGlobalPointerLoad(selector: *ComposedBlockSelector, result: []const u8, symbol: []const u8) !?Diagnostic {
    var definition = try AccumulatorDefinitionTransaction.begin(selector);
    defer definition.deinit();
    if (try definition.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .load_global_ptr_rax = symbol });
    try definition.define(result, .fullRax());
    try definition.commit();
    return null;
}

/// Symbolic addresses have no SSA source. The existing definition transaction
/// owns live accumulator preservation, flag preservation and rollback.
pub fn defineGlobalAddress(selector: *ComposedBlockSelector, result: []const u8, address: @import("../symbol_address.zig").Address) !?Diagnostic {
    var definition = try AccumulatorDefinitionTransaction.begin(selector);
    defer definition.deinit();
    if (try definition.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .lea_global_offset_rax = address });
    try definition.define(result, .fullRax());
    try definition.commit();
    return null;
}

pub fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
    if (bits == 64) try bindRax(selector, name) else try bindEax(selector, name);
}

pub fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
    const actual: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
    try bindResultLoc(selector, name, actual);
}

pub fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
    try bindResultLoc(selector, name, .{ .scratch128 = pair });
}

pub fn emitPairIntoAbiRegs(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
    if (src.eql(dst)) return;
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst.lo);
    try clobberArgReg(selector, dst.hi);
    if (src.lo == dst.hi and src.hi == dst.lo) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = src.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
    } else if (src.lo == dst.hi) {
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
    } else if (src.hi == dst.lo) {
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
    } else {
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
    }
}

pub fn spillCurrentAccumulator(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = try liveAccumulatorName(selector) orelse return null;
    return try spillValue(selector, name);
}

pub fn preserveRaxForDestructiveAccumulatorUse(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    _ = value;
    return try spillCurrentAccumulator(selector);
}

pub fn preserveLiveAccumulatorValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    const binding = selector.values.get(name) orelse return .{ .unsupported_value = "composed-block-preserve-live-lhs" };
    const loc = binding.loc;
    const bits = binding.vreg.bits;
    switch (loc) {
        .eax, .rax => {},
        else => return null,
    }
    const dst = try scratch64RegForUseAvoiding(selector, null) orelse return try spillValue(selector, name);
    try clobberArgReg(selector, dst);
    if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
        try bindValueLoc(selector, name, .{ .scratch64 = dst });
    } else if (bits <= 32) {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
        try bindValueLoc(selector, name, .{ .scratch32 = dst });
    } else return .{ .no_emitter = "composed-block-preserve-live-lhs-width" };
    return null;
}

pub fn spillValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    if (selector.stack_frame_bytes < 24) return .{ .no_spill_envelope = "composed-block-spill-frame" };
    const loc = resolveValue(selector, .{ .named = name }) orelse return .{ .unsupported_value = "composed-block-spill-unknown" };
    switch (loc) {
        .spill64 => return null,
        .spill128, .spill_fp, .spill_vector => return null,
        .aggregate_sse => return .{ .no_emitter = "composed-block-aggregate-spill" },
        .readonly_table_ptr => |ptr| if (ptr.storage == .spill) return null,
        else => {},
    }
    if (loc == .xmm and loc.xmm.vectorShape() != null) {
        const shape = loc.xmm.vectorShape().?;
        const frames = allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "composed-block-vector-spill-slots" };
        try selector.machine.instructions.append(selector.allocator, switch (shape.lane_type) {
            .float => .{ .spill_xmm128ps_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
            .double => .{ .spill_xmm128_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
            .integer => if (shape.lane_bits == 32)
                .{ .spill_xmm128ps_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } }
            else
                .{ .spill_xmm128_rsp = .{ .frame_index = frames.lo, .reg = loc.xmm.reg } },
        });
        try bindValueLoc(selector, name, .{ .spill_vector = .{ .frames = frames, .shape = shape } });
        return null;
    }
    const frame_index = allocateSpillSlot(selector, name) orelse return .{ .no_spill_envelope = "composed-block-spill-slots" };
    switch (loc) {
        .arg32, .scratch32 => |reg| {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg_rsp = .{ .frame_index = frame_index, .reg = reg } });
        },
        .arg64, .scratch64 => |reg| {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
        },
        .eax => {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
        },
        .rax => {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
        },
        .xmm => |fp| {
            if (fp.bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = frame_index, .reg = fp.reg } });
            } else if (fp.bits == 16 or fp.bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = fp.reg } });
            } else return .{ .no_emitter = "composed-block-spill-fp-width" };
            try bindValueLoc(selector, name, .{ .spill_fp = .{ .frame_index = frame_index, .bits = fp.bits } });
            return null;
        },
        .readonly_table_ptr => |ptr| switch (ptr.storage) {
            .reg => |reg| {
                try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = reg } });
                var spilled = ptr;
                spilled.storage = .{ .spill = frame_index };
                try bindValueLoc(selector, name, .{ .readonly_table_ptr = spilled });
                return null;
            },
            .spill => return null,
        },
        .arg128, .scratch128 => return .{ .no_emitter = "composed-block-spill-loc-pair" },
        .stack_scalar => return .{ .no_emitter = "composed-block-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-ptr" },
        .stack_f32_pair_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-f32-pair-ptr" },
        .spill64 => return .{ .no_emitter = "composed-block-spill-loc-spill64" },
        .spill128 => return .{ .no_emitter = "composed-block-spill-loc-spill128" },
        .spill_fp => return .{ .no_emitter = "composed-block-spill-loc-spill-fp" },
        .spill_vector => return .{ .no_emitter = "composed-block-spill-loc-spill-vector" },
        .aggregate_sse => return .{ .no_emitter = "composed-block-spill-loc-aggregate" },
    }
    try bindValueLoc(selector, name, .{ .spill64 = frame_index });
    return null;
}

pub fn spillPairValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    if (selector.stack_frame_bytes < stack128FrameBytes()) return .{ .no_spill_envelope = "composed-block-pair-spill-frame" };
    const loc = resolveValue(selector, .{ .named = name }) orelse return .{ .unsupported_value = "composed-block-pair-spill-unknown" };
    switch (loc) {
        .spill128 => return null,
        else => {},
    }
    const pair = switch (loc) {
        .arg128, .scratch128 => |pair| pair,
        .arg32, .scratch32, .eax => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr32" },
        .arg64, .scratch64, .rax, .spill64 => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr64" },
        .xmm, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-pair-spill-loc-fp" },
        .aggregate_sse => return .{ .no_emitter = "composed-block-pair-spill-loc-aggregate" },
        .stack_scalar => return .{ .no_emitter = "composed-block-pair-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-ptr" },
        .stack_f32_pair_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-f32-pair-ptr" },
        .readonly_table_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-readonly-table-ptr" },
        .spill128 => return .{ .no_emitter = "composed-block-pair-spill-loc-spill128" },
    };
    const spill = allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "composed-block-pair-spill-slots" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
    try bindValueLoc(selector, name, .{ .spill128 = spill });
    return null;
}

pub fn ensurePairSpill(selector: *ComposedBlockSelector, value: ir.Value) !PairSpillLoc {
    const name = namedValue(value) orelse return error.UnsupportedCodegenValue;
    if (resolveValue(selector, value)) |loc| switch (loc) {
        .spill128 => |spill| return spill,
        else => {},
    } else return error.UnsupportedCodegenValue;
    if (try spillPairValue(selector, name)) |_| return error.UnsupportedCodegenValue;
    return switch (resolveValue(selector, value) orelse return error.UnsupportedCodegenValue) {
        .spill128 => |spill| spill,
        else => error.UnsupportedCodegenValue,
    };
}

pub fn emitUnsignedLimbProduct(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, name: []const u8) !PairSpillLoc {
    try prepareFixedProductDefs(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try emitEflagsInstruction(selector, .{ .mul_rax_arg64_full = .rcx }, .write);
    try bindFixedProductResult(selector, name);
    return switch (valueLoc(selector, name) orelse return error.UnsupportedCodegenValue) {
        .spill128 => |spill| spill,
        else => error.UnsupportedCodegenValue,
    };
}

pub fn accumulateLimbWithCarry(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try emitEflagsDefinition(selector, .{ .add_arg64_rax = .rcx }, .carry);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try emitEflagsInstruction(selector, .adc_rax_imm0, .use_and_clobber);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

pub fn accumulateRegWithCarry(selector: *ComposedBlockSelector, lhs: ArgReg, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try emitEflagsDefinition(selector, .{ .add_arg64_rax = .rcx }, .carry);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try emitEflagsInstruction(selector, .adc_rax_imm0, .use_and_clobber);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

pub fn emitSignedUpperCorrection(selector: *ComposedBlockSelector, sign_limb: FrameIndex, subtract: PairSpillLoc) !void {
    const correction_label = try allocateEdgeLabel(selector);
    const end_label = try allocateEdgeLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = sign_limb } });
    try emitEflagsInstruction(selector, .{ .test_arg64 = .rcx }, .definition);
    try emitEflagsInstruction(selector, .{ .js = correction_label }, .use);
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end_label });
    try selector.machine.instructions.append(selector.allocator, .{ .label = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.lo } });
    try emitEflagsDefinition(selector, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } }, .carry);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.hi } });
    try emitEflagsInstruction(selector, .{ .sbb_arg64_rax = .rcx }, .use_and_clobber);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
}

pub const SpillSlotSnapshotEntry = struct {
    name: []const u8,
    assignment: SpillSlotAssignment,
};

fn insertOwnedSpillSlot(
    selector: *ComposedBlockSelector,
    lookup_name: []const u8,
    assignment: SpillSlotAssignment,
) !void {
    std.debug.assert(selector.spill_slots.get(lookup_name) == null);
    try selector.spill_slots.ensureUnusedCapacity(1);
    try selector.owned_spill_slot_keys.ensureUnusedCapacity(1);
    const owned_name = try selector.allocator.dupe(u8, lookup_name);
    errdefer selector.allocator.free(owned_name);
    selector.owned_spill_slot_keys.putAssumeCapacity(owned_name, owned_name);
    selector.spill_slots.putAssumeCapacity(owned_name, assignment);
}

fn snapshotContainsSpillSlot(
    snapshot: []const SpillSlotSnapshotEntry,
    name: []const u8,
) bool {
    for (snapshot) |entry| {
        if (std.mem.eql(u8, entry.name, name)) return true;
    }
    return false;
}

pub fn restoreSpillSlots(
    selector: *ComposedBlockSelector,
    snapshot: []const SpillSlotSnapshotEntry,
) void {
    while (true) {
        var speculative_name: ?[]const u8 = null;
        var owned_it = selector.owned_spill_slot_keys.keyIterator();
        while (owned_it.next()) |owned_name| {
            if (!snapshotContainsSpillSlot(snapshot, owned_name.*)) {
                speculative_name = owned_name.*;
                break;
            }
        }
        const name = speculative_name orelse break;
        std.debug.assert(selector.spill_slots.remove(name));
        const removed = selector.owned_spill_slot_keys.fetchRemove(name).?;
        selector.allocator.free(removed.value);
    }

    selector.spill_slots.clearRetainingCapacity();
    for (snapshot) |entry|
        selector.spill_slots.putAssumeCapacity(entry.name, entry.assignment);
}

pub fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
    if (selector.spill_slots.get(name)) |assignment| return spillFrameIndexMaybe(assignment.base);
    const base = selector.next_spill_slot;
    const frame_index = spillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and !frameIndexFitsFrame(selector, frame_index)) return null;
    insertOwnedSpillSlot(selector, name, .{ .base = base, .slots = 1 }) catch return null;
    selector.next_spill_slot = base + 1;
    return frame_index;
}

pub fn allocatePairSpillSlots(selector: *ComposedBlockSelector, name: []const u8) ?PairSpillLoc {
    if (selector.spill_slots.get(name)) |assignment| {
        if (assignment.slots < 2) return null;
        return pairSpillFrameIndexMaybe(assignment.base);
    }
    const base = selector.next_spill_slot;
    const spill = pairSpillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi))) return null;
    insertOwnedSpillSlot(selector, name, .{ .base = base, .slots = 2 }) catch return null;
    selector.next_spill_slot = base + 2;
    return spill;
}

pub fn spillFrameIndex(index: usize) FrameIndex {
    return spillFrameIndexMaybe(index) orelse unreachable;
}

pub fn spillFrameIndexMaybe(index: usize) ?FrameIndex {
    const byte_offset = std.math.mul(usize, index, 8) catch return null;
    return frameIndexForByteOffset(byte_offset);
}

pub fn frameIndexForByteOffset(byte_offset: usize) ?FrameIndex {
    if (byte_offset % 4 != 0) return null;
    return FrameIndex.fromSlot(byte_offset / 4) catch null;
}

pub fn pairSpillFrameIndexMaybe(index: usize) ?PairSpillLoc {
    const lo = spillFrameIndexMaybe(index) orelse return null;
    const hi = spillFrameIndexMaybe(index + 1) orelse return null;
    return .{ .lo = lo, .hi = hi };
}

pub fn emitValueIntoEax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    switch (value) {
        .int => |int| {
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try composed_helpers.i32BitPattern(int) });
        },
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            switch (loc) {
                .arg32, .scratch32, .arg64, .scratch64 => |reg| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                },
                .arg128, .scratch128 => |pair| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = pair.lo });
                },
                .spill64 => |frame_index| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = frame_index });
                },
                .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                .eax, .rax => {},
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    switch (value) {
        .int => return error.UnsupportedCodegenValue,
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            switch (loc) {
                .arg64, .scratch64 => |reg| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                },
                .spill64 => |frame_index| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                },
                .arg128, .scratch128 => |pair| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                },
                .rax => {},
                .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    if (bits == 64) try emitValueIntoRax(selector, value) else try emitValueIntoEax(selector, value);
}

pub fn preserveCurrentEaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = try liveEaxName(selector) orelse return null;
    const dst = try scratch64RegForUseAvoiding(selector, null) orelse {
        try spillValueOrError(selector, name);
        return null;
    };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch32 = dst });
    return null;
}

pub fn preserveCurrentRaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = try liveRaxName(selector) orelse return null;
    const dst = try scratch64RegForUseAvoiding(selector, null) orelse
        return .{ .no_spill_envelope = "composed-block-preserve-rax" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch64 = dst });
    return null;
}

pub fn scratchRegIsProvenFree(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return false,
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return false,
            .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| if (index.reg == reg) return false,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return false,
                .spill => {},
            },
            .eax, .rax, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return true;
}

pub fn emitValueIntoI128Return(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .stack128_value => |disp| {
            try loadStackU64IntoArg(selector, .rdx, disp + 8);
            try loadStackU64IntoRax(selector, disp);
            try clobberArgReg(selector, .rdx);
        },
        .arg128, .scratch128 => |pair| {
            try emitPairIntoAbiRegs(selector, pair, .{ .lo = .rdi, .hi = .rdx });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdi });
        },
        .spill128 => |spill| {
            try clobberArgReg(selector, .rdx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = spill.hi } });
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.lo });
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoFpReturn(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .xmm => |fp| {
            if (fp.bits != bits) return error.UnsupportedCodegenValue;
            if (fp.reg != .xmm0) try selector.machine.instructions.append(selector.allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = fp.reg } });
        },
        .spill_fp => |fp| {
            if (fp.bits != bits) return error.UnsupportedCodegenValue;
            if (bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm64_rsp = .{ .frame_index = fp.frame_index, .reg = .xmm0 } });
            } else if (bits == 16 or bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_xmm32_rsp = .{ .frame_index = fp.frame_index, .reg = .xmm0 } });
            } else return error.UnsupportedCodegenValue;
        },
        else => return error.UnsupportedCodegenValue,
    }
}

pub fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    try emitValueIntoScratchExcept(selector, value, reg, bits, null);
}

/// Materialize a named value into a scratch register and make that existing
/// copy its canonical location. Binary producers use this after stabilizing a
/// distinct accumulator alias before a destructive accumulator definition.
pub fn emitValueIntoScratchAndRelocate(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    const name = switch (value) {
        .named => |name| name,
        else => return error.UnsupportedCodegenValue,
    };
    try emitValueIntoScratch(selector, value, reg, bits);
    try bindValueLoc(selector, name, if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg });
}

pub fn emitPhiValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    switch (value) {
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            if (bits == 64) {
                switch (loc) {
                    .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = src } }),
                    .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = pair.lo } }),
                    .stack_f32_pair_ptr => |ptr| try emitStackF32PairPointerIntoReg(selector, ptr, reg),
                    .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            } else {
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = src } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = pair.lo } }),
                    .eax, .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            }
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn phiSourceDiagnostic(selector: *const ComposedBlockSelector, value: ir.Value) []const u8 {
    const loc = resolveValue(selector, value) orelse return "stage2-phi-src-unknown";
    return switch (loc) {
        .arg32 => "stage2-phi-src-arg32",
        .arg64 => "stage2-phi-src-arg64",
        .arg128 => "stage2-phi-src-arg128",
        .eax => "stage2-phi-src-eax",
        .rax => "stage2-phi-src-rax",
        .scratch32 => "stage2-phi-src-scratch32",
        .scratch64 => "stage2-phi-src-scratch64",
        .scratch128 => "stage2-phi-src-scratch128",
        .stack_scalar => "stage2-phi-src-stack64",
        .stack128 => "stage2-phi-src-stack128",
        .stack128_value => "stage2-phi-src-stack128-value",
        .stack_i32_array => "stage2-phi-src-stack-i32-array",
        .stack_i32_ptr => "stage2-phi-src-stack-i32-ptr",
        .stack_f32_pair_ptr => "stage2-phi-src-stack-f32-pair-ptr",
        .readonly_table_ptr => "stage2-phi-src-readonly-table-ptr",
        .spill64 => "stage2-phi-src-spill64",
        .spill128 => "stage2-phi-src-spill128",
        .xmm => "stage2-phi-src-xmm",
        .spill_fp => "stage2-phi-src-spill-fp",
        .spill_vector => "stage2-phi-src-spill-vector",
        .aggregate_sse => "stage2-phi-src-aggregate-sse",
    };
}

pub fn emitValueIntoScratchExcept(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16, ignore_name: ?[]const u8) !void {
    switch (value) {
        .int => return error.UnsupportedCodegenValue,
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            if (bits == 64) {
                switch (loc) {
                    .arg64, .scratch64 => |src| {
                        if (src != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                .dst = reg,
                                .src = src,
                            } });
                        }
                    },
                    .rax => {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                    },
                    .spill64 => |frame_index| {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } });
                    },
                    .arg128, .scratch128 => |pair| {
                        if (pair.lo != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                .dst = reg,
                                .src = pair.lo,
                            } });
                        }
                    },
                    .arg32, .scratch32, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            } else {
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |src| {
                        if (src != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                .dst = reg,
                                .src = src,
                            } });
                        }
                    },
                    .arg128, .scratch128 => |pair| {
                        if (pair.lo != reg) {
                            try clobberArgRegExcept(selector, reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                .dst = reg,
                                .src = pair.lo,
                            } });
                        }
                    },
                    .eax, .rax => {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    },
                    .spill64 => |frame_index| {
                        try clobberArgRegExcept(selector, reg, ignore_name);
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } });
                    },
                    .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
                }
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitBinaryArgAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, reg: ArgReg, bits: u16) !void {
    if (bits == 64) {
        try emitEflagsInstruction(selector, .{ .binary_arg_rax = .{
            .op = op,
            .reg = reg,
        } }, .write);
    } else {
        try emitEflagsInstruction(selector, .{ .binary_arg_eax = .{
            .op = op,
            .reg = reg,
        } }, .write);
    }
}

pub fn emitBinaryLocIntoAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc, bits: u16) !void {
    const reg: ArgReg = switch (loc) {
        .arg32, .scratch32 => |reg| if (bits <= 32) reg else return error.UnsupportedCodegenValue,
        .arg64, .scratch64 => |reg| if (bits == 64) reg else return error.UnsupportedCodegenValue,
        .spill64 => |frame_index| if (bits == 64) blk: {
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            break :blk .rcx;
        } else if (bits <= 32) blk: {
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            break :blk .rcx;
        } else return error.UnsupportedCodegenValue,
        .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    };
    try emitBinaryArgAccumulator(selector, op, reg, bits);
}

pub fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
    if (amount > 127) return error.UnsupportedCodegenValue;
    const existing = resolvePairValue(selector, value);
    const dst = if (existing) |src|
        try choosePairScratch(selector, src) orelse return error.UnsupportedCodegenValue
    else
        try choosePairScratch(selector, null) orelse return error.UnsupportedCodegenValue;
    const src = if (existing) |src| src else try materializePairValue(selector, value, dst);
    switch (amount) {
        0 => {
            try emitPairIntoScratch(selector, src, dst);
        },
        64 => {
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
            try emitZeroArg64(selector, dst.hi);
        },
        1...63 => {
            try emitPairIntoScratch(selector, src, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
            try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = @intCast(64 - amount) });
            try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.lo, .amount = @intCast(amount) } });
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = dst.lo } });
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
            try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.hi, .amount = @intCast(amount) } });
        },
        65...127 => return error.UnsupportedCodegenValue,
    }
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairShlImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
    if (amount != 64) return error.UnsupportedCodegenValue;
    const existing = resolvePairValue(selector, value);
    const dst = if (existing) |src| src else try materializePairValue(selector, value, pair_a);
    try clobberArgReg(selector, dst.hi);
    if (dst.lo != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
    try emitZeroArg64(selector, dst.lo);
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
    if (src.eql(dst)) return;
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst.lo);
    try clobberArgReg(selector, dst.hi);
    if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
    if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
}

pub fn materializePairValue(selector: *ComposedBlockSelector, value: ir.Value, dst: RegPair) !RegPair {
    switch (value) {
        .named => {},
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .arg128, .scratch128 => |src| {
            try emitPairIntoScratch(selector, src, dst);
            return dst;
        },
        .stack128_value => |disp| {
            try loadStackU64IntoArg(selector, dst.lo, disp);
            try loadStackU64IntoArg(selector, dst.hi, disp + 8);
            return dst;
        },
        .spill128 => |spill| {
            try clobberAccumulator(selector);
            try clobberArgReg(selector, dst.lo);
            try clobberArgReg(selector, dst.hi);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
            return dst;
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairLowLaneIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, dst: ArgReg) !void {
    switch (value) {
        .named => {},
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    switch (loc) {
        .arg128, .scratch128 => |pair| {
            if (pair.lo != dst) {
                try clobberArgReg(selector, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
            }
        },
        .stack128_value => |disp| {
            try clobberArgReg(selector, dst);
            try loadStackU64IntoArg(selector, dst, disp);
        },
        .spill128 => |spill| {
            try clobberArgReg(selector, dst);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = spill.lo } });
        },
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairHighLaneIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    try clobberAccumulator(selector);
    switch (loc) {
        .arg128, .scratch128 => |pair| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi }),
        .stack128_value => |disp| if (disp + 8 <= std.math.maxInt(u8))
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp + 8) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp + 8 }),
        .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.hi }),
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return error.UnsupportedCodegenValue,
    }
}

pub fn emitPairSignMask(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, dst: RegPair) !void {
    const src = try materializePairValue(selector, value, dst);
    if (src.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = dst.lo, .amount = 63 } });
    if (dst.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
    try bindPairScratch(selector, result_name, dst);
}

pub fn emitPairXorInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .xor, dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .xor, dst.hi, rhs.hi);
}

pub fn emitPairOrInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .@"or", dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .@"or", dst.hi, rhs.hi);
}

pub fn emitPairSubInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.lo });
    try emitEflagsDefinition(selector, .{ .binary_arg_rax = .{ .op = .sub, .reg = rhs.lo } }, .carry);
    try clobberArgReg(selector, dst.lo);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
    try emitEflagsInstruction(selector, .{ .sbb_arg64_rax = rhs.hi }, .use_and_clobber);
    try clobberArgReg(selector, dst.hi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
}

pub fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
        .op = op,
        .reg = rhs,
    } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
}

pub fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
    try clobberArgReg(selector, reg);
    switch (reg) {
        .rdx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdx = 0 }),
        .rcx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = 0 }),
        .r8 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = 0 }),
        .r9 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 }),
        .rdi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdi = 0 }),
        .rsi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rsi = 0 }),
    }
}

pub fn choosePairScratch(selector: *const ComposedBlockSelector, src: ?RegPair) !?RegPair {
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (try pairScratchIsAvailableForUse(selector, pair)) return pair;
    }
    return null;
}

pub fn choosePairScratchForClobber(selector: *const ComposedBlockSelector, src: ?RegPair) !?RegPair {
    if (!nextSpillSlotsFit(selector, 2)) return try choosePairScratch(selector, src);
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (try livePairNameContainingReg(selector, pair.lo) != null) continue;
        if (try livePairNameContainingReg(selector, pair.hi) != null) continue;
        return pair;
    }
    return null;
}

pub fn nextSpillSlotsFit(selector: *const ComposedBlockSelector, slots: usize) bool {
    if (slots == 0) return true;
    const last = std.math.add(usize, selector.next_spill_slot, slots - 1) catch return false;
    const frame_index = spillFrameIndexMaybe(last) orelse return false;
    return frameIndexFitsFrame(selector, frame_index);
}

pub fn pairScratchIsAvailableForUse(selector: *const ComposedBlockSelector, pair: RegPair) !bool {
    return try scratch64RegIsAvailableForUse(selector, pair.lo) and try scratch64RegIsAvailableForUse(selector, pair.hi);
}

pub fn clobberArgReg(selector: *ComposedBlockSelector, reg: ArgReg) !void {
    try clobberArgRegExcept(selector, reg, null);
}

pub fn clobberArgRegExcept(selector: *ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !void {
    while (pairNameContainingRegExcept(selector, reg, ignore_name)) |name| {
        if (try valueMustSurviveClobber(selector, name)) {
            try spillPairValueOrError(selector, name);
        } else {
            _ = removeValueBinding(selector, name);
        }
    }
    while (scalarNameInRegExcept(selector, reg, ignore_name)) |name| {
        if (try valueMustSurviveClobber(selector, name)) {
            try spillValueOrError(selector, name);
        } else {
            _ = removeValueBinding(selector, name);
        }
    }
}

pub fn clobberXmmReg(selector: *ComposedBlockSelector, reg: XmmReg) !void {
    while (fpNameInReg(selector, reg)) |name| {
        if (try valueMustSurviveClobber(selector, name)) {
            try spillValueOrError(selector, name);
        } else {
            _ = removeValueBinding(selector, name);
        }
    }
}

fn fpNameInReg(selector: *const ComposedBlockSelector, reg: XmmReg) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| switch (entry.value_ptr.loc) {
        .xmm => |fp| if (fp.reg == reg) return entry.key_ptr.*,
        else => {},
    };
    return null;
}

pub fn valueMustSurviveClobber(selector: *const ComposedBlockSelector, name: []const u8) !bool {
    if (selector.phi_results.contains(name)) return true;
    return if (selector.preserve_current_position_values)
        try valueIsLiveAtOrAfterCurrent(selector, name)
    else
        try valueIsLiveAfterCurrent(selector, name);
}

pub fn clobberAccumulator(selector: *ComposedBlockSelector) !void {
    try dropExpiredAccumulatorBindings(selector);
    while (try liveAccumulatorName(selector)) |name| {
        try spillValueOrError(selector, name);
    }
}

pub fn spillAccumulatorAliasesExcept(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const ignored = switch (value) {
        .named => |name| name,
        else => return,
    };
    while (try liveAccumulatorNameExcept(selector, ignored)) |name| {
        try spillValueOrError(selector, name);
    }
}

pub fn liveAccumulatorNameExcept(selector: *const ComposedBlockSelector, ignored: []const u8) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        if (!try valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn dropExpiredAccumulatorBindings(selector: *ComposedBlockSelector) !void {
    while (true) {
        var expired_name: ?[]const u8 = null;
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.loc) {
                .eax, .rax => {},
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => continue,
            }
            if (try valueMustSurviveClobber(selector, entry.key_ptr.*)) continue;
            expired_name = entry.key_ptr.*;
            break;
        }
        if (expired_name) |name| {
            _ = removeValueBinding(selector, name);
            continue;
        }
        break;
    }
}

/// The reuse-source transaction pins exactly one current operand across its
/// mutating preparation boundary. No other current-position value receives
/// this exclusion.
fn dropExpiredAccumulatorBindingsExcept(selector: *ComposedBlockSelector, excluded_name: []const u8) !void {
    while (true) {
        var expired_name: ?[]const u8 = null;
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (std.mem.eql(u8, entry.key_ptr.*, excluded_name)) continue;
            switch (entry.value_ptr.loc) {
                .eax, .rax => {},
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => continue,
            }
            if (try valueMustSurviveClobber(selector, entry.key_ptr.*)) continue;
            expired_name = entry.key_ptr.*;
            break;
        }
        if (expired_name) |name| {
            _ = removeValueBinding(selector, name);
            continue;
        }
        break;
    }
}

/// Preserve the simultaneous call inputs before sequential ABI placement.
/// In particular, a last-use argument can alias a register filled for an earlier
/// argument even though it is not live after the call.
/// Preserve the simultaneous pointer input before any ABI register changes.
/// Consumers receive its durable frame index, never a borrowed register home.
pub fn preserveIndirectCallTarget(selector: *ComposedBlockSelector, callee: ir.Value) !FrameIndex {
    if (callee != .named) return error.UnsupportedCodegenValue;
    const binding = selector.values.get(callee.named) orelse return error.UnsupportedCodegenValue;
    if (binding.vreg.bits != 64 or binding.vreg.class != .gpr64) return error.UnsupportedCodegenValue;
    if (try spillValue(selector, callee.named)) |_| return error.UnsupportedCodegenValue;
    const home = selector.values.get(callee.named).?.loc;
    if (home != .spill64) return error.UnsupportedCodegenValue;
    return home.spill64;
}

pub fn preserveCallArgumentSources(selector: *ComposedBlockSelector, call: ir.CallInst) !?Diagnostic {
    const stages_stack = @import("stack_arguments.zig").callCount(call) != null;
    var abi_index: usize = 0;
    for (call.args.items) |arg| {
        const previous = abi_index;
        abi_index += composed_helpers.callArgRegisterCount(arg.ty) orelse continue;
        if (arg.value != .named or !try valueIsLiveAtOrAfterCurrent(selector, arg.value.named)) continue;
        const loc = resolveValue(selector, arg.value) orelse continue;
        // Staging stack inputs precedes final register placement. Preserve
        // every register source, including inputs at their final use.
        var overlaps = stages_stack;
        for (0..@min(previous, 6)) |index| {
            const reg = ArgReg.fromIndex(index) catch unreachable;
            if (composed_helpers.locContainsReg(loc, reg)) overlaps = true;
        }
        if (!overlaps) continue;
        switch (loc) {
            .eax, .rax, .arg32, .arg64, .scratch32, .scratch64, .readonly_table_ptr => {
                if (try spillValue(selector, arg.value.named)) |diagnostic| return diagnostic;
            },
            .arg128, .scratch128 => if (try spillPairValue(selector, arg.value.named)) |diagnostic| return diagnostic,
            else => {},
        }
    }
    return null;
}

pub fn spillLiveCallerClobbersForCall(selector: *ComposedBlockSelector) !?Diagnostic {
    const AccumulatorAlias = struct {
        name: []const u8,
        loc: ValueLoc,
    };
    var accumulator_aliases: std.ArrayList(AccumulatorAlias) = .empty;
    defer accumulator_aliases.deinit(selector.allocator);
    var preserve_name: ?[]const u8 = null;
    var values = selector.values.iterator();
    while (values.next()) |entry| {
        const loc = entry.value_ptr.loc;
        switch (loc) {
            .eax, .rax => {},
            else => continue,
        }
        if (!try valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        try accumulator_aliases.append(selector.allocator, .{
            .name = entry.key_ptr.*,
            .loc = loc,
        });
        if (preserve_name == null or loc == .rax) preserve_name = entry.key_ptr.*;
    }
    if (preserve_name) |name| {
        if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        const preserved_home = selector.values.get(name).?.loc;
        for (accumulator_aliases.items) |alias| {
            if (std.mem.eql(u8, alias.name, name)) continue;
            try bindValueLoc(selector, alias.name, preserved_home);
        }
    }
    for (selector_allocatable_regs) |reg| {
        while (try livePairNameContainingReg(selector, reg)) |name| {
            if (try spillPairValue(selector, name)) |diagnostic| return diagnostic;
        }
        while (try liveScalarNameInReg(selector, reg)) |name| {
            if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        }
    }
    for (selector_allocatable_xmm_regs) |reg| {
        while (try liveFpNameInReg(selector, reg)) |name| {
            if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        }
    }
    return null;
}

fn liveFpNameInReg(selector: *const ComposedBlockSelector, reg: XmmReg) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .xmm => |fp| if (fp.reg == reg) return entry.key_ptr.*,
            else => {},
        }
    }
    return null;
}

pub fn liveAccumulatorName(selector: *const ComposedBlockSelector) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveAccumulatorNameAfterCurrent(selector: *const ComposedBlockSelector) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn valueIsLiveAtOrAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) !bool {
    return valueIsLiveAtBoundary(selector, name, .at_or_after_current);
}

pub fn liveEaxName(selector: *const ComposedBlockSelector) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveRaxName(selector: *const ComposedBlockSelector) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .eax, .scratch32, .scratch64, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveScalarNameInReg(selector: *const ComposedBlockSelector, reg: ArgReg) !?[]const u8 {
    return try liveScalarNameInRegExcept(selector, reg, null);
}

pub fn scalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .spill => {},
            },
            .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn liveScalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .spill => {},
            },
            .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn livePairNameContainingReg(selector: *const ComposedBlockSelector, reg: ArgReg) !?[]const u8 {
    return try livePairNameContainingRegExcept(selector, reg, null);
}

pub fn pairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn livePairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn valueIsLiveAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) !bool {
    return valueIsLiveAtBoundary(selector, name, .after_current);
}

pub const LivenessBoundary = enum {
    after_current,
    at_or_after_current,
};

pub fn valueIsLiveAtBoundary(
    selector: *const ComposedBlockSelector,
    name: []const u8,
    boundary: LivenessBoundary,
) !bool {
    if (selector.address_dependencies.count() != 0 and selector.allocation_plan == null)
        return error.AddressDependencyMissingPlan;
    const plan = selector.allocation_plan orelse return false;
    const context = AddressDependencyLivenessContext{ .selector = selector, .boundary = boundary };
    if (try selector.address_dependencies.dependencyIsRequired(name, context)) return true;
    const end = plan.intervalEnd(name) orelse return true;
    return intervalIsLiveAtBoundary(end, selector.current_position, boundary);
}

/// Validates both the live dependency graph and the named source's canonical
/// outgoing address edges without copying or accepting a caller-owned list.
pub fn validateAddressDependenciesForUse(
    selector: *const ComposedBlockSelector,
    name: []const u8,
) !void {
    if (selector.address_dependencies.count() != 0 and selector.allocation_plan == null)
        return error.AddressDependencyMissingPlan;
    if (selector.address_dependencies.count() == 0) return;
    const context = AddressDependencyLivenessContext{
        .selector = selector,
        .boundary = .at_or_after_current,
    };
    _ = try selector.address_dependencies.dependencyIsRequired(name, context);
    try selector.address_dependencies.validateOwnerClosure(name, context);
}

const AddressDependencyLivenessContext = struct {
    selector: *const ComposedBlockSelector,
    boundary: LivenessBoundary,

    pub fn validateOwner(context: AddressDependencyLivenessContext, owner: AddressDependencyDomain.OwnerView) !void {
        const binding = context.selector.values.get(owner.name) orelse
            return error.AddressDependencyMissingOwnerBinding;
        if (owner.identity_type != .address or binding.vreg.class != .stack_pointer)
            return error.AddressDependencyInvalidOwnerBindingType;
        if (!addressOwnerMatchesBinding(owner, binding.loc))
            return error.AddressDependencyStaleEdge;
    }

    pub fn isOwnerLive(context: AddressDependencyLivenessContext, owner_name: []const u8) !bool {
        const plan = context.selector.allocation_plan orelse
            return error.AddressDependencyMissingPlan;
        const end = plan.intervalEnd(owner_name) orelse
            return error.AddressDependencyMissingOwnerPlanEntry;
        return intervalIsLiveAtBoundary(end, context.selector.current_position, context.boundary);
    }

    pub fn validateDependency(
        context: AddressDependencyLivenessContext,
        dependency: AddressDependencyDomain.DependencyView,
    ) !void {
        const binding = context.selector.values.get(dependency.name) orelse
            return error.AddressDependencyMissingBinding;
        const plan = context.selector.allocation_plan orelse
            return error.AddressDependencyMissingPlan;
        _ = plan.intervalEnd(dependency.name) orelse
            return error.AddressDependencyMissingPlanEntry;
        const valid = switch (dependency.identity_type) {
            .address => binding.vreg.class == .stack_pointer,
            .pointer => binding.vreg.class == .stack_pointer or binding.vreg.class == .gpr64,
            .integer => switch (binding.vreg.class) {
                .gpr32, .gpr64, .gpr128 => true,
                .fp16, .fp32, .fp64, .vector_xmm, .aggregate_sse, .stack_object, .stack_pointer => false,
            },
            .frame_object => binding.vreg.class == .stack_object,
        };
        if (!valid) return error.AddressDependencyInvalidBindingType;
    }
};

fn intervalIsLiveAtBoundary(end: usize, current: usize, boundary: LivenessBoundary) bool {
    return switch (boundary) {
        .after_current => end > current,
        .at_or_after_current => end >= current,
    };
}

fn addressOwnerMatchesBinding(owner: AddressDependencyDomain.OwnerView, loc: ValueLoc) bool {
    const stack_ptr = switch (loc) {
        .stack_i32_ptr => |stack_ptr| stack_ptr,
        else => return false,
    };
    const index = stack_ptr.index orelse return false;
    const dependencies = owner.dependencySlice();
    const expected_count: usize = if (index.addend_name == null) 1 else 2;
    if (dependencies.len != expected_count) return false;
    if (dependencies[0].role != .index or
        dependencies[0].identity_type != .integer or
        !std.mem.eql(u8, dependencies[0].name, index.name)) return false;
    if (index.addend_name) |addend_name| {
        if (dependencies[1].role != .addend or
            dependencies[1].identity_type != .integer or
            !std.mem.eql(u8, dependencies[1].name, addend_name)) return false;
    }
    return true;
}

pub fn spillValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

/// Outgoing bounded variadic arguments are simultaneous values. Preserve a
/// later source before an earlier argument overwrites its current ABI register,
/// even when the source's last use is this call instruction itself.
pub fn preserveVariadicArgumentSources(selector: *ComposedBlockSelector, call: ir.CallInst) !?Diagnostic {
    if (call.args.items.len > 3) return .{ .no_emitter = "composed-block-variadic-argument-count" };
    for (call.args.items, 0..) |arg, index| {
        if (arg.value != .named) continue;
        const binding = selector.values.get(arg.value.named) orelse continue;
        const register = switch (binding.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |reg| reg,
            else => continue,
        };
        for (0..index) |earlier| {
            if (register == try ArgReg.fromIndex(earlier)) {
                // At most three scalar arguments: an overlapping source and
                // destination leave a spare ABI register outside both sets.
                // Use that register without requiring a spill frame solely
                // to break an argument permutation.
                var used: [6]bool = @splat(false);
                for (0..call.args.items.len) |destination| used[destination] = true;
                for (call.args.items) |source| {
                    if (source.value != .named) continue;
                    const current = selector.values.get(source.value.named) orelse continue;
                    switch (current.loc) {
                        .arg32, .arg64, .scratch32, .scratch64 => |reg| used[selector_types.argRegIndex(reg)] = true,
                        else => {},
                    }
                }
                var spare: ?ArgReg = null;
                for (used, 0..) |occupied, candidate| {
                    if (!occupied) {
                        spare = try ArgReg.fromIndex(candidate);
                        break;
                    }
                }
                const target = spare orelse return .{ .no_emitter = "composed-block-variadic-argument-registers" };
                try emitValueIntoScratchAndRelocate(selector, arg.value, target, binding.vreg.bits);
                break;
            }
        }
    }
    return null;
}

pub fn spillPairValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillPairValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

pub fn spillLiveValuesForCfgBoundary(selector: *ComposedBlockSelector) !void {
    while (try liveRegisterValueName(selector)) |name| {
        const loc = selector.values.get(name).?.loc;
        switch (loc) {
            .arg128, .scratch128 => try spillPairValueOrError(selector, name),
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64 => try spillValueOrError(selector, name),
            .xmm, .readonly_table_ptr => try spillValueOrError(selector, name),
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => unreachable,
        }
        if (selector.phi_results.contains(name)) {
            try selector.phi_destinations.put(name, selector.values.get(name).?.loc);
        }
    }
}

fn liveRegisterValueName(selector: *const ComposedBlockSelector) !?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!try valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm => return entry.key_ptr.*,
            .readonly_table_ptr => |ptr| if (ptr.storage == .reg) return entry.key_ptr.*,
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
        }
    }
    return null;
}

pub fn resolvePairValue(selector: *const ComposedBlockSelector, value: ir.Value) ?RegPair {
    const loc = resolveValue(selector, value) orelse return null;
    return switch (loc) {
        .arg128, .scratch128 => |pair| pair,
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => null,
    };
}

pub fn resolveValue(selector: *const ComposedBlockSelector, value: ir.Value) ?ValueLoc {
    return switch (value) {
        .named => |name| {
            const loc = valueLoc(selector, name) orelse resolveForwardValue(selector, name) orelse return null;
            return switch (loc) {
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm => loc,
                .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128, .spill_fp, .spill_vector => loc,
                .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => loc,
            };
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn resolveForwardValue(selector: *const ComposedBlockSelector, name: []const u8) ?ValueLoc {
    return resolveForwardValueForUse(selector, name) catch null;
}

pub fn resolveForwardValueForUse(
    selector: *const ComposedBlockSelector,
    name: []const u8,
) !ValueLoc {
    const plan = selector.allocation_plan orelse return error.ForwardValuePlanMissing;
    const forward = plan.forwardValue(name) orelse return error.ForwardValuePlanMissing;
    if (selector.current_position >= forward.definition_position)
        return error.ForwardValuePlanStale;
    return switch (plan.assignment(name) orelse return error.ForwardValueAssignmentMissing) {
        .gpr32 => |reg| if (forward.metadata.class == .gpr32)
            .{ .scratch32 = reg }
        else
            error.ForwardValueMetadataMismatch,
        .gpr64 => |reg| if (forward.metadata.class == .gpr64)
            .{ .scratch64 = reg }
        else
            error.ForwardValueMetadataMismatch,
        .spill => |index| switch (forward.metadata.class) {
            .gpr32, .gpr64 => if (spillFrameIndexMaybe(index)) |frame_index|
                if (frameIndexFitsFrame(selector, frame_index))
                    .{ .spill64 = frame_index }
                else
                    error.ForwardValueAssignmentOutOfFrame
            else
                error.ForwardValueMetadataMismatch,
            .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .aggregate_sse, .stack_object, .stack_pointer => error.ForwardValueMetadataMismatch,
        },
        .gpr128,
        .fp16,
        .fp32,
        .fp64,
        .vector_xmm,
        .stack_object,
        .stack_pointer,
        => error.ForwardValueMetadataMismatch,
    };
}
