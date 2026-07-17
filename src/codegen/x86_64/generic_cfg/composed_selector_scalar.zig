const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_icmp = @import("composed_selector_icmp.zig");
const ValueUseTransaction = @import("composed_selector_value_use_transaction.zig").ValueUseTransaction;

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
pub const lowerIcmp = selector_icmp.lowerIcmp;

pub fn lowerBinary(selector: *ComposedBlockSelector, result: ?[]const u8, binary: ir.BinaryInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (bits == 52) return lowerI52Binary(selector, result_name, binary);
    if (bits == 1) {
        if ((binary.op != .@"and" and binary.op != .@"or") or valueIsInt(binary.lhs) or valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits) catch return .{ .unsupported_value = "composed-block-unknown-rhs" };
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, accumulatorDirectMaterializationDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-unknown-lhs" };
        try emitArithmeticWrite(selector, .{ .binary_arg_eax = .{ .op = machineBinaryOp(binary.op) orelse unreachable, .reg = .rcx } });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (bits == 8) {
        if (binary.op != .@"and" or !valueIsInt(binary.rhs)) return .{ .no_emitter = "composed-block-binary-width" };
        return try lowerBinaryImmediateRhs(selector, result_name, binary);
    }
    const exact_ei_narrow = isExactEiNarrowBits(selector, bits);
    if (bits != 6 and bits != 7 and bits != 16 and bits != 32 and bits != 64 and bits != 128 and !exact_ei_narrow)
        return .{ .no_emitter = "composed-block-binary-width" };

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
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, .{ .imul_eax_arg32 = .rcx });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and (bits == 16 or bits == 32 or (exact_ei_narrow and bits < 32))) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, accumulatorDirectMaterializationDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, switch (binary.op) {
            .shl => .shl_eax_cl,
            .lshr => .shr_eax_cl,
            .ashr => .sar_eax_cl,
            else => unreachable,
        });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if ((binary.op == .shl or binary.op == .lshr or binary.op == .ashr) and (bits == 64 or (exact_ei_narrow and bits > 32))) {
        selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-ei-shift-rhs" };
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-ei-shift-lhs" };
        try emitArithmeticWrite(selector, switch (binary.op) {
            .shl => .shl_rax_cl,
            .lshr => .shr_rax_cl,
            .ashr => .sar_rax_cl,
            else => unreachable,
        });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (exact_ei_narrow and bits > 32) {
        const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
        selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, 64) catch return .{ .unsupported_value = "composed-block-ei-binary-rhs" };
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-ei-binary-lhs" };
        try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = op, .reg = .rcx } });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }

    const op = machineBinaryOp(binary.op) orelse return .{ .no_emitter = "composed-block-binary-op" };
    while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
        if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
    }
    if (namedValue(binary.lhs)) |lhs_name| {
        if (try selector_state.valueIsLiveAfterCurrent(selector, lhs_name)) {
            if (try selector_state.preserveLiveAccumulatorValue(selector, lhs_name)) |diagnostic| return diagnostic;
        }
    }
    const lhs = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };

    if (locIsAccumulator(rhs) and locIsAccumulator(lhs)) {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        const lhs_name = namedValue(binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
        const rhs_name = namedValue(binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        if (std.mem.eql(u8, lhs_name, rhs_name))
            try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits)
        else
            try selector_state.emitValueIntoScratchAndRelocate(selector, binary.rhs, .rcx, bits);
        if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try selector_state.emitBinaryArgAccumulator(selector, op, .rcx, bits);
        try finishArithmeticResult(&transaction, result_name, bits);
    } else if (locIsAccumulator(rhs)) {
        if (isCommutative(op)) {
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.rhs, .spill_live))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.rhs, accumulatorDefinition(bits));
            const current_lhs = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
            try selector_state.emitBinaryLocIntoAccumulator(selector, op, current_lhs, bits);
            try finishArithmeticResult(&transaction, result_name, bits);
        } else {
            const rhs_scratch: ArgReg = switch (lhs) {
                .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => .rcx,
                .eax, .rax => unreachable,
            };
            try selector_state.emitValueIntoScratch(selector, binary.rhs, rhs_scratch, bits);
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try selector_state.emitBinaryArgAccumulator(selector, op, rhs_scratch, bits);
            try finishArithmeticResult(&transaction, result_name, bits);
        }
    } else {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        const current_rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
        const rhs_reg: ArgReg = switch (current_rhs) {
            .arg32, .scratch32 => |reg| if (bits <= 32) reg else return .{ .no_emitter = "composed-block-rhs-i32-for-i64" },
            .arg64, .scratch64 => |reg| if (bits == 64 or (exact_ei_narrow and bits > 32)) reg else return .{ .no_emitter = "composed-block-rhs-i64-for-i32" },
            .arg128, .scratch128 => return .{ .no_emitter = "composed-block-rhs-width" },
            .spill64 => |frame_index| if (bits == 64 or (exact_ei_narrow and bits > 32)) blk: {
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else if (bits <= 32) blk: {
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = .rcx, .frame_index = frame_index } });
                break :blk .rcx;
            } else return .{ .no_emitter = "composed-block-rhs-stack" },
            .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-rhs-stack" },
            .eax, .rax => unreachable,
        };
        try selector_state.emitBinaryArgAccumulator(selector, op, rhs_reg, bits);
        try finishArithmeticResult(&transaction, result_name, bits);
    }
    return null;
}

pub fn lowerBinaryImmediateRhs(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const rhs = switch (binary.rhs) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    const bits = intBits(binary.ty) orelse return .{ .no_emitter = "composed-block-binary-not-int" };
    if (binary.op == .sdiv) {
        if (bits != 32 or rhs != 2 or binary.lhs != .named) return .{ .no_emitter = "composed-block-sdiv-form" };
        selector_state.clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-sdiv-rcx" };
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
        transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-sdiv-lhs" };
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rcx });
        try emitArithmeticWrite(selector, .{ .shr_eax_imm5 = 31 });
        try emitArithmeticWrite(selector, .add_ecx_eax);
        try emitArithmeticWrite(selector, .{ .sar_eax_imm5 = 1 });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (bits <= 32) switch (binary.op) {
        .shl, .ashr, .@"and", .@"or", .add, .sub, .xor => while (try selector_state.liveAccumulatorNameAfterCurrent(selector)) |live_name| {
            if (try selector_state.preserveLiveAccumulatorValue(selector, live_name)) |diagnostic| return diagnostic;
        },
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
                    if (amount != 0) try emitArithmeticWrite(selector, .{ .shr_arg_imm5 = .{
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
                    if (amount != 0) try emitArithmeticWrite(selector, .{ .shr_arg64_imm6 = .{
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
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
                if (amount != 0) try emitArithmeticWrite(selector, .{ .shl_rax_imm6 = amount });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-shl-imm-width" };
            const amount = try shiftAmount5(rhs);
            const lhs_loc = selector_state.resolveValue(selector, binary.lhs) orelse return .{ .unsupported_value = "composed-block-unknown-lhs" };
            switch (lhs_loc) {
                .scratch32 => |reg| {
                    if (try selector_state.preserveCurrentEaxIntoScratch(selector)) |diagnostic| return diagnostic;
                    try selector_state.emitValueIntoEax(selector, binary.lhs);
                    if (amount != 0) try emitArithmeticWrite(selector, .{ .shl_eax_imm5 = amount });
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = reg });
                    try selector_state.bindScratch(selector, result_name, reg, bits);
                },
                .arg32, .arg64, .scratch64, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => {
                    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                    defer transaction.deinit();
                    if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
                    try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
                    if (amount != 0) try emitArithmeticWrite(selector, .{ .shl_eax_imm5 = amount });
                    try finishArithmeticResult(&transaction, result_name, bits);
                },
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
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
                if (amount != 0) try emitArithmeticWrite(selector, .{ .sar_eax_imm5 = amount });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits != 64) return .{ .no_emitter = "composed-block-ashr-width" };
            const amount = try shiftAmount6(rhs);
            try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
            if (amount != 0) try emitArithmeticWrite(selector, .{ .sar_arg64_imm6 = .{
                .reg = .rcx,
                .amount = amount,
            } });
            try selector_state.bindScratch(selector, result_name, .rcx, bits);
            if (try selector_state.spillValue(selector, result_name)) |diagnostic| return diagnostic;
        },
        .@"and" => {
            if (bits == 64 and rhs == std.math.maxInt(u32)) {
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                const imm = i32BitPattern(rhs) catch return .{ .no_emitter = "composed-block-and64-imm" };
                try emitArithmeticWrite(selector, .{ .and_eax_imm32 = imm });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits == 64) {
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-and64-lhs" },
                    else => return err,
                };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .and_eax_imm32 = try i32Value(rhs) });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .@"or" => {
            if (bits == 64) {
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-or64-lhs" };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .rcx } });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try emitArithmeticWrite(selector, .{ .or_eax_imm32 = try i32Value(rhs) });
            try finishArithmeticResult(&transaction, result_name, bits);
        },
        .add => {
            if (bits == 64) {
                const imm = i32Value(rhs) catch {
                    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                    defer transaction.deinit();
                    if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                    transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-add64-lhs" };
                    try selector_state.clobberArgReg(selector, .rcx);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                    try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .add, .reg = .rcx } });
                    try finishArithmeticResult(&transaction, result_name, bits);
                    return null;
                };
                try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try emitArithmeticWrite(selector, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = imm } });
                try selector_state.bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
                try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
                try emitArithmeticWrite(selector, .{ .add_eax_imm32 = try i32Value(rhs) });
                try finishArithmeticResult(&transaction, result_name, bits);
            }
        },
        .sub => {
            const imm = try i32Value(rhs);
            if (bits == 64) {
                try selector_state.emitValueIntoScratch(selector, binary.lhs, .rcx, bits);
                try emitArithmeticWrite(selector, .{ .add_arg64_imm32 = .{ .reg = .rcx, .imm = -imm } });
                try selector_state.bindScratch(selector, result_name, .rcx, bits);
            } else {
                if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
                try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
                try emitArithmeticWrite(selector, .{ .add_eax_imm32 = -imm });
                try finishArithmeticResult(&transaction, result_name, bits);
            }
        },
        .xor => {
            if (bits == 64) {
                var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
                defer transaction.deinit();
                if (try transaction.prepare(.preserve, try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
                transaction.materialize(binary.lhs, accumulatorDefinition(bits)) catch return .{ .unsupported_value = "composed-block-xor64-lhs" };
                try selector_state.clobberArgReg(selector, .rcx);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs) });
                try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } });
                try finishArithmeticResult(&transaction, result_name, bits);
                return null;
            }
            if (bits > 32) return .{ .no_emitter = "composed-block-binary-imm-rhs-width" };
            try selector_state.clobberArgReg(selector, .rcx);
            var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
            defer transaction.deinit();
            if (try transaction.prepare(.preserve, try accumulatorArithmeticDisplacement(selector, binary.lhs, .scratch_preferred))) |diagnostic| return diagnostic;
            try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
            try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i32Value(rhs) });
            try emitArithmeticWrite(selector, .{ .binary_arg_eax = .{ .op = .xor, .reg = .rcx } });
            try finishArithmeticResult(&transaction, result_name, bits);
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
                if (lhs == .spill64) return try lowerMul64SpillLhsThroughRax(selector, result_name, binary.lhs, binary.rhs);
                return .{ .no_spill_envelope = "composed-block-mul64-dst" };
            }),
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-mul64-lhs" },
    };
    selector_state.emitValueIntoScratch(selector, binary.lhs, dst, 64) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };

    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .scratch64, .arg64 => |src| try emitArithmeticWrite(selector, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } }),
        .rax => try emitArithmeticWrite(selector, .{ .imul_arg64_rax = dst }),
        .spill64 => |frame_index| {
            if (scratch64RegForUseAvoiding(selector, dst)) |src| {
                selector_state.emitValueIntoScratch(selector, binary.rhs, src, 64) catch return .{ .unsupported_value = "composed-block-mul64-rhs" };
                try emitArithmeticWrite(selector, .{ .imul_arg64_arg64 = .{ .dst = dst, .src = src } });
            } else {
                if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
                try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = frame_index });
                try emitArithmeticWrite(selector, .{ .imul_arg64_rax = dst });
            }
        },
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try selector_state.bindScratch(selector, result_name, dst, 64);
    return null;
}

pub fn lowerMul64SpillLhsThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, lhs_value: ir.Value, rhs_value: ir.Value) !?Diagnostic {
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    transaction.materialize(lhs_value, accumulatorDefinition(64)) catch return .{ .unsupported_value = "composed-block-mul64-lhs" };
    const rhs = selector_state.resolveValue(selector, rhs_value) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    switch (rhs) {
        .arg64, .scratch64 => |src| try emitArithmeticWrite(selector, .{ .imul_rax_arg64 = src }),
        .spill64 => |frame_index| try emitArithmeticWrite(selector, .{ .imul_rax_rsp = frame_index }),
        .arg32, .scratch32, .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-mul64-rhs" },
    }
    try finishArithmeticResult(&transaction, result_name, 64);
    return null;
}

pub fn plannedScratch64RegForResult(selector: *const ComposedBlockSelector, name: []const u8) ?ArgReg {
    const plan = selector.allocation_plan orelse return null;
    const assignment = plan.assignment(name) orelse return null;
    const reg = switch (assignment) {
        .gpr64 => |reg| reg,
        .gpr32, .gpr128, .fp16, .fp32, .fp64, .vector_xmm, .stack_object, .stack_pointer, .spill => return null,
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
    return selector_state.reusableScratch64RegForInPlace(selector, value);
}

const SpillScratchForInPlaceResult = union(enum) {
    reg: ArgReg,
    diagnostic: Diagnostic,
};

pub fn spillScratch64SourceForInPlace(selector: *ComposedBlockSelector, value: ir.Value) !?SpillScratchForInPlaceResult {
    const source = selector_state.spillScratch64SourceForInPlace(selector, value) orelse return null;
    if (try selector_state.spillValue(selector, source.name)) |diagnostic| return .{ .diagnostic = diagnostic };
    return .{ .reg = source.reg };
}

pub fn tryLowerLshr64SpillThroughRax(selector: *ComposedBlockSelector, result_name: []const u8, value: ir.Value, amount: u6) !?Diagnostic {
    const loc = selector_state.resolveValue(selector, value) orelse return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
    switch (loc) {
        .spill64 => {},
        else => return .{ .no_spill_envelope = "composed-block-lshr64-dst" },
    }
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    transaction.materialize(value, accumulatorDefinition(64)) catch return .{ .no_spill_envelope = "composed-block-lshr64-dst" };
    if (amount != 0) try emitArithmeticWrite(selector, .{ .shr_rax_imm6 = amount });
    try finishArithmeticResult(&transaction, result_name, 64);
    return null;
}

pub fn scratch64RegIsAvailableForUse(selector: *const ComposedBlockSelector, reg: ArgReg) bool {
    const status = selector_state.regConflictStatus(selector, reg) orelse return true;
    return status;
}

pub fn lowerUnsignedDivRem(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
    if (binary.op == .urem) return lowerUnsignedRem(selector, result_name, binary, bits);
    const rhs = selector_state.resolveValue(selector, binary.rhs) orelse return .{ .unsupported_value = "composed-block-unknown-rhs" };
    const rhs_is_accumulator = switch (rhs) {
        .eax => bits == 32,
        .rax => bits == 64,
        else => false,
    };
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (rhs_is_accumulator) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        if (try transaction.prepare(.preserve, accumulatorDirectMaterializationDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
    } else {
        if (try transaction.prepare(.preserve, accumulatorDirectMaterializationDisplacement(selector, binary.lhs, .spill_live))) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    }
    try selector_state.clobberArgReg(selector, .rdx);
    try emitArithmeticWrite(selector, .xor_edx_edx);
    try selector_state.emitEflagsInstruction(selector, if (bits == 32) .{ .div_arg32 = .rcx } else .{ .div_arg64 = .rcx }, .clobber);
    try finishArithmeticResult(&transaction, result_name, bits);
    return null;
}

fn lowerUnsignedRem(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst, bits: u16) !?Diagnostic {
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
    try emitArithmeticWrite(selector, .xor_edx_edx);
    try selector_state.emitEflagsInstruction(selector, if (bits == 32) .{ .div_arg32 = .rcx } else .{ .div_arg64 = .rcx }, .clobber);
    try selector_state.bindScratch(selector, result_name, .rdx, bits);
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
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (binary.op == .sub and bits <= 32) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } });
        if (bits < 32) {
            const shift: u5 = @intCast(bits);
            const mask = (@as(i32, 1) << shift) - 1;
            try emitArithmeticWrite(selector, .{ .and_eax_imm32 = mask });
        }
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (binary.op == .shl and (bits == 16 or bits == 32)) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, .shl_eax_cl);
        if (bits == 16) try emitArithmeticWrite(selector, .{ .and_eax_imm32 = 0xffff });
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (binary.op != .lshr) return .{ .no_emitter = "composed-block-binary-imm-lhs" };
    if (bits == 64) {
        try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
        try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
        try emitArithmeticWrite(selector, .shr_rax_cl);
        try finishArithmeticResult(&transaction, result_name, bits);
        return null;
    }
    if (bits > 32) return .{ .no_emitter = "composed-block-variable-shift-width" };

    try selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, bits);
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    try transaction.materialize(binary.lhs, accumulatorDefinition(bits));
    try emitArithmeticWrite(selector, .shr_eax_cl);
    try finishArithmeticResult(&transaction, result_name, bits);
    return null;
}

pub fn lowerCast(selector: *ComposedBlockSelector, result: ?[]const u8, cast: ir.CastInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    const from_bits = intBits(cast.from_ty) orelse return .{ .no_emitter = "composed-block-cast-from-not-int" };
    const to_bits = intBits(cast.to_ty) orelse return .{ .no_emitter = "composed-block-cast-to-not-int" };
    if (from_bits == 52 or to_bits == 52) {
        if (ValueUseTransaction.isAccumulatorScalarCast(cast, false))
            return lowerAccumulatorScalarCast(selector, result_name, cast, from_bits, to_bits, false);
        return lowerI52Cast(cast);
    }
    if (from_bits > 128) return .{ .no_emitter = "composed-block-cast-width" };
    if (to_bits > 64 and !(cast.op == .zext and from_bits == 64 and to_bits == 128)) {
        return .{ .no_emitter = "composed-block-cast-width" };
    }

    switch (cast.op) {
        .trunc, .bitcast => {
            if (ValueUseTransaction.isPairLowScalarCast(cast))
                return lowerPairLowScalarCast(selector, result_name, cast, from_bits, to_bits);
            const loc = selector_state.resolveValue(selector, cast.value) orelse return .{ .unsupported_value = "composed-block-unknown-cast" };
            const result_loc: ValueLoc = if (from_bits > 32 and to_bits <= 32) switch (loc) {
                .arg64, .scratch64 => |reg| .{ .scratch32 = reg },
                .rax => .eax,
                .spill64 => |frame_index| .{ .spill64 = frame_index },
                .arg32, .scratch32, .eax => loc,
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-cast-width" },
            } else loc;
            try selector_state.bindValueLoc(selector, result_name, result_loc);
            switch (result_loc) {
                .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .spill64 => {},
                .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-cast-width" },
            }
        },
        .zext => {
            if (from_bits == 64 and to_bits == 128) {
                const dst = try selector_state.choosePairScratchForClobber(selector, null) orelse return .{ .no_spill_envelope = "composed-block-zext-pair" };
                try selector_state.emitValueIntoScratch(selector, cast.value, dst.lo, 64);
                try selector_state.emitZeroArg64(selector, dst.hi);
                try selector_state.bindPairScratch(selector, result_name, dst);
                return null;
            }
            const exact_ei_narrow = isExactEiNarrowBits(selector, from_bits) or isExactEiNarrowBits(selector, to_bits);
            if (from_bits > 32 and (!exact_ei_narrow or to_bits > 64))
                return .{ .no_emitter = "composed-block-zext-width" };
            if (to_bits > 32 and to_bits != 64 and !exact_ei_narrow) return .{ .no_emitter = "composed-block-zext-width" };
            if (ValueUseTransaction.isAccumulatorScalarCast(cast, exact_ei_narrow))
                return lowerAccumulatorScalarCast(selector, result_name, cast, from_bits, to_bits, exact_ei_narrow);
            return error.UnsupportedCodegenValue;
        },
        .sext => {
            if (from_bits != 32 or to_bits != 64) return .{ .no_emitter = "composed-block-sext-width" };
            if (ValueUseTransaction.isSignExtendScratchCast(cast))
                return lowerSignExtendScratchCast(selector, result_name, cast);
            return .{ .unsupported_value = "composed-block-unknown-sext" };
        },
        else => return .{ .no_emitter = "composed-block-cast-op" },
    }
    return null;
}

const ScalarCastDiagnosticKind = enum {
    pair_low,
    accumulator,
    sign_extend,
};

fn lowerPairLowScalarCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
    from_bits: u16,
    to_bits: u16,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = .gpr128,
        },
        .form = .pair_low_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .pair_low_scalar_cast = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .op = cast.op,
            .from_bits = from_bits,
            .to_bits = to_bits,
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .pair_low, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerAccumulatorScalarCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
    from_bits: u16,
    to_bits: u16,
    exact_ei: bool,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = if (from_bits <= 32) .gpr32 else .gpr64,
        },
        .form = .accumulator_scalar_cast_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .accumulator_scalar_cast = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
            .op = cast.op,
            .from_bits = from_bits,
            .to_bits = to_bits,
            .immediate = switch (cast.value) {
                .int => |value| value,
                else => null,
            },
            .exact_ei = exact_ei,
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    _ = try transaction.beginAccumulatorSession();
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .accumulator, err) orelse return err;
    try transaction.commit();
    return null;
}

fn lowerSignExtendScratchCast(
    selector: *ComposedBlockSelector,
    result_name: []const u8,
    cast: ir.CastInst,
) !?Diagnostic {
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const source_request = try transaction.register(.{
        .source = cast.value,
        .expected = .{
            .ty = cast.from_ty,
            .register_class = .gpr32,
        },
        .form = .sign_extend_scratch_operand,
        .destination = .prepared_view,
        .prepared_action = .{ .sign_extend_scratch = .{
            .result = try ValueUseTransaction.ActionIdentity.init(result_name),
        } },
    });
    transaction.seal() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.prepare() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.materializeAll() catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    const lease = transaction.preparedView(source_request) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    transaction.executePreparedAction(lease) catch |err|
        return scalarCastValueUseDiagnostic(&transaction, source_request, .sign_extend, err) orelse return err;
    try transaction.commit();
    return null;
}

fn scalarCastValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    source_request: ValueUseTransaction.RequestHandle,
    kind: ScalarCastDiagnosticKind,
    err: anyerror,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (!transaction.failedRequestIs(source_request)) return null;
    return switch (kind) {
        .pair_low => switch (err) {
            error.ValueUseScalarCastScratchUnavailable => .{ .no_spill_envelope = "composed-block-cast-scratch" },
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            => .{ .unsupported_value = "composed-block-unknown-cast" },
            else => null,
        },
        .accumulator => switch (err) {
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            error.ValueUseScalarCastImmediateMismatch,
            => .{ .unsupported_value = "composed-block-unknown-cast" },
            else => null,
        },
        .sign_extend => switch (err) {
            error.ValueUseUnresolvedSource,
            error.ValueUseExpiredSource,
            error.ValueUseUnsupportedSource,
            => .{ .unsupported_value = "composed-block-unknown-sext" },
            error.ValueUseTypeMismatch,
            error.ValueUseRegisterClassMismatch,
            error.ValueUseSourceViewMismatch,
            error.ValueUseScalarCastWidthUnsupported,
            error.ValueUseScalarCastLocationUnsupported,
            => .{ .no_emitter = "composed-block-sext-source" },
            else => null,
        },
    };
}

fn lowerI52Cast(
    cast: ir.CastInst,
) !?Diagnostic {
    if (cast.value != .named) return .{ .no_emitter = "composed-block-i52-cast-value" };
    return .{ .no_emitter = "composed-block-i52-cast-form" };
}

fn lowerI52Binary(selector: *ComposedBlockSelector, result_name: []const u8, binary: ir.BinaryInst) !?Diagnostic {
    const function = selector.function orelse return .{ .no_emitter = "composed-block-i52-shift-provenance" };
    if (binary.op != .shl or binary.lhs != .named or binary.rhs != .named or
        !isExactI52ShiftCount(function.*, binary.rhs.named))
    {
        return .{ .no_emitter = "composed-block-i52-binary-form" };
    }
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(
        .preserve,
        try accumulatorPreserveCurrentDisplacement(selector, binary.lhs, .spill_live),
    )) |diagnostic| return diagnostic;
    selector_state.emitValueIntoScratch(selector, binary.rhs, .rcx, 64) catch
        return .{ .unsupported_value = "composed-block-i52-shift-rhs" };
    transaction.materialize(binary.lhs, accumulatorDefinition(52)) catch
        return .{ .unsupported_value = "composed-block-i52-shift-lhs" };
    // Count 52 is poison in LLVM's i52 domain. The captured family keeps that
    // value on the unselected side of its guarding select; x86 may compute any
    // physical value here, and the low-52 mask preserves every defined case.
    try emitArithmeticWrite(selector, .shl_rax_cl);
    try maskRaxToI52(selector);
    try finishArithmeticResult(&transaction, result_name, 52);
    return null;
}

fn isExactI52ShiftCount(function: ir.Function, count_name: []const u8) bool {
    const widened = instructionByResult(function, count_name) orelse return false;
    const zext = switch (widened.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 6 }) or !zext.to_ty.eql(.{ .int = 52 }) or zext.value != .named) return false;

    const added = instructionByResult(function, zext.value.named) orelse return false;
    const add = switch (added.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.flags.nuw or !add.ty.eql(.{ .int = 6 }) or add.lhs != .named or !add.rhs.eql(.{ .int = 1 })) return false;

    const narrowed = instructionByResult(function, add.lhs.named) orelse return false;
    const trunc = switch (narrowed.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 52 }) or !trunc.to_ty.eql(.{ .int = 6 }) or trunc.value != .named) return false;

    const counted = instructionByResult(function, trunc.value.named) orelse return false;
    const call = switch (counted.kind) {
        .call => |call| call,
        else => return false,
    };
    return isExactCtlzI52Envelope(call);
}

fn isExactCtlzI52Envelope(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.ctlz.i52") or call.inline_asm != null or call.callee_value != null or
        call.callee_function_ty != null or call.calling_conv != null or call.raw_args != null or call.operand_bundle != null or
        !call.ret_ty.eql(.{ .int = 52 }) or call.args.items.len != 2)
    {
        return false;
    }
    if (call.tail_kind) |tail_kind| if (!std.mem.eql(u8, tail_kind, "tail")) return false;
    if (call.attrs) |attrs| {
        const trimmed = std.mem.trim(u8, attrs, " \t");
        if (trimmed.len < 2 or trimmed[0] != '#') return false;
        for (trimmed[1..]) |c| if (!std.ascii.isDigit(c)) return false;
    }
    const ret_attrs = std.mem.trim(u8, call.ret_attrs orelse return false, " \t");
    if (!std.mem.eql(u8, ret_attrs, "range(i52 0, 53)")) return false;
    return call.args.items[0].attrs == null and call.args.items[1].attrs == null and
        call.args.items[0].ty.eql(.{ .int = 52 }) and call.args.items[1].ty.eql(.{ .int = 1 }) and
        call.args.items[1].value.eql(.{ .int = 1 });
}

fn instructionByResult(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
        }
    }
    return null;
}

fn maskRaxToI52(selector: *ComposedBlockSelector) !void {
    try selector_state.clobberArgReg(selector, .rcx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = (1 << 52) - 1 });
    try emitArithmeticWrite(selector, .{ .binary_arg_rax = .{ .op = .@"and", .reg = .rcx } });
}

fn accumulatorLocDisplacement(
    value: ir.Value,
    source: ValueLoc,
) selector_state.AccumulatorDisplacementPolicy {
    return switch (source) {
        .eax, .rax => switch (value) {
            .named => |name| .{ .reuse_source = name },
            else => .spill_live,
        },
        else => .spill_live,
    };
}

fn accumulatorArithmeticDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    const name = switch (value) {
        .named => |name| name,
        else => return fallback,
    };
    const source = selector_state.resolveValue(selector, value) orelse return fallback;
    return switch (source) {
        .eax, .rax => if (!try selector_state.valueIsLiveAfterCurrent(selector, name))
            .{ .reuse_source = name }
        else
            fallback,
        else => fallback,
    };
}

fn accumulatorDirectMaterializationDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) selector_state.AccumulatorDisplacementPolicy {
    const source = selector_state.resolveValue(selector, value) orelse return fallback;
    return switch (source) {
        .eax, .rax => accumulatorLocDisplacement(value, source),
        else => fallback,
    };
}

pub fn accumulatorPreserveCurrentDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) !selector_state.AccumulatorDisplacementPolicy {
    if (try selector_state.liveAccumulatorName(selector)) |name| return .{ .spill_source = name };
    const name = switch (value) {
        .named => |name| name,
        else => return fallback,
    };
    const source = selector_state.resolveValue(selector, value) orelse return fallback;
    return switch (source) {
        .eax, .rax => .{ .reuse_source = name },
        else => fallback,
    };
}

fn accumulatorDefinition(bits: u16) selector_state.AccumulatorDefinition {
    return if (bits <= 32)
        .zeroExtending(bits)
    else if (bits == 64)
        .fullRax()
    else
        .zeroExtendedRax(bits);
}

fn emitArithmeticWrite(selector: *ComposedBlockSelector, instruction: x86_64_machine.Instruction) !void {
    try selector_state.emitEflagsInstruction(selector, instruction, .write);
}

fn finishArithmeticResult(
    transaction: *selector_state.AccumulatorDefinitionTransaction,
    result_name: []const u8,
    bits: u16,
) !void {
    try transaction.define(result_name, accumulatorDefinition(bits));
    try transaction.commit();
}

pub fn isExactEiNarrowBits(selector: *const ComposedBlockSelector, bits: u16) bool {
    const function = selector.function orelse return false;
    if (!stage2_planning.isExactEiScalarFamily(function.*)) return false;
    return switch (bits) {
        3, 4, 5, 13, 14, 26, 27, 55, 56 => true,
        else => false,
    };
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
        .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-freeze-loc" },
    }
    try selector_state.bindValueLoc(selector, result_name, loc);
    switch (loc) {
        .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .stack128_value, .spill64, .spill128 => {},
        .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill_fp, .spill_vector, .aggregate_sse => unreachable,
    }
    return null;
}
