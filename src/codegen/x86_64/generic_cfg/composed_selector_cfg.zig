const std = @import("std");
const ir = @import("../../../ir.zig");
const cfg = @import("../../../analysis/cfg.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_aggregate = @import("composed_selector_aggregate.zig");
const sysv_abi = @import("../sysv_abi.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");
const selector_calls = @import("composed_selector_calls.zig");
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
const pair_a = selector_types.pair_a;
const pair_b = selector_types.pair_b;
const selector_allocatable_pairs = selector_types.selector_allocatable_pairs;
const selector_allocatable_regs = selector_types.selector_allocatable_regs;
const argRegIndex = selector_types.argRegIndex;
const xmmRegIndex = selector_types.xmmRegIndex;

pub const Diagnostic = inspection.Diagnostic;
pub const SelectionResult = inspection.SelectionResult;

const NameSet = stage2_planning.NameSet;
const PlannedValueAssignment = stage2_planning.PlannedValueAssignment;
const SelectorAllocationPlan = stage2_planning.SelectorAllocationPlan;
const SelectorValueInterval = stage2_planning.SelectorValueInterval;
const SpillSlotAssignment = stage2_planning.SpillSlotAssignment;
const ValueUseTransaction = value_use.ValueUseTransaction;
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
const max_compare_chain_switch_cases = 8;

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

fn blockIndex(selector: *const ComposedBlockSelector, function: ir.Function, name: []const u8) ?usize {
    if (selector.allocation_plan) |plan| {
        if (plan.block_indexes.count() != 0) return plan.blockIndex(name);
    }
    return function.blockIndex(name);
}

pub fn blockEndsInTrap(block: ir.BasicBlock) bool {
    var index = block.instructions.items.len;
    while (index > 0) {
        index -= 1;
        const instruction = block.instructions.items[index];
        if (instruction.removed) continue;
        const call = switch (instruction.kind) {
            .call => |call| call,
            else => return false,
        };
        if (call.isDebugVariableLocation()) continue;
        return std.mem.eql(u8, call.callee, "llvm.trap") and call.ret_ty == .void and call.args.items.len == 0;
    }
    return false;
}

pub fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (!select.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-select-cond" };
    if (select.ty == .half or select.ty == .float or select.ty == .double) return lowerFpSelect(selector, result_name, select);
    const bits: u16 = if (select.ty.eql(.ptr)) 64 else intBits(select.ty) orelse return .{ .no_emitter = "composed-block-select-type" };
    if (bits == 0 or (bits > 32 and bits != 64)) return .{ .no_emitter = "composed-block-select-width" };

    {
        // Forming the condition may use RCX. Both select arms are still live
        // at this instruction, even when this is their final use.
        const previous = selector.preserve_current_position_values;
        selector.preserve_current_position_values = true;
        defer selector.preserve_current_position_values = previous;
        if (try emitBranchCondition(selector, select.cond)) |diagnostic| return diagnostic;
    }
    if (select.true_value == .named) {
        const true_name = select.true_value.named;
        switch (selector_state.resolveValue(selector, select.true_value) orelse return .{ .unsupported_value = "composed-block-select-true-value" }) {
            .eax => {
                _ = try selector_state.preserveCurrentEaxIntoScratch(selector);
                if (selector_state.resolveValue(selector, select.true_value)) |preserved| switch (preserved) {
                    .eax => try selector_state.spillValueOrError(selector, true_name),
                    else => {},
                };
            },
            .rax => try selector_state.spillValueOrError(selector, true_name),
            else => {},
        }
    }
    emitScalarSelectValue(selector, select.false_value, bits) catch return .{ .unsupported_value = "composed-block-select-false-value" };
    const end_label = try ownedSelectEndLabel(selector);
    try selector_state.emitEflagsInstruction(selector, .{ .je = end_label }, .use);
    emitScalarSelectValue(selector, select.true_value, bits) catch return .{ .unsupported_value = "composed-block-select-true-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
    try selector_state.bindAccumulator(selector, result_name, bits);
    return null;
}

fn emitScalarSelectValue(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    if (bits == 64 and value == .int) {
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(value.int) });
        return;
    }
    try selector_state.emitValueIntoAccumulator(selector, value, bits);
}

fn lowerFpSelect(selector: *ComposedBlockSelector, result_name: []const u8, select: ir.SelectInst) !?Diagnostic {
    const bits: u16 = if (select.ty == .half) 16 else if (select.ty == .float) 32 else if (select.ty == .double) 64 else return .{ .no_emitter = "composed-block-select-type" };
    if (try emitBranchCondition(selector, select.cond)) |diagnostic| return diagnostic;

    const true_reg = fpValueReg(selector, select.true_value, bits);
    const false_reg = fpValueReg(selector, select.false_value, bits);
    const dst = fpSelectScratch(true_reg, false_reg);
    if (try selector_fp.materializeFpValue(selector, select.false_value, dst, bits)) |diagnostic| return diagnostic;
    const end_label = try ownedSelectEndLabel(selector);
    try selector_state.emitEflagsInstruction(selector, .{ .je = end_label }, .use);
    if (try selector_fp.materializeFpValue(selector, select.true_value, dst, bits)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = dst, .bits = bits } });
    return null;
}

fn fpValueReg(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) ?x86_64_types.XmmReg {
    const loc = selector_state.resolveValue(selector, value) orelse return null;
    return switch (loc) {
        .xmm => |fp| if (fp.bits == bits and fp.vectorShape() == null) fp.reg else null,
        else => null,
    };
}

fn fpSelectScratch(first: ?x86_64_types.XmmReg, second: ?x86_64_types.XmmReg) x86_64_types.XmmReg {
    for (selector_types.selector_allocatable_xmm_regs) |reg| {
        if ((first == null or reg != first.?) and (second == null or reg != second.?)) return reg;
    }
    unreachable;
}

pub fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
    if (ret.ty == .void) {
        if (ret.value != null) return .{ .unsupported_value = "composed-block-void-ret-value" };
        try emitReturnEpilogue(selector);
        return null;
    }
    if (ret.ty == .ptr) {
        if (ret.ptr_addrspace != null) return .{ .no_emitter = "composed-block-pointer-ret-addrspace" };
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        var authority = try ValueUseTransaction.begin(selector);
        defer authority.deinit();
        _ = try authority.register(.{
            .source = value,
            .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 },
            .form = .pointer,
            .destination = .rax,
        });
        authority.seal() catch |err| return pointerReturnDiagnostic(err) orelse return err;
        authority.prepare() catch |err| return pointerReturnDiagnostic(err) orelse return err;
        authority.materializeAll() catch |err| return pointerReturnDiagnostic(err) orelse return err;
        try authority.commit();
        try emitReturnEpilogue(selector);
        return null;
    }
    if (ret.ty == .half or ret.ty == .float or ret.ty == .double) {
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        const bits: u16 = if (ret.ty == .half) 16 else if (ret.ty == .float) 32 else 64;
        selector_state.emitValueIntoFpReturn(selector, value, bits) catch return .{ .unsupported_value = "composed-block-fp-ret-value" };
        try emitReturnEpilogue(selector);
        return null;
    }
    if (sysv_abi.isVector128AbiType(ret.ty)) {
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        if (try @import("composed_selector_vector.zig").materializeAbiVector(selector, value, ret.ty, .xmm0)) |diagnostic| return diagnostic;
        try emitReturnEpilogue(selector);
        return null;
    }
    if (sysv_abi.sseAggregateReturnKind(ret.ty)) |kind| {
        const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
        selector_aggregate.emitReturn(selector, value, kind) catch return .{ .unsupported_value = "composed-block-aggregate-ret-value" };
        try emitReturnEpilogue(selector);
        return null;
    }
    const bits = intBits(ret.ty) orelse return .{ .no_emitter = "composed-block-ret-type" };
    if (!((bits > 0 and bits <= 64 and bits != 52) or bits == 128)) return .{ .no_emitter = "composed-block-ret-width" };
    const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
    switch (value) {
        .int => |int| if (bits <= 32)
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try composed_helpers.i32BitPattern(int) })
        else if (bits <= 64)
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) })
        else
            return .{ .unsupported_value = "composed-block-ret-value" },
        .named => {
            _ = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
            if (bits == 128) {
                try selector_state.emitValueIntoI128Return(selector, value);
            } else {
                try selector_state.emitValueIntoAccumulator(selector, value, bits);
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
    }
    try emitReturnEpilogue(selector);
    return null;
}

fn pointerReturnDiagnostic(err: anyerror) ?Diagnostic {
    return switch (err) {
        error.ValueUseUnsupportedSource,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        error.ValueUseUnsupportedAddressForm,
        => .{ .unsupported_value = "composed-block-pointer-ret-value" },
        else => null,
    };
}

pub fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
    if (selector.return_epilogue_label) |label| {
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = label });
        return;
    }
    if (selector.stack_frame_bytes != 0) try selector_frame.appendAddRsp(selector, selector.stack_frame_bytes);
    try selector.machine.instructions.append(selector.allocator, .ret);
}

pub fn lowerCfgTerminator(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    terminator: ir.Terminator,
) !?Diagnostic {
    return switch (terminator) {
        .ret => |ret| blk: {
            if (selector.stack_frame_bytes == 0) {
                if (try restoreDisplacedPhiDestinations(selector)) |diagnostic| break :blk diagnostic;
            }
            break :blk try lowerReturn(selector, ret);
        },
        .br => |br| {
            const target_index = blockIndex(selector, function, br.target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            if (selector.stack_frame_bytes != 0) {
                selector_state.spillLiveValuesForCfgBoundary(selector) catch return .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
            } else if (!blockHasPhiIncomingFrom(function.blocks.items[target_index], function.blocks.items[block_index].name)) {
                if (try restoreDisplacedPhiDestinations(selector)) |diagnostic| return diagnostic;
            }
            if (try emitPhiEdgeMoves(selector, function.blocks.items[target_index], function.blocks.items[block_index].name)) |diagnostic| return diagnostic;
            if (target_index != block_index + 1) {
                try selector.machine.instructions.append(selector.allocator, .{ .jmp = br.target });
            }
            return null;
        },
        .condbr => |condbr| {
            if (!condbr.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "stage2-condbr-type" };
            const then_index = blockIndex(selector, function, condbr.then_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            const else_index = blockIndex(selector, function, condbr.else_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            const then_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[then_index], function.blocks.items[block_index].name);
            const else_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[else_index], function.blocks.items[block_index].name);
            if (selector.stack_frame_bytes != 0) {
                selector_state.spillLiveValuesForCfgBoundary(selector) catch return .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
            } else if (!then_has_phi_edge and !else_has_phi_edge) {
                if (try restoreDisplacedPhiDestinations(selector)) |diagnostic| return diagnostic;
            }
            const previous_preserve_current = selector.preserve_current_position_values;
            if (then_has_phi_edge or else_has_phi_edge) selector.preserve_current_position_values = true;
            defer selector.preserve_current_position_values = previous_preserve_current;
            if (try emitBranchCondition(selector, condbr.cond)) |diagnostic| return diagnostic;
            if (then_has_phi_edge or else_has_phi_edge) {
                return try lowerConditionalPhiEdges(selector, function, block_index, then_index, else_index);
            }
            try selector_state.emitEflagsInstruction(selector, .{ .jne = condbr.then_target }, .use);
            if (else_index != block_index + 1) {
                try selector.machine.instructions.append(selector.allocator, .{ .jmp = condbr.else_target });
            }
            return null;
        },
        .@"switch" => |switch_term| try lowerSwitch(selector, function, block_index, switch_term),
        .@"unreachable" => blk: {
            if (!blockEndsInTrap(function.blocks.items[block_index]) and
                !isExclusivelyProvenMaskedSwitchDefault(function, function.blocks.items[block_index].name))
                try selector_state.emitEflagsInstruction(selector, .ud2, .preserve);
            break :blk null;
        },
        .indirectbr => |branch| blk: {
            if (branch.targets.items.len == 0) break :blk .{ .unsupported_control_flow = "stage2-indirect-targets" };
            for (branch.targets.items) |name| {
                const target = blockIndex(selector, function, name) orelse break :blk .{ .unsupported_control_flow = "stage2-indirect-target" };
                // PHI destinations require edge-specific snapshots; retain that
                // boundary until indirect edge trampolines are implemented.
                for (function.blocks.items[target].instructions.items) |inst| {
                    if (!inst.removed and inst.kind == .phi) break :blk .{ .no_emitter = "stage2-indirect-phi" };
                }
            }
            if (selector.stack_frame_bytes != 0)
                selector_state.spillLiveValuesForCfgBoundary(selector) catch break :blk .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
            var transaction = try ValueUseTransaction.begin(selector);
            defer transaction.deinit();
            _ = try transaction.register(.{ .source = branch.addr, .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 }, .form = .pointer, .destination = .{ .gpr64 = .rcx } });
            transaction.seal() catch break :blk .{ .unsupported_value = "stage2-indirect-address" };
            transaction.prepare() catch break :blk .{ .unsupported_value = "stage2-indirect-address" };
            transaction.materializeAll() catch break :blk .{ .unsupported_value = "stage2-indirect-address" };
            try transaction.commit();
            // These are original, module-owned targets. Private form rewrites
            // preserve the indirect successor list, just as ordinary labels.
            try selector_state.emitEflagsInstruction(selector, .{ .indirect_jump = .{ .reg = .rcx, .targets = branch.targets.items } }, .preserve);
            break :blk null;
        },
    };
}

fn lowerSwitch(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    switch_term: ir.SwitchTerminator,
) !?Diagnostic {
    const bits = intBits(switch_term.cond_ty) orelse return .{ .no_emitter = "stage2-switch-type" };
    if (bits == 0 or bits > 32) return .{ .no_emitter = "stage2-switch-width" };
    if (switch_term.cases.items.len == 0 or switch_term.cases.items.len > max_compare_chain_switch_cases) {
        return .{ .no_emitter = "stage2-switch-case-count" };
    }

    var case_values: [max_compare_chain_switch_cases]i32 = undefined;
    var case_target_indices: [max_compare_chain_switch_cases]usize = undefined;
    const predecessor = function.blocks.items[block_index].name;
    const default_index = blockIndex(selector, function, switch_term.default_target) orelse return .{ .unsupported_control_flow = "stage2-switch-target" };
    var has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[default_index], predecessor);

    for (switch_term.cases.items, 0..) |case, case_index| {
        if (!case.value_ty.eql(switch_term.cond_ty) or case.value != .int) return .{ .no_emitter = "stage2-switch-case-type" };
        const value = switchCaseValue(case.value.int, bits) orelse return .{ .no_emitter = "stage2-switch-case-value" };
        for (case_values[0..case_index]) |previous| {
            if (previous == value) return .{ .no_emitter = "stage2-switch-duplicate-case" };
        }
        case_values[case_index] = value;
        const target_index = blockIndex(selector, function, case.target) orelse return .{ .unsupported_control_flow = "stage2-switch-target" };
        case_target_indices[case_index] = target_index;
        has_phi_edge = has_phi_edge or blockHasPhiIncomingFrom(function.blocks.items[target_index], predecessor);
    }

    if (has_phi_edge) {
        if (isExactFrexpSwitchPhiShape(
            function,
            block_index,
            switch_term,
            case_values[0..switch_term.cases.items.len],
            case_target_indices[0..switch_term.cases.items.len],
            default_index,
        )) return lowerExactFrexpSwitchPhiEdge(
            selector,
            function,
            block_index,
            switch_term,
            case_values[0..switch_term.cases.items.len],
            case_target_indices[0..switch_term.cases.items.len],
            default_index,
        );
        if (!(try isExactEiEntrySwitchPhiShape(
            selector.allocator,
            function,
            block_index,
            switch_term,
            case_values[0..switch_term.cases.items.len],
            case_target_indices[0..switch_term.cases.items.len],
            default_index,
        ))) return .{ .no_emitter = "stage2-switch-phi-edge" };
        return lowerExactEiEntrySwitchPhiEdges(
            selector,
            function,
            block_index,
            switch_term,
            case_values[0..switch_term.cases.items.len],
            case_target_indices[0..switch_term.cases.items.len],
            default_index,
        );
    }

    const exhaustive_case = maskedSwitchExhaustiveCaseIndex(function, switch_term, bits, case_values[0..switch_term.cases.items.len]);
    var action_cases: [ValueUseTransaction.max_switch_cases]ValueUseTransaction.SwitchCaseIntent = undefined;
    for (switch_term.cases.items, case_values[0..switch_term.cases.items.len], 0..) |case, value, index| {
        action_cases[index] = .{ .value = value, .target = case.target };
    }
    const switch_action = try ValueUseTransaction.SwitchCompareChainAction.init(
        @intCast(bits),
        action_cases[0..switch_term.cases.items.len],
        switch_term.default_target,
        if (exhaustive_case) |index| @intCast(index) else null,
    );
    var authority = try ValueUseTransaction.begin(selector);
    defer authority.deinit();
    const action = try authority.register(.{
        .source = switch_term.cond,
        .expected = .{ .ty = switch_term.cond_ty, .register_class = .gpr32 },
        .form = .switch_condition,
        .destination = .prepared_view,
        .prepared_action = .{ .switch_compare_chain = switch_action },
    });
    authority.seal() catch |err| return switchConditionValueUseDiagnostic(err) orelse return err;
    const framed_boundary = selector.stack_frame_bytes != 0;
    authority.applySwitchBoundary(action) catch |err| {
        if (switchConditionValueUseDiagnostic(err)) |diagnostic| return diagnostic;
        if (framed_boundary) return .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
        return switch (err) {
            error.ValueUseSwitchPhiDestinationMissing,
            error.ValueUseSwitchPhiDestinationBitsMissing,
            => .{ .unsupported_value = "stage2-phi-dst" },
            error.UnsupportedCodegenValue => .{ .no_emitter = "stage2-phi-restore-loc" },
            else => return err,
        };
    };
    authority.prepare() catch |err| return switchConditionMaterializationDiagnostic(err) orelse return err;
    authority.materializeAll() catch |err| return switchConditionMaterializationDiagnostic(err) orelse return err;
    authority.executePreparedAction(try authority.preparedView(action)) catch |err|
        return switchConditionMaterializationDiagnostic(err) orelse return err;
    try authority.commit();
    return null;
}

fn switchConditionValueUseDiagnostic(err: anyerror) ?Diagnostic {
    return switch (err) {
        error.ValueUseUnsupportedSource,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseSwitchImmediateOutOfRange,
        error.ValueUseSwitchConditionHomeUnsupported,
        error.ValueUseSwitchConditionWidthMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        error.ValueUseSourceViewMismatch,
        => .{ .unsupported_value = "stage2-switch-cond" },
        else => null,
    };
}

fn switchConditionMaterializationDiagnostic(err: anyerror) ?Diagnostic {
    if (switchConditionValueUseDiagnostic(err)) |diagnostic| return diagnostic;
    return switch (err) {
        error.UnsupportedCodegenValue => .{ .unsupported_value = "stage2-switch-cond" },
        else => null,
    };
}

fn isExactFrexpSwitchPhiShape(
    function: ir.Function,
    block_index: usize,
    switch_term: ir.SwitchTerminator,
    case_values: []const i32,
    case_target_indices: []const usize,
    default_index: usize,
) bool {
    if (!switch_term.cond_ty.eql(.{ .int = 11 }) or switch_term.cond != .named or
        case_values.len != 2 or case_target_indices.len != 2)
    {
        return false;
    }

    var zero_index: ?usize = null;
    var all_ones_index: ?usize = null;
    for (case_values, 0..) |value, index| {
        if (value == 0) {
            if (zero_index != null) return false;
            zero_index = index;
        } else if (value == switchValueMask(11)) {
            if (all_ones_index != null) return false;
            all_ones_index = index;
        } else return false;
    }
    const zero_target_index = case_target_indices[zero_index orelse return false];
    const phi_target_index = case_target_indices[all_ones_index orelse return false];
    if (zero_target_index == phi_target_index or zero_target_index == default_index or phi_target_index == default_index) return false;

    const predecessor = function.blocks.items[block_index].name;
    if (blockHasPhiIncomingFrom(function.blocks.items[zero_target_index], predecessor) or
        blockHasPhiIncomingFrom(function.blocks.items[default_index], predecessor))
    {
        return false;
    }

    const target = function.blocks.items[phi_target_index];
    var i32_phi: ?ir.PhiInst = null;
    var i64_phi: ?ir.PhiInst = null;
    var phi_count: usize = 0;
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => continue,
        };
        phi_count += 1;
        if (phi.ty.eql(.{ .int = 32 })) {
            if (i32_phi != null) return false;
            i32_phi = phi;
        } else if (phi.ty.eql(.{ .int = 64 })) {
            if (i64_phi != null) return false;
            i64_phi = phi;
        } else return false;
    }
    if (phi_count != 2) return false;
    const exponent_phi = i32_phi orelse return false;
    const bits_phi = i64_phi orelse return false;
    if (!sameFourFullDefinedPhiPredecessors(function, exponent_phi, bits_phi)) return false;

    const exponent_incoming = phiIncomingFrom(exponent_phi, predecessor) orelse return false;
    const bits_incoming = phiIncomingFrom(bits_phi, predecessor) orelse return false;
    return exponent_incoming.value.eql(.{ .int = 0 }) and bits_incoming.value == .named;
}

fn sameFourFullDefinedPhiPredecessors(function: ir.Function, lhs: ir.PhiInst, rhs: ir.PhiInst) bool {
    if (lhs.incoming.items.len != 4 or rhs.incoming.items.len != 4) return false;
    for (lhs.incoming.items, 0..) |incoming, incoming_index| {
        if (!isFullDefinedScalarPhiValue(incoming.value) or function.blockIndex(incoming.block) == null) return false;
        for (lhs.incoming.items[0..incoming_index]) |previous| {
            if (std.mem.eql(u8, previous.block, incoming.block)) return false;
        }
        const other = phiIncomingFrom(rhs, incoming.block) orelse return false;
        if (!isFullDefinedScalarPhiValue(other.value)) return false;
    }
    for (rhs.incoming.items, 0..) |incoming, incoming_index| {
        if (function.blockIndex(incoming.block) == null) return false;
        for (rhs.incoming.items[0..incoming_index]) |previous| {
            if (std.mem.eql(u8, previous.block, incoming.block)) return false;
        }
    }
    return true;
}

fn isFullDefinedScalarPhiValue(value: ir.Value) bool {
    return switch (value) {
        .named, .int => true,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn lowerExactFrexpSwitchPhiEdge(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    switch_term: ir.SwitchTerminator,
    case_values: []const i32,
    case_target_indices: []const usize,
    default_index: usize,
) !?Diagnostic {
    const predecessor = function.blocks.items[block_index].name;
    const all_ones_case_index = for (case_values, 0..) |value, index| {
        if (value == switchValueMask(11)) break index;
    } else unreachable;
    const phi_target = function.blocks.items[case_target_indices[all_ones_case_index]];

    if (selector.stack_frame_bytes != 0) {
        selector_state.spillLiveValuesForCfgBoundary(selector) catch return .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
    }
    const previous_preserve_current = selector.preserve_current_position_values;
    selector.preserve_current_position_values = true;
    defer selector.preserve_current_position_values = previous_preserve_current;
    if (try stabilizePhiEdgeSources(selector, phi_target, predecessor)) |diagnostic| return diagnostic;

    selector_state.emitValueIntoEax(selector, switch_term.cond) catch return .{ .unsupported_value = "stage2-switch-cond" };
    try selector_state.emitEflagsInstruction(selector, .{ .and_eax_imm32 = switchValueMask(11) }, .write);
    const phi_edge_label = try ownedEdgeLabel(selector);
    for (switch_term.cases.items, case_values, 0..) |case, value, case_index| {
        try selector_state.emitEflagsInstruction(selector, .{ .cmp_eax_imm32 = value }, .definition);
        try selector_state.emitEflagsInstruction(selector, .{ .je = if (case_index == all_ones_case_index) phi_edge_label else case.target }, .use);
    }
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = function.blocks.items[default_index].name });
    try selector.machine.instructions.append(selector.allocator, .{ .label = phi_edge_label });
    if (try emitPhiEdgeMoves(selector, phi_target, predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = phi_target.name });
    return null;
}

fn isExactEiEntrySwitchPhiShape(
    allocator: std.mem.Allocator,
    function: ir.Function,
    block_index: usize,
    switch_term: ir.SwitchTerminator,
    case_values: []const i32,
    case_target_indices: []const usize,
    default_index: usize,
) !bool {
    if (block_index != 0 or !switch_term.cond_ty.eql(.{ .int = 16 }) or case_values.len != 5 or case_target_indices.len != 5) return false;

    var switch_count: usize = 0;
    for (function.blocks.items) |block| {
        switch (block.terminator orelse return false) {
            .@"switch" => switch_count += 1,
            .indirectbr => return false,
            .ret, .br, .condbr, .@"unreachable" => {},
        }
    }
    if (switch_count != 1) return false;

    var ordered_targets: [5]?usize = .{ null, null, null, null, null };
    for (case_values, case_target_indices) |value, target_index| {
        if (value < 0 or value > 4) return false;
        const value_index: usize = @intCast(value);
        if (ordered_targets[value_index] != null) return false;
        ordered_targets[value_index] = target_index;
    }
    for (ordered_targets) |target| if (target == null) return false;

    for (ordered_targets, 0..) |target, index| {
        if (target.? == default_index) return false;
        for (ordered_targets[0..index]) |previous| {
            if (previous.? == target.?) return false;
        }
    }

    const predecessor = function.blocks.items[block_index].name;
    const return_index = ordered_targets[0].?;
    const return_block = function.blocks.items[return_index];
    if (blockHasPhiIncomingFrom(function.blocks.items[default_index], predecessor)) return false;
    for (ordered_targets[1..]) |target| {
        if (blockHasPhiIncomingFrom(function.blocks.items[target.?], predecessor)) return false;
    }

    var return_phi: ?ir.PhiInst = null;
    var return_result: ?[]const u8 = null;
    var non_removed_instructions: usize = 0;
    for (return_block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        non_removed_instructions += 1;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => return false,
        };
        if (return_phi != null) return false;
        return_phi = phi;
        return_result = instruction.result orelse return false;
    }
    if (non_removed_instructions != 1) return false;
    const phi = return_phi orelse return false;
    const result_name = return_result orelse return false;
    if ((!phi.ty.eql(.half) and !phi.ty.eql(.float) and !phi.ty.eql(.double)) or
        !function.ret_ty.eql(phi.ty) or phi.incoming.items.len != 6) return false;
    const ret = switch (return_block.terminator orelse return false) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!ret.ty.eql(phi.ty) or ret.value == null or ret.value.? != .named or !std.mem.eql(u8, ret.value.?.named, result_name)) return false;

    var six_way_scalar_phi_count: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            const candidate = instruction.kind.phi;
            if (candidate.incoming.items.len == 6 and (candidate.ty.eql(.half) or candidate.ty.eql(.float) or candidate.ty.eql(.double))) {
                six_way_scalar_phi_count += 1;
            }
        }
    }
    if (six_way_scalar_phi_count != 1) return false;

    const entry_incoming = phiIncomingFrom(phi, predecessor) orelse return false;
    if (!isExactPositiveFpZero(entry_incoming.value, phi.ty)) return false;

    var known_predecessors: [5][]const u8 = undefined;
    known_predecessors[0] = predecessor;
    for (ordered_targets[1..], 1..) |target, index| {
        const case_block = function.blocks.items[target.?];
        known_predecessors[index] = case_block.name;
        const incoming = phiIncomingFrom(phi, case_block.name) orelse return false;
        if (incoming.value != .named) return false;
        const terminator = case_block.terminator orelse return false;
        if (terminator != .br or !std.mem.eql(u8, terminator.br.target, return_block.name)) return false;
    }

    var default_join_predecessor: ?usize = null;
    for (phi.incoming.items, 0..) |incoming, incoming_index| {
        _ = function.blockIndex(incoming.block) orelse return false;
        for (phi.incoming.items[0..incoming_index]) |previous| {
            if (std.mem.eql(u8, previous.block, incoming.block)) return false;
        }
        var known = false;
        for (known_predecessors) |name| {
            if (std.mem.eql(u8, name, incoming.block)) {
                known = true;
                break;
            }
        }
        if (known) continue;
        if (incoming.value != .named or default_join_predecessor != null) return false;
        default_join_predecessor = function.blockIndex(incoming.block) orelse return false;
    }
    const default_predecessor_index = default_join_predecessor orelse return false;
    const default_predecessor = function.blocks.items[default_predecessor_index];
    const default_terminator = default_predecessor.terminator orelse return false;
    if (default_terminator != .br or !std.mem.eql(u8, default_terminator.br.target, return_block.name)) return false;
    if (blockIsPlainUnreachable(function.blocks.items[default_index])) return false;
    return try blockCanReachViaOwnedBranches(allocator, function, default_index, default_predecessor_index);
}

fn isExactPositiveFpZero(value: ir.Value, ty: ir.Type) bool {
    if (value != .fp) return false;
    if (ty.eql(.half)) return std.mem.eql(u8, value.fp, "0xH0000");
    if (ty.eql(.float) or ty.eql(.double)) return std.mem.eql(u8, value.fp, "0.000000e+00");
    return false;
}

fn blockCanReachViaOwnedBranches(allocator: std.mem.Allocator, function: ir.Function, start_index: usize, target_index: usize) !bool {
    const count = function.blocks.items.len;
    if (count > stage2_max_blocks or start_index >= count or target_index >= count) return false;
    var graph = cfg.Graph.build(allocator, function) catch |err| {
        if (err == error.UnknownBlock or err == error.DuplicateBlock) return false;
        return err;
    };
    defer graph.deinit();
    const seen = try allocator.alloc(bool, count);
    defer allocator.free(seen);
    @memset(seen, false);
    const queue = try allocator.alloc(usize, count);
    defer allocator.free(queue);
    var read_index: usize = 0;
    var write_index: usize = 1;
    queue[0] = start_index;
    seen[start_index] = true;

    while (read_index < write_index) : (read_index += 1) {
        const block_index = queue[read_index];
        if (block_index == target_index) return true;
        const terminator = function.blocks.items[block_index].terminator orelse return false;
        switch (terminator) {
            .br, .condbr => {},
            .ret, .@"unreachable" => continue,
            .@"switch", .indirectbr => return false,
        }
        for (graph.successors(block_index)) |next| if (!seen[next]) {
            if (write_index == queue.len) return false;
            seen[next] = true;
            queue[write_index] = next;
            write_index += 1;
        };
    }
    return false;
}

fn lowerExactEiEntrySwitchPhiEdges(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    switch_term: ir.SwitchTerminator,
    case_values: []const i32,
    case_target_indices: []const usize,
    default_index: usize,
) !?Diagnostic {
    const predecessor = function.blocks.items[block_index].name;
    if (selector.stack_frame_bytes != 0) {
        selector_state.spillLiveValuesForCfgBoundary(selector) catch return .{ .no_spill_envelope = "stage2-cfg-boundary-spill" };
    }

    const previous_preserve_current = selector.preserve_current_position_values;
    selector.preserve_current_position_values = true;
    defer selector.preserve_current_position_values = previous_preserve_current;
    for (case_target_indices) |target_index| {
        if (try stabilizePhiEdgeSources(selector, function.blocks.items[target_index], predecessor)) |diagnostic| return diagnostic;
    }
    if (try stabilizePhiEdgeSources(selector, function.blocks.items[default_index], predecessor)) |diagnostic| return diagnostic;

    selector_state.emitValueIntoEax(selector, switch_term.cond) catch return .{ .unsupported_value = "stage2-switch-cond" };
    try selector_state.emitEflagsInstruction(selector, .{ .and_eax_imm32 = switchValueMask(16) }, .write);

    var case_edge_labels: [5][]const u8 = undefined;
    for (&case_edge_labels) |*label| label.* = try ownedEdgeLabel(selector);
    const default_edge_label = try ownedEdgeLabel(selector);
    for (case_values, case_edge_labels) |value, edge_label| {
        try selector_state.emitEflagsInstruction(selector, .{ .cmp_eax_imm32 = value }, .definition);
        try selector_state.emitEflagsInstruction(selector, .{ .je = edge_label }, .use);
    }
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = default_edge_label });

    for (case_target_indices, case_edge_labels) |target_index, edge_label| {
        const target = function.blocks.items[target_index];
        try selector.machine.instructions.append(selector.allocator, .{ .label = edge_label });
        if (try emitPhiEdgeMoves(selector, target, predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = target.name });
    }
    const default_target = function.blocks.items[default_index];
    try selector.machine.instructions.append(selector.allocator, .{ .label = default_edge_label });
    if (try emitPhiEdgeMoves(selector, default_target, predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = default_target.name });
    return null;
}

fn maskedSwitchExhaustiveCaseIndex(function: ir.Function, switch_term: ir.SwitchTerminator, bits: u16, case_values: []const i32) ?usize {
    if (bits < 2 or bits > 32 or case_values.len != 4) return null;
    const cond_name = switch (switch_term.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const producer = instructionByResult(function, cond_name) orelse return null;
    const binary = switch (producer.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .@"and" or !binary.ty.eql(switch_term.cond_ty)) return null;
    const mask = switch (binary.rhs) {
        .int => |value| value,
        else => switch (binary.lhs) {
            .int => |value| value,
            else => return null,
        },
    };
    if ((switchCaseValue(mask, bits) orelse return null) != 3) return null;

    var seen: u4 = 0;
    var final_case: ?usize = null;
    for (case_values, 0..) |value, case_index| {
        if (value < 0 or value > 3) return null;
        const bit: u4 = @as(u4, 1) << @intCast(value);
        if (seen & bit != 0) return null;
        seen |= bit;
        if (value == 3) final_case = case_index;
    }
    if (seen != 0b1111) return null;
    const default_index = function.blockIndex(switch_term.default_target) orelse return null;
    if (!blockIsPlainUnreachable(function.blocks.items[default_index])) return null;
    return final_case;
}

fn switchCaseValue(value: i128, bits: u16) ?i32 {
    if (bits == 0 or bits > 32) return null;
    if (bits == 32) return i32Value(value) catch null;
    const raw = i64Value(value) catch return null;
    const pattern: u64 = @bitCast(raw);
    return @intCast(pattern & @as(u32, @bitCast(switchValueMask(bits))));
}

fn switchValueMask(bits: u16) i32 {
    std.debug.assert(bits > 0 and bits < 32);
    const shift: u5 = @intCast(bits);
    return @bitCast((@as(u32, 1) << shift) - 1);
}

fn instructionByResult(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, name)) return instruction;
            }
        }
    }
    return null;
}

fn blockIsPlainUnreachable(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (!instruction.removed) return false;
    }
    const terminator = block.terminator orelse return false;
    return terminator == .@"unreachable";
}

fn isExclusivelyProvenMaskedSwitchDefault(function: ir.Function, target: []const u8) bool {
    var proven_default = false;
    for (function.blocks.items) |block| {
        const terminator = block.terminator orelse continue;
        switch (terminator) {
            .br => |br| if (std.mem.eql(u8, br.target, target)) return false,
            .condbr => |condbr| if (std.mem.eql(u8, condbr.then_target, target) or std.mem.eql(u8, condbr.else_target, target)) return false,
            .@"switch" => |switch_term| {
                for (switch_term.cases.items) |case| {
                    if (std.mem.eql(u8, case.target, target)) return false;
                }
                if (!std.mem.eql(u8, switch_term.default_target, target)) continue;
                const bits = intBits(switch_term.cond_ty) orelse return false;
                var values: [max_compare_chain_switch_cases]i32 = undefined;
                if (switch_term.cases.items.len > values.len) return false;
                for (switch_term.cases.items, 0..) |case, index| {
                    if (case.value != .int) return false;
                    values[index] = switchCaseValue(case.value.int, bits) orelse return false;
                }
                if (maskedSwitchExhaustiveCaseIndex(function, switch_term, bits, values[0..switch_term.cases.items.len]) == null) return false;
                proven_default = true;
            },
            .indirectbr => |indirectbr| for (indirectbr.targets.items) |indirect_target| {
                if (std.mem.eql(u8, indirect_target, target)) return false;
            },
            .ret, .@"unreachable" => {},
        }
    }
    return proven_default;
}

pub fn restoreDisplacedPhiDestinations(selector: *ComposedBlockSelector) !?Diagnostic {
    var it = selector.phi_destinations.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        if (!try selector_state.valueIsLiveAfterCurrent(selector, name)) continue;
        const destination = entry.value_ptr.*;
        const actual = selector_state.valueLoc(selector, name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        if (valueLocEql(actual, destination)) continue;
        const bits = selector_state.valueBits(selector, name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        selector_state.materializeLocIntoLocWithBits(selector, actual, destination, bits) catch return .{ .no_emitter = "stage2-phi-restore-loc" };
        try selector_state.bindValueLoc(selector, name, destination);
    }
    return null;
}

pub fn lowerConditionalPhiEdges(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    then_index: usize,
    else_index: usize,
) !?Diagnostic {
    const predecessor = function.blocks.items[block_index].name;
    const then_target = function.blocks.items[then_index].name;
    const else_target = function.blocks.items[else_index].name;
    const then_edge_label = try ownedEdgeLabel(selector);

    if (try stabilizePhiEdgeSources(selector, function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
    if (try stabilizePhiEdgeSources(selector, function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .{ .jne = then_edge_label }, .use);

    if (try emitPhiEdgeMoves(selector, function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = else_target });

    try selector.machine.instructions.append(selector.allocator, .{ .label = then_edge_label });
    if (try emitPhiEdgeMoves(selector, function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = then_target });

    return null;
}

pub fn ownedEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_phi_edge_{d}", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    selector.edge_label_count += 1;
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

pub fn ownedSelectEndLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_{d}_generic_cfg_select_end", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    selector.edge_label_count += 1;
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

pub fn ownedReturnEpilogueLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try selector.allocator.dupe(u8, "__zllvm_stage2_return_generic_cfg_select_end");
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

pub fn emitPhiEdgeMoves(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !?Diagnostic {
    const previous_preserve_current = selector.preserve_current_position_values;
    selector.preserve_current_position_values = true;
    defer selector.preserve_current_position_values = previous_preserve_current;
    const parallel_scalars = try emitParallelScalarPhiEdge(selector, target, predecessor);
    if (!parallel_scalars) if (try stabilizePhiEdgeSources(selector, target, predecessor)) |diagnostic| return diagnostic;
    var scalar_snapshots: std.ArrayList(ScalarPhiSnapshot) = .empty;
    defer scalar_snapshots.deinit(selector.allocator);
    if (!parallel_scalars) if (try snapshotScalarPhiSources(selector, target, predecessor, &scalar_snapshots)) |diagnostic| return diagnostic;
    var xmm_snapshots: std.ArrayList(XmmPhiSnapshot) = .empty;
    defer xmm_snapshots.deinit(selector.allocator);
    if (!parallel_scalars) if (try snapshotXmmPhiSources(selector, target, predecessor, &xmm_snapshots)) |diagnostic| return diagnostic;
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        const dst = selector.phi_destinations.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
        if (parallel_scalars) {
            // All source reads and destination writes complete before any
            // PHI result identity is rebound, including loop-carried swaps.
        } else if (scalarPhiSnapshot(&scalar_snapshots, result_name)) |snapshot| {
            materializeScalarPhiSnapshot(selector, snapshot.loc, dst, metadata.bits) catch return .{ .unsupported_value = "stage2-phi-src" };
        } else if (xmmPhiSnapshot(&xmm_snapshots, result_name)) |snapshot| {
            selector_state.materializeLocIntoLoc(selector, .{ .xmm = snapshot.loc }, dst) catch return .{ .unsupported_value = "stage2-phi-src" };
        } else if (try emitValueIntoLoc(selector, incoming.value, dst, result_name, metadata.bits)) |diagnostic| return diagnostic;
        try selector_state.bindValueLoc(selector, result_name, dst);
        switch (dst) {
            .scratch32, .scratch64, .xmm, .spill64, .spill128, .spill_fp, .spill_vector => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
    }
    return null;
}

fn emitParallelScalarPhiEdge(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !bool {
    var count: usize = 0;
    // Keep pair, vector and spill destinations in their existing envelopes.
    // Register scalar edges use the same transaction as call argument moves.
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const bits = intBits(phi.ty) orelse return false;
        if (bits == 0 or bits > 64) return false;
        const name = instruction.result orelse return false;
        const destination = selector.phi_destinations.get(name) orelse return false;
        if (destination != .scratch32 and destination != .scratch64) return false;
        const incoming = phiIncomingFrom(phi, predecessor) orelse return false;
        if (incoming.value != .named and incoming.value != .int) return false;
        count += 1;
        if (count > ValueUseTransaction.max_requests) return false;
    }
    if (count == 0) return false;
    var transfer = try ValueUseTransaction.begin(selector);
    defer transfer.deinit();
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const destination = selector.phi_destinations.get(instruction.result.?).?;
        const narrow = intBits(phi.ty).? <= 32;
        _ = try transfer.register(.{
            .source = phiIncomingFrom(phi, predecessor).?.value,
            .expected = .{ .ty = phi.ty, .register_class = if (narrow) .gpr32 else .gpr64 },
            .form = if (narrow) .gpr32 else .gpr64,
            .destination = switch (destination) {
                .scratch32 => |reg| .{ .gpr32 = reg },
                .scratch64 => |reg| .{ .gpr64 = reg },
                else => unreachable,
            },
        });
    }
    try transfer.seal();
    try transfer.prepare();
    try transfer.materializeAll();
    try transfer.commit();
    return true;
}

const ScalarPhiSnapshot = struct {
    result_name: []const u8,
    loc: ValueLoc,
};

fn snapshotScalarPhiSources(
    selector: *ComposedBlockSelector,
    target: ir.BasicBlock,
    predecessor: []const u8,
    snapshots: *std.ArrayList(ScalarPhiSnapshot),
) !?Diagnostic {
    var unavailable: [selector_allocatable_regs.len]bool = @splat(false);
    var earlier_writes: std.ArrayList(ValueLoc) = .empty;
    defer earlier_writes.deinit(selector.allocator);
    var pointer_snapshot_names = std.StringHashMap(void).init(selector.allocator);
    defer pointer_snapshot_names.deinit();
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        if (selector.phi_destinations.get(result_name)) |destination| markScalarLocRegsUnavailable(destination, &unavailable);
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        const source = selector_state.resolveValue(selector, incoming.value);
        if (source) |loc| {
            markScalarLocRegsUnavailable(loc, &unavailable);
            if (phi.ty == .ptr) for (earlier_writes.items) |written| {
                if (scalarLocsOverlap(loc, written)) {
                    try pointer_snapshot_names.put(result_name, {});
                    break;
                }
            };
        }
        if (selector.phi_destinations.get(result_name)) |destination| {
            if (source == null or !valueLocEql(source.?, destination))
                try earlier_writes.append(selector.allocator, destination);
        }
    }

    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
        if (metadata.class != .gpr128 or intBits(phi.ty) == null) continue;
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        if (incoming.value != .named) continue;
        const source = selector_state.resolveValue(selector, incoming.value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) };
        if (!scalarSourceOverlapsPhiDestination(selector, target, source)) continue;
        const pair = for (selector_allocatable_pairs) |candidate| {
            const lo = argRegIndex(candidate.lo);
            const hi = argRegIndex(candidate.hi);
            if (unavailable[lo] or unavailable[hi]) continue;
            unavailable[lo] = true;
            unavailable[hi] = true;
            break candidate;
        } else return .{ .no_spill_envelope = "stage2-phi-scalar-snapshot" };
        const loc: ValueLoc = .{ .scratch128 = pair };
        selector_state.materializeLocIntoLocWithBits(selector, source, loc, metadata.bits) catch return .{ .unsupported_value = "stage2-phi-src" };
        try snapshots.append(selector.allocator, .{
            .result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" },
            .loc = loc,
        });
    }

    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
        if ((metadata.class != .gpr32 and metadata.class != .gpr64) or (phi.ty != .ptr and intBits(phi.ty) == null)) continue;
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        if (incoming.value != .named) continue;
        const source = selector_state.resolveValue(selector, incoming.value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) };
        if (phi.ty == .ptr and !pointer_snapshot_names.contains(instruction.result.?)) continue;
        if (!scalarSourceOverlapsPhiDestination(selector, target, source)) continue;
        const reg = for (selector_allocatable_regs) |candidate| {
            const index = argRegIndex(candidate);
            if (unavailable[index]) continue;
            unavailable[index] = true;
            break candidate;
        } else return .{ .no_spill_envelope = "stage2-phi-scalar-snapshot" };
        const loc: ValueLoc = if (metadata.class == .gpr64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
        selector_state.materializeLocIntoLocWithBits(selector, source, loc, metadata.bits) catch return .{ .unsupported_value = "stage2-phi-src" };
        try snapshots.append(selector.allocator, .{
            .result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" },
            .loc = loc,
        });
    }
    return null;
}

fn markScalarLocRegsUnavailable(loc: ValueLoc, unavailable: *[selector_allocatable_regs.len]bool) void {
    switch (loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| unavailable[argRegIndex(reg)] = true,
        .arg128, .scratch128 => |pair| {
            unavailable[argRegIndex(pair.lo)] = true;
            unavailable[argRegIndex(pair.hi)] = true;
        },
        .readonly_table_ptr => |ptr| switch (ptr.storage) {
            .reg => |reg| unavailable[argRegIndex(reg)] = true,
            .spill => {},
        },
        .eax, .rax, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {},
    }
}

fn scalarSourceOverlapsPhiDestination(selector: *ComposedBlockSelector, target: ir.BasicBlock, source: ValueLoc) bool {
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => {},
            else => break,
        }
        const result_name = instruction.result orelse continue;
        const destination = selector.phi_destinations.get(result_name) orelse continue;
        if (scalarLocsOverlap(source, destination)) return true;
    }
    return false;
}

fn scalarLocsOverlap(lhs: ValueLoc, rhs: ValueLoc) bool {
    if (valueLocEql(lhs, rhs)) return true;
    return switch (lhs) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| locContainsReg(rhs, reg),
        .arg128, .scratch128 => |pair| locContainsReg(rhs, pair.lo) or locContainsReg(rhs, pair.hi),
        .eax, .rax => rhs == .eax or rhs == .rax,
        .spill64 => |frame| switch (rhs) {
            .spill64 => |other| frame.eql(other),
            .spill128 => |pair| frame.eql(pair.lo) or frame.eql(pair.hi),
            else => false,
        },
        .spill128 => |pair| switch (rhs) {
            .spill64 => |frame| frame.eql(pair.lo) or frame.eql(pair.hi),
            .spill128 => |other| pair.lo.eql(other.lo) or pair.lo.eql(other.hi) or pair.hi.eql(other.lo) or pair.hi.eql(other.hi),
            else => false,
        },
        .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill_fp, .spill_vector, .aggregate_sse => false,
    };
}

fn scalarPhiSnapshot(snapshots: *const std.ArrayList(ScalarPhiSnapshot), result_name: []const u8) ?ScalarPhiSnapshot {
    for (snapshots.items) |snapshot| {
        if (std.mem.eql(u8, snapshot.result_name, result_name)) return snapshot;
    }
    return null;
}

fn materializeScalarPhiSnapshot(selector: *ComposedBlockSelector, source: ValueLoc, destination: ValueLoc, bits: u16) !void {
    switch (source) {
        .scratch32 => |reg| switch (destination) {
            .spill64 => |frame_index| {
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
            },
            else => try selector_state.materializeLocIntoLocWithBits(selector, source, destination, bits),
        },
        .scratch64 => |reg| switch (destination) {
            .spill64 => |frame_index| {
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
            },
            else => try selector_state.materializeLocIntoLocWithBits(selector, source, destination, bits),
        },
        .scratch128 => |pair| switch (destination) {
            .spill128 => |spill| {
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = spill.hi });
            },
            else => try selector_state.materializeLocIntoLocWithBits(selector, source, destination, bits),
        },
        else => return error.UnsupportedCodegenValue,
    }
}

const XmmPhiSnapshot = struct {
    result_name: []const u8,
    loc: selector_types.XmmValueLoc,
};

fn snapshotXmmPhiSources(
    selector: *ComposedBlockSelector,
    target: ir.BasicBlock,
    predecessor: []const u8,
    snapshots: *std.ArrayList(XmmPhiSnapshot),
) !?Diagnostic {
    var unavailable: [selector_types.selector_allocatable_xmm_regs.len]bool = @splat(false);
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        if (selector.phi_destinations.get(result_name)) |dst| switch (dst) {
            .xmm => |fp| unavailable[xmmRegIndex(fp.reg)] = true,
            else => {},
        };
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        if (selector_state.resolveValue(selector, incoming.value)) |source| switch (source) {
            .xmm => |fp| unavailable[xmmRegIndex(fp.reg)] = true,
            else => {},
        };
    }

    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
        if (metadata.class != .fp32 and metadata.class != .fp64 and metadata.class != .vector_xmm) continue;
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        if (incoming.value != .named) continue;
        const reg = for (selector_types.selector_allocatable_xmm_regs) |candidate| {
            const index = xmmRegIndex(candidate);
            if (unavailable[index]) continue;
            unavailable[index] = true;
            break candidate;
        } else return .{ .no_spill_envelope = "stage2-phi-fp-snapshot" };
        const source = selector_state.resolveValue(selector, incoming.value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) };
        const snapshot_loc: selector_types.XmmValueLoc = switch (metadata.class) {
            .fp32, .fp64 => .{ .reg = reg, .bits = metadata.bits },
            .vector_xmm => blk: {
                const shape = switch (source) {
                    .xmm => |loc| loc.vectorShape() orelse return .{ .unsupported_value = "stage2-phi-src" },
                    .spill_vector => |loc| loc.shape,
                    else => return .{ .unsupported_value = "stage2-phi-src" },
                };
                if (!shape.eql(selector_types.VectorShape.f64x2(0b11))) return .{ .unsupported_value = "stage2-phi-src" };
                break :blk .{ .reg = reg, .bits = 128, .shape = .{ .vector = shape } };
            },
            else => unreachable,
        };
        selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = snapshot_loc }) catch return .{ .unsupported_value = "stage2-phi-src" };
        try snapshots.append(selector.allocator, .{ .result_name = result_name, .loc = snapshot_loc });
    }
    return null;
}

fn xmmPhiSnapshot(snapshots: *const std.ArrayList(XmmPhiSnapshot), result_name: []const u8) ?XmmPhiSnapshot {
    for (snapshots.items) |snapshot| {
        if (std.mem.eql(u8, snapshot.result_name, result_name)) return snapshot;
    }
    return null;
}

fn stabilizePhiEdgeSources(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !?Diagnostic {
    for (target.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const phi = switch (instruction.kind) {
            .phi => |phi| phi,
            else => break,
        };
        const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
        const name = switch (incoming.value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
        };
        const loc = selector_state.valueLoc(selector, name) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) };
        switch (loc) {
            .arg32, .arg64, .scratch32, .scratch64, .eax, .rax => if (try selector_state.spillValue(selector, name)) |diagnostic| return diagnostic,
            .arg128, .scratch128 => if (try selector_state.spillPairValue(selector, name)) |diagnostic| return diagnostic,
            .spill64, .spill128, .spill_fp, .spill_vector, .stack_f32_pair_ptr => {},
            .xmm => if (try selector_state.spillValue(selector, name)) |diagnostic| return diagnostic,
            .stack_scalar, .stack128, .stack_i32_array => if (phi.ty != .ptr) return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) },
            .stack128_value, .stack_i32_ptr, .readonly_table_ptr, .aggregate_sse => return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, incoming.value) },
        }
    }
    return null;
}

pub fn emitValueIntoLoc(selector: *ComposedBlockSelector, value: ir.Value, dst: ValueLoc, ignore_name: []const u8, bits: u16) !?Diagnostic {
    _ = ignore_name;
    switch (dst) {
        .scratch32 => |reg| {
            switch (value) {
                .int => |int| {
                    try selector_state.clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                },
                .named => {
                    selector_state.emitPhiValueIntoScratch(selector, value, reg, 32) catch return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
            }
        },
        .scratch64 => |reg| {
            switch (value) {
                .int => |int| {
                    try selector_state.clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                },
                .named => {
                    selector_state.emitPhiValueIntoScratch(selector, value, reg, 64) catch return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
            }
        },
        .spill64 => |frame_index| switch (value) {
            .int => |int| {
                try selector_state.clobberAccumulator(selector);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                } else {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
                }
            },
            .named => {
                const actual = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
                selector_state.materializeLocIntoLocWithBits(selector, actual, dst, bits) catch return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
        },
        .spill128 => switch (value) {
            .named => {
                const actual = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
                selector_state.materializeLocIntoLocWithBits(selector, actual, dst, bits) catch return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
            },
            .int => |int| {
                if (bits != 128) return .{ .unsupported_value = "stage2-phi-src" };
                const raw: u128 = @bitCast(int);
                const lo: i64 = @bitCast(@as(u64, @truncate(raw)));
                const hi: i64 = @bitCast(@as(u64, @truncate(raw >> 64)));
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = lo });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = dst.spill128.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = hi });
                try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = dst.spill128.hi });
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
        },
        .xmm, .spill_fp, .spill_vector => switch (value) {
            .named => {
                const actual = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
                selector_state.materializeLocIntoLoc(selector, actual, dst) catch return .{ .unsupported_value = selector_state.phiSourceDiagnostic(selector, value) };
            },
            .fp => {
                const scratch = switch (dst) {
                    .xmm => |fp| fp.reg,
                    .spill_fp => .xmm0,
                    .spill_vector => return .{ .unsupported_value = "stage2-phi-src" },
                    else => unreachable,
                };
                if (try selector_fp.materializeFpValue(selector, value, scratch, bits)) |diagnostic| return diagnostic;
                if (dst == .spill_fp) {
                    selector_state.materializeLocIntoLoc(selector, .{ .xmm = .{ .reg = scratch, .bits = bits } }, dst) catch return .{ .unsupported_value = "stage2-phi-src" };
                }
            },
            .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
        },
        .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .aggregate_sse => return .{ .no_emitter = "stage2-phi-dst-loc" },
    }
    return null;
}

pub fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    var authority = try ValueUseTransaction.begin(selector);
    defer authority.deinit();
    const action = try authority.register(.{
        .source = value,
        .expected = .{ .ty = .{ .int = 1 }, .register_class = .gpr32 },
        .form = .branch_condition,
        .destination = .prepared_view,
        .prepared_action = .branch_condition,
    });
    authority.seal() catch |err| return branchConditionValueUseDiagnostic(err) orelse return err;
    authority.prepare() catch |err| return branchConditionValueUseDiagnostic(err) orelse return err;
    authority.materializeAll() catch |err| return branchConditionValueUseDiagnostic(err) orelse return err;
    authority.executePreparedAction(try authority.preparedView(action)) catch |err|
        return branchConditionValueUseDiagnostic(err) orelse return err;
    try authority.commit();
    return null;
}

fn branchConditionValueUseDiagnostic(err: anyerror) ?Diagnostic {
    return switch (err) {
        error.ValueUseUnsupportedSource,
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseUntypedNullPointer,
        error.ValueUsePreparedViewUnsupported,
        => .{ .unsupported_value = "stage2-unknown-cond" },
        error.ValueUseBranchConditionHomeUnsupported,
        error.ValueUseBranchConditionWidthMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        error.ValueUseSourceViewMismatch,
        => .{ .no_emitter = "stage2-cond-loc" },
        else => null,
    };
}
