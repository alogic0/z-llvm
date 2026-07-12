const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");

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
    if (try prepareStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);
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
        try expireExpiredBindings(&composed);
        if (try lowerCfgTerminator(&composed, function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        composed.current_position += 1;
    }
    if (composed.return_epilogue_label) |label| {
        try machine.instructions.append(allocator, .{ .label = label });
        try appendAddRsp(&composed, composed.stack_frame_bytes);
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
            try bindValueLoc(selector, param.name, .{ .arg64 = reg });
        } else {
            const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
            switch (bits) {
                32 => try bindValueLoc(selector, param.name, .{ .arg32 = reg }),
                64 => try bindValueLoc(selector, param.name, .{ .arg64 = reg }),
                128 => {
                    const high = ArgReg.fromIndex(abi_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                    try bindValueLoc(selector, param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
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
                .{ .spill64 = allocateSpillSlot(selector, result_name) orelse return .{ .no_spill_envelope = "stage2-phi-spill-slots" } };
            try selector.phi_results.put(result_name, {});
            try selector.phi_destinations.put(result_name, destination);
            try bindValueLoc(selector, result_name, destination);
        }
    }
    return null;
}

fn stabilizeFramedParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    if (function.blocks.items.len <= 1 or selector.stack_frame_bytes == 0) return null;
    for (function.params.items) |param| {
        const loc = valueLoc(selector, param.name) orelse return .{ .unsupported_value = "stage2-param-home" };
        switch (loc) {
            .spill64, .spill128 => {},
            .arg32, .arg64, .scratch32, .scratch64, .eax, .rax => {
                if (try spillValue(selector, param.name)) |diagnostic| return diagnostic;
            },
            .arg128, .scratch128 => {
                if (try spillPairValue(selector, param.name)) |diagnostic| return diagnostic;
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
        try bindValueLoc(selector, result_name, loc);
        switch (loc) {
            .scratch32, .scratch64, .spill64 => {},
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
    }
    return null;
}

pub fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
    if (instruction.removed) return null;
    try expireExpiredBindings(selector);
    defer selector.current_position += 1;
    return switch (instruction.kind) {
        .phi => null,
        .binary => |binary| lowerBinary(selector, instruction.result, binary) catch |err| return instructionValueError(selector, err, "stage2-binary-value"),
        .alloca => |alloca| lowerAlloca(selector, instruction.result, alloca) catch |err| return instructionValueError(selector, err, "stage2-alloca-value"),
        .cast => |cast| lowerCast(selector, instruction.result, cast) catch |err| return instructionValueError(selector, err, "stage2-cast-value"),
        .freeze => |freeze| lowerFreeze(selector, instruction.result, freeze) catch |err| return instructionValueError(selector, err, "stage2-freeze-value"),
        .icmp => |icmp| lowerIcmp(selector, instruction.result, icmp) catch |err| return instructionValueError(selector, err, "stage2-icmp-value"),
        .load => |load| lowerLoad(selector, instruction.result, load) catch |err| return instructionValueError(selector, err, "stage2-load-value"),
        .store => |store| lowerStore(selector, store) catch |err| return instructionValueError(selector, err, "stage2-store-value"),
        .gep => |gep| lowerGep(selector, instruction.result, gep) catch |err| return instructionValueError(selector, err, "stage2-gep-value"),
        .call => |call| lowerCall(selector, instruction.result, call) catch |err| return instructionValueError(selector, err, "stage2-call-value"),
        .extractvalue => |extract| lowerExtractValue(selector, instruction.result, extract) catch |err| return instructionValueError(selector, err, "stage2-extractvalue-value"),
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

fn lowerAlloca(selector: *ComposedBlockSelector, result: ?[]const u8, alloca: ir.AllocaInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (valueLoc(selector, result_name)) |loc| switch (loc) {
        .stack_scalar, .stack128, .stack_i32_array => return null,
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => {},
    };
    if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
    if (alloca.allocated_ty.eql(.{ .int = 64 })) {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        try appendSubRsp(selector, 24);
        selector.stack_slot_allocated = true;
        selector.stack_frame_bytes = 24;
        try bindValueLoc(selector, result_name, .{ .stack_scalar = .{ .base_disp = 0, .bits = 64 } });
        return null;
    }
    if (alloca.allocated_ty.eql(.{ .int = 128 })) {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        const frame_bytes = stack128FrameBytes();
        try appendSubRsp(selector, frame_bytes);
        selector.stack_slot_allocated = true;
        selector.stack_frame_bytes = frame_bytes;
        try bindValueLoc(selector, result_name, .{ .stack128 = 0 });
        return null;
    }
    if (parseI32ArrayType(alloca.allocated_ty)) |len| {
        if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
        const payload_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        try appendSubRsp(selector, frame_bytes);
        selector.stack_array_allocated = true;
        selector.stack_frame_bytes = frame_bytes;
        try bindValueLoc(selector, result_name, .{ .stack_i32_array = .{ .base_disp = 0, .len = len } });
        return null;
    }
    return .{ .no_emitter = "composed-block-alloca-form" };
}

fn allocaAlignment(attrs: ?[]const u8, natural_alignment: u32) ?u32 {
    const text = attrs orelse return natural_alignment;
    var fields = std.mem.splitScalar(u8, text, ',');
    while (fields.next()) |raw_field| {
        const field = std.mem.trim(u8, raw_field, " \t");
        if (!std.mem.startsWith(u8, field, "align ")) continue;
        const alignment = std.fmt.parseUnsigned(u32, std.mem.trim(u8, field["align ".len..], " \t"), 10) catch return null;
        if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) return null;
        return @max(alignment, natural_alignment);
    }
    return natural_alignment;
}

pub fn prepareStackFrame(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
    var payload_bytes: u32 = 0;
    var scalar_slot_count: usize = 0;
    var array_count: usize = 0;
    var saw_phi = false;
    var saw_array_alloca = false;
    var saw_fixed_smul_overflow = false;
    var saw_wide_icmp = false;
    if (selector.allocation_plan) |plan| selector.next_spill_slot = @max(selector.next_spill_slot, plan.spill_slots);

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind == .phi) saw_phi = true;
            if (instruction.kind == .alloca and parseI32ArrayType(instruction.kind.alloca.allocated_ty) != null) saw_array_alloca = true;
            if (instruction.kind == .call and
                (std.mem.eql(u8, instruction.kind.call.callee, "llvm.smul.with.overflow.i64") or
                    std.mem.eql(u8, instruction.kind.call.callee, "llvm.smul.with.overflow.i128"))) saw_fixed_smul_overflow = true;
            if (instruction.kind == .icmp and instruction.kind.icmp.operand_ty.eql(.{ .int = 128 })) saw_wide_icmp = true;
        }
    }

    const pressure = try analyzeStageTwoNoSpillEnvelope(selector.allocator, function);
    const reserve_spill_area = pressure.exceedsNoSpill() or saw_phi or saw_fixed_smul_overflow or saw_wide_icmp or (selector.allocation_plan != null and selector.allocation_plan.?.spill_slots != 0);
    const spill_reserved_bytes = spillReservedBytes(selector, reserve_spill_area) orelse return .{ .no_spill_envelope = "composed-block-spill-frame-size" };
    payload_bytes = if (saw_array_alloca) @max(spill_reserved_bytes, stage2SpillReservedBytes()) else 0;

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.kind != .alloca) continue;
            const result_name = instruction.result orelse return .{ .unsupported_value = "composed-block-missing-result" };
            const alloca = instruction.kind.alloca;
            if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
            if (intBits(alloca.allocated_ty)) |bits| {
                if (bits != 8 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-alloca-form" };
                payload_bytes = @max(payload_bytes, spill_reserved_bytes);
                scalar_slot_count += 1;
                const natural_alignment: u32 = if (bits == 128) 16 else @max(@as(u32, 1), @as(u32, bits / 8));
                const alignment = allocaAlignment(alloca.attrs, natural_alignment) orelse return .{ .no_emitter = "composed-block-alloca-align" };
                payload_bytes = std.mem.alignForward(u32, payload_bytes, alignment);
                const base_disp = payload_bytes;
                const size: u32 = if (bits == 128) stack128FrameBytes() - 8 else @max(@as(u32, 1), @as(u32, bits / 8));
                payload_bytes = std.math.add(u32, payload_bytes, size) catch return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                if (bits == 128) {
                    try bindValueLoc(selector, result_name, .{ .stack128 = base_disp });
                } else {
                    try bindValueLoc(selector, result_name, .{ .stack_scalar = .{ .base_disp = base_disp, .bits = bits } });
                }
            } else if (parseI32ArrayType(alloca.allocated_ty)) |len| {
                array_count += 1;
                const alignment = allocaAlignment(alloca.attrs, 4) orelse return .{ .no_emitter = "composed-block-alloca-align" };
                payload_bytes = std.mem.alignForward(u32, payload_bytes, alignment);
                const array_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                const base_disp = payload_bytes;
                payload_bytes = std.math.add(u32, payload_bytes, array_bytes) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                try bindValueLoc(selector, result_name, .{ .stack_i32_array = .{ .base_disp = base_disp, .len = len } });
            } else {
                return .{ .no_emitter = "composed-block-alloca-form" };
            }
        }
    }

    if (payload_bytes == 0) {
        if (pressure.exceedsNoSpill() or saw_phi or saw_fixed_smul_overflow or saw_wide_icmp) payload_bytes = spill_reserved_bytes;
    }

    if (payload_bytes == 0) return null;
    const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
    try appendSubRsp(selector, frame_bytes);
    selector.stack_frame_bytes = frame_bytes;
    selector.stack_slot_allocated = scalar_slot_count != 0;
    selector.stack_array_allocated = array_count != 0;
    selector.stack_array_count = array_count;
    return null;
}

pub fn spillReservedBytes(selector: *const ComposedBlockSelector, reserve_spill_area: bool) ?u32 {
    if (!reserve_spill_area) return 0;
    const preallocated_slots = if (selector.allocation_plan) |plan| @max(plan.spill_slots, selector.next_spill_slot) else selector.next_spill_slot;
    var emergency_slots: usize = stage2_spill_slots;
    if (selector.allocation_plan) |plan| {
        const value_slots = std.math.mul(usize, plan.assignments.count(), 2) catch return null;
        emergency_slots = @max(emergency_slots, value_slots);
    }
    const reserved_slots = std.math.add(usize, preallocated_slots, emergency_slots) catch return null;
    return std.math.mul(u32, std.math.cast(u32, reserved_slots) orelse return null, 8) catch null;
}

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (bits == 1) {
        if (binary.op != .@"and" or valueIsInt(binary.lhs) or valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        emitValueIntoScratch(selector, binary.rhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
        emitValueIntoEax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .@"and", .reg = .rcx } });
        try bindEax(selector, result_name);
        return null;
    }
    if (bits == 8) {
        if (binary.op != .@"and" or !valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        return try lowerBinaryImmediateRhs(selector, result_name, binary);
    }
    if (bits != 6 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-binary-width" };

    if (valueIsInt(binary.rhs)) {
        return try lowerBinaryImmediateRhs(selector, result_name, binary);
    }
    if (valueIsInt(binary.lhs)) {
        return try lowerBinaryImmediateLhs(selector, result_name, binary);
    }
    if (bits == 128) return try lowerPairBinary(selector, result_name, binary);

    if (binary.op == .mul and bits == 64) return try lowerMul64(selector, result_name, binary);
    if ((binary.op == .udiv or binary.op == .urem) and bits == 64) {
        return try lowerUnsignedDivRem64(selector, result_name, binary);
    }
    if (binary.op == .mul and bits <= 32) {
        while (liveAccumulatorNameAfterCurrent(selector)) |live_name| {
            if (try preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
        }
        try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try emitValueIntoEax(selector, binary.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .imul_eax_arg32 = .rcx });
        try bindEax(selector, result_name);
        return null;
    }
    if ((binary.op == .shl or binary.op == .lshr) and bits == 32) {
        try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try emitValueIntoEax(selector, binary.lhs);
        try selector.machine.instructions.append(selector.allocator, switch (binary.op) {
            .shl => .shl_eax_cl,
            .lshr => .shr_eax_cl,
            else => unreachable,
        });
        try bindEax(selector, result_name);
        return null;
    }

    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
    while (liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    if (namedValue(binary.lhs)) |lhs_name| {
        if (valueIsLiveAfterCurrent(selector, lhs_name)) {
            if (try preserveLiveAccumulatorValue(selector, lhs_name)) |diagnostic| return diagnostic;
        }
    }
    const lhs = resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
    const rhs = resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

    if (locIsAccumulator(rhs) and locIsAccumulator(lhs)) {
        try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try emitValueIntoAccumulator(selector, binary.lhs, bits);
        try emitBinaryArgAccumulator(selector, op, .rcx, bits);
    } else if (locIsAccumulator(rhs)) {
        if (isCommutative(op)) {
            try spillAccumulatorAliasesExcept(selector, binary.rhs);
            try emitBinaryLocIntoAccumulator(selector, op, lhs, bits);
        } else {
            const rhs_scratch: ArgReg = switch (lhs) {
                .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
                .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => .rcx,
                .eax, .rax => unreachable,
            };
            try emitValueIntoScratch(selector, binary.rhs, rhs_scratch, bits);
            if (locIsAccumulator(lhs)) try spillAccumulatorAliasesExcept(selector, binary.lhs);
            try emitValueIntoAccumulator(selector, binary.lhs, bits);
            try emitBinaryArgAccumulator(selector, op, rhs_scratch, bits);
        }
    } else {
        if (locIsAccumulator(lhs)) try spillAccumulatorAliasesExcept(selector, binary.lhs);
        try emitValueIntoAccumulator(selector, binary.lhs, bits);
        const rhs_reg: ArgReg = switch (rhs) {
            .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-i32-for-i64" },
            .arg64, .scratch64 => |reg| if (bits == 64) reg else return .{ .no_emitter = "composed-block-rhs-i64-for-i32" },
            .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
            .spill64 => |frame_index| if (bits == 64) blk: {
                try clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else if (bits <= 32) blk: {
                try clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return .{ .no_emitter = "composed-block-rhs-stack" },
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-rhs-stack" },
            .eax, .rax => unreachable,
        };
        try emitBinaryArgAccumulator(selector, op, rhs_reg, bits);
    }

    try bindAccumulator(selector, result_name, bits);
    return null;
}

pub fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const rhs = switch (binary.rhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    switch (binary.op) {
        .lshr => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                try emitPairLshrImmediate(selector, result_name, binary.lhs, amount);
                return null;
            }
            switch (bits) {
                16, 32 => {
                    try emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                    const amount = try shiftAmount5(rhs);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                        .reg = .rcx,
                        .amount = amount,
                    } });
                    try bindScratch(selector, result_name, .rcx, bits);
                },
                64 => {
                    const amount = try shiftAmount6(rhs);
                    const dst = plannedScratch64RegForResult(selector, result_name) orelse
                        scratch64RegForUseAvoiding(selector, null) orelse
                        reusableScratch64RegForInPlace(selector, binary.lhs) orelse
                        blk: {
                            if (try spillScratch64SourceForInPlace(selector, binary.lhs)) |spill_result| switch (spill_result) {
                                .reg => |reg| break :blk reg,
                                .diagnostic => |diagnostic| return diagnostic,
                            };
                            if (try tryLowerLshr64SpillThroughRax(selector, result_name, binary.lhs, amount)) |diagnostic| return diagnostic;
                            return null;
                        };
                    try emitValueIntoScratch(selector, binary.lhs, dst, bits);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{
                        .reg = dst,
                        .amount = amount,
                    } });
                    try bindScratch(selector, result_name, dst, bits);
                },
                else => return .{ .no_emitter = "composed-block-binary-width" },
            }
        },
        .shl => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                try emitPairShlImmediate(selector, result_name, binary.lhs, amount);
                return null;
            }
            if (bits == 64) {
                const amount = try shiftAmount6(rhs);
                if (try preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                try emitValueIntoRax(selector, binary.lhs);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = amount });
                try bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-shl-imm-width" };
            const amount = try shiftAmount5(rhs);
            const lhs_loc = resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
            if (try preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
            try emitValueIntoEax(selector, binary.lhs);
            if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_eax_imm5 = amount });
            switch (lhs_loc) {
                .scratch32 => |reg| {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    try bindScratch(selector, result_name, reg, bits);
                },
                .arg32, .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => try bindEax(selector, result_name),
            }
        },
        .ashr => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                if (amount != 127) return .{ .no_emitter = "composed-block-ashr-i128-amount" };
                try emitPairSignMask(selector, result_name, binary.lhs, pair_a);
                return null;
            }
            if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
            const amount = try shiftAmount6(rhs);
            try emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
            if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{
                .reg = .rcx,
                .amount = amount,
            } });
            try bindScratch(selector, result_name, .rcx, bits);
            if (try spillValue(selector, result_name)) |diagnostic| return diagnostic;
        },
        .@"and" => {
            if (bits == 64 and rhs == std.math.maxInt(u32)) {
                if (try preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                emitValueIntoRax(selector, binary.lhs) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                const imm = i32BitPattern(rhs) catch return .{ .no_emitter = "composed-block-and64-imm" };
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = imm });
                try bindRax(selector, result_name);
                return null;
            }
            if (bits == 64) {
                if (try preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                emitValueIntoRax(selector, binary.lhs) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                try clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
                try bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try emitValueIntoEax(selector, binary.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
            try bindEax(selector, result_name);
        },
        .@"or" => {
            if (bits == 64) {
                if (try preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                emitValueIntoRax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-or64-lhs" };
                try clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } });
                try bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try emitValueIntoEax(selector, binary.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
            try bindEax(selector, result_name);
        },
        .add => {
            if (bits == 64) {
                const imm = i32Value(rhs) catch {
                    if (try preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                    emitValueIntoRax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-add64-lhs" };
                    try clobberArgReg(selector, .rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .add, .reg = .rcx } });
                    try bindRax(selector, result_name);
                    return null;
                };
                try emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = imm } });
                try bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try emitValueIntoEax(selector, binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                try bindEax(selector, result_name);
            }
        },
        .sub => {
            const imm = try i32Value(rhs);
            if (bits == 64) {
                try emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                try bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try emitValueIntoEax(selector, binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -imm });
                try bindEax(selector, result_name);
            }
        },
        .xor => {
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try emitValueIntoEax(selector, binary.lhs);
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i32Value(rhs) });
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } });
            try bindEax(selector, result_name);
        },
        else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
    }
    return null;
}

fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (!select.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-select-cond" };
    const bits: u16 = if (select.ty.eql(.ptr)) 64 else intBits(select.ty) orelse return .{ .no_emitter = "composed-block-select-type" };
    if (bits == 0 or (bits > 32 and bits != 64)) return .{ .no_emitter = "composed-block-select-width" };

    if (try emitBranchCondition(selector, select.cond)) |diagnostic| return diagnostic;
    if (select.true_value == .named) {
        const true_name = select.true_value.named;
        switch (resolveValue(selector, select.true_value) orelse return .{ .unsupported_value = "composed-block-select-true-value" }) {
            .eax => {
                _ = try preserveCurrentEaxIntoScratch(selector);
                if (resolveValue(selector, select.true_value)) |preserved| switch (preserved) {
                    .eax => try spillValueOrError(selector, true_name),
                    else => {},
                };
            },
            .rax => try spillValueOrError(selector, true_name),
            else => {},
        }
    }
    emitValueIntoAccumulator(selector, select.false_value, bits) catch return .{ .unsupported_value = "composed-block-select-false-value" };
    const end_label = try ownedSelectEndLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .je = end_label });
    emitValueIntoAccumulator(selector, select.true_value, bits) catch return .{ .unsupported_value = "composed-block-select-true-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
    try bindAccumulator(selector, result_name, bits);
    return null;
}

fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
    switch (op) {
        .xor => {
            const lhs = materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            const rhs = materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            try emitPairXorInPlace(selector, rhs, lhs);
            try bindPairScratch(selector, result_name, rhs);
        },
        .@"or" => {
            const lhs_existing = resolvePairValue(selector, binary.lhs);
            const rhs_existing = resolvePairValue(selector, binary.rhs);
            if (lhs_existing) |lhs_pair| {
                if (rhs_existing) |rhs_pair| {
                    try emitPairOrInPlace(selector, lhs_pair, rhs_pair);
                    try bindPairScratch(selector, result_name, lhs_pair);
                    return null;
                }
            }
            var lhs: RegPair = undefined;
            var rhs: RegPair = undefined;
            if (lhs_existing) |existing| {
                if (existing.eql(pair_b)) {
                    lhs = materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                    rhs = materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                } else {
                    rhs = materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    lhs = materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                }
            } else {
                rhs = materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                lhs = materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            }
            try emitPairOrInPlace(selector, rhs, lhs);
            try bindPairScratch(selector, result_name, rhs);
        },
        .sub => {
            const lhs = materializePairValue(selector, binary.lhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            const rhs = materializePairValue(selector, binary.rhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            try emitPairSubInPlace(selector, lhs, rhs);
            try bindPairScratch(selector, result_name, lhs);
        },
        else => return .{ .no_emitter = "composed-block-pair-binary-op" },
    }
    return null;
}

pub fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const lhs = resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
    const dst = switch (lhs) {
        .scratch64 => |reg| if (selector.allocation_plan == null)
            reg
        else
            reusableScratch64RegForInPlace(selector, binary.lhs) orelse
                plannedScratch64RegForResult(selector, result_name) orelse
                scratch64RegForUseAvoiding(selector, null) orelse
                blk: {
                    if (try spillScratch64SourceForInPlace(selector, binary.lhs)) |spill_result| switch (spill_result) {
                        .reg => |spilled_reg| break :blk spilled_reg,
                        .diagnostic => |diagnostic| return diagnostic,
                    };
                    return .{ .no_spill_envelope = "composed-block-mul64-dst" };
                },
        .arg64, .rax, .spill64 => plannedScratch64RegForResult(selector, result_name) orelse
            (scratch64RegForUseAvoiding(selector, null) orelse {
                if (lhs == .spill64) return try lowerMul64SpillLhsThroughRax(selector, result_name, lhs.spill64, binary.rhs);
                return .{ .no_spill_envelope = "composed-block-mul64-dst" };
            }),
        .arg32, .scratch32, .arg128, .scratch128, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-lhs" },
    };
    emitValueIntoScratch(selector, binary.lhs, dst, 64) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };

    const rhs = resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .scratch64, .arg64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } }),
        .spill64 => |frame_index| {
            if (scratch64RegForUseAvoiding(selector, dst)) |src| {
                emitValueIntoScratch(selector, binary.rhs, src, 64) catch return .{ .unsupported_value = "composed-block-mul64-rhs" };
                try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
            } else {
                if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
                try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_rax = dst });
            }
        },
        .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try bindScratch(selector, result_name, dst, 64);
    return null;
}

fn lowerMul64SpillLhsThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, lhs_frame_index: FrameIndex, rhs_value: ir.Value) !?Diagnostic {
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs_frame_index });
    const rhs = resolveValue(selector, rhs_value) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .arg64, .scratch64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64 = src }),
        .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_rsp = frame_index }),
        .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try bindRax(selector, result_name);
    return null;
}

fn plannedScratch64RegForResult(selector: *const ComposedBlockSelector, name: []const u8) ?ArgReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(name) orelse return null;
    const reg = switch (assignment) {
        .gpr64 => |reg| reg,
        .gpr32, .gpr128, .stack_object, .stack_pointer, .spill => return null,
    };
    return if (scratch64RegIsAvailableForUse(selector, reg)) reg else null;
}

fn scratch64RegForUseAvoiding(selector: *const ComposedBlockSelector, avoid: ?ArgReg) ?ArgReg {
    for (selector_allocatable_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (scratch64RegIsAvailableForUse(selector, reg)) return reg;
    }
    return null;
}

fn reusableScratch64RegForInPlace(selector: *const ComposedBlockSelector, value: ir.Value) ?ArgReg {
    const name = namedValue(value) orelse return null;
    const loc = resolveValue(selector, value) orelse return null;
    const reg: ArgReg = switch (loc) {
        .scratch64 => |reg| reg,
        else => return null,
    };
    const plan = selector.allocation_plan orelse return null;
    const end = plan.intervalEnd(name) orelse return null;
    if (end > selector.current_position) return null;

    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
        if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
        const other_end = plan.intervalEnd(entry.key_ptr.*) orelse return null;
        if (other_end >= selector.current_position) return null;
    }

    return reg;
}

const SpillScratchForInPlaceResult = union(enum) {
    reg: ArgReg,
    diagnostic: Diagnostic,
};

fn spillScratch64SourceForInPlace(selector: *ComposedBlockSelector, value: ir.Value) !?SpillScratchForInPlaceResult {
    const name = namedValue(value) orelse return null;
    const loc = resolveValue(selector, value) orelse return null;
    const reg: ArgReg = switch (loc) {
        .scratch64 => |reg| reg,
        else => return null,
    };
    const plan = selector.allocation_plan orelse return null;
    _ = plan.intervalEnd(name) orelse return null;

    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!locContainsReg(entry.value_ptr.loc, reg)) continue;
        if (std.mem.eql(u8, entry.key_ptr.*, name)) continue;
        const other_end = plan.intervalEnd(entry.key_ptr.*) orelse return null;
        if (other_end >= selector.current_position) return null;
    }

    if (try spillValue(selector, name)) |diagnostic| return .{ .diagnostic = diagnostic };
    return .{ .reg = reg };
}

fn tryLowerLshr64SpillThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u6) !?Diagnostic {
    const loc = resolveValue(selector, value) orelse return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
    const frame_index = switch (loc) {
        .spill64 => |frame_index| frame_index,
        else => return .{ .no_spill_envelope = "composed-block-lshr64-dst" },
    };
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = amount });
    try bindRax(selector, result_name);
    return null;
}

fn scratch64RegIsAvailableForUse(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    const status = regConflictStatus(selector, reg) orelse return true;
    return status;
}

fn lowerUnsignedDivRem64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const rhs = resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    if (rhs == .rax) {
        try emitValueIntoScratch(selector, binary.rhs, .rcx, 64);
        try emitValueIntoRax(selector, binary.lhs);
    } else {
        try emitValueIntoRax(selector, binary.lhs);
        try emitValueIntoScratch(selector, binary.rhs, .rcx, 64);
    }
    try clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .xor_edx_edx);
    try selector.machine.instructions.append(selector.allocator, .{ .div_arg64 = .rcx });
    switch (binary.op) {
        .udiv => {
            try bindRax(selector, result_name);
        },
        .urem => {
            try bindScratch(selector, result_name, .rdx, 64);
        },
        else => unreachable,
    }
    return null;
}

fn lowerBinaryImmediateLhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const lhs = switch (binary.lhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (binary.op == .sub and bits == 128 and lhs == 0) {
        const rhs = materializePairValue(selector, binary.rhs, pair_a) catch
            return .{ .unsupported_value = "composed-block-unknown-rhs" };
        try emitZeroArg64(selector, pair_b.lo);
        try emitZeroArg64(selector, pair_b.hi);
        try emitPairSubInPlace(selector, pair_b, rhs);
        try bindPairScratch(selector, result_name, pair_b);
        return null;
    }
    if (binary.op == .sub and bits == 64) {
        try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
        try bindRax(selector, result_name);
        return null;
    }
    if (binary.op == .sub and bits <= 32) {
        try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
        if (bits < 32) {
            const shift: u5 = @intCast(bits);
            const mask = (@as(i32, 1) << shift) - 1;
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
        }
        try bindEax(selector, result_name);
        return null;
    }
    if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
    if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

    try emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
    try selector.machine.instructions.append(selector.allocator, .shr_eax_cl);
    try bindEax(selector, result_name);
    return null;
}

pub fn lowerCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-block-cast-from-not-int" };
    const to_bits = intBits(cast.to_ty) orelse return .{ .no_emitter = "composed-block-cast-to-not-int" };
    if (from_bits > 128) return .{ .no_emitter = "composed-block-cast-width" };
    if (to_bits > 64 and !(cast.op == .zext and from_bits == 64 and to_bits == 128)) {
        return .{ .no_emitter = "composed-block-cast-width" };
    }

    switch (cast.op) {
        .trunc, .bitcast => {
            if (from_bits == 128) {
                const dst = plannedScratch64RegForResult(selector, result_name) orelse
                    if (resolvePairValue(selector, cast.value)) |pair|
                        pair.lo
                    else
                        scratch64RegForUseAvoiding(selector, null) orelse return .{ .no_spill_envelope = "composed-block-cast-scratch" };
                emitPairLowLaneIntoScratch(selector, cast.value, dst) catch return .{ .unsupported_value = "composed-block-unknown-cast" };
                try bindScratch(selector, result_name, dst, 64);
            } else {
                const loc = resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                const result_loc: ValueLoc = if (from_bits > 32 and to_bits <= 32) switch (loc) {
                    .arg64, .scratch64 => |reg| .{ .scratch32 = reg },
                    .rax => .eax,
                    .spill64 => |frame_index| .{ .spill64 = frame_index },
                    .arg32, .scratch32, .eax => loc,
                    .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-cast-width" },
                } else loc;
                try bindValueLoc(selector, result_name, result_loc);
                switch (result_loc) {
                    .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
                    .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-cast-width" },
                }
            }
        },
        .zext => {
            if (from_bits == 64 and to_bits == 128) {
                const dst = choosePairScratchForClobber(selector, null) orelse return .{ .no_spill_envelope = "composed-block-zext-pair" };
                try emitValueIntoScratch(selector, cast.value, dst.lo, 64);
                try emitZeroArg64(selector, dst.hi);
                try bindPairScratch(selector, result_name, dst);
                return null;
            }
            if (from_bits > 32 or (to_bits > 32 and to_bits != 64)) return .{ .no_emitter = "composed-block-zext-width" };
            try emitValueIntoEax(selector, cast.value);
            if (from_bits < 32) {
                const shift: u5 = @intCast(from_bits);
                const mask = (@as(i32, 1) << shift) - 1;
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
            }
            try bindAccumulator(selector, result_name, to_bits);
        },
        .sext => {
            if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
            const loc = resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-sext" };
            const src = switch (loc) {
                .arg32, .scratch32 => |reg| reg,
                .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-sext-source" },
            };
            const dst: ArgReg = switch (src) {
                .rdi => .r8,
                .rsi => .r9,
                .rdx => .rcx,
                .rcx => .r8,
                .r8 => .r9,
                .r9 => .r8,
            };
            try selector.machine.instructions.append(selector.allocator, .{ .movsxd_arg32_arg64 = .{ .dst = dst, .src = src } });
            try bindScratch(selector, result_name, dst, 64);
        },
        else => return .{ .no_emitter = "composed-block-cast-op" },
    }
    return null;
}

fn lowerFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(freeze.ty) orelse return .{ .no_emitter = "composed-block-freeze-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-freeze-width" };
    const loc = resolveValue(selector, freeze.value) orelse return .{ .unsupported_value = "composed-block-unknown-freeze" };
    switch (loc) {
        .arg32, .scratch32, .eax => if (bits != 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg64, .scratch64, .rax => if (bits != 64) return .{ .no_emitter = "composed-block-freeze-width" },
        .spill64 => if (bits != 64 and bits > 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg128, .scratch128, .stack128_value, .spill128 => if (bits != 128) return .{ .no_emitter = "composed-block-freeze-width" },
        .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr => return .{ .no_emitter = "composed-block-freeze-loc" },
    }
    try bindValueLoc(selector, result_name, loc);
    switch (loc) {
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .spill64, .spill128 => {},
        .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr => unreachable,
    }
    return null;
}

fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const is_ne_zero_i16 = icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 16 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (is_ne_zero_i16) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr) and icmp.rhs == .null_value) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr)) {
        if (icmp.rhs != .named) return .{ .no_emitter = "composed-block-icmp-rhs" };
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == std.math.minInt(i128),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        const existing = resolvePairValue(selector, icmp.lhs);
        const pair = if (existing) |source|
            if (source.contains(pair_a.lo) or source.contains(pair_a.hi)) pair_b else pair_a
        else
            pair_a;
        _ = materializePairValue(selector, icmp.lhs, pair) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        const temp: ArgReg = if (pair.contains(.r8)) .rcx else .r8;
        try clobberAccumulator(selector);
        try clobberArgReg(selector, temp);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi });
        try selector.machine.instructions.append(selector.allocator, switch (temp) {
            .rcx => .{ .mov_imm_rcx = std.math.minInt(i64) },
            .r8 => .{ .mov_imm_r8 = std.math.minInt(i64) },
            else => unreachable,
        });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = temp } });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = pair.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = temp });
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = temp, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq) {
        const bits = intBits(icmp.operand_ty) orelse return .{ .no_emitter = "composed-block-icmp-type" };
        if (icmp.rhs == .named) {
            if (bits == 64) {
                emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else if (bits <= 32) {
                emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                emitValueIntoScratch(selector, icmp.rhs, .r8, 32) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else return .{ .no_emitter = "composed-block-icmp-rhs" };
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, if (bits == 64) .{ .cmp_rcx_arg64 = .r8 } else .{ .cmp_ecx_arg32 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try bindEax(selector, result_name);
            return null;
        }
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        const imm = try i64Value(rhs);
        if (imm != 0) {
            if (bits == 64) {
                emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = imm } });
            } else if (bits <= 32) {
                emitValueIntoEax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(rhs) });
            } else return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try bindEax(selector, result_name);
            return null;
        }
        const loc = resolveValue(selector, icmp.lhs) orelse return .{ .unsupported_value = "composed-block-icmp-lhs" };
        switch (loc) {
            .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
            .rax => {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .test_rax_rax);
            },
            .arg32, .scratch32 => |reg| {
                if (bits > 32) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = reg });
            },
            .arg64, .scratch64 => |reg| {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = reg });
            },
            .spill64 => |frame_index| {
                try clobberArgReg(selector, .rcx);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
                } else if (bits <= 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
                } else return .{ .no_emitter = "composed-block-icmp-lhs-width" };
            },
            .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        }
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .named) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .int) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_r8d_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 6 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 << 5 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = std.math.minInt(i32) });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        emitPairHighLaneIntoRax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try preserveCurrentRaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try emitValueIntoRax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_eax_imm5 = 31 });
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 })) {
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else return .{ .no_emitter = "composed-block-icmp-form" };
    try bindEax(selector, result_name);
    return null;
}

fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
    if (!load.ty.eql(.{ .int = 8 }) and !load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
    const ptr = resolveValue(selector, load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
    switch (ptr) {
        .stack_scalar => |stack| {
            if (stack.bits == 64 and load.ty.eql(.{ .int = 64 })) {
                try loadStackU64IntoRax(selector, stack.base_disp);
                try bindRax(selector, result_name);
            } else if (stack.bits == 8 and load.ty.eql(.{ .int = 8 })) {
                try clobberAccumulator(selector);
                if (stack.base_disp <= std.math.maxInt(u8)) {
                    try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_u8_eax = @intCast(stack.base_disp) });
                } else {
                    try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_u8_eax = stack.base_disp });
                }
                try bindEax(selector, result_name);
            } else return .{ .no_emitter = "composed-block-load-stack-width" };
        },
        .stack128 => |disp| {
            if (!load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-stack-width" };
            try bindValueLoc(selector, result_name, .{ .stack128_value = disp });
        },
        .stack_i32_ptr => |stack_ptr| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
            try appendLoadStackI32(selector, stack_ptr);
            try bindEax(selector, result_name);
        },
        .stack_i32_array => |stack_array| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
            try appendLoadStackI32(selector, .{ .disp = stack_array.base_disp });
            try bindEax(selector, result_name);
        },
        .arg64, .scratch64 => |reg| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = reg });
            try bindEax(selector, result_name);
        },
        .spill64 => |frame_index| {
            if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
            try clobberAccumulator(selector);
            try materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
            try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = .rcx });
            try bindEax(selector, result_name);
        },
        .arg32, .arg128, .eax, .rax, .scratch32, .scratch128, .stack128_value, .spill128 => return .{ .no_emitter = "composed-block-load-ptr" },
    }
    return null;
}

fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
    if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
    if (!store.ty.eql(.{ .int = 1 }) and !store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-width" };
    const ptr = resolveValue(selector, store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
    const value_loc = switch (store.value) {
        .named => resolveValue(selector, store.value) orelse return .{ .unsupported_value = "composed-block-unknown-store-value" },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
    const value_detail = if (value_loc) |loc| switch (loc) {
        .arg32, .arg64 => "composed-block-store-value-arg",
        .scratch32, .scratch64 => "composed-block-store-value-scratch",
        .eax, .rax => "composed-block-store-value-accumulator",
        .spill64 => "composed-block-store-value-spill",
        .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => "composed-block-store-value-other",
    } else "composed-block-store-value-other";
    emitValueIntoEax(selector, store.value) catch return .{ .unsupported_value = value_detail };
    switch (ptr) {
        .stack_scalar => |stack| {
            if (stack.bits != 8 or !store.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-store-stack-width" };
            if (stack.base_disp <= std.math.maxInt(u8)) {
                try selector.machine.instructions.append(selector.allocator, .{ .store_al_stack_disp8 = @intCast(stack.base_disp) });
            } else {
                try selector.machine.instructions.append(selector.allocator, .{ .store_al_stack_disp32 = stack.base_disp });
            }
        },
        .arg64, .scratch64 => |reg| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = reg });
        },
        .stack_i32_ptr => |stack_ptr| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            appendStoreStackI32(selector, stack_ptr) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-stack-index" },
                else => return err,
            };
        },
        .stack_i32_array => |stack_array| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            appendStoreStackI32(selector, .{ .disp = stack_array.base_disp }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-array-index" },
                else => return err,
            };
        },
        .spill64 => |frame_index| {
            if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-ptr-width" };
            materializeLocIntoLoc(selector, .{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-spill-ptr" },
                else => return err,
            };
            try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = .rcx });
        },
        .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack128, .stack128_value, .spill128 => return .{ .no_emitter = "composed-block-store-ptr" },
    }
    return null;
}

fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (isBytePointerSource(gep.source_ty)) return try lowerBytePointerGep(selector, result_name, gep);
    if (isI32ElementPointerSource(gep.source_ty)) return try lowerI32ElementPointerGep(selector, result_name, gep);
    const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
    const base = resolveValue(selector, gep.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-array-gep-ptr" };
    const stack_array = switch (base) {
        .stack_i32_array => |stack_array| stack_array,
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-gep-ptr" },
    };
    if (stack_array.len != len) return .{ .no_emitter = "composed-block-gep-len" };
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 2) return .{ .no_emitter = "composed-block-gep-index-count" };
    const first_index = gep.indices.items[0];
    if (!first_index.ty.eql(.{ .int = 64 }) or !first_index.value.eql(.{ .int = 0 })) return .{ .no_emitter = "composed-block-gep-base-index" };
    const elem_index = gep.indices.items[1];
    if (!elem_index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    const stack_ptr = switch (elem_index.value) {
        .int => |int| blk: {
            const index = std.math.cast(u32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
            if (index >= stack_array.len) return .{ .no_emitter = "composed-block-gep-index-range" };
            const byte_offset = std.math.mul(u32, index, 4) catch return .{ .no_spill_envelope = "composed-block-gep-offset" };
            break :blk StackPtrLoc{ .disp = stack_array.base_disp + byte_offset };
        },
        .named => |name| blk: {
            try emitValueIntoScratch(selector, elem_index.value, .rcx, 64);
            break :blk StackPtrLoc{ .disp = stack_array.base_disp, .index = .{ .reg = .rcx, .name = name } };
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    };
    try bindValueLoc(selector, result_name, .{ .stack_i32_ptr = stack_ptr });
    return null;
}

fn lowerI32ElementPointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
    if (index.value != .named) return .{ .no_emitter = "composed-block-gep-index-form" };

    if (resolveValue(selector, gep.ptr)) |base| switch (base) {
        .stack_i32_array => |stack_array| {
            emitValueIntoScratch(selector, index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            const index_name = switch (index.value) {
                .named => |name| name,
                else => unreachable,
            };
            try bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{
                .disp = stack_array.base_disp,
                .index = .{ .reg = .rcx, .name = index_name },
            } });
            return null;
        },
        .stack_i32_ptr => |stack_ptr| {
            const stack_index = stack_ptr.index orelse return .{ .no_emitter = "composed-block-gep-ptr" };
            if (stack_index.reg != .rcx) return .{ .no_emitter = "composed-block-gep-ptr" };
            if (stack_index.addend_name != null) return .{ .no_emitter = "composed-block-gep-index-depth" };
            const addend_name = switch (index.value) {
                .named => |name| name,
                else => unreachable,
            };
            try bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{
                .disp = stack_ptr.disp,
                .index = .{ .reg = .rcx, .name = stack_index.name, .addend_name = addend_name },
            } });
            return null;
        },
        else => {},
    };

    emitValueIntoScratch(selector, gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-i32-element-gep-ptr" };
    emitValueIntoScratch(selector, index.value, .r8, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
    try selector.machine.instructions.append(selector.allocator, .{ .shl_r8_imm6 = 2 });
    try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    try bindScratch(selector, result_name, .rcx, 64);
    return null;
}

fn lowerBytePointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
    if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
    if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };

    switch (index.value) {
        .int => |int| {
            const offset = std.math.cast(i32, int) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
            if (resolveValue(selector, gep.ptr)) |base| switch (base) {
                .stack_i32_ptr => |stack_ptr| {
                    const adjusted = std.math.add(i64, stack_ptr.disp, offset) catch return .{ .no_emitter = "composed-block-gep-index-range" };
                    const disp = std.math.cast(u32, adjusted) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
                    try bindValueLoc(selector, result_name, .{ .stack_i32_ptr = .{ .disp = disp, .index = stack_ptr.index } });
                    return null;
                },
                else => {},
            };
            emitValueIntoScratch(selector, gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
            if (offset != 0) try selector.machine.instructions.append(selector.allocator, .{ .add_rcx_imm32 = offset });
            try bindScratch(selector, result_name, .rcx, 64);
        },
        .named => {
            emitValueIntoScratch(selector, gep.ptr, .r8, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
            emitValueIntoScratch(selector, index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
            try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
            try bindScratch(selector, result_name, .rcx, 64);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
    }
    return null;
}

fn isI32ElementPointerSource(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[4 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn isBytePointerSource(ty: ir.Type) bool {
    if (ty.eql(.{ .int = 8 })) return true;
    return switch (ty) {
        .aggregate => |text| std.mem.eql(u8, std.mem.trim(u8, text, " "), "[1 x i8]"),
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (call.isDebugVariableLocation()) return null;
    if (std.mem.eql(u8, call.callee, "llvm.assume")) return lowerAssume(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.trap")) return try lowerTrap(selector, result, call);
    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize")) return try lowerIntByteSizeCall(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i32")) return try lowerAbsI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try lowerAbsI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i128")) return try lowerAbsI128(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32")) return try lowerCtlzI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fshl.i32")) return try lowerFshlI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) return try lowerInlineMemcpy(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i32")) return try lowerUaddOverflowI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i64")) return try lowerSmulOverflowI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i128")) return try lowerSmulOverflowI128(selector, result, call);
    if (call.inline_asm != null) return .{ .no_emitter = "composed-block-inline-asm-call" };
    if (call.callee_value != null) return .{ .unsupported_value = "composed-block-indirect-call" };
    if (!isDefaultOrFastcc(call.calling_conv) or call.tail_kind != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-call-form" };
    }
    const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
    if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64 and ret_bits != 128) return .{ .no_emitter = "composed-block-call-ret-width" };
    var abi_index: usize = 0;

    if (try spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    for (call.args.items) |arg| {
        const target = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
        if (try lowerDirectCallArg(selector, arg, target)) |diagnostic| return diagnostic;
        abi_index += callArgRegisterCount(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (abi_index > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };
    }

    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    if (result) |result_name| switch (ret_bits) {
        0 => return .{ .unsupported_value = "composed-block-void-call-result" },
        32 => try bindEax(selector, result_name),
        64 => try bindRax(selector, result_name),
        128 => {},
        else => unreachable,
    };
    return null;
}

fn lowerUaddOverflowI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-overflow-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-overflow-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-overflow-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .aggregate = "{ i32, i1 }" }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-overflow-signature" };
    const lhs = call.args.items[0];
    const rhs = call.args.items[1];
    if (!lhs.ty.eql(.{ .int = 32 }) or !rhs.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-overflow-args" };

    const lhs_loc = resolveValue(selector, lhs.value) orelse return .{ .unsupported_value = "composed-block-overflow-lhs" };
    const rhs_scratch: ArgReg = switch (lhs_loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
        .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => .rcx,
    };
    emitValueIntoScratch(selector, rhs.value, rhs_scratch, 32) catch return .{ .unsupported_value = "composed-block-overflow-rhs" };
    switch (lhs_loc) {
        .eax, .rax => {
            spillAccumulatorAliasesExcept(selector, lhs.value) catch return .{ .no_spill_envelope = "composed-block-overflow-lhs-alias" };
            if (namedValue(lhs.value)) |lhs_name| {
                if (valueIsLiveAfterCurrent(selector, lhs_name)) {
                    spillValueOrError(selector, lhs_name) catch return .{ .no_spill_envelope = "composed-block-overflow-live-lhs" };
                }
            }
        },
        else => {},
    }
    emitValueIntoEax(selector, lhs.value) catch return .{ .unsupported_value = "composed-block-overflow-lhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = rhs_scratch } });
    try clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdx });
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .setb_eax);
    try selector.overflow_results.put(result_name, .{
        .value = .{ .scratch32 = .rdx },
        .overflow = .eax,
    });
    return null;
}

fn lowerSmulOverflowI128(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-smulo-i128-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-smulo-i128-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-smulo-i128-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .aggregate = "{ i128, i1 }" }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-smulo-i128-signature" };
    const lhs = call.args.items[0];
    const rhs = call.args.items[1];
    if (!lhs.ty.eql(.{ .int = 128 }) or !rhs.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-smulo-i128-args" };

    const lhs_spill = ensurePairSpill(selector, lhs.value) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-lhs" };
    const rhs_spill = ensurePairSpill(selector, rhs.value) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-rhs" };
    clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };
    clobberArgReg(selector, .r8) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };
    clobberArgReg(selector, .r9) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };

    const p00_name = try ownedInternalValueName(selector, result_name, "p00");
    const p01_name = try ownedInternalValueName(selector, result_name, "p01");
    const p10_name = try ownedInternalValueName(selector, result_name, "p10");
    const p11_name = try ownedInternalValueName(selector, result_name, "p11");
    const overflow_name = try ownedInternalValueName(selector, result_name, "overflow");
    const p00 = emitUnsignedLimbProduct(selector, lhs_spill.lo, rhs_spill.lo, p00_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p00" };
    const p01 = emitUnsignedLimbProduct(selector, lhs_spill.lo, rhs_spill.hi, p01_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p01" };
    const p10 = emitUnsignedLimbProduct(selector, lhs_spill.hi, rhs_spill.lo, p10_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p10" };
    const p11 = emitUnsignedLimbProduct(selector, lhs_spill.hi, rhs_spill.hi, p11_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p11" };

    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .r9, .frame_index = p01.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = p11.hi } });

    try accumulateLimbWithCarry(selector, p00.hi, p01.lo, .r8, .r9);
    try accumulateRegWithCarry(selector, .r8, p10.lo, .r8, .r9);
    try accumulateRegWithCarry(selector, .r9, p10.hi, .r9, .rdx);
    try accumulateRegWithCarry(selector, .r9, p11.lo, .r9, .rdx);

    try emitSignedUpperCorrection(selector, lhs_spill.hi, rhs_spill);
    try emitSignedUpperCorrection(selector, rhs_spill.hi, lhs_spill);

    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = p00.hi, .reg = .r8 } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = .r8 } });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .r8 });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .r8 } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
    try selector.machine.instructions.append(selector.allocator, .setne_eax);

    const overflow_spill = allocateSpillSlot(selector, overflow_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i128-overflow-spill" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = overflow_spill });
    try selector.overflow_results.put(result_name, .{
        .value = .{ .spill128 = p00 },
        .overflow = .{ .spill64 = overflow_spill },
        .require_value_first = false,
    });
    return null;
}

fn lowerSmulOverflowI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-smulo-i64-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-smulo-i64-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-smulo-i64-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .aggregate = "{ i64, i1 }" }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-smulo-i64-signature" };
    const lhs = call.args.items[0];
    const rhs = call.args.items[1];
    if (!lhs.ty.eql(.{ .int = 64 }) or !rhs.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-smulo-i64-args" };

    prepareFixedProductDefs(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-fixed-defs" };
    emitValueIntoScratch(selector, rhs.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-rhs" };
    emitValueIntoAccumulator(selector, lhs.value, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-lhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64_full = .rcx });

    const value_name = try ownedInternalValueName(selector, result_name, "value");
    const value_spill = allocateSpillSlot(selector, value_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i64-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = value_spill });
    clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-sign" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } });
    try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .rdx });
    clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-overflow" };
    try selector.machine.instructions.append(selector.allocator, .setne_eax);
    const overflow_name = try ownedInternalValueName(selector, result_name, "overflow");
    const overflow_spill = allocateSpillSlot(selector, overflow_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i64-overflow" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = overflow_spill });
    try selector.overflow_results.put(result_name, .{
        .value = .{ .spill64 = value_spill },
        .overflow = .{ .spill64 = overflow_spill },
        .require_value_first = false,
    });
    return null;
}

fn lowerExtractValue(selector: *ComposedBlockSelector, result: ?[]const u8, extract: ir.ExtractValueInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-extractvalue-missing-result" };
    const aggregate_name = switch (extract.aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-extractvalue-aggregate" },
    };
    const overflow = selector.overflow_results.getPtr(aggregate_name) orelse return .{ .unsupported_value = "composed-block-extractvalue-aggregate" };
    const loc = if (std.mem.eql(u8, extract.indices, "0")) blk: {
        if (overflow.value_extracted) return .{ .no_emitter = "composed-block-extractvalue-duplicate" };
        overflow.value_extracted = true;
        break :blk overflow.value;
    } else if (std.mem.eql(u8, extract.indices, "1")) blk: {
        if (overflow.require_value_first and !overflow.value_extracted) return .{ .no_emitter = "composed-block-extractvalue-order" };
        if (overflow.overflow_extracted) return .{ .no_emitter = "composed-block-extractvalue-duplicate" };
        overflow.overflow_extracted = true;
        break :blk overflow.overflow;
    } else return .{ .unsupported_value = "composed-block-extractvalue-index" };
    try bindResultLoc(selector, result_name, loc);
    if (overflow.value_extracted and overflow.overflow_extracted) _ = selector.overflow_results.remove(aggregate_name);
    return null;
}

fn lowerInlineMemcpy(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (result != null) return .{ .unsupported_value = "composed-block-memcpy-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-memcpy-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-memcpy-tail-kind" };
    }
    if (call.ret_ty != .void or call.args.items.len != 4) return .{ .no_emitter = "composed-block-memcpy-signature" };
    const dst = call.args.items[0];
    const src = call.args.items[1];
    const len = call.args.items[2];
    const is_volatile = call.args.items[3];
    if (dst.ty != .ptr or src.ty != .ptr or !len.ty.eql(.{ .int = 64 }) or
        !is_volatile.ty.eql(.{ .int = 1 }) or !is_volatile.value.eql(.{ .int = 0 }))
    {
        return .{ .no_emitter = "composed-block-memcpy-args" };
    }

    if (try spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    emitValueIntoScratch(selector, dst.value, .rdi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-dst" };
    emitValueIntoScratch(selector, src.value, .rsi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-src" };
    emitValueIntoScratch(selector, len.value, .rdx, 64) catch return .{ .unsupported_value = "composed-block-memcpy-len" };
    try selector.machine.instructions.append(selector.allocator, .memcpy_rdi_rsi_rdx_rax);
    return null;
}

fn lowerCtlzI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-ctlz-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-ctlz-signature" };
    const value_arg = call.args.items[0];
    const undef_arg = call.args.items[1];
    const valid_zero_flag = undef_arg.value.eql(.{ .int = 0 }) or undef_arg.value.eql(.{ .int = 1 });
    if (!value_arg.ty.eql(.{ .int = 32 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !valid_zero_flag) {
        return .{ .no_emitter = "composed-block-ctlz-args" };
    }
    emitValueIntoScratch(selector, value_arg.value, .rdi, 32) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .clz_i32_edi_eax);
    try bindEax(selector, result_name);
    return null;
}

fn lowerFshlI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-fshl-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 3) return .{ .no_emitter = "composed-block-fshl-signature" };
    for (call.args.items) |arg| {
        if (!arg.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-fshl-args" };
    }
    const amount_value = switch (call.args.items[2].value) {
        .int => |int| try i64Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-fshl-amount" },
    };
    const amount: u5 = @intCast(@as(u64, @bitCast(amount_value)) & 31);
    emitValueIntoEax(selector, call.args.items[0].value) catch return .{ .unsupported_value = "composed-block-fshl-lhs" };
    emitValueIntoScratch(selector, call.args.items[1].value, .rcx, 32) catch return .{ .unsupported_value = "composed-block-fshl-rhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .fshl_eax_arg32_imm5 = .{ .reg = .rcx, .amount = amount } });
    try bindEax(selector, result_name);
    return null;
}

fn lowerAssume(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
    _ = selector;
    if (result != null) return .{ .unsupported_value = "composed-block-assume-result" };
    if (call.inline_asm != null or call.callee_value != null or call.ret_attrs != null or call.raw_args != null or
        (call.operand_bundle != null and !isColdAssumeBundle(call.operand_bundle.?)))
    {
        return .{ .no_emitter = "composed-block-assume-form" };
    }
    if (call.ret_ty != .void or call.args.items.len != 1) return .{ .no_emitter = "composed-block-assume-signature" };
    return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .no_emitter = "composed-block-assume-arg" };
}

fn lowerTrap(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (result != null) return .{ .unsupported_value = "composed-block-trap-result" };
    if (call.inline_asm != null or call.callee_value != null or call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null or call.ret_ty != .void or call.args.items.len != 0) {
        return .{ .no_emitter = "composed-block-trap-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-trap-tail-kind" };
    }
    try selector.machine.instructions.append(selector.allocator, .ud2);
    return null;
}

fn lowerIntByteSizeCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-intbytesize-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-intbytesize-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 1) return .{ .no_emitter = "composed-block-intbytesize-signature" };
    const arg = call.args.items[0];
    if (!arg.ty.eql(.{ .int = 16 })) return .{ .no_emitter = "composed-block-intbytesize-arg" };

    if (try spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    emitValueIntoScratch(selector, arg.value, .rdi, 16) catch return .{ .unsupported_value = "composed-block-intbytesize-arg-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try bindEax(selector, result_name);
    return null;
}

fn lowerAbsI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-abs-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
    const value_arg = call.args.items[0];
    const poison_arg = call.args.items[1];
    if (!value_arg.ty.eql(.{ .int = 32 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
    const poison_ok = switch (poison_arg.value) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

    try emitValueIntoScratch(selector, value_arg.value, .rdi, 32);
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .abs_i32_edi_eax);
    try bindEax(selector, result_name);
    return null;
}

fn lowerAbsI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-abs-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
    const value_arg = call.args.items[0];
    const poison_arg = call.args.items[1];
    if (!value_arg.ty.eql(.{ .int = 64 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
    if (!valueIsInt(poison_arg.value)) return .{ .no_emitter = "composed-block-abs-poison-arg" };
    const poison_ok = switch (poison_arg.value) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

    try emitValueIntoScratch(selector, value_arg.value, .rdi, 64);
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .abs_i64_rdi_rax);
    try bindRax(selector, result_name);
    return null;
}

fn lowerAbsI128(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-abs-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 128 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-abs-signature" };
    const value_arg = call.args.items[0];
    const poison_arg = call.args.items[1];
    if (!value_arg.ty.eql(.{ .int = 128 }) or !poison_arg.ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-abs-args" };
    const poison_ok = switch (poison_arg.value) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (!poison_ok) return .{ .no_emitter = "composed-block-abs-poison-mode" };

    try emitPairSignMask(selector, "__zllvm_abs_i128_sign", value_arg.value, pair_a);
    _ = materializePairValue(selector, value_arg.value, pair_b) catch return .{ .unsupported_value = "composed-block-abs-value" };
    try emitPairXorInPlace(selector, pair_b, pair_a);
    try emitPairSubInPlace(selector, pair_b, pair_a);
    try bindPairScratch(selector, result_name, pair_b);
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
            _ = resolveValue(selector, value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
            if (bits == 128) {
                try emitValueIntoI128Return(selector, value);
            } else {
                try emitValueIntoAccumulator(selector, value, bits);
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
    }
    try emitReturnEpilogue(selector);
    return null;
}

fn appendSubRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
    switch (bytes) {
        8 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_8),
        24 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_24),
        40 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_40),
        56 => try selector.machine.instructions.append(selector.allocator, .sub_rsp_56),
        else => if (bytes <= std.math.maxInt(u8))
            try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm8 = @intCast(bytes) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .sub_rsp_imm32 = bytes }),
    }
}

fn appendAddRsp(selector: *ComposedBlockSelector, bytes: u32) !void {
    switch (bytes) {
        8 => try selector.machine.instructions.append(selector.allocator, .add_rsp_8),
        24 => try selector.machine.instructions.append(selector.allocator, .add_rsp_24),
        40 => try selector.machine.instructions.append(selector.allocator, .add_rsp_40),
        56 => try selector.machine.instructions.append(selector.allocator, .add_rsp_56),
        else => if (bytes <= std.math.maxInt(u8))
            try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm8 = @intCast(bytes) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .add_rsp_imm32 = bytes }),
    }
}

fn appendLoadStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
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

fn appendStoreStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
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

fn materializeStackIndex(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
    const index = stack_ptr.index orelse return;
    try emitValueIntoScratch(selector, .{ .named = index.name }, .rcx, 64);
    if (index.addend_name) |addend_name| {
        try emitValueIntoScratch(selector, .{ .named = addend_name }, .r8, 64);
        try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
    }
}

fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
    if (selector.return_epilogue_label) |label| {
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = label });
        return;
    }
    if (selector.stack_frame_bytes != 0) try appendAddRsp(selector, selector.stack_frame_bytes);
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
        const actual = valueLoc(selector, name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
        if (valueLocEql(actual, destination)) continue;
        const bits = selector.values.get(name).?.vreg.bits;
        materializeLocIntoLocWithBits(selector, actual, destination, bits) catch return .{ .no_emitter = "stage2-phi-restore-loc" };
        try bindValueLoc(selector, name, destination);
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

fn ownedInternalValueName(selector: *ComposedBlockSelector, result_name: []const u8, suffix: []const u8) ![]const u8 {
    const name = try std.fmt.allocPrint(selector.allocator, "__zllvm_{s}_{s}", .{ result_name, suffix });
    errdefer selector.allocator.free(name);
    try selector.machine.owned_labels.append(selector.allocator, name);
    return name;
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
        try bindValueLoc(selector, result_name, dst);
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
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                },
                .named => {
                    emitPhiValueIntoScratch(selector, value, reg, 32) catch return .{ .unsupported_value = phiSourceDiagnostic(selector, value) };
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
            }
        },
        .scratch64 => |reg| {
            switch (value) {
                .int => |int| {
                    try clobberAccumulator(selector);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                },
                .named => {
                    emitPhiValueIntoScratch(selector, value, reg, 64) catch return .{ .unsupported_value = phiSourceDiagnostic(selector, value) };
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
            }
        },
        .spill64 => |frame_index| switch (value) {
            .int => |int| {
                try clobberAccumulator(selector);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = frame_index });
                } else {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = frame_index });
                }
            },
            .named => {
                const actual = resolveValue(selector, value) orelse return .{ .unsupported_value = phiSourceDiagnostic(selector, value) };
                materializeLocIntoLocWithBits(selector, actual, dst, bits) catch return .{ .unsupported_value = phiSourceDiagnostic(selector, value) };
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
        },
        .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
    }
    return null;
}

fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    const loc = resolveValue(selector, value) orelse return .{ .unsupported_value = "stage2-unknown-cond" };
    switch (loc) {
        .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
        .arg32, .scratch32 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = reg }),
        .spill64 => |frame_index| {
            try clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
            try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = .rcx });
        },
        .arg64, .scratch64, .arg128, .scratch128, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-cond-loc" },
    }
    return null;
}

fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
    if (arg.ty == .ptr) {
        const loc = resolveValue(selector, arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
        const disp = switch (loc) {
            .stack_scalar => |stack| stack.base_disp,
            .stack128 => |disp| disp,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-call-ptr-arg" },
        };
        try clobberArgReg(selector, target);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
        if (disp != 0) {
            const addend: i32 = std.math.cast(i32, disp) orelse return .{ .no_spill_envelope = "composed-block-call-stack-disp" };
            try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } });
        }
        return null;
    }

    const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-call-arg-width" };
    const loc = resolveValue(selector, arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-arg" };
    if (bits == 128) {
        const target_hi = ArgReg.fromIndex(argRegIndex(target) + 1) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
        switch (loc) {
            .arg128, .scratch128 => |pair| try emitPairIntoAbiRegs(selector, pair, .{ .lo = target, .hi = target_hi }),
            .stack128_value => |disp| {
                try loadStackU64IntoArg(selector, target, disp);
                try loadStackU64IntoArg(selector, target_hi, disp + 8);
            },
            .spill128 => |spill| {
                try clobberArgReg(selector, target);
                try clobberArgReg(selector, target_hi);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target_hi, .frame_index = spill.hi } });
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return .{ .no_emitter = "composed-block-call-arg-loc" },
        }
        return null;
    }
    switch (loc) {
        .arg32, .scratch32 => |reg| {
            if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
            if (reg != target) {
                try clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = target, .src = reg } });
            }
        },
        .arg64, .scratch64 => |reg| {
            if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
            if (reg != target) {
                try clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
            }
        },
        .eax => {
            if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
            try clobberArgReg(selector, target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = target });
        },
        .rax => {
            if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
            try clobberArgReg(selector, target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
        },
        .spill64 => |frame_index| {
            try clobberArgReg(selector, target);
            if (bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
            } else if (bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = target, .frame_index = frame_index } });
            } else return .{ .no_emitter = "composed-block-call-arg-width" };
        },
        .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-call-arg-loc" },
    }
    return null;
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
    try selector.values.put(name, .{ .vreg = vreg, .loc = loc });
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
    try selector.values.put(name, .{ .vreg = vreg, .loc = target });
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
        .gpr32, .gpr64, .stack_object, .stack_pointer => return error.UnsupportedCodegenValue,
    }
}

fn plannedResultLoc(selector: *const ComposedBlockSelector, name: []const u8, actual: ValueLoc) ?ValueLoc {
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
        .stack_object, .stack_pointer => actual,
        .spill => |index| switch (actual) {
            .arg32, .scratch32, .eax => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg64, .scratch64, .rax, .spill64 => if (spillFrameIndexMaybe(index)) |frame_index| if (frameIndexFitsFrame(selector, frame_index)) .{ .spill64 = frame_index } else null else null,
            .arg128, .scratch128, .spill128 => if (pairSpillFrameIndexMaybe(index)) |spill| if (frameIndexFitsFrame(selector, spill.lo) and frameIndexFitsFrame(selector, spill.hi)) .{ .spill128 = spill } else null else null,
            else => null,
        },
    };
    const target = planned orelse return null;
    if (std.meta.activeTag(target) == .spill64 or std.meta.activeTag(target) == .spill128) return target;
    if (valueLocEql(actual, target)) return target;
    return if (selector.enable_expired_plan_register_reuse and selector.expired_binding_this_position and targetLocHasOnlyExpiredConflicts(selector, target)) target else null;
}

fn targetLocHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, target: ValueLoc) bool {
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
        .arg32, .arg64, .arg128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => false,
    };
}

fn regHasOnlyExpiredConflicts(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var saw_conflict = false;
    if (regConflictStatus(selector, reg)) |expired| {
        if (!expired) return false;
        saw_conflict = true;
    }
    return saw_conflict;
}

fn regConflictStatus(selector: *const ComposedBlockSelector, reg: ArgReg) ?bool {
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
            .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
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
            .arg32, .scratch32, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
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
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
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
                .arg128, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
            }
        },
        .spill128 => |spill| {
            if (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi)) return error.UnsupportedCodegenValue;
            switch (actual) {
                .arg128, .scratch128 => |pair| {
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
                },
                .spill128 => {},
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
            }
        },
        .arg32, .arg64, .arg128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr => return error.UnsupportedCodegenValue,
    }
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

fn frameIndexFitsFrame(selector: *const ComposedBlockSelector, frame_index: FrameIndex) bool {
    const offset = frame_index.byteOffset() catch return false;
    const end = std.math.add(u32, offset, 8) catch return false;
    return end <= selector.stack_frame_bytes;
}

pub fn valueLoc(selector: *const ComposedBlockSelector, name: []const u8) ?ValueLoc {
    const binding = selector.values.get(name) orelse return null;
    return binding.loc;
}

pub fn virtualRegMetadata(loc: ValueLoc) VirtualRegMetadata {
    return switch (loc) {
        .arg32, .scratch32, .eax => .{ .class = .gpr32, .bits = 32 },
        .arg64, .scratch64, .rax, .spill64 => .{ .class = .gpr64, .bits = 64 },
        .arg128, .scratch128, .spill128, .stack128_value => .{ .class = .gpr128, .bits = 128 },
        .stack_scalar, .stack128, .stack_i32_array => .{ .class = .stack_object, .bits = 0 },
        .stack_i32_ptr => .{ .class = .stack_pointer, .bits = 64 },
    };
}

fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .eax);
}

fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
    try bindResultLoc(selector, name, .rax);
}

fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
    if (bits == 64) try bindRax(selector, name) else try bindEax(selector, name);
}

fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
    const actual: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
    try bindResultLoc(selector, name, actual);
}

fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
    try bindResultLoc(selector, name, .{ .scratch128 = pair });
}

fn emitPairIntoAbiRegs(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
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

fn spillCurrentAccumulator(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveAccumulatorName(selector) orelse return null;
    return try spillValue(selector, name);
}

fn preserveRaxForDestructiveAccumulatorUse(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
    _ = value;
    return try spillCurrentAccumulator(selector);
}

fn preserveLiveAccumulatorValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
    const binding = selector.values.get(name) orelse return .{ .unsupported_value = "composed-block-preserve-live-lhs" };
    const loc = binding.loc;
    const bits = binding.vreg.bits;
    switch (loc) {
        .eax, .rax => {},
        else => return null,
    }
    const dst = scratch64RegForUseAvoiding(selector, null) orelse return try spillValue(selector, name);
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
        .spill128 => return null,
        else => {},
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
        .arg128, .scratch128 => return .{ .no_emitter = "composed-block-spill-loc-pair" },
        .stack_scalar => return .{ .no_emitter = "composed-block-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-ptr" },
        .spill64 => return .{ .no_emitter = "composed-block-spill-loc-spill64" },
        .spill128 => return .{ .no_emitter = "composed-block-spill-loc-spill128" },
    }
    try bindValueLoc(selector, name, .{ .spill64 = frame_index });
    return null;
}

fn spillPairValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
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
        .stack_scalar => return .{ .no_emitter = "composed-block-pair-spill-loc-stack64" },
        .stack128 => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128" },
        .stack128_value => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128-value" },
        .stack_i32_array => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-array" },
        .stack_i32_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-ptr" },
        .spill128 => return .{ .no_emitter = "composed-block-pair-spill-loc-spill128" },
    };
    const spill = allocatePairSpillSlots(selector, name) orelse return .{ .no_spill_envelope = "composed-block-pair-spill-slots" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
    try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
    try bindValueLoc(selector, name, .{ .spill128 = spill });
    return null;
}

fn ensurePairSpill(selector: *ComposedBlockSelector, value: ir.Value) !PairSpillLoc {
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

fn emitUnsignedLimbProduct(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, name: []const u8) !PairSpillLoc {
    try prepareFixedProductDefs(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .mul_rax_arg64_full = .rcx });
    try bindFixedProductResult(selector, name);
    return switch (valueLoc(selector, name) orelse return error.UnsupportedCodegenValue) {
        .spill128 => |spill| spill,
        else => error.UnsupportedCodegenValue,
    };
}

fn accumulateLimbWithCarry(selector: *ComposedBlockSelector, lhs: FrameIndex, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try selector.machine.instructions.append(selector.allocator, .adc_rax_imm0);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

fn accumulateRegWithCarry(selector: *ComposedBlockSelector, lhs: ArgReg, rhs: FrameIndex, sum: ArgReg, carry: ArgReg) !void {
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = rhs } });
    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = sum });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = carry });
    try selector.machine.instructions.append(selector.allocator, .adc_rax_imm0);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = carry });
}

fn emitSignedUpperCorrection(selector: *ComposedBlockSelector, sign_limb: FrameIndex, subtract: PairSpillLoc) !void {
    const correction_label = try ownedEdgeLabel(selector);
    const end_label = try ownedEdgeLabel(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = sign_limb } });
    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .js = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = end_label });
    try selector.machine.instructions.append(selector.allocator, .{ .label = correction_label });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.lo } });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .r9 });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = subtract.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rdx });
    try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
}

fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
    if (selector.spill_slots.get(name)) |assignment| return spillFrameIndexMaybe(assignment.base);
    const base = selector.next_spill_slot;
    const frame_index = spillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and !frameIndexFitsFrame(selector, frame_index)) return null;
    selector.spill_slots.put(name, .{ .base = base, .slots = 1 }) catch return null;
    selector.next_spill_slot = base + 1;
    return frame_index;
}

fn allocatePairSpillSlots(selector: *ComposedBlockSelector, name: []const u8) ?PairSpillLoc {
    if (selector.spill_slots.get(name)) |assignment| {
        if (assignment.slots < 2) return null;
        return pairSpillFrameIndexMaybe(assignment.base);
    }
    const base = selector.next_spill_slot;
    const spill = pairSpillFrameIndexMaybe(base) orelse return null;
    if (selector.stack_frame_bytes != 0 and (!frameIndexFitsFrame(selector, spill.lo) or !frameIndexFitsFrame(selector, spill.hi))) return null;
    selector.spill_slots.put(name, .{ .base = base, .slots = 2 }) catch return null;
    selector.next_spill_slot = base + 2;
    return spill;
}

fn spillFrameIndex(index: usize) FrameIndex {
    return spillFrameIndexMaybe(index) orelse unreachable;
}

fn spillFrameIndexMaybe(index: usize) ?FrameIndex {
    const byte_offset = std.math.mul(usize, index, 8) catch return null;
    return frameIndexForByteOffset(byte_offset);
}

fn frameIndexForByteOffset(byte_offset: usize) ?FrameIndex {
    if (byte_offset % 4 != 0) return null;
    return FrameIndex.fromSlot(byte_offset / 4) catch null;
}

fn pairSpillFrameIndexMaybe(index: usize) ?PairSpillLoc {
    const lo = spillFrameIndexMaybe(index) orelse return null;
    const hi = spillFrameIndexMaybe(index + 1) orelse return null;
    return .{ .lo = lo, .hi = hi };
}

pub fn emitValueIntoEax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    switch (value) {
        .int => |int| {
            try clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
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
                .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                .eax, .rax => {},
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitValueIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
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
                .arg32, .scratch32, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
    if (bits == 64) try emitValueIntoRax(selector, value) else try emitValueIntoEax(selector, value);
}

fn preserveCurrentEaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveEaxName(selector) orelse return null;
    const dst = scratch64RegForUseAvoiding(selector, null) orelse {
        try spillValueOrError(selector, name);
        return null;
    };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch32 = dst });
    return null;
}

fn preserveCurrentRaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
    const name = liveRaxName(selector) orelse return null;
    const dst = scratch64RegForUseAvoiding(selector, null) orelse
        return .{ .no_spill_envelope = "composed-block-preserve-rax" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    try bindValueLoc(selector, name, .{ .scratch64 = dst });
    return null;
}

fn scratchRegIsProvenFree(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return false,
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return false,
            .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| if (index.reg == reg) return false,
            .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => {},
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
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
    }
}

fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    try emitValueIntoScratchExcept(selector, value, reg, bits, null);
}

fn emitPhiValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
    switch (value) {
        .named => {
            const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
            if (bits == 64) {
                switch (loc) {
                    .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = src } }),
                    .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = pair.lo } }),
                    .arg32, .scratch32, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            } else {
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = src } }),
                    .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = pair.lo } }),
                    .eax, .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg }),
                    .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                    .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            }
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn phiSourceDiagnostic(selector: *const ComposedBlockSelector, value: ir.Value) []const u8 {
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
        .spill64 => "stage2-phi-src-spill64",
        .spill128 => "stage2-phi-src-spill128",
    };
}

fn emitValueIntoScratchExcept(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16, ignore_name: ?[]const u8) !void {
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
                    .arg32, .scratch32, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
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
                    .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            }
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

fn emitBinaryArgAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, reg: ArgReg, bits: u16) !void {
    if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
            .op = op,
            .reg = reg,
        } });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{
            .op = op,
            .reg = reg,
        } });
    }
}

fn emitBinaryLocIntoAccumulator(selector: *ComposedBlockSelector, op: MachineBinaryOp, loc: ValueLoc, bits: u16) !void {
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
        .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
    };
    try emitBinaryArgAccumulator(selector, op, reg, bits);
}

pub fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
    if (amount > 127) return error.UnsupportedCodegenValue;
    const existing = resolvePairValue(selector, value);
    const dst = if (existing) |src|
        choosePairScratch(selector, src) orelse return error.UnsupportedCodegenValue
    else
        choosePairScratch(selector, null) orelse return error.UnsupportedCodegenValue;
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

fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
    if (src.eql(dst)) return;
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst.lo);
    try clobberArgReg(selector, dst.hi);
    if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
    if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
}

fn materializePairValue(selector: *ComposedBlockSelector, value: ir.Value, dst: RegPair) !RegPair {
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
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
    }
}

fn emitPairLowLaneIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, dst: ArgReg) !void {
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
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
    }
}

fn emitPairHighLaneIntoRax(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const loc = resolveValue(selector, value) orelse return error.UnsupportedCodegenValue;
    try clobberAccumulator(selector);
    switch (loc) {
        .arg128, .scratch128 => |pair| try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.hi }),
        .stack128_value => |disp| if (disp + 8 <= std.math.maxInt(u8))
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp + 8) })
        else
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp + 8 }),
        .spill128 => |spill| try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.hi }),
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
    }
}

fn emitPairSignMask(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, dst: RegPair) !void {
    const src = try materializePairValue(selector, value, dst);
    if (src.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = dst.lo, .amount = 63 } });
    if (dst.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
    try bindPairScratch(selector, result_name, dst);
}

fn emitPairXorInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .xor, dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .xor, dst.hi, rhs.hi);
}

fn emitPairOrInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try emitPairLaneBinaryInto(selector, dst.lo, .@"or", dst.lo, rhs.lo);
    try emitPairLaneBinaryInto(selector, dst.hi, .@"or", dst.hi, rhs.hi);
}

fn emitPairSubInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
    try clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = rhs.lo } });
    try clobberArgReg(selector, dst.lo);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
    try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = rhs.hi });
    try clobberArgReg(selector, dst.hi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
}

fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
    try clobberAccumulator(selector);
    try clobberArgReg(selector, dst);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
        .op = op,
        .reg = rhs,
    } });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
}

fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
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

fn choosePairScratch(selector: *const ComposedBlockSelector, src: ?RegPair) ?RegPair {
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (pairScratchIsAvailableForUse(selector, pair)) return pair;
    }
    return null;
}

fn choosePairScratchForClobber(selector: *const ComposedBlockSelector, src: ?RegPair) ?RegPair {
    if (!nextSpillSlotsFit(selector, 2)) return choosePairScratch(selector, src);
    for (selector_allocatable_pairs) |pair| {
        if (src) |source| if (source.eql(pair)) continue;
        if (livePairNameContainingReg(selector, pair.lo) != null) continue;
        if (livePairNameContainingReg(selector, pair.hi) != null) continue;
        return pair;
    }
    return null;
}

fn nextSpillSlotsFit(selector: *const ComposedBlockSelector, slots: usize) bool {
    if (slots == 0) return true;
    const last = std.math.add(usize, selector.next_spill_slot, slots - 1) catch return false;
    const frame_index = spillFrameIndexMaybe(last) orelse return false;
    return frameIndexFitsFrame(selector, frame_index);
}

fn pairScratchIsAvailableForUse(selector: *const ComposedBlockSelector, pair: RegPair) bool {
    return scratch64RegIsAvailableForUse(selector, pair.lo) and scratch64RegIsAvailableForUse(selector, pair.hi);
}

fn clobberArgReg(selector: *ComposedBlockSelector, reg: ArgReg) !void {
    try clobberArgRegExcept(selector, reg, null);
}

fn clobberArgRegExcept(selector: *ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !void {
    while (pairNameContainingRegExcept(selector, reg, ignore_name)) |name| {
        if (valueMustSurviveClobber(selector, name)) {
            try spillPairValueOrError(selector, name);
        } else {
            _ = selector.values.remove(name);
        }
    }
    while (scalarNameInRegExcept(selector, reg, ignore_name)) |name| {
        if (valueMustSurviveClobber(selector, name)) {
            try spillValueOrError(selector, name);
        } else {
            _ = selector.values.remove(name);
        }
    }
}

fn valueMustSurviveClobber(selector: *const ComposedBlockSelector, name: []const u8) bool {
    if (selector.phi_results.contains(name)) return true;
    return if (selector.preserve_current_position_values)
        valueIsLiveAtOrAfterCurrent(selector, name)
    else
        valueIsLiveAfterCurrent(selector, name);
}

fn clobberAccumulator(selector: *ComposedBlockSelector) !void {
    dropExpiredAccumulatorBindings(selector);
    while (liveAccumulatorName(selector)) |name| {
        try spillValueOrError(selector, name);
    }
}

fn spillAccumulatorAliasesExcept(selector: *ComposedBlockSelector, value: ir.Value) !void {
    const ignored = switch (value) {
        .named => |name| name,
        else => return,
    };
    while (liveAccumulatorNameExcept(selector, ignored)) |name| {
        try spillValueOrError(selector, name);
    }
}

fn liveAccumulatorNameExcept(selector: *const ComposedBlockSelector, ignored: []const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        if (!valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn dropExpiredAccumulatorBindings(selector: *ComposedBlockSelector) void {
    while (true) {
        var expired_name: ?[]const u8 = null;
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.loc) {
                .eax, .rax => {},
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => continue,
            }
            if (valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
            expired_name = entry.key_ptr.*;
            break;
        }
        if (expired_name) |name| {
            _ = selector.values.remove(name);
            continue;
        }
        break;
    }
}

fn spillLiveCallerClobbersForCall(selector: *ComposedBlockSelector) !?Diagnostic {
    if (try spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    for (selector_allocatable_regs) |reg| {
        if (livePairNameContainingReg(selector, reg)) |name| {
            if (try spillPairValue(selector, name)) |diagnostic| return diagnostic;
        }
        if (liveScalarNameInReg(selector, reg)) |name| {
            if (try spillValue(selector, name)) |diagnostic| return diagnostic;
        }
    }
    return null;
}

fn liveAccumulatorName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAtOrAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn liveAccumulatorNameAfterCurrent(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax, .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn valueIsLiveAtOrAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) bool {
    const plan = selector.allocation_plan orelse return false;
    const end = plan.intervalEnd(name) orelse return true;
    return end >= selector.current_position;
}

fn liveEaxName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .eax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .rax, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn liveRaxName(selector: *const ComposedBlockSelector) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .rax => return entry.key_ptr.*,
            .arg32, .arg64, .arg128, .eax, .scratch32, .scratch64, .scratch128, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn liveScalarNameInReg(selector: *const ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
    return liveScalarNameInRegExcept(selector, reg, null);
}

fn scalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn liveScalarNameInRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
            .arg128, .scratch128, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn livePairNameContainingReg(selector: *const ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
    return livePairNameContainingRegExcept(selector, reg, null);
}

fn pairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn livePairNameContainingRegExcept(selector: *const ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        if (ignore_name) |ignored| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
        }
        if (!valueIsLiveAfterCurrent(selector, entry.key_ptr.*)) continue;
        switch (entry.value_ptr.loc) {
            .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
        }
    }
    return null;
}

fn valueIsLiveAfterCurrent(selector: *const ComposedBlockSelector, name: []const u8) bool {
    const plan = selector.allocation_plan orelse return false;
    var it = selector.values.iterator();
    while (it.next()) |entry| {
        const stack_ptr = switch (entry.value_ptr.loc) {
            .stack_i32_ptr => |stack_ptr| stack_ptr,
            else => continue,
        };
        const index = stack_ptr.index orelse continue;
        if (!std.mem.eql(u8, index.name, name) and
            (index.addend_name == null or !std.mem.eql(u8, index.addend_name.?, name))) continue;
        const pointer_end = plan.intervalEnd(entry.key_ptr.*) orelse return true;
        if (pointer_end > selector.current_position) return true;
    }
    const end = plan.intervalEnd(name) orelse return true;
    return end > selector.current_position;
}

fn spillValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

fn spillPairValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
    if (try spillPairValue(selector, name)) |_| return error.UnsupportedCodegenValue;
}

fn resolvePairValue(selector: *const ComposedBlockSelector, value: ir.Value) ?RegPair {
    const loc = resolveValue(selector, value) orelse return null;
    return switch (loc) {
        .arg128, .scratch128 => |pair| pair,
        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => null,
    };
}

fn resolveValue(selector: *const ComposedBlockSelector, value: ir.Value) ?ValueLoc {
    return switch (value) {
        .named => |name| {
            const loc = valueLoc(selector, name) orelse return null;
            return switch (loc) {
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128 => loc,
                .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => loc,
                .stack_i32_ptr => loc,
            };
        },
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
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
    if (try prepareStackFrame(&composed, function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try lowerInstruction(&composed, instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    try expireExpiredBindings(&composed);
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
