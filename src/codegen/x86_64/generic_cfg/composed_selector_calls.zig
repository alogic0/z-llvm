const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_machine = @import("../machine.zig");
const x86_64_types = @import("../types.zig");
const sysv_abi = @import("../sysv_abi.zig");
const inspection = @import("inspection.zig");
const selector_types = @import("selector_types.zig");
const stage2_planning = @import("stage2_planning.zig");
const composed_helpers = @import("composed_helpers.zig");
const selector_state = @import("composed_selector_state.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_memory = @import("composed_selector_memory.zig");

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

fn isColdAssumeBundle(bundle: []const u8) bool {
    return std.mem.eql(u8, std.mem.trim(u8, bundle, " \t"), "[ \"cold\"() ]");
}

pub fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (call.isDebugVariableLocation()) return null;
    if (call.inline_asm != null) return lowerFpBarrier(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.lifetime.start.p0") or std.mem.eql(u8, call.callee, "llvm.lifetime.end.p0")) return lowerLifetimeMarker(result, call);
    if (std.mem.eql(u8, call.callee, "llvm.assume")) return lowerAssume(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.trap")) return try lowerTrap(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f16")) return try lowerFpAbs(selector, result, call, 16);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f32")) return try lowerFpAbs(selector, result, call, 32);
    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize")) return try lowerIntByteSizeCall(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i32")) return try lowerAbsI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try lowerAbsI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i128")) return try lowerAbsI128(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i16")) return try lowerCtlzI16(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32")) return try lowerCtlzI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fshl.i32")) return try lowerFshlI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64")) return try lowerInlineMemcpy(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i32")) return try lowerUnsignedOverflowI32(selector, result, call, .add);
    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i32")) return try lowerUnsignedOverflowI32(selector, result, call, .sub);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i64")) return try lowerSmulOverflowI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i128")) return try lowerSmulOverflowI128(selector, result, call);
    if (call.callee_value != null) return .{ .unsupported_value = "composed-block-indirect-call" };
    if (!isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-call-form" };
    }
    if (sysv_abi.callHasScalarSseType(call)) return lowerScalarSseCall(selector, result, call);
    try sysv_abi.rejectUnsupportedCallEnvelope(call);
    try sysv_abi.rejectUnsupportedCallSignature(call);
    const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
    if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64 and ret_bits != 128) return .{ .no_emitter = "composed-block-call-ret-width" };
    var abi_index: usize = 0;

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    for (call.args.items) |arg| {
        const target = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
        if (try lowerDirectCallArg(selector, arg, target)) |diagnostic| return diagnostic;
        abi_index += callArgRegisterCount(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (abi_index > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };
    }

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    if (result) |result_name| switch (ret_bits) {
        0 => return .{ .unsupported_value = "composed-block-void-call-result" },
        32 => try selector_state.bindEax(selector, result_name),
        64 => try selector_state.bindRax(selector, result_name),
        128 => {},
        else => unreachable,
    };
    return null;
}

fn lowerScalarSseCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    var plan = try sysv_abi.planScalarCall(selector.allocator, call);
    defer plan.deinit(selector.allocator);

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    for (call.args.items) |arg| {
        if (!sysv_abi.isScalarSseAbiType(arg.ty)) continue;
        const name = switch (arg.value) {
            .named => |name| name,
            else => continue,
        };
        if (try selector_state.spillValue(selector, name)) |diagnostic| return diagnostic;
    }

    for (call.args.items, plan.assignments.items) |arg, assignment| switch (assignment) {
        .gpr => |target| if (try lowerDirectCallArg(selector, arg, target)) |diagnostic| return diagnostic,
        .sse => |target| {
            const bits: u16 = if (arg.ty == .half) 16 else if (arg.ty == .float) 32 else if (arg.ty == .double) 64 else unreachable;
            if (try selector_fp.materializeFpValue(selector, arg.value, target, bits)) |diagnostic| return diagnostic;
        },
        .stack_i32_const, .stack_i32_param => return .{ .unsupported_value = "composed-block-call-stack-gpr-arg" },
        .stack_f32_const, .stack_f32_param, .stack_f64_const, .stack_f64_param => return .{ .unsupported_value = "composed-block-call-stack-fp-arg" },
        .byval_stack_copy, .aggregate_register_passthrough, .aggregate_stack_passthrough => return .{ .no_emitter = "composed-block-call-aggregate-arg" },
    };

    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    if (result) |result_name| {
        if (sysv_abi.isScalarSseAbiType(call.ret_ty)) {
            const bits: u16 = if (call.ret_ty == .half) 16 else if (call.ret_ty == .float) 32 else 64;
            try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
        } else if (call.ret_ty.eql(.{ .int = 32 })) {
            try selector_state.bindEax(selector, result_name);
        } else if (call.ret_ty.eql(.{ .int = 64 }) or call.ret_ty == .ptr) {
            try selector_state.bindRax(selector, result_name);
        } else if (call.ret_ty == .void) {
            return .{ .unsupported_value = "composed-block-void-call-result" };
        } else {
            return .{ .no_emitter = "composed-block-call-ret" };
        }
    }
    return null;
}

fn lowerFpAbs(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, bits: u16) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-fabs-result" };
    const ty: ir.Type = if (bits == 16) .half else .float;
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty) or call.inline_asm != null or call.callee_value != null) {
        return .{ .no_emitter = "composed-block-fabs-form" };
    }
    const source = selector_state.resolveValue(selector, call.args.items[0].value) orelse return .{ .unsupported_value = "composed-block-fabs-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fabs-source" };
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
    try selector_state.clobberXmmReg(selector, .xmm0);
    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = if (bits == 16) 0x7fff else 0x7fff_ffff });
    try selector.machine.instructions.append(selector.allocator, .{ .movd_eax_xmm = .xmm0 });
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerFpBarrier(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
    if (result != null) return .{ .unsupported_value = "composed-block-inline-asm-result" };
    const inline_asm = call.inline_asm orelse return .{ .no_emitter = "composed-block-inline-asm-call" };
    if (!inline_asm.sideeffect or inline_asm.template.len != 0 or
        !std.mem.eql(u8, inline_asm.constraints, "rm,~{dirflag},~{fpsr},~{flags}") or
        call.ret_ty != .void or call.args.items.len != 1 or
        (call.args.items[0].ty != .float and call.args.items[0].ty != .double))
    {
        return .{ .no_emitter = "composed-block-inline-asm-call" };
    }
    const loc = selector_state.resolveValue(selector, call.args.items[0].value) orelse return .{ .unsupported_value = "composed-block-inline-asm-value" };
    const bits: u16 = if (call.args.items[0].ty == .float) 32 else 64;
    switch (loc) {
        .xmm => |fp| if (fp.bits != bits) return .{ .unsupported_value = "composed-block-inline-asm-value" },
        .spill_fp => |fp| if (fp.bits != bits) return .{ .unsupported_value = "composed-block-inline-asm-value" },
        else => return .{ .unsupported_value = "composed-block-inline-asm-value" },
    }
    return null;
}

fn lowerLifetimeMarker(result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
    if (result != null or call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.tail_kind != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-lifetime-call-form" };
    }
    if (call.ret_ty != .void or call.args.items.len != 1 or call.args.items[0].ty != .ptr) {
        return .{ .no_emitter = "composed-block-lifetime-signature" };
    }
    return null;
}

pub fn lowerUnsignedOverflowI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, op: MachineBinaryOp) !?Diagnostic {
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

    const lhs_loc = selector_state.resolveValue(selector, lhs.value) orelse return .{ .unsupported_value = "composed-block-overflow-lhs" };
    const rhs_scratch: ArgReg = switch (lhs_loc) {
        .arg32, .arg64, .scratch32, .scratch64 => |reg| if (reg == .rcx) .rdx else .rcx,
        .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector => .rcx,
    };
    selector_state.emitValueIntoScratch(selector, rhs.value, rhs_scratch, 32) catch return .{ .unsupported_value = "composed-block-overflow-rhs" };
    switch (lhs_loc) {
        .eax, .rax => {
            selector_state.spillAccumulatorAliasesExcept(selector, lhs.value) catch return .{ .no_spill_envelope = "composed-block-overflow-lhs-alias" };
            if (namedValue(lhs.value)) |lhs_name| {
                if (selector_state.valueIsLiveAfterCurrent(selector, lhs_name)) {
                    selector_state.spillValueOrError(selector, lhs_name) catch return .{ .no_spill_envelope = "composed-block-overflow-live-lhs" };
                }
            }
        },
        else => {},
    }
    selector_state.emitValueIntoEax(selector, lhs.value) catch return .{ .unsupported_value = "composed-block-overflow-lhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_scratch } });
    try selector_state.clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdx });
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .setb_eax);
    try selector.overflow_results.put(result_name, .{
        .value = .{ .scratch32 = .rdx },
        .overflow = .eax,
    });
    return null;
}

pub fn lowerSmulOverflowI128(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    const lhs_spill = selector_state.ensurePairSpill(selector, lhs.value) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-lhs" };
    const rhs_spill = selector_state.ensurePairSpill(selector, rhs.value) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-rhs" };
    selector_state.clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };
    selector_state.clobberArgReg(selector, .r8) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };
    selector_state.clobberArgReg(selector, .r9) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-scratch" };

    const p00_name = try ownedInternalValueName(selector, result_name, "p00");
    const p01_name = try ownedInternalValueName(selector, result_name, "p01");
    const p10_name = try ownedInternalValueName(selector, result_name, "p10");
    const p11_name = try ownedInternalValueName(selector, result_name, "p11");
    const overflow_name = try ownedInternalValueName(selector, result_name, "overflow");
    const p00 = selector_state.emitUnsignedLimbProduct(selector, lhs_spill.lo, rhs_spill.lo, p00_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p00" };
    const p01 = selector_state.emitUnsignedLimbProduct(selector, lhs_spill.lo, rhs_spill.hi, p01_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p01" };
    const p10 = selector_state.emitUnsignedLimbProduct(selector, lhs_spill.hi, rhs_spill.lo, p10_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p10" };
    const p11 = selector_state.emitUnsignedLimbProduct(selector, lhs_spill.hi, rhs_spill.hi, p11_name) catch return .{ .no_spill_envelope = "composed-block-smulo-i128-p11" };

    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .r9, .frame_index = p01.hi } });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = .rdx, .frame_index = p11.hi } });

    try selector_state.accumulateLimbWithCarry(selector, p00.hi, p01.lo, .r8, .r9);
    try selector_state.accumulateRegWithCarry(selector, .r8, p10.lo, .r8, .r9);
    try selector_state.accumulateRegWithCarry(selector, .r9, p10.hi, .r9, .rdx);
    try selector_state.accumulateRegWithCarry(selector, .r9, p11.lo, .r9, .rdx);

    try selector_state.emitSignedUpperCorrection(selector, lhs_spill.hi, rhs_spill);
    try selector_state.emitSignedUpperCorrection(selector, rhs_spill.hi, lhs_spill);

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

    const overflow_spill = selector_state.allocateSpillSlot(selector, overflow_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i128-overflow-spill" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = overflow_spill });
    try selector.overflow_results.put(result_name, .{
        .value = .{ .spill128 = p00 },
        .overflow = .{ .spill64 = overflow_spill },
        .require_value_first = false,
    });
    return null;
}

pub fn lowerSmulOverflowI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    selector_state.prepareFixedProductDefs(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-fixed-defs" };
    selector_state.emitValueIntoScratch(selector, rhs.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-rhs" };
    selector_state.emitValueIntoAccumulator(selector, lhs.value, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-lhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .imul_rax_arg64_full = .rcx });

    const value_name = try ownedInternalValueName(selector, result_name, "value");
    const value_spill = selector_state.allocateSpillSlot(selector, value_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i64-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = value_spill });
    selector_state.clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-sign" };
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rcx });
    try selector.machine.instructions.append(selector.allocator, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } });
    try selector.machine.instructions.append(selector.allocator, .{ .cmp_rcx_arg64 = .rdx });
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-overflow" };
    try selector.machine.instructions.append(selector.allocator, .setne_eax);
    const overflow_name = try ownedInternalValueName(selector, result_name, "overflow");
    const overflow_spill = selector_state.allocateSpillSlot(selector, overflow_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i64-overflow" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_eax_rsp = overflow_spill });
    try selector.overflow_results.put(result_name, .{
        .value = .{ .spill64 = value_spill },
        .overflow = .{ .spill64 = overflow_spill },
        .require_value_first = false,
    });
    return null;
}

pub fn lowerExtractValue(selector: *ComposedBlockSelector, result: ?[]const u8, extract: ir.ExtractValueInst) !?Diagnostic {
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
    try selector_state.bindResultLoc(selector, result_name, loc);
    if (overflow.value_extracted and overflow.overflow_extracted) _ = selector.overflow_results.remove(aggregate_name);
    return null;
}

pub fn lowerInlineMemcpy(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    selector_state.emitValueIntoScratch(selector, dst.value, .rdi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-dst" };
    selector_state.emitValueIntoScratch(selector, src.value, .rsi, 64) catch return .{ .unsupported_value = "composed-block-memcpy-src" };
    selector_state.emitValueIntoScratch(selector, len.value, .rdx, 64) catch return .{ .unsupported_value = "composed-block-memcpy-len" };
    try selector.machine.instructions.append(selector.allocator, .memcpy_rdi_rsi_rdx_rax);
    return null;
}

pub fn lowerCtlzI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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
    selector_state.emitValueIntoScratch(selector, value_arg.value, .rdi, 32) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .clz_i32_edi_eax);
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerCtlzI16(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-ctlz-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-ctlz-signature" };
    const value_arg = call.args.items[0];
    const undef_arg = call.args.items[1];
    const valid_zero_flag = undef_arg.value.eql(.{ .int = 0 }) or undef_arg.value.eql(.{ .int = 1 });
    if (!value_arg.ty.eql(.{ .int = 16 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !valid_zero_flag) {
        return .{ .no_emitter = "composed-block-ctlz-args" };
    }
    selector_state.emitValueIntoEax(selector, value_arg.value) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .and_eax_imm32 = 0xffff });
    try selector_state.clobberArgReg(selector, .rdi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdi });
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .clz_i32_edi_eax);
    try selector.machine.instructions.append(selector.allocator, .{ .add_eax_imm32 = -16 });
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerFshlI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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
    selector_state.emitValueIntoEax(selector, call.args.items[0].value) catch return .{ .unsupported_value = "composed-block-fshl-lhs" };
    selector_state.emitValueIntoScratch(selector, call.args.items[1].value, .rcx, 32) catch return .{ .unsupported_value = "composed-block-fshl-rhs" };
    try selector.machine.instructions.append(selector.allocator, .{ .fshl_eax_arg32_imm5 = .{ .reg = .rcx, .amount = amount } });
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerAssume(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
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

pub fn lowerTrap(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

pub fn lowerIntByteSizeCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    selector_state.emitValueIntoScratch(selector, arg.value, .rdi, 16) catch return .{ .unsupported_value = "composed-block-intbytesize-arg-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerAbsI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    try selector_state.emitValueIntoScratch(selector, value_arg.value, .rdi, 32);
    if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .abs_i32_edi_eax);
    try selector_state.bindEax(selector, result_name);
    return null;
}

pub fn lowerAbsI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    try selector_state.emitValueIntoScratch(selector, value_arg.value, .rdi, 64);
    if (try selector_state.spillCurrentAccumulator(selector)) |diagnostic| return diagnostic;
    try selector.machine.instructions.append(selector.allocator, .abs_i64_rdi_rax);
    try selector_state.bindRax(selector, result_name);
    return null;
}

pub fn lowerAbsI128(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
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

    try selector_state.emitPairSignMask(selector, "__zllvm_abs_i128_sign", value_arg.value, pair_a);
    _ = selector_state.materializePairValue(selector, value_arg.value, pair_b) catch return .{ .unsupported_value = "composed-block-abs-value" };
    try selector_state.emitPairXorInPlace(selector, pair_b, pair_a);
    try selector_state.emitPairSubInPlace(selector, pair_b, pair_a);
    try selector_state.bindPairScratch(selector, result_name, pair_b);
    return null;
}

pub fn ownedInternalValueName(selector: *ComposedBlockSelector, result_name: []const u8, suffix: []const u8) ![]const u8 {
    const name = try std.fmt.allocPrint(selector.allocator, "__zllvm_{s}_{s}", .{ result_name, suffix });
    errdefer selector.allocator.free(name);
    try selector.machine.owned_labels.append(selector.allocator, name);
    return name;
}

pub fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
    if (arg.ty == .ptr) {
        const loc = selector_state.resolveValue(selector, arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
        const disp = switch (loc) {
            .stack_scalar => |stack| stack.base_disp,
            .stack128 => |disp| disp,
            .arg32, .arg64, .arg128, .eax, .rax, .scratch32, .scratch64, .scratch128, .xmm, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-call-ptr-arg" },
        };
        try selector_state.clobberArgReg(selector, target);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
        if (disp != 0) {
            const addend: i32 = std.math.cast(i32, disp) orelse return .{ .no_spill_envelope = "composed-block-call-stack-disp" };
            try selector.machine.instructions.append(selector.allocator, .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } });
        }
        return null;
    }

    const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-call-arg-width" };
    const loc = selector_state.resolveValue(selector, arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-arg" };
    if (bits == 128) {
        const target_hi = ArgReg.fromIndex(argRegIndex(target) + 1) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
        switch (loc) {
            .arg128, .scratch128 => |pair| try selector_state.emitPairIntoAbiRegs(selector, pair, .{ .lo = target, .hi = target_hi }),
            .stack128_value => |disp| {
                try selector_memory.loadStackU64IntoArg(selector, target, disp);
                try selector_memory.loadStackU64IntoArg(selector, target_hi, disp + 8);
            },
            .spill128 => |spill| {
                try selector_state.clobberArgReg(selector, target);
                try selector_state.clobberArgReg(selector, target_hi);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = spill.lo } });
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target_hi, .frame_index = spill.hi } });
            },
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-call-arg-loc" },
        }
        return null;
    }
    switch (loc) {
        .arg32, .scratch32 => |reg| {
            if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
            if (reg != target) {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_arg = .{ .dst = target, .src = reg } });
            }
        },
        .arg64, .scratch64 => |reg| {
            if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
            if (reg != target) {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
            }
        },
        .eax => {
            if (bits != 32) return .{ .no_emitter = "composed-block-call-arg-width" };
            try selector_state.clobberArgReg(selector, target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = target });
        },
        .rax => {
            if (bits != 64) return .{ .no_emitter = "composed-block-call-arg-width" };
            try selector_state.clobberArgReg(selector, target);
            try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
        },
        .spill64 => |frame_index| {
            try selector_state.clobberArgReg(selector, target);
            if (bits == 64) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
            } else if (bits == 32) {
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg_rsp = .{ .reg = target, .frame_index = frame_index } });
            } else return .{ .no_emitter = "composed-block-call-arg-width" };
        },
        .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector => return .{ .no_emitter = "composed-block-call-arg-loc" },
    }
    return null;
}
