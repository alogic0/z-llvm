const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../ir.zig");
const x86_64_machine = @import("../../machine.zig");
const x86_64_types = @import("../../types.zig");
const selector_types = @import("../selector_types.zig");
const state_data = @import("../composed_selector_state_data.zig");
const selector_state = @import("../composed_selector_state.zig");
const stage2_planning = @import("../stage2_planning.zig");
const address_dependencies = @import("../composed_selector_address_dependencies.zig");
const eflags = @import("../composed_selector_eflags.zig");
const constant_table = @import("../../constant_table.zig");
const aggregate_object = @import("../aggregate_object.zig");
const composed_helpers = @import("../composed_helpers.zig");
const Diagnostic = @import("../inspection.zig").Diagnostic;

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
const model = @import("model.zig");
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

pub fn beginAccumulatorSession(
    comptime Authority: type,
    transaction: anytype,
) !AccumulatorSessionHandle {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .sealed)
        return error.ValueUseAccumulatorSessionRequiresSealedPlan;
    if (transaction.accumulator_session != null)
        return error.ValueUseAccumulatorSessionAlreadyOpen;
    openAccumulatorSession(transaction);
    return .{
        .authority = @intFromPtr(transaction),
        .namespace = transaction.identity_namespace,
        .generation = transaction.view_generation,
    };
}

/// Internal action-owned session opening for closed actions whose private
/// semantic plan decides whether an accumulator result exists. This is not
/// part of the production facade.
pub fn beginAccumulatorSessionForPreparedAction(
    comptime Authority: type,
    transaction: anytype,
) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .views_exposed)
        return error.ValueUseAccumulatorSessionRequiresPreparedAction;
    if (transaction.accumulator_session != null)
        return error.ValueUseAccumulatorSessionAlreadyOpen;
    openAccumulatorSession(transaction);
}

fn openAccumulatorSession(transaction: anytype) void {
    transaction.accumulator_session = AccumulatorDefinitionSession.init(transaction.selector);
}
pub fn prepareAccumulator(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
    effect: AccumulatorPreparationEffect,
    displacement: AccumulatorDisplacementPolicy,
) !?Diagnostic {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    if (try session.prepare(effect, displacement)) |diagnostic| {
        Authority.rollbackInternal(Authority, transaction);
        return diagnostic;
    }
    return null;
}
pub fn prepareAccumulatorCallBeforeArguments(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
    effect: AccumulatorPreparationEffect,
) !?Diagnostic {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    if (try session.prepareCallBeforeArguments(effect)) |diagnostic| {
        Authority.rollbackInternal(Authority, transaction);
        return diagnostic;
    }
    return null;
}
pub fn finishAccumulatorCallPreparationAfterArguments(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
) !void {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    try session.finishCallPreparationAfterArguments();
}
pub fn materializeAccumulator(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
    source: ir.Value,
    definition: AccumulatorDefinition,
) !void {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    try session.materialize(source, definition);
}
pub fn spillAccumulatorValue(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
    name: []const u8,
) !void {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    try session.spill(name);
}
pub fn defineAccumulatorResult(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
    name: []const u8,
    definition: AccumulatorDefinition,
) !void {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    try session.define(name, definition);
}
pub fn finalizeAccumulatorResult(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
) !void {
    const session = try validateAccumulatorSession(Authority, transaction, handle);
    errdefer Authority.rollbackInternal(Authority, transaction);
    try session.finalize();
}
pub fn commitAccumulatorSession(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
) !void {
    _ = try validateAccumulatorSession(Authority, transaction, handle);
    return error.ValueUseAccumulatorIndependentCommit;
}
fn validateAccumulatorSession(
    comptime Authority: type,
    transaction: anytype,
    handle: AccumulatorSessionHandle,
) !*AccumulatorDefinitionSession {
    try Authority.requireActive(Authority, transaction);
    if (handle.authority != @intFromPtr(transaction) or
        handle.namespace != transaction.identity_namespace or
        handle.generation != transaction.view_generation)
    {
        return error.ValueUseAccumulatorSessionStale;
    }
    return if (transaction.accumulator_session) |*session|
        session
    else
        error.ValueUseAccumulatorSessionMissing;
}
pub fn ownActionIdentity(
    comptime _: type,
    transaction: anytype,
    identity: *const Types.ActionIdentity,
) ![]const u8 {
    const owned = try transaction.selector.allocator.dupe(u8, identity.slice());
    errdefer transaction.selector.allocator.free(owned);
    try transaction.selector.machine.owned_labels.append(transaction.selector.allocator, owned);
    return owned;
}
pub fn ownRegisteredOperandName(
    comptime Authority: type,
    transaction: anytype,
    handle: Types.RequestHandle,
) ![]const u8 {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    const source = switch (transaction.requests[index].source) {
        .named => |*identity| try identity.slice(&transaction.selector.value_use_names),
        .int, .null_value, .unsupported => {
            Authority.recordRequestFailure(Authority, transaction, index);
            return error.ValueUseActionOperandNotNamed;
        },
    };
    const owned = try transaction.selector.allocator.dupe(u8, source);
    errdefer transaction.selector.allocator.free(owned);
    try transaction.selector.machine.owned_labels.append(transaction.selector.allocator, owned);
    return owned;
}
