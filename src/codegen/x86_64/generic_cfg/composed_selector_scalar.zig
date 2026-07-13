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

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (bits == 1) {
        if (binary.op != .@"and" or valueIsInt(binary.lhs) or valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
        selector_state.emitValueIntoEax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .@"and", .reg = .rcx } });
        try selector_state.bindEax(selector, result_name);
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
    if ((binary.op == .udiv or binary.op == .urem) and (bits == 32 or bits == 64)) {
        return try lowerUnsignedDivRem(selector, result_name, binary, bits);
    }
    if (binary.op == .mul and bits <= 32) {
        while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
        }
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.emitValueIntoEax(selector, binary.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .imul_eax_arg32 = .rcx });
        try selector_state.bindEax(selector, result_name);
        return null;
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and (bits == 16 or bits == 32)) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.emitValueIntoEax(selector, binary.lhs);
        try selector.machine.instructions.append(selector.allocator, switch (binary.op) {
            .shl => .shl_eax_cl,
            .lshr => .shr_eax_cl,
            .ashr => .sar_eax_cl,
            else => unreachable,
        });
        try selector_state.bindEax(selector, result_name);
        return null;
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and bits == 64) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoRax(selector, binary.lhs);
        try selector.machine.instructions.append(selector.allocator, switch (binary.op) {
            .shl => .shl_rax_cl,
            .lshr => .shr_rax_cl,
            .ashr => .sar_rax_cl,
            else => unreachable,
        });
        try selector_state.bindRax(selector, result_name);
        return null;
    }

    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
    while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    if (namedValue(binary.lhs)) |lhs_name| {
        if (selector_state.valueIsLiveAfterCurrent(selector, lhs_name)) {
            if (try selector_state.preserveLiveAccumulatorValue(selector, lhs_name)) |diagnostic| return diagnostic;
        }
    }
    const lhs = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

    if (locIsAccumulator(rhs) and locIsAccumulator(lhs)) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
        try selector_state.emitBinaryArgAccumulator(selector, op, .rcx, bits);
    } else if (locIsAccumulator(rhs)) {
        if (isCommutative(op)) {
            try selector_state.spillAccumulatorAliasesExcept(selector, binary.rhs);
            try selector_state.emitBinaryLocIntoAccumulator(selector, op, lhs, bits);
        } else {
            const rhs_scratch: ArgReg = switch (lhs) {
                .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128, .spill_fp => .rcx,
                .eax, .rax => unreachable,
            };
            try selector_state.emitValueIntoScratch(selector, binary.rhs, rhs_scratch, bits);
            if (locIsAccumulator(lhs)) try selector_state.spillAccumulatorAliasesExcept(selector, binary.lhs);
            try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
            try selector_state.emitBinaryArgAccumulator(selector, op, rhs_scratch, bits);
        }
    } else {
        if (locIsAccumulator(lhs)) try selector_state.spillAccumulatorAliasesExcept(selector, binary.lhs);
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
        const rhs_reg: ArgReg = switch (rhs) {
            .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-i32-for-i64" },
            .arg64, .scratch64 => |reg| if (bits == 64) reg else return .{ .no_emitter = "composed-block-rhs-i64-for-i32" },
            .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
            .spill64 => |frame_index| if (bits == 64) blk: {
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else if (bits <= 32) blk: {
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return .{ .no_emitter = "composed-block-rhs-stack" },
            .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-rhs-stack" },
            .eax, .rax => unreachable,
        };
        try selector_state.emitBinaryArgAccumulator(selector, op, rhs_reg, bits);
    }

    try selector_state.bindAccumulator(selector, result_name, bits);
    return null;
}

pub fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const rhs = switch (binary.rhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (bits <= 32) switch (binary.op) {
        .shl, .ashr, .@"and", .@"or", .add, .sub, .xor => if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic,
        else => {},
    };
    switch (binary.op) {
        .lshr => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                try selector_state.emitPairLshrImmediate(selector, result_name, binary.lhs, amount);
                return null;
            }
            switch (bits) {
                16, 32 => {
                    try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                    const amount = try shiftAmount5(rhs);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg_imm5 = .{
                        .reg = .rcx,
                        .amount = amount,
                    } });
                    try selector_state.bindScratch(selector, result_name, .rcx, bits);
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
                    try selector_state.emitValueIntoScratch(selector, binary.lhs, dst, bits);
                    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_arg64_imm6 = .{
                        .reg = dst,
                        .amount = amount,
                    } });
                    try selector_state.bindScratch(selector, result_name, dst, bits);
                },
                else => return .{ .no_emitter = "composed-block-binary-width" },
            }
        },
        .shl => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                try selector_state.emitPairShlImmediate(selector, result_name, binary.lhs, amount);
                return null;
            }
            if (bits == 64) {
                const amount = try shiftAmount6(rhs);
                if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                try selector_state.emitValueIntoRax(selector, binary.lhs);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_rax_imm6 = amount });
                try selector_state.bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-shl-imm-width" };
            const amount = try shiftAmount5(rhs);
            const lhs_loc = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
            if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
            try selector_state.emitValueIntoEax(selector, binary.lhs);
            if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shl_eax_imm5 = amount });
            switch (lhs_loc) {
                .scratch32 => |reg| {
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    try selector_state.bindScratch(selector, result_name, reg, bits);
                },
                .arg32, .arg64, .scratch64, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128, .spill_fp => try selector_state.bindEax(selector, result_name),
            }
        },
        .ashr => {
            if (bits == 128) {
                const amount = try shiftAmount7(rhs);
                if (amount != 127) return .{ .no_emitter = "composed-block-ashr-i128-amount" };
                try selector_state.emitPairSignMask(selector, result_name, binary.lhs, pair_a);
                return null;
            }
            if (bits <= 32) {
                const amount = try shiftAmount5(rhs);
                try selector_state.emitValueIntoEax(selector, binary.lhs);
                if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_eax_imm5 = amount });
                try selector_state.bindEax(selector, result_name);
                return null;
            }
            if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
            const amount = try shiftAmount6(rhs);
            try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
            if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{
                .reg = .rcx,
                .amount = amount,
            } });
            try selector_state.bindScratch(selector, result_name, .rcx, bits);
            if (try selector_state.spillValue(selector, result_name)) |diagnostic| return diagnostic;
        },
        .@"and" => {
            if (bits == 64 and rhs == std.math.maxInt(u32)) {
                if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                selector_state.emitValueIntoRax(selector, binary.lhs) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                const imm = i32BitPattern(rhs) catch return .{ .no_emitter = "composed-block-and64-imm" };
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = imm });
                try selector_state.bindRax(selector, result_name);
                return null;
            }
            if (bits == 64) {
                if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                selector_state.emitValueIntoRax(selector, binary.lhs) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
                try selector_state.bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try selector_state.emitValueIntoEax(selector, binary.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = try i32Value(rhs) });
            try selector_state.bindEax(selector, result_name);
        },
        .@"or" => {
            if (bits == 64) {
                if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                selector_state.emitValueIntoRax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-or64-lhs" };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } });
                try selector_state.bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try selector_state.emitValueIntoEax(selector, binary.lhs);
            try selector.machine.instructions.append(selector.allocator, .{ .or_eax_imm32 = try i32Value(rhs) });
            try selector_state.bindEax(selector, result_name);
        },
        .add => {
            if (bits == 64) {
                const imm = i32Value(rhs) catch {
                    if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                    selector_state.emitValueIntoRax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-add64-lhs" };
                    try selector_state.clobberArgReg(selector, .rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .add, .reg = .rcx } });
                    try selector_state.bindRax(selector, result_name);
                    return null;
                };
                try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = imm } });
                try selector_state.bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector_state.emitValueIntoEax(selector, binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = try i32Value(rhs) });
                try selector_state.bindEax(selector, result_name);
            }
        },
        .sub => {
            const imm = try i32Value(rhs);
            if (bits == 64) {
                try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                try selector_state.bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                try selector_state.emitValueIntoEax(selector, binary.lhs);
                try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -imm });
                try selector_state.bindEax(selector, result_name);
            }
        },
        .xor => {
            if (bits == 64) {
                if (try selector_state.preserveRaxForDestructiveAccumulatorUse(selector, binary.lhs)) |diagnostic| return diagnostic;
                selector_state.emitValueIntoRax(selector, binary.lhs) catch return .{ .unsupported_value = "composed-block-xor64-lhs" };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } });
                try selector_state.bindRax(selector, result_name);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try selector_state.emitValueIntoEax(selector, binary.lhs);
            try selector_state.clobberArgReg(selector, .rcx);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i32Value(rhs) });
            try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } });
            try selector_state.bindEax(selector, result_name);
        },
        else => return .{ .no_emitter = "composed-block-binary-imm-rhs" },
    }
    return null;
}

pub fn lowerPairBinary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-pair-binary-op" };
    switch (op) {
        .xor => {
            const lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            const rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            try selector_state.emitPairXorInPlace(selector, rhs, lhs);
            try selector_state.bindPairScratch(selector, result_name, rhs);
        },
        .@"or" => {
            const lhs_existing = selector_state.resolvePairValue(selector, binary.lhs);
            const rhs_existing = selector_state.resolvePairValue(selector, binary.rhs);
            if (lhs_existing) |lhs_pair| {
                if (rhs_existing) |rhs_pair| {
                    try selector_state.emitPairOrInPlace(selector, lhs_pair, rhs_pair);
                    try selector_state.bindPairScratch(selector, result_name, lhs_pair);
                    return null;
                }
            }
            var lhs: RegPair = undefined;
            var rhs: RegPair = undefined;
            if (lhs_existing) |existing| {
                if (existing.eql(pair_b)) {
                    lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                    rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                } else {
                    rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                    lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
                }
            } else {
                rhs = selector_state.materializePairValue(selector, binary.rhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
                lhs = selector_state.materializePairValue(selector, binary.lhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            }
            try selector_state.emitPairOrInPlace(selector, rhs, lhs);
            try selector_state.bindPairScratch(selector, result_name, rhs);
        },
        .sub => {
            const lhs = selector_state.materializePairValue(selector, binary.lhs, pair_b) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
            const rhs = selector_state.materializePairValue(selector, binary.rhs, pair_a) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
            try selector_state.emitPairSubInPlace(selector, lhs, rhs);
            try selector_state.bindPairScratch(selector, result_name, lhs);
        },
        else => return .{ .no_emitter = "composed-block-pair-binary-op" },
    }
    return null;
}

pub fn lowerMul64(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const lhs = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
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
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-mul64-lhs" },
    };
    selector_state.emitValueIntoScratch(selector, binary.lhs, dst, 64) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };

    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .scratch64, .arg64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } }),
        .spill64 => |frame_index| {
            if (scratch64RegForUseAvoiding(selector, dst)) |src| {
                selector_state.emitValueIntoScratch(selector, binary.rhs, src, 64) catch return .{ .unsupported_value = "composed-block-mul64-rhs" };
                try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
            } else {
                if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
                try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                try selector.machine.instructions.append(selector.allocator, .{ .imul_arg64_rax = dst });
            }
        },
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try selector_state.bindScratch(selector, result_name, dst, 64);
    return null;
}

pub fn lowerMul64SpillLhsThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, lhs_frame_index: FrameIndex, rhs_value: ir.Value) !?Diagnostic {
    if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = lhs_frame_index });
    const rhs = selector_state.resolveValue(selector, rhs_value) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .arg64, .scratch64 => |src| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64 = src }),
        .spill64 => |frame_index| try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_rsp = frame_index }),
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try selector_state.bindRax(selector, result_name);
    return null;
}

pub fn plannedScratch64RegForResult(selector: *const ComposedBlockSelector, name: []const u8) ?ArgReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(name) orelse return null;
    const reg = switch (assignment) {
        .gpr64 => |reg| reg,
        .gpr32, .gpr128, .fp16, .fp32, .fp64, .stack_object, .stack_pointer, .spill => return null,
    };
    return if (scratch64RegIsAvailableForUse(selector, reg)) reg else null;
}

pub fn scratch64RegForUseAvoiding(selector: *const ComposedBlockSelector, avoid: ?ArgReg) ?ArgReg {
    for (selector_allocatable_regs) |reg| {
        if (avoid != null and reg == avoid.?) continue;
        if (scratch64RegIsAvailableForUse(selector, reg)) return reg;
    }
    return null;
}

pub fn reusableScratch64RegForInPlace(selector: *const ComposedBlockSelector, value: ir.Value) ?ArgReg {
    const name = namedValue(value) orelse return null;
    const loc = selector_state.resolveValue(selector, value) orelse return null;
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

pub fn spillScratch64SourceForInPlace(selector: *ComposedBlockSelector, value: ir.Value) !?SpillScratchForInPlaceResult {
    const name = namedValue(value) orelse return null;
    const loc = selector_state.resolveValue(selector, value) orelse return null;
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

    if (try selector_state.spillValue(selector, name)) |diagnostic| return .{ .diagnostic = diagnostic };
    return .{ .reg = reg };
}

pub fn tryLowerLshr64SpillThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u6) !?Diagnostic {
    const loc = selector_state.resolveValue(selector, value) orelse return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
    const frame_index = switch (loc) {
        .spill64 => |frame_index| frame_index,
        else => return .{ .no_spill_envelope = "composed-block-lshr64-dst" },
    };
    if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
    if (amount != 0) try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = amount });
    try selector_state.bindRax(selector, result_name);
    return null;
}

pub fn scratch64RegIsAvailableForUse(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    const status = selector_state.regConflictStatus(selector, reg) orelse return true;
    return status;
}

pub fn lowerUnsignedDivRem(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    const rhs_is_accumulator = switch (rhs) {
        .eax => bits == 32,
        .rax => bits == 64,
        else => false,
    };
    if (rhs_is_accumulator) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
    } else {
        try selector_state.emitValueIntoAccumulator(selector, binary.lhs, bits);
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    }
    try selector_state.clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .xor_edx_edx);
    try selector.machine.instructions.append(selector.allocator, if (bits == 32) .{ .div_arg32 = .rcx } else .{ .div_arg64 = .rcx });
    switch (binary.op) {
        .udiv => {
            try selector_state.bindAccumulator(selector, result_name, bits);
        },
        .urem => {
            try selector_state.bindScratch(selector, result_name, .rdx, bits);
        },
        else => unreachable,
    }
    return null;
}

pub fn lowerBinaryImmediateLhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const lhs = switch (binary.lhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (binary.op == .sub and bits == 128 and lhs == 0) {
        const rhs = selector_state.materializePairValue(selector, binary.rhs, pair_a) catch
            return .{ .unsupported_value = "composed-block-unknown-rhs" };
        try selector_state.emitZeroArg64(selector, pair_b.lo);
        try selector_state.emitZeroArg64(selector, pair_b.hi);
        try selector_state.emitPairSubInPlace(selector, pair_b, rhs);
        try selector_state.bindPairScratch(selector, result_name, pair_b);
        return null;
    }
    if (binary.op == .sub and bits == 64) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
        try selector_state.bindRax(selector, result_name);
        return null;
    }
    if (binary.op == .sub and bits <= 32) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
        if (bits < 32) {
            const shift: u5 = @intCast(bits);
            const mask = (@as(i32, 1) << shift) - 1;
            try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
        }
        try selector_state.bindEax(selector, result_name);
        return null;
    }
    if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
    if (bits == 64) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = try i64Value(lhs) });
        try selector.machine.instructions.append(selector.allocator, .shr_rax_cl);
        try selector_state.bindRax(selector, result_name);
        return null;
    }
    if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

    try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = try i32Value(lhs) });
    try selector.machine.instructions.append(selector.allocator, .shr_eax_cl);
    try selector_state.bindEax(selector, result_name);
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
                    if (selector_state.resolvePairValue(selector, cast.value)) |pair|
                        pair.lo
                    else
                        scratch64RegForUseAvoiding(selector, null) orelse return .{ .no_spill_envelope = "composed-block-cast-scratch" };
                selector_state.emitPairLowLaneIntoScratch(selector, cast.value, dst) catch return .{ .unsupported_value = "composed-block-unknown-cast" };
                try selector_state.bindScratch(selector, result_name, dst, 64);
            } else {
                const loc = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
                const result_loc: ValueLoc = if (from_bits > 32 and to_bits <= 32) switch (loc) {
                    .arg64, .scratch64 => |reg| .{ .scratch32 = reg },
                    .rax => .eax,
                    .spill64 => |frame_index| .{ .spill64 = frame_index },
                    .arg32, .scratch32, .eax => loc,
                    .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-cast-width" },
                } else loc;
                try selector_state.bindValueLoc(selector, result_name, result_loc);
                switch (result_loc) {
                    .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
                    .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-cast-width" },
                }
            }
        },
        .zext => {
            if (from_bits == 64 and to_bits == 128) {
                const dst = selector_state.choosePairScratchForClobber(selector, null) orelse return .{ .no_spill_envelope = "composed-block-zext-pair" };
                try selector_state.emitValueIntoScratch(selector, cast.value, dst.lo, 64);
                try selector_state.emitZeroArg64(selector, dst.hi);
                try selector_state.bindPairScratch(selector, result_name, dst);
                return null;
            }
            if (from_bits > 32 or (to_bits > 32 and to_bits != 64)) return .{ .no_emitter = "composed-block-zext-width" };
            try selector_state.emitValueIntoEax(selector, cast.value);
            if (from_bits < 32) {
                const shift: u5 = @intCast(from_bits);
                const mask = (@as(i32, 1) << shift) - 1;
                try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = mask });
            }
            try selector_state.bindAccumulator(selector, result_name, to_bits);
        },
        .sext => {
            if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
            const loc = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-sext" };
            const src = switch (loc) {
                .arg32, .scratch32 => |reg| reg,
                .arg64, .scratch64, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill64, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-sext-source" },
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
            try selector_state.bindScratch(selector, result_name, dst, 64);
        },
        else => return .{ .no_emitter = "composed-block-cast-op" },
    }
    return null;
}

pub fn lowerFreeze(selector: *ComposedBlockSelector, result: ?[]const u8, freeze: ir.FreezeInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(freeze.ty) orelse return .{ .no_emitter = "composed-block-freeze-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-freeze-width" };
    const loc = selector_state.resolveValue(selector, freeze.value) orelse return .{ .unsupported_value = "composed-block-unknown-freeze" };
    switch (loc) {
        .arg32, .scratch32, .eax => if (bits != 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg64, .scratch64, .rax => if (bits != 64) return .{ .no_emitter = "composed-block-freeze-width" },
        .spill64 => if (bits != 64 and bits > 32) return .{ .no_emitter = "composed-block-freeze-width" },
        .arg128, .scratch128, .stack128_value, .spill128 => if (bits != 128) return .{ .no_emitter = "composed-block-freeze-width" },
        .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill_fp => return .{ .no_emitter = "composed-block-freeze-loc" },
    }
    try selector_state.bindValueLoc(selector, result_name, loc);
    switch (loc) {
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .spill64, .spill128 => {},
        .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .spill_fp => unreachable,
    }
    return null;
}

pub fn lowerIcmp(selector: *ComposedBlockSelector, result: ?[]const u8, icmp: ir.IcmpInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    while (selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    const is_ne_zero_i16 = icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 16 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
    if (is_ne_zero_i16) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .ne and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } });
        try selector.machine.instructions.append(selector.allocator, .setne_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr) and icmp.rhs == .null_value) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.ptr)) {
        if (icmp.rhs != .named) return .{ .no_emitter = "composed-block-icmp-rhs" };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .eq and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == std.math.minInt(i128),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        const existing = selector_state.resolvePairValue(selector, icmp.lhs);
        const pair = if (existing) |source|
            if (source.contains(pair_a.lo) or source.contains(pair_a.hi)) pair_b else pair_a
        else
            pair_a;
        _ = selector_state.materializePairValue(selector, icmp.lhs, pair) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        const temp: ArgReg = if (pair.contains(.r8)) .rcx else .r8;
        try selector_state.clobberAccumulator(selector);
        try selector_state.clobberArgReg(selector, temp);
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
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 64) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else if (bits <= 32) {
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, 32) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
            } else return .{ .no_emitter = "composed-block-icmp-rhs" };
            try selector_state.clobberAccumulator(selector);
            try selector.machine.instructions.append(selector.allocator, if (bits == 64) .{ .cmp_rcx_arg64 = .r8 } else .{ .cmp_ecx_arg32 = .r8 });
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try selector_state.bindEax(selector, result_name);
            return null;
        }
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        const imm = try i64Value(rhs);
        if (imm != 0) {
            if (bits == 64) {
                selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector_state.clobberAccumulator(selector);
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = imm } });
            } else if (bits <= 32) {
                selector_state.emitValueIntoEax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
                try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(rhs) });
            } else return .{ .no_emitter = "composed-block-icmp-eq-rhs" };
            try selector.machine.instructions.append(selector.allocator, .sete_eax);
            try selector_state.bindEax(selector, result_name);
            return null;
        }
        const loc = selector_state.resolveValue(selector, icmp.lhs) orelse return .{ .unsupported_value = "composed-block-icmp-lhs" };
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
                try selector_state.clobberArgReg(selector, .rcx);
                if (bits == 64) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg64 = .rcx });
                } else if (bits <= 32) {
                    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                    try selector.machine.instructions.append(selector.allocator, .{ .test_arg32 = .rcx });
                } else return .{ .no_emitter = "composed-block-icmp-lhs-width" };
            },
            .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .spill128, .spill_fp => return .{ .no_emitter = "composed-block-icmp-lhs-loc" },
        }
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if ((icmp.predicate == .ult or icmp.predicate == .ugt) and icmp.operand_ty.eql(.{ .int = 16 }) and icmp.rhs == .int) {
        const imm = try i64Value(icmp.rhs.int);
        if (imm < 0 or imm > std.math.maxInt(u16)) return .{ .no_emitter = "composed-block-icmp-rhs" };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 16) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg16_imm16 = .{ .reg = .rcx, .imm = @intCast(imm) } });
        try selector.machine.instructions.append(selector.allocator, if (icmp.predicate == .ult) .setb_eax else .seta_eax);
    } else if (icmp.predicate == .ugt and (icmp.operand_ty.eql(.{ .int = 32 }) or icmp.operand_ty.eql(.{ .int = 64 })) and icmp.rhs == .named) {
        const bits: u16 = if (icmp.operand_ty.eql(.{ .int = 32 })) 32 else 64;
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .r8, bits) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, if (bits == 32) .{ .cmp_ecx_arg32 = .r8 } else .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 64 }) and icmp.rhs == .int) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ugt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberArgReg(selector, .r8);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r8 = try i64Value(icmp.rhs.int) });
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_r8d_arg32 = .rcx });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 6 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 1 << 5 });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == -1,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = std.math.minInt(i32) });
        try selector.machine.instructions.append(selector.allocator, .sete_eax);
    } else if (icmp.predicate == .sgt and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        try selector.machine.instructions.append(selector.allocator, .setg_eax);
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 128 }) and switch (icmp.rhs) {
        .int => |int| int == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        selector_state.emitPairHighLaneIntoRax(selector, icmp.lhs) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 64 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentRaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoRax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_rax_imm6 = 63 });
    } else if (icmp.predicate == .slt and icmp.operand_ty.eql(.{ .int = 32 }) and switch (icmp.rhs) {
        .int => |int| try i64Value(int) == 0,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    }) {
        if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .shr_eax_imm5 = 31 });
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .named) {
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .r8, 32) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        selector_state.emitValueIntoScratch(selector, icmp.rhs, .rcx, 32) catch return .{ .unsupported_value = "composed-block-icmp-rhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_ecx_arg32 = .r8 });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 32 }) and icmp.rhs == .int) {
        try selector_state.emitValueIntoEax(selector, icmp.lhs);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_eax_imm32 = try i32Value(icmp.rhs.int) });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else if (icmp.predicate == .ult and icmp.operand_ty.eql(.{ .int = 64 })) {
        const rhs = switch (icmp.rhs) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return .{ .no_emitter = "composed-block-icmp-rhs" },
        };
        selector_state.emitValueIntoScratch(selector, icmp.lhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-icmp-lhs" };
        try selector_state.clobberAccumulator(selector);
        try selector.machine.instructions.append(selector.allocator, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = try i64Value(rhs) } });
        try selector.machine.instructions.append(selector.allocator, .setb_eax);
    } else return .{ .no_emitter = "composed-block-icmp-form" };
    try selector_state.bindEax(selector, result_name);
    return null;
}
