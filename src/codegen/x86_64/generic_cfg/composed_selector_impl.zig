const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_memory = @import("composed_selector_memory.zig");
const selector_calls = @import("composed_selector_calls.zig");

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

fn isColdAssumeBundle(bundle: []const u8) bool {
    return std.mem.eql(u8, std.mem.trim(u8, bundle, " \t"), "[ \"cold\"() ]");
}

fn blockEndsInTrap(block: ir.BasicBlock) bool {
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

pub fn tryLowerComposedCfg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "stage2-ret-type" });
    if (function.blocks.items.len == 0) return unsupported(.{ .unsupported_control_flow = "stage2-empty-function" });
    if (function.blocks.items.len > stage2_max_blocks) return unsupported(.{ .no_spill_envelope = "stage2-block-count" });

    var allocation_plan = try buildSelectorAllocationPlan(allocator, function);
    defer allocation_plan.deinit();

    const start_len = machine.instructions.items.len;
    var composed = ComposedBlockSelector.init(allocator, machine);
    composed.allocation_plan = &allocation_plan;
    composed.next_spill_slot = allocation_plan.spill_slots;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();

    if (try bindParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try bindPhiResults(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try selector_frame.prepareStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try stabilizeFramedParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (composed.stack_frame_bytes != 0) {
        composed.return_epilogue_label = try ownedReturnEpilogueLabel(&composed);
    }

    for (function.blocks.items, 0..) |block, block_index| {
        if (block_index != 0) try machine.instructions.append(allocator, .{ .label = block.name });
        if (try enterBlock(&composed, block)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        for (block.instructions.items) |instruction| {
            if (try lowerInstruction(&composed, instruction)) |diagnostic| {
                machine.instructions.items.len = start_len;
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            machine.instructions.items.len = start_len;
            return unsupported(.{ .unsupported_control_flow = "stage2-missing-terminator" });
        };
        try selector_state.expireExpiredBindings(&composed);
        if (try lowerCfgTerminator(&composed, function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        composed.current_position += 1;
    }
    if (composed.return_epilogue_label) |label| {
        try machine.instructions.append(allocator, .{ .label = label });
        try selector_frame.appendAddRsp(&composed, composed.stack_frame_bytes);
        try machine.instructions.append(allocator, .ret);
    }
    return .selected;
}

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

fn bindParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    if (function.params.items.len > 6) return .{ .unsupported_value = "composed-block-too-many-params" };
    var abi_index: usize = 0;
    for (function.params.items) |param| {
        const reg = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
        if (param.ty == .ptr) {
            try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg });
        } else {
            const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
            switch (bits) {
                32 => try selector_state.bindValueLoc(selector, param.name, .{ .arg32 = reg }),
                64 => try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg }),
                128 => {
                    const high = ArgReg.fromIndex(abi_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                    try selector_state.bindValueLoc(selector, param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
                    abi_index += 1;
                },
                else => return .{ .no_emitter = "composed-block-param-width" },
            }
        }
        abi_index += 1;
    }
    return null;
}

fn bindPhiResults(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    for (function.blocks.items) |block| {
        var used_in_block = [_]bool{false} ** phi_regs.len;
        for (block.instructions.items) |instruction| {
            if (instruction.removed or instruction.kind != .phi) continue;
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const phi = instruction.kind.phi;
            const metadata = selectorValueMetadata(phi.ty) orelse return .{ .no_emitter = "stage2-phi-type" };
            const bits = switch (metadata.class) {
                .gpr32 => @as(u16, 32),
                .gpr64 => @as(u16, 64),
                .gpr128, .stack_object, .stack_pointer => return .{ .no_emitter = "stage2-phi-width" },
            };
            const destination: ValueLoc = if (nextPhiReg(&used_in_block)) |reg|
                if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg }
            else
                .{ .spill64 = selector_state.allocateSpillSlot(selector, result_name) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } };
            try selector.phi_results.put(result_name, {});
            try selector.phi_destinations.put(result_name, destination);
            try selector_state.bindValueLoc(selector, result_name, destination);
        }
    }
    return null;
}

fn stabilizeFramedParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    if (function.blocks.items.len <= 1 or selector.stack_frame_bytes == 0) return null;
    for (function.params.items) |param| {
        const loc = selector_state.valueLoc(selector, param.name) orelse return .{ .unsupported_value = "stage2-param-home" };
        switch (loc) {
            .spill64, .spill128 => {},
            .arg32, .arg64, .scratch32, .scratch64, .eax, .rax => {
                if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .arg128, .scratch128 => {
                if (try selector_state.spillPairValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr => return .{ .unsupported_value = "stage2-param-home" },
        }
    }
    return null;
}

fn nextPhiReg(used_in_block: *[phi_regs.len]bool) ?ArgReg {
    for (phi_regs, 0..) |reg, index| {
        if (used_in_block[index]) continue;
        used_in_block[index] = true;
        return reg;
    }
    return null;
}

fn enterBlock(selector: *ComposedBlockSelector, block: ir.BasicBlock) !?Diagnostic {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => {},
            else => break,
        }
        const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
        const loc = selector.phi_destinations.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        try selector_state.bindValueLoc(selector, result_name, loc);
        switch (loc) {
            .scratch32, .scratch64, .spill64 => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
    }
    return null;
}

pub fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    if (instruction.removed) return null;
    try selector_state.expireExpiredBindings(selector);
    defer selector.current_position += 1;
    return switch (instruction.kind) {
        .phi => null,
        .binary => |binary| selector_scalar.lowerBinary(selector, instruction.result, binary) catch |err| return instructionValueError(selector, err, "stage2-binary-value"),
        .alloca => |alloca| selector_memory.lowerAlloca(selector, instruction.result, alloca) catch |err| return instructionValueError(selector, err, "stage2-alloca-value"),
        .cast => |cast| selector_scalar.lowerCast(selector, instruction.result, cast) catch |err| return instructionValueError(selector, err, "stage2-cast-value"),
        .freeze => |freeze| selector_scalar.lowerFreeze(selector, instruction.result, freeze) catch |err| return instructionValueError(selector, err, "stage2-freeze-value"),
        .icmp => |icmp| selector_scalar.lowerIcmp(selector, instruction.result, icmp) catch |err| return instructionValueError(selector, err, "stage2-icmp-value"),
        .load => |load| selector_memory.lowerLoad(selector, instruction.result, load) catch |err| return instructionValueError(selector, err, "stage2-load-value"),
        .store => |store| selector_memory.lowerStore(selector, store) catch |err| return instructionValueError(selector, err, "stage2-store-value"),
        .gep => |gep| selector_memory.lowerGep(selector, instruction.result, gep) catch |err| return instructionValueError(selector, err, "stage2-gep-value"),
        .call => |call| selector_calls.lowerCall(selector, instruction.result, call) catch |err| return instructionValueError(selector, err, "stage2-call-value"),
        .extractvalue => |extract| selector_calls.lowerExtractValue(selector, instruction.result, extract) catch |err| return instructionValueError(selector, err, "stage2-extractvalue-value"),
        .select => |select| lowerSelect(selector, instruction.result, select) catch |err| return instructionValueError(selector, err, "stage2-select-value"),
        else => .{ .no_emitter = "composed-block-instruction-not-owned" },
    };
}

fn instructionValueError(selector: *ComposedBlockSelector, err: anyerror, detail: []const u8) anyerror!?Diagnostic {
    _ = selector;
    return switch (err) {
        error.UnsupportedCodegenValue => .{ .unsupported_value = detail },
        else => err,
    };
}

fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (!select.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-select-cond" };
    const bits: u16 = if (select.ty.eql(.ptr)) 64 else intBits(select.ty) orelse return .{ .no_emitter = "composed-block-select-type" };
    if (bits == 0 or (bits > 32 and bits != 64)) return .{ .no_emitter = "composed-block-select-width" };

    if (try emitBranchCondition(selector, select.cond)) |diagnostic| return diagnostic;
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
    selector_state.emitValueIntoAccumulator(selector, select.false_value, bits) catch return .{ .unsupported_value = "composed-block-select-false-value" };
    const end_label = try ownedSelectEndLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .je = end_label });
    selector_state.emitValueIntoAccumulator(selector, select.true_value, bits) catch return .{ .unsupported_value = "composed-block-select-true-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
    try selector_state.bindAccumulator(selector, result_name, bits);
    return null;
}

fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
    if (ret.ty == .void) {
        if (ret.value != null) return .{ .unsupported_value = "composed-block-void-ret-value" };
        try emitReturnEpilogue(selector);
        return null;
    }
    const bits = intBits(ret.ty) orelse return .{ .no_emitter = "composed-block-ret-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-ret-width" };
    const value = ret.value orelse return .{ .unsupported_value = "composed-block-missing-ret-value" };
    switch (value) {
        .int => |int| switch (bits) {
            32 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) }),
            64 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) }),
            128 => return .{ .unsupported_value = "composed-block-ret-value" },
            else => unreachable,
        },
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

fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
    if (selector.return_epilogue_label) |label| {
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = label });
        return;
    }
    if (selector.stack_frame_bytes != 0) try selector_frame.appendAddRsp(selector, selector.stack_frame_bytes);
    try selector.machine.instructions.append(selector.allocator, .ret);
}

fn lowerCfgTerminator(
    selector: *ComposedBlockSelector,
    function: ir.Function,
    block_index: usize,
    terminator: ir.Terminator,
) !?Diagnostic {
    return switch (terminator) {
        .ret => |ret| blk: {
            if (try restoreDisplacedPhiDestinations(selector)) |diagnostic| break :blk diagnostic;
            break :blk try lowerReturn(selector, ret);
        },
        .br => |br| {
            const target_index = function.blockIndex(br.target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            if (!blockHasPhiIncomingFrom(function.blocks.items[target_index], function.blocks.items[block_index].name)) {
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
            const then_index = function.blockIndex(condbr.then_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            const else_index = function.blockIndex(condbr.else_target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
            const then_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[then_index], function.blocks.items[block_index].name);
            const else_has_phi_edge = blockHasPhiIncomingFrom(function.blocks.items[else_index], function.blocks.items[block_index].name);
            if (!then_has_phi_edge and !else_has_phi_edge) {
                if (try restoreDisplacedPhiDestinations(selector)) |diagnostic| return diagnostic;
            }
            const previous_preserve_current = selector.preserve_current_position_values;
            if (then_has_phi_edge or else_has_phi_edge) selector.preserve_current_position_values = true;
            defer selector.preserve_current_position_values = previous_preserve_current;
            if (try emitBranchCondition(selector, condbr.cond)) |diagnostic| return diagnostic;
            if (then_has_phi_edge or else_has_phi_edge) {
                return try lowerConditionalPhiEdges(selector, function, block_index, then_index, else_index);
            }
            try selector.machine.instructions.append(selector.allocator, .{ .jne = condbr.then_target });
            if (else_index != block_index + 1) {
                try selector.machine.instructions.append(selector.allocator, .{ .jmp = condbr.else_target });
            }
            return null;
        },
        .@"unreachable" => if (blockEndsInTrap(function.blocks.items[block_index])) null else .{ .no_emitter = "stage2-terminator-not-owned" },
        .@"switch", .indirectbr => .{ .no_emitter = "stage2-terminator-not-owned" },
    };
}

fn restoreDisplacedPhiDestinations(selector: *ComposedBlockSelector) !?Diagnostic {
    var it = selector.phi_destinations.iterator();
    while (it.next()) |entry| {
        const name = entry.key_ptr.*;
        const destination = entry.value_ptr.*;
        const actual = selector_state.valueLoc(selector, name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        if (valueLocEql(actual, destination)) continue;
        const bits = selector.values.get(name).?.vreg.bits;
        selector_state.materializeLocIntoLocWithBits(selector, actual, destination, bits) catch return .{ .no_emitter = "stage2-phi-restore-loc" };
        try selector_state.bindValueLoc(selector, name, destination);
    }
    return null;
}

fn lowerConditionalPhiEdges(
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

    try selector.machine.instructions.append(selector.allocator, .{ .jne = then_edge_label });

    if (try emitPhiEdgeMoves(selector, function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = else_target });

    try selector.machine.instructions.append(selector.allocator, .{ .label = then_edge_label });
    if (try emitPhiEdgeMoves(selector, function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = then_target });

    return null;
}

fn ownedEdgeLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_phi_edge_{d}", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    selector.edge_label_count += 1;
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

fn ownedSelectEndLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try std.fmt.allocPrint(selector.allocator, "__zllvm_stage2_{d}_generic_cfg_select_end", .{selector.edge_label_count});
    errdefer selector.allocator.free(label);
    selector.edge_label_count += 1;
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

fn ownedReturnEpilogueLabel(selector: *ComposedBlockSelector) ![]const u8 {
    const label = try selector.allocator.dupe(u8, "__zllvm_stage2_return_generic_cfg_select_end");
    errdefer selector.allocator.free(label);
    try selector.machine.owned_labels.append(selector.allocator, label);
    return label;
}

fn emitPhiEdgeMoves(selector: *ComposedBlockSelector, target: ir.BasicBlock, predecessor: []const u8) !?Diagnostic {
    const previous_preserve_current = selector.preserve_current_position_values;
    selector.preserve_current_position_values = true;
    defer selector.preserve_current_position_values = previous_preserve_current;
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
        if (try emitValueIntoLoc(selector, incoming.value, dst, result_name, metadata.bits)) |diagnostic| return diagnostic;
        try selector_state.bindValueLoc(selector, result_name, dst);
        switch (dst) {
            .scratch32, .scratch64, .spill64 => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
    }
    return null;
}

fn emitValueIntoLoc(selector: *ComposedBlockSelector, value: ir.Value, dst: ValueLoc, ignore_name: []const u8, bits: u16) !?Diagnostic {
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
        .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
    }
    return null;
}

fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    const loc = selector_state.resolveValue(selector, value) orelse return .{ .unsupported_value = "stage2-unknown-cond" };
    switch (loc) {
        .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
        .arg32, .scratch32 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = reg }),
        .spill64 => |frame_index| {
            try selector_state.clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = .rcx });
        },
        .arg64, .scratch64, .arg128, .scratch128, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-cond-loc" },
    }
    return null;
}

pub fn tryLowerComposedBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !SelectionResult {
    if (!isComposedReturnType(function.ret_ty)) return unsupported(.{ .no_emitter = "composed-block-ret-type" });
    if (function.blocks.items.len != 1) return unsupported(.{ .no_emitter = "composed-block-not-single-block" });

    var allocation_plan = try buildSelectorAllocationPlan(allocator, function);
    defer allocation_plan.deinit();

    var composed = ComposedBlockSelector.init(allocator, machine);
    composed.allocation_plan = &allocation_plan;
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();

    if (try bindParams(&composed, function)) |diagnostic| return unsupported(diagnostic);
    if (try selector_frame.prepareStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try lowerInstruction(&composed, instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    try selector_state.expireExpiredBindings(&composed);
    switch (terminator) {
        .ret => |ret| {
            if (try lowerReturn(&composed, ret)) |diagnostic| return unsupported(diagnostic);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    return .selected;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
