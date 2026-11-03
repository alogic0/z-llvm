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

pub fn executeScalarLoad(
    comptime Authority: type,
    transaction: anytype,
    request_index: u8,
    view: *const Types.PreparedView,
    action: Types.ScalarLoadAction,
) !void {
    const session = if (transaction.accumulator_session) |*session| session else return error.ValueUseLoadAccumulatorSessionRequired;

    switch (action.kind) {
        .ordinary => {
            try prepareScalarLoadAccumulator(Authority, transaction, session);
            try refreshLoadPreparedOperand(Authority, transaction, request_index);
            try executeOrdinaryScalarLoad(
                Authority,
                transaction,
                &transaction.prepared_views[request_index].view,
                action.bits,
                action.is_ptr,
            );
        },
        .readonly_pointer => {
            const ptr_reg = try stageReadOnlyScalarLoadPointer(Authority, transaction, view);
            try prepareScalarLoadAccumulator(Authority, transaction, session);
            try refreshLoadPreparedOperand(Authority, transaction, request_index);
            try executeReadOnlyScalarLoad(Authority, transaction, ptr_reg, action.bits);
        },
    }
}
fn prepareScalarLoadAccumulator(
    comptime Authority: type,
    transaction: anytype,
    session: *AccumulatorDefinitionSession,
) !void {
    const displacement: selector_state.AccumulatorDisplacementPolicy = if (transaction.selector.stack_frame_bytes >= 24)
        .spill_live
    else
        .scratch_preferred;
    if (try session.prepare(.preserve, displacement)) |diagnostic| {
        transaction.action_diagnostic = diagnostic;
        return error.ValueUseActionDiagnostic;
    }
    try failLoadForTest(Authority, transaction, .after_preservation);
}
fn refreshLoadPreparedOperand(comptime Authority: type, transaction: anytype, request_index: u8) !void {
    if (!transaction.prepared_view_valid[request_index]) {
        Authority.recordRequestFailure(Authority, transaction, request_index);
        return error.ValueUsePreparedViewMissing;
    }
    transaction.prepared_views[request_index] = try Authority.materialization.buildPreparedRecord(Authority, transaction, request_index);
}
fn executeOrdinaryScalarLoad(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    bits: u16,
    is_ptr: bool,
) !void {
    switch (view.*) {
        .stack_object => |stack| switch (stack) {
            .scalar => |scalar| switch (bits) {
                8 => if (scalar.base_disp <= std.math.maxInt(u8))
                    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                        .load_stack_disp8_u8_eax = @intCast(scalar.base_disp),
                    })
                else
                    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                        .load_stack_disp32_u8_eax = scalar.base_disp,
                    }),
                64 => try appendPreparedLoadStackU64IntoRax(transaction.selector, scalar.base_disp),
                else => return error.ValueUseLoadOrdinaryStackWidth,
            },
            .integer32_array => |array| try appendPreparedLoadStackI32(
                Authority,
                transaction,
                .{ .disp = array.base_disp },
            ),
            .integer128 => return error.ValueUseLoadOrdinaryStackWidth,
        },
        .address_descriptor => |descriptor| try appendPreparedLoadStackI32(Authority, transaction, descriptor),
        .register => |prepared| {
            if ((!is_ptr and bits != 8 and bits != 16 and bits != 32 and bits != 64) or (is_ptr and bits != 64)) return error.ValueUseLoadOrdinaryPointerWidth;
            const reg = switch (prepared.register) {
                .gpr64 => |reg| reg,
                else => return error.ValueUseLoadOrdinaryPointerRejected,
            };
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (is_ptr or bits == 64)
                    .{ .load_arg_ptr_disp8_rax = .{ .reg = reg, .offset = 0 } }
                else if (bits == 8)
                    .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = reg, .offset = 0 } }
                else if (bits == 16)
                    .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = reg, .offset = 0 } }
                else
                    .{ .load_arg_ptr_eax = reg },
            );
        },
        .spill => |spill| {
            if (((!is_ptr and bits != 8 and bits != 16 and bits != 32 and bits != 64) or (is_ptr and bits != 64)) or spill.bits < 64) return error.ValueUseLoadOrdinaryPointerWidth;
            try materialization.materializeScalar64(
                transaction.selector,
                .{ .spill64 = spill.frame_index },
                .{ .gpr64 = .rcx },
            );
            try failLoadForTest(Authority, transaction, .after_pointer_staging);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (is_ptr or bits == 64)
                    .{ .load_arg_ptr_disp8_rax = .{ .reg = .rcx, .offset = 0 } }
                else if (bits == 8)
                    .{ .load_arg_ptr_disp8_u8_eax = .{ .reg = .rcx, .offset = 0 } }
                else if (bits == 16)
                    .{ .load_arg_ptr_disp8_u16_eax = .{ .reg = .rcx, .offset = 0 } }
                else
                    .{ .load_arg_ptr_eax = .rcx },
            );
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    }
}
fn appendPreparedLoadStackI32(
    comptime _: type,
    transaction: anytype,
    descriptor: Types.PreparedAddressDescriptor,
) !void {
    if (descriptor.index) |index| {
        try materialization.materializeScalar64(
            transaction.selector,
            preparedScalarHomeLoc(index.home),
            .{ .gpr64 = .rcx },
        );
        if (descriptor.addend) |addend| {
            try materialization.materializeScalar64(
                transaction.selector,
                preparedScalarHomeLoc(addend.home),
                .{ .gpr64 = .r8 },
            );
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
        }
        if (descriptor.disp <= std.math.maxInt(u8)) {
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_stack_rcx4_disp8_eax = @intCast(descriptor.disp),
            });
        } else {
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_stack_rcx4_disp32_eax = descriptor.disp,
            });
        }
    } else if (descriptor.disp <= std.math.maxInt(u8)) {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_stack_disp8_eax = @intCast(descriptor.disp),
        });
    } else {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_stack_disp32_eax = descriptor.disp,
        });
    }
}
fn appendPreparedLoadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{
            .load_stack_disp8_rax = @intCast(disp),
        });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{
            .load_stack_disp32_rax = disp,
        });
    }
}
fn preparedScalarHomeLoc(home: Types.PreparedScalarHome) ValueLoc {
    return switch (home) {
        .register => |reg| switch (reg) {
            .gpr32 => |value| .{ .scratch32 = value },
            .gpr64 => |value| .{ .scratch64 = value },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |frame_index| .{ .spill64 = frame_index },
    };
}
fn executeReadOnlyScalarLoad(
    comptime Authority: type,
    transaction: anytype,
    ptr_reg: ArgReg,
    bits: u16,
) !void {
    switch (bits) {
        8 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        16 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        32 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        56 => {
            const scratch: ArgReg = if (ptr_reg == .rcx) .r8 else .rcx;
            try selector_state.clobberArgReg(transaction.selector, scratch);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_u16_eax = .{ .reg = ptr_reg, .offset = 4 },
            });
            try failLoadForTest(Authority, transaction, .after_first_partial_load);
            try selector_state.emitEflagsInstruction(transaction.selector, .{ .shl_rax_imm6 = 32 }, .write);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_rax_to_arg = scratch,
            });
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_u8_eax = .{ .reg = ptr_reg, .offset = 6 },
            });
            try selector_state.emitEflagsInstruction(transaction.selector, .{ .shl_rax_imm6 = 48 }, .write);
            try selector_state.emitEflagsInstruction(transaction.selector, .{
                .binary_arg_rax = .{ .op = .@"or", .reg = scratch },
            }, .write);
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .mov_rax_to_arg = scratch,
            });
            try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
                .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 0 },
            });
            try selector_state.emitEflagsInstruction(transaction.selector, .{
                .binary_arg_rax = .{ .op = .@"or", .reg = scratch },
            }, .write);
        },
        64 => try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 },
        }),
        else => return error.ValueUseLoadReadonlyWidth,
    }
}
fn stageReadOnlyScalarLoadPointer(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
) !ArgReg {
    return materializePreparedLoadPointer(Authority, transaction, view, .rdi) catch |err|
        return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerSpill;
}
fn materializePreparedLoadPointer(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    spill_destination: ArgReg,
) !ArgReg {
    return switch (view.*) {
        .register => |prepared| switch (prepared.register) {
            .gpr64 => |reg| reg,
            else => error.ValueUseLoadReadonlyPointerProvenance,
        },
        .spill => |spill| blk: {
            if (spill.bits < 64) return error.ValueUseLoadReadonlyPointerProvenance;
            try materialization.materializeScalar64(
                transaction.selector,
                .{ .spill64 = spill.frame_index },
                .{ .gpr64 = spill_destination },
            );
            try failLoadForTest(Authority, transaction, .after_pointer_staging);
            break :blk spill_destination;
        },
        else => error.ValueUseLoadReadonlyPointerProvenance,
    };
}
pub fn executeReadOnlyPairLoad(
    comptime Authority: type,
    transaction: anytype,
    request_index: u8,
    view: *const Types.PreparedView,
    action: *const Types.ReadOnlyPairLoadAction,
) !void {
    _ = request_index;
    var ptr_reg = materializePreparedLoadPointer(Authority, transaction, view, .rdi) catch |err|
        return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerSpill;
    if (action.bits != 96 and action.bits != 128)
        return error.ValueUseLoadReadonlyWidth;
    // Preserve the accepted authority and timing exactly: spill-backed
    // pointers stage first, then the existing pair chooser observes the
    // resulting selector/spill state. Seal conservatively declared every
    // pair register the chooser can return, so this late read-only decision
    // cannot introduce an unplanned physical write.
    const pair = try selector_state.choosePairScratchForClobber(transaction.selector, null) orelse
        return error.ValueUseLoadReadonlyPairUnavailable;
    if (pair.contains(ptr_reg)) {
        const current = switch (view.*) {
            .register => |prepared| switch (prepared.register) {
                .gpr64 => |reg| ValueLoc{ .scratch64 = reg },
                else => return error.ValueUseLoadReadonlyPointerProvenance,
            },
            else => return error.ValueUseLoadReadonlyPointerProvenance,
        };
        materialization.materializeScalar64(transaction.selector, current, .{ .gpr64 = .rdi }) catch |err|
            return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyPointerAlias;
        ptr_reg = .rdi;
        try failLoadForTest(Authority, transaction, .after_pointer_staging);
    }
    try selector_state.clobberArgReg(transaction.selector, pair.lo);
    try selector_state.clobberArgReg(transaction.selector, pair.hi);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 0 },
    });
    try failLoadForTest(Authority, transaction, .after_first_partial_load);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .mov_rax_to_arg = pair.lo,
    });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, if (action.bits == 96)
        .{ .load_arg_ptr_disp8_eax = .{ .reg = ptr_reg, .offset = 8 } }
    else
        .{ .load_arg_ptr_disp8_rax = .{ .reg = ptr_reg, .offset = 8 } });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .mov_rax_to_arg = pair.hi,
    });
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .scratch128 = pair });
}
pub fn executeStackI128AliasLoad(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    action: *const Types.StackI128AliasLoadAction,
) !void {
    const disp = switch (view.*) {
        .stack_object => |stack| switch (stack) {
            .integer128 => |disp| disp,
            else => return error.ValueUseLoadOrdinaryStackWidth,
        },
        else => return error.ValueUseLoadOrdinaryPointerRejected,
    };
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .stack128_value = disp });
}
pub fn executeReadOnlyTableI16Load(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    action: *const Types.ReadOnlyTableI16LoadAction,
) !void {
    const table = switch (view.*) {
        .table_pointer => |table| table,
        else => return error.ValueUseLoadReadonlyTableType,
    };
    const base: ArgReg = switch (table.storage) {
        .register => |reg| reg,
        .spill => |frame_index| blk: {
            materialization.materializeScalar64(
                transaction.selector,
                .{ .spill64 = frame_index },
                .{ .gpr64 = .rcx },
            ) catch |err| return if (err == error.OutOfMemory) err else error.ValueUseLoadReadonlyTableSpill;
            failLoadForTest(Authority, transaction, .after_pointer_staging) catch
                return error.ValueUseLoadReadonlyTableSpill;
            break :blk .rcx;
        },
    };
    if (table.shape != .i16_128 or table.offset != 0)
        return error.ValueUseLoadReadonlyTableType;
    try selector_state.clobberArgReg(transaction.selector, .r8);
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .load_arg_ptr_disp8_u16_arg = .{ .base = base, .dst = .r8, .offset = 0 },
    });
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    try selector_state.bindResultLoc(transaction.selector, result_name, .{ .scratch32 = .r8 });
}
fn failLoadForTest(
    comptime _: type,
    transaction: anytype,
    boundary: Types.LoadTestFailure,
) !void {
    if (builtin.is_test) {
        if (transaction.load_test_failure == boundary)
            return error.ValueUseLoadTestFailure;
    }
}
pub fn executeStoreScalar(
    comptime Authority: type,
    transaction: anytype,
    value_view: *const Types.PreparedView,
    action: Types.StoreScalarAction,
) !void {
    var staged: Types.PreparedView = undefined;
    const before = try Authority.registeredOperandView(Authority, transaction, action.pointer);
    const staged_address = (try materialization.preparedViewLoc(before)) == .rax;
    if (staged_address) {
        staged = before.*;
        try stageAccumulatorStorePointer(Authority, transaction, &staged);
    }
    try materializeActionScalar32(Authority, transaction, value_view, .accumulator);
    const pointer_view = if (staged_address) &staged else try Authority.registeredOperandView(Authority, transaction, action.pointer);
    executeStoreEaxToPointer(Authority, transaction, pointer_view, action.bits) catch |err| {
        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, action.pointer, err);
        return err;
    };
}
pub fn executeStoreImmediate(
    comptime Authority: type,
    transaction: anytype,
    pointer_view: *const Types.PreparedView,
    action: Types.StoreImmediateAction,
) !void {
    var staged_pointer: Types.PreparedView = undefined;
    const actual_pointer = if ((try materialization.preparedViewLoc(pointer_view)) == .rax) blk: {
        staged_pointer = pointer_view.*;
        try stageAccumulatorStorePointer(Authority, transaction, &staged_pointer);
        break :blk &staged_pointer;
    } else pointer_view;
    try materialization.clobberPhysicalNode(transaction.selector, .accumulator);
    if (action.bits == 64 and action.value < 0) {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .mov_imm_rax = @as(i64, action.value),
        });
    } else {
        try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
            .mov_imm_eax = action.value,
        });
    }
    try executeStoreEaxToPointer(Authority, transaction, actual_pointer, action.bits);
}

fn stageAccumulatorStorePointer(comptime Authority: type, transaction: anytype, view: *Types.PreparedView) !void {
    const pointer = try materialization.preparedViewLoc(view);
    if (pointer != .rax) return;
    // The plan owns this RAX -> RCX transfer. Stage the address before scalar
    // materialization overwrites EAX; retain the original canonical ownership.
    try materializeActionPointer(Authority, transaction, pointer, .rcx);
    view.* = .{ .register = .{ .register = .{ .gpr64 = .rcx }, .bits = 64 } };
}
pub fn executeStoreI64(
    comptime Authority: type,
    transaction: anytype,
    pointer_view: *const Types.PreparedView,
    action: Types.StoreI64Action,
) !void {
    const pointer = try materialization.preparedViewLoc(pointer_view);
    const reg: ArgReg = switch (pointer) {
        .arg64, .scratch64 => |r| r,
        .spill64 => blk: {
            try materializeActionPointer(Authority, transaction, pointer, .rcx);
            break :blk .rcx;
        },
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    const value_view = try Authority.registeredOperandView(Authority, transaction, action.value);
    materializeActionScalar64(Authority, transaction, value_view, .accumulator) catch |err| {
        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, action.value, err);
        return err;
    };
    if (reg == .rcx) {
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .store_rax_rcx_ptr,
        );
    } else {
        try transaction.selector.machine.instructions.append(
            transaction.selector.allocator,
            .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } },
        );
    }
}
pub fn executeStoreStackPointer(
    comptime Authority: type,
    transaction: anytype,
    source_view: *const Types.PreparedView,
    action: Types.StoreStackPointerAction,
) !void {
    const source = try stackScalarFromPreparedView(source_view);
    const destination_view = try Authority.registeredOperandView(Authority, transaction, action.destination);
    const destination = stackScalarFromPreparedView(destination_view) catch |err| {
        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, action.destination, err);
        return err;
    };
    if (destination.kind != .integer or destination.bits != 64) {
        Authority.noteRegisteredOperandBoundaryError(
            Authority,
            transaction,
            action.destination,
            error.ValueUseStorePointerFormUnsupported,
        );
        return error.ValueUseStorePointerFormUnsupported;
    }

    try materialization.clobberPhysicalNode(transaction.selector, .rcx);
    try transaction.selector.machine.instructions.append(
        transaction.selector.allocator,
        .{ .mov_rsp_arg64 = .rcx },
    );
    if (source.base_disp != 0) {
        const offset = std.math.cast(i32, source.base_disp) orelse
            return error.ValueUseStorePointerFormUnsupported;
        try selector_state.emitEflagsInstruction(
            transaction.selector,
            .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = offset } },
            .write,
        );
    }
    if (destination.base_disp % 4 != 0) {
        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, action.destination, error.ValueUseStorePointerAlignment);
        return error.ValueUseStorePointerAlignment;
    }
    const frame_index = FrameIndex.fromSlot(destination.base_disp / 4) catch {
        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, action.destination, error.ValueUseStorePointerFrame);
        return error.ValueUseStorePointerFrame;
    };
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .spill_arg64_rsp = .{ .frame_index = frame_index, .reg = .rcx },
    });
}
fn executeStoreEaxToPointer(
    comptime Authority: type,
    transaction: anytype,
    pointer_view: *const Types.PreparedView,
    bits: u8,
) !void {
    const pointer = try materialization.preparedViewLoc(pointer_view);
    switch (pointer) {
        .stack_scalar => |stack| {
            if (bits > 8 or stack.kind != .integer or stack.bits != 8)
                return error.ValueUseStorePointerFormUnsupported;
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (stack.base_disp <= std.math.maxInt(u8))
                    .{ .store_al_stack_disp8 = @intCast(stack.base_disp) }
                else
                    .{ .store_al_stack_disp32 = stack.base_disp },
            );
        },
        .arg64, .scratch64 => |reg| {
            if (bits == 0 or bits > 64) return error.ValueUseStorePointerFormUnsupported;
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (bits <= 8)
                    .{ .store_al_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } }
                else if (bits <= 16)
                    .{ .store_ax_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } }
                else if (bits <= 32)
                    .{ .store_eax_arg_ptr = reg }
                else
                    .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } },
            );
        },
        .spill64 => {
            if (bits == 0 or bits > 64) return error.ValueUseStorePointerFormUnsupported;
            try materializeActionPointer(Authority, transaction, pointer, .rcx);
            try transaction.selector.machine.instructions.append(
                transaction.selector.allocator,
                if (bits <= 8)
                    .{ .store_al_arg_ptr_disp8 = .{ .reg = .rcx, .offset = 0 } }
                else if (bits <= 16)
                    .{ .store_ax_arg_ptr_disp8 = .{ .reg = .rcx, .offset = 0 } }
                else if (bits <= 32)
                    .{ .store_eax_arg_ptr = .rcx }
                else
                    .{ .store_rax_arg_ptr_disp8 = .{ .reg = .rcx, .offset = 0 } },
            );
        },
        .stack_i32_ptr => |stack_ptr| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try executeStoreStackI32(Authority, transaction, pointer_view, stack_ptr.disp);
        },
        .stack_i32_array => |array| {
            if (bits != 32) return error.ValueUseStorePointerFormUnsupported;
            try appendStoreEaxStack(Authority, transaction, array.base_disp, false);
        },
        .readonly_table_ptr => return error.ValueUseStoreReadOnlyPointer,
        else => return error.ValueUseStorePointerFormUnsupported,
    }
}
fn executeStoreStackI32(
    comptime Authority: type,
    transaction: anytype,
    pointer_view: *const Types.PreparedView,
    disp: u32,
) !void {
    const descriptor = switch (pointer_view.*) {
        .address_descriptor => |*value| value,
        else => return error.ValueUseStorePointerFormUnsupported,
    };
    if (descriptor.index) |*index| {
        try materializeActionScalarHome(Authority, transaction, index.home, .rcx);
        if (descriptor.addend) |*addend| {
            try materializeActionScalarHome(Authority, transaction, addend.home, .r8);
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
        }
        try appendStoreEaxStack(Authority, transaction, disp, true);
    } else {
        try appendStoreEaxStack(Authority, transaction, disp, false);
    }
}
fn appendStoreEaxStack(
    comptime _: type,
    transaction: anytype,
    disp: u32,
    indexed: bool,
) !void {
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, if (indexed)
        if (disp <= std.math.maxInt(u8))
            .{ .store_eax_stack_rcx4_disp8 = @intCast(disp) }
        else
            .{ .store_eax_stack_rcx4_disp32 = disp }
    else if (disp <= std.math.maxInt(u8))
        .{ .store_eax_stack_disp8 = @intCast(disp) }
    else
        .{ .store_eax_stack_disp32 = disp });
}
fn materializeActionScalar32(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    destination: Types.PhysicalNode,
) !void {
    const current = try materialization.preparedViewLoc(view);
    try clobberActionDestination(Authority, transaction, current, destination);
    try materialization.materializeScalar32(transaction.selector, current, .eax);
}
fn materializeActionScalar64(
    comptime Authority: type,
    transaction: anytype,
    view: *const Types.PreparedView,
    destination: Types.PhysicalNode,
) !void {
    const current = try materialization.preparedViewLoc(view);
    try clobberActionDestination(Authority, transaction, current, destination);
    try materialization.materializeScalar64(transaction.selector, current, .rax);
}
fn materializeActionPointer(
    comptime Authority: type,
    transaction: anytype,
    current: ValueLoc,
    destination: ArgReg,
) !void {
    try clobberActionDestination(Authority, transaction, current, Types.PhysicalNode.fromArgReg(destination));
    try materialization.materializePointer(transaction.selector, current, .{ .gpr64 = destination });
}
fn materializeActionScalarHome(
    comptime Authority: type,
    transaction: anytype,
    home: Types.PreparedScalarHome,
    destination: ArgReg,
) !void {
    const current: ValueLoc = switch (home) {
        .register => |register| switch (register) {
            .gpr32 => |reg| .{ .scratch32 = reg },
            .gpr64 => |reg| .{ .scratch64 = reg },
            .eax => .eax,
            .rax => .rax,
        },
        .spill => |frame_index| .{ .spill64 = frame_index },
    };
    try clobberActionDestination(Authority, transaction, current, Types.PhysicalNode.fromArgReg(destination));
    try materialization.materializeScalar64(transaction.selector, current, .{ .gpr64 = destination });
}
fn clobberActionDestination(
    comptime _: type,
    transaction: anytype,
    current: ValueLoc,
    destination: Types.PhysicalNode,
) !void {
    if (Types.PhysicalNode.scalarSource(current)) |source| if (source == destination) return;
    try materialization.clobberPhysicalNode(transaction.selector, destination);
}
fn stackScalarFromPreparedView(
    view: *const Types.PreparedView,
) !selector_types.StackScalarLoc {
    return switch (view.*) {
        .stack_object => |object| switch (object) {
            .scalar => |stack| stack,
            else => error.ValueUseStorePointerFormUnsupported,
        },
        else => error.ValueUseStorePointerFormUnsupported,
    };
}

fn scalarCastScratchAvailable(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    return selector_state.regConflictStatus(selector, reg) orelse true;
}

fn byteAddressDestination(selector: *const ComposedBlockSelector, result_name: []const u8) ArgReg {
    if (selector.allocation_plan) |plan| {
        if (plan.assignment(result_name)) |assignment| {
            const planned_reg: ?ArgReg = switch (assignment) {
                .gpr64, .stack_pointer => |reg| reg,
                else => null,
            };
            if (planned_reg) |reg| {
                if (scalarCastScratchAvailable(selector, reg)) return reg;
                for (selector_types.selector_allocatable_regs) |candidate| {
                    if (scalarCastScratchAvailable(selector, candidate)) return candidate;
                }
                return reg;
            }
        }
    }
    return .rcx;
}

pub fn executeByteAddress(
    comptime Authority: type,
    transaction: anytype,
    base_index: u8,
    base_view: *const Types.PreparedView,
    base_request: *const Types.StoredRequest,
    action: Types.ByteAddressAction,
) !void {
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    switch (action.offset) {
        .constant => |offset| {
            const current = (try Authority.validateRequest(
                Authority,
                transaction,
                base_index,
                base_request,
            )) orelse
                return error.ValueUseUnsupportedSource;
            switch (current) {
                .stack_f32_pair_ptr => |ptr| {
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    const object_end = std.math.add(u32, ptr.object_base_disp, aggregate_object.byte_size) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    if (disp < ptr.object_base_disp or disp > object_end)
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_f32_pair_ptr = .{
                            .object_base_disp = ptr.object_base_disp,
                            .disp = disp,
                        },
                    });
                },
                .stack_i32_ptr => |ptr| {
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp, .index = ptr.index },
                    });
                },
                .readonly_table_ptr => |ptr| {
                    if (offset != 8 or ptr.offset != 0 or !ptr.shape.allowsOffset(8))
                        return error.ValueUseAddressOffsetOutOfRange;
                    var result = ptr;
                    result.offset = 8;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .readonly_table_ptr = result });
                },
                else => {
                    const dest_reg = byteAddressDestination(transaction.selector, result_name);
                    try materialization.materializeByteAddressPointer(transaction.selector, try materialization.preparedViewLoc(base_view), dest_reg);
                    if (offset != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .add_arg64_imm32 = .{ .reg = dest_reg, .imm = offset } },
                        .write,
                    );
                    try selector_state.bindScratch(transaction.selector, result_name, dest_reg, 64);
                },
            }
        },
        .request => |offset_handle| {
            const offset_view = try Authority.registeredOperandView(Authority, transaction, offset_handle);
            try materialization.materializeByteAddressPointer(transaction.selector, try materialization.preparedViewLoc(base_view), .r8);
            const offset_loc = materialization.preparedViewLoc(offset_view) catch |err| {
                Authority.noteRegisteredOperandBoundaryError(Authority, transaction, offset_handle, err);
                return err;
            };
            materialization.materializeScalar64(transaction.selector, offset_loc, .{ .gpr64 = .rcx }) catch |err| {
                Authority.noteRegisteredOperandBoundaryError(Authority, transaction, offset_handle, err);
                return err;
            };
            try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
            try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
        },
    }
}
pub fn executeScaledAddress(
    comptime Authority: type,
    transaction: anytype,
    base_index: u8,
    base_view: *const Types.PreparedView,
    base_request: *const Types.StoredRequest,
    action: Types.ScaledAddressAction,
) !void {
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    const current = (try Authority.validateRequest(
        Authority,
        transaction,
        base_index,
        base_request,
    )) orelse
        return error.ValueUseUnsupportedSource;
    switch (current) {
        .stack_i32_array => |array| {
            if (action.scale != 4) return error.ValueUseAddressDescriptorScaleMismatch;
            if (action.expected_stack_array_len) |expected_len| {
                if (array.len != expected_len) return error.ValueUseAddressDescriptorLengthMismatch;
            }
            switch (action.index) {
                .constant => |constant_index| {
                    const index = std.math.cast(u32, constant_index) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    if (index >= array.len) return error.ValueUseAddressOffsetOutOfRange;
                    const byte_offset = std.math.mul(u32, index, action.scale) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.add(u32, array.base_disp, byte_offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp },
                    });
                },
                .request => |index_handle| {
                    const index_name = try composition.ownRegisteredOperandName(Authority, transaction, index_handle);
                    const index_view = try Authority.registeredOperandView(Authority, transaction, index_handle);
                    const index_loc = materialization.preparedViewLoc(index_view) catch |err| {
                        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, index_handle, err);
                        return err;
                    };
                    materialization.materializeScalar64(transaction.selector, index_loc, .{ .gpr64 = .rcx }) catch |err| {
                        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, index_handle, err);
                        return err;
                    };
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .stack_i32_ptr = .{
                        .disp = array.base_disp,
                        .index = .{ .reg = .rcx, .name = index_name },
                    } });
                },
            }
        },
        .stack_i32_ptr => |ptr| {
            if (action.expected_stack_array_len != null)
                return error.ValueUseAddressDescriptorLengthMismatch;
            if (action.scale != 4) return error.ValueUseAddressDescriptorScaleMismatch;
            switch (action.index) {
                .constant => |constant_index| {
                    const offset = try scaledOffset(constant_index, action.scale);
                    const adjusted = std.math.add(i64, ptr.disp, offset) catch
                        return error.ValueUseAddressOffsetOutOfRange;
                    const disp = std.math.cast(u32, adjusted) orelse
                        return error.ValueUseAddressOffsetOutOfRange;
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{
                        .stack_i32_ptr = .{ .disp = disp, .index = ptr.index },
                    });
                },
                .request => |index_handle| {
                    const existing = ptr.index orelse return error.ValueUseUnsupportedAddressForm;
                    if (existing.reg != .rcx) return error.ValueUseUnsupportedAddressForm;
                    if (existing.addend_name != null) return error.ValueUseUnsupportedAddressForm;
                    const addend_name = try composition.ownRegisteredOperandName(Authority, transaction, index_handle);
                    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .stack_i32_ptr = .{
                        .disp = ptr.disp,
                        .index = .{ .reg = existing.reg, .name = existing.name, .addend_name = addend_name },
                    } });
                },
            }
        },
        else => {
            if (action.expected_stack_array_len != null)
                return error.ValueUseAddressDescriptorLengthMismatch;
            try materialization.materializePointer(transaction.selector, try materialization.preparedViewLoc(base_view), .{ .gpr64 = .rcx });
            switch (action.index) {
                .constant => |constant_index| {
                    const offset = try scaledOffset(constant_index, action.scale);
                    if (offset != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = offset } },
                        .write,
                    );
                },
                .request => |index_handle| {
                    const index_view = try Authority.registeredOperandView(Authority, transaction, index_handle);
                    const index_loc = materialization.preparedViewLoc(index_view) catch |err| {
                        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, index_handle, err);
                        return err;
                    };
                    materialization.materializeScalar64(transaction.selector, index_loc, .{ .gpr64 = .r8 }) catch |err| {
                        Authority.noteRegisteredOperandBoundaryError(Authority, transaction, index_handle, err);
                        return err;
                    };
                    const shift = try scaleShift(action.scale);
                    if (shift != 0) try selector_state.emitEflagsInstruction(
                        transaction.selector,
                        .{ .shl_r8_imm6 = shift },
                        .write,
                    );
                    try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
                },
            }
            try selector_state.bindScratch(transaction.selector, result_name, .rcx, 64);
        },
    }
}
pub fn executeReadOnlyTableAddress(
    comptime Authority: type,
    transaction: anytype,
    index_view: *const Types.PreparedView,
    index_request: *const Types.StoredRequest,
    action: Types.ReadOnlyTableAddressAction,
) !void {
    _ = index_request;
    const result_name = try composition.ownActionIdentity(Authority, transaction, &action.result);
    const symbol = try composition.ownActionIdentity(Authority, transaction, &action.symbol);
    try materialization.materializeScalar64(transaction.selector, try materialization.preparedViewLoc(index_view), .{ .gpr64 = .r8 });
    try transaction.selector.machine.instructions.append(transaction.selector.allocator, .{
        .lea_global_arg64 = .{ .reg = .rcx, .symbol = symbol },
    });
    const shift = try scaleShift(action.scale);
    if (shift != 0) try selector_state.emitEflagsInstruction(
        transaction.selector,
        .{ .shl_r8_imm6 = shift },
        .write,
    );
    try selector_state.emitEflagsInstruction(transaction.selector, .add_r8_rcx, .write);
    try selector_state.bindValueLoc(transaction.selector, result_name, .{ .readonly_table_ptr = .{
        .storage = .{ .reg = .rcx },
        .symbol = symbol,
        .shape = action.shape,
    } });
}
fn scaleShift(scale: u8) !u6 {
    if (scale == 0 or !std.math.isPowerOfTwo(scale)) return error.ValueUseAddressScaleInvalid;
    var value = scale;
    var shift: u6 = 0;
    while (value > 1) : (value >>= 1) shift += 1;
    return shift;
}
fn scaledOffset(index: i32, scale: u8) !i32 {
    _ = try scaleShift(scale);
    return std.math.mul(i32, index, scale) catch error.ValueUseAddressOffsetOutOfRange;
}
