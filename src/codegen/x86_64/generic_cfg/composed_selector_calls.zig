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
const selector_vector = @import("composed_selector_vector.zig");
const selector_scalar = @import("composed_selector_scalar.zig");
const selector_frame = @import("composed_selector_frame.zig");
const selector_fp = @import("composed_selector_fp.zig");
const selector_memory = @import("composed_selector_memory.zig");
const value_use = @import("composed_selector_value_use_transaction.zig");
const intrinsic_attrs = @import("intrinsic_attrs.zig");
const stack_arguments = @import("stack_arguments.zig");

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

pub const ComposedBlockSelector = selector_state.ComposedBlockSelector;

fn isColdAssumeBundle(bundle: []const u8) bool {
    return std.mem.eql(u8, std.mem.trim(u8, bundle, " \t"), "[ \"cold\"() ]");
}

pub fn lowerCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (call.isDebugVariableLocation()) return null;
    if (sysv_abi.isVariadicCall(call)) try sysv_abi.rejectUnsupportedCallSignature(call);
    if (std.mem.eql(u8, call.callee, "llvm.experimental.noalias.scope.decl"))
        return if (result == null and intrinsic_attrs.isNoAliasScopeDecl(call)) null else .{ .no_emitter = "composed-block-noalias-scope-decl" };
    if (call.inline_asm != null) {
        if (@import("../inline_asm.zig").classify(call)) |operation|
            return lowerSystemAssembly(selector, result, call, operation);
        return lowerFpBarrier(selector, result, call);
    }
    if (std.mem.eql(u8, call.callee, "llvm.lifetime.start.p0") or std.mem.eql(u8, call.callee, "llvm.lifetime.end.p0")) return lowerLifetimeMarker(result, call);
    if (std.mem.eql(u8, call.callee, "llvm.assume")) return lowerAssume(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.trap")) return try lowerTrap(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.returnaddress")) return lowerReturnAddress(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f16")) return try lowerFpAbs(selector, result, call, 16);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f32")) return try lowerFpAbs(selector, result, call, 32);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.f64")) return try lowerFpAbs(selector, result, call, 64);
    if (std.mem.eql(u8, call.callee, "llvm.maxnum.f32")) return try selector_fp.lowerMaxNum(selector, result, call, 32);
    if (std.mem.eql(u8, call.callee, "llvm.maxnum.f64")) return try selector_fp.lowerMaxNum(selector, result, call, 64);
    if (std.mem.eql(u8, call.callee, "llvm.copysign.f32")) return try selector_fp.lowerCopySignF32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.copysign.f64")) return try selector_fp.lowerCopySignF64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.copysign.v2f32")) return try selector_vector.lowerCopySignV2F32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.copysign.v2f64")) return try selector_vector.lowerCopySignV2F64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v2f32")) return try selector_vector.lowerFabsV2F32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v4f32")) return try selector_vector.lowerFabsV4F32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.fabs.v2f64")) return try selector_vector.lowerFabsV2F64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "zig.target.intByteSize")) return try lowerIntByteSizeCall(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i32")) return try lowerAbsI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i64")) return try lowerAbsI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.abs.i128")) return try lowerAbsI128(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i16")) return try lowerCtlzI16(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i32")) return try lowerCtlzI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i52")) return try lowerCtlzI52(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctlz.i64")) return try lowerCtlzI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.cttz.i32")) return try lowerCttzI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.cttz.i64")) return try lowerCttzI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.ctpop.i64")) return try lowerCtpop(selector, result, call, 64);
    if (std.mem.eql(u8, call.callee, "llvm.ctpop.i128")) return try lowerCtpop(selector, result, call, 128);
    if (std.mem.startsWith(u8, call.callee, "llvm.usub.sat.")) return try lowerUsubSat(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.bswap.i16")) return try lowerBitPermutation(selector, result, call, 16, .byte_swap);
    if (std.mem.eql(u8, call.callee, "llvm.bswap.i32")) return try lowerBitPermutation(selector, result, call, 32, .byte_swap);
    if (std.mem.eql(u8, call.callee, "llvm.bswap.i64")) return try lowerBitPermutation(selector, result, call, 64, .byte_swap);
    if (std.mem.eql(u8, call.callee, "llvm.bswap.i128")) return try lowerBitPermutation(selector, result, call, 128, .byte_swap);
    if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i32")) return try lowerBitPermutation(selector, result, call, 32, .bit_reverse);
    if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i64")) return try lowerBitPermutation(selector, result, call, 64, .bit_reverse);
    if (std.mem.eql(u8, call.callee, "llvm.bitreverse.i128")) return try lowerBitPermutation(selector, result, call, 128, .bit_reverse);
    if (std.mem.eql(u8, call.callee, "llvm.ucmp.i32.i128")) return try lowerI128Compare(selector, result, call, false);
    if (std.mem.eql(u8, call.callee, "llvm.scmp.i32.i128")) return try lowerI128Compare(selector, result, call, true);
    if (std.mem.eql(u8, call.callee, "llvm.fshl.i32")) return try lowerFshlI32(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.memset.p0.i64")) return try lowerMemset(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.memcpy.inline.p0.p0.i64") or
        std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64")) return try lowerInlineMemcpy(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.memmove.p0.p0.i64")) return try lowerInlineMemmove(selector, result, call);
    if (std.mem.eql(u8, call.callee, "strlen") and
        !(call.args.items.len == 1 and ordinaryGlobalArgument(selector, call.args.items[0].value) != null))
        return try lowerInlineStrlen(selector, result, call);
    if (std.mem.eql(u8, call.callee, "strnlen")) return try lowerInlineStrnlen(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.uadd.with.overflow.i32")) return try lowerUnsignedOverflowI32(selector, result, call, .add);
    if (std.mem.eql(u8, call.callee, "llvm.usub.with.overflow.i32")) return try lowerUnsignedOverflowI32(selector, result, call, .sub);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i64") or std.mem.eql(u8, call.callee, "llvm.umul.with.overflow.i64")) return try lowerSmulOverflowI64(selector, result, call);
    if (std.mem.eql(u8, call.callee, "llvm.smul.with.overflow.i128")) return try lowerSmulOverflowI128(selector, result, call);
    if (std.mem.startsWith(u8, call.callee, "llvm.")) return .{ .no_emitter = "composed-block-llvm-intrinsic" };
    if (call.callee_value) |callee| {
        if (callee != .named or callee.named.len == 0 or callee.named[0] == '@' or
            call.callee_function_ty != null or sysv_abi.callHasScalarSseType(call) or call.ret_ty.eql(.{ .int = 1 }))
            return .{ .unsupported_value = "composed-block-indirect-call" };
    }
    if (!isDefaultOrFastcc(call.calling_conv) or !sysv_abi.callReturnAttrsSupported(call) or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-call-form" };
    }
    if (sysv_abi.callHasScalarSseType(call)) return lowerScalarSseCall(selector, result, call);
    try sysv_abi.rejectUnsupportedCallEnvelope(call);
    try sysv_abi.rejectUnsupportedCallSignature(call);
    for (call.args.items) |arg| try sysv_abi.rejectUnsupportedCallArgAttrs(arg);
    if (call.ret_ty.eql(.{ .int = 1 })) return lowerBooleanCall(selector, result, call);
    const ret_bits = if (call.ret_ty == .void) @as(u16, 0) else if (call.ret_ty == .ptr) @as(u16, 64) else intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-call-ret" };
    if (ret_bits != 0 and ret_bits != 32 and ret_bits != 64 and ret_bits != 128) return .{ .no_emitter = "composed-block-call-ret-width" };
    var abi_index: usize = 0;

    var transaction: ?selector_state.AccumulatorDefinitionTransaction = if (result != null and (ret_bits == 32 or ret_bits == 64))
        try selector_state.AccumulatorDefinitionTransaction.begin(selector)
    else
        null;
    defer if (transaction) |*active| active.deinit();
    if (transaction) |*active| {
        if (try active.prepareCallBeforeArguments(.clobber)) |diagnostic| return diagnostic;
    } else if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    // The call target is another simultaneous input and can die at this call.
    // Preserve it before argument registers change, then load RAX last.
    const indirect_target: ?FrameIndex = if (call.callee_value) |callee|
        selector_state.preserveIndirectCallTarget(selector, callee) catch |err| switch (err) {
            error.UnsupportedCodegenValue => return .{ .unsupported_value = "composed-block-indirect-target" },
            else => return err,
        }
    else
        null;
    if (sysv_abi.isVariadicCall(call)) {
        if (try selector_state.preserveVariadicArgumentSources(selector, call)) |diagnostic| return diagnostic;
    }
    if (try selector_state.preserveCallArgumentSources(selector, call)) |diagnostic| return diagnostic;
    const stack_count = stack_arguments.callCount(call) orelse 0;
    var stack_sources: [stack_arguments.max_arguments - 6]FrameIndex = undefined;
    if (stack_count != 0) {
        for (call.args.items[6..], 0..) |arg, index| {
            if (try lowerDirectCallArg(selector, arg, .rdi)) |diagnostic| return diagnostic;
            // NUL cannot be an unquoted IR identifier. The state authority
            // owns a copy of this private slot key and reuses it across calls.
            var key_buffer: [40]u8 = undefined;
            const key = try std.fmt.bufPrint(&key_buffer, "\x00outgoing.{d}", .{index});
            const frame = selector_state.allocateSpillSlot(selector, key) orelse return .{ .no_spill_envelope = "composed-block-call-stack-slots" };
            stack_sources[index] = frame;
            try selector.machine.instructions.append(selector.allocator, .{ .spill_arg64_rsp = .{ .frame_index = frame, .reg = .rdi } });
        }
    }
    for (call.args.items[0..if (stack_count != 0) 6 else call.args.items.len]) |arg| {
        const target = ArgReg.fromIndex(abi_index) catch return .{ .unsupported_value = "composed-block-call-arg-reg" };
        if (try lowerDirectCallArg(selector, arg, target)) |diagnostic| return diagnostic;
        abi_index += callArgRegisterCount(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
        if (abi_index > 6) return .{ .unsupported_value = "composed-block-call-arg-count" };
    }
    if (transaction) |*active| try active.finishCallPreparationAfterArguments();

    const needs_alignment = selector.stack_frame_bytes == 0;
    if (needs_alignment) try selector_frame.appendSubRsp(selector, 8);
    var pushed_bytes: u32 = 0;
    if (stack_count != 0) {
        if (needs_alignment) return .{ .no_spill_envelope = "composed-block-call-stack-frame" };
        if (stack_count % 2 != 0) {
            try selector_frame.appendSubRsp(selector, 8);
            pushed_bytes = 8;
        }
        var index = stack_count;
        while (index != 0) {
            index -= 1;
            const displacement = std.math.add(u32, try stack_sources[index].byteOffset(), pushed_bytes) catch
                return .{ .no_spill_envelope = "composed-block-call-stack-offset" };
            try selector.machine.instructions.append(selector.allocator, .{ .push_stack_disp32 = displacement });
            pushed_bytes += 8;
        }
    }
    if (sysv_abi.isVariadicCall(call)) {
        // Caller values are preserved and integer/pointer arguments materialized.
        // MOV leaves condition flags unchanged and supplies the SysV AL count.
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = 0 });
    }
    if (indirect_target) |frame| {
        if (needs_alignment) return .{ .no_spill_envelope = "composed-block-indirect-frame" };
        const displacement = std.math.add(u32, try frame.byteOffset(), pushed_bytes) catch return .{ .no_spill_envelope = "composed-block-indirect-offset" };
        try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = displacement });
        try selector_state.emitEflagsInstruction(selector, .{ .indirect_call_rax = call.ret_ty }, .clobber);
    } else if (transaction != null)
        try selector_state.emitEflagsInstruction(selector, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } }, .clobber)
    else
        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    if (needs_alignment) try selector_frame.appendAddRsp(selector, 8);
    if (pushed_bytes != 0) try selector_frame.appendAddRsp(selector, pushed_bytes);
    if (result) |result_name| switch (ret_bits) {
        0 => return .{ .unsupported_value = "composed-block-void-call-result" },
        32 => {
            try transaction.?.define(result_name, .zeroExtending(32));
            try transaction.?.commit();
        },
        64 => {
            try transaction.?.define(result_name, .fullRax());
            try transaction.?.commit();
        },
        128 => try selector_state.bindFixedProductResult(selector, result_name),
        else => unreachable,
    };
    return null;
}

fn lowerReturnAddress(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const name = result orelse return .{ .unsupported_value = "composed-block-return-address-result" };
    if (call.ret_ty != .ptr or call.args.items.len != 1 or call.args.items[0].attrs != null or
        !call.args.items[0].ty.eql(.{ .int = 32 }) or !call.args.items[0].value.eql(.{ .int = 0 }) or
        call.callee_value != null or call.callee_function_ty != null or call.inline_asm != null or call.raw_args != null or
        call.operand_bundle != null or call.calling_conv != null or call.ret_attrs != null)
        return .{ .no_emitter = "composed-block-return-address-form" };
    try sysv_abi.rejectUnsupportedCallEnvelope(call);
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;
    // The frame has a fixed size. Calls restore RSP before the next IR
    // instruction, so its entry return address is at exactly this offset.
    try selector.machine.instructions.append(selector.allocator, .{ .load_stack_disp32_rax = selector.stack_frame_bytes });
    try transaction.define(name, .fullRax());
    try transaction.commit();
    return null;
}

pub fn lowerUsubSat(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-usub-sat-result" };
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        !isDefaultOrFastcc(call.calling_conv) or call.raw_args != null or call.operand_bundle != null or
        call.args.items.len != 2)
    {
        return .{ .no_emitter = "composed-block-usub-sat-form" };
    }
    const bits = intBits(call.ret_ty) orelse return .{ .no_emitter = "composed-block-usub-sat-type" };
    if (bits == 0 or bits > 64) return .{ .no_emitter = "composed-block-usub-sat-width" };
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-block-usub-sat-tail" };
        }
    }
    const lhs = call.args.items[0];
    const rhs = call.args.items[1];
    if (!lhs.ty.eql(call.ret_ty) or lhs.value != .named or
        !rhs.ty.eql(call.ret_ty) or rhs.value != .int or rhs.value.int < 0)
    {
        return .{ .no_emitter = "composed-block-usub-sat-args" };
    }
    if (bits == 64) {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(
            .preserve,
            try selector_scalar.accumulatorPreserveCurrentDisplacement(selector, lhs.value, .spill_live),
        )) |diagnostic| return diagnostic;
        transaction.materialize(lhs.value, .fullRax()) catch return .{ .unsupported_value = "composed-block-usub-sat-lhs" };
        try selector_state.clobberArgReg(selector, .rcx);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs.value.int) });
        try selector_state.emitEflagsDefinition(selector, .{ .binary_arg_rax = .{ .op = .sub, .reg = .rcx } }, .carry);
        const no_borrow = try selector_state.allocateEdgeLabel(selector);
        try selector_state.emitEflagsInstruction(selector, .{ .jae = no_borrow }, .use);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rax = 0 });
        try selector.machine.instructions.append(selector.allocator, .{ .label = no_borrow });
        try transaction.define(result_name, .fullRax());
        try transaction.commit();
        return null;
    } else {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(
            .preserve,
            try selector_scalar.accumulatorPreserveCurrentDisplacement(selector, lhs.value, .spill_live),
        )) |diagnostic| return diagnostic;
        transaction.materialize(lhs.value, .zeroExtending(bits)) catch return .{ .unsupported_value = "composed-block-usub-sat-lhs" };
        try selector_state.clobberArgReg(selector, .rcx);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_rcx = try i64Value(rhs.value.int) });
        try selector_state.emitEflagsDefinition(selector, .{ .binary_arg_eax = .{ .op = .sub, .reg = .rcx } }, .carry);
        const no_borrow = try selector_state.allocateEdgeLabel(selector);
        try selector_state.emitEflagsInstruction(selector, .{ .jae = no_borrow }, .use);
        try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = 0 });
        try selector.machine.instructions.append(selector.allocator, .{ .label = no_borrow });
        try transaction.define(result_name, .zeroExtending(bits));
        try transaction.commit();
        return null;
    }
}

pub const lowerUsubSatI64 = lowerUsubSat;

fn lowerScalarSseCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    var plan = try sysv_abi.planScalarCall(selector.allocator, call);
    defer plan.deinit(selector.allocator);

    const gpr_result = result != null and (call.ret_ty.eql(.{ .int = 32 }) or call.ret_ty.eql(.{ .int = 64 }) or call.ret_ty == .ptr);
    var transaction: ?selector_state.AccumulatorDefinitionTransaction = if (gpr_result)
        try selector_state.AccumulatorDefinitionTransaction.begin(selector)
    else
        null;
    defer if (transaction) |*active| active.deinit();
    if (transaction) |*active| {
        if (try active.prepareCallBeforeArguments(.clobber)) |diagnostic| return diagnostic;
    } else if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    var has_vector_abi = sysv_abi.isVector128AbiType(call.ret_ty);
    for (call.args.items) |arg| has_vector_abi = has_vector_abi or sysv_abi.isVector128AbiType(arg.ty);
    if (has_vector_abi) if (try selector_state.preserveFixedCallInputs(selector, call)) |diagnostic| return diagnostic;
    for (call.args.items) |arg| {
        if (!sysv_abi.isScalarSseAbiType(arg.ty) and !sysv_abi.isVector128AbiType(arg.ty)) continue;
        const name = switch (arg.value) {
            .named => |name| name,
            else => continue,
        };
        if (try selector_state.spillValue(selector, name)) |diagnostic| return diagnostic;
    }

    for (call.args.items, plan.assignments.items) |arg, assignment| switch (assignment) {
        .gpr => |target| if (try lowerDirectCallArg(selector, arg, target)) |diagnostic| return diagnostic,
        .sse => |target| {
            if (sysv_abi.isVector128AbiType(arg.ty)) {
                if (try selector_vector.materializeAbiVector(selector, arg.value, arg.ty, target)) |diagnostic| return diagnostic;
                continue;
            }
            const bits: u16 = if (arg.ty == .half) 16 else if (arg.ty == .float) 32 else if (arg.ty == .double) 64 else unreachable;
            if (try selector_fp.materializeFpValue(selector, arg.value, target, bits)) |diagnostic| return diagnostic;
        },
        .stack_i32_const, .stack_i32_param => return .{ .unsupported_value = "composed-block-call-stack-gpr-arg" },
        .stack_f32_const, .stack_f32_param, .stack_f64_const, .stack_f64_param => return .{ .unsupported_value = "composed-block-call-stack-fp-arg" },
        .byval_stack_copy, .aggregate_register_passthrough, .aggregate_stack_passthrough => return .{ .no_emitter = "composed-block-call-aggregate-arg" },
    };
    if (transaction) |*active| try active.finishCallPreparationAfterArguments();

    if (transaction != null)
        try selector_state.emitEflagsInstruction(selector, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } }, .clobber)
    else
        try selector.machine.instructions.append(selector.allocator, .{ .direct_call = .{ .symbol = call.callee, .ret_ty = call.ret_ty } });
    if (result) |result_name| {
        if (selector_vector.abiShape(call.ret_ty)) |shape| {
            try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = 128, .shape = .{ .vector = shape } } });
            return null;
        }
        if (sysv_abi.isScalarSseAbiType(call.ret_ty)) {
            const bits: u16 = if (call.ret_ty == .half) 16 else if (call.ret_ty == .float) 32 else 64;
            try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
        } else if (call.ret_ty.eql(.{ .int = 32 })) {
            try transaction.?.define(result_name, .zeroExtending(32));
            try transaction.?.commit();
        } else if (call.ret_ty.eql(.{ .int = 64 }) or call.ret_ty == .ptr) {
            try transaction.?.define(result_name, .fullRax());
            try transaction.?.commit();
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
    const ty: ir.Type = switch (bits) {
        16 => .half,
        32 => .float,
        64 => .double,
        else => unreachable,
    };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty) or call.inline_asm != null or call.callee_value != null) {
        return .{ .no_emitter = "composed-block-fabs-form" };
    }
    const source = selector_state.resolveValue(selector, call.args.items[0].value) orelse return .{ .unsupported_value = "composed-block-fabs-source" };
    selector_state.materializeLocIntoLoc(selector, source, .{ .xmm = .{ .reg = .xmm0, .bits = bits } }) catch return .{ .unsupported_value = "composed-block-fabs-source" };
    try selector_state.clobberAccumulator(selector);
    if (bits == 64) {
        try selector.machine.instructions.append(selector.allocator, .{ .movq_xmm_rax = .xmm0 });
        try selector_state.emitEflagsInstruction(selector, .{ .shl_rax_imm6 = 1 }, .write);
        try selector_state.emitEflagsInstruction(selector, .{ .shr_rax_imm6 = 1 }, .write);
        try selector_state.clobberXmmReg(selector, .xmm0);
        try selector.machine.instructions.append(selector.allocator, .{ .movq_rax_xmm = .xmm0 });
    } else {
        try selector.machine.instructions.append(selector.allocator, .{ .movd_xmm_eax = .xmm0 });
        try selector_state.clobberXmmReg(selector, .xmm0);
        try selector_state.emitEflagsInstruction(selector, .{ .and_eax_imm32 = if (bits == 16) 0x7fff else 0x7fff_ffff }, .write);
        try selector.machine.instructions.append(selector.allocator, .{ .movd_eax_xmm = .xmm0 });
    }
    try selector_state.bindResultLoc(selector, result_name, .{ .xmm = .{ .reg = .xmm0, .bits = bits } });
    return null;
}

fn lowerSystemAssembly(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, operation: @import("../inline_asm.zig").Operation) !?Diagnostic {
    if (operation == .register_snapshot and result != null) return .{ .unsupported_value = "inline-asm-result" };
    if (operation == .linux_syscall and result == null) return .{ .unsupported_value = "inline-asm-result" };
    var transaction: ?selector_state.AccumulatorDefinitionTransaction = if (result != null)
        try selector_state.AccumulatorDefinitionTransaction.begin(selector)
    else
        null;
    defer if (transaction) |*active| active.deinit();
    if (transaction) |*active| {
        if (try active.prepareCallBeforeArguments(.clobber)) |diagnostic| return diagnostic;
    } else if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    if (try selector_state.preserveFixedCallInputs(selector, call)) |diagnostic| return diagnostic;
    switch (operation) {
        .linux_syscall => |count| {
            for (call.args.items[1..], 0..) |arg, index| {
                if (try lowerDirectCallArg(selector, arg, try ArgReg.fromIndex(index))) |diagnostic| return diagnostic;
            }
            try transaction.?.finishCallPreparationAfterArguments();
            try transaction.?.materialize(call.args.items[0].value, .fullRax());
            try selector_state.emitEflagsInstruction(selector, .{ .linux_syscall = count }, .clobber);
            if (result) |name| try transaction.?.define(name, .fullRax());
        },
        .register_snapshot => {
            if (try lowerDirectCallArg(selector, call.args.items[0], .rdi)) |diagnostic| return diagnostic;
            try selector_state.emitEflagsInstruction(selector, .register_snapshot_rdi, .clobber);
        },
    }
    if (transaction) |*active| try active.commit();
    return null;
}

fn lowerFpBarrier(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) ?Diagnostic {
    if (result != null) return .{ .unsupported_value = "composed-block-inline-asm-result" };
    const inline_asm = call.inline_asm orelse return .{ .no_emitter = "composed-block-inline-asm-call" };
    if (inline_asm.sideeffect and inline_asm.template.len == 0 and
        std.mem.eql(u8, inline_asm.constraints, "m,~{memory},~{dirflag},~{fpsr},~{flags}") and
        call.ret_ty == .void and call.args.items.len == 1 and call.args.items[0].ty == .ptr)
    {
        const loc = selector_state.resolveValue(selector, call.args.items[0].value) orelse return .{ .unsupported_value = "composed-block-inline-asm-value" };
        return switch (loc) {
            .stack_scalar => |stack| if (stack.bits == 64 and stack.kind == .integer) null else .{ .unsupported_value = "composed-block-inline-asm-value" },
            else => .{ .unsupported_value = "composed-block-inline-asm-value" },
        };
    }
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
        .arg128, .scratch128, .xmm, .eax, .rax, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill128, .spill_fp, .spill_vector, .aggregate_sse => .rcx,
    };
    selector_state.emitValueIntoScratch(selector, rhs.value, rhs_scratch, 32) catch return .{ .unsupported_value = "composed-block-overflow-rhs" };
    switch (lhs_loc) {
        .eax, .rax => {
            selector_state.spillAccumulatorAliasesExcept(selector, lhs.value) catch return .{ .no_spill_envelope = "composed-block-overflow-lhs-alias" };
            if (namedValue(lhs.value)) |lhs_name| {
                if (try selector_state.valueIsLiveAfterCurrent(selector, lhs_name)) {
                    selector_state.spillValueOrError(selector, lhs_name) catch return .{ .no_spill_envelope = "composed-block-overflow-live-lhs" };
                }
            }
        },
        else => {},
    }
    selector_state.emitValueIntoEax(selector, lhs.value) catch return .{ .unsupported_value = "composed-block-overflow-lhs" };
    try selector_state.emitEflagsDefinition(selector, .{ .binary_arg_eax = .{ .op = op, .reg = rhs_scratch } }, .carry);
    try selector_state.clobberArgReg(selector, .rdx);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdx });
    try selector_state.clobberAccumulator(selector);
    try selector_state.emitEflagsInstruction(selector, .setb_eax, .use);
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
    try selector_state.emitEflagsInstruction(selector, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .r9 });
    try selector_state.emitEflagsInstruction(selector, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .r8 });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg_rax = .rdx });
    try selector_state.emitEflagsInstruction(selector, .{ .binary_arg_rax = .{ .op = .xor, .reg = .rcx } }, .write);
    try selector_state.emitEflagsInstruction(selector, .{ .binary_arg_rax = .{ .op = .@"or", .reg = .r8 } }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rcx });
    try selector_state.emitEflagsInstruction(selector, .{ .cmp_arg64_imm64 = .{ .reg = .rcx, .imm = 0 } }, .definition);
    try selector_state.emitEflagsInstruction(selector, .setne_eax, .use);

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
    const signed = !std.mem.eql(u8, call.callee, "llvm.umul.with.overflow.i64");
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

    selector_state.preserveFixedProductOperands(selector, lhs.value, rhs.value) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-operands" };
    selector_state.prepareFixedProductDefs(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-fixed-defs" };
    selector_state.emitValueIntoScratch(selector, rhs.value, .rcx, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-rhs" };
    selector_state.emitValueIntoAccumulator(selector, lhs.value, 64) catch return .{ .unsupported_value = "composed-block-smulo-i64-lhs" };
    try selector_state.emitEflagsInstruction(selector, if (signed) .{ .imul_rax_arg64_full = .rcx } else .{ .mul_rax_arg64_full = .rcx }, .write);

    const value_name = try ownedInternalValueName(selector, result_name, "value");
    const value_spill = selector_state.allocateSpillSlot(selector, value_name) orelse return .{ .no_spill_envelope = "composed-block-smulo-i64-value" };
    try selector.machine.instructions.append(selector.allocator, .{ .spill_rax_rsp = value_spill });
    if (signed) {
        selector_state.clobberArgReg(selector, .rcx) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-sign" };
        try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = .rcx });
        try selector_state.emitEflagsInstruction(selector, .{ .sar_arg64_imm6 = .{ .reg = .rcx, .amount = 63 } }, .write);
        try selector_state.emitEflagsInstruction(selector, .{ .cmp_rcx_arg64 = .rdx }, .definition);
    } else {
        // Unsigned overflow is exactly a nonzero upper half of RDX:RAX.
        try selector_state.emitEflagsInstruction(selector, .{ .test_arg64 = .rdx }, .definition);
    }
    selector_state.clobberAccumulator(selector) catch return .{ .no_spill_envelope = "composed-block-smulo-i64-overflow" };
    try selector_state.emitEflagsInstruction(selector, .setne_eax, .use);
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

fn lowerMemset(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (result != null or call.ret_ty != .void or call.args.items.len != 4)
        return .{ .no_emitter = "composed-block-memset-signature" };
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
        return .{ .no_emitter = "composed-block-memset-call-form" };
    if (call.tail_kind) |tail| if (!std.mem.eql(u8, tail, "tail") and !std.mem.eql(u8, tail, "notail"))
        return .{ .no_emitter = "composed-block-memset-tail-kind" };
    const dst = call.args.items[0];
    const fill = call.args.items[1];
    const len = call.args.items[2];
    const vol = call.args.items[3];
    if (dst.ty != .ptr or !fill.ty.eql(.{ .int = 8 }) or !len.ty.eql(.{ .int = 64 }) or
        !vol.ty.eql(.{ .int = 1 }) or !vol.value.eql(.{ .int = 0 }))
        return .{ .no_emitter = "composed-block-memset-args" };
    // Pointer address spaces and ABI-changing argument attributes are opaque
    // in CallArg. Admit only the alignment annotation used by this intrinsic.
    if (!memsetAlignmentAttribute(dst.attrs) or fill.attrs != null or len.attrs != null or vol.attrs != null)
        return .{ .no_emitter = "composed-block-memset-attrs" };
    // Undef permits any concrete byte; select zero. Poison and all memory/ABI
    // envelope restrictions retain their existing fail-closed behavior.
    if (dst.value != .named or (fill.value != .named and fill.value != .int and fill.value != .undef) or
        (len.value != .named and len.value != .int))
        return .{ .unsupported_value = "composed-block-memset-value" };
    const fill_immediate: u8 = if (fill.value == .int) blk: {
        if (fill.value.int < -128 or fill.value.int > 255) return .{ .unsupported_value = "composed-block-memset-fill" };
        break :blk @truncate(@as(u128, @bitCast(fill.value.int)));
    } else 0;
    const length_immediate: u64 = if (len.value == .int) std.math.cast(u64, len.value.int) orelse
        return .{ .unsupported_value = "composed-block-memset-length" } else 0;
    var authority = try ValueUseTransaction.begin(selector);
    defer authority.deinit();
    const fill_request = if (fill.value == .named) try authority.register(.{
        .source = fill.value,
        .expected = .{ .ty = .{ .int = 8 }, .register_class = .gpr32 },
        .form = .gpr32,
        .destination = .prepared_source,
    }) else null;
    const length_request = if (len.value == .named) try authority.register(.{
        .source = len.value,
        .expected = .{ .ty = .{ .int = 64 }, .register_class = .gpr64 },
        .form = .memcpy_length,
        .destination = .prepared_source,
    }) else null;
    const action = try authority.register(.{
        .source = dst.value,
        .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 },
        .form = .memcpy_pointer,
        .destination = .prepared_view,
        .prepared_action = .{ .inline_memset = .{
            .fill = fill_request,
            .fill_immediate = fill_immediate,
            .length = length_request,
            .length_immediate = length_immediate,
        } },
    });
    authority.seal() catch |err| return memsetDiagnostic(&authority, err) orelse return err;
    authority.prepare() catch |err| return memsetDiagnostic(&authority, err) orelse return err;
    authority.materializeAll() catch |err| return memsetDiagnostic(&authority, err) orelse return err;
    authority.executePreparedAction(try authority.preparedView(action)) catch |err|
        return memsetDiagnostic(&authority, err) orelse return err;
    try authority.commit();
    return null;
}

fn memsetAlignmentAttribute(attrs: ?[]const u8) bool {
    const text = attrs orelse return true;
    if (!std.mem.startsWith(u8, text, "align ")) return false;
    const alignment = std.fmt.parseUnsigned(u32, text[6..], 10) catch return false;
    return std.math.isPowerOfTwo(alignment);
}

fn memsetDiagnostic(authority: *const ValueUseTransaction, err: anyerror) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return authority.actionDiagnostic();
    return switch (err) {
        error.ValueUseUnresolvedSource,
        error.ValueUseExpiredSource,
        error.ValueUseSourceViewMismatch,
        error.ValueUseRegisterClassMismatch,
        error.ValueUseTypeMismatch,
        error.ValueUseMemcpyPointerHomeUnsupported,
        error.ValueUseMemcpyPointerWidthMismatch,
        error.ValueUseMemcpyLengthHomeUnsupported,
        error.ValueUseMemcpyLengthWidthMismatch,
        => .{ .unsupported_value = "composed-block-memset-value" },
        else => null,
    };
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
    // Keep the pre-existing inline intrinsic contract; the newly admitted
    // ordinary intrinsic accepts only the exact retained pointer annotations.
    if (std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64")) {
        if (call.callee_function_ty != null or call.calling_conv != null or
            !memsetAlignmentAttribute(dst.attrs) or !memcpySourceAttributes(src.attrs) or
            len.attrs != null or is_volatile.attrs != null)
            return .{ .no_emitter = "composed-block-memcpy-attrs" };
    }

    var authority = try ValueUseTransaction.begin(selector);
    defer authority.deinit();
    const source_request = authority.register(.{
        .source = src.value,
        .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 },
        .form = .memcpy_pointer,
        .destination = .prepared_source,
    }) catch return .{ .unsupported_value = "composed-block-memcpy-src" };
    const length_immediate: u64 = if (len.value == .int) std.math.cast(u64, len.value.int) orelse return .{ .unsupported_value = "composed-block-memcpy-len" } else 0;
    const length_request: ?ValueUseTransaction.RequestHandle = if (len.value == .int) null else authority.register(.{
        .source = len.value,
        .expected = .{ .ty = .{ .int = 64 }, .register_class = .gpr64 },
        .form = .memcpy_length,
        .destination = .prepared_source,
    }) catch return .{ .unsupported_value = "composed-block-memcpy-len" };
    const destination_request = authority.register(.{
        .source = dst.value,
        .expected = .{ .ty = .ptr, .register_class = .gpr64, .pointer_address_space = 0 },
        .form = .memcpy_pointer,
        .destination = .prepared_view,
        .prepared_action = .{ .inline_memcpy = .{
            .source = source_request,
            .length = length_request,
            .length_immediate = length_immediate,
        } },
    }) catch return .{ .unsupported_value = "composed-block-memcpy-dst" };
    authority.seal() catch |err| return inlineMemcpyValueUseDiagnostic(
        &authority,
        err,
        destination_request,
        source_request,
        length_request,
    ) orelse return err;
    authority.prepare() catch |err| return inlineMemcpyValueUseDiagnostic(
        &authority,
        err,
        destination_request,
        source_request,
        length_request,
    ) orelse return err;
    authority.materializeAll() catch |err| return inlineMemcpyValueUseDiagnostic(
        &authority,
        err,
        destination_request,
        source_request,
        length_request,
    ) orelse return err;
    const lease = authority.preparedView(destination_request) catch |err|
        return inlineMemcpyValueUseDiagnostic(
            &authority,
            err,
            destination_request,
            source_request,
            length_request,
        ) orelse return err;
    authority.executePreparedAction(lease) catch |err|
        return inlineMemcpyValueUseDiagnostic(
            &authority,
            err,
            destination_request,
            source_request,
            length_request,
        ) orelse return err;
    try authority.commit();
    return null;
}

pub fn lowerInlineMemmove(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (result != null) return .{ .unsupported_value = "composed-block-memmove-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-memmove-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-memmove-tail-kind" };
    }
    if (call.ret_ty != .void or call.args.items.len != 4) return .{ .no_emitter = "composed-block-memmove-signature" };
    const dst = call.args.items[0];
    const src = call.args.items[1];
    const len = call.args.items[2];
    const is_volatile = call.args.items[3];
    if (dst.ty != .ptr or src.ty != .ptr or !len.ty.eql(.{ .int = 64 }) or
        !is_volatile.ty.eql(.{ .int = 1 }) or !is_volatile.value.eql(.{ .int = 0 }))
    {
        return .{ .no_emitter = "composed-block-memmove-args" };
    }

    if (try selector_state.spillLiveCallerClobbersForCall(selector)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, dst, .rdi)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, src, .rsi)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, len, .rdx)) |diagnostic| return diagnostic;

    try selector_state.emitEflagsInstruction(selector, .memmove_rdi_rsi_rdx_rax, .clobber);
    return null;
}

pub fn lowerInlineStrlen(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-strlen-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-strlen-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) return .{ .no_emitter = "composed-block-strlen-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 1) return .{ .no_emitter = "composed-block-strlen-signature" };
    const s = call.args.items[0];
    if (s.ty != .ptr) return .{ .no_emitter = "composed-block-strlen-args" };

    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepareCallBeforeArguments(.clobber)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, s, .rdi)) |diagnostic| return diagnostic;
    try transaction.finishCallPreparationAfterArguments();

    try selector_state.emitEflagsInstruction(selector, .strlen_rdi_rax, .clobber);
    try transaction.define(result_name, .fullRax());
    try transaction.commit();
    return null;
}

pub fn lowerInlineStrnlen(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-strnlen-result" };
    if (call.inline_asm != null or call.callee_value != null or !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-strnlen-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) return .{ .no_emitter = "composed-block-strnlen-tail-kind" };
    }
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-strnlen-signature" };
    const s = call.args.items[0];
    const maxlen = call.args.items[1];
    if (s.ty != .ptr or !maxlen.ty.eql(.{ .int = 64 })) return .{ .no_emitter = "composed-block-strnlen-args" };

    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepareCallBeforeArguments(.clobber)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, s, .rdi)) |diagnostic| return diagnostic;
    if (try lowerDirectCallArg(selector, maxlen, .rsi)) |diagnostic| return diagnostic;
    try transaction.finishCallPreparationAfterArguments();

    try selector_state.emitEflagsInstruction(selector, .strnlen_rdi_rsi_rax, .clobber);
    try transaction.define(result_name, .fullRax());
    try transaction.commit();
    return null;
}

fn memcpySourceAttributes(attrs: ?[]const u8) bool {
    const text = attrs orelse return true;
    if (std.mem.eql(u8, text, "readonly")) return true;
    if (std.mem.startsWith(u8, text, "readonly ")) return memsetAlignmentAttribute(text[9..]);
    return memsetAlignmentAttribute(text);
}

fn inlineMemcpyValueUseDiagnostic(
    transaction: *const ValueUseTransaction,
    err: anyerror,
    destination: ValueUseTransaction.RequestHandle,
    source: ValueUseTransaction.RequestHandle,
    length: ?ValueUseTransaction.RequestHandle,
) ?Diagnostic {
    if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
    if (transaction.failedRequestIs(destination))
        return .{ .unsupported_value = "composed-block-memcpy-dst" };
    if (transaction.failedRequestIs(source))
        return .{ .unsupported_value = "composed-block-memcpy-src" };
    if (length) |handle| if (transaction.failedRequestIs(handle))
        return .{ .unsupported_value = "composed-block-memcpy-len" };
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
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr32 },
        .form = .gpr32,
        .destination = .{ .gpr32 = .rdi },
    }) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    const accumulator = try transaction.beginAccumulatorSession();
    transaction.prepare() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.materializeAll() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .clz_i32_edi_eax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .zeroExtending(32));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

fn accumulatorInputDisplacement(
    selector: *const ComposedBlockSelector,
    value: ir.Value,
    fallback: selector_state.AccumulatorDisplacementPolicy,
) selector_state.AccumulatorDisplacementPolicy {
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

pub fn lowerCtlzI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-ctlz-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-ctlz-signature" };
    const value_arg = call.args.items[0];
    const undef_arg = call.args.items[1];
    const valid_zero_flag = undef_arg.value.eql(.{ .int = 0 }) or undef_arg.value.eql(.{ .int = 1 });
    if (!value_arg.ty.eql(.{ .int = 64 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !valid_zero_flag) {
        return .{ .no_emitter = "composed-block-ctlz-args" };
    }
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr64 },
        .form = .gpr64,
        .destination = .{ .gpr64 = .rdi },
    }) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    const accumulator = try transaction.beginAccumulatorSession();
    transaction.prepare() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.materializeAll() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .clz_i64_rdi_eax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .fullRax());
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

pub fn lowerCtlzI52(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (!isExactCtlzI52Call(call)) return .{ .no_emitter = "composed-block-ctlz-i52-envelope" };
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = call.args.items[0].value,
        .expected = .{ .ty = call.args.items[0].ty, .register_class = .gpr64 },
        .form = .gpr64,
        .destination = .{ .gpr64 = .rdi },
    }) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    const accumulator = try transaction.beginAccumulatorSession();
    transaction.prepare() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    transaction.materializeAll() catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .clz_i64_rdi_eax, .clobber);
    try selector_state.emitEflagsInstruction(selector, .{ .add_eax_imm32 = -12 }, .write);
    try transaction.defineAccumulatorResult(accumulator, result_name, .zeroExtendedRax(52));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

pub fn isExactCtlzI52Call(call: ir.CallInst) bool {
    if (!std.mem.eql(u8, call.callee, "llvm.ctlz.i52") or call.inline_asm != null or call.callee_value != null or
        call.callee_function_ty != null or call.calling_conv != null or call.raw_args != null or call.operand_bundle != null)
    {
        return false;
    }
    if (call.tail_kind) |tail_kind| if (!std.mem.eql(u8, tail_kind, "tail")) return false;
    if (call.attrs) |attrs| if (!isAttributeGroupReference(attrs)) return false;
    if (!intrinsic_attrs.matchesIntegerRange(call.ret_attrs, 52, 0, 53) or
        !call.ret_ty.eql(.{ .int = 52 }) or call.args.items.len != 2)
    {
        return false;
    }
    const value_arg = call.args.items[0];
    const zero_undef_arg = call.args.items[1];
    return value_arg.attrs == null and zero_undef_arg.attrs == null and
        value_arg.ty.eql(.{ .int = 52 }) and zero_undef_arg.ty.eql(.{ .int = 1 }) and
        zero_undef_arg.value.eql(.{ .int = 1 });
}

fn isAttributeGroupReference(attrs: []const u8) bool {
    const trimmed = std.mem.trim(u8, attrs, " \t");
    if (trimmed.len < 2 or trimmed[0] != '#') return false;
    for (trimmed[1..]) |c| if (!std.ascii.isDigit(c)) return false;
    return true;
}

pub fn lowerCttzI32(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-cttz-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-cttz-signature" };
    const value_arg = call.args.items[0];
    const undef_arg = call.args.items[1];
    const valid_zero_flag = undef_arg.value.eql(.{ .int = 0 }) or undef_arg.value.eql(.{ .int = 1 });
    if (!value_arg.ty.eql(.{ .int = 32 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !valid_zero_flag) {
        return .{ .no_emitter = "composed-block-cttz-args" };
    }
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr32 },
        .form = .gpr32,
        .destination = .{ .gpr32 = .rdi },
    }) catch return .{ .unsupported_value = "composed-block-cttz-value" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    const accumulator = try transaction.beginAccumulatorSession();
    transaction.prepare() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    transaction.materializeAll() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .ctz_i32_edi_eax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .zeroExtending(32));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

pub fn lowerCttzI64(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-missing-result" };
    if (call.inline_asm != null or call.callee_value != null or call.raw_args != null or call.operand_bundle != null) {
        return .{ .no_emitter = "composed-block-cttz-call-form" };
    }
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 2) return .{ .no_emitter = "composed-block-cttz-signature" };
    const value_arg = call.args.items[0];
    const undef_arg = call.args.items[1];
    const valid_zero_flag = undef_arg.value.eql(.{ .int = 0 }) or undef_arg.value.eql(.{ .int = 1 });
    if (!value_arg.ty.eql(.{ .int = 64 }) or !undef_arg.ty.eql(.{ .int = 1 }) or !valid_zero_flag) {
        return .{ .no_emitter = "composed-block-cttz-args" };
    }
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr64 },
        .form = .gpr64,
        .destination = .{ .gpr64 = .rdi },
    }) catch return .{ .unsupported_value = "composed-block-cttz-value" };
    transaction.seal() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    const accumulator = try transaction.beginAccumulatorSession();
    transaction.prepare() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    transaction.materializeAll() catch return .{ .unsupported_value = "composed-block-cttz-value" };
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .ctz_i64_rdi_eax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .fullRax());
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
    return null;
}

fn lowerCtpop(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, bits: u16) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-ctpop-result" };
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        !isDefaultOrFastcc(call.calling_conv) or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-block-ctpop-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-block-ctpop-tail-kind" };
        }
    }
    const upper: u128 = @as(u128, bits) + 1;
    if (!intrinsic_attrs.matchesIntegerRange(call.ret_attrs, bits, 0, upper)) {
        return .{ .no_emitter = "composed-block-ctpop-range" };
    }
    const ty: ir.Type = .{ .int = bits };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty) or call.args.items[0].attrs != null) {
        return .{ .no_emitter = "composed-block-ctpop-signature" };
    }

    if (bits == 64) {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.clobber, accumulatorInputDisplacement(selector, call.args.items[0].value, .spill_live))) |diagnostic| return diagnostic;
        transaction.materialize(call.args.items[0].value, .fullRax()) catch
            return .{ .unsupported_value = "composed-block-ctpop-value" };
        try selector_state.clobberArgReg(selector, .rcx);
        try selector_state.clobberArgReg(selector, .rdx);
        try selector_state.emitEflagsInstruction(selector, .popcount_rax, .clobber);
        try transaction.define(result_name, .fullRax());
        try transaction.commit();
        return null;
    }

    if (bits != 128) unreachable;
    const source = selector_state.ensurePairSpill(selector, call.args.items[0].value) catch
        return .{ .no_spill_envelope = "composed-block-ctpop-pair" };
    try selector_state.clobberArgReg(selector, pair_b.lo);
    try selector_state.clobberArgReg(selector, pair_b.hi);
    try selector_state.clobberArgReg(selector, .rcx);
    try selector_state.clobberArgReg(selector, .rdx);
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
    try selector.machine.instructions.append(selector.allocator, .popcount_rax);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair_b.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
    try selector.machine.instructions.append(selector.allocator, .popcount_rax);
    try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_rax = pair_b.lo }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair_b.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_r9 = 0 });
    try selector_state.bindPairScratch(selector, result_name, pair_b);
    return null;
}

const BitPermutation = enum {
    byte_swap,
    bit_reverse,
};

fn lowerBitPermutation(
    selector: *ComposedBlockSelector,
    result: ?[]const u8,
    call: ir.CallInst,
    bits: u16,
    operation: BitPermutation,
) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-bit-permutation-result" };
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        !isDefaultOrFastcc(call.calling_conv) or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-block-bit-permutation-call-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail")) return .{ .no_emitter = "composed-block-bit-permutation-tail-kind" };
    }
    const ty: ir.Type = .{ .int = bits };
    if (!call.ret_ty.eql(ty) or call.args.items.len != 1 or !call.args.items[0].ty.eql(ty)) {
        return .{ .no_emitter = "composed-block-bit-permutation-signature" };
    }

    if (operation == .byte_swap and (bits == 16 or bits == 32 or bits == 64)) {
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        const effect: selector_state.AccumulatorPreparationEffect = if (bits == 16) .clobber else .preserve;
        if (try transaction.prepare(effect, accumulatorInputDisplacement(selector, call.args.items[0].value, .spill_live))) |diagnostic| return diagnostic;
        const definition: selector_state.AccumulatorDefinition = if (bits == 64) .fullRax() else .zeroExtending(bits);
        transaction.materialize(call.args.items[0].value, definition) catch
            return .{ .unsupported_value = "composed-block-bit-permutation-value" };
        if (bits == 16) {
            try selector_state.emitEflagsInstruction(selector, .{ .rol_ax_imm8 = 8 }, .write);
            try selector_state.emitEflagsInstruction(selector, .{ .and_eax_imm32 = 65535 }, .write);
        } else try selector_state.emitEflagsInstruction(selector, if (bits == 32) .bswap_eax else .bswap_rax, .preserve);
        try transaction.define(result_name, definition);
        try transaction.commit();
        return null;
    }

    if (operation == .bit_reverse and (bits == 32 or bits == 64))
        try selector_state.preserveFixedPermutationOperand(selector, call.args.items[0].value, bits);

    if (bits == 32) {
        if (operation != .bit_reverse) unreachable;
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.clobber, accumulatorInputDisplacement(selector, call.args.items[0].value, .spill_live))) |diagnostic| return diagnostic;
        try selector_state.clobberArgReg(selector, .rdi);
        try selector_state.clobberArgReg(selector, .rcx);
        try selector_state.clobberArgReg(selector, .rdx);
        transaction.materialize(call.args.items[0].value, .fullRax()) catch
            return .{ .unsupported_value = "composed-block-bit-permutation-value" };
        try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdi });
        try selector_state.emitEflagsInstruction(selector, .bit_reverse_i32_edi_eax, .clobber);
        try transaction.define(result_name, .zeroExtending(32));
        try transaction.commit();
        return null;
    }

    if (bits == 64) {
        if (operation != .bit_reverse) unreachable;
        var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
        defer transaction.deinit();
        if (try transaction.prepare(.clobber, accumulatorInputDisplacement(selector, call.args.items[0].value, .spill_live))) |diagnostic| return diagnostic;
        try selector_state.clobberArgReg(selector, .rcx);
        try selector_state.clobberArgReg(selector, .rdx);
        transaction.materialize(call.args.items[0].value, .fullRax()) catch
            return .{ .unsupported_value = "composed-block-bit-permutation-value" };
        try selector_state.emitEflagsInstruction(selector, .bit_reverse_rax, .clobber);
        try transaction.define(result_name, .fullRax());
        try transaction.commit();
        return null;
    }

    if (bits != 128) unreachable;
    const source = selector_state.ensurePairSpill(selector, call.args.items[0].value) catch
        return .{ .no_spill_envelope = "composed-block-bit-permutation-pair" };
    try selector_state.clobberArgReg(selector, pair_b.lo);
    try selector_state.clobberArgReg(selector, pair_b.hi);
    if (operation == .bit_reverse) {
        try selector_state.clobberArgReg(selector, .rcx);
        try selector_state.clobberArgReg(selector, .rdx);
    }
    try selector_state.clobberAccumulator(selector);
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.hi });
    try selector.machine.instructions.append(selector.allocator, switch (operation) {
        .byte_swap => .bswap_rax,
        .bit_reverse => .bit_reverse_rax,
    });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair_b.lo });
    try selector.machine.instructions.append(selector.allocator, .{ .reload_rsp_rax = source.lo });
    try selector.machine.instructions.append(selector.allocator, switch (operation) {
        .byte_swap => .bswap_rax,
        .bit_reverse => .bit_reverse_rax,
    });
    try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = pair_b.hi });
    try selector_state.bindPairScratch(selector, result_name, pair_b);
    return null;
}

fn lowerI128Compare(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst, signed: bool) !?Diagnostic {
    const result_name = result orelse return .{ .unsupported_value = "composed-block-i128-compare-result" };
    if (call.inline_asm != null or call.callee_value != null or call.callee_function_ty != null or
        call.calling_conv != null or call.ret_attrs != null or call.raw_args != null or call.operand_bundle != null)
    {
        return .{ .no_emitter = "composed-block-i128-compare-form" };
    }
    if (call.tail_kind) |tail_kind| {
        if (!std.mem.eql(u8, tail_kind, "tail") and !std.mem.eql(u8, tail_kind, "notail")) {
            return .{ .no_emitter = "composed-block-i128-compare-tail-kind" };
        }
    }
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2 or
        !call.args.items[0].ty.eql(.{ .int = 128 }) or !call.args.items[1].ty.eql(.{ .int = 128 }))
    {
        return .{ .no_emitter = "composed-block-i128-compare-signature" };
    }

    const lhs = selector_state.resolvePairValue(selector, call.args.items[0].value) orelse
        return .{ .unsupported_value = "composed-block-i128-compare-lhs" };
    const rhs = selector_state.resolvePairValue(selector, call.args.items[1].value) orelse
        return .{ .unsupported_value = "composed-block-i128-compare-rhs" };
    if (!lhs.eql(.{ .lo = .rdi, .hi = .rsi }) or !rhs.eql(.{ .lo = .rdx, .hi = .rcx })) {
        return .{ .no_emitter = "composed-block-i128-compare-location" };
    }

    const high_diff = try selector_state.allocateEdgeLabel(selector);
    const low_diff = try selector_state.allocateEdgeLabel(selector);
    const done = try selector_state.allocateEaxJoinLabel(selector);
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.preserve, .spill_live)) |diagnostic| return diagnostic;

    try selector_state.emitEflagsInstruction(selector, .{ .cmp_rcx_arg64 = .rsi }, .definition);
    const high_flags = selector.eflags.snapshot();
    try selector_state.emitEflagsInstruction(selector, .{ .jne = high_diff }, .use);
    try selector_state.emitEflagsInstruction(selector, .cmp_rdx_rdi, .definition);
    const low_flags = selector.eflags.snapshot();
    try selector_state.emitEflagsInstruction(selector, .{ .jne = low_diff }, .use);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_imm_eax = 0 });
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = done });
    try selector.machine.instructions.append(selector.allocator, .{ .label = high_diff });
    selector.eflags.restore(high_flags);
    try selector_state.emitEflagsInstruction(selector, if (signed) .setg_eax else .seta_eax, .use);
    try selector_state.emitEflagsInstruction(selector, .{ .shl_eax_imm5 = 1 }, .write);
    try selector_state.emitEflagsInstruction(selector, .{ .add_eax_imm32 = -1 }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .jmp = done });
    try selector.machine.instructions.append(selector.allocator, .{ .label = low_diff });
    selector.eflags.restore(low_flags);
    try selector_state.emitEflagsInstruction(selector, .setb_eax, .use);
    try selector_state.emitEflagsInstruction(selector, .{ .shl_eax_imm5 = 1 }, .write);
    try selector_state.emitEflagsInstruction(selector, .{ .add_eax_imm32 = -1 }, .write);
    try selector.machine.instructions.append(selector.allocator, .{ .label = done });
    try transaction.define(result_name, .zeroExtending(32));
    try transaction.commit();
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
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.clobber, accumulatorInputDisplacement(selector, value_arg.value, .spill_live))) |diagnostic| return diagnostic;
    transaction.materialize(value_arg.value, .zeroExtending(16)) catch return .{ .unsupported_value = "composed-block-ctlz-value" };
    try selector_state.emitEflagsInstruction(selector, .{ .and_eax_imm32 = 0xffff }, .write);
    try selector_state.clobberArgReg(selector, .rdi);
    try selector.machine.instructions.append(selector.allocator, .{ .mov_eax_to_arg = .rdi });
    try selector_state.emitEflagsInstruction(selector, .clz_i32_edi_eax, .clobber);
    try selector_state.emitEflagsInstruction(selector, .{ .add_eax_imm32 = -16 }, .write);
    try transaction.define(result_name, .zeroExtending(16));
    try transaction.commit();
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
    var transaction = try selector_state.AccumulatorDefinitionTransaction.begin(selector);
    defer transaction.deinit();
    if (try transaction.prepare(.clobber, accumulatorInputDisplacement(selector, call.args.items[0].value, .spill_live))) |diagnostic| return diagnostic;
    transaction.materialize(call.args.items[0].value, .zeroExtending(32)) catch return .{ .unsupported_value = "composed-block-fshl-lhs" };
    selector_state.emitValueIntoScratch(selector, call.args.items[1].value, .rcx, 32) catch return .{ .unsupported_value = "composed-block-fshl-rhs" };
    try selector_state.emitEflagsInstruction(selector, .{ .fshl_eax_arg32_imm5 = .{ .reg = .rcx, .amount = amount } }, .write);
    try transaction.define(result_name, .zeroExtending(32));
    try transaction.commit();
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

fn lowerBooleanCall(selector: *ComposedBlockSelector, result: ?[]const u8, call: ir.CallInst) !?Diagnostic {
    if (call.args.items.len > 6) return .{ .unsupported_value = "composed-block-boolean-call-arg-count" };
    for (call.args.items) |arg| {
        try sysv_abi.rejectUnsupportedCallArgAttrs(arg);
        if (arg.ty != .ptr and !arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 }))
            return .{ .no_emitter = "composed-block-boolean-call-arg-type" };
        if (arg.value != .named or std.mem.startsWith(u8, arg.value.named, "@"))
            return .{ .unsupported_value = "composed-block-boolean-call-arg-value" };
    }
    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    var arguments: [6]ValueUseTransaction.RequestHandle = undefined;
    var argument_types: [6]ir.Type = undefined;
    for (call.args.items, 0..) |arg, index| {
        arguments[index] = try transaction.register(.{
            .source = arg.value,
            .expected = .{
                .ty = arg.ty,
                .register_class = if (arg.ty == .ptr) .stack_object else if (arg.ty.int == 32) .gpr32 else .gpr64,
                .pointer_address_space = if (arg.ty == .ptr) 0 else null,
            },
            .form = if (arg.ty == .ptr) .stack_object_address else if (arg.ty.int == 32) .gpr32 else .gpr64,
            .destination = .prepared_source,
        });
        argument_types[index] = arg.ty;
    }
    try transaction.attachCallAction(.{ .direct_call = try ValueUseTransaction.DirectCallAction.init(
        call.callee,
        result,
        call.ret_ty,
        arguments[0..call.args.items.len],
        argument_types[0..call.args.items.len],
    ) });
    try transaction.seal();
    try transaction.prepare();
    transaction.materializeAll() catch |err| {
        if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
        for (arguments[0..call.args.items.len]) |argument|
            if (transaction.failedRequestIs(argument))
                return .{ .unsupported_value = "composed-block-boolean-call-arg-value" };
        return err;
    };
    try transaction.commit();
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

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    const argument = try transaction.register(.{
        .source = arg.value,
        .expected = .{ .ty = arg.ty, .register_class = .gpr32 },
        .form = .gpr32,
        .destination = .prepared_source,
    });
    try transaction.attachCallAction(.{ .int_byte_size_call = try ValueUseTransaction.IntByteSizeCallAction.init(
        call.callee,
        result_name,
        argument,
    ) });
    try transaction.seal();
    try transaction.prepare();
    transaction.materializeAll() catch |err| {
        if (err == error.ValueUseActionDiagnostic) return transaction.actionDiagnostic();
        if (transaction.failedRequestIs(argument))
            return .{ .unsupported_value = "composed-block-intbytesize-arg-value" };
        return err;
    };
    try transaction.commit();
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

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = try transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr32 },
        .form = .gpr32,
        .destination = .{ .gpr32 = .rdi },
    });
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .abs_i32_edi_eax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .zeroExtending(32));
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
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

    var transaction = try ValueUseTransaction.begin(selector);
    defer transaction.deinit();
    _ = try transaction.register(.{
        .source = value_arg.value,
        .expected = .{ .ty = value_arg.ty, .register_class = .gpr64 },
        .form = .gpr64,
        .destination = .{ .gpr64 = .rdi },
    });
    try transaction.seal();
    const accumulator = try transaction.beginAccumulatorSession();
    try transaction.prepare();
    try transaction.materializeAll();
    if (try transaction.prepareAccumulator(accumulator, .clobber, .spill_live)) |diagnostic| return diagnostic;
    try selector_state.emitEflagsInstruction(selector, .abs_i64_rdi_rax, .clobber);
    try transaction.defineAccumulatorResult(accumulator, result_name, .fullRax());
    try transaction.finalizeAccumulatorResult(accumulator);
    try transaction.commit();
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

fn ordinaryGlobalArgument(selector: *ComposedBlockSelector, value: ir.Value) ?[]const u8 {
    if (value != .named or !std.mem.startsWith(u8, value.named, "@")) return null;
    const context = selector.module_context orelse return null;
    const global = context.findGlobal(value.named) orelse return null;
    if (global.address_attrs) |attrs| {
        if (std.mem.indexOf(u8, attrs, "thread_local") != null or
            std.mem.indexOf(u8, attrs, "addrspace") != null) return null;
    }
    return global.name;
}

pub fn lowerDirectCallArg(selector: *ComposedBlockSelector, arg: ir.CallArg, target: ArgReg) !?Diagnostic {
    if (arg.ty == .ptr) {
        if (ordinaryGlobalArgument(selector, arg.value)) |symbol| {
            try sysv_abi.rejectUnsupportedCallArgAttrs(arg);
            try selector_state.clobberArgReg(selector, target);
            try selector.machine.instructions.append(selector.allocator, .{ .lea_global_arg64 = .{ .reg = target, .symbol = symbol } });
            return null;
        }
        if (arg.value == .null_value) {
            try sysv_abi.rejectUnsupportedCallArgAttrs(arg);
            try selector_state.emitZeroArg64(selector, target);
            return null;
        }
        const loc = selector_state.resolveValue(selector, arg.value) orelse return .{ .unsupported_value = "composed-block-call-unknown-ptr-arg" };
        switch (loc) {
            .stack_scalar => |stack| {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
                if (stack.base_disp != 0) {
                    const addend: i32 = std.math.cast(i32, stack.base_disp) orelse return .{ .no_spill_envelope = "composed-block-call-stack-disp" };
                    try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } }, .write);
                }
                return null;
            },
            .stack128 => |disp| {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rsp_arg64 = target });
                if (disp != 0) {
                    const addend: i32 = std.math.cast(i32, disp) orelse return .{ .no_spill_envelope = "composed-block-call-stack-disp" };
                    try selector_state.emitEflagsInstruction(selector, .{ .add_arg64_imm32 = .{ .reg = target, .imm = addend } }, .write);
                }
                return null;
            },
            .arg64, .scratch64 => |reg| {
                if (reg != target) {
                    try selector_state.clobberArgReg(selector, target);
                    try selector.machine.instructions.append(selector.allocator, .{ .mov_arg64_arg = .{ .dst = target, .src = reg } });
                }
                return null;
            },
            .rax => {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .mov_rax_to_arg = target });
                return null;
            },
            .spill64 => |frame_index| {
                try selector_state.clobberArgReg(selector, target);
                try selector.machine.instructions.append(selector.allocator, .{ .reload_arg64_rsp = .{ .reg = target, .frame_index = frame_index } });
                return null;
            },
            .arg32, .arg128, .eax, .scratch32, .scratch128, .xmm, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-call-ptr-arg" },
        }
    }

    const bits = intBits(arg.ty) orelse return .{ .no_emitter = "composed-block-call-arg-type" };
    if (bits != 32 and bits != 64 and bits != 128) return .{ .no_emitter = "composed-block-call-arg-width" };
    if (arg.value == .int and bits != 128) {
        const immediate: i64 = if (bits == 32) try composed_helpers.i32BitPattern(arg.value.int) else try i64Value(arg.value.int);
        try selector_state.clobberArgReg(selector, target);
        try selector.machine.instructions.append(selector.allocator, switch (target) {
            .rdi => .{ .mov_imm_rdi = immediate },
            .rsi => .{ .mov_imm_rsi = immediate },
            .rdx => .{ .mov_imm_rdx = immediate },
            .rcx => .{ .mov_imm_rcx = immediate },
            .r8 => .{ .mov_imm_r8 = immediate },
            .r9 => .{ .mov_imm_r9 = immediate },
        });
        return null;
    }
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
            .arg32, .arg64, .eax, .rax, .scratch32, .scratch64, .xmm, .stack_scalar, .stack128, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill64, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-call-arg-loc" },
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
        .arg128, .scratch128, .xmm, .stack_scalar, .stack128, .stack128_value, .stack_i32_array, .stack_i32_ptr, .stack_f32_pair_ptr, .readonly_table_ptr, .spill128, .spill_fp, .spill_vector, .aggregate_sse => return .{ .no_emitter = "composed-block-call-arg-loc" },
    }
    return null;
}
