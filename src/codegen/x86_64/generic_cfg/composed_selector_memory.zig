const std = @import("std");
const ir = @import("../../../ir.zig");
const cfg = @import("../../../analysis/cfg.zig");
const constant_table = @import("../constant_table.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_vector = @import("composed_selector_vector.zig");
const aggregate_object = @import("aggregate_object.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const MachineBinaryOp = x86_64_types.MachineBinaryOp;
const PairSpillLoc = selector_types.PairSpillLoc;
const RegPair = selector_types.RegPair;
const StackArrayLoc = selector_types.StackArrayLoc;
const StackPtrLoc = selector_types.StackPtrLoc;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const VirtualRegMetadata = selector_types.VirtualRegMetadata;
const ValueUseTransaction = value_use.ValueUseTransaction;
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
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
const stage2_max_blocks = stage2_planning.stage2_max_blocks;
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
const isComposedReturnType = composed_helpers.isComposedReturnType;
const shiftAmount5 = composed_helpers.shiftAmount5;
const shiftAmount6 = composed_helpers.shiftAmount6;
const shiftAmount7 = composed_helpers.shiftAmount7;
const i32Value = composed_helpers.i32Value;
const i32BitPattern = composed_helpers.i32BitPattern;
const i64Value = composed_helpers.i64Value;

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

pub fn lowerAlloca(selector: *ComposedBlockSelector, result: ?[]const u8, alloca: ir.AllocaInst) !?Diagnostic {
    if (!alloca.isSingleObject()) return .{ .no_emitter = "composed-block-alloca-count" };
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const loc = selector_state.valueLoc(selector, result_name) orelse return .{ .no_emitter = "composed-block-alloca-unplanned" };
    switch (loc) {
        .stack_scalar => |stack| {
            const integer_bits = if (alloca.allocated_ty == .ptr) @as(?u16, 64) else intBits(alloca.allocated_ty);
            const fp_bits = scalarFpStoreBits(alloca.allocated_ty);
            const bits = integer_bits orelse fp_bits orelse return .{ .no_emitter = "composed-block-alloca-plan-type" };
            const expected_kind: selector_types.StackScalarLoc.Kind = if (fp_bits != null) .fp else .integer;
            if (stack.bits != bits or stack.kind != expected_kind) return .{ .no_emitter = "composed-block-alloca-plan-type" };
        },
        .stack128 => if (!alloca.allocated_ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-alloca-plan-type" },
        .stack_i32_array => |stack_array| {
            const len = parseI32ArrayType(alloca.allocated_ty) orelse return .{ .no_emitter = "composed-block-alloca-plan-type" };
            if (stack_array.len != len) return .{ .no_emitter = "composed-block-alloca-plan-type" };
        },
        .stack_f32_pair_ptr => if (!aggregate_object.isF32PairType(selector.module_context, alloca.allocated_ty)) return .{ .no_emitter = "composed-block-alloca-plan-type" },
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack128_value, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-alloca-plan-loc" },
    }
    return null;
}

pub fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
    if (load.ty.eql(.{ .int = 8 }) and (load.ty_addrspace != null or load.ptr_addrspace != null)) return .{ .no_emitter = "composed-block-byte-load-addrspace" };
    if (inspection.isByteVector128(load.ty)) return lowerLoadByteVector(selector, result_name, load);
    if (selector_state.resolveValue(selector, load.ptr)) |ptr| if (ptr == .readonly_table_ptr)
        return lowerReadOnlyTableLoad(selector, result_name, load, ptr.readonly_table_ptr);
    if (load.ptr == .named and selector.readonly_pointer_params.contains(load.ptr.named)) {
        if (intBits(load.ty)) |bits| {
            const exact_ei = if (selector.function) |function| stage2_planning.isExactEiScalarFamily(function.*) else false;
            if (exact_ei or bits == 64 or bits == 96 or bits == 128)
                return lowerReadOnlyPointerIntegerLoad(selector, result_name, load, bits);
        }
    }
    if (isF32x2(load.ty)) return lowerLoadF32Pair(selector, result_name, load);
    if (scalarFpBits(load.ty)) |bits| return lowerLoadFp(selector, result_name, load, bits);
    if (!load.ty.eql(.{ .int = 8 }) and !load.ty.eql(.{ .int = 16 }) and !load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const alias_i128 = load.ty.eql(.{ .int = 128 });
    const bits: u16 = @intCast(load.ty.int);
    const pointer_request = try registerValueUseAction(
        &transaction,
        load.ptr,
        .ptr,
        .stack_pointer,
        .load_address,
        if (alias_i128)
            .{ .load_stack_i128_alias = .{ .result = try valueUseActionIdentity(result_name) } }
        else
            .{ .load_scalar = .{ .kind = .ordinary, .bits = bits } },
    );
    transaction.seal() catch |err| return ordinaryLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;

    const accumulator = if (alias_i128)
        null
    else
        try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err| return ordinaryLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    transaction.materializeAll() catch |err| return ordinaryLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    const lease = transaction.preparedView(pointer_request) catch |err|
        return ordinaryLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return ordinaryLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;

    if (accumulator) |handle| {
        const definition: selector_state.AccumulatorDefinition = switch (bits) {
            8, 32 => .zeroExtending(bits),
            64 => .fullRax(),
            else => unreachable,
        };
        try transaction.defineAccumulatorResult(handle, result_name, definition);
        try transaction.finalizeAccumulatorResult(handle);
    }
    try transaction.commit();
    return null;
}

fn ordinaryLoadValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    pointer_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (!transaction.failedRequestIs(pointer_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-unknown-load-ptr" },
        error.ValueUseLoadOrdinaryStackWidth => .{ .no_emitter = "composed-block-load-stack-width" },
        error.ValueUseLoadOrdinaryStackArrayWidth => .{ .no_emitter = "composed-block-load-stack-array-width" },
        error.ValueUseLoadOrdinaryPointerWidth => .{ .no_emitter = "composed-block-load-ptr-width" },
        error.ValueUseLoadOrdinaryPointerRejected => .{ .no_emitter = "composed-block-load-ptr" },
        else => null,
    };
}

pub fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
    if (store.ty.eql(.{ .int = 8 }) and (store.ty_addrspace != null or store.ptr_addrspace != null)) return .{ .no_emitter = "composed-block-byte-store-addrspace" };
    if (store.ptr == .named and selector.readonly_pointer_params.contains(store.ptr.named))
        return .{ .no_emitter = "composed-block-store-readonly-param" };
    if (inspection.isByteVector128(store.ty)) return lowerStoreByteVector(selector, store);
    if (scalarFpStoreBits(store.ty)) |bits| return lowerStoreFp(selector, store, bits);
    if (store.ty == .ptr) return lowerStoreStackPointer(selector, store);
    if (!store.ty.eql(.{ .int = 1 }) and !store.ty.eql(.{ .int = 8 }) and !store.ty.eql(.{ .int = 32 }) and !store.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-store-width" };
    const pointer_class = selector_state.storePointerDiagnosticClass(selector, store.ptr) orelse
        return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    if (store.ty.eql(.{ .int = 64 })) return lowerStoreI64Transactional(selector, store, pointer_class);
    return lowerStoreScalarTransactional(selector, store, pointer_class, @intCast(store.ty.int));
}

fn lowerReadOnlyPointerIntegerLoad(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst, bits: u16) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-readonly-param-addrspace" };
    const ptr_name = switch (load.ptr) {
        .named => |name| name,
        else => return .{ .no_emitter = "composed-block-load-readonly-param-provenance" },
    };
    if (!selector.readonly_pointer_params.contains(ptr_name)) return .{ .no_emitter = "composed-block-load-ptr-width" };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const pair_result = bits == 96 or bits == 128;
    const pointer_request = try registerValueUseAction(
        &transaction,
        load.ptr,
        .ptr,
        .stack_pointer,
        .load_address,
        if (pair_result)
            .{ .load_readonly_pair = .{
                .result = try valueUseActionIdentity(result_name),
                .bits = bits,
            } }
        else
            .{ .load_scalar = .{ .kind = .readonly_pointer, .bits = bits } },
    );
    transaction.seal() catch |err|
        return readOnlyPointerLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;

    const accumulator = if (pair_result)
        null
    else
        try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return readOnlyPointerLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return readOnlyPointerLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    const lease = transaction.preparedView(pointer_request) catch |err|
        return readOnlyPointerLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return readOnlyPointerLoadValueUseDiagnostic(&transaction, pointer_request, err) orelse return err;

    if (accumulator) |handle| {
        const definition: selector_state.AccumulatorDefinition = switch (bits) {
            8, 16, 32 => .zeroExtending(bits),
            56 => .zeroExtendedRax(56),
            64 => .fullRax(),
            else => unreachable,
        };
        try transaction.defineAccumulatorResult(handle, result_name, definition);
        try transaction.finalizeAccumulatorResult(handle);
    }
    try transaction.commit();
    return null;
}

fn readOnlyPointerLoadValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    pointer_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (!transaction.failedRequestIs(pointer_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-unknown-load-ptr" },
        error.ValueUseLoadReadonlyPointerProvenance => .{ .no_emitter = "composed-block-load-readonly-param-provenance" },
        error.ValueUseLoadReadonlyPointerSpill => .{ .unsupported_value = "composed-block-load-readonly-param-spill" },
        error.ValueUseLoadReadonlyPointerAlias => .{ .unsupported_value = "composed-block-load-readonly-param-alias" },
        error.ValueUseLoadReadonlyPairUnavailable => .{ .no_spill_envelope = "composed-block-load-readonly-param-pair" },
        error.ValueUseLoadReadonlyWidth => .{ .no_emitter = "composed-block-load-width" },
        else => null,
    };
}

fn lowerStoreStackPointer(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.ty_addrspace != null or store.ptr_addrspace != null) return .{ .no_emitter = "composed-block-store-stack-pointer-addrspace" };
    const destination_class = selector_state.storePointerDiagnosticClass(selector, store.ptr) orelse
        return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    switch (destination_class) {
        .stack_scalar => |stack| if (stack.bits != 64 or stack.kind != .integer)
            return .{ .no_emitter = "composed-block-store-stack-pointer-width" },
        else => return .{ .no_emitter = "composed-block-store-stack-pointer-ptr" },
    }
    const source_class = selector_state.storePointerDiagnosticClass(selector, store.value) orelse
        return .{ .unsupported_value = "composed-block-store-stack-pointer-value" };
    if (source_class != .stack_scalar)
        return .{ .no_emitter = "composed-block-store-stack-pointer-value" };

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const destination = registerValueUseSource(
        &transaction,
        store.ptr,
        .ptr,
        .stack_object,
        .stack_object_address,
    ) catch return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    const action = registerValueUseAction(
        &transaction,
        store.value,
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .store_stack_pointer = .{ .destination = destination } },
    ) catch return .{ .unsupported_value = "composed-block-store-stack-pointer-value" };
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseStorePointerAlignment => .{ .no_emitter = "composed-block-store-stack-pointer-align" },
        error.ValueUseStorePointerFrame => .{ .no_emitter = "composed-block-store-stack-pointer-frame" },
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = "composed-block-store-stack-pointer-value" },
        error.ValueUseStorePointerFormUnsupported,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        => .{ .no_emitter = "composed-block-store-stack-pointer-value" },
        else => return err,
    };
    return null;
}

fn scalarFpBits(ty: ir.Type) ?u16 {
    return if (ty == .float) 32 else if (ty == .double) 64 else null;
}

fn scalarFpStoreBits(ty: ir.Type) ?u16 {
    return if (ty == .half) 16 else scalarFpBits(ty);
}

// Scalar byte loops use the existing framed CFG/phi machinery. Raw byte vectors
// require verified loop-carried XMM ownership proof in cyclic CFGs:
// 1. Zero other XMM values in the function (no FP/vector params, return, phis, or instructions).
// 2. Intra-block transient ownership: every byte-vector load has an intra-block store
//    with no intervening byte-vector load, and exactly 1 use across the function.
// 3. Every byte-vector store consumes a byte-vector loaded earlier in the same block.
fn byteTransfersAreAcyclic(selector: *ComposedBlockSelector) !bool {
    const function = selector.function orelse return false;
    if (function.blocks.items.len > stage2_max_blocks) return false;
    var graph = try cfg.Graph.build(selector.allocator, function.*);
    defer graph.deinit();
    var remaining: [stage2_max_blocks]usize = undefined;
    var queue: [stage2_max_blocks]usize = undefined;
    var end: usize = 0;
    for (graph.edges.items, 0..) |edges, index| {
        remaining[index] = edges.predecessors.items.len;
        if (remaining[index] == 0) {
            queue[end] = index;
            end += 1;
        }
    }
    var cursor: usize = 0;
    while (cursor < end) : (cursor += 1) {
        for (graph.successors(queue[cursor])) |successor| {
            remaining[successor] -= 1;
            if (remaining[successor] == 0) {
                queue[end] = successor;
                end += 1;
            }
        }
    }
    return end == function.blocks.items.len;
}

fn valueUsesName(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |n| std.mem.eql(u8, n, name),
        else => false,
    };
}

fn countInstructionUsesOfName(instruction: ir.Instruction, name: []const u8) usize {
    if (instruction.removed) return 0;
    var count: usize = 0;
    switch (instruction.kind) {
        .binary => |b| {
            if (valueUsesName(b.lhs, name)) count += 1;
            if (valueUsesName(b.rhs, name)) count += 1;
        },
        .cast => |c| {
            if (valueUsesName(c.value, name)) count += 1;
        },
        .icmp => |i| {
            if (valueUsesName(i.lhs, name)) count += 1;
            if (valueUsesName(i.rhs, name)) count += 1;
        },
        .fcmp => |f| {
            if (valueUsesName(f.lhs, name)) count += 1;
            if (valueUsesName(f.rhs, name)) count += 1;
        },
        .select => |s| {
            if (valueUsesName(s.cond, name)) count += 1;
            if (valueUsesName(s.true_value, name)) count += 1;
            if (valueUsesName(s.false_value, name)) count += 1;
        },
        .load => |l| {
            if (valueUsesName(l.ptr, name)) count += 1;
        },
        .store => |s| {
            if (valueUsesName(s.ptr, name)) count += 1;
            if (valueUsesName(s.value, name)) count += 1;
        },
        .gep => |g| {
            if (valueUsesName(g.ptr, name)) count += 1;
            for (g.indices.items) |idx| {
                if (valueUsesName(idx.value, name)) count += 1;
            }
        },
        .call => |c| {
            for (c.args.items) |arg| {
                if (valueUsesName(arg.value, name)) count += 1;
            }
        },
        .phi => |p| {
            for (p.incoming.items) |inc| {
                if (valueUsesName(inc.value, name)) count += 1;
            }
        },
        .freeze => |f| {
            if (valueUsesName(f.value, name)) count += 1;
        },
        .extractelement => |e| {
            if (valueUsesName(e.vector, name)) count += 1;
            if (valueUsesName(e.index, name)) count += 1;
        },
        .insertelement => |i| {
            if (valueUsesName(i.vector, name)) count += 1;
            if (valueUsesName(i.value, name)) count += 1;
            if (valueUsesName(i.index, name)) count += 1;
        },
        .shufflevector => |s| {
            if (valueUsesName(s.lhs, name)) count += 1;
            if (valueUsesName(s.rhs, name)) count += 1;
        },
        .extractvalue => |e| {
            if (valueUsesName(e.aggregate, name)) count += 1;
        },
        .insertvalue => |i| {
            if (valueUsesName(i.aggregate, name)) count += 1;
            if (valueUsesName(i.value, name)) count += 1;
        },
        .alloca, .atomicrmw, .cmpxchg, .fence => {},
    }
    return count;
}

fn countTerminatorUsesOfName(terminator: ir.Terminator, name: []const u8) usize {
    var count: usize = 0;
    switch (terminator) {
        .ret => |r| if (r.value) |v| if (valueUsesName(v, name)) { count += 1; },
        .condbr => |c| if (valueUsesName(c.cond, name)) { count += 1; },
        .@"switch" => |s| {
            if (valueUsesName(s.cond, name)) count += 1;
            for (s.cases.items) |case| if (valueUsesName(case.value, name)) { count += 1; };
        },
        .indirectbr => |i| if (valueUsesName(i.addr, name)) { count += 1; },
        .br, .@"unreachable" => {},
    }
    return count;
}

fn countFunctionUsesOfName(function: ir.Function, name: []const u8) usize {
    var count: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            count += countInstructionUsesOfName(inst, name);
        }
        if (block.terminator) |term| {
            count += countTerminatorUsesOfName(term, name);
        }
    }
    return count;
}

fn isOtherXmmType(ty: ir.Type) bool {
    if (inspection.isByteVector128(ty)) return false;
    return switch (ty) {
        .half, .float, .double, .x86_fp80, .fp128, .vector => true,
        else => false,
    };
}

fn functionHasConflictingXmmState(function: ir.Function) bool {
    if (isOtherXmmType(function.ret_ty)) return true;
    for (function.params.items) |param| {
        if (isOtherXmmType(param.ty)) return true;
    }
    for (function.blocks.items) |block| {
        for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .binary => |b| if (isOtherXmmType(b.ty)) return true,
                .cast => |c| if (isOtherXmmType(c.from_ty) or isOtherXmmType(c.to_ty)) return true,
                .fcmp => return true,
                .select => |s| if (isOtherXmmType(s.ty)) return true,
                .phi => |p| if (isOtherXmmType(p.ty) or inspection.isByteVector128(p.ty)) return true,
                .alloca => |a| if (isOtherXmmType(a.allocated_ty) or inspection.isByteVector128(a.allocated_ty)) return true,
                .load => |l| if (isOtherXmmType(l.ty)) return true,
                .store => |s| if (isOtherXmmType(s.ty)) return true,
                .call => |c| {
                    if (isOtherXmmType(c.ret_ty)) return true;
                    for (c.args.items) |arg| if (isOtherXmmType(arg.ty)) return true;
                },
                .extractelement, .insertelement, .shufflevector => return true,
                .extractvalue => |e| if (isOtherXmmType(e.result_ty)) return true,
                .insertvalue => |i| if (isOtherXmmType(i.aggregate_ty)) return true,
                .gep, .freeze, .icmp, .atomicrmw, .cmpxchg, .fence => {},
            }
        }
    }
    return false;
}

fn cyclicByteVectorTransfersAreSafe(selector: *ComposedBlockSelector) bool {
    const function = selector.function orelse return false;
    if (function.blocks.items.len > stage2_max_blocks) return false;
    if (functionHasConflictingXmmState(function.*)) return false;

    for (function.blocks.items) |block| {
        for (block.instructions.items, 0..) |inst, inst_idx| {
            if (inst.removed) continue;
            if (inst.kind == .load and inspection.isByteVector128(inst.kind.load.ty)) {
                const def_name = inst.result orelse return false;
                if (countFunctionUsesOfName(function.*, def_name) != 1) return false;

                var store_found = false;
                for (block.instructions.items[inst_idx + 1 ..]) |later_inst| {
                    if (later_inst.removed) continue;
                    if (later_inst.kind == .load and inspection.isByteVector128(later_inst.kind.load.ty)) {
                        return false;
                    }
                    if (later_inst.kind == .store and inspection.isByteVector128(later_inst.kind.store.ty)) {
                        if (later_inst.kind.store.value == .named and
                            std.mem.eql(u8, later_inst.kind.store.value.named, def_name))
                        {
                            store_found = true;
                            break;
                        }
                    }
                }
                if (!store_found) return false;
            } else if (inst.kind == .store and inspection.isByteVector128(inst.kind.store.ty)) {
                if (inst.kind.store.value != .named) return false;
                const val_name = inst.kind.store.value.named;
                var def_found = false;
                for (block.instructions.items[0..inst_idx]) |prior_inst| {
                    if (prior_inst.removed) continue;
                    if (prior_inst.kind == .load and inspection.isByteVector128(prior_inst.kind.load.ty)) {
                        if (prior_inst.result) |res| {
                            if (std.mem.eql(u8, res, val_name)) {
                                def_found = true;
                                break;
                            }
                        }
                    }
                }
                if (!def_found) return false;
            }
        }
    }
    return true;
}

fn byteVectorTransferIsAdmissible(selector: *ComposedBlockSelector) !bool {
    if (try byteTransfersAreAcyclic(selector)) return true;
    return cyclicByteVectorTransfersAreSafe(selector);
}

fn byteVectorShape() selector_types.VectorShape {
    return .{ .lane_type = .integer, .lane_count = 16, .lane_bits = 8, .defined_lanes = 0xffff };
}

// Raw byte vectors have no arithmetic interpretation here. Reuse the existing
// XMM preservation/spill machinery and move all 128 bits without alignment claims.
fn stageByteVectorPointer(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = value,
        .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 },
        .form = .pointer,
        .destination = .{ .gpr64 = .rcx },
    }) catch return .{ .unsupported_value = "composed-block-byte-vector-pointer" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-byte-vector-pointer" };
    try transaction.prepare();
    try transaction.materializeAll();
    try transaction.commit();
    return null;
}

fn lowerLoadByteVector(selector: *ComposedBlockSelector, name: []const u8, load: ir.LoadInst) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-byte-vector-addrspace" };
    if (!try byteVectorTransferIsAdmissible(selector)) return .{ .no_emitter = "composed-block-byte-transfer-cyclic-cfg" };
    if (try stageByteVectorPointer(selector, load.ptr)) |diagnostic| return diagnostic;
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, .{ .load_f128_arg_ptr_xmm0 = .{ .reg = .rcx, .offset = 0, .unaligned = true } });
    try selector_state.bindResultLoc(selector, name, .{ .xmm = .{ .reg = .xmm0, .bits = 128, .shape = .{ .vector = byteVectorShape() } } });
    return null;
}

fn lowerStoreByteVector(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.ty_addrspace != null or store.ptr_addrspace != null) return .{ .no_emitter = "composed-block-byte-vector-addrspace" };
    if (!try byteVectorTransferIsAdmissible(selector)) return .{ .no_emitter = "composed-block-byte-transfer-cyclic-cfg" };
    if (store.value != .named) return .{ .no_emitter = "composed-block-byte-vector-store-value" };
    if (try stageByteVectorPointer(selector, store.ptr)) |diagnostic| return diagnostic;
    if (try selector_vector.materializeByteVector(selector, store.value, byteVectorShape())) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .store_f128_xmm0_arg_ptr = .{ .reg = .rcx, .offset = 0, .unaligned = true } });
    return null;
}

fn lowerLoadFp(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst, bits: u16) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-fp-addrspace" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    const stack = switch (ptr) {
        .stack_scalar => |stack| stack,
        else => return .{ .no_emitter = "composed-block-load-fp-ptr" },
    };
    if (stack.kind != .fp or stack.bits != bits) return .{ .no_emitter = "composed-block-load-stack-width" };

    try selector_state.clobberXmmReg(selector, .xmm0);
    if (bits == 32) {
        if (stack.base_disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(stack.base_disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0_f32 = stack.base_disp });
        }
    } else if (bits == 64) {
        if (stack.base_disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0 = @intCast(stack.base_disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0 = stack.base_disp });
        }
    } else unreachable;
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerLoadF32Pair(selector: *ComposedBlockSelector, result_name: []const u8, load: ir.LoadInst) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-f32-pair-addrspace" };
    const view = aggregatePointerView(selector, load.ptr) orelse return .{ .no_emitter = "composed-block-load-f32-pair-ptr" };
    if (view.offset != 0 or !view.allows(aggregate_object.byte_size)) return .{ .no_emitter = "composed-block-load-f32-pair-bounds" };
    const ptr = selector_state.resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    try selector_state.clobberXmmReg(selector, .xmm0);
    switch (ptr) {
        .stack_f32_pair_ptr => |stack| {
            if (stack.disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_xmm0 = @intCast(stack.disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_xmm0 = stack.disp });
            }
        },
        .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = reg, .dst = .xmm0, .offset = 0 } }),
        .spill64 => |frame_index| {
            try selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = .rcx, .dst = .xmm0, .offset = 0 } });
        },
        else => return .{ .no_emitter = "composed-block-load-f32-pair-ptr" },
    }
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{
        .reg = .xmm0,
        .bits = 128,
        .shape = .{ .vector = selector_types.VectorShape.f32x2(0b11) },
    } });
    return null;
}

fn lowerStoreFp(selector: *ComposedBlockSelector, store: ir.StoreInst, bits: u16) !?Diagnostic {
    if (store.ty_addrspace != null or store.ptr_addrspace != null) return .{ .no_emitter = "composed-block-store-fp-addrspace" };
    const ptr = selector_state.resolveValue(selector, store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    if (aggregatePointerView(selector, store.ptr)) |view| {
        if (bits != 32 or !view.allows(4)) return .{ .no_emitter = "composed-block-store-f32-pair-bounds" };
        if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;
        switch (ptr) {
            .stack_f32_pair_ptr => |stack| {
                if (stack.disp % 4 != 0) return .{ .no_emitter = "composed-block-store-f32-pair-align" };
                const frame_index = FrameIndex.fromSlot(stack.disp / 4) catch return .{ .no_spill_envelope = "composed-block-store-f32-pair-frame" };
                try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
            },
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = 0 } }),
            .spill64 => |frame_index| {
                try selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
                try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = .rcx, .offset = 0 } });
            },
            else => return .{ .no_emitter = "composed-block-store-f32-pair-ptr" },
        }
        return null;
    }
    if (ptr == .stack_scalar) {
        const stack = ptr.stack_scalar;
        if (stack.kind != .fp or stack.bits != bits) return .{ .no_emitter = "composed-block-store-stack-width" };
        if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;

        if (bits == 16) {
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
            try selector_state.clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = .rcx });
            if (stack.base_disp != 0) {
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = @intCast(stack.base_disp) } });
            }
            try selector.machine.instructions.append(selector.allocator, .store_ax_rcx_ptr);
            return null;
        }

        if (stack.base_disp % 4 != 0) return .{ .no_emitter = "composed-block-store-fp-align" };
        const frame_index = FrameIndex.fromSlot(stack.base_disp / 4) catch return .{ .no_spill_envelope = "composed-block-store-fp-frame" };
        if (bits == 32) {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm32_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
        } else if (bits == 64) {
            try selector.machine.instructions.append(selector.allocator, .{ .spill_xmm64_rsp = .{ .frame_index = frame_index, .reg = .xmm0 } });
        } else unreachable;
        return null;
    }

    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-store-fp-ptr" },
    };
    if (!selector.abi_pointer_params.contains(ptr_name)) return .{ .no_emitter = "composed-block-store-fp-ptr" };
    if (try selector_fp.materializeFpValue(selector, store.value, .xmm0, bits)) |diagnostic| return diagnostic;
    const ptr_reg = switch (ptr) {
        .arg64, .scratch64 => |reg| reg,
        .spill64 => |frame_index| blk: {
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch return .{ .unsupported_value = "composed-block-store-fp-ptr" };
            break :blk .rcx;
        },
        else => return .{ .no_emitter = "composed-block-store-fp-ptr" },
    };
    if (bits == 16) {
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
        try selector.machine.instructions.append(selector.allocator, .{ .store_ax_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else if (bits == 32) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = ptr_reg, .offset = 0 } });
    } else unreachable;
    return null;
}

fn lowerStoreScalarTransactional(
    selector: *ComposedBlockSelector,
    store: ir.StoreInst,
    pointer_class: selector_state.StorePointerDiagnosticClass,
    bits: u8,
) !?Diagnostic {
    if (scalarStorePointerDiagnostic(pointer_class, bits)) |diagnostic| return diagnostic;
    const pointer_use = pointerUseForm(selector, store.ptr, false) orelse
        return .{ .no_emitter = "composed-block-store-ptr" };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const action = switch (store.value) {
        .named => blk: {
            const pointer = registerValueUseSource(
                &transaction,
                store.ptr,
                .ptr,
                pointer_use.class,
                pointer_use.form,
            ) catch return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
            break :blk registerValueUseAction(
                &transaction,
                store.value,
                .{ .int = bits },
                .gpr32,
                .gpr32,
                .{ .store_scalar = .{ .pointer = pointer, .bits = bits } },
            ) catch return .{ .unsupported_value = storeValueDetail(selector, store.value) };
        },
        .int => |int| blk: {
            const immediate = i32Value(int) catch return .{ .unsupported_value = "composed-block-store-value-other" };
            break :blk registerValueUseAction(
                &transaction,
                store.ptr,
                .ptr,
                pointer_use.class,
                pointer_use.form,
                .{ .store_immediate = .{ .value = immediate, .bits = bits } },
            ) catch return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-store-value-other" },
    };
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseStoreReadOnlyPointer => .{ .no_emitter = "composed-block-store-readonly-table" },
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = storeValueDetail(selector, store.value) },
        error.ValueUseStorePointerFormUnsupported,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        => .{ .no_emitter = "composed-block-store-ptr" },
        else => return err,
    };
    return null;
}

fn lowerStoreI64Transactional(
    selector: *ComposedBlockSelector,
    store: ir.StoreInst,
    pointer_class: selector_state.StorePointerDiagnosticClass,
) !?Diagnostic {
    switch (pointer_class) {
        .register64, .spill64 => {},
        else => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    if (store.value != .named) return .{ .unsupported_value = "composed-block-store-value-other" };
    const pointer_use = pointerUseForm(selector, store.ptr, false) orelse
        return .{ .no_emitter = "composed-block-store-ptr" };

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const value = registerValueUseSource(
        &transaction,
        store.value,
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ) catch return .{ .unsupported_value = storeValueDetail(selector, store.value) };
    const action = registerValueUseAction(
        &transaction,
        store.ptr,
        .ptr,
        pointer_use.class,
        pointer_use.form,
        .{ .store_i64 = .{ .value = value } },
    ) catch return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = storeValueDetail(selector, store.value) },
        error.ValueUseStorePointerFormUnsupported,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        => .{ .no_emitter = "composed-block-store-ptr" },
        else => return err,
    };
    return null;
}

fn scalarStorePointerDiagnostic(
    pointer_class: selector_state.StorePointerDiagnosticClass,
    bits: u8,
) ?Diagnostic {
    return switch (pointer_class) {
        .stack_scalar => |stack| if ((bits == 1 or bits == 8) and stack.bits == 8 and stack.kind == .integer)
            null
        else
            .{ .no_emitter = "composed-block-store-stack-width" },
        .register64, .spill64 => if (bits == 8 or bits == 32)
            null
        else
            .{ .no_emitter = "composed-block-store-ptr-width" },
        .stack_i32_ptr, .stack_i32_array => if (bits == 32)
            null
        else
            .{ .no_emitter = "composed-block-store-ptr-width" },
        .readonly_table => .{ .no_emitter = "composed-block-store-readonly-table" },
        .other => .{ .no_emitter = "composed-block-store-ptr" },
    };
}

fn storeValueDetail(selector: *const ComposedBlockSelector, value: ir.Value) []const u8 {
    return switch (selector_state.storeValueDiagnosticClass(selector, value) orelse return "composed-block-unknown-store-value") {
        .argument => "composed-block-store-value-arg",
        .scratch => "composed-block-store-value-scratch",
        .accumulator => "composed-block-store-value-accumulator",
        .spill => "composed-block-store-value-spill",
        .other => "composed-block-store-value-other",
    };
}

fn valueUseExpected(ty: ir.Type, register_class: VirtualRegClass) ValueUseTransaction.Expected {
    return .{
        .ty = ty,
        .register_class = register_class,
        .pointer_address_space = if (ty == .ptr) 0 else null,
    };
}

fn valueUseActionIdentity(name: []const u8) !ValueUseTransaction.ActionIdentity {
    return ValueUseTransaction.ActionIdentity.init(name);
}

fn registerValueUseSource(
    transaction: *ValueUseTransaction,
    source: ir.Value,
    ty: ir.Type,
    register_class: VirtualRegClass,
    form: ValueUseTransaction.UseForm,
) !ValueUseTransaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = valueUseExpected(ty, register_class),
        .form = form,
        .destination = .prepared_source,
    });
}

fn registerValueUseAction(
    transaction: *ValueUseTransaction,
    source: ir.Value,
    ty: ir.Type,
    register_class: VirtualRegClass,
    form: ValueUseTransaction.UseForm,
    action: ValueUseTransaction.PreparedAction,
) !ValueUseTransaction.RequestHandle {
    return transaction.register(.{
        .source = source,
        .expected = valueUseExpected(ty, register_class),
        .form = form,
        .destination = .prepared_view,
        .prepared_action = action,
    });
}

fn executeValueUseAction(
    authority: *ValueUseTransaction,
    action: ValueUseTransaction.RequestHandle,
) !void {
    try authority.seal();
    try authority.prepare();
    try authority.materializeAll();
    try authority.executePreparedAction(try authority.preparedView(action));
    try authority.commit();
}

fn pointerUseForm(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    bounded_f32_pair: bool,
) ?struct { class: VirtualRegClass, form: ValueUseTransaction.UseForm } {
    const register_class = selector_state.valueRegisterClass(selector, value) orelse return null;
    if (bounded_f32_pair) {
        if (register_class != .stack_pointer) return null;
        return .{ .class = .stack_pointer, .form = .stack_f32_pair_byte_address };
    }
    return switch (register_class) {
        .gpr64, .stack_pointer => .{ .class = register_class, .form = .pointer },
        .stack_object => .{ .class = .stack_object, .form = .stack_object_address },
        else => null,
    };
}

pub fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (gep.ptr == .named and std.mem.startsWith(u8, gep.ptr.named, "@"))
        return try lowerReadOnlyTableGep(selector, result_name, gep);
    const exact_ei = if (selector.function) |function| stage2_planning.isExactEiScalarFamily(function.*) else false;
    const readonly_base = exact_ei and gep.ptr == .named and selector.readonly_pointer_params.contains(gep.ptr.named);
    if (isBytePointerSource(gep.source_ty)) {
        const diagnostic = try lowerBytePointerGep(selector, result_name, gep);
        if (diagnostic == null and readonly_base) try selector.readonly_pointer_params.put(result_name, {});
        return diagnostic;
    }
    if (isI32ElementPointerSource(gep.source_ty)) {
        const diagnostic = try lowerI32ElementPointerGep(selector, result_name, gep);
        if (diagnostic == null and readonly_base) try selector.readonly_pointer_params.put(result_name, {});
        return diagnostic;
    }
    const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
    const base_class = selector_state.valueRegisterClass(selector, gep.ptr) orelse
        return .{ .unsupported_value = "composed-block-unknown-array-gep-ptr" };
    if (base_class != .stack_object) return .{ .no_emitter = "composed-block-gep-ptr" };
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 2) return .{ .no_emitter = "composed-block-gep-index-count" };
    const first_index = gep.indices.items[0];
    if (!first_index.ty.eql(.{ .int = 64 }) or !first_index.value.eql(.{ .int = 0 })) return .{ .no_emitter = "composed-block-gep-base-index" };
    const elem_index = gep.indices.items[1];
    if (!elem_index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const action_index: ValueUseTransaction.AddressOffset = switch (elem_index.value) {
        .int => |int| .{ .constant = std.math.cast(i32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" } },
        .named => blk: {
            const index_class = selector_state.valueRegisterClass(selector, elem_index.value) orelse
                return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            if (index_class != .gpr64)
                return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            break :blk .{ .request = registerValueUseSource(
                &transaction,
                elem_index.value,
                .{ .int = 64 },
                .gpr64,
                .gpr64,
            ) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" } };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    };
    const action = try registerValueUseAction(
        &transaction,
        gep.ptr,
        .ptr,
        .stack_object,
        .stack_object_address,
        .{ .form_scaled_address = .{
            .result = try valueUseActionIdentity(result_name),
            .index = action_index,
            .scale = 4,
            .expected_stack_array_len = len,
        } },
    );
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseAddressDescriptorLengthMismatch => .{ .no_emitter = "composed-block-gep-len" },
        error.ValueUseAddressOffsetOutOfRange => .{ .no_emitter = "composed-block-gep-index-range" },
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = "composed-block-gep-dynamic-index" },
        error.ValueUseSourceViewMismatch, error.ValueUseRegisterClassMismatch, error.ValueUseTypeMismatch => .{ .no_emitter = "composed-block-gep-ptr" },
        else => return err,
    };
    return null;
}

pub fn lowerI32ElementPointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    if (index.value != .named) return .{ .no_emitter = "composed-block-gep-index-form" };
    const base_use = pointerUseForm(selector, gep.ptr, false) orelse
        return .{ .unsupported_value = "composed-block-unknown-i32-element-gep-ptr" };
    const index_class = selector_state.valueRegisterClass(selector, index.value) orelse
        return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
    if (index_class != .gpr64) return .{ .unsupported_value = "composed-block-gep-dynamic-index" };

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const index_handle = registerValueUseSource(
        &transaction,
        index.value,
        .{ .int = 64 },
        .gpr64,
        .gpr64,
    ) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
    const action = try registerValueUseAction(
        &transaction,
        gep.ptr,
        .ptr,
        base_use.class,
        base_use.form,
        .{ .form_scaled_address = .{
            .result = try valueUseActionIdentity(result_name),
            .index = .{ .request = index_handle },
            .scale = 4,
        } },
    );
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = "composed-block-gep-dynamic-index" },
        error.ValueUseUnsupportedAddressForm => .{ .no_emitter = "composed-block-gep-ptr" },
        error.ValueUseSourceViewMismatch, error.ValueUseRegisterClassMismatch, error.ValueUseTypeMismatch => .{ .unsupported_value = "composed-block-unknown-i32-element-gep-ptr" },
        else => return err,
    };
    return null;
}

pub fn lowerBytePointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    const bounded_f32_pair = aggregatePointerView(selector, gep.ptr) != null;
    const base_use = pointerUseForm(selector, gep.ptr, bounded_f32_pair) orelse
        return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
    if (base_use.form == .stack_object_address)
        return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const action_offset: ValueUseTransaction.AddressOffset = switch (index.value) {
        .int => |int| .{ .constant = std.math.cast(i32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" } },
        .named => blk: {
            const index_class = selector_state.valueRegisterClass(selector, index.value) orelse
                return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            if (index_class != .gpr64) return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            const handle = registerValueUseSource(
                &transaction,
                index.value,
                .{ .int = 64 },
                .gpr64,
                .gpr64,
            ) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            break :blk .{ .request = handle };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    };
    const action = try registerValueUseAction(
        &transaction,
        gep.ptr,
        .ptr,
        base_use.class,
        base_use.form,
        .{ .form_byte_address = .{
            .result = try valueUseActionIdentity(result_name),
            .offset = action_offset,
        } },
    );
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseAddressOffsetOutOfRange => if (gep.ptr == .named and selector.readonly_pointer_params.contains(gep.ptr.named))
            .{ .no_emitter = "composed-block-gep-readonly-table-offset" }
        else
            .{ .no_emitter = "composed-block-gep-index-range" },
        error.ValueUseUnresolvedSource, error.ValueUseExpiredSource => .{ .unsupported_value = "composed-block-gep-dynamic-index" },
        error.ValueUseUnsupportedAddressForm, error.ValueUseSourceViewMismatch, error.ValueUseRegisterClassMismatch, error.ValueUseTypeMismatch => .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" },
        else => return err,
    };
    return null;
}

fn aggregatePointerView(selector: *const ComposedBlockSelector, value: ir.Value) ?aggregate_object.PointerView {
    const function = selector.function orelse return null;
    return aggregate_object.pointerView(function.*, selector.module_context, value);
}

fn isF32x2(ty: ir.Type) bool {
    return ty == .vector and ty.vector.len == 2 and ty.vector.elem_ty == .float;
}

fn lowerReadOnlyTableGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-readonly-table-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-readonly-table-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or index.value != .named) return .{ .no_emitter = "composed-block-gep-readonly-table-index" };
    const context = selector.module_context orelse return .{ .no_emitter = "composed-block-gep-readonly-table-context" };
    var decoded = (constant_table.decodeSymbol(selector.allocator, context.*, gep.ptr.named) catch return .{ .no_emitter = "composed-block-gep-readonly-table-global" }) orelse
        return .{ .no_emitter = "composed-block-gep-readonly-table-global" };
    defer decoded.deinit(selector.allocator);
    if (!sourceStrideMatchesShape(gep.source_ty, decoded.shape)) return .{ .no_emitter = "composed-block-gep-readonly-table-source" };
    if (!hasAdmittedIndexProof(selector, index.value.named, decoded.shape)) return .{ .no_emitter = "composed-block-gep-readonly-table-range" };
    const index_class = selector_state.valueRegisterClass(selector, index.value) orelse
        return .{ .unsupported_value = "composed-block-gep-readonly-table-index" };
    if (index_class != .gpr64)
        return .{ .unsupported_value = "composed-block-gep-readonly-table-index" };

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const action = registerValueUseAction(
        &transaction,
        index.value,
        .{ .int = 64 },
        .gpr64,
        .gpr64,
        .{ .form_readonly_table_address = .{
            .result = try valueUseActionIdentity(result_name),
            .symbol = try valueUseActionIdentity(decoded.symbol),
            .shape = decoded.shape,
            .scale = decoded.shape.stride(),
        } },
    ) catch return .{ .unsupported_value = "composed-block-gep-readonly-table-index" };
    executeValueUseAction(&transaction, action) catch |err| return switch (err) {
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        => .{ .unsupported_value = "composed-block-gep-readonly-table-index" },
        else => return err,
    };
    return null;
}

fn lowerReadOnlyTableLoad(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    load: ir.LoadInst,
    ptr: selector_types.ReadOnlyTablePtrLoc,
) !?Diagnostic {
    if (load.ty_addrspace != null or load.ptr_addrspace != null) return .{ .no_emitter = "composed-block-load-readonly-table-addrspace" };
    if (!ptr.shape.allowsOffset(ptr.offset)) return .{ .no_emitter = "composed-block-load-readonly-table-offset" };
    if (ptr.shape == .i16_128 and ptr.offset == 0 and load.ty.eql(.{ .int = 16 })) {
        return lowerReadOnlyTableI16Transactional(selector, result_name, load);
    }

    // The surviving direct materialization belongs to the untouched
    // double/XMM O3 tail (and its legacy rejected-type diagnostics).
    const base: ArgReg = switch (ptr.storage) {
        .reg => |reg| reg,
        .spill => |frame_index| blk: {
            selector_state.materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch return .{ .unsupported_value = "composed-block-load-readonly-table-spill" };
            break :blk .rcx;
        },
    };
    if (ptr.shape == .i16_128) {
        return .{ .no_emitter = "composed-block-load-readonly-table-type" };
    }
    if (load.ty != .double) return .{ .no_emitter = "composed-block-load-readonly-table-type" };
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_disp8_xmm = .{ .base = base, .dst = .xmm0, .offset = ptr.offset } });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 64 } });
    return null;
}

fn lowerReadOnlyTableI16Transactional(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    load: ir.LoadInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const table_request = try registerValueUseAction(
        &transaction,
        load.ptr,
        .ptr,
        .stack_pointer,
        .load_address,
        .{ .load_readonly_table_i16 = .{
            .result = try valueUseActionIdentity(result_name),
        } },
    );
    transaction.seal() catch |err|
        return readOnlyTableLoadValueUseDiagnostic(&transaction, table_request, err) orelse return err;
    transaction.prepare() catch |err|
        return readOnlyTableLoadValueUseDiagnostic(&transaction, table_request, err) orelse return err;
    transaction.materializeAll() catch |err|
        return readOnlyTableLoadValueUseDiagnostic(&transaction, table_request, err) orelse return err;
    const lease = transaction.preparedView(table_request) catch |err|
        return readOnlyTableLoadValueUseDiagnostic(&transaction, table_request, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return readOnlyTableLoadValueUseDiagnostic(&transaction, table_request, err) orelse return err;
    try transaction.commit();
    return null;
}

fn readOnlyTableLoadValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    table_request: ValueUseTransaction.RequestHandle,
    err: anyerror,
) ?Diagnostic {
    if (!transaction.failedRequestIs(table_request)) return null;
    return switch (err) {
        error.ValueUseUnresolvedSource => .{ .unsupported_value = "composed-block-unknown-load-ptr" },
        error.ValueUseLoadReadonlyTableOffset => .{ .no_emitter = "composed-block-load-readonly-table-offset" },
        error.ValueUseLoadReadonlyTableType => .{ .no_emitter = "composed-block-load-readonly-table-type" },
        error.ValueUseLoadReadonlyTableSpill => .{ .unsupported_value = "composed-block-load-readonly-table-spill" },
        else => null,
    };
}

fn sourceStrideMatchesShape(source_ty: ir.Type, shape: constant_table.Shape) bool {
    const expected = switch (shape) {
        .i16_128 => "[2 x i8]",
        .f64_16, .f64_512_pairs => "[8 x i8]",
        .f64_pair_128 => "[16 x i8]",
    };
    return switch (source_ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " \t"), expected),
        else => false,
    };
}

fn hasAdmittedIndexProof(selector: *const ComposedBlockSelector, name: []const u8, shape: constant_table.Shape) bool {
    const function = selector.function orelse return false;
    const source_name = stripZext(function.*, name) orelse name;
    const mask: i128 = switch (shape) {
        .i16_128, .f64_pair_128 => 127,
        .f64_16 => 15,
        .f64_512_pairs => 510,
    };
    const binary = findInstruction(function.*, source_name) orelse return false;
    const and_inst = switch (binary.kind) {
        .binary => |value| if (value.op == .@"and" and intOperand(value.lhs, value.rhs, mask)) value else return false,
        else => return false,
    };
    if (shape != .f64_512_pairs) return true;
    const shifted = namedNonIntOperand(and_inst.lhs, and_inst.rhs) orelse return false;
    const shift_inst = findInstruction(function.*, shifted) orelse return false;
    return switch (shift_inst.kind) {
        .binary => |value| value.op == .shl and intOperand(value.lhs, value.rhs, 1),
        else => false,
    };
}

fn stripZext(function: ir.Function, name: []const u8) ?[]const u8 {
    const instruction = findInstruction(function, name) orelse return null;
    return switch (instruction.kind) {
        .cast => |cast| if (cast.op == .zext and cast.value == .named) cast.value.named else null,
        else => null,
    };
}

fn findInstruction(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
    };
    return null;
}

fn intOperand(lhs: ir.Value, rhs: ir.Value, expected: i128) bool {
    return (lhs == .int and lhs.int == expected) or (rhs == .int and rhs.int == expected);
}

fn namedNonIntOperand(lhs: ir.Value, rhs: ir.Value) ?[]const u8 {
    if (lhs == .named and rhs == .int) return lhs.named;
    if (rhs == .named and lhs == .int) return rhs.named;
    return null;
}

pub fn isI32ElementPointerSource(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[4 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn isBytePointerSource(ty: ir.Type) bool {
    if (ty.eql(.{ .int = 8 })) return true;
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[1 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn appendLoadStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    try materializeStackIndex(selector, stack_ptr);
    if (stack_ptr.index != null) {
        if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp8_eax = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_rcx4_disp32_eax = stack_ptr.disp });
        }
    } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_eax = @intCast(stack_ptr.disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_eax = stack_ptr.disp });
    }
}

pub fn loadStackU64IntoArg(selector: *ComposedBlockSelector, reg: ArgReg, disp: u32) !void {
    try selector_state.clobberArgReg(selector, reg);
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
    }
}

pub fn loadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    try selector_state.clobberAccumulator(selector);
    try appendLoadStackU64IntoRax(selector, disp);
}

fn appendLoadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
    if (disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp });
    }
}

pub fn appendStoreStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    try materializeStackIndex(selector, stack_ptr);
    if (stack_ptr.index != null) {
        if (stack_ptr.disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp8 = @intCast(stack_ptr.disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_rcx4_disp32 = stack_ptr.disp });
        }
    } else if (stack_ptr.disp <= std.math.maxInt(u8)) {
        try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp8 = @intCast(stack_ptr.disp) });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .store_eax_stack_disp32 = stack_ptr.disp });
    }
}

pub fn materializeStackIndex(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    const index = stack_ptr.index orelse return;
    try selector_state.emitValueIntoScratch(selector, .{ .named = index.name }, .rcx, 64);
    if (index.addend_name) |addend_name| {
        try selector_state.emitValueIntoScratch(selector, .{ .named = addend_name }, .r8, 64);
        try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    }
}
