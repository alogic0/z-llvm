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

pub fn prepare(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .sealed) return error.ValueUsePrepareBeforeSeal;
    errdefer Authority.rollbackInternal(Authority, transaction);

    for (transaction.requests[0..transaction.request_count], 0..) |request, index| {
        if (request.prepared_action != null and request.prepared_action.? == .switch_compare_chain and
            !transaction.switch_boundary_applied[index])
        {
            return error.ValueUseSwitchBoundaryRequired;
        }
    }

    const saved_preserve = transaction.selector.preserve_current_position_values;
    transaction.selector.preserve_current_position_values = true;
    defer transaction.selector.preserve_current_position_values = saved_preserve;

    try materializeEarlyPlans(Authority, transaction);
    var nodes = transaction.write_nodes;
    for (transaction.requests[0..transaction.request_count], 0..) |*request, request_index_usize| {
        if (request.destination == .prepared_source) continue;
        if (request.destination == .prepared_view and request.prepared_action.? != .emit_copy_to) continue;
        if (request.form != .pointer and request.form != .stack_object_address) continue;
        const request_index: u8 = @intCast(request_index_usize);
        const current = switch (request.source) {
            .named => (Authority.validateRequestAt(Authority, transaction, request_index) catch |err| {
                Authority.noteRequestBoundaryError(Authority, transaction, request_index, err);
                return err;
            }) orelse continue,
            .int, .null_value, .unsupported => continue,
        };
        if (current == .stack_i32_ptr or current == .stack_scalar or current == .stack128 or current == .stack_i32_array) {
            nodes[@backingInt(PhysicalNode.rcx)] = true;
            if (current == .stack_i32_ptr and current.stack_i32_ptr.index != null)
                nodes[@backingInt(PhysicalNode.r8)] = true;
        }
    }
    for (transaction.early_plans) |plan| {
        if (plan.destination) |reg| nodes[@backingInt(Types.PhysicalNode.fromArgReg(reg))] = false;
    }
    for (nodes, 0..) |needed, index| {
        if (!needed) continue;
        try clobberPhysicalNode(transaction.selector, @fromBackingInt(@intCast(index)));
    }
    transaction.request_phase = .prepared;
}
pub fn materializeAll(comptime Authority: type, transaction: anytype) !void {
    try Authority.requireActive(Authority, transaction);
    if (transaction.request_phase != .prepared) return error.ValueUseMaterializeBeforePrepare;
    transaction.request_phase = .materializing;
    errdefer Authority.rollbackInternal(Authority, transaction);
    // Complete every mutation-producing fixed materialization first.
    for (transaction.requests[0..transaction.request_count], 0..) |*request, index| {
        if (request.destination == .prepared_source or request.destination == .prepared_view) continue;
        if (transaction.early_home_valid[index]) {
            try Authority.validateEarlyHome(Authority, transaction, @intCast(index));
            continue;
        }
        try materializeRequest(Authority, transaction, @intCast(index), request);
    }
    // Only now expose source-derived views from canonical current state.
    for (transaction.requests[0..transaction.request_count], 0..) |*request, index| {
        if (request.destination != .prepared_source and request.destination != .prepared_view) continue;
        transaction.prepared_views[index] = try buildPreparedRecord(Authority, transaction, @intCast(index));
        transaction.prepared_view_valid[index] = true;
    }
    transaction.request_phase = .materialized;
    if (transaction.call_action) |*action| {
        transaction.request_phase = .views_exposed;
        try Authority.executeAttachedCallAction(Authority, transaction, action);
        transaction.call_action_executed = true;
    }
}
fn registeredOperandCurrent(comptime Authority: type, transaction: anytype, handle: RequestHandle) !ValueLoc {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    return (try Authority.validateRequestAt(Authority, transaction, index)) orelse {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUseUnsupportedSource;
    };
}
fn registeredOperandView(
    comptime Authority: type,
    transaction: anytype,
    handle: RequestHandle,
) !*const PreparedView {
    const index = try Authority.validateRegisteredOperandHandle(Authority, transaction, handle);
    if (!transaction.prepared_view_valid[index]) {
        Authority.recordRequestFailure(Authority, transaction, index);
        return error.ValueUsePreparedViewMissing;
    }
    return &transaction.prepared_views[index].view;
}
pub fn materializeEarlyPlans(comptime Authority: type, transaction: anytype) !void {
    for (transaction.ordered_operands[0..transaction.ordered_operand_count]) |ordered| {
        if (ordered.phase != .safe_early) continue;
        const index = ordered.request_index;
        materializeEarlyPlan(Authority, transaction, index) catch |err| {
            Authority.noteRequestBoundaryError(Authority, transaction, index, err);
            return err;
        };
    }
}
fn materializeEarlyPlan(comptime Authority: type, transaction: anytype, index: u8) !void {
    const plan = transaction.early_plans[index];
    const destination_reg = plan.destination orelse return;
    if (!selector_state.scratchRegIsProvenFree(transaction.selector, destination_reg))
        return error.ValueUseEarlyDestinationNoLongerFree;
    const request = &transaction.requests[index];
    switch (request.source) {
        .named => {},
        .int, .null_value, .unsupported => return error.ValueUseEarlySourceNotNamed,
    }
    const binding = requestSourceBinding(transaction, index) orelse
        return if (transaction.lifetime_context.forward_snapshots[index] != null)
            error.ValueUseForwardPlanStale
        else
            error.ValueUseUnresolvedSource;
    const current = (try Authority.validateRequestAt(Authority, transaction, index)) orelse
        return error.ValueUseUnsupportedSource;
    if (!earlyCopyIsFlagsPreserving(current, request.form))
        return error.ValueUseEarlyMaterializationNotFlagsPreserving;

    const instruction_start = transaction.selector.machine.instructions.items.len;
    const destination: Destination = switch (request.form) {
        .gpr32 => .{ .gpr32 = destination_reg },
        .gpr64, .pointer => .{ .gpr64 = destination_reg },
        else => return error.ValueUseEarlyMaterializationNotFlagsPreserving,
    };
    try materializeRequestFromLoc(Authority, transaction, request, current, destination);
    for (transaction.selector.machine.instructions.items[instruction_start..]) |instruction| {
        if (eflags.instructionEffect(instruction) != .preserve)
            return error.ValueUseEarlyMaterializationClobbersEflags;
    }
    transaction.early_homes[index] = .{
        .loc = switch (request.form) {
            .gpr32 => .{ .scratch32 = destination_reg },
            .gpr64, .pointer => .{ .scratch64 = destination_reg },
            else => unreachable,
        },
        .source_vreg = binding.vreg,
    };
    transaction.early_home_valid[index] = true;
}
pub fn materializeRequest(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    request: *const StoredRequest,
) !void {
    return materializeRequestAtUnchecked(Authority, transaction, index, request) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
fn materializeRequestAtUnchecked(
    comptime Authority: type,
    transaction: anytype,
    index: u8,
    request: *const StoredRequest,
) !void {
    const current = switch (request.source) {
        .named => (try Authority.validateRequestAt(Authority, transaction, index)) orelse
            return error.ValueUseUnsupportedSource,
        .null_value => {
            try materializeNull(transaction.selector, request.destination);
            return;
        },
        .int, .unsupported => return error.ValueUseUnsupportedSource,
    };
    try materializeRequestFromLoc(Authority, transaction, request, current, request.destination);
}
fn materializeRequestUnchecked(comptime Authority: type, transaction: anytype, request: *const StoredRequest) !void {
    const current = switch (request.source) {
        .named => |*name| blk: {
            // Deliberately resolve after all preparation/spill mutations.
            const binding = transaction.selector.values.get(name.slice()) orelse return error.ValueUseUnresolvedSource;
            try selector_state.validateAddressDependenciesForUse(transaction.selector, name.slice());
            const current = try resolveNamedCurrent(Authority, transaction, name.slice());
            try validateBindingCompatibility(binding, request, current);
            break :blk current;
        },
        .null_value => {
            try materializeNull(transaction.selector, request.destination);
            return;
        },
        .int => return error.ValueUseUnsupportedSource,
        .unsupported => return error.ValueUseUnsupportedSource,
    };
    try materializeRequestFromLoc(Authority, transaction, request, current, request.destination);
}
fn materializeRequestFromLoc(
    comptime _: type,
    transaction: anytype,
    request: *const StoredRequest,
    current: ValueLoc,
    destination: Destination,
) !void {
    try validateSourceView(current, request.form);
    switch (request.form) {
        .gpr32 => try materializeScalar32(transaction.selector, current, destination),
        .gpr64 => try materializeScalar64(transaction.selector, current, destination),
        .pointer, .stack_object_address => try materializePointer(transaction.selector, current, destination),
        .stack_f32_pair_byte_address,
        .branch_condition,
        .switch_condition,
        .memcpy_pointer,
        .memcpy_length,
        .load_address,
        .scratch_compare_operand,
        .current_home_eq_zero_operand,
        .setcc_eax_compare_operand,
        .current_home_sign_bit_operand,
        .i128_icmp_pair_operand,
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        => return error.ValueUsePreparedActionRequired,
        .pair_low_high, .pair_high_low => try materializePair(transaction.selector, current, request.form, destination),
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
pub fn resolveNamedCurrent(comptime _: type, transaction: anytype, name: []const u8) !ValueLoc {
    return selector_state.resolveValue(transaction.selector, .{ .named = name }) orelse
        error.ValueUseUnresolvedSource;
}

fn requestSourceBinding(transaction: anytype, index: u8) ?ValueBinding {
    const request = &transaction.requests[index];
    const name = switch (request.source) {
        .named => |*identity| identity.slice(),
        .int, .null_value, .unsupported => return null,
    };
    if (transaction.selector.values.get(name)) |binding| return binding;
    const snapshot = transaction.lifetime_context.forward_snapshots[index] orelse return null;
    return .{
        .vreg = snapshot.virtualReg(),
        .loc = switch (snapshot.assignment) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .spill => |spill_index| .{
                .spill64 = selector_state.spillFrameIndexMaybe(spill_index) orelse return null,
            },
        },
    };
}
pub fn buildPreparedRecord(comptime Authority: type, transaction: anytype, index: u8) !PreparedRecord {
    return buildPreparedRecordUnchecked(Authority, transaction, index) catch |err| {
        Authority.noteRequestBoundaryError(Authority, transaction, index, err);
        return err;
    };
}
fn buildPreparedRecordUnchecked(comptime Authority: type, transaction: anytype, index: u8) !PreparedRecord {
    const request = &transaction.requests[index];
    if (request.destination != .prepared_source and request.destination != .prepared_view)
        return error.ValueUsePreparedViewMissing;
    switch (request.source) {
        .named => {},
        .int => |value| {
            const action = request.prepared_action orelse
                return error.ValueUsePreparedViewUnsupported;
            if (request.form == .accumulator_scalar_cast_operand and
                action == .accumulator_scalar_cast and
                action.accumulator_scalar_cast.immediate != null and
                action.accumulator_scalar_cast.immediate.? == value)
            {
                return .{
                    .view = .{ .accumulator_scalar_cast = {} },
                    .source_vreg = .{
                        .index = std.math.maxInt(usize),
                        .class = if (request.expected.ty.int <= 32) .gpr32 else .gpr64,
                        .bits = request.expected.ty.int,
                    },
                    .canonical_source_loc = if (request.expected.ty.int <= 32) .eax else .rax,
                };
            }
            if (request.form != .switch_condition or action != .switch_compare_chain)
                return error.ValueUsePreparedViewUnsupported;
            try validateExpectedType(request.expected, request.form);
            const immediate = std.math.cast(i32, value) orelse
                return error.ValueUseSwitchImmediateOutOfRange;
            return .{
                .view = .{ .condition = .{ .immediate = immediate } },
                .source_vreg = .{
                    .index = std.math.maxInt(usize),
                    .class = .gpr32,
                    .bits = request.expected.ty.int,
                },
                .canonical_source_loc = .eax,
            };
        },
        else => return error.ValueUsePreparedViewUnsupported,
    }
    if (transaction.lifetime_context.pins[index]) |pin| {
        if (pin.call_final_use != null)
            _ = try Authority.validateRequestAt(Authority, transaction, index);
    }
    const binding = requestSourceBinding(transaction, index) orelse
        return if (transaction.lifetime_context.forward_snapshots[index] != null)
            error.ValueUseForwardPlanStale
        else
            error.ValueUseUnresolvedSource;
    const current = (try Authority.validateRequestAt(Authority, transaction, index)) orelse
        return error.ValueUsePreparedViewUnsupported;
    const prepared_loc = if (transaction.early_home_valid[index]) blk: {
        try Authority.validateEarlyHome(Authority, transaction, index);
        break :blk transaction.early_homes[index].loc;
    } else current;
    return .{
        .view = try preparedViewFromLoc(Authority, transaction, request, prepared_loc),
        .source_vreg = binding.vreg,
        .canonical_source_loc = current,
    };
}
pub fn preparedViewFromLoc(
    comptime Authority: type,
    transaction: anytype,
    request: *const Types.StoredRequest,
    loc: ValueLoc,
) !Types.PreparedView {
    try validateExpectedType(request.expected, request.form);
    try validateSourceView(loc, request.form);
    return switch (request.form) {
        .gpr32, .gpr64 => preparedScalarView(loc),
        .pointer, .load_address => preparedPointerView(Authority, transaction, request, loc),
        .stack_f32_pair_byte_address => preparedStackF32PairAddressView(loc),
        .stack_object_address => preparedStackObjectView(loc),
        .pair_low_high, .pair_high_low => preparedPairView(loc, request.form),
        .branch_condition, .switch_condition => preparedConditionView(loc),
        .memcpy_pointer, .memcpy_length => preparedMemcpyScalarView(loc),
        .scratch_compare_operand => preparedScratchCompareView(loc, request.expected.ty),
        .current_home_eq_zero_operand => .{ .current_home_eq_zero = .{
            .bits = request.expected.ty.int,
        } },
        .setcc_eax_compare_operand => .{ .setcc_eax_compare = .{
            .bits = request.expected.ty.int,
        } },
        .current_home_sign_bit_operand => .{ .current_home_sign_bit = .{
            .bits = request.expected.ty.int,
        } },
        .i128_icmp_pair_operand => .{ .i128_icmp_pair = {} },
        .pair_low_scalar_cast_operand => .{ .pair_low_scalar_cast = {} },
        .accumulator_scalar_cast_operand => .{ .accumulator_scalar_cast = {} },
        .sign_extend_scratch_operand => .{ .sign_extend_scratch = {} },
        .immediate_rhs_scalar_operand => .{ .immediate_rhs_scalar = {} },
        .immediate_lhs_scalar_operand => .{ .immediate_lhs_scalar = {} },
        .named_scalar_operand => preparedScalarView(loc),
        .stack_argument => error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => error.ValueUseNewPairOwnershipUnsupported,
    };
}
pub fn preparedMemcpyScalarView(loc: ValueLoc) !Types.PreparedView {
    return switch (loc) {
        .stack128, .stack_i32_array => preparedStackObjectView(loc),
        .arg64, .scratch64, .rax, .spill64 => preparedScalarView(loc),
        .arg128, .scratch128 => |pair| .{
            .register = .{ .register = .{ .gpr64 = pair.lo }, .bits = 64 },
        },
        else => error.ValueUseSourceViewMismatch,
    };
}
pub fn preparedScratchCompareView(
    loc: ValueLoc,
    operand_ty: ir.Type,
) !Types.PreparedView {
    const bits: u16 = switch (operand_ty) {
        .int => |value| value,
        .ptr => 64,
        else => return error.ValueUseTypeMismatch,
    };
    return switch (loc) {
        .arg128, .scratch128 => |pair| .{ .register = .{
            .register = if (bits <= 32)
                .{ .gpr32 = pair.lo }
            else
                .{ .gpr64 = pair.lo },
            .bits = if (bits <= 32) 32 else 64,
        } },
        else => preparedScalarView(loc),
    };
}
pub fn preparedConditionView(loc: ValueLoc) !Types.PreparedView {
    return .{ .condition = switch (loc) {
        .eax => .eax,
        .rax => .rax_low32,
        .arg32, .scratch32 => |reg| .{ .register32 = reg },
        .arg64, .scratch64 => |reg| .{ .register64_low32 = reg },
        .arg128, .scratch128 => |pair| .{ .pair_low32 = pair.lo },
        .spill64 => |frame_index| .{ .spill_low32 = frame_index },
        else => return error.ValueUseSourceViewMismatch,
    } };
}
pub fn preparedStackF32PairAddressView(loc: ValueLoc) !Types.PreparedView {
    return switch (loc) {
        .stack_f32_pair_ptr => |ptr| .{ .stack_f32_pair_address = .{
            .object_base_disp = ptr.object_base_disp,
            .disp = ptr.disp,
        } },
        else => error.ValueUseSourceViewMismatch,
    };
}
pub fn preparedScalarView(loc: ValueLoc) !Types.PreparedView {
    return switch (loc) {
        .arg32, .scratch32 => |reg| .{ .register = .{ .register = .{ .gpr32 = reg }, .bits = 32 } },
        .arg64, .scratch64 => |reg| .{ .register = .{ .register = .{ .gpr64 = reg }, .bits = 64 } },
        .eax => .{ .register = .{ .register = .eax, .bits = 32 } },
        .rax => .{ .register = .{ .register = .rax, .bits = 64 } },
        .spill64 => |frame_index| .{ .spill = .{ .frame_index = frame_index, .bits = 64 } },
        else => error.ValueUseSourceViewMismatch,
    };
}
pub fn preparedPointerView(
    comptime Authority: type,
    transaction: anytype,
    request: *const Types.StoredRequest,
    loc: ValueLoc,
) !Types.PreparedView {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => preparedScalarView(loc),
        .stack_scalar, .stack128, .stack_i32_array => preparedStackObjectView(loc),
        .stack_i32_ptr => |ptr| .{ .address_descriptor = try preparedAddressDescriptor(Authority, transaction, request, ptr) },
        .readonly_table_ptr => |ptr| .{ .table_pointer = .{
            .storage = switch (ptr.storage) {
                .reg => |reg| .{ .register = reg },
                .spill => |frame_index| .{ .spill = frame_index },
            },
            .symbol = try Types.PreparedIdentity.init(ptr.symbol),
            .shape = ptr.shape,
            .offset = ptr.offset,
        } },
        else => error.ValueUseUnsupportedAddressForm,
    };
}
pub fn preparedStackObjectView(loc: ValueLoc) !Types.PreparedView {
    return switch (loc) {
        .stack_scalar => |stack| .{ .stack_object = .{ .scalar = stack } },
        .stack128 => |disp| .{ .stack_object = .{ .integer128 = disp } },
        .stack_i32_array => |array| .{ .stack_object = .{ .integer32_array = array } },
        else => error.ValueUseSourceViewMismatch,
    };
}
fn preparedAddressDescriptor(
    comptime Authority: type,
    transaction: anytype,
    request: *const Types.StoredRequest,
    ptr: selector_types.StackPtrLoc,
) !Types.PreparedAddressDescriptor {
    const owner_name = switch (request.source) {
        .named => |*name| name.slice(),
        else => return error.ValueUsePreparedViewUnsupported,
    };
    var result = Types.PreparedAddressDescriptor{ .disp = ptr.disp };
    if (ptr.index) |index| {
        const owner = transaction.selector.address_dependencies.ownerNamed(owner_name) orelse
            return error.AddressDependencyMissingOwner;
        try requireDependencyRole(owner, index.name, .index);
        result.index = try preparedAddressComponent(Authority, transaction, index.name, .index);
        if (index.addend_name) |addend_name| {
            try requireDependencyRole(owner, addend_name, .addend);
            result.addend = try preparedAddressComponent(Authority, transaction, addend_name, .addend);
        }
    }
    return result;
}
fn requireDependencyRole(
    owner: AddressDependencyDomain.OwnerView,
    name: []const u8,
    role: AddressDependencyDomain.Role,
) !void {
    for (owner.dependencies[0..owner.dependency_count]) |dependency| {
        if (dependency.role == role and std.mem.eql(u8, dependency.name, name)) return;
    }
    return error.AddressDependencyMissingIdentity;
}
fn preparedAddressComponent(
    comptime Authority: type,
    transaction: anytype,
    name: []const u8,
    role: AddressDependencyDomain.Role,
) !Types.PreparedAddressComponent {
    const current = try resolveNamedCurrent(Authority, transaction, name);
    const binding = transaction.selector.values.get(name) orelse return error.ValueUseUnresolvedSource;
    return .{
        .identity = try Types.PreparedIdentity.init(name),
        .role = role,
        .home = try preparedScalarHome(current),
        .vreg = binding.vreg,
    };
}
fn preparedScalarHome(loc: ValueLoc) !Types.PreparedScalarHome {
    return switch (loc) {
        .arg32, .scratch32 => |reg| .{ .register = .{ .gpr32 = reg } },
        .arg64, .scratch64 => |reg| .{ .register = .{ .gpr64 = reg } },
        .eax => .{ .register = .eax },
        .rax => .{ .register = .rax },
        .spill64 => |frame_index| .{ .spill = frame_index },
        else => error.ValueUseSourceViewMismatch,
    };
}
pub fn preparedPairView(
    loc: ValueLoc,
    form: Types.UseForm,
) !Types.PreparedView {
    const low: Types.PreparedPairLimb = switch (loc) {
        .arg128, .scratch128 => |pair| .{ .register = pair.lo },
        .spill128 => |pair| .{ .spill = pair.lo },
        else => return error.ValueUseSourceViewMismatch,
    };
    const high: Types.PreparedPairLimb = switch (loc) {
        .arg128, .scratch128 => |pair| .{ .register = pair.hi },
        .spill128 => |pair| .{ .spill = pair.hi },
        else => return error.ValueUseSourceViewMismatch,
    };
    return .{ .read_only_pair = if (form == .pair_low_high)
        .{ .first = low, .second = high }
    else
        .{ .first = high, .second = low } };
}
pub fn validatePreparedShape(
    view: *const Types.PreparedView,
    expected: Types.PreparedShape,
) !void {
    const matches = switch (expected) {
        .register_gpr32 => |reg| view.* == .register and
            view.register.register == .gpr32 and view.register.register.gpr32 == reg,
        .register_gpr64 => |reg| view.* == .register and
            view.register.register == .gpr64 and view.register.register.gpr64 == reg,
        .register_eax => view.* == .register and view.register.register == .eax,
        .register_rax => view.* == .register and view.register.register == .rax,
        .scalar_spill => |frame_index| view.* == .spill and view.spill.frame_index.eql(frame_index),
        .stack_scalar => |disp| view.* == .stack_object and
            view.stack_object == .scalar and view.stack_object.scalar.base_disp == disp,
        .stack_integer128 => |disp| view.* == .stack_object and
            view.stack_object == .integer128 and view.stack_object.integer128 == disp,
        .stack_i32_array => |array| view.* == .stack_object and
            view.stack_object == .integer32_array and std.meta.eql(view.stack_object.integer32_array, array),
        .address_descriptor => |shape| view.* == .address_descriptor and
            (view.address_descriptor.index != null) == shape.has_index and
            (view.address_descriptor.addend != null) == shape.has_addend,
        .table_register => |reg| view.* == .table_pointer and
            view.table_pointer.storage == .register and view.table_pointer.storage.register == reg,
        .table_spill => |frame_index| view.* == .table_pointer and
            view.table_pointer.storage == .spill and view.table_pointer.storage.spill.eql(frame_index),
        .pair_register => |pair| view.* == .read_only_pair and
            view.read_only_pair.first == .register and view.read_only_pair.second == .register and
            view.read_only_pair.first.register == pair.lo and view.read_only_pair.second.register == pair.hi,
        .pair_spill => |pair| view.* == .read_only_pair and
            view.read_only_pair.first == .spill and view.read_only_pair.second == .spill and
            view.read_only_pair.first.spill.eql(pair.lo) and view.read_only_pair.second.spill.eql(pair.hi),
    };
    if (!matches) return error.ValueUsePreparedShapeMismatch;
}
pub fn preparedViewLoc(view: *const Types.PreparedView) !ValueLoc {
    return switch (view.*) {
        .register => |value| switch (value.register) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |value| .{ .spill64 = value.frame_index },
        .stack_object => |object| switch (object) {
            .scalar => |stack| .{ .stack_scalar = stack },
            .integer128 => |disp| .{ .stack128 = disp },
            .integer32_array => |array| .{ .stack_i32_array = array },
        },
        .address_descriptor => |*address| .{ .stack_i32_ptr = .{
            .disp = address.disp,
            .index = if (address.index) |*index| .{
                .reg = .rcx,
                .name = index.identity.slice(),
                .addend_name = if (address.addend) |*addend| addend.identity.slice() else null,
            } else null,
        } },
        .stack_f32_pair_address => |address| .{ .stack_f32_pair_ptr = .{
            .object_base_disp = address.object_base_disp,
            .disp = address.disp,
        } },
        .table_pointer => |*table| .{ .readonly_table_ptr = .{
            .storage = switch (table.storage) {
                .register => |reg| .{ .reg = reg },
                .spill => |frame_index| .{ .spill = frame_index },
            },
            .symbol = table.symbol.slice(),
            .shape = table.shape,
            .offset = table.offset,
        } },
        .read_only_pair,
        .condition,
        .current_home_eq_zero,
        .setcc_eax_compare,
        .current_home_sign_bit,
        .i128_icmp_pair,
        .pair_low_scalar_cast,
        .accumulator_scalar_cast,
        .sign_extend_scratch,
        .immediate_rhs_scalar,
        .immediate_lhs_scalar,
        => error.ValueUsePreparedActionFormMismatch,
    };
}
pub fn preparedRecordEql(
    lhs: *const Types.PreparedRecord,
    rhs: *const Types.PreparedRecord,
) bool {
    return std.meta.eql(lhs.source_vreg, rhs.source_vreg) and
        std.meta.eql(lhs.canonical_source_loc, rhs.canonical_source_loc) and
        preparedViewEql(&lhs.view, &rhs.view);
}
fn preparedViewEql(
    lhs: *const Types.PreparedView,
    rhs: *const Types.PreparedView,
) bool {
    if (std.meta.activeTag(lhs.*) != std.meta.activeTag(rhs.*)) return false;
    return switch (lhs.*) {
        .register => |value| std.meta.eql(value, rhs.register),
        .spill => |value| std.meta.eql(value, rhs.spill),
        .stack_object => |*value| preparedStackObjectEql(value, &rhs.stack_object),
        .address_descriptor => |*value| preparedAddressDescriptorEql(value, &rhs.address_descriptor),
        .stack_f32_pair_address => |value| std.meta.eql(value, rhs.stack_f32_pair_address),
        .table_pointer => |*value| preparedTablePointerEql(value, &rhs.table_pointer),
        .read_only_pair => |value| std.meta.eql(value, rhs.read_only_pair),
        .condition => |value| std.meta.eql(value, rhs.condition),
        .current_home_eq_zero => |value| std.meta.eql(value, rhs.current_home_eq_zero),
        .setcc_eax_compare => |value| std.meta.eql(value, rhs.setcc_eax_compare),
        .current_home_sign_bit => |value| std.meta.eql(value, rhs.current_home_sign_bit),
        .i128_icmp_pair => true,
        .pair_low_scalar_cast => true,
        .accumulator_scalar_cast => true,
        .sign_extend_scratch => true,
        .immediate_rhs_scalar => true,
        .immediate_lhs_scalar => true,
    };
}
fn preparedStackObjectEql(
    lhs: *const Types.PreparedStackObject,
    rhs: *const Types.PreparedStackObject,
) bool {
    if (std.meta.activeTag(lhs.*) != std.meta.activeTag(rhs.*)) return false;
    return switch (lhs.*) {
        .scalar => |value| std.meta.eql(value, rhs.scalar),
        .integer128 => |value| value == rhs.integer128,
        .integer32_array => |value| std.meta.eql(value, rhs.integer32_array),
    };
}
fn preparedAddressDescriptorEql(
    lhs: *const Types.PreparedAddressDescriptor,
    rhs: *const Types.PreparedAddressDescriptor,
) bool {
    if (lhs.disp != rhs.disp or (lhs.index == null) != (rhs.index == null) or
        (lhs.addend == null) != (rhs.addend == null)) return false;
    if (lhs.index) |*component| {
        if (!preparedAddressComponentEql(component, &rhs.index.?)) return false;
    }
    if (lhs.addend) |*component| {
        if (!preparedAddressComponentEql(component, &rhs.addend.?)) return false;
    }
    return true;
}
fn preparedAddressComponentEql(
    lhs: *const Types.PreparedAddressComponent,
    rhs: *const Types.PreparedAddressComponent,
) bool {
    return lhs.identity.eql(&rhs.identity) and lhs.role == rhs.role and
        std.meta.eql(lhs.home, rhs.home) and std.meta.eql(lhs.vreg, rhs.vreg);
}
fn preparedTablePointerEql(
    lhs: *const Types.PreparedTablePointer,
    rhs: *const Types.PreparedTablePointer,
) bool {
    return std.meta.eql(lhs.storage, rhs.storage) and lhs.symbol.eql(&rhs.symbol) and
        lhs.shape == rhs.shape and lhs.offset == rhs.offset;
}
pub fn clobberPhysicalNode(selector: *ComposedBlockSelector, node: Types.PhysicalNode) !void {
    if (node.argReg()) |reg| {
        try selector_state.clobberArgReg(selector, reg);
    } else {
        try selector_state.clobberAccumulator(selector);
        selector.accumulator_domain.invalidate();
    }
}
pub fn materializeScalar32(selector: *ComposedBlockSelector, current: ValueLoc, destination: Types.Destination) !void {
    switch (destination) {
        .gpr32 => |reg| try selector_state.materializeLocIntoLoc(selector, current, .{ .scratch32 = reg }),
        .eax => switch (current) {
            .arg32, .scratch32, .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = frame_index }),
            .eax, .rax => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        else => return error.ValueUseDestinationFormMismatch,
    }
}
pub fn materializeScalar64(selector: *ComposedBlockSelector, current: ValueLoc, destination: Types.Destination) !void {
    switch (destination) {
        .gpr64 => |reg| try selector_state.materializeLocIntoLoc(selector, current, .{ .scratch64 = reg }),
        .rax => switch (current) {
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index }),
            .rax => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        else => return error.ValueUseDestinationFormMismatch,
    }
}
pub fn materializeByteAddressPointer(selector: *ComposedBlockSelector, current: ValueLoc, destination: ArgReg) !void {
    switch (current) {
        .stack_f32_pair_ptr => try selector_state.materializeLocIntoLoc(
            selector,
            current,
            .{ .scratch64 = destination },
        ),
        else => try materializePointer(selector, current, .{ .gpr64 = destination }),
    }
}
pub fn materializePointer(selector: *ComposedBlockSelector, current: ValueLoc, destination: Types.Destination) !void {
    switch (current) {
        .arg64, .scratch64, .rax, .spill64 => try materializeScalar64(selector, current, destination),
        .readonly_table_ptr => |ptr| switch (destination) {
            .gpr64 => |reg| try selector_state.materializeLocIntoLoc(selector, .{ .readonly_table_ptr = ptr }, .{ .scratch64 = reg }),
            .rax => switch (ptr.storage) {
                .reg => |reg| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg }),
                .spill => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index }),
            },
            else => return error.ValueUseDestinationFormMismatch,
        },
        .stack_scalar => |stack| try materializeStackAddress(selector, stack.base_disp, null, destination),
        .stack128 => |disp| try materializeStackAddress(selector, disp, null, destination),
        .stack_i32_array => |array| try materializeStackAddress(selector, array.base_disp, null, destination),
        .stack_i32_ptr => |ptr| try materializeStackAddress(selector, ptr.disp, ptr, destination),
        else => return error.ValueUseUnsupportedAddressForm,
    }
}
pub fn materializeStackAddress(
    selector: *ComposedBlockSelector,
    disp: u32,
    stack_ptr: ?selector_types.StackPtrLoc,
    destination: Types.Destination,
) !void {
    if (stack_ptr) |ptr| {
        if (ptr.index) |index| {
            try selector_state.emitValueIntoScratch(selector, .{ .named = index.name }, .rcx, 64);
            if (index.addend_name) |addend_name| {
                try selector_state.emitValueIntoScratch(selector, .{ .named = addend_name }, .r8, 64);
                try selector_state.emitEflagsInstruction(selector, .add_r8_rcx, .write);
            }
            try selector_state.emitEflagsInstruction(selector, .{ .shl_rcx_imm6 = 2 }, .write);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .r8 });
            try selector_state.emitEflagsInstruction(selector, .add_r8_rcx, .write);
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
        }
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
    }
    if (disp != 0) {
        const immediate = std.math.cast(i32, disp) orelse return error.ValueUseUnsupportedAddressForm;
        try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = immediate } }, .write);
    }
    switch (destination) {
        .gpr64 => |reg| if (reg != .rcx) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = .rcx } }),
        .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rcx }),
        else => return error.ValueUseDestinationFormMismatch,
    }
}
pub fn materializePair(
    selector: *ComposedBlockSelector,
    current: ValueLoc,
    form: Types.UseForm,
    destination: Types.Destination,
) !void {
    const pair = switch (destination) {
        .pair => |pair| pair,
        else => return error.ValueUseDestinationFormMismatch,
    };
    if (form == .pair_low_high) {
        try materializePairLimb(selector, current, false, pair.lo);
        try materializePairLimb(selector, current, true, pair.hi);
    } else {
        try materializePairLimb(selector, current, true, pair.lo);
        try materializePairLimb(selector, current, false, pair.hi);
    }
}
pub fn materializePairLimb(selector: *ComposedBlockSelector, current: ValueLoc, high: bool, destination: ArgReg) !void {
    switch (current) {
        .arg128, .scratch128 => |source| {
            const reg = if (high) source.hi else source.lo;
            if (reg != destination) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = destination, .src = reg } });
        },
        .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{
            .reg = destination,
            .frame_index = if (high) spill.hi else spill.lo,
        } }),
        else => return error.ValueUseSourceViewMismatch,
    }
}
pub fn materializeNull(selector: *ComposedBlockSelector, destination: Types.Destination) !void {
    switch (destination) {
        .gpr64 => |reg| try selector.machine.instructions.append(selector.allocator, switch (reg) {
            .rdi => .{ .mov_imm_rdi = 0 },
            .rsi => .{ .mov_imm_rsi = 0 },
            .rdx => .{ .mov_imm_rdx = 0 },
            .rcx => .{ .mov_imm_rcx = 0 },
            .r8 => .{ .mov_imm_r8 = 0 },
            .r9 => .{ .mov_imm_r9 = 0 },
        }),
        .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = 0 }),
        else => return error.ValueUseDestinationFormMismatch,
    }
}
fn validateBindingCompatibility(
    binding: ValueBinding,
    request: *const Types.StoredRequest,
    current: ValueLoc,
) !void {
    if (request.form == .scratch_compare_operand) {
        try validateScratchCompareBinding(binding, request.expected, current);
        return;
    }
    if (request.form == .current_home_eq_zero_operand) {
        // The canonical post-preamble home is the authority. Resolution and
        // liveness happen now; width/location classification is intentionally
        // deferred until the action refreshes after accumulator preservation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .setcc_eax_compare_operand) {
        // The action re-resolves after its live-accumulator preamble. Only
        // semantic typing is stable at seal; canonical width/home admission
        // is request-scoped and happens after that relocation.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .current_home_sign_bit_operand) {
        // Width and canonical-home admission occur after both action-owned
        // preservation phases. Seal validates only the stable semantic type.
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form == .i128_icmp_pair_operand) {
        // The pair wrapper owns the strict post-preamble home fence. Seal
        // checks only the stable semantic i128 request and its binding width.
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseI128PairWidthUnsupported;
        return;
    }
    if (request.form == .pair_low_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr128 or binding.vreg.bits < 128)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .accumulator_scalar_cast_operand) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .sign_extend_scratch_operand) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.class != .gpr32 or binding.vreg.bits < 32)
            return error.ValueUseScalarCastWidthUnsupported;
        return;
    }
    if (request.form == .immediate_rhs_scalar_operand or
        request.form == .immediate_lhs_scalar_operand or
        request.form == .named_scalar_operand)
    {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        const valid_class = if (bits <= 32)
            binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64
        else
            binding.vreg.class == .gpr64;
        if (!valid_class or binding.vreg.bits < bits)
            return if (request.form == .named_scalar_operand)
                error.ValueUseNamedScalarWidthUnsupported
            else
                error.ValueUseImmediateScalarWidthUnsupported;
        return;
    }
    if (request.form == .load_address) {
        try validateExpectedType(request.expected, request.form);
        const action = request.prepared_action orelse
            return error.ValueUsePreparedActionMissing;
        switch (action) {
            .load_scalar => |load| switch (load.kind) {
                .ordinary => try validateOrdinaryLoadHome(binding, current, load.bits, false, load.is_ptr),
                .readonly_pointer => try validateReadOnlyPointerLoadHome(binding, current),
            },
            .load_readonly_pair => try validateReadOnlyPointerLoadHome(binding, current),
            .load_stack_i128_alias => try validateOrdinaryLoadHome(binding, current, 128, true, false),
            .load_readonly_table_i16 => try validateReadOnlyTableLoadHome(binding, current),
            else => return error.ValueUsePreparedActionFormMismatch,
        }
        return;
    }
    if (request.form == .memcpy_pointer or request.form == .memcpy_length) {
        try validateExpectedType(request.expected, request.form);
        if (request.form == .memcpy_pointer and binding.vreg.class == .stack_object) {
            if (request.prepared_action) |action| if (action == .inline_memset and action.inline_memset.length == null) {
                const extent: ?u64 = switch (current) {
                    .stack128 => 16,
                    .stack_i32_array => |array| @as(u64, array.len) * 4,
                    else => null,
                };
                if (extent) |bytes| if (action.inline_memset.length_immediate <= bytes) return;
            };
        }
        if (binding.vreg.bits < 64) return if (request.form == .memcpy_pointer)
            error.ValueUseMemcpyPointerWidthMismatch
        else
            error.ValueUseMemcpyLengthWidthMismatch;
        const accepted_class = binding.vreg.class == .gpr64 or binding.vreg.class == .gpr128;
        const accepted_home = switch (current) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => true,
            else => false,
        };
        if (!accepted_class or !accepted_home)
            return if (request.form == .memcpy_pointer)
                error.ValueUseMemcpyPointerHomeUnsupported
            else
                error.ValueUseMemcpyLengthHomeUnsupported;
        return;
    }
    if (request.form == .branch_condition) {
        try validateExpectedType(request.expected, request.form);
        if (binding.vreg.bits < 1) return error.ValueUseBranchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            else => false,
        };
        if (!accepted) return error.ValueUseBranchConditionHomeUnsupported;
        return;
    }
    if (request.form == .switch_condition) {
        try validateExpectedType(request.expected, request.form);
        const bits = request.expected.ty.int;
        if (binding.vreg.bits < bits) return error.ValueUseSwitchConditionWidthMismatch;
        const accepted = switch (current) {
            .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
            .arg64, .scratch64, .rax, .spill64 => binding.vreg.class == .gpr32 or binding.vreg.class == .gpr64,
            .arg128, .scratch128 => binding.vreg.class == .gpr128,
            else => false,
        };
        if (!accepted) return error.ValueUseSwitchConditionHomeUnsupported;
        return;
    }
    if (binding.vreg.class == request.expected.register_class) {
        try validateExpectedType(request.expected, request.form);
        return;
    }
    if (request.form != .gpr32 or request.expected.register_class != .gpr32 or
        request.expected.ty != .int or request.expected.ty.int == 0 or
        request.expected.ty.int > 32 or binding.vreg.class != .gpr64 or
        binding.vreg.bits < request.expected.ty.int or !hasLow32View(current))
    {
        return error.ValueUseRegisterClassMismatch;
    }
    try validateExpectedType(request.expected, request.form);
}
fn validateScratchCompareBinding(
    binding: ValueBinding,
    expected: Types.Expected,
    current: ValueLoc,
) !void {
    try validateExpectedType(expected, .scratch_compare_operand);
    const bits: u16 = switch (expected.ty) {
        .int => |value| value,
        .ptr => 64,
        else => unreachable,
    };
    if (binding.vreg.bits < bits) return error.ValueUseScratchCompareWidthMismatch;
    const accepted = if (bits <= 32) switch (current) {
        .eax, .arg32, .scratch32 => binding.vreg.class == .gpr32,
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr32 or
            binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    } else switch (current) {
        .rax, .arg64, .scratch64, .spill64 => binding.vreg.class == .gpr64,
        .arg128, .scratch128 => binding.vreg.class == .gpr128,
        else => false,
    };
    if (!accepted) return error.ValueUseScratchCompareHomeUnsupported;
}
fn validateOrdinaryLoadHome(
    binding: ValueBinding,
    current: ValueLoc,
    bits: u16,
    alias_i128: bool,
    is_ptr: bool,
) !void {
    switch (current) {
        .stack_scalar => |stack| {
            if (alias_i128 or binding.vreg.class != .stack_object or stack.kind != .integer or
                stack.bits != bits or (bits != 8 and bits != 64))
            {
                return error.ValueUseLoadOrdinaryStackWidth;
            }
        },
        .stack128 => {
            if (!alias_i128 or binding.vreg.class != .stack_object)
                return error.ValueUseLoadOrdinaryStackWidth;
        },
        .stack_i32_array => {
            if (alias_i128 or binding.vreg.class != .stack_object or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .stack_i32_ptr => {
            if (alias_i128 or binding.vreg.class != .stack_pointer or bits != 32)
                return error.ValueUseLoadOrdinaryStackArrayWidth;
        },
        .arg64, .scratch64, .rax, .spill64 => {
            if (alias_i128 or binding.vreg.class != .gpr64 or binding.vreg.bits < 64 or
                (!is_ptr and bits != 8 and bits != 16 and bits != 32 and bits != 64) or (is_ptr and bits != 64))
            {
                return error.ValueUseLoadOrdinaryPointerWidth;
            }
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    }
}
fn validateReadOnlyPointerLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .arg64, .scratch64, .spill64 => if (binding.vreg.class != .gpr64 or binding.vreg.bits < 64)
            return error.ValueUseLoadReadonlyPointerProvenance,
        else => return error.ValueUseLoadReadonlyPointerProvenance,
    }
}
fn validateReadOnlyTableLoadHome(binding: ValueBinding, current: ValueLoc) !void {
    switch (current) {
        .readonly_table_ptr => |ptr| {
            if (binding.vreg.class != .stack_pointer)
                return error.ValueUseLoadReadonlyTableType;
            if (!ptr.shape.allowsOffset(ptr.offset))
                return error.ValueUseLoadReadonlyTableOffset;
        },
        else => return error.ValueUseLoadReadonlyTableType,
    }
}
fn hasLow32View(loc: ValueLoc) bool {
    return switch (loc) {
        .arg64, .scratch64, .rax, .spill64 => true,
        else => false,
    };
}
fn validateExpectedType(expected: Types.Expected, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => if (expected.ty != .int or expected.ty.int == 0 or expected.ty.int > 32 or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .gpr64 => if (expected.ty != .int or expected.ty.int <= 32 or expected.ty.int > 64 or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .pointer => {
            if (expected.ty != .ptr or
                (expected.register_class != .gpr64 and expected.register_class != .stack_pointer) or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_f32_pair_byte_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_pointer or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .stack_object_address => {
            if (expected.ty != .ptr or
                expected.register_class != .stack_object or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .pair_low_high, .pair_high_low => if (!expected.ty.eql(.{ .int = 128 }) or expected.register_class != .gpr128)
            return error.ValueUseTypeMismatch,
        .branch_condition => if (!expected.ty.eql(.{ .int = 1 }) or expected.register_class != .gpr32)
            return error.ValueUseTypeMismatch,
        .switch_condition => if (expected.ty != .int or expected.ty.int == 0 or
            expected.ty.int > 32 or expected.register_class != .gpr32)
        {
            return error.ValueUseTypeMismatch;
        },
        .memcpy_pointer => {
            if (expected.ty != .ptr or expected.register_class != .gpr64 or
                expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
            {
                return error.ValueUseTypeMismatch;
            }
        },
        .memcpy_length => if (!expected.ty.eql(.{ .int = 64 }) or expected.register_class != .gpr64)
            return error.ValueUseTypeMismatch,
        .load_address => if (expected.ty != .ptr or expected.register_class != .stack_pointer or
            expected.pointer_address_space == null or expected.pointer_address_space.? != 0)
        {
            return error.ValueUseTypeMismatch;
        },
        .scratch_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            .ptr => {
                if (expected.register_class != .gpr64 or
                    expected.pointer_address_space == null or
                    expected.pointer_address_space.? != 0)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_eq_zero_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .setcc_eax_compare_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .current_home_sign_bit_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .i128_icmp_pair_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or
            expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .pair_low_scalar_cast_operand => if (!expected.ty.eql(.{ .int = 128 }) or
            expected.register_class != .gpr128 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .accumulator_scalar_cast_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .sign_extend_scratch_operand => if (!expected.ty.eql(.{ .int = 32 }) or
            expected.register_class != .gpr32 or expected.pointer_address_space != null)
        {
            return error.ValueUseTypeMismatch;
        },
        .immediate_rhs_scalar_operand, .immediate_lhs_scalar_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                {
                    return error.ValueUseTypeMismatch;
                }
            },
            else => return error.ValueUseTypeMismatch,
        },
        .named_scalar_operand => switch (expected.ty) {
            .int => |bits| {
                if (bits == 0 or bits > 64 or
                    expected.register_class != if (bits <= 32)
                        VirtualRegClass.gpr32
                    else
                        VirtualRegClass.gpr64)
                    return error.ValueUseTypeMismatch;
            },
            else => return error.ValueUseTypeMismatch,
        },
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
fn validateSourceView(loc: ValueLoc, form: Types.UseForm) !void {
    switch (form) {
        .gpr32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .gpr64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .pointer, .stack_object_address => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr => {},
            .stack_f32_pair_ptr, .stack128_value => return error.ValueUseUnsupportedAddressForm,
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .stack_f32_pair_byte_address => switch (loc) {
            .stack_f32_pair_ptr => {},
            else => return error.ValueUseSourceViewMismatch,
        },
        .pair_low_high, .pair_high_low => switch (loc) {
            .arg128, .scratch128, .spill128 => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseSourceViewMismatch,
        },
        .branch_condition => switch (loc) {
            .eax, .arg32, .scratch32, .spill64 => {},
            else => return error.ValueUseBranchConditionHomeUnsupported,
        },
        .switch_condition => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseSwitchConditionHomeUnsupported,
        },
        .memcpy_pointer, .memcpy_length => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .arg128, .scratch128 => {},
            .stack128, .stack_i32_array => if (form != .memcpy_pointer) return error.ValueUseSourceViewMismatch,
            else => return error.ValueUseSourceViewMismatch,
        },
        .load_address => switch (loc) {
            .arg64,
            .scratch64,
            .rax,
            .spill64,
            .stack_scalar,
            .stack128,
            .stack_i32_array,
            .stack_i32_ptr,
            .readonly_table_ptr,
            => {},
            .xmm => return error.ValueUseXmmUnsupported,
            .aggregate_sse => return error.ValueUseAggregateUnsupported,
            else => return error.ValueUseLoadAddressHomeUnsupported,
        },
        .scratch_compare_operand => switch (loc) {
            .eax,
            .rax,
            .arg32,
            .scratch32,
            .arg64,
            .scratch64,
            .arg128,
            .scratch128,
            .spill64,
            => {},
            else => return error.ValueUseScratchCompareHomeUnsupported,
        },
        // The action must inspect the canonical home only after the accepted
        // live-accumulator preamble. No home is admitted by this generic
        // validation layer.
        .current_home_eq_zero_operand => {},
        // Canonical admission occurs after the action-owned preamble. Pair
        // and spill128 homes are rejected there, preserving the O2-6 frontier.
        .setcc_eax_compare_operand => {},
        // The action owns both preservation phases and classifies the
        // canonical i32/i64 home only after re-resolution.
        .current_home_sign_bit_operand => {},
        // Strict pair-home admission follows the established preamble and
        // canonical refresh inside the two closed wrapper actions. Their
        // exact semantic classifiers fence the admitted spill128 view.
        .i128_icmp_pair_operand => {},
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        => {},
        .stack_argument => return error.ValueUseStackArgumentUnsupported,
        .new_pair_ownership => return error.ValueUseNewPairOwnershipUnsupported,
    }
}
fn earlyCopyIsFlagsPreserving(loc: ValueLoc, form: Types.UseForm) bool {
    return switch (form) {
        .gpr32 => switch (loc) {
            .arg32, .scratch32, .arg64, .scratch64, .eax, .rax, .spill64 => true,
            else => false,
        },
        .gpr64 => switch (loc) {
            .arg64, .scratch64, .rax, .spill64 => true,
            else => false,
        },
        .pointer => switch (loc) {
            .arg64, .scratch64, .rax, .spill64, .readonly_table_ptr => true,
            else => false,
        },
        .stack_f32_pair_byte_address,
        .stack_object_address,
        .pair_low_high,
        .pair_high_low,
        .branch_condition,
        .switch_condition,
        .memcpy_pointer,
        .memcpy_length,
        .load_address,
        .scratch_compare_operand,
        .current_home_eq_zero_operand,
        .setcc_eax_compare_operand,
        .current_home_sign_bit_operand,
        .i128_icmp_pair_operand,
        .pair_low_scalar_cast_operand,
        .accumulator_scalar_cast_operand,
        .sign_extend_scratch_operand,
        .immediate_rhs_scalar_operand,
        .immediate_lhs_scalar_operand,
        .named_scalar_operand,
        .stack_argument,
        .new_pair_ownership,
        => false,
    };
}
