const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../../ir.zig");
const x86_64_machine = @import("../../../machine.zig");
const x86_64_types = @import("../../../types.zig");
const selector_types = @import("../../selector_types.zig");
const state_data = @import("../../composed_selector_state_data.zig");
const selector_state = @import("../../composed_selector_state.zig");
const stage2_planning = @import("../../stage2_planning.zig");
const address_dependencies = @import("../../composed_selector_address_dependencies.zig");
const eflags = @import("../../composed_selector_eflags.zig");
const constant_table = @import("../../../constant_table.zig");
const aggregate_object = @import("../../aggregate_object.zig");
const composed_helpers = @import("../../composed_helpers.zig");
const Diagnostic = @import("../../inspection.zig").Diagnostic;

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;
const model = @import("../model.zig");
const Types = model;
const max_requests = Types.max_requests;
const max_identity_bytes = Types.max_identity_bytes;
const address_domain_snapshot_copies = Types.address_domain_snapshot_copies;
const address_domain_copies_per_request = Types.address_domain_copies_per_request;
const address_domain_snapshot_bytes = Types.address_domain_snapshot_bytes;
const Expected = Types.Expected;
const UseForm = Types.UseForm;
const Destination = Types.Destination;
const RequestHandle = Types.RequestHandle;
const AccumulatorSessionHandle = Types.AccumulatorSessionHandle;
const PreparedViewLease = Types.PreparedViewLease;
const ActionIdentity = Types.ActionIdentity;
const AddressOffset = Types.AddressOffset;
const PreparedShape = Types.PreparedShape;
const ByteAddressAction = Types.ByteAddressAction;
const ScaledAddressAction = Types.ScaledAddressAction;
const ReadOnlyTableAddressAction = Types.ReadOnlyTableAddressAction;
const StoreScalarAction = Types.StoreScalarAction;
const StoreImmediateAction = Types.StoreImmediateAction;
const StoreI64Action = Types.StoreI64Action;
const StoreStackPointerAction = Types.StoreStackPointerAction;
const MemcpyAction = Types.MemcpyAction;
const MemcpyTestFailure = Types.MemcpyTestFailure;
const ScalarLoadKind = Types.ScalarLoadKind;
const ScalarLoadAction = Types.ScalarLoadAction;
const ReadOnlyPairLoadAction = Types.ReadOnlyPairLoadAction;
const StackI128AliasLoadAction = Types.StackI128AliasLoadAction;
const ReadOnlyTableI16LoadAction = Types.ReadOnlyTableI16LoadAction;
const LoadRequestError = Types.LoadRequestError;
const LoadTestFailure = Types.LoadTestFailure;
const ScratchCompareRhs = Types.ScratchCompareRhs;
const ScratchCompareAction = Types.ScratchCompareAction;
const ScratchCompareTestFailure = Types.ScratchCompareTestFailure;
const CurrentHomeEqZeroAction = Types.CurrentHomeEqZeroAction;
const CurrentHomeEqZeroRequestError = Types.CurrentHomeEqZeroRequestError;
const CurrentHomeEqZeroTestFailure = Types.CurrentHomeEqZeroTestFailure;
const SetccEaxCompareStructure = Types.SetccEaxCompareStructure;
const SetccEaxCompareAction = Types.SetccEaxCompareAction;
const SetccEaxCompareRequestError = Types.SetccEaxCompareRequestError;
const SetccEaxCompareTestFailure = Types.SetccEaxCompareTestFailure;
const CurrentHomeSignBitAction = Types.CurrentHomeSignBitAction;
const CurrentHomeSignBitRequestError = Types.CurrentHomeSignBitRequestError;
const CurrentHomeSignBitTestFailure = Types.CurrentHomeSignBitTestFailure;
const I128EqMinAction = Types.I128EqMinAction;
const I128SignBitAction = Types.I128SignBitAction;
const I128PairRequestError = Types.I128PairRequestError;
const I128EqMinTestFailure = Types.I128EqMinTestFailure;
const I128SignBitTestFailure = Types.I128SignBitTestFailure;
const max_switch_cases = Types.max_switch_cases;
const SwitchCaseIntent = Types.SwitchCaseIntent;
const SwitchCompareChainAction = Types.SwitchCompareChainAction;
const PreparedAction = Types.PreparedAction;
const CopyDestination = Types.CopyDestination;
const PreparedIdentity = Types.PreparedIdentity;
const PreparedRegister = Types.PreparedRegister;
const PreparedScalarHome = Types.PreparedScalarHome;
const PreparedStackObject = Types.PreparedStackObject;
const PreparedAddressComponent = Types.PreparedAddressComponent;
const PreparedAddressDescriptor = Types.PreparedAddressDescriptor;
const PreparedStackF32PairAddress = Types.PreparedStackF32PairAddress;
const PreparedTablePointer = Types.PreparedTablePointer;
const PreparedPairLimb = Types.PreparedPairLimb;
const PreparedReadOnlyPair = Types.PreparedReadOnlyPair;
const PreparedCondition = Types.PreparedCondition;
const PreparedView = Types.PreparedView;
const PreparedRecord = Types.PreparedRecord;
const EarlyPlan = Types.EarlyPlan;
const OperandPhase = Types.OperandPhase;
const OrderedOperand = Types.OrderedOperand;
const SemanticRole = Types.SemanticRole;
const EarlyPreparedHome = Types.EarlyPreparedHome;
const Request = Types.Request;
const RequestPhase = Types.RequestPhase;
const Lifecycle = Types.Lifecycle;
const Identity = Types.Identity;
const Source = Types.Source;
const StoredRequest = Types.StoredRequest;
const PhysicalNode = Types.PhysicalNode;
const physical_node_count = Types.physical_node_count;
const max_mappings = Types.max_mappings;
const materialization = @import("../materialization.zig");
const composition = @import("../composition.zig");

const ScratchCompareKind = enum {
    ne_zero_i16,
    ne_zero_i32,
    ne_zero_i64,
    ne_named,
    eq_pointer_null,
    eq_pointer_named,
    eq_i52_zero,
    eq_named,
    eq_i64_immediate,
    unsigned_i16_immediate,
    ugt_named,
    ugt_i64_immediate,
    ugt_i32_immediate,
    sgt_i64_immediate,
    slt_i16_zero,
    slt_i64_immediate,
    signed_named,
    ult_i32_named,
    ult_i64_named,
    ult_i64_immediate,
};

const ScratchComparePlan = struct {
    kind: ScratchCompareKind,
    bits: u16,
    lhs_register: ArgReg = .rcx,
    rhs_register: ?ArgReg = null,
    immediate_register: ?ArgReg = null,
};

const SetccEaxComparePlan = struct {
    bits: u16,
    mask: ?i32 = null,
    signed_shift: ?u5 = null,
    definition: union(enum) {
        instruction: x86_64_machine.Instruction,
        compare_immediate: i128,
    },
    setcc: ?x86_64_machine.Instruction,
    prepare_before_definition: bool = false,
};

const CurrentHomeSignBitPlan = struct {
    bits: u16,
    shift: x86_64_machine.Instruction,
};

const CurrentHomeEqZeroTest = union(enum) {
    direct: x86_64_machine.Instruction,
    spill32: FrameIndex,
    spill64: FrameIndex,
};

pub fn isCurrentHomeSignBitIcmp(icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt or icmp.samesign) return false;
    const bits = switch (icmp.operand_ty) {
        .int => |value| value,
        else => return false,
    };
    if (bits != 32 and bits != 64) return false;
    if (icmp.lhs != .named) return false;
    return switch (icmp.rhs) {
        .int => |value| value == 0,
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => false,
    };
}

pub fn isI128EqMinIcmp(icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .eq) return false;
    if (!icmp.operand_ty.eql(.{ .int = 128 }) or icmp.lhs != .named) return false;
    return switch (icmp.rhs) {
        .int => |value| value == std.math.minInt(i128),
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => false,
    };
}

/// Pure future-dispatch classifier for the exact pair sign-bit form.
pub fn isI128SignBitIcmp(icmp: ir.IcmpInst) bool {
    if (icmp.predicate != .slt) return false;
    if (!icmp.operand_ty.eql(.{ .int = 128 }) or icmp.lhs != .named) return false;
    return switch (icmp.rhs) {
        .int => |value| value == 0,
        .named,
        .fp,
        .undef,
        .poison,
        .null_value,
        .zero_initializer,
        .vector,
        .constant_expr,
        => false,
    };
}

pub fn classifyScratchCompare(
    action: *const Types.ScratchCompareAction,
) !ScratchComparePlan {
    const rhs_tag = std.meta.activeTag(action.rhs);
    if (action.operand_ty == .ptr) {
        if (action.predicate != .eq) return error.ValueUseScratchCompareFormUnsupported;
        return switch (rhs_tag) {
            .null_pointer => .{ .kind = .eq_pointer_null, .bits = 64 },
            .named => .{
                .kind = .eq_pointer_named,
                .bits = 64,
                .rhs_register = .r8,
            },
            .immediate => error.ValueUseScratchCompareFormUnsupported,
        };
    }
    if (action.operand_ty != .int) return error.ValueUseScratchCompareFormUnsupported;
    const bits = action.operand_ty.int;
    if (bits == 0 or bits > 64) return error.ValueUseScratchCompareFormUnsupported;
    switch (action.rhs) {
        .null_pointer => return error.ValueUseScratchCompareFormUnsupported,
        .immediate => |immediate| {
            if (action.predicate == .ne and immediate == 0) return switch (bits) {
                16 => .{ .kind = .ne_zero_i16, .bits = bits },
                32 => .{ .kind = .ne_zero_i32, .bits = bits },
                64 => .{ .kind = .ne_zero_i64, .bits = bits },
                else => error.ValueUseScratchCompareFormUnsupported,
            };
            if (!action.samesign and action.predicate == .eq and bits == 52 and immediate == 0)
                return .{ .kind = .eq_i52_zero, .bits = bits };
            if (action.predicate == .eq and bits == 64 and immediate != 0) {
                _ = composed_helpers.i64Value(immediate) catch
                    return error.ValueUseScratchCompareImmediateOutOfRange;
                return .{ .kind = .eq_i64_immediate, .bits = bits };
            }
            if ((action.predicate == .ult or action.predicate == .ugt) and bits == 16) {
                _ = composed_helpers.u16BitPattern(immediate) catch
                    return error.ValueUseScratchCompareImmediateOutOfRange;
                return .{ .kind = .unsigned_i16_immediate, .bits = bits };
            }
            if (action.predicate == .ugt and bits == 64) return .{
                .kind = .ugt_i64_immediate,
                .bits = bits,
                .immediate_register = .r8,
            };
            if (action.predicate == .ugt and bits == 32) return .{
                .kind = .ugt_i32_immediate,
                .bits = bits,
                .immediate_register = .r8,
            };
            if (!action.samesign and action.predicate == .sgt and bits == 64)
                return .{ .kind = .sgt_i64_immediate, .bits = bits };
            if (action.predicate == .slt and bits == 16 and immediate == 0)
                return .{ .kind = .slt_i16_zero, .bits = bits };
            if (!action.samesign and action.predicate == .slt and bits == 64 and immediate != 0)
                return .{ .kind = .slt_i64_immediate, .bits = bits };
            if (action.predicate == .ult and bits == 64)
                return .{ .kind = .ult_i64_immediate, .bits = bits };
        },
        .named => {
            if (!action.samesign and action.predicate == .ne and
                (bits == 16 or bits == 32 or bits == 64))
            {
                return .{ .kind = .ne_named, .bits = bits, .rhs_register = .r8 };
            }
            if (action.predicate == .eq and (bits <= 32 or bits == 64))
                return .{ .kind = .eq_named, .bits = bits, .rhs_register = .r8 };
            if (action.predicate == .ugt and (bits == 32 or bits == 64))
                return .{ .kind = .ugt_named, .bits = bits, .rhs_register = .r8 };
            if (!action.samesign and (action.predicate == .slt or action.predicate == .sgt) and
                (bits == 16 or bits == 32 or bits == 64))
            {
                return .{ .kind = .signed_named, .bits = bits, .rhs_register = .r8 };
            }
            if (action.predicate == .ult and bits == 32) return .{
                .kind = .ult_i32_named,
                .bits = bits,
                .lhs_register = .r8,
                .rhs_register = .rcx,
            };
            if (!action.samesign and action.predicate == .ult and bits == 64) return .{
                .kind = .ult_i64_named,
                .bits = bits,
                .lhs_register = .r8,
                .rhs_register = .rcx,
            };
        },
    }
    return error.ValueUseScratchCompareFormUnsupported;
}
pub fn executeScratchCompare(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    initial_lhs_view: *const Types.PreparedView,
    action: *const Types.ScratchCompareAction,
) !void {
    _ = initial_lhs_view;
    const plan = try classifyScratchCompare(action);
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseScratchCompareAccumulatorSessionRequired;

    try preserveScratchCompareLiveAccumulator(Authority, transaction);
    try refreshScratchCompareOperandViews(Authority, transaction, lhs_index, action);
    try failScratchCompareForTest(Authority, transaction, .after_canonical_view_refresh);

    try stageScratchCompareOperand(
        Authority,
        transaction,
        lhs_index,
        &transaction.prepared_views[lhs_index].view,
        plan.lhs_register,
        plan.bits,
    );
    try failScratchCompareForTest(Authority, transaction, .after_lhs_staging);

    switch (action.rhs) {
        .named => |handle| {
            const rhs_index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
            try stageScratchCompareOperand(
                Authority,
                transaction,
                rhs_index,
                try Authority.registeredOperandView(Authority, transaction, handle),
                plan.rhs_register orelse return error.ValueUseScratchCompareFormUnsupported,
                plan.bits,
            );
            try failScratchCompareForTest(Authority, transaction, .after_rhs_staging);
        },
        .immediate => |immediate| if (plan.immediate_register) |reg| {
            try materialization.clobberPhysicalNode(transaction.selector, Types.PhysicalNode.fromArgReg(reg));
            const value = composed_helpers.i64Value(immediate) catch
                return error.ValueUseScratchCompareImmediateOutOfRange;
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                switch (reg) {
                    .r8 => .{ .mov_imm_r8 = value },
                    else => unreachable,
                },
            );
            try failScratchCompareForTest(Authority, transaction, .after_immediate_staging);
        },
        .null_pointer => {},
    }

    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failScratchCompareForTest(Authority, transaction, .after_accumulator_preparation);

    if ((plan.kind == .ne_named or plan.kind == .signed_named) and plan.bits == 16) {
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .shl_rcx_imm6 = 48 },
            .write,
        );
        try failScratchCompareForTest(Authority, transaction, .after_lhs_normalize_shl);
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 48 } },
            .write,
        );
        try failScratchCompareForTest(Authority, transaction, .after_lhs_normalize_sar);
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .shl_r8_imm6 = 48 },
            .write,
        );
        try failScratchCompareForTest(Authority, transaction, .after_rhs_normalize_shl);
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .sar_arg64_imm6 = .{ .reg = .r8, .amount = 48 } },
            .write,
        );
        try failScratchCompareForTest(Authority, transaction, .after_rhs_normalize_sar);
    }

    const definition: x86_64_machine.Instruction = switch (plan.kind) {
        .ne_zero_i16, .slt_i16_zero => .{
            .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 },
        },
        .ne_zero_i32 => .{ .test_arg32 = .rcx },
        .ne_zero_i64 => .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } },
        .ne_named,
        .eq_pointer_named,
        .eq_named,
        .ugt_named,
        .signed_named,
        => if (plan.bits <= 32)
            .{ .cmp_ecx_arg32 = .r8 }
        else
            .{ .cmp_rcx_arg64 = .r8 },
        .eq_pointer_null, .eq_i52_zero => .{ .test_arg64 = .rcx },
        .eq_i64_immediate,
        .sgt_i64_immediate,
        .slt_i64_immediate,
        .ult_i64_immediate,
        => .{ .cmp_arg64_imm64 = .{
            .reg = .rcx,
            .imm = composed_helpers.i64Value(action.rhs.immediate) catch
                return error.ValueUseScratchCompareImmediateOutOfRange,
        } },
        .unsigned_i16_immediate => .{ .cmp_arg16_imm16 = .{
            .reg = .rcx,
            .imm = composed_helpers.u16BitPattern(action.rhs.immediate) catch unreachable,
        } },
        .ugt_i64_immediate => .{ .cmp_rcx_arg64 = .r8 },
        .ugt_i32_immediate => .{ .cmp_r8d_arg32 = .rcx },
        .ult_i32_named => .{ .cmp_ecx_arg32 = .r8 },
        .ult_i64_named => .{ .cmp_rcx_arg64 = .r8 },
    };
    try selector_state.emitEflagsInstruction(transaction.selector, definition, .definition);
    try failScratchCompareForTest(Authority, transaction, .after_flags_definition);

    const setcc: x86_64_machine.Instruction = switch (plan.kind) {
        .ne_zero_i16, .ne_zero_i32, .ne_zero_i64, .ne_named => .setne_eax,
        .eq_pointer_null, .eq_pointer_named, .eq_i52_zero, .eq_named, .eq_i64_immediate => .sete_eax,
        .unsigned_i16_immediate => if (action.predicate == .ult) .setb_eax else .seta_eax,
        .ugt_named, .ugt_i64_immediate, .ugt_i32_immediate => .setb_eax,
        .sgt_i64_immediate => .setg_eax,
        .slt_i16_zero, .slt_i64_immediate => .setl_eax,
        .signed_named => if (action.predicate == .slt) .setg_eax else .setl_eax,
        .ult_i32_named, .ult_i64_named, .ult_i64_immediate => .setb_eax,
    };
    try selector_state.emitEflagsInstruction(transaction.selector, setcc, .use);
    try failScratchCompareForTest(Authority, transaction, .after_setcc);
    const stored_action = &transaction.requests[lhs_index].prepared_action.?.scratch_compare;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failScratchCompareForTest(Authority, transaction, .after_result_identity_ownership);
    try session.define(result_name, .zeroExtending(1));
    try failScratchCompareForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failScratchCompareForTest(Authority, transaction, .after_result_finalization);
}
fn preserveScratchCompareLiveAccumulator(
    comptime Authority: type,
    transaction: anytype,
) !void {
    const flags_before = transaction.selector.eflags.snapshot();
    const semantic_records_before = transaction.selector.eflags_semantics.items.len;
    var preserved_any = false;
    while (try selector_state.liveAccumulatorNameAfterCurrent(transaction.selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(transaction.selector, live_name)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        if (!preserved_any) {
            preserved_any = true;
            try failScratchCompareForTest(Authority, transaction, .after_first_accumulator_preservation);
        }
    }
    try transaction.selector.eflags.validateSnapshot(flags_before);
    if (transaction.selector.eflags_semantics.items.len != semantic_records_before)
        return error.EflagsScratchComparePreservationChanged;
}
fn refreshScratchCompareOperandViews(
    comptime Authority: type,
    transaction: anytype,
    lhs_index: u8,
    action: *const Types.ScratchCompareAction,
) !void {
    transaction.prepared_views[lhs_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, lhs_index);
    transaction.prepared_view_valid[lhs_index] = true;
    switch (action.rhs) {
        .named => |handle| {
            const rhs_index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
            transaction.prepared_views[rhs_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, rhs_index);
            transaction.prepared_view_valid[rhs_index] = true;
        },
        .immediate, .null_pointer => {},
    }
}
fn stageScratchCompareOperand(
    comptime Authority: type,
    transaction: anytype,
    request_index: u8,
    view: *const Types.PreparedView,
    destination: ArgReg,
    bits: u16,
) !void {
    return stageScratchCompareOperandUnchecked(Authority, transaction, view, destination, bits) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
        return err;
    };
}
fn stageScratchCompareOperandUnchecked(
    comptime _: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    destination: ArgReg,
    bits: u16,
) !void {
    const current = try materialization.preparedViewLoc(view);
    const already_in_place = switch (current) {
        .arg32, .scratch32, .arg64, .scratch64 => |reg| reg == destination,
        else => false,
    };
    if (already_in_place) return;
    try materialization.clobberPhysicalNode(transaction.selector, Types.PhysicalNode.fromArgReg(destination));
    if (bits <= 32) {
        try materialization.materializeScalar32(transaction.selector, current, .{ .gpr32 = destination });
    } else {
        try materialization.materializeScalar64(transaction.selector, current, .{ .gpr64 = destination });
    }
}
fn failScratchCompareForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.ScratchCompareTestFailure,
) !void {
    if (builtin.is_test and transaction.scratch_compare_test_failure == boundary)
        return error.ValueUseScratchCompareTestFailure;
}
pub fn executeCurrentHomeEqZero(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.CurrentHomeEqZeroAction,
) !void {
    _ = initial_source_view;
    _ = action;
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseCurrentHomeEqZeroAccumulatorSessionRequired;

    try preserveScratchCompareLiveAccumulator(Authority, transaction);
    transaction.prepared_views[source_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, source_index);
    transaction.prepared_view_valid[source_index] = true;

    const request = &transaction.requests[source_index];
    const source_name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return error.ValueUseUnsupportedSource,
    };
    const binding = transaction.selector.values.get(source_name) orelse
        return error.ValueUseUnresolvedSource;
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    const test_plan = classifyCurrentHomeEqZero(binding, request.expected, current) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };

    switch (test_plan) {
        .direct => |instruction| try selector_state.emitEflagsInstruction(
            transaction.selector,
            instruction,
            .definition,
        ),
        .spill32 => |frame_index| {
            try materialization.clobberPhysicalNode(transaction.selector, .rcx);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } },
            );
            try selector_state.emitEflagsInstruction(
                transaction.selector,
                .{ .test_arg32 = .rcx },
                .definition,
            );
        },
        .spill64 => |frame_index| {
            try materialization.clobberPhysicalNode(transaction.selector, .rcx);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } },
            );
            try selector_state.emitEflagsInstruction(
                transaction.selector,
                .{ .test_arg64 = .rcx },
                .definition,
            );
        },
    }
    try failCurrentHomeEqZeroForTest(Authority, transaction, .after_test_definition);

    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failCurrentHomeEqZeroForTest(Authority, transaction, .after_accumulator_preparation);

    try selector_state.emitEflagsInstruction(transaction.selector, .sete_eax, .use);
    const stored_action = &transaction.requests[source_index].prepared_action.?.current_home_eq_zero;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try session.define(result_name, .zeroExtending(1));
    try session.finalize();
}
fn classifySetccEaxCompare(
    action: *const Types.SetccEaxCompareAction,
) !SetccEaxComparePlan {
    const bits = switch (action.operand_ty) {
        .int => |value| value,
        else => return error.ValueUseSetccEaxCompareFormUnsupported,
    };
    if (bits == 0 or bits > 64) return error.ValueUseSetccEaxCompareFormUnsupported;

    if (action.structure == .exact_ei) {
        const exact_width = bits == 3 or bits == 4 or bits == 5 or bits == 13 or
            bits == 14 or bits == 26 or bits == 27 or bits == 55 or bits == 56;
        if (!exact_width) return error.ValueUseSetccEaxCompareFormUnsupported;
        if (bits > 32) return error.ValueUseSetccEaxCompareExactEiWidthUnsupported;
        const mask: u32 = (@as(u32, 1) << @intCast(bits)) - 1;
        const rhs_bits: u32 = @intCast(action.immediate & @as(i128, mask));
        const signed = action.predicate == .slt or action.predicate == .sle or
            action.predicate == .sgt or action.predicate == .sge;
        const shift: ?u5 = if (signed) @intCast(32 - bits) else null;
        const compare_rhs: i32 = if (shift) |amount| blk: {
            const shifted: i32 = @bitCast(rhs_bits << amount);
            break :blk shifted >> amount;
        } else @bitCast(rhs_bits);
        const setcc: ?x86_64_machine.Instruction = switch (action.predicate) {
            .eq => .sete_eax,
            .ne => .setne_eax,
            .ult => .setb_eax,
            .ugt => .seta_eax,
            .slt => .setl_eax,
            .sgt => .setg_eax,
            .ule, .uge, .sle, .sge => null,
        };
        return .{
            .bits = bits,
            .mask = @bitCast(mask),
            .signed_shift = shift,
            .definition = .{ .instruction = .{ .cmp_eax_imm32 = compare_rhs } },
            .setcc = setcc,
        };
    }

    if (bits > 32) return error.ValueUseSetccEaxCompareFormUnsupported;
    if ((action.predicate == .eq or action.predicate == .ne) and action.immediate != 0) {
        _ = std.math.cast(i64, action.immediate) orelse
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        return .{
            .bits = bits,
            .definition = .{ .compare_immediate = action.immediate },
            .setcc = if (action.predicate == .eq) .sete_eax else .setne_eax,
        };
    }
    if (action.predicate == .sgt and (bits == 6 or bits == 16 or bits == 32)) {
        const immediate = std.math.cast(i64, action.immediate) orelse
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        if (immediate == -1) {
            const sign_mask: i32 = switch (bits) {
                6 => 1 << 5,
                16 => 1 << 15,
                32 => std.math.minInt(i32),
                else => unreachable,
            };
            return .{
                .bits = bits,
                .definition = .{ .instruction = .{ .and_eax_imm32 = sign_mask } },
                .setcc = .sete_eax,
                .prepare_before_definition = true,
            };
        }
        if (bits == 32) return .{
            .bits = bits,
            .definition = .{ .compare_immediate = action.immediate },
            .setcc = .setg_eax,
        };
    }
    if (!action.samesign and action.predicate == .slt and bits == 32) {
        _ = std.math.cast(i64, action.immediate) orelse
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        if (action.immediate == 0) return error.ValueUseSetccEaxCompareFormUnsupported;
        return .{
            .bits = bits,
            .definition = .{ .compare_immediate = action.immediate },
            .setcc = .setl_eax,
        };
    }
    if (action.samesign and (action.predicate == .ult or action.predicate == .ugt) and
        (bits == 6 or bits == 7))
    {
        const mask: i32 = if (bits == 6) 63 else 127;
        const immediate = std.math.cast(i64, action.immediate) orelse
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        if (immediate < 0 or immediate > mask)
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        return .{
            .bits = bits,
            .mask = mask,
            .definition = .{ .instruction = .{ .cmp_eax_imm32 = @intCast(immediate) } },
            .setcc = if (action.predicate == .ult) .setb_eax else .seta_eax,
        };
    }
    if (!action.samesign and action.predicate == .ult and bits == 6 and
        (action.immediate & 63) == 51)
    {
        return .{
            .bits = bits,
            .mask = 63,
            .definition = .{ .instruction = .{ .cmp_eax_imm32 = 51 } },
            .setcc = .setb_eax,
        };
    }
    if ((action.predicate == .ule or action.predicate == .ult) and bits == 8) {
        const immediate = std.math.cast(i64, action.immediate) orelse
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        if (immediate < 0 or immediate > 255)
            return error.ValueUseSetccEaxCompareImmediateOutOfRange;
        return .{
            .bits = bits,
            .definition = .{ .instruction = .{ .cmp_eax_imm32 = @intCast(immediate) } },
            .setcc = if (action.predicate == .ule) .setbe_eax else .setb_eax,
        };
    }
    if (action.predicate == .ult and bits == 32) return .{
        .bits = bits,
        .definition = .{ .compare_immediate = action.immediate },
        .setcc = .setb_eax,
    };
    return error.ValueUseSetccEaxCompareFormUnsupported;
}
pub fn executeSetccEaxCompare(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.SetccEaxCompareAction,
) !void {
    _ = initial_source_view;
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseSetccEaxCompareAccumulatorSessionRequired;
    try preserveScratchCompareLiveAccumulator(Authority, transaction);
    try failSetccEaxCompareForTest(Authority, transaction, .after_preamble);
    transaction.prepared_views[source_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, source_index);
    transaction.prepared_view_valid[source_index] = true;
    const plan = try classifySetccEaxCompare(action);

    const request = &transaction.requests[source_index];
    const source_name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return error.ValueUseUnsupportedSource,
    };
    const binding = transaction.selector.values.get(source_name) orelse
        return error.ValueUseUnresolvedSource;
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    validateSetccEaxCompareHome(binding, request.expected, current) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    selector_state.emitValueIntoEax(transaction.selector, .{ .named = source_name }) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failSetccEaxCompareForTest(Authority, transaction, .after_materialization);

    if (plan.mask) |mask| try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .and_eax_imm32 = mask },
        .write,
    );
    if (plan.signed_shift) |shift| {
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .shl_eax_imm5 = shift },
            .write,
        );
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .sar_eax_imm5 = shift },
            .write,
        );
    }
    try failSetccEaxCompareForTest(Authority, transaction, .after_normalization_or_mask);

    if (plan.prepare_before_definition) {
        if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        try failSetccEaxCompareForTest(Authority, transaction, .after_accumulator_preparation);
    }
    const definition: x86_64_machine.Instruction = switch (plan.definition) {
        .instruction => |instruction| instruction,
        .compare_immediate => |immediate| .{
            .cmp_eax_imm32 = std.math.cast(i32, immediate) orelse
                return error.ValueUseSetccEaxCompareImmediateOutOfRange,
        },
    };
    try selector_state.emitEflagsInstruction(transaction.selector, definition, .definition);
    try failSetccEaxCompareForTest(Authority, transaction, .after_eflags_definition);
    if (!plan.prepare_before_definition) {
        if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        try failSetccEaxCompareForTest(Authority, transaction, .after_accumulator_preparation);
    }
    const setcc = plan.setcc orelse return error.ValueUseSetccEaxComparePredicateUnsupported;
    try selector_state.emitEflagsInstruction(transaction.selector, setcc, .use);
    try failSetccEaxCompareForTest(Authority, transaction, .after_setcc);

    const stored_action = &transaction.requests[source_index].prepared_action.?.setcc_eax_compare;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try session.define(result_name, .zeroExtending(1));
    try failSetccEaxCompareForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failSetccEaxCompareForTest(Authority, transaction, .after_finalization);
}
fn validateSetccEaxCompareHome(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) Types.SetccEaxCompareRequestError!void {
    const bits = switch (expected.ty) {
        .int => |value| value,
        else => return error.ValueUseSetccEaxCompareWidthUnsupported,
    };
    if (bits == 0 or bits > 32 or binding.vreg.bits < bits)
        return error.ValueUseSetccEaxCompareWidthUnsupported;
    const accepted = switch (current) {
        .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr32 or
            binding.vreg.class == .gpr64,
        else => false,
    };
    if (!accepted) return error.ValueUseSetccEaxCompareLocationUnsupported;
}
fn failSetccEaxCompareForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.SetccEaxCompareTestFailure,
) !void {
    if (builtin.is_test and transaction.setcc_eax_compare_test_failure == boundary)
        return error.ValueUseSetccEaxCompareTestFailure;
}
fn classifyCurrentHomeSignBit(
    action: *const Types.CurrentHomeSignBitAction,
) Types.CurrentHomeSignBitRequestError!CurrentHomeSignBitPlan {
    return switch (action.operand_ty) {
        .int => |bits| switch (bits) {
            32 => .{ .bits = 32, .shift = .{ .shr_eax_imm5 = 31 } },
            64 => .{ .bits = 64, .shift = .{ .shr_rax_imm6 = 63 } },
            else => error.ValueUseCurrentHomeSignBitWidthUnsupported,
        },
        else => error.ValueUseCurrentHomeSignBitWidthUnsupported,
    };
}
pub fn executeCurrentHomeSignBit(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.CurrentHomeSignBitAction,
) !void {
    _ = initial_source_view;
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseCurrentHomeSignBitAccumulatorSessionRequired;

    try preserveCurrentHomeSignBitLiveAccumulator(Authority, transaction);
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_global_preamble);

    const plan = classifyCurrentHomeSignBit(action) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    const flags_before = transaction.selector.eflags.snapshot();
    const semantic_records_before = transaction.selector.eflags_semantics.items.len;
    const preservation_diagnostic = if (plan.bits == 32)
        try selector_state.preserveCurrentEaxIntoScratch(transaction.selector)
    else
        try selector_state.preserveCurrentRaxIntoScratch(transaction.selector);
    if (preservation_diagnostic) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try transaction.selector.eflags.validateSnapshot(flags_before);
    if (transaction.selector.eflags_semantics.items.len != semantic_records_before)
        return error.EflagsCurrentHomeSignBitPreservationChanged;
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_current_home_preservation);

    transaction.prepared_views[source_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, source_index);
    transaction.prepared_view_valid[source_index] = true;
    const request = &transaction.requests[source_index];
    const source_name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return error.ValueUseUnsupportedSource,
    };
    const binding = transaction.selector.values.get(source_name) orelse {
        Authority.recordRequestFailure(Authority, transaction, source_index);
        return error.ValueUseUnresolvedSource;
    };
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    validateCurrentHomeSignBitHome(binding, request.expected, current) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    if (plan.bits == 32) {
        selector_state.emitValueIntoEax(
            transaction.selector,
            .{ .named = source_name },
        ) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
            return err;
        };
    } else {
        selector_state.emitValueIntoRax(
            transaction.selector,
            .{ .named = source_name },
        ) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
            return err;
        };
    }
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_materialization);

    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_accumulator_preparation);

    try selector_state.emitEflagsInstruction(transaction.selector, plan.shift, .write);
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_shift);

    const stored_action =
        &transaction.requests[source_index].prepared_action.?.current_home_sign_bit;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try session.define(result_name, .zeroExtending(1));
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failCurrentHomeSignBitForTest(Authority, transaction, .after_finalization);
}
fn validateCurrentHomeSignBitHome(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) Types.CurrentHomeSignBitRequestError!void {
    const bits = switch (expected.ty) {
        .int => |value| value,
        else => return error.ValueUseCurrentHomeSignBitWidthUnsupported,
    };
    if ((bits != 32 and bits != 64) or binding.vreg.bits < bits)
        return error.ValueUseCurrentHomeSignBitWidthUnsupported;
    const accepted = if (bits == 32) switch (current) {
        .eax, .rax => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
        .arg32, .scratch32 => binding.vreg.class == .gpr32,
        .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr32 or
            binding.vreg.class == .gpr64,
        else => false,
    } else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr64,
        else => false,
    };
    if (!accepted) return error.ValueUseCurrentHomeSignBitLocationUnsupported;
}
fn preserveCurrentHomeSignBitLiveAccumulator(
    comptime _: type,
    transaction: anytype,
) !void {
    const flags_before = transaction.selector.eflags.snapshot();
    const semantic_records_before = transaction.selector.eflags_semantics.items.len;
    while (try selector_state.liveAccumulatorNameAfterCurrent(transaction.selector)) |live_name| {
        const original = transaction.selector.values.get(live_name) orelse {
            transaction.action_diagnostic =
                .{ .unsupported_value = "composed-block-preserve-live-lhs" };
            return error.ValueUseActionDiagnostic;
        };
        const original_loc = original.loc;
        if (try selector_state.preserveLiveAccumulatorValue(
            transaction.selector,
            live_name,
        )) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
        const preserved_loc = transaction.selector.values.get(live_name).?.loc;

        // Logical aliases of one live physical accumulator value share the
        // single accepted preservation move. Rebinding aliases emits no copy.
        while (true) {
            var alias_name: ?[]const u8 = null;
            var iterator = transaction.selector.values.iterator();
            while (iterator.next()) |entry| {
                if (std.mem.eql(u8, entry.key_ptr.*, live_name)) continue;
                if (!std.meta.eql(entry.value_ptr.loc, original_loc)) continue;
                if (!try selector_state.valueIsLiveAfterCurrent(
                    transaction.selector,
                    entry.key_ptr.*,
                )) continue;
                // Selector-map keys are stable IR-owned identities. Reuse
                // that durable key; never introduce transaction-local name
                // storage into the binding map.
                alias_name = entry.key_ptr.*;
                break;
            }
            const name = alias_name orelse break;
            try selector_state.bindValueLoc(
                transaction.selector,
                name,
                preserved_loc,
            );
        }
    }
    try transaction.selector.eflags.validateSnapshot(flags_before);
    if (transaction.selector.eflags_semantics.items.len != semantic_records_before)
        return error.EflagsCurrentHomeSignBitPreambleChanged;
}
fn failCurrentHomeSignBitForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.CurrentHomeSignBitTestFailure,
) !void {
    if (builtin.is_test and transaction.current_home_sign_bit_test_failure == boundary)
        return error.ValueUseCurrentHomeSignBitTestFailure;
}
pub fn executeI128EqMin(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.I128EqMinAction,
) !void {
    _ = initial_source_view;
    _ = action;
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseI128EqMinAccumulatorSessionRequired;

    try preserveScratchCompareLiveAccumulator(Authority, transaction);
    try failI128EqMinForTest(Authority, transaction, .after_preamble);
    const source_name = try refreshAndValidateI128PairSource(Authority, transaction, source_index);
    try failI128EqMinForTest(Authority, transaction, .after_canonical_refresh);

    const existing = selector_state.resolvePairValue(
        transaction.selector,
        .{ .named = source_name },
    );
    const pair = if (existing) |source|
        if (source.contains(selector_types.pair_a.lo) or
            source.contains(selector_types.pair_a.hi))
            selector_types.pair_b
        else
            selector_types.pair_a
    else
        selector_types.pair_a;
    try failI128EqMinForTest(Authority, transaction, .after_pair_selection);

    _ = selector_state.materializePairValue(
        transaction.selector,
        .{ .named = source_name },
        pair,
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failI128EqMinForTest(Authority, transaction, .after_pair_materialization);

    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failI128EqMinForTest(Authority, transaction, .after_accumulator_preparation);

    const temp: ArgReg = if (pair.contains(.r8)) .rcx else .r8;
    try selector_state.clobberArgReg(transaction.selector, temp);
    try failI128EqMinForTest(Authority, transaction, .after_temp_clobber);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_arg_rax = pair.hi },
    );
    try failI128EqMinForTest(Authority, transaction, .after_high_to_rax);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        switch (temp) {
            .rcx => .{ .mov_imm_rcx = std.math.minInt(i64) },
            .r8 => .{ .mov_imm_r8 = std.math.minInt(i64) },
            else => unreachable,
        },
    );
    try failI128EqMinForTest(Authority, transaction, .after_min_int);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .binary_arg_rax = .{ .op = .xor, .reg = temp } },
        .write,
    );
    try failI128EqMinForTest(Authority, transaction, .after_xor);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .binary_arg_rax = .{ .op = .@"or", .reg = pair.lo } },
        .write,
    );
    try failI128EqMinForTest(Authority, transaction, .after_or);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_rax_to_arg = temp },
    );
    try failI128EqMinForTest(Authority, transaction, .after_temp_copy);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .cmp_arg64_imm64 = .{ .reg = temp, .imm = 0 } },
        .definition,
    );
    try failI128EqMinForTest(Authority, transaction, .after_cmp);
    try selector_state.emitEflagsInstruction(transaction.selector, .sete_eax, .use);
    try failI128EqMinForTest(Authority, transaction, .after_sete);

    const stored_action = &transaction.requests[source_index].prepared_action.?.i128_eq_min;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failI128EqMinForTest(Authority, transaction, .after_result_identity_ownership);
    try session.define(result_name, .zeroExtending(1));
    try failI128EqMinForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failI128EqMinForTest(Authority, transaction, .after_finalization);
}
pub fn executeI128SignBit(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
    initial_source_view: *const Types.PreparedView,
    action: *const Types.I128SignBitAction,
) !void {
    _ = initial_source_view;
    _ = action;
    const session = if (transaction.accumulator_session) |*session|
        session
    else
        return error.ValueUseI128SignBitAccumulatorSessionRequired;

    try preserveScratchCompareLiveAccumulator(Authority, transaction);
    try failI128SignBitForTest(Authority, transaction, .after_preamble);
    const source_name = try refreshAndValidateI128PairSource(Authority, transaction, source_index);
    try failI128SignBitForTest(Authority, transaction, .after_canonical_refresh);

    selector_state.emitPairHighLaneIntoRax(
        transaction.selector,
        .{ .named = source_name },
    ) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    try failI128SignBitForTest(Authority, transaction, .after_high_limb_load);

    if (try session.prepare(.preserve, .spill_live)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failI128SignBitForTest(Authority, transaction, .after_accumulator_preparation);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .shr_rax_imm6 = 63 },
        .write,
    );
    try failI128SignBitForTest(Authority, transaction, .after_shift);

    const stored_action = &transaction.requests[source_index].prepared_action.?.i128_sign_bit;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &stored_action.result);
    try failI128SignBitForTest(Authority, transaction, .after_result_identity_ownership);
    try session.define(result_name, .zeroExtending(1));
    try failI128SignBitForTest(Authority, transaction, .after_result_definition);
    try session.finalize();
    try failI128SignBitForTest(Authority, transaction, .after_finalization);
}
fn refreshAndValidateI128PairSource(
    comptime Authority: type,
    transaction: anytype,
    source_index: u8,
) ![]const u8 {
    transaction.prepared_views[source_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, source_index);
    transaction.prepared_view_valid[source_index] = true;
    const request = &transaction.requests[source_index];
    const source_name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, source_index);
            return error.ValueUseUnsupportedSource;
        },
    };
    const binding = transaction.selector.values.get(source_name) orelse {
        Authority.recordRequestFailure(Authority, transaction, source_index);
        return error.ValueUseUnresolvedSource;
    };
    const current = transaction.prepared_views[source_index].canonical_source_loc;
    validateI128PairHome(binding, request.expected, current) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, source_index, err);
        return err;
    };
    return source_name;
}
fn validateI128PairHome(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) Types.I128PairRequestError!void {
    if (!expected.ty.eql(.{ .int = 128 }) or expected.register_class != .gpr128 or
        binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
    {
        return error.ValueUseI128PairWidthUnsupported;
    }
    switch (current) {
        .arg128, .scratch128, .stack128_value, .spill128 => {},
        else => return error.ValueUseI128PairLocationUnsupported,
    }
}
fn failI128EqMinForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.I128EqMinTestFailure,
) !void {
    if (builtin.is_test and transaction.i128_eq_min_test_failure == boundary)
        return error.ValueUseI128EqMinTestFailure;
}
fn failI128SignBitForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.I128SignBitTestFailure,
) !void {
    if (builtin.is_test and transaction.i128_sign_bit_test_failure == boundary)
        return error.ValueUseI128SignBitTestFailure;
}
fn classifyCurrentHomeEqZero(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) Types.CurrentHomeEqZeroRequestError!CurrentHomeEqZeroTest {
    const bits = switch (expected.ty) {
        .int => |value| value,
        else => return error.ValueUseCurrentHomeEqZeroWidthUnsupported,
    };
    if (bits == 0 or bits > 64 or binding.vreg.bits < bits)
        return error.ValueUseCurrentHomeEqZeroWidthUnsupported;

    if (bits <= 32) return switch (current) {
        .eax => if (binding.vreg.class == .gpr32)
            .{ .direct = .test_eax_eax }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .arg32, .scratch32 => |reg| if (binding.vreg.class == .gpr32)
            .{ .direct = .{ .test_arg32 = reg } }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .spill64 => |frame_index| if (binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64)
            .{ .spill32 = frame_index }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .rax, .arg64, .scratch64 => error.ValueUseCurrentHomeEqZeroWidthUnsupported,
        .spill128 => error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        else => error.ValueUseCurrentHomeEqZeroLocationUnsupported,
    };
    if (bits != 64) return error.ValueUseCurrentHomeEqZeroWidthUnsupported;
    return switch (current) {
        .rax => if (binding.vreg.class == .gpr64)
            .{ .direct = .test_rax_rax }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .arg64, .scratch64 => |reg| if (binding.vreg.class == .gpr64)
            .{ .direct = .{ .test_arg64 = reg } }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .spill64 => |frame_index| if (binding.vreg.class == .gpr64)
            .{ .spill64 = frame_index }
        else
            error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        .eax, .arg32, .scratch32 => error.ValueUseCurrentHomeEqZeroWidthUnsupported,
        .spill128 => error.ValueUseCurrentHomeEqZeroLocationUnsupported,
        else => error.ValueUseCurrentHomeEqZeroLocationUnsupported,
    };
}
fn failCurrentHomeEqZeroForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.CurrentHomeEqZeroTestFailure,
) !void {
    if (builtin.is_test and transaction.current_home_eq_zero_test_failure == boundary)
        return error.ValueUseCurrentHomeEqZeroTestFailure;
}

pub fn executeBranchCondition(
    comptime _: type,
    transaction: anytype,
    view: *const Types.PreparedView,
) !void {
    const condition = switch (view.*) {
        .condition => |condition| condition,
        else => return error.ValueUseBranchConditionHomeUnsupported,
    };
    switch (condition) {
        .eax => try selector_state.emitEflagsInstruction(
            transaction.selector,
            .test_eax_eax,
            .definition,
        ),
        .register32 => |reg| try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .test_arg8 = reg },
            .definition,
        ),
        .spill_low32 => |frame_index| {
            try materialization.clobberPhysicalNode(transaction.selector, .rcx);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index },
            });
            try selector_state.emitEflagsInstruction(
                transaction.selector,
                .{ .test_arg8 = .rcx },
                .definition,
            );
        },
        .rax_low32,
        .register64_low32,
        .pair_low32,
        .immediate,
        => return error.ValueUseBranchConditionHomeUnsupported,
    }
}
pub fn executeSwitchCompareChain(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    action: *const Types.SwitchCompareChainAction,
) !void {
    var targets: [Types.max_switch_cases][]const u8 = undefined;
    for (0..action.case_count) |index|
        targets[index] = try composition.ownActionIdentity(Authority, transaction, &action.case_targets[index]);
    const default_target = try composition.ownActionIdentity(Authority, transaction, &action.default_target);

    const condition = switch (view.*) {
        .condition => |condition| condition,
        else => return error.ValueUseSwitchConditionHomeUnsupported,
    };
    switch (condition) {
        .eax, .rax_low32 => {},
        .register32, .register64_low32, .pair_low32 => |reg| {
            try materialization.clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_arg_eax = reg,
            });
        },
        .spill_low32 => |frame_index| {
            try materialization.clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .reload_rsp_eax = frame_index,
            });
        },
        .immediate => |value| {
            try materialization.clobberPhysicalNode(transaction.selector, .accumulator);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_imm_eax = value,
            });
        },
    }
    if (action.bits < 32) try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .and_eax_imm32 = switchConditionMask(action.bits) },
        .write,
    );
    for (0..action.case_count) |index| {
        if (action.exhaustive_case != null and action.exhaustive_case.? == index) continue;
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .cmp_eax_imm32 = action.case_values[index] },
            .definition,
        );
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .je = targets[index] },
            .use,
        );
    }
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .jmp = if (action.exhaustive_case) |index| targets[index] else default_target,
    });
}
fn switchConditionMask(bits: u8) i32 {
    std.debug.assert(bits > 0 and bits < 32);
    const shift: u5 = @intCast(bits);
    return @bitCast((@as(u32, 1) << shift) - 1);
}
fn restoreSwitchDisplacedPhiDestinations(selector: *ComposedBlockSelector) !void {
    var it = selector.phi_destinations.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        if (!try selector_state.valueIsLiveAfterCurrent(selector, name)) continue;
        const destination = entry.value_ptr.*;
        const actual = selector_state.valueLoc(selector, name) orelse
            return error.ValueUseSwitchPhiDestinationMissing;
        if (composed_helpers.valueLocEql(actual, destination)) continue;
        const bits = selector_state.valueBits(selector, name) orelse
            return error.ValueUseSwitchPhiDestinationBitsMissing;
        try selector_state.materializeLocIntoLocWithBits(selector, actual, destination, bits);
        try selector_state.bindValueLoc(selector, name, destination);
    }
}
