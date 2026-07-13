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
const selector_fp = @import("composed_selector_fp.zig");
const selector_memory = @import("composed_selector_memory.zig");
const selector_calls = @import("composed_selector_calls.zig");
const selector_cfg = @import("composed_selector_cfg.zig");

pub const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const XmmReg = x86_64_types.XmmReg;
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
        composed.return_epilogue_label = try selector_cfg.ownedReturnEpilogueLabel(&composed);
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
        if (try selector_cfg.lowerCfgTerminator(&composed, function, block_index, terminator)) |diagnostic| {
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
    var gpr_index: usize = 0;
    var xmm_index: usize = 0;
    for (function.params.items) |param| {
        if (param.ty == .half or param.ty == .float or param.ty == .double) {
            const reg = XmmReg.fromIndex(xmm_index) catch return .{ .unsupported_value = "composed-block-param-xmm-reg" };
            const bits: u16 = if (param.ty == .half) 16 else if (param.ty == .float) 32 else 64;
            try selector_state.bindValueLoc(selector, param.name, .{ .xmm = .{ .reg = reg, .bits = bits } });
            xmm_index += 1;
            continue;
        }
        const reg = ArgReg.fromIndex(gpr_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
        if (param.ty == .ptr) {
            try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg });
        } else {
            const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
            switch (bits) {
                32 => try selector_state.bindValueLoc(selector, param.name, .{ .arg32 = reg }),
                64 => try selector_state.bindValueLoc(selector, param.name, .{ .arg64 = reg }),
                128 => {
                    const high = ArgReg.fromIndex(gpr_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                    try selector_state.bindValueLoc(selector, param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
                    gpr_index += 1;
                },
                else => return .{ .no_emitter = "composed-block-param-width" },
            }
        }
        gpr_index += 1;
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
            if (metadata.class == .fp16 or metadata.class == .fp32 or metadata.class == .fp64) {
                const assignment = selector.allocation_plan.?.assignment(result_name) orelse return .{ .unsupported_value = "stage2-phi-plan" };
                const destination: ValueLoc = switch (assignment) {
                    .fp16 => |reg| if (metadata.bits == 16) .{ .xmm = .{ .reg = reg, .bits = 16 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .fp32 => |reg| if (metadata.bits == 32) .{ .xmm = .{ .reg = reg, .bits = 32 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .fp64 => |reg| if (metadata.bits == 64) .{ .xmm = .{ .reg = reg, .bits = 64 } } else return .{ .no_emitter = "stage2-phi-width" },
                    .spill => |index| .{ .spill_fp = .{
                        .frame_index = selector_state.spillFrameIndexMaybe(index) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                        .bits = metadata.bits,
                    } },
                    else => return .{ .no_emitter = "stage2-phi-width" },
                };
                try selector.phi_results.put(result_name, {});
                try selector.phi_destinations.put(result_name, destination);
                try selector_state.bindValueLoc(selector, result_name, destination);
                continue;
            }
            const bits = switch (metadata.class) {
                .gpr32 => @as(u16, 32),
                .gpr64 => @as(u16, 64),
                .gpr128 => @as(u16, 128),
                .fp16, .fp32, .fp64, .stack_object, .stack_pointer => return .{ .no_emitter = "stage2-phi-width" },
            };
            const planned_spill = if (bits != 128 and selector.allocation_plan != null) switch (selector.allocation_plan.?.assignment(result_name) orelse return .{ .unsupported_value = "stage2-phi-plan" }) {
                .spill => |index| selector_state.spillFrameIndexMaybe(index) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" },
                .gpr32, .gpr64, .gpr128, .fp16, .fp32, .fp64, .stack_object, .stack_pointer => null,
            } else null;
            const destination: ValueLoc = if (bits == 128)
                .{ .spill128 = selector_state.allocatePairSpillSlots(selector, result_name) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } }
            else if (planned_spill) |frame_index|
                .{ .spill64 = frame_index }
            else if (nextPhiReg(&used_in_block)) |reg|
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
            .spill64, .spill128, .spill_fp => {},
            .arg32, .arg64, .scratch32, .scratch64, .eax, .rax => {
                if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .arg128, .scratch128 => {
                if (try selector_state.spillPairValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .xmm => if (try selector_state.spillValue(selector, param.name)) |diagnostic| return diagnostic,
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
            .scratch32, .scratch64, .xmm, .spill64, .spill128, .spill_fp => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr => return .{ .no_emitter = "stage2-phi-dst-loc" },
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
        .binary => |binary| if (binary.op == .fadd or binary.op == .fsub or binary.op == .fmul or binary.op == .fdiv)
            selector_fp.lowerFpBinary(selector, instruction.result, binary) catch |err| return instructionValueError(selector, err, "stage2-fp-binary-value")
        else
            selector_scalar.lowerBinary(selector, instruction.result, binary) catch |err| return instructionValueError(selector, err, "stage2-binary-value"),
        .alloca => |alloca| selector_memory.lowerAlloca(selector, instruction.result, alloca) catch |err| return instructionValueError(selector, err, "stage2-alloca-value"),
        .cast => |cast| if (cast.op == .fpext or cast.op == .fptrunc or (cast.op == .bitcast and selector_fp.isFpIntBitcast(cast)))
            selector_fp.lowerFpCast(selector, instruction.result, cast) catch |err| return instructionValueError(selector, err, "stage2-fp-cast-value")
        else
            selector_scalar.lowerCast(selector, instruction.result, cast) catch |err| return instructionValueError(selector, err, "stage2-cast-value"),
        .freeze => |freeze| selector_scalar.lowerFreeze(selector, instruction.result, freeze) catch |err| return instructionValueError(selector, err, "stage2-freeze-value"),
        .icmp => |icmp| selector_scalar.lowerIcmp(selector, instruction.result, icmp) catch |err| return instructionValueError(selector, err, "stage2-icmp-value"),
        .fcmp => |fcmp| selector_fp.lowerFcmp(selector, instruction.result, fcmp) catch |err| return instructionValueError(selector, err, "stage2-fcmp-value"),
        .load => |load| selector_memory.lowerLoad(selector, instruction.result, load) catch |err| return instructionValueError(selector, err, "stage2-load-value"),
        .store => |store| selector_memory.lowerStore(selector, store) catch |err| return instructionValueError(selector, err, "stage2-store-value"),
        .gep => |gep| selector_memory.lowerGep(selector, instruction.result, gep) catch |err| return instructionValueError(selector, err, "stage2-gep-value"),
        .call => |call| selector_calls.lowerCall(selector, instruction.result, call) catch |err| return instructionValueError(selector, err, "stage2-call-value"),
        .extractvalue => |extract| selector_calls.lowerExtractValue(selector, instruction.result, extract) catch |err| return instructionValueError(selector, err, "stage2-extractvalue-value"),
        .select => |select| selector_cfg.lowerSelect(selector, instruction.result, select) catch |err| return instructionValueError(selector, err, "stage2-select-value"),
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
            if (try selector_cfg.lowerReturn(&composed, ret)) |diagnostic| return unsupported(diagnostic);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    return .selected;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
