const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");

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
    composed.enable_expired_plan_register_reuse = canUseExpiredPlanRegisterReuse(function);
    defer composed.deinit();

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.bindPhiResults(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.prepareStackFrame(function)) |diagnostic| return unsupported(diagnostic);
    if (composed.stack_frame_bytes != 0) {
        composed.return_epilogue_label = try composed.ownedReturnEpilogueLabel();
    }

    for (function.blocks.items, 0..) |block, block_index| {
        if (block_index != 0) try machine.instructions.append(allocator, .{ .label = block.name });
        if (try composed.enterBlock(block)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        for (block.instructions.items) |instruction| {
            if (try composed.lowerInstruction(instruction)) |diagnostic| {
                machine.instructions.items.len = start_len;
                return unsupported(diagnostic);
            }
        }
        const terminator = block.terminator orelse {
            machine.instructions.items.len = start_len;
            return unsupported(.{ .unsupported_control_flow = "stage2-missing-terminator" });
        };
        try composed.expireExpiredBindings();
        if (try composed.lowerCfgTerminator(function, block_index, terminator)) |diagnostic| {
            machine.instructions.items.len = start_len;
            return unsupported(diagnostic);
        }
        composed.current_position += 1;
    }
    if (composed.return_epilogue_label) |label| {
        try machine.instructions.append(allocator, .{ .label = label });
        try composed.appendAddRsp(composed.stack_frame_bytes);
        try machine.instructions.append(allocator, .ret);
    }
    return .selected;
}

pub const ComposedBlockSelector = struct {
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    allocation_plan: ?*const SelectorAllocationPlan = null,
    values: std.StringHashMap(ValueBinding),
    phi_results: NameSet,
    phi_destinations: std.StringHashMap(ValueLoc),
    next_virtual_reg: usize = 0,
    edge_label_count: usize = 0,
    stack_slot_allocated: bool = false,
    stack_array_allocated: bool = false,
    stack_array_count: usize = 0,
    stack_frame_bytes: u32 = 0,
    return_epilogue_label: ?[]const u8 = null,
    current_position: usize = 1,
    expired_binding_this_position: bool = false,
    enable_expired_plan_register_reuse: bool = false,
    spill_slots: std.StringHashMap(SpillSlotAssignment),
    next_spill_slot: usize = 0,

    pub fn init(allocator: std.mem.Allocator, machine: *MachineFunction) ComposedBlockSelector {
        return .{
            .allocator = allocator,
            .machine = machine,
            .allocation_plan = null,
            .values = std.StringHashMap(ValueBinding).init(allocator),
            .phi_results = NameSet.init(allocator),
            .phi_destinations = std.StringHashMap(ValueLoc).init(allocator),
            .spill_slots = std.StringHashMap(SpillSlotAssignment).init(allocator),
        };
    }

    pub fn deinit(selector: *ComposedBlockSelector) void {
        selector.spill_slots.deinit();
        selector.phi_destinations.deinit();
        selector.phi_results.deinit();
        selector.values.deinit();
    }

    fn bindParams(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        if (function.params.items.len > 6) return .{ .unsupported_value = "composed-block-too-many-params" };
        var abi_index: usize = 0;
        for (function.params.items) |param| {
            const reg = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-param-reg" };
            if (param.ty == .ptr) {
                try selector.bindValueLoc(param.name, .{ .arg64 = reg });
            } else {
                const bits = intBits(param.ty) orelse return .{ .no_emitter = "composed-block-param-not-scalar" };
                switch (bits) {
                    32 => try selector.bindValueLoc(param.name, .{ .arg32 = reg }),
                    64 => try selector.bindValueLoc(param.name, .{ .arg64 = reg }),
                    128 => {
                        const high = ArgReg.fromIndex(abi_index + 1) catch return .{ .unsupported_value = "composed-block-param-reg" };
                        try selector.bindValueLoc(param.name, .{ .arg128 = .{ .lo = reg, .hi = high } });
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
                const reg = nextPhiReg(&used_in_block) orelse return .{ .no_spill_envelope = "stage2-phi-registers" };
                const destination: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
                try selector.phi_results.put(result_name, {});
                try selector.phi_destinations.put(result_name, destination);
                try selector.bindValueLoc(result_name, destination);
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
            try selector.bindValueLoc(result_name, loc);
            switch (loc) {
                .scratch32, .scratch64 => {},
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn lowerInstruction(selector: *ComposedBlockSelector, instruction: ir.Instruction) !?Diagnostic {
        if (instruction.removed) return null;
        try selector.expireExpiredBindings();
        defer selector.current_position += 1;
        return switch (instruction.kind) {
            .phi => null,
            .binary => |binary| selector.lowerBinary(instruction.result, binary) catch |err| return selector.instructionValueError(err, "stage2-binary-value"),
            .alloca => |alloca| selector.lowerAlloca(instruction.result, alloca) catch |err| return selector.instructionValueError(err, "stage2-alloca-value"),
            .cast => |cast| selector.lowerCast(instruction.result, cast) catch |err| return selector.instructionValueError(err, "stage2-cast-value"),
            .freeze => |freeze| selector.lowerFreeze(instruction.result, freeze) catch |err| return selector.instructionValueError(err, "stage2-freeze-value"),
            .icmp => |icmp| selector.lowerIcmp(instruction.result, icmp) catch |err| return selector.instructionValueError(err, "stage2-icmp-value"),
            .load => |load| selector.lowerLoad(instruction.result, load) catch |err| return selector.instructionValueError(err, "stage2-load-value"),
            .store => |store| selector.lowerStore(store) catch |err| return selector.instructionValueError(err, "stage2-store-value"),
            .gep => |gep| selector.lowerGep(instruction.result, gep) catch |err| return selector.instructionValueError(err, "stage2-gep-value"),
            .call => |call| selector.lowerCall(instruction.result, call) catch |err| return selector.instructionValueError(err, "stage2-call-value"),
            .select => |select| selector.lowerSelect(instruction.result, select) catch |err| return selector.instructionValueError(err, "stage2-select-value"),
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
        if (selector.valueLoc(result_name)) |loc| switch (loc) {
            .stack64, .stack128, .stack_i32_array => return null,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => {},
        };
        if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
        if (alloca.allocated_ty.eql(.{ .int = 64 })) {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            try selector.appendSubRsp(24);
            selector.stack_slot_allocated = true;
            selector.stack_frame_bytes = 24;
            try selector.bindValueLoc(result_name, .{ .stack64 = 0 });
            return null;
        }
        if (alloca.allocated_ty.eql(.{ .int = 128 })) {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            const frame_bytes = stack128FrameBytes();
            try selector.appendSubRsp(frame_bytes);
            selector.stack_slot_allocated = true;
            selector.stack_frame_bytes = frame_bytes;
            try selector.bindValueLoc(result_name, .{ .stack128 = 0 });
            return null;
        }
        if (parseI32ArrayType(alloca.allocated_ty)) |len| {
            if (selector.stack_slot_allocated or selector.stack_array_allocated) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
            const payload_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
            const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
            try selector.appendSubRsp(frame_bytes);
            selector.stack_array_allocated = true;
            selector.stack_frame_bytes = frame_bytes;
            try selector.bindValueLoc(result_name, .{ .stack_i32_array = .{ .base_disp = 0, .len = len } });
            return null;
        }
        return .{ .no_emitter = "composed-block-alloca-form" };
    }

    fn prepareStackFrame(selector: *ComposedBlockSelector, function: ir.Function) !?Diagnostic {
        var payload_bytes: u32 = 0;
        var scalar_slot_count: usize = 0;
        var array_count: usize = 0;
        var saw_phi = false;
        if (selector.allocation_plan) |plan| selector.next_spill_slot = plan.spill_slots;

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.kind == .phi) saw_phi = true;
            }
        }

        const pressure = try analyzeStageTwoNoSpillEnvelope(selector.allocator, function);
        const reserve_spill_area = pressure.exceedsNoSpill() or saw_phi or (selector.allocation_plan != null and selector.allocation_plan.?.spill_slots != 0);
        const spill_reserved_bytes = selector.spillReservedBytes(reserve_spill_area) orelse return .{ .no_spill_envelope = "composed-block-spill-frame-size" };

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.kind != .alloca) continue;
                const result_name = instruction.result orelse return .{ .unsupported_value = "composed-block-missing-result" };
                const alloca = instruction.kind.alloca;
                if (alloca.allocated_ty_addrspace != null) return .{ .no_emitter = "composed-block-alloca-addrspace" };
                if (alloca.allocated_ty.eql(.{ .int = 64 })) {
                    if (payload_bytes != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    scalar_slot_count += 1;
                    if (scalar_slot_count > 1) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    const base_disp = spill_reserved_bytes;
                    payload_bytes = std.math.add(u32, base_disp, 8) catch return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    try selector.bindValueLoc(result_name, .{ .stack64 = base_disp });
                } else if (parseI32ArrayType(alloca.allocated_ty)) |len| {
                    if (scalar_slot_count != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    if (array_count == 0) payload_bytes = if (reserve_spill_area) spill_reserved_bytes else stage2SpillReservedBytes();
                    array_count += 1;
                    if (array_count > 4) return .{ .no_spill_envelope = "composed-block-stack-array-count" };
                    const array_bytes = std.math.mul(u32, len, 4) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                    const base_disp = payload_bytes;
                    payload_bytes = std.math.add(u32, payload_bytes, array_bytes) catch return .{ .no_spill_envelope = "composed-block-stack-array-size" };
                    try selector.bindValueLoc(result_name, .{ .stack_i32_array = .{ .base_disp = base_disp, .len = len } });
                } else if (alloca.allocated_ty.eql(.{ .int = 128 })) {
                    if (payload_bytes != 0) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    scalar_slot_count += 1;
                    if (scalar_slot_count > 1) return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    const base_disp = spill_reserved_bytes;
                    payload_bytes = std.math.add(u32, base_disp, stack128FrameBytes() - 8) catch return .{ .no_spill_envelope = "composed-block-stack-slot-count" };
                    try selector.bindValueLoc(result_name, .{ .stack128 = base_disp });
                } else {
                    return .{ .no_emitter = "composed-block-alloca-form" };
                }
            }
        }

        if (payload_bytes == 0) {
            if (pressure.exceedsNoSpill() or saw_phi) payload_bytes = spill_reserved_bytes;
        }

        if (payload_bytes == 0) return null;
        const frame_bytes = alignedCallFrameBytes(payload_bytes) orelse return .{ .no_spill_envelope = "composed-block-stack-array-size" };
        try selector.appendSubRsp(frame_bytes);
        selector.stack_frame_bytes = frame_bytes;
        selector.stack_slot_allocated = scalar_slot_count != 0;
        selector.stack_array_allocated = array_count != 0;
        selector.stack_array_count = array_count;
        return null;
    }

    fn spillReservedBytes(selector: ComposedBlockSelector, reserve_spill_area: bool) ?u32 {
        if (!reserve_spill_area) return 0;
        const planned_slots = if (selector.allocation_plan) |plan| plan.spill_slots else selector.next_spill_slot;
        const reserved_slots = @max(planned_slots, stage2_spill_slots);
        return std.math.mul(u32, std.math.cast(u32, reserved_slots) orelse return null, 8) catch null;
    }

    pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
        if (bits != 6 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-binary-width" };

        if (valueIsInt(binary.rhs)) {
            return try selector.lowerBinaryImmediateRhs(result_name, binary);
        }
        if (valueIsInt(binary.lhs)) {
            return try selector.lowerBinaryImmediateLhs(result_name, binary);
        }
        if (bits == 128) return try selector.lowerPairBinary(result_name, binary);

        if (binary.op == .mul and bits == 64) return try selector.lowerMul64(result_name, binary);
        if ((binary.op == .udiv or binary.op == .urem) and bits == 64) {
            return try selector.lowerUnsignedDivRem64(result_name, binary);
        }
        if ((binary.op == .shl or binary.op == .lshr) and bits == 32) {
            try selector.emitValueIntoScratch(binary.rhs, .rcx, bits);
            try selector.emitValueIntoEax(binary.lhs);
            try selector.machine.instructions.append(selector.allocator, switch (binary.op) {
                .shl => .shl_eax_cl,
                .lshr => .shr_eax_cl,
                else => unreachable,
            });
            try selector.bindEax(result_name);
            return null;
        }

        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

        if (locIsAccumulator(rhs) and !locIsAccumulator(lhs)) {
            if (isCommutative(op)) {
                try selector.spillAccumulatorAliasesExcept(binary.rhs);
                try selector.emitBinaryLocIntoAccumulator(op, lhs, bits);
            } else {
                const rhs_scratch: ArgReg = switch (lhs) {
                    .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
                    .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => .rcx,
                    .eax, .rax => unreachable,
                };
                try selector.emitValueIntoScratch(binary.rhs, rhs_scratch, bits);
                if (locIsAccumulator(lhs)) try selector.spillAccumulatorAliasesExcept(binary.lhs);
                try selector.emitValueIntoAccumulator(binary.lhs, bits);
                try selector.emitBinaryArgAccumulator(op, rhs_scratch, bits);
            }
        } else {
            if (locIsAccumulator(lhs)) try selector.spillAccumulatorAliasesExcept(binary.lhs);
            try selector.emitValueIntoAccumulator(binary.lhs, bits);
            const rhs_reg: ArgReg = switch (rhs) {
                .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-i32-for-i64" },
                .arg64, .scratch64 => |reg| if (bits == 64) reg else return .{ .no_emitter = "composed-block-rhs-i64-for-i32" },
                .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
                .spill64 => |frame_index| if (bits == 64) blk: {
                    try selector.clobberArgReg(.rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    break :blk .rcx;
                } else if (bits <= 32) blk: {
                    try selector.clobberArgReg(.rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    break :blk .rcx;
                } else return .{ .no_emitter = "composed-block-rhs-stack" },
                .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-rhs-stack" },
                .eax, .rax => return .{ .no_spill_envelope = "composed-block-two-address-rhs-accumulator" },
            };
            try selector.emitBinaryArgAccumulator(op, rhs_reg, bits);
        }

        try selector.bindAccumulator(result_name, bits);
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
                    try selector.emitPairLshrImmediate(result_name, binary.lhs, amount);
                    return null;
                }
                switch (bits) {
                    16, 32 => {
                        try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                        const amount = try shiftAmount5(rhs);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                            .reg = .rcx,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, .rcx, bits);
                    },
                    64 => {
                        const amount = try shiftAmount6(rhs);
                        const dst = selector.plannedScratch64RegForResult(result_name) orelse
                            selector.scratch64RegForUseAvoiding(null) orelse
                            selector.reusableScratch64RegForInPlace(binary.lhs) orelse
                            blk: {
                                if (try selector.spillScratch64SourceForInPlace(binary.lhs)) |spill_result| switch (spill_result) {
                                    .reg => |reg| break :blk reg,
                                    .diagnostic => |diagnostic| return diagnostic,
                                };
                                if (try selector.tryLowerLshr64SpillThroughRax(result_name, binary.lhs, amount)) |diagnostic| return diagnostic;
                                return null;
                            };
                        try selector.emitValueIntoScratch(binary.lhs, dst, bits);
                        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{
                            .reg = dst,
                            .amount = amount,
                        } });
                        try selector.bindScratch(result_name, dst, bits);
                    },
                    else => return .{ .no_emitter = "composed-block-binary-width" },
                }
            },
            .shl => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    try selector.emitPairShlImmediate(result_name, binary.lhs, amount);
                    return null;
                }
                if (bits == 64) {
                    const amount = try shiftAmount6(rhs);
                    if (try selector.preserveRaxForDestructiveAccumulatorUse(binary.lhs)) |diagnostic| return diagnostic;
                    try selector.emitValueIntoRax(binary.lhs);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = amount });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits > 32) return .{ .no_emitter = "composed-block-shl-imm-width" };
                const amount = try shiftAmount5(rhs);
                const lhs_loc = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
                if (try selector.preserveCurrentEaxIntoScratch()) |diagnostic| return diagnostic;
                try selector.emitValueIntoEax(binary.lhs);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_eax_imm5 = amount });
                switch (lhs_loc) {
                    .scratch32 => |reg| {
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                        try selector.bindScratch(result_name, reg, bits);
                    },
                    .arg32, .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => try selector.bindEax(result_name),
                }
            },
            .ashr => {
                if (bits == 128) {
                    const amount = try shiftAmount7(rhs);
                    if (amount != 127) return .{ .no_emitter = "composed-block-ashr-i128-amount" };
                    try selector.emitPairSignMask(result_name, binary.lhs, pair_a);
                    return null;
                }
                if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
                const amount = try shiftAmount6(rhs);
                try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{
                    .reg = .rcx,
                    .amount = amount,
                } });
                try selector.bindScratch(result_name, .rcx, bits);
                if (try selector.spillValue(result_name)) |diagnostic| return diagnostic;
            },
            .@"and" => {
                if (bits == 64 and rhs == std.math.maxInt(u32)) {
                    if (try selector.preserveRaxForDestructiveAccumulatorUse(binary.lhs)) |diagnostic| return diagnostic;
                    selector.emitValueIntoRax(binary.lhs) catch |err| switch (err) {
                        error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                        else => return err,
                    };
                    const imm = i32BitPattern(rhs) catch return .{ .no_emitter = "composed-block-and64-imm" };
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = imm });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits == 64) {
                    if (try selector.preserveRaxForDestructiveAccumulatorUse(binary.lhs)) |diagnostic| return diagnostic;
                    selector.emitValueIntoRax(binary.lhs) catch |err| switch (err) {
                        error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                        else => return err,
                    };
                    try selector.clobberArgReg(.rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .@"or" => {
                if (bits == 64) {
                    if (try selector.preserveRaxForDestructiveAccumulatorUse(binary.lhs)) |diagnostic| return diagnostic;
                    selector.emitValueIntoRax(binary.lhs) catch return .{ .unsupported_value = "composed-block-or64-lhs" };
                    try selector.clobberArgReg(.rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } });
                    try selector.bindRax(result_name);
                    return null;
                }
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector.emitValueIntoEax(binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
                try selector.bindEax(result_name);
            },
            .add => {
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = try i32Value(rhs) } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                    try selector.bindEax(result_name);
                }
            },
            .sub => {
                const imm = try i32Value(rhs);
                if (bits == 64) {
                    try selector.emitValueIntoScratch(binary.lhs, .rcx, bits);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                    try selector.bindScratch(result_name, .rcx, bits);
                } else {
                    if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                    try selector.emitValueIntoEax(binary.lhs);
                    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -imm });
                    try selector.bindEax(result_name);
                }
            },
            else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
        }
        return null;
    }

    fn lowerSelect(selector: *ComposedBlockSelector, result: ?[]const u8, select: ir.SelectInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (!select.cond_ty.eql(.{ .int = 1 })) return .{ .no_emitter = "composed-block-select-cond" };
        const bits = intBits(select.ty) orelse return .{ .no_emitter = "composed-block-select-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-select-width" };

        if (try selector.emitBranchCondition(select.cond)) |diagnostic| return diagnostic;
        if (select.true_value == .named) {
            const true_name = select.true_value.named;
            switch (selector.resolveValue(select.true_value) orelse return .{ .unsupported_value = "composed-block-select-true-value" }) {
                .eax => {
                    _ = try selector.preserveCurrentEaxIntoScratch();
                    if (selector.resolveValue(select.true_value)) |preserved| switch (preserved) {
                        .eax => try selector.spillValueOrError(true_name),
                        else => {},
                    };
                },
                .rax => try selector.spillValueOrError(true_name),
                else => {},
            }
        }
        selector.emitValueIntoAccumulator(select.false_value, bits) catch return .{ .unsupported_value = "composed-block-select-false-value" };
        const end_label = try selector.ownedSelectEndLabel();
        try selector.machine.instructions.append(selector.allocator, .{ .je = end_label });
        selector.emitValueIntoAccumulator(select.true_value, bits) catch return .{ .unsupported_value = "composed-block-select-true-value" };
        try selector.machine.instructions.append(selector.allocator, .{ .label = end_label });
        try selector.bindAccumulator(result_name, bits);
        return null;
    }

    fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
        switch (op) {
            .xor => {
                const lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                const rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                try selector.emitPairXorInPlace(rhs, lhs);
                try selector.bindPairScratch(result_name, rhs);
            },
            .@"or" => {
                const lhs_existing = selector.resolvePairValue(binary.lhs);
                const rhs_existing = selector.resolvePairValue(binary.rhs);
                if (lhs_existing) |lhs_pair| {
                    if (rhs_existing) |rhs_pair| {
                        try selector.emitPairOrInPlace(lhs_pair, rhs_pair);
                        try selector.bindPairScratch(result_name, lhs_pair);
                        return null;
                    }
                }
                var lhs: RegPair = undefined;
                var rhs: RegPair = undefined;
                if (lhs_existing) |existing| {
                    if (existing.eql(pair_b)) {
                        lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                        rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    } else {
                        rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                        lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                    }
                } else {
                    rhs = selector.materializePairValue(binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    lhs = selector.materializePairValue(binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                }
                try selector.emitPairOrInPlace(rhs, lhs);
                try selector.bindPairScratch(result_name, rhs);
            },
            .sub => {
                const lhs = selector.materializePairValue(binary.lhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                const rhs = selector.materializePairValue(binary.rhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                try selector.emitPairSubInPlace(lhs, rhs);
                try selector.bindPairScratch(result_name, lhs);
            },
            else => return .{ .no_emitter = "composed-block-pair-binary-op" },
        }
        return null;
    }

    pub fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const lhs = selector.resolveValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const dst = switch (lhs) {
            .scratch64 => |reg| if (selector.allocation_plan == null)
                reg
            else
                selector.reusableScratch64RegForInPlace(binary.lhs) orelse
                    selector.plannedScratch64RegForResult(result_name) orelse
                    selector.scratch64RegForUseAvoiding(null) orelse
                    blk: {
                        if (try selector.spillScratch64SourceForInPlace(binary.lhs)) |spill_result| switch (spill_result) {
                            .reg => |spilled_reg| break :blk spilled_reg,
                            .diagnostic => |diagnostic| return diagnostic,
                        };
                        return .{ .no_spill_envelope = "composed-block-mul64-dst" };
                    },
            .arg64, .rax, .spill64 => selector.plannedScratch64RegForResult(result_name) orelse
                (selector.scratch64RegForUseAvoiding(null) orelse {
                    if (lhs == .spill64) return try selector.lowerMul64SpillLhsThroughRax(result_name, lhs.spill64, binary.rhs);
                    return .{ .no_spill_envelope = "composed-block-mul64-dst" };
                }),
            .arg32, .scratch32, .arg128, .scratch128, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-lhs" },
        };
        selector.emitValueIntoScratch(binary.lhs, dst, 64) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };

        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        switch (rhs) {
            .scratch64, .arg64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } }),
            .spill64 => |frame_index| {
                if (selector.scratch64RegForUseAvoiding(dst)) |src| {
                    selector.emitValueIntoScratch(binary.rhs, src, 64) catch return .{ .unsupported_value = "composed-block-mul64-rhs" };
                    try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
                } else {
                    if (try selector.spillCurrentAccumulator()) |diagnostic| return diagnostic;
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                    try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_rax = dst });
                }
            },
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
        }
        try selector.bindScratch(result_name, dst, 64);
        return null;
    }

    fn lowerMul64SpillLhsThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, lhs_frame_index: FrameIndex, rhs_value: ir.Value) !?Diagnostic {
        if (try selector.spillCurrentAccumulator()) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs_frame_index });
        const rhs = selector.resolveValue(rhs_value) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        switch (rhs) {
            .arg64, .scratch64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64 = src }),
            .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_rsp = frame_index }),
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-mul64-rhs" },
        }
        try selector.bindRax(result_name);
        return null;
    }

    fn plannedScratch64RegForResult(selector: ComposedBlockSelector, name: []const u8) ?ArgReg {
        const plan = selector.allocation_plan orelse return null;
        const assignment = plan.assignment(name) orelse return null;
        const reg = switch (assignment) {
            .gpr64 => |reg| reg,
            .gpr32, .gpr128, .stack_object, .stack_pointer, .spill => return null,
        };
        return if (selector.scratch64RegIsAvailableForUse(reg)) reg else null;
    }

    fn scratch64RegForUseAvoiding(selector: ComposedBlockSelector, avoid: ?ArgReg) ?ArgReg {
        for (selector_allocatable_regs) |reg| {
            if (avoid != null and reg == avoid.?) continue;
            if (selector.scratch64RegIsAvailableForUse(reg)) return reg;
        }
        return null;
    }

    fn reusableScratch64RegForInPlace(selector: ComposedBlockSelector, value: ir.Value) ?ArgReg {
        const name = namedValue(value) orelse return null;
        const loc = selector.resolveValue(value) orelse return null;
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
        const loc = selector.resolveValue(value) orelse return null;
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

        if (try selector.spillValue(name)) |diagnostic| return .{ .diagnostic = diagnostic };
        return .{ .reg = reg };
    }

    fn tryLowerLshr64SpillThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u6) !?Diagnostic {
        const loc = selector.resolveValue(value) orelse return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
        const frame_index = switch (loc) {
            .spill64 => |frame_index| frame_index,
            else => return .{ .no_spill_envelope = "composed-block-lshr64-dst" },
        };
        if (try selector.spillCurrentAccumulator()) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
        if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = amount });
        try selector.bindRax(result_name);
        return null;
    }

    fn scratch64RegIsAvailableForUse(selector: ComposedBlockSelector, reg: ArgReg) bool {
        const status = selector.regConflictStatus(reg) orelse return true;
        return status;
    }

    fn lowerUnsignedDivRem64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
        const rhs = selector.resolveValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        if (rhs == .rax) {
            try selector.emitValueIntoScratch(binary.rhs, .rcx, 64);
            try selector.emitValueIntoRax(binary.lhs);
        } else {
            try selector.emitValueIntoRax(binary.lhs);
            try selector.emitValueIntoScratch(binary.rhs, .rcx, 64);
        }
        try selector.clobberArgReg(.rdx);
        try selector.machine.instructions.append(selector.allocator, .xor_edx_edx);
        try selector.machine.instructions.append(selector.allocator, .{ .div_arg64 = .rcx });
        switch (binary.op) {
            .udiv => {
                try selector.bindRax(result_name);
            },
            .urem => {
                try selector.bindScratch(result_name, .rdx, 64);
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
        if (binary.op == .sub and bits == 6) {
            try selector.emitValueIntoScratch(binary.rhs, .rcx, bits);
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
            try selector.bindEax(result_name);
            return null;
        }
        if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
        if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

        try selector.emitValueIntoScratch(binary.rhs, .rcx, bits);
        try selector.clobberAccumulator();
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .shr_eax_cl);
        try selector.bindEax(result_name);
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
                    const dst = selector.plannedScratch64RegForResult(result_name) orelse
                        if (selector.resolvePairValue(cast.value)) |pair|
                            pair.lo
                        else
                            selector.scratch64RegForUseAvoiding(null) orelse return .{ .no_spill_envelope = "composed-block-cast-scratch" };
                    selector.emitPairLowLaneIntoScratch(cast.value, dst) catch return .{ .unsupported_value = "composed-block-unknown-cast" };
                    try selector.bindScratch(result_name, dst, 64);
                } else {
                    const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                    const result_loc: ValueLoc = if (from_bits > 32 and to_bits <= 32) switch (loc) {
                        .arg64, .scratch64 => |reg| .{ .scratch32 = reg },
                        .rax => .eax,
                        .spill64 => |frame_index| .{ .spill64 = frame_index },
                        .arg32, .scratch32, .eax => loc,
                        .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-cast-width" },
                    } else loc;
                    try selector.bindValueLoc(result_name, result_loc);
                    switch (result_loc) {
                        .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
                        .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-cast-width" },
                    }
                }
            },
            .zext => {
                if (from_bits == 64 and to_bits == 128) {
                    const dst = selector.choosePairScratchForClobber(null) orelse return .{ .no_spill_envelope = "composed-block-zext-pair" };
                    try selector.emitValueIntoScratch(cast.value, dst.lo, 64);
                    try selector.emitZeroArg64(dst.hi);
                    try selector.bindPairScratch(result_name, dst);
                    return null;
                }
                if (from_bits > 32 or (to_bits > 32 and to_bits != 64)) return .{ .no_emitter = "composed-block-zext-width" };
                try selector.emitValueIntoEax(cast.value);
                if (from_bits < 32) {
                    const shift: u5 = @intCast(from_bits);
                    const mask = (@as(i32, 1) << shift) - 1;
                    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
                }
                try selector.bindAccumulator(result_name, to_bits);
            },
            .sext => {
                if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
                const loc = selector.resolveValue(cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-sext" };
                const src = switch (loc) {
                    .arg32, .scratch32 => |reg| reg,
                    .arg64, .scratch64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-sext-source" },
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
                try selector.bindScratch(result_name, dst, 64);
            },
            else => return .{ .no_emitter = "composed-block-cast-op" },
        }
        return null;
    }

    fn lowerFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        const bits = intBits(freeze.ty) orelse return .{ .no_emitter = "composed-block-freeze-type" };
        if (bits != 32 and bits != 64) return .{ .no_emitter = "composed-block-freeze-width" };
        const loc = selector.resolveValue(freeze.value) orelse return .{ .unsupported_value = "composed-block-unknown-freeze" };
        switch (loc) {
            .arg32, .scratch32, .eax => if (bits != 32) return .{ .no_emitter = "composed-block-freeze-width" },
            .arg64, .scratch64, .rax => if (bits != 64) return .{ .no_emitter = "composed-block-freeze-width" },
            .spill64 => if (bits != 64 and bits > 32) return .{ .no_emitter = "composed-block-freeze-width" },
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-freeze-loc" },
        }
        try selector.bindValueLoc(result_name, loc);
        switch (loc) {
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => unreachable,
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
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
            try selector.machine.instructions.append(selector.allocator, .setne_eax);
        } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
            .int => |int| try i64Value(int) == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        }) {
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
            try selector.machine.instructions.append(selector.allocator, .setne_eax);
        } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr)) {
            if (icmp.rhs != .named) return .{ .no_emitter = "composed-block-icmp-rhs" };
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            selector.emitValueIntoScratch(icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
        } else if (icmp.predicate == .eq) {
            const bits = intBits(icmp.operand_ty) orelse return .{ .no_emitter = "composed-block-icmp-type" };
            if (icmp.rhs == .named) {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-rhs" };
                selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                selector.emitValueIntoScratch(icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
                try selector.clobberAccumulator();
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
                try selector.machine.instructions.append(selector.allocator, .sete_eax);
                try selector.bindEax(result_name);
                return null;
            }
            const rhs = switch (icmp.rhs) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
            };
            const imm = try i64Value(rhs);
            if (imm != 0) {
                if (bits != 64) return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
                selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector.clobberAccumulator();
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = imm } });
                try selector.machine.instructions.append(selector.allocator, .sete_eax);
                try selector.bindEax(result_name);
                return null;
            }
            const loc = selector.resolveValue(icmp.lhs) orelse return .{ .unsupported_value = "composed-block-icmp-lhs" };
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
                    try selector.clobberArgReg(.rcx);
                    if (bits == 64) {
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                        try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
                    } else if (bits <= 32) {
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                        try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
                    } else return .{ .no_emitter = "composed-block-icmp-lhs-width" };
                },
                .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-icmp-lhs-loc" },
            }
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
        } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .named) {
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            selector.emitValueIntoScratch(icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .setb_eax);
        } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .int) {
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try selector.clobberArgReg(.r8);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .setb_eax);
        } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 6 }) and switch (icmp.rhs) {
            .int => |int| try i64Value(int) == -1,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        }) {
            try selector.emitValueIntoEax(icmp.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 << 5 });
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
        } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
            .int => |int| try i64Value(int) == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        }) {
            try selector.emitValueIntoRax(icmp.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
        } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 })) {
            const rhs = switch (icmp.rhs) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
            };
            selector.emitValueIntoScratch(icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
            try selector.clobberAccumulator();
            try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
            try selector.machine.instructions.append(selector.allocator, .setb_eax);
        } else return .{ .no_emitter = "composed-block-icmp-form" };
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerLoad(selector: *ComposedBlockSelector, result: ?[]const u8, load: ir.LoadInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (load.attrs.isBarrier()) return .{ .no_emitter = "composed-block-load-barrier" };
        if (!load.ty.eql(.{ .int = 32 }) and !load.ty.eql(.{ .int = 64 }) and !load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-width" };
        const ptr = selector.resolveValue(load.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-load-ptr" };
        switch (ptr) {
            .stack64 => |disp| {
                if (!load.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-load-stack-width" };
                try selector.loadStackU64IntoRax(disp);
                try selector.bindRax(result_name);
            },
            .stack128 => |disp| {
                if (!load.ty.eql(.{ .int = 128 })) return .{ .no_emitter = "composed-block-load-stack-width" };
                try selector.bindValueLoc(result_name, .{ .stack128_value = disp });
            },
            .stack_i32_ptr => |stack_ptr| {
                if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-stack-array-width" };
                try selector.appendLoadStackI32(stack_ptr);
                try selector.bindEax(result_name);
            },
            .arg64, .scratch64 => |reg| {
                if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
                try selector.clobberAccumulator();
                try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = reg });
                try selector.bindEax(result_name);
            },
            .spill64 => |frame_index| {
                if (!load.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-load-ptr-width" };
                try selector.clobberAccumulator();
                try selector.materializeLocIntoLoc(.{ .spill64 = frame_index }, .{ .scratch64 = .rcx });
                try selector.machine.instructions.append(selector.allocator, .{ .load_arg_ptr_eax = .rcx });
                try selector.bindEax(result_name);
            },
            .arg32, .arg128, .eax, .rax, .scratch32, .scratch128, .stack128_value, .stack_i32_array, .spill128 => return .{ .no_emitter = "composed-block-load-ptr" },
        }
        return null;
    }

    fn lowerStore(selector: *ComposedBlockSelector, store: ir.StoreInst) !?Diagnostic {
        if (store.attrs.isBarrier()) return .{ .no_emitter = "composed-block-store-barrier" };
        if (!store.ty.eql(.{ .int = 32 })) return .{ .no_emitter = "composed-block-store-width" };
        const ptr = selector.resolveValue(store.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-store-ptr" };
        const value_loc = switch (store.value) {
            .named => selector.resolveValue(store.value) orelse return .{ .unsupported_value = "composed-block-unknown-store-value" },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
        const value_detail = if (value_loc) |loc| switch (loc) {
            .arg32, .arg64 => "composed-block-store-value-arg",
            .scratch32, .scratch64 => "composed-block-store-value-scratch",
            .eax, .rax => "composed-block-store-value-accumulator",
            .spill64 => "composed-block-store-value-spill",
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => "composed-block-store-value-other",
        } else "composed-block-store-value-other";
        selector.emitValueIntoEax(store.value) catch return .{ .unsupported_value = value_detail };
        switch (ptr) {
            .arg64, .scratch64 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = reg }),
            .stack_i32_ptr => |stack_ptr| selector.appendStoreStackI32(stack_ptr) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-stack-index" },
                else => return err,
            },
            .stack_i32_array => |stack_array| selector.appendStoreStackI32(.{ .disp = stack_array.base_disp }) catch |err| switch (err) {
                error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-array-index" },
                else => return err,
            },
            .spill64 => |frame_index| {
                selector.materializeLocIntoLoc(.{ .spill64 = frame_index }, .{ .scratch64 = .rcx }) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-store-spill-ptr" },
                    else => return err,
                };
                try selector.machine.instructions.append(selector.allocator, .{ .store_eax_arg_ptr = .rcx });
            },
            .arg32, .scratch32, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .spill128 => return .{ .no_emitter = "composed-block-store-ptr" },
        }
        return null;
    }

    fn lowerGep(selector: *ComposedBlockSelector, result: ?[]const u8, gep: ir.GepInst) !?Diagnostic {
        const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
        if (gep.source_ty.eql(.{ .int = 8 })) return try selector.lowerBytePointerGep(result_name, gep);
        if (isI32ElementPointerSource(gep.source_ty)) return try selector.lowerI32ElementPointerGep(result_name, gep);
        const len = parseI32ArrayType(gep.source_ty) orelse return .{ .no_emitter = "composed-block-gep-source" };
        const base = selector.resolveValue(gep.ptr) orelse return .{ .unsupported_value = "composed-block-unknown-array-gep-ptr" };
        const stack_array = switch (base) {
            .stack_i32_array => |stack_array| stack_array,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-gep-ptr" },
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
                try selector.emitValueIntoScratch(elem_index.value, .rcx, 64);
                break :blk StackPtrLoc{ .disp = stack_array.base_disp, .index = .{ .reg = .rcx, .name = name } };
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-gep-dynamic-index" },
        };
        try selector.bindValueLoc(result_name, .{ .stack_i32_ptr = stack_ptr });
        return null;
    }

    fn lowerI32ElementPointerGep(selector: *ComposedBlockSelector, result_name: []const u8, gep: ir.GepInst) !?Diagnostic {
        if (gep.ptr_addrspace != null) return .{ .no_emitter = "composed-block-gep-addrspace" };
        if (gep.indices.items.len != 1) return .{ .no_emitter = "composed-block-gep-index-count" };
        const index = gep.indices.items[0];
        if (!index.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-gep-elem-index-ty" };
        if (index.value != .named) return .{ .no_emitter = "composed-block-gep-index-form" };

        if (selector.resolveValue(gep.ptr)) |base| switch (base) {
            .stack_i32_array => |stack_array| {
                selector.emitValueIntoScratch(index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
                const index_name = switch (index.value) {
                    .named => |name| name,
                    else => unreachable,
                };
                try selector.bindValueLoc(result_name, .{ .stack_i32_ptr = .{
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
                try selector.bindValueLoc(result_name, .{ .stack_i32_ptr = .{
                    .disp = stack_ptr.disp,
                    .index = .{ .reg = .rcx, .name = stack_index.name, .addend_name = addend_name },
                } });
                return null;
            },
            else => {},
        };

        selector.emitValueIntoScratch(gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-i32-element-gep-ptr" };
        selector.emitValueIntoScratch(index.value, .r8, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
        try selector.machine.instructions.append(selector.allocator, .{ .shl_r8_imm6 = 2 });
        try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
        try selector.bindScratch(result_name, .rcx, 64);
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
                if (selector.resolveValue(gep.ptr)) |base| switch (base) {
                    .stack_i32_ptr => |stack_ptr| {
                        const adjusted = std.math.add(i64, stack_ptr.disp, offset) catch return .{ .no_emitter = "composed-block-gep-index-range" };
                        const disp = std.math.cast(u32, adjusted) orelse return .{ .no_emitter = "composed-block-gep-index-range" };
                        try selector.bindValueLoc(result_name, .{ .stack_i32_ptr = .{ .disp = disp, .index = stack_ptr.index } });
                        return null;
                    },
                    else => {},
                };
                selector.emitValueIntoScratch(gep.ptr, .rcx, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
                if (offset != 0) try selector.machine.instructions.append(selector.allocator, .{ .add_rcx_imm32 = offset });
                try selector.bindScratch(result_name, .rcx, 64);
            },
            .named => {
                selector.emitValueIntoScratch(gep.ptr, .r8, 64) catch return .{ .unsupported_value = "composed-block-unknown-byte-gep-ptr" };
                selector.emitValueIntoScratch(index.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-gep-dynamic-index" };
                try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
                try selector.bindScratch(result_name, .r8, 64);
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

    fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
        if (call.isDebugVariableLocation()) return null;
        if (std.mem.eql(u8, call.callee, "llvm.assume")) return selector.lowerAssume(result, call);
        if (std.mem.eql(u8, call.callee, "zig.target.intByteSize")) return try selector.lowerIntByteSizeCall(result, call);
        if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try selector.lowerAbsI64(result, call);
        if (std.mem.eql(u8, call.callee, "llvm.abs.i128")) return try selector.lowerAbsI128(result, call);
        if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32")) return try selector.lowerCtlzI32(result, call);
        if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) return try selector.lowerInlineMemcpy(result, call);
        if (call.inline_asm != null) return .{ .no_emitter = "composed-block-inline-asm-call" };
        if (call.callee_value != null) return .{ .unsupported_value = "composed-block-indirect-call" };
        if (!isDefaultOrFastcc(call.calling_conv) or call.tail_kind != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-call-form" };
        }
        const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
        if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64 and ret_bits != 128) return .{ .no_emitter = "composed-block-call-ret-width" };
        var abi_index: usize = 0;

        if (try selector.spillLiveCallerClobbersForCall()) |diagnostic| return diagnostic;
        for (call.args.items) |arg| {
            const target = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
            if (try selector.lowerDirectCallArg(arg, target)) |diagnostic| return diagnostic;
            abi_index += callArgRegisterCount(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
            if (abi_index > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };
        }

        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
        if (result) |result_name| switch (ret_bits) {
            0 => return .{ .unsupported_value = "composed-block-void-call-result" },
            32 => try selector.bindEax(result_name),
            64 => try selector.bindRax(result_name),
            128 => {},
            else => unreachable,
        };
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

        if (try selector.spillLiveCallerClobbersForCall()) |diagnostic| return diagnostic;
        selector.emitValueIntoScratch(dst.value, .rdi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-dst" };
        selector.emitValueIntoScratch(src.value, .rsi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-src" };
        selector.emitValueIntoScratch(len.value, .rdx, 64) catch return .{ .unsupported_value = "composed-block-memcpy-len" };
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
        if (!value_arg.ty.eql(.{ .int = 32 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !undef_arg.value.eql(.{ .int = 1 })) {
            return .{ .no_emitter = "composed-block-ctlz-args" };
        }
        selector.emitValueIntoScratch(value_arg.value, .rdi, 32) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
        try selector.clobberAccumulator();
        try selector.machine.instructions.append(selector.allocator, .clz_i32_edi_eax);
        try selector.bindEax(result_name);
        return null;
    }

    fn lowerAssume(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
        _ = selector;
        if (result != null) return .{ .unsupported_value = "composed-block-assume-result" };
        if (call.inline_asm != null or call.callee_value != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
            return .{ .no_emitter = "composed-block-assume-form" };
        }
        if (call.ret_ty != .void or call.args.items.len != 1) return .{ .no_emitter = "composed-block-assume-signature" };
        return if (call.args.items[0].ty.eql(.{ .int = 1 })) null else .{ .no_emitter = "composed-block-assume-arg" };
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

        if (try selector.spillLiveCallerClobbersForCall()) |diagnostic| return diagnostic;
        selector.emitValueIntoScratch(arg.value, .rdi, 16) catch return .{ .unsupported_value = "composed-block-intbytesize-arg-value" };
        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
        try selector.bindEax(result_name);
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

        try selector.emitValueIntoScratch(value_arg.value, .rdi, 64);
        if (try selector.spillCurrentAccumulator()) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .abs_i64_rdi_rax);
        try selector.bindRax(result_name);
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

        try selector.emitPairSignMask("__zllvm_abs_i128_sign", value_arg.value, pair_a);
        _ = selector.materializePairValue(value_arg.value, pair_b) catch return .{ .unsupported_value = "composed-block-abs-value" };
        try selector.emitPairXorInPlace(pair_b, pair_a);
        try selector.emitPairSubInPlace(pair_b, pair_a);
        try selector.bindPairScratch(result_name, pair_b);
        return null;
    }

    fn lowerReturn(selector: *ComposedBlockSelector, ret: anytype) !?Diagnostic {
        if (ret.ty == .void) {
            if (ret.value != null) return .{ .unsupported_value = "composed-block-void-ret-value" };
            try selector.emitReturnEpilogue();
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
                _ = selector.resolveValue(value) orelse return .{ .unsupported_value = "composed-block-unknown-ret" };
                if (bits == 128) {
                    try selector.emitValueIntoI128Return(value);
                } else {
                    try selector.emitValueIntoAccumulator(value, bits);
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "composed-block-ret-value" },
        }
        try selector.emitReturnEpilogue();
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
        try selector.materializeStackIndex(stack_ptr);
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
        try selector.clobberArgReg(reg);
        if (disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_arg64 = .{ .reg = reg, .disp = @intCast(disp) } });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_arg64 = .{ .reg = reg, .disp = disp } });
        }
    }

    fn loadStackU64IntoRax(selector: *ComposedBlockSelector, disp: u32) !void {
        try selector.clobberAccumulator();
        if (disp <= std.math.maxInt(u8)) {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp8_rax = @intCast(disp) });
        } else {
            try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = disp });
        }
    }

    fn appendStoreStackI32(selector: *ComposedBlockSelector, stack_ptr: StackPtrLoc) !void {
        try selector.materializeStackIndex(stack_ptr);
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
        try selector.emitValueIntoScratch(.{ .named = index.name }, .rcx, 64);
        if (index.addend_name) |addend_name| {
            try selector.emitValueIntoScratch(.{ .named = addend_name }, .r8, 64);
            try selector.machine.instructions.append(selector.allocator, .add_r8_rcx);
        }
    }

    fn emitReturnEpilogue(selector: *ComposedBlockSelector) !void {
        if (selector.return_epilogue_label) |label| {
            try selector.machine.instructions.append(selector.allocator, .{ .jmp = label });
            return;
        }
        if (selector.stack_frame_bytes != 0) try selector.appendAddRsp(selector.stack_frame_bytes);
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
                if (try selector.restoreDisplacedPhiDestinations()) |diagnostic| break :blk diagnostic;
                break :blk try selector.lowerReturn(ret);
            },
            .br => |br| {
                const target_index = function.blockIndex(br.target) orelse return .{ .unsupported_control_flow = "stage2-branch-target" };
                if (!blockHasPhiIncomingFrom(function.blocks.items[target_index], function.blocks.items[block_index].name)) {
                    if (try selector.restoreDisplacedPhiDestinations()) |diagnostic| return diagnostic;
                }
                if (try selector.emitPhiEdgeMoves(function.blocks.items[target_index], function.blocks.items[block_index].name)) |diagnostic| return diagnostic;
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
                    if (try selector.restoreDisplacedPhiDestinations()) |diagnostic| return diagnostic;
                }
                if (try selector.emitBranchCondition(condbr.cond)) |diagnostic| return diagnostic;
                if (then_has_phi_edge or else_has_phi_edge) {
                    return try selector.lowerConditionalPhiEdges(function, block_index, then_index, else_index);
                }
                try selector.machine.instructions.append(selector.allocator, .{ .jne = condbr.then_target });
                if (else_index != block_index + 1) {
                    try selector.machine.instructions.append(selector.allocator, .{ .jmp = condbr.else_target });
                }
                return null;
            },
            .@"switch", .indirectbr, .@"unreachable" => .{ .no_emitter = "stage2-terminator-not-owned" },
        };
    }

    fn restoreDisplacedPhiDestinations(selector: *ComposedBlockSelector) !?Diagnostic {
        var it = selector.phi_destinations.iterator();
        while (it.next()) |entry| {
            const name = entry.key_ptr.*;
            const destination = entry.value_ptr.*;
            const actual = selector.valueLoc(name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            if (valueLocEql(actual, destination)) continue;
            selector.materializeLocIntoLoc(actual, destination) catch return .{ .no_emitter = "stage2-phi-restore-loc" };
            try selector.bindValueLoc(name, destination);
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
        const then_edge_label = try selector.ownedEdgeLabel();

        try selector.machine.instructions.append(selector.allocator, .{ .jne = then_edge_label });

        if (try selector.emitPhiEdgeMoves(function.blocks.items[else_index], predecessor)) |diagnostic| return diagnostic;
        try selector.machine.instructions.append(selector.allocator, .{ .jmp = else_target });

        try selector.machine.instructions.append(selector.allocator, .{ .label = then_edge_label });
        if (try selector.emitPhiEdgeMoves(function.blocks.items[then_index], predecessor)) |diagnostic| return diagnostic;
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
        for (target.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const phi = switch (instruction.kind) {
                .phi => |phi| phi,
                else => break,
            };
            const result_name = instruction.result orelse return .{ .unsupported_value = "stage2-phi-missing-result" };
            const incoming = phiIncomingFrom(phi, predecessor) orelse return .{ .unsupported_control_flow = "stage2-phi-incoming" };
            const dst = selector.phi_destinations.get(result_name) orelse return .{ .unsupported_value = "stage2-phi-dst" };
            if (try selector.emitValueIntoLoc(incoming.value, dst, result_name)) |diagnostic| return diagnostic;
            try selector.bindValueLoc(result_name, dst);
            switch (dst) {
                .scratch32, .scratch64 => {},
                .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
            }
        }
        return null;
    }

    fn emitValueIntoLoc(selector: *ComposedBlockSelector, value: ir.Value, dst: ValueLoc, ignore_name: []const u8) !?Diagnostic {
        _ = ignore_name;
        switch (dst) {
            .scratch32 => |reg| {
                switch (value) {
                    .int => |int| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    },
                    .named => {
                        selector.emitPhiValueIntoScratch(value, reg, 32) catch return .{ .unsupported_value = selector.phiSourceDiagnostic(value) };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .scratch64 => |reg| {
                switch (value) {
                    .int => |int| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(int) });
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                    },
                    .named => {
                        selector.emitPhiValueIntoScratch(value, reg, 64) catch return .{ .unsupported_value = selector.phiSourceDiagnostic(value) };
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .unsupported_value = "stage2-phi-src" },
                }
            },
            .arg32, .arg64, .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "stage2-phi-dst-loc" },
        }
        return null;
    }

    fn emitBranchCondition(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
        const loc = selector.resolveValue(value) orelse return .{ .unsupported_value = "stage2-unknown-cond" };
        switch (loc) {
            .eax => try selector.machine.instructions.append(selector.allocator, .test_eax_eax),
            .arg32, .scratch32 => |reg| try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = reg }),
            .spill64 => |frame_index| {
                try selector.clobberArgReg(.rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                try selector.machine.instructions.append(selector.allocator, .{ .test_arg8 = .rcx });
            },
            .arg64, .scratch64, .arg128, .scratch128, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "stage2-cond-loc" },
        }
        return null;
    }

    fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
        if (arg.ty == .ptr) {
            const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
            const disp = switch (loc) {
                .stack64 => |disp| disp,
                .stack128 => |disp| disp,
                .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => return .{ .no_emitter = "composed-block-call-ptr-arg" },
            };
            try selector.clobberArgReg(target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
            if (disp != 0) {
                const addend: i32 = std.math.cast(i32, disp) orelse return .{ .no_spill_envelope = "composed-block-call-stack-disp" };
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } });
            }
            return null;
        }

        const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-call-arg-width" };
        const loc = selector.resolveValue(arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-arg" };
        if (bits == 128) {
            const target_hi = ArgReg.fromIndex(argRegIndex(target) + 1) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
            switch (loc) {
                .arg128, .scratch128 => |pair| try selector.emitPairIntoAbiRegs(pair, .{ .lo = target, .hi = target_hi }),
                .stack128_value => |disp| {
                    try selector.loadStackU64IntoArg(target, disp);
                    try selector.loadStackU64IntoArg(target_hi, disp + 8);
                },
                .spill128 => |spill| {
                    try selector.clobberArgReg(target);
                    try selector.clobberArgReg(target_hi);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = spill.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target_hi, .frame_index = spill.hi } });
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return .{ .no_emitter = "composed-block-call-arg-loc" },
            }
            return null;
        }
        switch (loc) {
            .arg32, .scratch32 => |reg| {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    try selector.clobberArgReg(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = target, .src = reg } });
                }
            },
            .arg64, .scratch64 => |reg| {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                if (reg != target) {
                    try selector.clobberArgReg(target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
                }
            },
            .eax => {
                if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
                try selector.clobberArgReg(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = target });
            },
            .rax => {
                if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
                try selector.clobberArgReg(target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
            },
            .spill64 => |frame_index| {
                try selector.clobberArgReg(target);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
                } else if (bits == 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = target, .frame_index = frame_index } });
                } else return .{ .no_emitter = "composed-block-call-arg-width" };
            },
            .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return .{ .no_emitter = "composed-block-call-arg-loc" },
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
        const target = selector.plannedResultLoc(name, actual) orelse actual;
        if (!valueLocEql(actual, target)) try selector.materializeLocIntoLoc(actual, target);
        try selector.bindValueLoc(name, target);
    }

    fn plannedResultLoc(selector: ComposedBlockSelector, name: []const u8, actual: ValueLoc) ?ValueLoc {
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
            .spill => |index| if (selector.stack_frame_bytes >= (selector.spillReservedBytes(true) orelse return null)) switch (actual) {
                .arg64, .scratch64, .rax, .spill64 => if (spillFrameIndexMaybe(index)) |frame_index| .{ .spill64 = frame_index } else null,
                .arg128, .scratch128, .spill128 => if (pairSpillFrameIndexMaybe(index)) |spill| .{ .spill128 = spill } else null,
                else => null,
            } else null,
        };
        const target = planned orelse return null;
        if (std.meta.activeTag(target) == .spill64 or std.meta.activeTag(target) == .spill128) return target;
        if (valueLocEql(actual, target)) return target;
        return if (selector.enable_expired_plan_register_reuse and selector.expired_binding_this_position and selector.targetLocHasOnlyExpiredConflicts(target)) target else null;
    }

    fn targetLocHasOnlyExpiredConflicts(selector: ComposedBlockSelector, target: ValueLoc) bool {
        return switch (target) {
            .scratch32, .scratch64 => |reg| selector.regHasOnlyExpiredConflicts(reg),
            .scratch128 => |pair| blk: {
                var saw_conflict = false;
                if (selector.regConflictStatus(pair.lo)) |expired| {
                    if (!expired) break :blk false;
                    saw_conflict = true;
                }
                if (selector.regConflictStatus(pair.hi)) |expired| {
                    if (!expired) break :blk false;
                    saw_conflict = true;
                }
                break :blk saw_conflict;
            },
            .arg32, .arg64, .arg128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => false,
        };
    }

    fn regHasOnlyExpiredConflicts(selector: ComposedBlockSelector, reg: ArgReg) bool {
        var saw_conflict = false;
        if (selector.regConflictStatus(reg)) |expired| {
            if (!expired) return false;
            saw_conflict = true;
        }
        return saw_conflict;
    }

    fn regConflictStatus(selector: ComposedBlockSelector, reg: ArgReg) ?bool {
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
                        try selector.clobberArgReg(dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                    }
                },
                .arg128, .scratch128 => |pair| {
                    if (pair.lo != dst) {
                        try selector.clobberArgReg(dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = pair.lo } });
                    }
                },
                .eax, .rax => {
                    try selector.clobberArgReg(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = dst });
                },
                .spill64 => |frame_index| {
                    try selector.clobberArgReg(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = dst, .frame_index = frame_index } });
                },
                .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
            },
            .scratch64 => |dst| switch (actual) {
                .arg64, .scratch64 => |src| {
                    if (src != dst) {
                        try selector.clobberArgReg(dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = src } });
                    }
                },
                .arg128, .scratch128 => |pair| {
                    if (pair.lo != dst) {
                        try selector.clobberArgReg(dst);
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
                    }
                },
                .rax => {
                    try selector.clobberArgReg(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
                },
                .spill64 => |frame_index| {
                    try selector.clobberArgReg(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = frame_index } });
                },
                .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
            },
            .scratch128 => |dst| switch (actual) {
                .arg128, .scratch128 => |src| try selector.emitPairIntoScratch(src, dst),
                .spill128 => |spill| {
                    try selector.clobberAccumulator();
                    try selector.clobberArgReg(dst.lo);
                    try selector.clobberArgReg(dst.hi);
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
                },
                .stack128_value => |disp| {
                    try selector.loadStackU64IntoArg(dst.lo, disp);
                    try selector.loadStackU64IntoArg(dst.hi, disp + 8);
                },
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
            },
            .spill64 => |frame_index| {
                if (selector.stack_frame_bytes < (selector.spillReservedBytes(true) orelse return error.UnsupportedCodegenValue)) return error.UnsupportedCodegenValue;
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
                    .spill64 => {},
                    .arg128, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            },
            .spill128 => |spill| {
                if (selector.stack_frame_bytes < (selector.spillReservedBytes(true) orelse return error.UnsupportedCodegenValue)) return error.UnsupportedCodegenValue;
                switch (actual) {
                    .arg128, .scratch128 => |pair| {
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
                        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
                    },
                    .spill128 => {},
                    .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
                }
            },
            .arg32, .arg64, .arg128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr => return error.UnsupportedCodegenValue,
        }
    }

    pub fn valueLoc(selector: ComposedBlockSelector, name: []const u8) ?ValueLoc {
        const binding = selector.values.get(name) orelse return null;
        return binding.loc;
    }

    pub fn virtualRegMetadata(loc: ValueLoc) VirtualRegMetadata {
        return switch (loc) {
            .arg32, .scratch32, .eax => .{ .class = .gpr32, .bits = 32 },
            .arg64, .scratch64, .rax, .spill64 => .{ .class = .gpr64, .bits = 64 },
            .arg128, .scratch128, .spill128, .stack128_value => .{ .class = .gpr128, .bits = 128 },
            .stack64, .stack128, .stack_i32_array => .{ .class = .stack_object, .bits = 0 },
            .stack_i32_ptr => .{ .class = .stack_pointer, .bits = 64 },
        };
    }

    fn bindEax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.bindResultLoc(name, .eax);
    }

    fn bindRax(selector: *ComposedBlockSelector, name: []const u8) !void {
        try selector.bindResultLoc(name, .rax);
    }

    fn bindAccumulator(selector: *ComposedBlockSelector, name: []const u8, bits: u16) !void {
        if (bits == 64) try selector.bindRax(name) else try selector.bindEax(name);
    }

    fn bindScratch(selector: *ComposedBlockSelector, name: []const u8, reg: ArgReg, bits: u16) !void {
        const actual: ValueLoc = if (bits == 64) .{ .scratch64 = reg } else .{ .scratch32 = reg };
        try selector.bindResultLoc(name, actual);
    }

    fn bindPairScratch(selector: *ComposedBlockSelector, name: []const u8, pair: RegPair) !void {
        try selector.bindResultLoc(name, .{ .scratch128 = pair });
    }

    fn emitPairIntoAbiRegs(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
        if (src.eql(dst)) return;
        try selector.clobberAccumulator();
        try selector.clobberArgReg(dst.lo);
        try selector.clobberArgReg(dst.hi);
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
        const name = selector.liveAccumulatorName() orelse return null;
        return try selector.spillValue(name);
    }

    fn preserveRaxForDestructiveAccumulatorUse(selector: *ComposedBlockSelector, value: ir.Value) !?Diagnostic {
        _ = value;
        return try selector.spillCurrentAccumulator();
    }

    pub fn spillValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
        if (selector.stack_frame_bytes < 24) return .{ .no_spill_envelope = "composed-block-spill-frame" };
        const loc = selector.resolveValue(.{ .named = name }) orelse return .{ .unsupported_value = "composed-block-spill-unknown" };
        switch (loc) {
            .spill64 => return null,
            .spill128 => return null,
            else => {},
        }
        const frame_index = selector.allocateSpillSlot(name) orelse return .{ .no_spill_envelope = "composed-block-spill-slots" };
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
            .stack64 => return .{ .no_emitter = "composed-block-spill-loc-stack64" },
            .stack128 => return .{ .no_emitter = "composed-block-spill-loc-stack128" },
            .stack128_value => return .{ .no_emitter = "composed-block-spill-loc-stack128-value" },
            .stack_i32_array => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-array" },
            .stack_i32_ptr => return .{ .no_emitter = "composed-block-spill-loc-stack-i32-ptr" },
            .spill64 => return .{ .no_emitter = "composed-block-spill-loc-spill64" },
            .spill128 => return .{ .no_emitter = "composed-block-spill-loc-spill128" },
        }
        try selector.bindValueLoc(name, .{ .spill64 = frame_index });
        return null;
    }

    fn spillPairValue(selector: *ComposedBlockSelector, name: []const u8) !?Diagnostic {
        if (selector.stack_frame_bytes < stack128FrameBytes()) return .{ .no_spill_envelope = "composed-block-pair-spill-frame" };
        const loc = selector.resolveValue(.{ .named = name }) orelse return .{ .unsupported_value = "composed-block-pair-spill-unknown" };
        switch (loc) {
            .spill128 => return null,
            else => {},
        }
        const pair = switch (loc) {
            .arg128, .scratch128 => |pair| pair,
            .arg32, .scratch32, .eax => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr32" },
            .arg64, .scratch64, .rax, .spill64 => return .{ .no_emitter = "composed-block-pair-spill-loc-gpr64" },
            .stack64 => return .{ .no_emitter = "composed-block-pair-spill-loc-stack64" },
            .stack128 => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128" },
            .stack128_value => return .{ .no_emitter = "composed-block-pair-spill-loc-stack128-value" },
            .stack_i32_array => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-array" },
            .stack_i32_ptr => return .{ .no_emitter = "composed-block-pair-spill-loc-stack-i32-ptr" },
            .spill128 => return .{ .no_emitter = "composed-block-pair-spill-loc-spill128" },
        };
        const spill = selector.allocatePairSpillSlots(name) orelse return .{ .no_spill_envelope = "composed-block-pair-spill-slots" };
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.lo, .reg = pair.lo } });
        try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = spill.hi, .reg = pair.hi } });
        try selector.bindValueLoc(name, .{ .spill128 = spill });
        return null;
    }

    fn allocateSpillSlot(selector: *ComposedBlockSelector, name: []const u8) ?FrameIndex {
        if (selector.spill_slots.get(name)) |assignment| return spillFrameIndexMaybe(assignment.base);
        const base = selector.next_spill_slot;
        const frame_index = spillFrameIndexMaybe(base) orelse return null;
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
                try selector.clobberAccumulator();
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(int) });
            },
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg32, .scratch32, .arg64, .scratch64 => |reg| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = reg });
                    },
                    .arg128, .scratch128 => |pair| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_eax = pair.lo });
                    },
                    .spill64 => |frame_index| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_eax = frame_index });
                    },
                    .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
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
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                switch (loc) {
                    .arg64, .scratch64 => |reg| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = reg });
                    },
                    .spill64 => |frame_index| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                    },
                    .arg128, .scratch128 => |pair| {
                        try selector.clobberAccumulator();
                        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = pair.lo });
                    },
                    .rax => {},
                    .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                }
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoAccumulator(selector: *ComposedBlockSelector, value: ir.Value, bits: u16) !void {
        if (bits == 64) try selector.emitValueIntoRax(value) else try selector.emitValueIntoEax(value);
    }

    fn preserveCurrentEaxIntoScratch(selector: *ComposedBlockSelector) !?Diagnostic {
        const name = selector.liveEaxName() orelse return null;
        if (!selector.scratchRegIsProvenFree(.rdx)) return null;
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdx });
        try selector.bindValueLoc(name, .{ .scratch32 = .rdx });
        return null;
    }

    fn scratchRegIsProvenFree(selector: ComposedBlockSelector, reg: ArgReg) bool {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            switch (entry.value_ptr.loc) {
                .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return false,
                .arg128, .scratch128 => |pair| if (pair.contains(reg)) return false,
                .stack_i32_ptr => |stack_ptr| if (stack_ptr.index) |index| if (index.reg == reg) return false,
                .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => {},
            }
        }
        return true;
    }

    pub fn emitValueIntoI128Return(selector: *ComposedBlockSelector, value: ir.Value) !void {
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        switch (loc) {
            .stack128_value => |disp| {
                try selector.loadStackU64IntoArg(.rdx, disp + 8);
                try selector.loadStackU64IntoRax(disp);
                try selector.clobberArgReg(.rdx);
            },
            .arg128, .scratch128 => |pair| {
                try selector.emitPairIntoAbiRegs(pair, .{ .lo = .rdi, .hi = .rdx });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdi });
            },
            .spill128 => |spill| {
                try selector.clobberArgReg(.rdx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = spill.hi } });
                try selector.clobberAccumulator();
                try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = spill.lo });
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
        try selector.emitValueIntoScratchExcept(value, reg, bits, null);
    }

    fn emitPhiValueIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, reg: ArgReg, bits: u16) !void {
        switch (value) {
            .named => {
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                if (bits == 64) {
                    switch (loc) {
                        .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = src } }),
                        .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg }),
                        .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                        .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = reg, .src = pair.lo } }),
                        .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                    }
                } else {
                    switch (loc) {
                        .arg32, .scratch32, .arg64, .scratch64 => |src| if (src != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = src } }),
                        .arg128, .scratch128 => |pair| if (pair.lo != reg) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = reg, .src = pair.lo } }),
                        .eax, .rax => try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg }),
                        .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } }),
                        .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                    }
                }
            },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
    }

    fn phiSourceDiagnostic(selector: ComposedBlockSelector, value: ir.Value) []const u8 {
        const loc = selector.resolveValue(value) orelse return "stage2-phi-src-unknown";
        return switch (loc) {
            .arg32 => "stage2-phi-src-arg32",
            .arg64 => "stage2-phi-src-arg64",
            .arg128 => "stage2-phi-src-arg128",
            .eax => "stage2-phi-src-eax",
            .rax => "stage2-phi-src-rax",
            .scratch32 => "stage2-phi-src-scratch32",
            .scratch64 => "stage2-phi-src-scratch64",
            .scratch128 => "stage2-phi-src-scratch128",
            .stack64 => "stage2-phi-src-stack64",
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
                const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
                if (bits == 64) {
                    switch (loc) {
                        .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                try selector.clobberArgRegExcept(reg, ignore_name);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .rax => {
                            try selector.clobberArgRegExcept(reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = reg });
                        },
                        .spill64 => |frame_index| {
                            try selector.clobberArgRegExcept(reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = frame_index } });
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                try selector.clobberArgRegExcept(reg, ignore_name);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .arg32, .scratch32, .eax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
                    }
                } else {
                    switch (loc) {
                        .arg32, .scratch32, .arg64, .scratch64 => |src| {
                            if (src != reg) {
                                try selector.clobberArgRegExcept(reg, ignore_name);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = src,
                                } });
                            }
                        },
                        .arg128, .scratch128 => |pair| {
                            if (pair.lo != reg) {
                                try selector.clobberArgRegExcept(reg, ignore_name);
                                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{
                                    .dst = reg,
                                    .src = pair.lo,
                                } });
                            }
                        },
                        .eax, .rax => {
                            try selector.clobberArgRegExcept(reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                        },
                        .spill64 => |frame_index| {
                            try selector.clobberArgRegExcept(reg, ignore_name);
                            try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = frame_index } });
                        },
                        .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
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
                try selector.clobberArgReg(.rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else if (bits <= 32) blk: {
                try selector.clobberArgReg(.rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return error.UnsupportedCodegenValue,
            .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128 => return error.UnsupportedCodegenValue,
        };
        try selector.emitBinaryArgAccumulator(op, reg, bits);
    }

    pub fn emitPairLshrImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
        if (amount > 127) return error.UnsupportedCodegenValue;
        const existing = selector.resolvePairValue(value);
        const dst = if (existing) |src|
            selector.choosePairScratch(src) orelse return error.UnsupportedCodegenValue
        else
            selector.choosePairScratch(null) orelse return error.UnsupportedCodegenValue;
        const src = if (existing) |src| src else try selector.materializePairValue(value, dst);
        switch (amount) {
            0 => {
                try selector.emitPairIntoScratch(src, dst);
            },
            64 => {
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
                try selector.emitZeroArg64(dst.hi);
            },
            1...63 => {
                try selector.emitPairIntoScratch(src, dst);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
                try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = @intCast(64 - amount) });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.lo, .amount = @intCast(amount) } });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = dst.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
                try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{ .reg = dst.hi, .amount = @intCast(amount) } });
            },
            65...127 => return error.UnsupportedCodegenValue,
        }
        try selector.bindPairScratch(result_name, dst);
    }

    pub fn emitPairShlImmediate(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u7) !void {
        if (amount != 64) return error.UnsupportedCodegenValue;
        const existing = selector.resolvePairValue(value);
        const dst = if (existing) |src| src else try selector.materializePairValue(value, pair_a);
        try selector.clobberArgReg(dst.hi);
        if (dst.lo != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
        try selector.emitZeroArg64(dst.lo);
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairIntoScratch(selector: *ComposedBlockSelector, src: RegPair, dst: RegPair) !void {
        if (src.eql(dst)) return;
        try selector.clobberAccumulator();
        try selector.clobberArgReg(dst.lo);
        try selector.clobberArgReg(dst.hi);
        if (src.lo != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.lo } });
        if (src.hi != dst.hi) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = src.hi } });
    }

    fn materializePairValue(selector: *ComposedBlockSelector, value: ir.Value, dst: RegPair) !RegPair {
        switch (value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        switch (loc) {
            .arg128, .scratch128 => |src| {
                try selector.emitPairIntoScratch(src, dst);
                return dst;
            },
            .stack128_value => |disp| {
                try selector.loadStackU64IntoArg(dst.lo, disp);
                try selector.loadStackU64IntoArg(dst.hi, disp + 8);
                return dst;
            },
            .spill128 => |spill| {
                try selector.clobberAccumulator();
                try selector.clobberArgReg(dst.lo);
                try selector.clobberArgReg(dst.hi);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.lo, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst.hi, .frame_index = spill.hi } });
                return dst;
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitPairLowLaneIntoScratch(selector: *ComposedBlockSelector, value: ir.Value, dst: ArgReg) !void {
        switch (value) {
            .named => {},
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        }
        const loc = selector.resolveValue(value) orelse return error.UnsupportedCodegenValue;
        switch (loc) {
            .arg128, .scratch128 => |pair| {
                if (pair.lo != dst) {
                    try selector.clobberArgReg(dst);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst, .src = pair.lo } });
                }
            },
            .stack128_value => |disp| {
                try selector.clobberArgReg(dst);
                try selector.loadStackU64IntoArg(dst, disp);
            },
            .spill128 => |spill| {
                try selector.clobberArgReg(dst);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = dst, .frame_index = spill.lo } });
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack_i32_array, .stack_i32_ptr, .spill64 => return error.UnsupportedCodegenValue,
        }
    }

    fn emitPairSignMask(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, dst: RegPair) !void {
        const src = try selector.materializePairValue(value, dst);
        if (src.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.lo, .src = src.hi } });
        try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = dst.lo, .amount = 63 } });
        if (dst.hi != dst.lo) try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = dst.hi, .src = dst.lo } });
        try selector.bindPairScratch(result_name, dst);
    }

    fn emitPairXorInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        try selector.emitPairLaneBinaryInto(dst.lo, .xor, dst.lo, rhs.lo);
        try selector.emitPairLaneBinaryInto(dst.hi, .xor, dst.hi, rhs.hi);
    }

    fn emitPairOrInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        try selector.emitPairLaneBinaryInto(dst.lo, .@"or", dst.lo, rhs.lo);
        try selector.emitPairLaneBinaryInto(dst.hi, .@"or", dst.hi, rhs.hi);
    }

    fn emitPairSubInPlace(selector: *ComposedBlockSelector, dst: RegPair, rhs: RegPair) !void {
        try selector.clobberAccumulator();
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = rhs.lo } });
        try selector.clobberArgReg(dst.lo);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.lo });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = dst.hi });
        try selector.machine.instructions.append(selector.allocator, .{ .sbb_arg64_rax = rhs.hi });
        try selector.clobberArgReg(dst.hi);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst.hi });
    }

    fn emitPairLaneBinaryInto(selector: *ComposedBlockSelector, dst: ArgReg, op: MachineBinaryOp, lhs: ArgReg, rhs: ArgReg) !void {
        try selector.clobberAccumulator();
        try selector.clobberArgReg(dst);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = lhs });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{
            .op = op,
            .reg = rhs,
        } });
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = dst });
    }

    fn emitZeroArg64(selector: *ComposedBlockSelector, reg: ArgReg) !void {
        try selector.clobberArgReg(reg);
        switch (reg) {
            .rdx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdx = 0 }),
            .rcx => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = 0 }),
            .r8 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = 0 }),
            .r9 => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 }),
            .rdi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rdi = 0 }),
            .rsi => try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rsi = 0 }),
        }
    }

    fn choosePairScratch(selector: ComposedBlockSelector, src: ?RegPair) ?RegPair {
        for (selector_allocatable_pairs) |pair| {
            if (src) |source| if (source.eql(pair)) continue;
            if (selector.pairScratchIsAvailableForUse(pair)) return pair;
        }
        return null;
    }

    fn choosePairScratchForClobber(selector: ComposedBlockSelector, src: ?RegPair) ?RegPair {
        if (selector.stack_frame_bytes < (selector.spillReservedBytes(true) orelse return null)) return selector.choosePairScratch(src);
        for (selector_allocatable_pairs) |pair| {
            if (src) |source| if (source.eql(pair)) continue;
            if (selector.livePairNameContainingReg(pair.lo) != null) continue;
            if (selector.livePairNameContainingReg(pair.hi) != null) continue;
            return pair;
        }
        return null;
    }

    fn pairScratchIsAvailableForUse(selector: ComposedBlockSelector, pair: RegPair) bool {
        return selector.scratch64RegIsAvailableForUse(pair.lo) and selector.scratch64RegIsAvailableForUse(pair.hi);
    }

    fn clobberArgReg(selector: *ComposedBlockSelector, reg: ArgReg) !void {
        try selector.clobberArgRegExcept(reg, null);
    }

    fn clobberArgRegExcept(selector: *ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) !void {
        if (selector.pairNameContainingRegExcept(reg, ignore_name)) |name| {
            if (selector.valueIsLiveAfterCurrent(name) or selector.stack_frame_bytes >= (selector.spillReservedBytes(true) orelse return error.UnsupportedCodegenValue)) {
                try selector.spillPairValueOrError(name);
            } else if (selector.phi_results.contains(name)) {
                // Phi destinations are pre-bound before edge materialization.
            } else {
                _ = selector.values.remove(name);
            }
        }
        if (selector.scalarNameInRegExcept(reg, ignore_name)) |name| {
            if (selector.valueIsLiveAfterCurrent(name)) {
                try selector.spillValueOrError(name);
            } else if (selector.phi_results.contains(name)) {
                // Phi destinations are pre-bound before edge materialization.
            } else {
                _ = selector.values.remove(name);
            }
        }
    }

    fn clobberAccumulator(selector: *ComposedBlockSelector) !void {
        selector.dropExpiredAccumulatorBindings();
        while (selector.liveAccumulatorName()) |name| {
            try selector.spillValueOrError(name);
        }
    }

    fn spillAccumulatorAliasesExcept(selector: *ComposedBlockSelector, value: ir.Value) !void {
        const ignored = switch (value) {
            .named => |name| name,
            else => return,
        };
        while (selector.liveAccumulatorNameExcept(ignored)) |name| {
            try selector.spillValueOrError(name);
        }
    }

    fn liveAccumulatorNameExcept(selector: ComposedBlockSelector, ignored: []const u8) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
            if (!selector.valueIsLiveAtOrAfterCurrent(entry.key_ptr.*)) continue;
            switch (entry.value_ptr.loc) {
                .eax, .rax => return entry.key_ptr.*,
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
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
                    .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => continue,
                }
                if (selector.valueIsLiveAfterCurrent(entry.key_ptr.*)) continue;
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
        if (try selector.spillCurrentAccumulator()) |diagnostic| return diagnostic;
        for (selector_allocatable_regs) |reg| {
            if (selector.livePairNameContainingReg(reg)) |name| {
                if (try selector.spillPairValue(name)) |diagnostic| return diagnostic;
            }
            if (selector.liveScalarNameInReg(reg)) |name| {
                if (try selector.spillValue(name)) |diagnostic| return diagnostic;
            }
        }
        return null;
    }

    fn liveAccumulatorName(selector: ComposedBlockSelector) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (!selector.valueIsLiveAtOrAfterCurrent(entry.key_ptr.*)) continue;
            switch (entry.value_ptr.loc) {
                .eax, .rax => return entry.key_ptr.*,
                .arg32, .arg64, .arg128, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn valueIsLiveAtOrAfterCurrent(selector: ComposedBlockSelector, name: []const u8) bool {
        const plan = selector.allocation_plan orelse return false;
        const end = plan.intervalEnd(name) orelse return true;
        return end >= selector.current_position;
    }

    fn liveEaxName(selector: ComposedBlockSelector) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (!selector.valueIsLiveAfterCurrent(entry.key_ptr.*)) continue;
            switch (entry.value_ptr.loc) {
                .eax => return entry.key_ptr.*,
                .arg32, .arg64, .arg128, .rax, .scratch32, .scratch64, .scratch128, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn liveScalarNameInReg(selector: ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
        return selector.liveScalarNameInRegExcept(reg, null);
    }

    fn scalarNameInRegExcept(selector: ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (ignore_name) |ignored| {
                if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
            }
            switch (entry.value_ptr.loc) {
                .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn liveScalarNameInRegExcept(selector: ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (ignore_name) |ignored| {
                if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
            }
            if (!selector.valueIsLiveAfterCurrent(entry.key_ptr.*)) continue;
            switch (entry.value_ptr.loc) {
                .arg32, .arg64, .scratch32, .scratch64 => |value_reg| if (value_reg == reg) return entry.key_ptr.*,
                .arg128, .scratch128, .eax, .rax, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn livePairNameContainingReg(selector: ComposedBlockSelector, reg: ArgReg) ?[]const u8 {
        return selector.livePairNameContainingRegExcept(reg, null);
    }

    fn pairNameContainingRegExcept(selector: ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (ignore_name) |ignored| {
                if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
            }
            switch (entry.value_ptr.loc) {
                .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn livePairNameContainingRegExcept(selector: ComposedBlockSelector, reg: ArgReg, ignore_name: ?[]const u8) ?[]const u8 {
        var it = selector.values.iterator();
        while (it.next()) |entry| {
            if (ignore_name) |ignored| {
                if (std.mem.eql(u8, entry.key_ptr.*, ignored)) continue;
            }
            if (!selector.valueIsLiveAfterCurrent(entry.key_ptr.*)) continue;
            switch (entry.value_ptr.loc) {
                .arg128, .scratch128 => |pair| if (pair.contains(reg)) return entry.key_ptr.*,
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => {},
            }
        }
        return null;
    }

    fn valueIsLiveAfterCurrent(selector: ComposedBlockSelector, name: []const u8) bool {
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
        if (try selector.spillValue(name)) |_| return error.UnsupportedCodegenValue;
    }

    fn spillPairValueOrError(selector: *ComposedBlockSelector, name: []const u8) !void {
        if (try selector.spillPairValue(name)) |_| return error.UnsupportedCodegenValue;
    }

    fn resolvePairValue(selector: ComposedBlockSelector, value: ir.Value) ?RegPair {
        const loc = selector.resolveValue(value) orelse return null;
        return switch (loc) {
            .arg128, .scratch128 => |pair| pair,
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .stack64, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128 => null,
        };
    }

    fn resolveValue(selector: ComposedBlockSelector, value: ir.Value) ?ValueLoc {
        return switch (value) {
            .named => |name| {
                const loc = selector.valueLoc(name) orelse return null;
                return switch (loc) {
                    .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128 => loc,
                    .stack64, .stack128, .stack128_value, .stack_i32_array, .spill64, .spill128 => loc,
                    .stack_i32_ptr => loc,
                };
            },
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
        };
    }
};

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

    if (try composed.bindParams(function)) |diagnostic| return unsupported(diagnostic);
    if (try composed.prepareStackFrame(function)) |diagnostic| return unsupported(diagnostic);

    const block = function.blocks.items[0];
    for (block.instructions.items) |instruction| {
        if (try composed.lowerInstruction(instruction)) |diagnostic| return unsupported(diagnostic);
    }

    const terminator = block.terminator orelse return unsupported(.{ .unsupported_control_flow = "composed-block-missing-terminator" });
    try composed.expireExpiredBindings();
    switch (terminator) {
        .ret => |ret| {
            if (try composed.lowerReturn(ret)) |diagnostic| return unsupported(diagnostic);
        },
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return unsupported(.{ .no_emitter = "composed-block-terminator-not-owned" }),
    }
    return .selected;
}

fn unsupported(diagnostic: Diagnostic) SelectionResult {
    return .{ .unsupported = diagnostic };
}
