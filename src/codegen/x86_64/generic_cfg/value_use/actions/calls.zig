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

pub const CallTestFailure = enum(u8) {
    mutate_after_prepared_construction,
    mutate_after_refresh,
    mutate_before_argument,
    after_preservation,
    after_argument,
    after_alignment,
    after_symbol_ownership,
    after_call_append,
    after_unalignment,
    after_mask,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub fn setCallTestFailureForTest(
    transaction: anytype,
    failure: ?CallTestFailure,
    argument_index: u8,
) !void {
    if (!builtin.is_test) return error.ValueUseTestHookUnavailable;
    transaction.call_test_failure = if (failure) |value| @backingInt(value) else null;
    transaction.call_test_argument_index = argument_index;
}

pub fn validateCallActionAttachment(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.PreparedAction,
) !void {
    switch (action.*) {
        .direct_call => |*direct| try validateDirectCallAttachment(Authority, transaction, direct),
        .int_byte_size_call => |*specialized| try validateIntByteSizeAttachment(Authority, transaction, specialized),
        else => return error.ValueUseCallActionUnsupported,
    }
}

pub fn executeAttachedCallAction(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.PreparedAction,
) !void {
    switch (action.*) {
        .direct_call => |*direct| try executeDirectCall(Authority, transaction, direct),
        .int_byte_size_call => |*specialized| try executeIntByteSizeCall(Authority, transaction, specialized),
        else => return error.ValueUseCallActionUnsupported,
    }
}

fn validateDirectCallAttachment(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.DirectCallAction,
) !void {
    try action.symbol.validate();
    if (action.argument_count > 6)
        return error.ValueUseCallArgumentCountUnsupported;
    const result_definition = try callResultDefinition(action.return_type);
    if (action.result) |*result| {
        try result.validate();
        if (result_definition == null) return error.ValueUseCallResultUnsupported;
    } else if (action.return_type == .void) {
        // A request-free transaction is admitted only by this closed,
        // validated zero-argument direct-call action.
    }
    var seen: [Types.max_requests]bool = @splat(false);
    var previous_index: ?u8 = null;
    for (
        action.arguments[0..action.argument_count],
        action.argument_types[0..action.argument_count],
    ) |handle, declared_type| {
        const index = Authority.validateRegisteredOperandHandle(
            Authority,
            transaction,
            handle,
        ) catch |err| {
            noteCallAttachmentHandleError(Authority, transaction, handle, err);
            return err;
        };
        if (transaction.requests[index].prepared_action != null) {
            Authority.noteRequestBoundaryError(
                Authority,
                transaction,
                index,
                error.ValueUsePreparedActionUnexpected,
            );
            return error.ValueUsePreparedActionUnexpected;
        }
        if (previous_index) |previous| {
            if (index < previous) {
                Authority.noteRequestBoundaryError(
                    Authority,
                    transaction,
                    index,
                    error.ValueUseCallArgumentSourceOrder,
                );
                return error.ValueUseCallArgumentSourceOrder;
            }
        }
        previous_index = index;
        _ = declared_type;
        seen[index] = true;
    }
    for (seen[0..transaction.request_count], 0..) |present, index| {
        if (!present) {
            Authority.noteRequestBoundaryError(
                Authority,
                transaction,
                @intCast(index),
                error.ValueUseCallRequestUnclaimed,
            );
            return error.ValueUseCallRequestUnclaimed;
        }
    }
}

fn validateIntByteSizeAttachment(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.IntByteSizeCallAction,
) !void {
    try action.symbol.validate();
    try action.result.validate();
    if (transaction.request_count != 1)
        return error.ValueUseCallArgumentCountUnsupported;
    const index = Authority.validateRegisteredOperandHandle(
        Authority,
        transaction,
        action.argument,
    ) catch |err| {
        noteCallAttachmentHandleError(Authority, transaction, action.argument, err);
        return err;
    };
    if (transaction.requests[index].prepared_action != null) {
        Authority.noteRequestBoundaryError(
            Authority,
            transaction,
            index,
            error.ValueUsePreparedActionUnexpected,
        );
        return error.ValueUsePreparedActionUnexpected;
    }
    if (index != 0) {
        Authority.noteRequestBoundaryError(
            Authority,
            transaction,
            index,
            error.ValueUseCallArgumentSourceOrder,
        );
        return error.ValueUseCallArgumentSourceOrder;
    }
}

fn noteCallAttachmentHandleError(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
    err: anyerror,
) void {
    if (handle.authority != @intFromPtr(transaction) or
        handle.generation != transaction.view_generation or
        handle.index >= transaction.request_count)
    {
        return;
    }
    Authority.noteRequestBoundaryError(Authority, transaction, handle.index, err);
}

fn validateCallRequest(request: *const Types.StoredRequest, declared_type: ir.Type) !void {
    if (!request.expected.ty.eql(declared_type) or request.destination != .prepared_source)
        return error.ValueUseCallArgumentTypeUnsupported;
    if (declared_type == .ptr) {
        if (request.form != .stack_object_address or request.expected.register_class != .stack_object or
            request.expected.pointer_address_space != 0)
            return error.ValueUseCallArgumentTypeUnsupported;
        return;
    }
    const bits = switch (declared_type) {
        .int => |value| value,
        else => return error.ValueUseCallArgumentTypeUnsupported,
    };
    if (bits != 32 and bits != 64) return error.ValueUseCallArgumentWidthUnsupported;
    if (request.form != (if (bits == 32) Types.UseForm.gpr32 else Types.UseForm.gpr64) or
        request.expected.register_class != if (bits == 32)
            VirtualRegClass.gpr32
        else
            VirtualRegClass.gpr64)
    {
        return error.ValueUseCallArgumentTypeUnsupported;
    }
}

fn executeDirectCall(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.DirectCallAction,
) !void {
    mutateCallSourceForTest(transaction, .mutate_after_prepared_construction, null);
    var next_eflags = transaction.selector.eflags;
    try next_eflags.apply(.clobber);
    const preservation_eflags = transaction.selector.eflags.snapshot();
    try validateDirectCallCopySchedule(Authority, transaction, action);
    const result_definition = try callResultDefinition(action.return_type);
    if (action.result != null) {
        try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
        if (try transaction.accumulator_session.?.prepareCallBeforeArguments(.clobber)) |diagnostic| {
            transaction.action_diagnostic = diagnostic;
            return error.ValueUseActionDiagnostic;
        }
    } else if (try selector_state.spillLiveCallerClobbersForCall(transaction.selector)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try refreshCallArguments(Authority, transaction, action.arguments[0..action.argument_count]);
    mutateCallSourceForTest(transaction, .mutate_after_refresh, null);
    if (builtin.is_test and
        transaction.call_test_failure == @backingInt(CallTestFailure.after_preservation))
        try transaction.selector.eflags.validateSnapshot(preservation_eflags);
    try failCallForTest(transaction, .after_preservation, null);

    for (
        action.arguments[0..action.argument_count],
        action.argument_types[0..action.argument_count],
        0..,
    ) |handle, declared_type, argument_index| {
        mutateCallSourceForTest(transaction, .mutate_before_argument, @intCast(argument_index));
        const target = ArgReg.fromIndex(argument_index) catch
            return error.ValueUseCallArgumentCountUnsupported;
        try stageDirectCallArgument(Authority, transaction, handle, declared_type, target);
        try failCallForTest(transaction, .after_argument, @intCast(argument_index));
    }
    if (action.result != null)
        try transaction.accumulator_session.?.finishCallPreparationAfterArguments();
    try emitCallAndAlignment(Authority, transaction, &action.symbol, action.return_type);
    if (action.result) |*result| {
        const owned_result = try composition.ownActionIdentity(Authority, transaction, result);
        try failCallForTest(transaction, .after_result_identity_ownership, null);
        try transaction.accumulator_session.?.define(owned_result, result_definition.?);
        try failCallForTest(transaction, .after_result_definition, null);
        try transaction.accumulator_session.?.finalize();
        try failCallForTest(transaction, .after_finalization, null);
    }
}

fn validateDirectCallCopySchedule(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.DirectCallAction,
) !void {
    for (action.arguments[0..action.argument_count], 0..) |handle, argument_index| {
        const destination = ArgReg.fromIndex(argument_index) catch
            return error.ValueUseCallArgumentCountUnsupported;
        const source = try preparedCallSourceArgReg(Authority, transaction, handle);
        if (source != null and source.? == destination) continue;
        for (action.arguments[argument_index + 1 .. action.argument_count]) |later_handle| {
            if ((try preparedCallSourceArgReg(Authority, transaction, later_handle)) == destination)
                return error.ValueUseCopyCycleRequiresO4;
        }
    }
}

fn preparedCallSourceArgReg(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
) !?ArgReg {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    if (!transaction.prepared_view_valid[index])
        return error.ValueUsePreparedViewMissing;
    return switch (transaction.prepared_views[index].canonical_source_loc) {
        .arg32, .scratch32, .arg64, .scratch64 => |reg| reg,
        else => null,
    };
}

fn executeIntByteSizeCall(
    comptime Authority: type,
    transaction: anytype,
    action: *const Types.IntByteSizeCallAction,
) !void {
    var next_eflags = transaction.selector.eflags;
    try next_eflags.apply(.clobber);
    try composition.beginAccumulatorSessionForPreparedAction(Authority, transaction);
    if (try transaction.accumulator_session.?.prepareCallBeforeArguments(.clobber)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try refreshCallArguments(Authority, transaction, &.{action.argument});
    try failCallForTest(transaction, .after_preservation, null);
    try stageIntByteSizeArgument(Authority, transaction, action.argument);
    try failCallForTest(transaction, .after_argument, 0);
    try transaction.accumulator_session.?.finishCallPreparationAfterArguments();
    try emitCallAndAlignment(Authority, transaction, &action.symbol, .{ .int = 16 });
    try selector_state.emitEflagsInstruction(transaction.selector, .{ .and_eax_imm32 = 0xffff }, .write);
    try failCallForTest(transaction, .after_mask, null);
    const owned_result = try composition.ownActionIdentity(Authority, transaction, &action.result);
    try failCallForTest(transaction, .after_result_identity_ownership, null);
    try transaction.accumulator_session.?.define(owned_result, .zeroExtending(16));
    try failCallForTest(transaction, .after_result_definition, null);
    try transaction.accumulator_session.?.finalize();
    try failCallForTest(transaction, .after_finalization, null);
}

fn emitCallAndAlignment(
    comptime Authority: type,
    transaction: anytype,
    symbol: *const Types.ActionIdentity,
    return_type: ir.Type,
) !void {
    const needs_alignment = transaction.selector.stack_frame_bytes == 0;
    if (needs_alignment) {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .sub_rsp_8);
        try failCallForTest(transaction, .after_alignment, null);
    }
    const owned_symbol = try composition.ownActionIdentity(Authority, transaction, symbol);
    try failCallForTest(transaction, .after_symbol_ownership, null);
    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .direct_call = .{ .symbol = owned_symbol, .ret_ty = return_type } },
        .clobber,
    );
    try failCallForTest(transaction, .after_call_append, null);
    if (needs_alignment) {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .add_rsp_8);
        try failCallForTest(transaction, .after_unalignment, null);
    }
}

fn refreshCallArguments(
    comptime Authority: type,
    transaction: anytype,
    arguments: []const Types.RequestHandle,
) !void {
    for (arguments) |handle| {
        const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
        transaction.prepared_views[index] = Authority.materialization.buildPreparedRecord(
            Authority,
            transaction,
            index,
        ) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, index, err);
            return err;
        };
        transaction.prepared_view_valid[index] = true;
    }
}

fn stageDirectCallArgument(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
    declared_type: ir.Type,
    target: ArgReg,
) !void {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    validateCallRequest(&transaction.requests[index], declared_type) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
    stageValidatedCallArgument(Authority, transaction, index, declared_type, target) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn stageIntByteSizeArgument(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
) !void {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    const request = &transaction.requests[index];
    if (!request.expected.ty.eql(.{ .int = 16 }) or
        request.expected.register_class != .gpr32 or
        request.form != .gpr32 or
        request.destination != .prepared_source)
    {
        Authority.noteRequestBoundaryError(
            Authority,
            transaction,
            index,
            error.ValueUseCallArgumentTypeUnsupported,
        );
        return error.ValueUseCallArgumentTypeUnsupported;
    }
    stageValidatedCallArgument(Authority, transaction, index, .{ .int = 16 }, .rdi) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}

fn stageValidatedCallArgument(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    declared_type: ir.Type,
    target: ArgReg,
) !void {
    const request = &transaction.requests[index];
    switch (request.source) {
        .named => {},
        .int, .null_value, .unsupported => return error.ValueUseCallArgumentNotNamed,
    }
    const current = (try Authority.validateRequestAt(Authority, transaction, index)) orelse
        return error.ValueUseCallArgumentLocationUnsupported;
    if (declared_type == .ptr) {
        const disp = switch (current) {
            .stack_scalar => |stack| stack.base_disp,
            .stack128 => |value| value,
            else => return error.ValueUseCallPointerLocationUnsupported,
        };
        try selector_state.clobberArgReg(transaction.selector, target);
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .{ .mov_rsp_arg64 = target },
        );
        if (disp != 0) {
            const addend = std.math.cast(i32, disp) orelse
                return error.ValueUseCallStackDisplacementUnsupported;
            try selector_state.emitEflagsInstruction(
                transaction.selector,
                .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } },
                .write,
            );
        }
        return;
    }
    const bits = declared_type.int;
    if (bits <= 32) {
        materialization.materializeScalar32(
            transaction.selector,
            current,
            .{ .gpr32 = target },
        ) catch return error.ValueUseCallArgumentLocationUnsupported;
    } else {
        materialization.materializeScalar64(
            transaction.selector,
            current,
            .{ .gpr64 = target },
        ) catch return error.ValueUseCallArgumentLocationUnsupported;
    }
}

fn callResultDefinition(return_type: ir.Type) !?AccumulatorDefinition {
    if (return_type == .void) return null;
    if (return_type == .ptr) return .fullRax();
    return switch (return_type) {
        .int => |bits| switch (bits) {
            32 => .zeroExtending(32),
            64 => .fullRax(),
            else => error.ValueUseCallReturnTypeUnsupported,
        },
        else => error.ValueUseCallReturnTypeUnsupported,
    };
}

fn failCallForTest(
    transaction: anytype,
    boundary: CallTestFailure,
    argument_index: ?u8,
) !void {
    if (builtin.is_test) {
        const configured = transaction.call_test_failure orelse return;
        if (configured != @backingInt(boundary)) return;
        if (argument_index) |index| {
            if (transaction.call_test_argument_index != index) return;
        }
        return error.ValueUseCallTestFailure;
    }
}

fn mutateCallSourceForTest(
    transaction: anytype,
    boundary: CallTestFailure,
    argument_index: ?u8,
) void {
    if (!builtin.is_test) return;
    const configured = transaction.call_test_failure orelse return;
    if (configured != @backingInt(boundary)) return;
    if (argument_index) |index| {
        if (transaction.call_test_argument_index != index) return;
    }
    const request_index = transaction.call_test_argument_index;
    const name = transaction.requests[request_index].source.named.slice();
    transaction.selector.values.getPtr(name).?.vreg.index += 1;
}

pub fn executeInlineMemcpy(
    comptime Authority: type,
    transaction: anytype,
    destination_index: u8,
    action: Types.MemcpyAction,
) !void {
    // Validate the final call clobber before caller preservation or argument
    // staging mutates selector state. The emission authority repeats this
    // check while applying the semantic record immediately before append.
    var next_eflags = transaction.selector.eflags;
    try next_eflags.apply(.clobber);

    if (try selector_state.spillLiveCallerClobbersForCall(transaction.selector)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    // These operands may die at this call, yet must survive earlier ABI
    // argument writes. Keep their canonical home stable before exposing the
    // refreshed records; live-after-call preservation alone is insufficient.
    try preserveMemcpyOperandBeforeStaging(Authority, transaction, action.source.index, false);
    if (action.length) |handle| try preserveMemcpyOperandBeforeStaging(Authority, transaction, handle.index, true);
    // Caller preservation may durably relocate an operand that dies at this
    // call (the legacy accumulator path is the notable case). Refresh the
    // transaction-owned canonical records immediately after that sole
    // authority, so later argument staging remains subject to strict
    // no-rebind post-validation without inventing post-call liveness.
    try refreshMemcpyPreparedOperand(Authority, transaction, destination_index);
    try refreshMemcpyPreparedOperand(Authority, transaction, action.source.index);
    if (action.length) |handle| try refreshMemcpyPreparedOperand(Authority, transaction, handle.index);
    try failMemcpyForTest(Authority, transaction, .after_preservation);

    try materializeMemcpyRequest(Authority, transaction, destination_index, .rdi);
    try failMemcpyForTest(Authority, transaction, .after_destination);
    try materializeMemcpyHandle(Authority, transaction, action.source, .rsi);
    try failMemcpyForTest(Authority, transaction, .after_source);
    if (action.length) |handle| {
        try materializeMemcpyHandle(Authority, transaction, handle, .rdx);
    } else {
        try selector_state.clobberArgReg(transaction.selector, .rdx);
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{ .mov_imm_rdx = @bitCast(action.length_immediate) });
    }
    try failMemcpyForTest(Authority, transaction, .after_length);

    try selector_state.emitEflagsInstruction(
        transaction.selector,
        .memcpy_rdi_rsi_rdx_rax,
        .clobber,
    );
    try failMemcpyForTest(Authority, transaction, .after_call_append);
}
pub fn executeInlineMemset(
    comptime Authority: type,
    transaction: anytype,
    destination_index: u8,
    action: Types.MemsetAction,
) !void {
    var next_eflags = transaction.selector.eflags;
    try next_eflags.apply(.clobber);
    if (try selector_state.spillLiveCallerClobbersForCall(transaction.selector)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try refreshMemcpyPreparedOperand(Authority, transaction, destination_index);
    if (action.fill) |handle| try refreshMemcpyPreparedOperand(Authority, transaction, handle.index);
    if (action.length) |handle| try refreshMemcpyPreparedOperand(Authority, transaction, handle.index);
    try failMemcpyForTest(Authority, transaction, .after_preservation);
    try materializeMemcpyRequest(Authority, transaction, destination_index, .rdi);
    try failMemcpyForTest(Authority, transaction, .after_destination);
    if (action.fill) |handle| {
        const current = try Authority.registeredOperandCurrent(Authority, transaction, handle);
        try materialization.materializeScalar32(transaction.selector, current, .{ .gpr32 = .rsi });
    } else {
        try selector_state.clobberArgReg(transaction.selector, .rsi);
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{ .mov_imm_rsi = action.fill_immediate });
    }
    try failMemcpyForTest(Authority, transaction, .after_source);
    if (action.length) |handle| {
        try materializeMemcpyHandle(Authority, transaction, handle, .rdx);
    } else {
        try selector_state.clobberArgReg(transaction.selector, .rdx);
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{ .mov_imm_rdx = @bitCast(action.length_immediate) });
    }
    try failMemcpyForTest(Authority, transaction, .after_length);
    try selector_state.emitEflagsInstruction(transaction.selector, .memset_rdi_sil_rdx_rax, .clobber);
    try failMemcpyForTest(Authority, transaction, .after_call_append);
}

fn preserveMemcpyOperandBeforeStaging(comptime Authority: type, transaction: anytype, index: u8, is_length: bool) !void {
    const current = (try Authority.validateRequestAt(Authority, transaction, index)) orelse return error.ValueUseUnsupportedSource;
    const source_reg: ?ArgReg = switch (current) {
        .arg64, .scratch64 => |reg| reg,
        .arg128, .scratch128 => |pair| pair.lo,
        else => null,
    };
    const reg = source_reg orelse return;
    if (reg != .rdi and !(is_length and reg == .rsi)) return;
    const name = transaction.requests[index].source.named.slice();
    if (try selector_state.spillValue(transaction.selector, name)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
}
fn refreshMemcpyPreparedOperand(comptime Authority: type, transaction: anytype, index: u8) !void {
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    transaction.prepared_views[index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, index);
}
fn materializeMemcpyHandle(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
    destination: ArgReg,
) !void {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    try materializeMemcpyRequest(Authority, transaction, index, destination);
}
fn materializeMemcpyRequest(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    destination: ArgReg,
) !void {
    return materializeMemcpyRequestUnchecked(Authority, transaction, index, destination) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
fn materializeMemcpyRequestUnchecked(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    destination: ArgReg,
) !void {
    const current = (try Authority.validateRequestAt(Authority, transaction, index)) orelse {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUseUnsupportedSource;
    };
    switch (current) {
        .arg128, .scratch128 => |pair| {
            if (pair.lo == destination) return;
            try selector_state.clobberArgReg(transaction.selector, destination);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_arg64_arg = .{ .dst = destination, .src = pair.lo },
            });
        },
        else => try materialization.materializeScalar64(
            transaction.selector,
            current,
            .{ .gpr64 = destination },
        ),
    }
}
fn failMemcpyForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.MemcpyTestFailure,
) !void {
    if (builtin.is_test) {
        if (transaction.memcpy_test_failure == boundary)
            return error.ValueUseMemcpyTestFailure;
    }
}
