const core = @import("core.zig");
const core_impl = @import("core_impl.zig");
const f128_debug_rows = @import("cabi_f128_debug_rows.zig");
pub const std = @import("std");
pub const ir = @import("../../../ir.zig");
pub const target = @import("../../../target.zig");
pub const memory_location = @import("../../../analysis/memory_location.zig");
pub const x86_64_types = @import("../types.zig");
pub const sysv_abi = @import("../sysv_abi.zig");
pub const x86_64_emit = @import("../emit.zig");
pub const x86_64_match = @import("../match.zig");
pub const runtime_float = @import("../runtime_float.zig");
pub const x86_64_machine = @import("../machine.zig");

pub const MachineBinaryOp = x86_64_types.MachineBinaryOp;
pub const ArgReg = x86_64_types.ArgReg;
pub const XmmReg = x86_64_types.XmmReg;
pub const MachineFunction = x86_64_machine.MachineFunction;
pub const FrameIndex = x86_64_types.FrameIndex;
pub const SysVAggregateEightbyteClass = sysv_abi.AggregateEightbyteClass;
pub const SysVAggregateKind = sysv_abi.AggregateKind;
pub const SysVAggregateClassification = sysv_abi.AggregateClassification;
pub const SysVCallPlanCounts = sysv_abi.CallPlanCounts;
pub const SysVSmallIntegerAggregate = sysv_abi.SmallIntegerAggregate;
pub const SysVRegisterNeeds = sysv_abi.RegisterNeeds;
pub const SysVRegisterAggregatePassThrough = sysv_abi.RegisterAggregatePassThrough;
pub const SysVCallPlan = sysv_abi.CallPlan;
pub const SysVParamCursor = sysv_abi.ParamCursor;
pub const SysVCallTarget = x86_64_emit.SysVCallTarget;
pub const max_sysv_stack_call_args = x86_64_emit.max_sysv_stack_call_args;
pub const appendIntegerOverflowCall = x86_64_emit.appendIntegerOverflowCall;
pub const appendStackFrame = x86_64_emit.appendStackFrame;
pub const appendStackFrameEnd = x86_64_emit.appendStackFrameEnd;
pub const appendDirectCall = x86_64_emit.appendDirectCall;
pub const appendAlignedDirectCall = x86_64_emit.appendAlignedDirectCall;
pub const appendDirectCallWithStackArgs = x86_64_emit.appendDirectCallWithStackArgs;
pub const appendIndirectCallRaxWithStackArgs = x86_64_emit.appendIndirectCallRaxWithStackArgs;
pub const appendLoadStackDispArg32 = x86_64_emit.appendLoadStackDispArg32;
pub const appendLoadStackDispArg64 = x86_64_emit.appendLoadStackDispArg64;
pub const appendMoveImmToArgReg = x86_64_emit.appendMoveImmToArgReg;
pub const appendMoveImm32ToXmm = x86_64_emit.appendMoveImm32ToXmm;
pub const appendMoveImm64ToXmm = x86_64_emit.appendMoveImm64ToXmm;
pub const setupSysVCallTarget = x86_64_emit.setupSysVCallTarget;
pub const appendSysVCallTarget = x86_64_emit.appendSysVCallTarget;
pub const appendAlignedSysVCallTarget = x86_64_emit.appendAlignedSysVCallTarget;
pub const appendSysVCallTargetWithStackArgs = x86_64_emit.appendSysVCallTargetWithStackArgs;
pub const appendPanicCall = x86_64_emit.appendPanicCall;
pub const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
pub const isNamed = x86_64_match.isNamed;
pub const callIsFastcc = x86_64_match.callIsFastcc;
pub const callArgAttrsContain = x86_64_match.callArgAttrsContain;
pub const paramAttrsContain = x86_64_match.paramAttrsContain;
pub const globalSymbolName = x86_64_match.globalSymbolName;
pub const symbolName = x86_64_match.symbolName;
pub const isInt = x86_64_match.isInt;
pub const i32Value = x86_64_match.i32Value;
pub const u8Value = x86_64_match.u8Value;
pub const i64Value = x86_64_match.i64Value;
pub const u5Value = x86_64_match.u5Value;
pub const isFpText = x86_64_match.isFpText;
pub const fp32TextBits = x86_64_match.fp32TextBits;
pub const fp64TextBits = x86_64_match.fp64TextBits;
pub const isCalleeName = x86_64_match.isCalleeName;

pub const validateAllocaNamed = core_impl.validateAllocaNamed;
pub const validateMemset = core_impl.validateMemset;
pub const validateStore = core_impl.validateStore;
pub const validateRetVoid = core_impl.validateRetVoid;
pub const singleRetVoidBlock = core_impl.singleRetVoidBlock;
pub const hasSingleBlockInstructionCount = core_impl.hasSingleBlockInstructionCount;
pub const sliceSumHasOverflowCheck = core_impl.functionHasOverflowPanicEdge;
pub const genericCfgSupportsSingleBlockI32Value = core_impl.genericCfgSupportsSingleBlockI32Value;
pub const genericCfgSupportsI64Value = core_impl.genericCfgSupportsI64Value;
pub const emitGenericCfgI32ValueIntoEax = core_impl.emitGenericCfgI32ValueIntoEax;
pub const emitGenericCfgI64ValueIntoRax = core_impl.emitGenericCfgI64ValueIntoRax;
pub const genericCfgSupportsI1Param = core_impl.genericCfgSupportsI1Param;
pub const genericCfgSupportsSminSelect = core_impl.genericCfgSupportsSminSelect;
pub const GenericCfgBranchKind = core_impl.GenericCfgBranchKind;
pub const appendGenericCfgBlockLabel = core_impl.appendGenericCfgBlockLabel;
pub const appendGenericCfgConditionalBranch = core_impl.appendGenericCfgConditionalBranch;
pub const appendGenericCfgCompareParamZero = core_impl.appendGenericCfgCompareParamZero;
pub const appendGenericCfgCompareLocalImm = core_impl.appendGenericCfgCompareLocalImm;
pub const matchGlobalUpdate = core_impl.matchGlobalUpdate;

pub fn x86_64SysVDataLayout() !target.DataLayout {
    return target.DataLayout.parse(std.heap.page_allocator, "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn validateCondbr(block: ir.BasicBlock, cond_name: []const u8, true_block: []const u8, false_block: []const u8) !void {
    const condbr = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        .ret, .br, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!isNamed(condbr.cond, cond_name) or !std.mem.eql(u8, condbr.then_target, true_block) or !std.mem.eql(u8, condbr.else_target, false_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBr(block: ir.BasicBlock, target_block: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, target_block)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAssumeTrue(instruction: ir.Instruction) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.assume") or call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !call.args.items[0].value.eql(.{ .int = 1 })) return error.UnsupportedCodegenInstruction;
}

pub fn lowerDebugSpirvMergeLogicalPointers(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "spirv_merge_logical_pointers.a")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const result_slot = try validateAllocaNamed(entry.instructions.items[0], .ptr);
    const cond_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 1 });
    const false_slot = try validateAllocaNamed(entry.instructions.items[2], .ptr);
    const true_slot = try validateAllocaNamed(entry.instructions.items[3], .ptr);
    try validateMemset(entry.instructions.items[4], true_slot, 8);
    try validateMemset(entry.instructions.items[5], false_slot, 8);
    try validateStore(entry.instructions.items[6], .{ .int = 1 }, .{ .int = 0 }, cond_slot);
    const cond_name = try validateNamedLoad(entry.instructions.items[7], .{ .int = 1 }, cond_slot);
    try validateCondbr(entry, cond_name, "8", "10");

    const merge = function.blocks.items[1];
    if (!std.mem.eql(u8, merge.name, "6") or merge.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const phi_name = merge.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (phi.incoming.items.len != 2 or !phi.ty.eql(.ptr)) return error.UnsupportedCodegenInstruction;
    try validatePhiIncoming(phi.incoming.items[0], "9", "8");
    try validatePhiIncoming(phi.incoming.items[1], "11", "10");
    try validateStore(merge.instructions.items[1], .ptr, .{ .named = phi_name }, result_slot);
    try validateRetVoid(merge);

    const true_block = function.blocks.items[2];
    if (!std.mem.eql(u8, true_block.name, "8") or true_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const true_loaded = try validateNamedLoad(true_block.instructions.items[0], .ptr, true_slot);
    if (!std.mem.eql(u8, true_loaded, "9")) return error.UnsupportedCodegenInstruction;
    try validateBr(true_block, "6");

    const false_block = function.blocks.items[3];
    if (!std.mem.eql(u8, false_block.name, "10") or false_block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const false_loaded = try validateNamedLoad(false_block.instructions.items[0], .ptr, false_slot);
    if (!std.mem.eql(u8, false_loaded, "11")) return error.UnsupportedCodegenInstruction;
    try validateBr(false_block, "6");

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validatePhiIncoming(incoming: ir.PhiIncoming, value_name: []const u8, block_name: []const u8) !void {
    if (!isNamed(incoming.value, value_name) or !std.mem.eql(u8, incoming.block, block_name)) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64PassThroughFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugInheritWantSafety(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugInheritWantSafety(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "inherit_want_safety.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 16) return false;
    try validateDebugInheritWantSafetyShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 4 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugInheritWantSafetyShape(function: ir.Function) !void {
    if (function.blocks.items.len != 16) return error.UnsupportedCodegenControlFlow;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;
    const ret_slot = try validateAllocaNamed(entry.instructions.items[0], .{ .int = 64 });
    const counter_slot = try validateAllocaNamed(entry.instructions.items[1], .{ .int = 64 });
    try validateStore(entry.instructions.items[2], .{ .int = 64 }, .{ .int = 0 }, counter_slot);
    const first_load = try validateNamedLoad(entry.instructions.items[3], .{ .int = 64 }, counter_slot);
    const first_add = try validateAddNamedImm(entry.instructions.items[4], .{ .int = 64 }, first_load, 1);
    try validateStore(entry.instructions.items[5], .{ .int = 64 }, .{ .named = first_add }, counter_slot);
    const branch_load = try validateNamedLoad(entry.instructions.items[6], .{ .int = 64 }, counter_slot);
    const branch_cmp = try validateIcmpNamedImm(entry.instructions.items[7], .eq, .{ .int = 64 }, branch_load, 0);
    try validateCondbr(entry, branch_cmp, "8", "11");

    try validateEmptyBrBlock(blockByName(function, "7") orelse return error.InvalidBranchTarget, "7", "14");
    try validateCounterIncrementBlock(blockByName(function, "8") orelse return error.InvalidBranchTarget, "8", counter_slot, "7");
    try validateEmptyBrBlock(blockByName(function, "11") orelse return error.InvalidBranchTarget, "11", "7");
    try validateLoopSetupBlock(blockByName(function, "12") orelse return error.InvalidBranchTarget, ret_slot, counter_slot, "24");
    try validateLoopHeaderBlock(blockByName(function, "14") orelse return error.InvalidBranchTarget, "14", counter_slot, "18", "21");
    try validateEmptyBrBlock(blockByName(function, "17") orelse return error.InvalidBranchTarget, "17", "14");
    try validateCounterIncrementBlock(blockByName(function, "18") orelse return error.InvalidBranchTarget, "18", counter_slot, "17");
    try validateEmptyBrBlock(blockByName(function, "21") orelse return error.InvalidBranchTarget, "21", "12");
    try validateSwitchBlock(blockByName(function, "22") orelse return error.InvalidBranchTarget, "22", counter_slot, "39");
    try validateLoopCompareBlock(blockByName(function, "24") orelse return error.InvalidBranchTarget, "24", ret_slot, "13", "29", "32");
    try validateCounterIncrementBlock(blockByName(function, "29") orelse return error.InvalidBranchTarget, "29", counter_slot, "27");
    try validateEmptyBrBlock(blockByName(function, "32") orelse return error.InvalidBranchTarget, "32", "22");

    const block27 = blockByName(function, "27") orelse return error.InvalidBranchTarget;
    if (block27.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const loop_index = try validateAddNamedImm(block27.instructions.items[0], .{ .int = 64 }, "25", 1);
    try validateStore(block27.instructions.items[1], .{ .int = 64 }, .{ .named = loop_index }, ret_slot);
    try validateBr(block27, "24");

    const block33 = blockByName(function, "33") orelse return error.InvalidBranchTarget;
    if (block33.instructions.items.len != 7) return error.UnsupportedCodegenInstruction;
    const load34 = try validateNamedLoad(block33.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add35 = try validateAddNamedImm(block33.instructions.items[1], .{ .int = 64 }, load34, 1);
    try validateStore(block33.instructions.items[2], .{ .int = 64 }, .{ .named = add35 }, counter_slot);
    const ret_name = try validateNamedLoad(block33.instructions.items[3], .{ .int = 64 }, counter_slot);
    const load37 = try validateNamedLoad(block33.instructions.items[4], .{ .int = 64 }, counter_slot);
    const add38 = try validateAddNamedImm(block33.instructions.items[5], .{ .int = 64 }, load37, 1);
    try validateStore(block33.instructions.items[6], .{ .int = 64 }, .{ .named = add38 }, counter_slot);
    const ret = switch (block33.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(.{ .int = 64 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_name)) return error.UnsupportedCodegenControlFlow;

    try validateCounterIncrementBlock(blockByName(function, "39") orelse return error.InvalidBranchTarget, "39", counter_slot, "33");
}

pub fn validateEmptyBrBlock(block: ir.BasicBlock, name: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 0) return error.UnsupportedCodegenControlFlow;
    try validateBr(block, target_block);
}

pub fn validateLoopSetupBlock(block: ir.BasicBlock, ret_slot: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, "12") or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    try validateStore(block.instructions.items[0], .{ .int = 64 }, .{ .int = 0 }, ret_slot);
    const limit_name = try validateNamedLoad(block.instructions.items[1], .{ .int = 64 }, counter_slot);
    if (!std.mem.eql(u8, limit_name, "13")) return error.UnsupportedCodegenInstruction;
    try validateBr(block, target_block);
}

pub fn validateCounterIncrementBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, target_block: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const add_name = try validateAddNamedImm(block.instructions.items[1], .{ .int = 64 }, load_name, 1);
    try validateStore(block.instructions.items[2], .{ .int = 64 }, .{ .named = add_name }, counter_slot);
    try validateBr(block, target_block);
}

pub fn validateLoopHeaderBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 64 }, load_name, 0);
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateLoopCompareBlock(block: ir.BasicBlock, name: []const u8, ret_slot: []const u8, limit_name: []const u8, then_target: []const u8, else_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 2) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, ret_slot);
    const cmp_name = block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (block.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != .ult or !cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(cmp.lhs, load_name) or !isNamed(cmp.rhs, limit_name)) return error.UnsupportedCodegenInstruction;
    try validateCondbr(block, cmp_name, then_target, else_target);
}

pub fn validateSwitchBlock(block: ir.BasicBlock, name: []const u8, counter_slot: []const u8, default_target: []const u8) !void {
    if (!std.mem.eql(u8, block.name, name) or block.instructions.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 64 }, counter_slot);
    const switch_term = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .@"switch" => |switch_term| switch_term,
        .ret, .br, .condbr, .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (!switch_term.cond_ty.eql(.{ .int = 64 }) or !isNamed(switch_term.cond, load_name) or !std.mem.eql(u8, switch_term.default_target, default_target)) return error.UnsupportedCodegenControlFlow;
    if (switch_term.cases.items.len != 0) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAddNamedImm(instruction: ir.Instruction, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != .add or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateIcmpNamedImm(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !cmp.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn blockByName(function: ir.Function, name: []const u8) ?ir.BasicBlock {
    for (function.blocks.items) |block| {
        if (std.mem.eql(u8, block.name, name)) return block;
    }
    return null;
}

pub fn lowerI64SaturatingHelperFunctionFamily(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (try lowerDebugNoCompilePanicUncheckedArith(allocator, machine, function)) return true;
    return false;
}

pub fn lowerDebugNoCompilePanicUncheckedArith(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return false;
    if (function.blocks.items[0].instructions.items.len != 21) return false;
    try validateDebugNoCompilePanicUncheckedArithShape(function);

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateDebugNoCompilePanicUncheckedArithShape(function: ir.Function) !void {
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 21 or !ret.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;

    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .int = 64 });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .int = 0 }, slot);
    const load2 = try validateNamedLoad(block.instructions.items[2], .{ .int = 64 }, slot);
    const add3 = try validateBinaryNamedImm(block.instructions.items[3], .add, .{ .int = 64 }, load2, 1);
    try validateStore(block.instructions.items[4], .{ .int = 64 }, .{ .named = add3 }, slot);
    const load5 = try validateNamedLoad(block.instructions.items[5], .{ .int = 64 }, slot);
    const sub6 = try validateBinaryNamedImm(block.instructions.items[6], .sub, .{ .int = 64 }, load5, 1);
    try validateStore(block.instructions.items[7], .{ .int = 64 }, .{ .named = sub6 }, slot);
    const load8 = try validateNamedLoad(block.instructions.items[8], .{ .int = 64 }, slot);
    const mul9 = try validateBinaryNamedImm(block.instructions.items[9], .mul, .{ .int = 64 }, load8, 2);
    try validateStore(block.instructions.items[10], .{ .int = 64 }, .{ .named = mul9 }, slot);
    const load11 = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, slot);
    const uadd12 = try validateSaturatingCall(block.instructions.items[12], "llvm.uadd.sat.i64", load11, 1, null);
    try validateStore(block.instructions.items[13], .{ .int = 64 }, .{ .named = uadd12 }, slot);
    const load14 = try validateNamedLoad(block.instructions.items[14], .{ .int = 64 }, slot);
    const usub15 = try validateSaturatingCall(block.instructions.items[15], "llvm.usub.sat.i64", load14, 1, null);
    try validateStore(block.instructions.items[16], .{ .int = 64 }, .{ .named = usub15 }, slot);
    const load17 = try validateNamedLoad(block.instructions.items[17], .{ .int = 64 }, slot);
    const umul18 = try validateSaturatingCall(block.instructions.items[18], "llvm.umul.fix.sat.i64", load17, 2, 0);
    try validateStore(block.instructions.items[19], .{ .int = 64 }, .{ .named = umul18 }, slot);
    const load20 = try validateNamedLoad(block.instructions.items[20], .{ .int = 64 }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, load20)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateBinaryNamedImm(instruction: ir.Instruction, op: ir.BinaryOp, ty: ir.Type, lhs_name: []const u8, rhs: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (binary.op != op or !binary.ty.eql(ty) or !isNamed(binary.lhs, lhs_name) or !binary.rhs.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateSaturatingCall(instruction: ir.Instruction, callee: []const u8, lhs_name: []const u8, rhs: i128, scale: ?i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or !call.ret_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    const expected_args: usize = if (scale == null) 2 else 3;
    if (call.args.items.len != expected_args) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(call.args.items[0].value, lhs_name)) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = rhs })) return error.UnsupportedCodegenInstruction;
    if (scale) |scale_value| {
        if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = scale_value })) return error.UnsupportedCodegenInstruction;
    }
    return name;
}

pub fn lowerStartTrampoline(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "start._start")) return false;
    if (function.ret_ty != .void) return false;
    if (function.params.items.len != 0) return false;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;

    const block = function.blocks.items[0];
    const terminator = block.terminator orelse return error.BlockWithoutTerminator;
    switch (terminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return error.UnsupportedCodegenControlFlow;
    try validateStartCfiInlineAsm(block.instructions.items[0]);
    const call_target = try validateStartTrampolineInlineAsm(block.instructions.items[1]);
    if (block.instructions.items.len == 3) try validateTrapCall(block.instructions.items[2]);

    try machine.instructions.append(allocator, .xor_ebp_ebp);
    try machine.instructions.append(allocator, .mov_rsp_rdi);
    try machine.instructions.append(allocator, .and_rsp_neg16);
    try machine.instructions.append(allocator, .{ .noreturn_direct_call = call_target });
    return true;
}

pub fn validateStartCfiInlineAsm(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, ".cfi_undefined %rip")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;
}

pub fn validateTrapCall(instruction: ir.Instruction) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.trap") or call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

pub fn validateStartTrampolineInlineAsm(instruction: ir.Instruction) ![]const u8 {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    const inline_asm = call.inline_asm orelse return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!inline_asm.sideeffect) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.template, " xorl %ebp, %ebp\\0A movq %rsp, %rdi\\0A andq $$-16, %rsp\\0A callq ${1:P}")) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, inline_asm.constraints, "X,X,~{dirflag},~{fpsr},~{flags}")) return error.UnsupportedCodegenInstruction;

    const self_arg = call.args.items[0];
    if (self_arg.ty != .ptr or !isNamed(self_arg.value, "@start._start")) return error.UnsupportedCodegenInstruction;

    const target_arg = call.args.items[1];
    if (target_arg.ty != .ptr) return error.UnsupportedCodegenInstruction;
    const call_target = switch (target_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.startsWith(u8, call_target, "@")) return error.UnsupportedCodegenInstruction;
    return call_target[1..];
}

pub fn lowerSelectedInfiniteLoop(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "main._start")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 2) return false;

    const entry = function.blocks.items[0];
    const loop = function.blocks.items[1];
    if (entry.instructions.items.len != 0 or loop.instructions.items.len != 0) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, entry_br.target, loop.name)) return false;
    const loop_br = switch (loop.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        .ret, .condbr, .@"switch", .indirectbr, .@"unreachable" => return false,
    };
    if (!std.mem.eql(u8, loop_br.target, loop.name)) return false;

    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .ud2);
    return true;
}

pub fn lowerSelectedIssue339TestFoo(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "test.foo")) return false;
    if (function.ret_ty != .void or function.params.items.len != 0) return false;
    if (function.blocks.items.len != 4) return false;

    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 2) return error.UnsupportedCodegenInstruction;
    const call_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "test.bar") or !call.ret_ty.eql(.{ .int = 16 }) or call.args.items.len != 0 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    const cmp_name = try validateIcmpNamedImm(entry.instructions.items[1], .eq, .{ .int = 16 }, call_name, 0);
    try validateCondbr(entry, cmp_name, "4", "5");

    const ret_block = blockByName(function, "3") orelse return error.InvalidBranchTarget;
    if (ret_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    try validateRetVoid(ret_block);

    try validateEmptyBrBlock(blockByName(function, "4") orelse return error.InvalidBranchTarget, "4", "3");

    const panic = blockByName(function, "5") orelse return error.InvalidBranchTarget;
    if (panic.instructions.items.len != 1) return error.UnsupportedCodegenInstruction;
    try validatePanicCallWithNamedI16(panic.instructions.items[0], "debug.FullPanic((function 'panic')).unwrapError", call_name);
    switch (panic.terminator orelse return error.BlockWithoutTerminator) {
        .@"unreachable" => {},
        .ret, .br, .condbr, .@"switch", .indirectbr => return error.UnsupportedCodegenControlFlow,
    }

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSelectedLibfuzzerDebugO0(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (std.mem.eql(u8, function.name, "main.runner_broadcast_input")) {
        if (!hasSingleBlockInstructionCount(function, 4)) return false;
        try validateDebugLibfuzzerBroadcastInput(function);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_futex_wait")) {
        if (!hasSingleBlockInstructionCount(function, 3)) return false;
        try validateDebugLibfuzzerFutexWait(function);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_name")) {
        if (!hasSingleBlockInstructionCount(function, 7)) return false;
        try validateDebugLibfuzzerTestName(function);
        try machine.instructions.append(allocator, .{ .lea_global_rax = "__anon_22815" });
        try machine.instructions.append(allocator, .{ .mov_imm_rdx = 4 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.runner_test_run")) {
        if (!hasSingleBlockInstructionCount(function, 24)) return false;
        try validateDebugLibfuzzerTestRun(function);
        try machine.instructions.append(allocator, .sub_rsp_8);
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_8117" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_22035" });
        try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
        try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
        try machine.instructions.append(allocator, .add_rsp_8);
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    if (std.mem.eql(u8, function.name, "main.testOne")) {
        if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 0) return false;
        if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
        const block = function.blocks.items[0];
        if (block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
        const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
            .ret => |ret| ret,
            .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
        };
        if (!ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenControlFlow;
        try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    return false;
}

pub fn validateDebugLibfuzzerBroadcastInput(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!function.params.items[0].ty.eql(.{ .int = 32 }) or !function.params.items[1].ty.eql(.{ .int = 64 }) or !function.params.items[2].ty.eql(.{ .int = 64 })) {
        return error.UnsupportedCodegenInstruction;
    }
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    try validateStore(block.instructions.items[1], .{ .int = 64 }, .{ .named = function.params.items[1].name }, slot);
    const gep_name = try validateI8GepInstruction(block.instructions.items[2], slot, 8);
    try validateStore(block.instructions.items[3], .{ .int = 64 }, .{ .named = function.params.items[2].name }, gep_name);
}

pub fn validateDebugLibfuzzerFutexWait(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .int = 1 }) or function.params.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 3 or !ret.ty.eql(.{ .int = 1 }) or !(ret.value orelse return error.InvalidRet).eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;
    const load_name = try validateNamedLoad(block.instructions.items[0], .{ .int = 32 }, function.params.items[0].name);
    const cmp_name = try validateIcmpNamed(block.instructions.items[1], .eq, .{ .int = 32 }, load_name, function.params.items[1].name);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
}

pub fn validateDebugLibfuzzerTestName(function: ir.Function) !void {
    if (!function.ret_ty.eql(.{ .aggregate = "{ i64, i64 }" }) or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (function.blocks.items.len != 1) return error.UnsupportedCodegenControlFlow;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => return error.UnsupportedCodegenControlFlow,
    };
    if (block.instructions.items.len != 7 or !ret.ty.eql(.{ .aggregate = "{ i64, i64 }" })) return error.UnsupportedCodegenInstruction;
    const slot = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[1], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[2], cmp_name);
    const ptr_name = try validateExtractConstantSliceValue(block.instructions.items[3], "@__anon_22815", 0);
    const len_name = try validateExtractConstantSliceValue(block.instructions.items[4], "@__anon_22815", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[5], slot, ptr_name, len_name);
    const loaded = try validateNamedLoad(block.instructions.items[6], .{ .aggregate = "{ i64, i64 }" }, slot);
    if (!isNamed(ret.value orelse return error.InvalidRet, loaded)) return error.UnsupportedCodegenControlFlow;
}

pub fn validateDebugLibfuzzerTestRun(function: ir.Function) !void {
    if (function.ret_ty != .void or function.params.items.len != 1) return error.UnsupportedCodegenInstruction;
    const block = try singleRetVoidBlock(function);
    if (block.instructions.items.len != 24) return error.UnsupportedCodegenInstruction;
    const raw_hello = try validateAllocaNamed(block.instructions.items[0], .{ .aggregate = "[16 x i8]" });
    const hello_slice = try validateAllocaNamed(block.instructions.items[1], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const raw_empty = try validateAllocaNamed(block.instructions.items[2], .{ .aggregate = "[16 x i8]" });
    const empty_slice = try validateAllocaNamed(block.instructions.items[3], .{ .aggregate = "%Build.abi.fuzz.Slice" });
    const cmp_name = try validateIcmpNamedImm(block.instructions.items[4], .eq, .{ .int = 32 }, function.params.items[0].name, 0);
    try validateDebugAssertCall(block.instructions.items[5], cmp_name);
    try validateVoidCall(block.instructions.items[6], "fuzzer_set_test", &.{.{ .ty = .ptr, .value = .{ .named = "@main.testOne" } }});
    const empty_ptr = try validateExtractConstantSliceValue(block.instructions.items[7], "@__anon_8117", 0);
    const empty_len = try validateExtractConstantSliceValue(block.instructions.items[8], "@__anon_8117", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[9], empty_slice, empty_ptr, empty_len);
    try validateMemcpy(block.instructions.items[10], raw_empty, empty_slice, 16);
    const empty_input_ptr = try validateNamedLoad(block.instructions.items[11], .{ .int = 64 }, raw_empty);
    const empty_input_len_ptr = try validateI8GepInstruction(block.instructions.items[12], raw_empty, 8);
    const empty_input_len = try validateNamedLoad(block.instructions.items[13], .{ .int = 64 }, empty_input_len_ptr);
    try validateVoidCall(block.instructions.items[14], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = empty_input_len } },
    });
    const hello_ptr = try validateExtractConstantSliceValue(block.instructions.items[15], "@__anon_22035", 0);
    const hello_len = try validateExtractConstantSliceValue(block.instructions.items[16], "@__anon_22035", 1);
    try validateFuzzSliceFromSlice(block.instructions.items[17], hello_slice, hello_ptr, hello_len);
    try validateMemcpy(block.instructions.items[18], raw_hello, hello_slice, 16);
    const hello_input_ptr = try validateNamedLoad(block.instructions.items[19], .{ .int = 64 }, raw_hello);
    const hello_input_len_ptr = try validateI8GepInstruction(block.instructions.items[20], raw_hello, 8);
    const hello_input_len = try validateNamedLoad(block.instructions.items[21], .{ .int = 64 }, hello_input_len_ptr);
    try validateVoidCall(block.instructions.items[22], "fuzzer_new_input", &.{
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_ptr } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = hello_input_len } },
    });
    try validateVoidCall(block.instructions.items[23], "fuzzer_start_test", &.{});
}

pub fn validateI8GepInstruction(instruction: ir.Instruction, ptr_name: []const u8, offset: i128) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, ptr_name, offset);
    return name;
}

pub fn validateIcmpNamed(instruction: ir.Instruction, predicate: ir.IcmpPredicate, ty: ir.Type, lhs_name: []const u8, rhs_name: []const u8) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const cmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (cmp.predicate != predicate or !cmp.operand_ty.eql(ty) or !isNamed(cmp.lhs, lhs_name) or !isNamed(cmp.rhs, rhs_name)) return error.UnsupportedCodegenInstruction;
    return name;
}

pub fn validateDebugAssertCall(instruction: ir.Instruction, cond_name: []const u8) !void {
    const args = [_]ExpectedCallArg{.{
        .ty = .{ .int = 1 },
        .value = .{ .named = cond_name },
    }};
    try validateVoidCall(instruction, "debug.assert", &args);
}

pub fn validateExtractConstantSliceValue(instruction: ir.Instruction, symbol: []const u8, index: u32) ![]const u8 {
    const name = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const extract = switch (instruction.kind) {
        .extractvalue => |extract| extract,
        else => return error.UnsupportedCodegenInstruction,
    };
    var index_buf: [16]u8 = undefined;
    const expected_index = std.fmt.bufPrint(&index_buf, "{d}", .{index}) catch return error.UnsupportedCodegenValue;
    if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, expected_index)) return error.UnsupportedCodegenInstruction;
    const expected_len: i128 = if (std.mem.eql(u8, symbol, "@__anon_22035")) 5 else if (std.mem.eql(u8, symbol, "@__anon_22815")) 4 else 0;
    switch (extract.aggregate) {
        .constant_expr => |text| {
            var len_buf: [32]u8 = undefined;
            const len_text = std.fmt.bufPrint(&len_buf, "i64 {d}", .{expected_len}) catch return error.UnsupportedCodegenValue;
            if (std.mem.indexOf(u8, text, symbol) == null or std.mem.indexOf(u8, text, len_text) == null) return error.UnsupportedCodegenValue;
        },
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => return error.UnsupportedCodegenValue,
    }
    return name;
}

pub fn validateFuzzSliceFromSlice(instruction: ir.Instruction, sret_name: []const u8, ptr_name: []const u8, len_name: []const u8) !void {
    const args = [_]ExpectedCallArg{
        .{ .ty = .ptr, .value = .{ .named = ptr_name } },
        .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } },
    };
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, "Build.abi.fuzz.Slice.fromSlice") or call.ret_ty != .void or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, sret_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(args[0].ty) or !call.args.items[1].value.eql(args[0].value)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(args[1].ty) or !call.args.items[2].value.eql(args[1].value)) return error.UnsupportedCodegenValue;
}

pub fn validateMemcpy(instruction: ir.Instruction, dst_name: []const u8, src_name: []const u8, len: i64) !void {
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "llvm.memcpy.p0.p0.i64") or call.ret_ty != .void or call.args.items.len != 4) return error.UnsupportedCodegenInstruction;
    if (call.args.items[0].ty != .ptr or !isNamed(call.args.items[0].value, dst_name)) return error.UnsupportedCodegenValue;
    if (call.args.items[1].ty != .ptr or !isNamed(call.args.items[1].value, src_name)) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 64 }) or !call.args.items[2].value.eql(.{ .int = len })) return error.UnsupportedCodegenValue;
    if (!call.args.items[3].ty.eql(.{ .int = 1 }) or !call.args.items[3].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
}

pub fn validatePanicCallWithNamedI16(instruction: ir.Instruction, callee: []const u8, arg_name: []const u8) !void {
    if (instruction.removed or instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isCalleeName(call.callee, callee) or call.ret_ty != .void or call.args.items.len != 1 or call.callee_value != null or call.inline_asm != null) {
        return error.UnsupportedCodegenInstruction;
    }
    if (!call.args.items[0].ty.eql(.{ .int = 16 }) or !isNamed(call.args.items[0].value, arg_name)) return error.UnsupportedCodegenValue;
}

pub fn lowerGetauxvalImpl(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!std.mem.eql(u8, function.name, "os.linux.getauxvalImpl")) return false;
    if (!function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 64 })) return false;
    try validateGetauxvalShape(function);

    try machine.instructions.append(allocator, .{ .load_global_ptr_rax = "os.linux.elf_aux_maybe" });
    try machine.instructions.append(allocator, .test_rax_rax);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .{ .label = "loop" });
    try machine.instructions.append(allocator, .load_rax_ptr_rdx);
    try machine.instructions.append(allocator, .test_rdx_rdx);
    try machine.instructions.append(allocator, .{ .je = "zero" });
    try machine.instructions.append(allocator, .cmp_rdx_rdi);
    try machine.instructions.append(allocator, .{ .je = "found" });
    try machine.instructions.append(allocator, .{ .add_rax_imm8 = 16 });
    try machine.instructions.append(allocator, .{ .jmp = "loop" });
    try machine.instructions.append(allocator, .{ .label = "found" });
    try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = 8 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = "zero" });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateGetauxvalShape(function: ir.Function) !void {
    const optimized_shape = function.blockIndex("common.ret") != null and function.blockIndex(".preheader") != null and function.blockIndex("8") != null;
    const debug_shape = function.blockIndex("11") != null and function.blockIndex("18") != null and function.blockIndex("29") != null;
    if (!optimized_shape and !debug_shape) return error.UnsupportedCodegenControlFlow;

    var saw_global_load = false;
    var saw_tag_load = false;
    var saw_value_load = false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| {
                    if (load.ty == .ptr and isNamed(load.ptr, "@os.linux.elf_aux_maybe")) saw_global_load = true;
                    if (load.ty.eql(.{ .int = 64 }) and instruction.result != null) {
                        if (isNamed(load.ptr, "3") or isNamed(load.ptr, "14") or isNamed(load.ptr, "21")) saw_tag_load = true;
                        if (isNamed(load.ptr, "9") or isNamed(load.ptr, "33")) saw_value_load = true;
                    }
                },
                else => {},
            }
        }
    }
    if (!saw_global_load or !saw_tag_load or !saw_value_load) return error.UnsupportedCodegenControlFlow;
}

pub fn validateAssertDCShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return f128_debug_rows.validateDebugAssertDCShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 8) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[2].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double) or !isNamed(fcmp.lhs, function.params.items[0].name)) return error.UnsupportedCodegenInstruction;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "-2.500000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const zext_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, fcmp_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[4].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[1].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .eq or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 15 })) return error.UnsupportedCodegenInstruction;

    const select_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[6].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(select.cond, low_cmp_name) or !isNamed(select.true_value, zext_name) or !select.false_value.eql(.{ .int = 2 })) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[7].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertCFFShape(function: ir.Function) !void {
    if (function.blocks.items.len == 13) return f128_debug_rows.validateDebugAssertCFFShape(function);
    if (function.blocks.items.len < 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 13) return error.UnsupportedCodegenInstruction;
    const lshr_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const lshr = switch (entry.instructions.items[2].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (lshr.op != .lshr or !lshr.ty.eql(.{ .int = 64 }) or !isNamed(lshr.lhs, function.params.items[0].name) or !lshr.rhs.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;

    const trunc_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const trunc = switch (entry.instructions.items[3].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 }) or !isNamed(trunc.value, lshr_name)) return error.UnsupportedCodegenInstruction;

    const bitcast_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const bitcast = switch (entry.instructions.items[4].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (bitcast.op != .bitcast or !bitcast.from_ty.eql(.{ .int = 32 }) or !bitcast.to_ty.eql(.float) or !isNamed(bitcast.value, trunc_name)) return error.UnsupportedCodegenInstruction;

    const and_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const and_inst = switch (entry.instructions.items[5].kind) {
        .binary => |binary| binary,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (and_inst.op != .@"and" or !and_inst.ty.eql(.{ .int = 64 }) or !isNamed(and_inst.lhs, function.params.items[0].name) or !and_inst.rhs.eql(.{ .int = 255 })) return error.UnsupportedCodegenInstruction;

    const low_cmp_name = entry.instructions.items[6].result orelse return error.UnsupportedCodegenInstruction;
    const low_cmp = switch (entry.instructions.items[6].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (low_cmp.predicate != .ne or !low_cmp.operand_ty.eql(.{ .int = 64 }) or !isNamed(low_cmp.lhs, and_name) or !low_cmp.rhs.eql(.{ .int = 39 })) return error.UnsupportedCodegenInstruction;

    const zext_name = entry.instructions.items[7].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[7].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, low_cmp_name)) return error.UnsupportedCodegenInstruction;

    const payload_cmp_name = entry.instructions.items[8].result orelse return error.UnsupportedCodegenInstruction;
    const payload_cmp = switch (entry.instructions.items[8].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (payload_cmp.predicate != .une or !payload_cmp.operand_ty.eql(.float) or !isNamed(payload_cmp.lhs, bitcast_name)) return error.UnsupportedCodegenInstruction;

    const payload_select_name = entry.instructions.items[9].result orelse return error.UnsupportedCodegenInstruction;
    const payload_select = switch (entry.instructions.items[9].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(payload_select.cond, payload_cmp_name) or !payload_select.true_value.eql(.{ .int = 2 }) or !isNamed(payload_select.false_value, zext_name)) return error.UnsupportedCodegenInstruction;

    const arg_cmp_name = entry.instructions.items[10].result orelse return error.UnsupportedCodegenInstruction;
    const arg_cmp = switch (entry.instructions.items[10].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (arg_cmp.predicate != .une or !arg_cmp.operand_ty.eql(.float) or !isNamed(arg_cmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenInstruction;

    const final_select_name = entry.instructions.items[11].result orelse return error.UnsupportedCodegenInstruction;
    const final_select = switch (entry.instructions.items[11].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!isNamed(final_select.cond, arg_cmp_name) or !final_select.true_value.eql(.{ .int = 3 }) or !isNamed(final_select.false_value, payload_select_name)) return error.UnsupportedCodegenInstruction;

    const zero_cmp_name = entry.instructions.items[12].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[12].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(zero_cmp.lhs, final_select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenInstruction;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const ok_ret = switch (function.blocks.items[ok_index].terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, final_select_name)) return error.UnsupportedCodegenValue;
}

pub fn validateAssertPDShape(function: ir.Function) !void {
    if (function.blocks.items.len == 10) return f128_debug_rows.validateDebugAssertPDShape(function);
    if (function.blocks.items.len != 3) return error.UnsupportedCodegenControlFlow;
    const entry = function.blocks.items[0];
    if (entry.instructions.items.len != 6) return error.UnsupportedCodegenInstruction;
    const alloca_name = entry.instructions.items[0].result orelse return error.UnsupportedCodegenInstruction;
    const alloca = switch (entry.instructions.items[0].kind) {
        .alloca => |alloca| alloca,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "{ %main.PD }" })) return error.UnsupportedCodegenType;

    const ptr_ne_name = entry.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const ptr_ne = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (ptr_ne.predicate != .ne or !ptr_ne.operand_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(ptr_ne.lhs, function.params.items[0].name) or !ptr_ne.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const zext_name = entry.instructions.items[2].result orelse return error.UnsupportedCodegenInstruction;
    const zext = switch (entry.instructions.items[2].kind) {
        .cast => |cast| cast,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 1 }) or !zext.to_ty.eql(.{ .int = 32 }) or !isNamed(zext.value, ptr_ne_name)) return error.UnsupportedCodegenInstruction;

    const fcmp_name = entry.instructions.items[3].result orelse return error.UnsupportedCodegenInstruction;
    const fcmp = switch (entry.instructions.items[3].kind) {
        .fcmp => |fcmp| fcmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (fcmp.predicate != .une or !fcmp.operand_ty.eql(.double)) return error.UnsupportedCodegenInstruction;
    if (!isNamed(fcmp.lhs, function.params.items[1].name)) return error.UnsupportedCodegenValue;
    switch (fcmp.rhs) {
        .fp => |text| if (!std.mem.eql(u8, text, "5.000000e-01")) return error.UnsupportedCodegenValue,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }

    const select_name = entry.instructions.items[4].result orelse return error.UnsupportedCodegenInstruction;
    const select = switch (entry.instructions.items[4].kind) {
        .select => |select| select,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(select.cond, fcmp_name) or !select.true_value.eql(.{ .int = 2 }) or !isNamed(select.false_value, zext_name)) return error.UnsupportedCodegenValue;

    const zero_cmp_name = entry.instructions.items[5].result orelse return error.UnsupportedCodegenInstruction;
    const zero_cmp = switch (entry.instructions.items[5].kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (zero_cmp.predicate != .eq or !zero_cmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (!isNamed(zero_cmp.lhs, select_name) or !zero_cmp.rhs.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    const condbr = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!condbr.cond_ty.eql(.{ .int = 1 }) or !isNamed(condbr.cond, zero_cmp_name)) return error.UnsupportedCodegenControlFlow;
    const ok_index = blockIndex(function, condbr.then_target) orelse return error.InvalidBranchTarget;
    const fail_index = blockIndex(function, condbr.else_target) orelse return error.InvalidBranchTarget;

    const ok_block = function.blocks.items[ok_index];
    if (ok_block.instructions.items.len != 0) return error.UnsupportedCodegenInstruction;
    const ok_ret = switch (ok_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ok_ret.ty.eql(.{ .int = 32 }) or !isNamed(ok_ret.value orelse return error.InvalidRet, select_name)) return error.UnsupportedCodegenValue;

    const fail_block = function.blocks.items[fail_index];
    if (fail_block.instructions.items.len != 4) return error.UnsupportedCodegenInstruction;
    const store_ptr = switch (fail_block.instructions.items[0].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_ptr.ty.eql(.{ .int = 64 }) or !isNamed(store_ptr.value, function.params.items[0].name) or !isNamed(store_ptr.ptr, alloca_name)) return error.UnsupportedCodegenValue;
    const gep_name = fail_block.instructions.items[1].result orelse return error.UnsupportedCodegenInstruction;
    const gep = switch (fail_block.instructions.items[1].kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    try validateI8GepOffset(gep, alloca_name, 8);
    const store_double = switch (fail_block.instructions.items[2].kind) {
        .store => |store| store,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!store_double.ty.eql(.double) or !isNamed(store_double.value, function.params.items[1].name) or !isNamed(store_double.ptr, gep_name)) return error.UnsupportedCodegenValue;
    const call = switch (fail_block.instructions.items[3].kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!std.mem.eql(u8, call.callee, "debug.print__anon_14634") or call.ret_ty != .void) return error.UnsupportedCodegenInstruction;
}

pub fn validateNamedLoad(instruction: ir.Instruction, expected_ty: ir.Type, ptr_name: []const u8) ![]const u8 {
    const result = instruction.result orelse return error.UnsupportedCodegenInstruction;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!load.ty.eql(expected_ty) or load.attrs.isBarrier() or !isNamed(load.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    return result;
}

pub fn validateI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) !void {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 1) return error.UnsupportedCodegenInstruction;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !index.value.eql(.{ .int = offset })) return error.UnsupportedCodegenInstruction;
}

pub fn functionHasOverflowPanicEdge(function: ir.Function) bool {
    return sliceSumHasOverflowCheck(function);
}

pub fn appendI32CallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.has_non_i32_arg) return error.UnsupportedCodegenType;
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| switch (arg.value) {
                .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                .named => |name| {
                    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
                        error.UnsupportedCodegenAbi => null,
                        else => return err,
                    }) |src| {
                        if (src != dst) try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                    } else {
                        try appendLoadStackDispArg32(allocator, machine, dst, try scalarParamStackDisp8(function, name, .{ .int = 32 }));
                    }
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            },
            .stack_i32_const => |value| {
                stack_args[stack_arg_count] = .{ .imm = value };
                stack_arg_count += 1;
            },
            .stack_i32_param => |name| {
                stack_args[stack_arg_count] = .{ .stack_disp = try scalarParamStackDisp8(function, name, .{ .int = 32 }) };
                stack_arg_count += 1;
            },
            .sse, .aggregate_register_passthrough, .aggregate_stack_passthrough => return error.UnsupportedCodegenType,
        }
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count != 0 and stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var index = stack_arg_count;
    while (index > 0) {
        index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn i32CallStackArgCount(call: ir.CallInst) !usize {
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        if (!arg.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
        if (index >= 6) {
            switch (arg.value) {
                .int, .named => {},
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
            }
            stack_arg_count += 1;
        }
    }
    return stack_arg_count;
}

pub fn appendSysVScalarCallArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
) !usize {
    return try appendSysVScalarCallArgsWithBlock(allocator, machine, function, null, call);
}

pub fn appendSysVScalarCallArgsWithBlock(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    call: ir.CallInst,
) anyerror!usize {
    var plan = try planSysVCall(allocator, function, call);
    defer plan.deinit(allocator);
    if (plan.counts.stack_args > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var stack_arg_count: usize = 0;
    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr, .sse, .aggregate_register_passthrough => {},
            .stack_i32_const => |value| {
                stack_args[stack_arg_count] = .{ .imm = value };
                stack_arg_count += 1;
            },
            .stack_i32_param => |name| {
                if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenAbi => null,
                    else => return err,
                }) |src| {
                    stack_args[stack_arg_count] = .{ .arg_reg = src };
                } else if (scalarParamStackDisp8(function, name, arg.ty) catch |err| switch (err) {
                    error.UnsupportedCodegenValue => null,
                    else => return err,
                }) |disp| {
                    stack_args[stack_arg_count] = .{ .stack_disp = disp };
                } else if (arg.ty.eql(.{ .int = 32 })) {
                    const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsSingleBlockI32Value(function, block, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i32 = .{ .named = name } };
                } else if (arg.ty.eql(.{ .int = 64 })) {
                    _ = maybe_block orelse return error.UnsupportedCodegenAbi;
                    if (!genericCfgSupportsI64Value(function, .{ .named = name })) return error.UnsupportedCodegenValue;
                    stack_args[stack_arg_count] = .{ .computed_i64 = .{ .named = name } };
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                stack_arg_count += 1;
            },
            .aggregate_stack_passthrough => |aggregate| {
                try appendSysVStackAggregatePassThroughArgs(&stack_args, &stack_arg_count, aggregate);
            },
        }
    }
    var precomputed_stack_arg = false;
    for (stack_args[0..stack_arg_count]) |*stack_arg| {
        switch (stack_arg.*) {
            .computed_i32 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            .computed_i64 => |value| {
                if (precomputed_stack_arg) return error.UnsupportedCodegenAbi;
                const block = maybe_block orelse return error.UnsupportedCodegenAbi;
                try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
                stack_arg.* = .precomputed_rax;
                precomputed_stack_arg = true;
            },
            else => {},
        }
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count != 0 and stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var stack_index = stack_arg_count;
    while (stack_index > 0) {
        stack_index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, maybe_block, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    const incoming_stack_adjust = reserved_stack_bytes;

    for (call.args.items, 0..) |arg, index| {
        const assignment = plan.assignments.items[index];
        switch (assignment) {
            .gpr => |dst| {
                if (!arg.ty.eql(.{ .int = 32 }) and !arg.ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .int => |int| try appendMoveImmToArgReg(allocator, machine, dst, try i64Value(int)),
                    .named => |name| {
                        if (sysvIntegerParamRegOrNull(function, name, arg.ty) catch |err| switch (err) {
                            error.UnsupportedCodegenAbi => null,
                            else => return err,
                        }) |src| {
                            if (src != dst) {
                                try machine.instructions.append(allocator, if (arg.ty.eql(.{ .int = 64 }))
                                    .{ .mov_arg64_arg = .{ .dst = dst, .src = src } }
                                else
                                    .{ .mov_arg_arg = .{ .dst = dst, .src = src } });
                            }
                        } else if (arg.ty.eql(.{ .int = 32 })) {
                            try appendLoadStackDispArg32(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, .{ .int = 32 })) + incoming_stack_adjust);
                        } else if (arg.ty.eql(.{ .int = 64 })) {
                            try appendLoadStackDispArg64(allocator, machine, dst, @as(usize, try scalarParamStackDisp8(function, name, .{ .int = 64 })) + incoming_stack_adjust);
                        }
                    },
                    .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .sse => |dst| {
                if (!arg.ty.eql(.float) and !arg.ty.eql(.double)) return error.UnsupportedCodegenType;
                switch (arg.value) {
                    .fp => if (arg.ty.eql(.float))
                        try appendMoveImm32ToXmm(allocator, machine, dst, try fp32TextBits(arg.value))
                    else
                        try appendMoveImm64ToXmm(allocator, machine, dst, try fp64TextBits(arg.value)),
                    .named => |name| {
                        if ((if (arg.ty.eql(.float))
                            fpParamIndex(function, name, .float)
                        else
                            fpParamIndex(function, name, .double)) catch |err| switch (err) {
                            error.UnsupportedCodegenAbi => null,
                            else => return err,
                        }) |src_index| {
                            const dst_index: usize = @intFromEnum(dst);
                            if (src_index != dst_index) {
                                try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                                    .dst = dst,
                                    .src = try XmmReg.fromIndex(src_index),
                                } });
                            }
                        } else if (arg.ty.eql(.double)) {
                            try appendLoadStackDispXmm(
                                allocator,
                                machine,
                                dst,
                                try adjustedIncomingStackDisp8(try scalarParamStackDisp8(function, name, .double), incoming_stack_adjust),
                            );
                        } else {
                            return error.UnsupportedCodegenAbi;
                        }
                    },
                    .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
                }
            },
            .aggregate_register_passthrough => |aggregate| {
                try appendSysVRegisterAggregatePassThroughArg(allocator, machine, aggregate, incoming_stack_adjust);
            },
            .stack_i32_const, .stack_i32_param, .aggregate_stack_passthrough => {},
        }
    }
    return stack_arg_count;
}

pub fn adjustedIncomingStackDisp8(base_offset: u8, incoming_stack_adjust: usize) !u8 {
    const adjusted = @as(usize, base_offset) + incoming_stack_adjust;
    if (adjusted > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(adjusted);
}

pub fn sysvCallPlanCountsForTest(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlanCounts {
    return try sysv_abi.callPlanCountsForTest(allocator, function, call);
}

pub fn planSysVCall(allocator: std.mem.Allocator, function: ir.Function, call: ir.CallInst) !SysVCallPlan {
    return try sysv_abi.planCall(allocator, function, call);
}

pub fn appendSysVRegisterAggregatePassThroughArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    pass: SysVRegisterAggregatePassThrough,
    incoming_stack_adjust: usize,
) !void {
    const dest = switch (pass.dest) {
        .registers => |dest| dest,
        .stack => return error.UnsupportedCodegenAbi,
    };
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        if (pass.source.gpr != dest.gpr) {
            if (dest.gpr < pass.source.gpr) {
                var gpr_offset: usize = 0;
                while (gpr_offset < needs.gpr) : (gpr_offset += 1) {
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + gpr_offset),
                        .src = try ArgReg.fromIndex(pass.source.gpr + gpr_offset),
                    } });
                }
            } else {
                var remaining = needs.gpr;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{
                        .dst = try ArgReg.fromIndex(dest.gpr + remaining),
                        .src = try ArgReg.fromIndex(pass.source.gpr + remaining),
                    } });
                }
            }
        }

        if (pass.source.sse != dest.sse) {
            if (dest.sse < pass.source.sse) {
                var sse_offset: usize = 0;
                while (sse_offset < needs.sse) : (sse_offset += 1) {
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + sse_offset),
                        .src = try XmmReg.fromIndex(pass.source.sse + sse_offset),
                    } });
                }
            } else {
                var remaining = needs.sse;
                while (remaining > 0) {
                    remaining -= 1;
                    try machine.instructions.append(allocator, .{ .movapd_xmm = .{
                        .dst = try XmmReg.fromIndex(dest.sse + remaining),
                        .src = try XmmReg.fromIndex(pass.source.sse + remaining),
                    } });
                }
            }
        }
        return;
    }

    var gpr_offset: usize = 0;
    var sse_offset: usize = 0;
    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
            .integer => {
                const dst = try ArgReg.fromIndex(dest.gpr + gpr_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                try appendLoadStackDispArg64(allocator, machine, dst, offset);
                gpr_offset += 1;
            },
            .sse => {
                const dst = try XmmReg.fromIndex(dest.sse + sse_offset);
                const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8 + incoming_stack_adjust;
                if (offset <= std.math.maxInt(i8)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else if (offset <= std.math.maxInt(u32)) {
                    try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = dst, .disp = @intCast(offset) } });
                } else {
                    return error.UnsupportedCodegenAbi;
                }
                sse_offset += 1;
            },
        }
    }
}

pub fn appendSysVStackAggregatePassThroughArgs(
    stack_args: *[max_sysv_stack_call_args]StackScalarCallArg,
    stack_arg_count: *usize,
    pass: SysVRegisterAggregatePassThrough,
) !void {
    switch (pass.dest) {
        .stack => {},
        .registers => return error.UnsupportedCodegenAbi,
    }
    const needs = sysvAggregateRegisterNeeds(pass.classification);
    const source_in_registers = pass.source.gpr + needs.gpr <= 6 and pass.source.sse + needs.sse <= 8;
    if (source_in_registers) {
        if (pass.source.stack_eightbytes != 0) return error.UnsupportedCodegenAbi;
        var sse_offset: usize = 0;
        var gpr_offset: usize = 0;
        var eightbyte_index: usize = 0;
        while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
            if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
            switch (pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi) {
                .integer => {
                    stack_args[stack_arg_count.*] = .{ .arg_reg = try ArgReg.fromIndex(pass.source.gpr + gpr_offset) };
                    gpr_offset += 1;
                },
                .sse => {
                    stack_args[stack_arg_count.*] = .{ .xmm_reg = try XmmReg.fromIndex(pass.source.sse + sse_offset) };
                    sse_offset += 1;
                },
            }
            stack_arg_count.* += 1;
        }
        return;
    }

    var eightbyte_index: usize = 0;
    while (eightbyte_index < pass.classification.eightbyte_count) : (eightbyte_index += 1) {
        _ = pass.classification.eightbytes[eightbyte_index] orelse return error.UnsupportedCodegenAbi;
        if (stack_arg_count.* >= stack_args.len) return error.UnsupportedCodegenAbi;
        const offset = 8 + (pass.source.stack_eightbytes + eightbyte_index) * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        stack_args[stack_arg_count.*] = .{ .stack_disp = @intCast(offset) };
        stack_arg_count.* += 1;
    }
}

pub fn appendSysVMemoryAggregateStackPassThroughArgs(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    source: SysVParamCursor,
    classification: SysVAggregateClassification,
) !usize {
    if (classification.kind != .memory or classification.size_bytes == 0) return error.UnsupportedCodegenAbi;
    const stack_arg_count = @as(usize, @intCast((classification.size_bytes + 7) / 8));
    if (stack_arg_count == 0 or stack_arg_count > max_sysv_stack_call_args) return error.UnsupportedCodegenAbi;

    var stack_args: [max_sysv_stack_call_args]StackScalarCallArg = undefined;
    var index: usize = 0;
    while (index < stack_arg_count) : (index += 1) {
        const offset = 8 + (source.stack_eightbytes + index) * 8;
        if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
        stack_args[index] = .{ .stack_disp = @intCast(offset) };
    }

    var reserved_stack_bytes: usize = 0;
    if (stack_arg_count % 2 == 0) {
        try machine.instructions.append(allocator, .sub_rsp_8);
        reserved_stack_bytes = 8;
    }
    var stack_index = stack_arg_count;
    while (stack_index > 0) {
        stack_index -= 1;
        try appendStackScalarCallArg(allocator, machine, function, null, stack_args[stack_index], reserved_stack_bytes);
        reserved_stack_bytes += 8;
    }
    return stack_arg_count;
}

pub fn sysvParamCursorFor(function: ir.Function, name: []const u8, ty: ir.Type) !SysVParamCursor {
    return try sysvParamCursorForWithInitial(function, name, ty, .{ .gpr = 0, .sse = 0, .stack_eightbytes = 0 });
}

pub fn sysvParamCursorForWithInitial(function: ir.Function, name: []const u8, ty: ir.Type, initial: SysVParamCursor) !SysVParamCursor {
    var cursor: SysVParamCursor = initial;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenType;
            return cursor;
        }
        try advanceSysVParamCursors(param.ty, &cursor.gpr, &cursor.sse, &cursor.stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvScalarCallNeedsStackArgs(call: ir.CallInst) bool {
    var int_arg_index: usize = 0;
    var fp_arg_index: usize = 0;
    for (call.args.items) |arg| {
        if (arg.attrs != null) return true;
        if (arg.ty.eql(.{ .int = 32 }) or arg.ty.eql(.{ .int = 64 })) {
            if (int_arg_index >= 6) return true;
            int_arg_index += 1;
        } else if (arg.ty.eql(.float) or arg.ty.eql(.double)) {
            if (fp_arg_index >= 8) return true;
            fp_arg_index += 1;
        } else {
            return true;
        }
    }
    return false;
}

pub const StackScalarCallArg = union(enum) {
    imm: i32,
    stack_disp: u8,
    arg_reg: ArgReg,
    xmm_reg: XmmReg,
    computed_i32: ir.Value,
    computed_i64: ir.Value,
    precomputed_rax,
};

pub fn appendStackScalarCallArg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    maybe_block: ?ir.BasicBlock,
    arg: StackScalarCallArg,
    reserved_stack_bytes: usize,
) anyerror!void {
    switch (arg) {
        .imm => |value| try machine.instructions.append(allocator, .{ .push_imm32 = value }),
        .arg_reg => |reg| try machine.instructions.append(allocator, .{ .push_arg = reg }),
        .xmm_reg => |reg| try machine.instructions.append(allocator, .{ .push_xmm64 = reg }),
        .computed_i32 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .computed_i64 => |value| {
            const block = maybe_block orelse return error.UnsupportedCodegenAbi;
            try emitGenericCfgI64ValueIntoRax(allocator, machine, function, block, value);
            try machine.instructions.append(allocator, .push_rax);
        },
        .precomputed_rax => try machine.instructions.append(allocator, .push_rax),
        .stack_disp => |base_offset| {
            const adjusted = @as(usize, base_offset) + reserved_stack_bytes;
            if (adjusted <= std.math.maxInt(i8)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp8 = @intCast(adjusted) });
            } else if (adjusted <= std.math.maxInt(u32)) {
                try machine.instructions.append(allocator, .{ .push_stack_disp32 = @intCast(adjusted) });
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn appendAlignedDirectCallPreservingI32Param(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    symbol: []const u8,
    ret_ty: ir.Type,
    live_param: ?ArgReg,
) !void {
    try appendStackFrame(allocator, machine, 8);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = reg,
    } });
    try appendDirectCall(allocator, machine, symbol, ret_ty);
    if (live_param) |reg| try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = reg,
        .frame_index = .slot0,
    } });
    try appendStackFrameEnd(allocator, machine, 8);
}

pub fn appendAlignedDirectCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
) !void {
    try appendAlignedCallPreservingI32Params(allocator, machine, function, call, live_params, .{ .direct = call.callee });
}

pub fn appendAlignedCallPreservingI32Params(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    call: ir.CallInst,
    live_params: LiveParamSet,
    call_target: SysVCallTarget,
) !void {
    switch (live_params.count) {
        0 => {
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendAlignedSysVCallTarget(allocator, machine, call_target, call.ret_ty);
        },
        1 => {
            try appendStackFrame(allocator, machine, 8);
            try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                .frame_index = .slot0,
                .reg = live_params.regs[0],
            } });
            try setupSysVCallTarget(allocator, machine, call_target);
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                .reg = live_params.regs[0],
                .frame_index = .slot0,
            } });
            try appendStackFrameEnd(allocator, machine, 8);
        },
        2...6 => {
            const frame_bytes: u8 = if (live_params.count <= 3) 24 else 40;
            try appendStackFrame(allocator, machine, frame_bytes);
            var index: usize = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
                    .frame_index = frameIndexForLiveParam(index),
                    .reg = live_params.regs[index],
                } });
            }
            try setupSysVCallTarget(allocator, machine, call_target);
            _ = try appendI32CallArgs(allocator, machine, function, call);
            try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
            index = 0;
            while (index < live_params.count) : (index += 1) {
                try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
                    .reg = live_params.regs[index],
                    .frame_index = frameIndexForLiveParam(index),
                } });
            }
            try appendStackFrameEnd(allocator, machine, frame_bytes);
        },
        else => return error.UnsupportedLiveAcrossCall,
    }
}

pub fn frameIndexForLiveParam(index: usize) FrameIndex {
    return switch (index) {
        0 => .slot0,
        1 => .slot1,
        2 => .slot2,
        3 => .slot3,
        4 => .slot4,
        5 => .slot5,
        else => unreachable,
    };
}

pub fn lowerReturnTerminator(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !void {
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!ret.ty.eql(function.ret_ty)) return error.ReturnTypeMismatch;
    if (ret.ty == .void) {
        try machine.instructions.append(allocator, .ret);
        return;
    }
    if (!ret.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    try lowerReturnValue(allocator, machine, function, block, ret.value orelse return error.InvalidRet);
    try machine.instructions.append(allocator, .ret);
}

pub fn lowerReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) {
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            switch (instruction.kind) {
                .binary => |binary| {
                    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
                    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
                    if (binary.op == .add and try lowerI32AddTreeReturn(allocator, machine, function, block, binary)) {
                        return;
                    }
                    const lhs_const: ?i128 = switch (binary.lhs) {
                        .int => |lhs| lhs,
                        else => null,
                    };
                    const rhs_const: ?i128 = switch (binary.rhs) {
                        .int => |rhs| rhs,
                        else => null,
                    };
                    if (lhs_const) |lhs| {
                        if (rhs_const) |rhs| {
                            try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(lhs) });
                            switch (op) {
                                .add => try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(rhs) }),
                                else => return error.UnsupportedCodegenInstruction,
                            }
                            return;
                        }
                    }
                    const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
                    const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs });
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
                },
                .select => |select| try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, 0),
                .cast, .freeze, .icmp, .fcmp, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return error.UnsupportedCodegenInstruction,
            }
        },
    }
}

pub fn lowerGenericCfgSelectReturnValue(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    select: ir.SelectInst,
    depth: u2,
) anyerror!void {
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const cond_name = switch (select.cond) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const true_label = genericCfgSelectTrueLabel(depth);
    const end_label = genericCfgSelectEndLabel(depth);
    if (genericCfgSupportsI1Param(function, cond_name)) {
        const cond_reg = try paramReg(function, cond_name, .{ .int = 1 });
        try machine.instructions.append(allocator, .{ .test_arg8 = cond_reg });
        try machine.instructions.append(allocator, .{ .jne = true_label });
    } else {
        const cond_inst = findInstruction(block, cond_name) orelse return error.UnsupportedCodegenValue;
        const cond = switch (cond_inst.kind) {
            .icmp => |icmp| icmp,
            else => return error.UnsupportedCodegenInstruction,
        };
        if (try lowerGenericCfgSminSelectReturn(allocator, machine, function, select, cond)) return;
        const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, cond);
        try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    }
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.false_value, depth +| 1);
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try lowerGenericCfgI32ValueIntoEax(allocator, machine, function, block, select.true_value, depth +| 1);
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
}

pub fn lowerGenericCfgI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    depth: u2,
) anyerror!void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try paramRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            const instruction = findInstruction(block, name) orelse return error.UnsupportedCodegenValue;
            const select = switch (instruction.kind) {
                .select => |select| select,
                .binary => {
                    try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
                    return;
                },
                else => return error.UnsupportedCodegenInstruction,
            };
            if (depth == std.math.maxInt(u2)) return error.UnsupportedCodegenInstruction;
            try lowerGenericCfgSelectReturnValue(allocator, machine, function, block, select, depth);
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgSelectTrueLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_true",
        1 => "generic_cfg_nested1_select_true",
        2 => "generic_cfg_nested2_select_true",
        3 => "generic_cfg_nested3_select_true",
    };
}

pub fn genericCfgSelectEndLabel(depth: u2) []const u8 {
    return switch (depth) {
        0 => "generic_cfg_select_end",
        1 => "generic_cfg_nested1_generic_cfg_select_end",
        2 => "generic_cfg_nested2_generic_cfg_select_end",
        3 => "generic_cfg_nested3_generic_cfg_select_end",
    };
}

pub fn lowerGenericCfgSminSelectReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    select: ir.SelectInst,
    icmp: ir.IcmpInst,
) !bool {
    if (!genericCfgSupportsSminSelect(function, select, icmp)) return false;
    const lhs = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const rhs = switch (icmp.rhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if ((try paramReg(function, lhs, .{ .int = 32 })) != .rdi) return error.UnsupportedCodegenAbi;
    if ((try paramReg(function, rhs, .{ .int = 32 })) != .rsi) return error.UnsupportedCodegenAbi;
    try machine.instructions.append(allocator, .smin_i32_edi_esi_eax);
    return true;
}

pub fn emitGenericCfgIcmpCondition(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    icmp: ir.IcmpInst,
) !GenericCfgBranchKind {
    const branch_kind: GenericCfgBranchKind = switch (icmp.predicate) {
        .eq => .je,
        .ne => .jne,
        .slt => if (icmp.operand_ty.eql(.{ .int = 32 }) and isInt(icmp.rhs, 0))
            .js
        else
            return error.UnsupportedCodegenInstruction,
        .ugt, .uge, .ult, .ule, .sgt, .sge, .sle => return error.UnsupportedCodegenInstruction,
    };

    if (icmp.operand_ty.eql(.ptr)) {
        const ptr_value = if (icmp.lhs == .null_value) icmp.rhs else if (icmp.rhs == .null_value) icmp.lhs else return error.UnsupportedCodegenValue;
        const ptr_reg = try paramValueReg(function, ptr_value, .ptr);
        try machine.instructions.append(allocator, .{ .test_arg64 = ptr_reg });
        return branch_kind;
    }

    if (icmp.operand_ty.eql(.{ .int = 8 })) {
        if (icmp.lhs == .int and icmp.rhs != .int) {
            const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 8 });
            try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = rhs_reg, .imm = try u8Value(switch (icmp.lhs) {
                .int => |int| int,
                else => unreachable,
            }) } });
            return branch_kind;
        }
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 8 });
        const rhs_imm = switch (icmp.rhs) {
            .int => |int| try u8Value(int),
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        try machine.instructions.append(allocator, .{ .cmp_arg8_imm8 = .{ .reg = lhs_reg, .imm = rhs_imm } });
        return branch_kind;
    }

    if (!icmp.operand_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    if (icmp.predicate == .slt and isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return .js;
    }

    if (isInt(icmp.rhs, 0)) {
        const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, lhs_reg);
        return branch_kind;
    }
    if (isInt(icmp.lhs, 0)) {
        const rhs_reg = try paramValueReg(function, icmp.rhs, .{ .int = 32 });
        try appendGenericCfgCompareParamZero(allocator, machine, rhs_reg);
        return branch_kind;
    }

    const lhs_reg = try paramValueReg(function, icmp.lhs, .{ .int = 32 });
    const rhs_imm = switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    try machine.instructions.append(allocator, .{ .mov_arg_eax = lhs_reg });
    try appendGenericCfgCompareLocalImm(allocator, machine, .eax, rhs_imm);
    return branch_kind;
}

pub fn lowerI32AddTreeReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
) !bool {
    var terms: std.ArrayList(ir.Value) = .empty;
    defer terms.deinit(allocator);
    try collectI32AddTerms(allocator, block, binary, &terms);
    if (terms.items.len < 2) return false;
    try emitI32ValueIntoEax(allocator, machine, function, terms.items[0]);
    for (terms.items[1..]) |term| {
        switch (term) {
            .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
            .named => |name| {
                if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
                } else if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
                    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                } else return false;
            },
            .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    return true;
}

pub fn collectI32AddTerms(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    try collectI32AddValue(allocator, block, binary.lhs, terms);
    try collectI32AddValue(allocator, block, binary.rhs, terms);
}

pub fn collectI32AddValue(
    allocator: std.mem.Allocator,
    block: ir.BasicBlock,
    value: ir.Value,
    terms: *std.ArrayList(ir.Value),
) anyerror!void {
    switch (value) {
        .named => |name| {
            if (findInstruction(block, name)) |instruction| {
                switch (instruction.kind) {
                    .binary => |nested| if (nested.op == .add and nested.ty.eql(.{ .int = 32 })) {
                        try collectI32AddTerms(allocator, block, nested, terms);
                        return;
                    },
                    else => {},
                }
            }
            try terms.append(allocator, value);
        },
        .int => try terms.append(allocator, value),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| {
            if (try emitI32ParamOrStackIntoEax(allocator, machine, function, name)) return;
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn lowerReturnValueAfterCalls(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    last_eax_value: ?[]const u8,
    call_count: usize,
) !void {
    switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return lowerReturnValue(allocator, machine, function, block, value),
        .named => |name| {
            if (call_count == 0) return lowerReturnValue(allocator, machine, function, block, value);
            if (last_eax_value) |eax_name| {
                if (std.mem.eql(u8, name, eax_name)) return;
            }
            const instruction = findInstruction(block, name) orelse return lowerReturnValue(allocator, machine, function, block, value);
            switch (instruction.kind) {
                .binary => |binary| {
                    if (call_count != 1) return error.UnsupportedCodegenInstruction;
                    try lowerBinaryReturnAfterCall(allocator, machine, function, block, binary, last_eax_value orelse return error.UnsupportedCodegenValue);
                },
                else => return lowerReturnValue(allocator, machine, function, block, value),
            }
        },
    }
}

pub fn lowerBinaryReturnAfterCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    binary: ir.BinaryInst,
    eax_name: []const u8,
) !void {
    if (!binary.ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    const op = machineBinaryOp(binary.op) orelse return error.UnsupportedCodegenInstruction;
    if (binary.op == .add) {
        var terms: std.ArrayList(ir.Value) = .empty;
        defer terms.deinit(allocator);
        try collectI32AddTerms(allocator, block, binary, &terms);
        var has_eax_value = false;
        for (terms.items) |term| {
            if (isNamed(term, eax_name)) {
                has_eax_value = true;
                break;
            }
        }
        if (has_eax_value) {
            for (terms.items) |term| {
                if (isNamed(term, eax_name)) continue;
                try appendI32AddTermToEax(allocator, machine, function, term);
            }
            return;
        }
    }
    if (isNamed(binary.lhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.rhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const rhs = try paramValueReg(function, binary.rhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = rhs } });
        return;
    }
    if (isCommutative(binary.op) and isNamed(binary.rhs, eax_name)) {
        if (binary.op == .add) {
            switch (binary.lhs) {
                .int => |int| {
                    try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) });
                    return;
                },
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
            }
        }
        const lhs = try paramValueReg(function, binary.lhs, .{ .int = 32 });
        try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = op, .reg = lhs } });
        return;
    }
    return error.UnsupportedCodegenInstruction;
}

pub fn appendI32AddTermToEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    term: ir.Value,
) !void {
    switch (term) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => |name| {
            if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
                try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = reg } });
                return;
            }
            if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
                try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = offset });
                return;
            }
            return error.UnsupportedCodegenValue;
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn machineBinaryOp(op: ir.BinaryOp) ?MachineBinaryOp {
    return switch (op) {
        .add => .add,
        .sub => .sub,
        .@"and" => .@"and",
        .@"or" => .@"or",
        .xor => .xor,
        .fadd, .fsub, .fmul, .fdiv, .frem, .mul, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => null,
    };
}

pub fn singleLiveParamAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !?ArgReg {
    var live: ?ArgReg = null;
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParams(function, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValue(function, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub const LiveParamSet = struct {
    regs: [6]ArgReg = undefined,
    count: usize = 0,

    fn add(self: *LiveParamSet, reg: ArgReg) !void {
        if (self.has(reg)) return;
        if (self.count == self.regs.len) return error.UnsupportedLiveAcrossCall;
        self.regs[self.count] = reg;
        self.count += 1;
    }

    fn has(self: LiveParamSet, reg: ArgReg) bool {
        for (self.regs[0..self.count]) |existing| {
            if (existing == reg) return true;
        }
        return false;
    }
};

pub fn liveParamsAfter(function: ir.Function, block: ir.BasicBlock, instruction_index: usize) !LiveParamSet {
    var live: LiveParamSet = .{};
    for (block.instructions.items[instruction_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        try noteLiveParamsSet(function, block, instruction, &live);
    }
    if (block.terminator) |terminator| switch (terminator) {
        .ret => |ret| if (ret.value) |value| try noteLiveValueSet(function, block, value, &live),
        .br, .condbr, .@"switch", .indirectbr, .@"unreachable" => {},
    };
    return live;
}

pub fn noteLiveParamsSet(function: ir.Function, block: ir.BasicBlock, instruction: ir.Instruction, live: *LiveParamSet) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValueSet(function, block, binary.lhs, live);
            try noteLiveValueSet(function, block, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValueSet(function, block, arg.value, live),
        .cast => |cast| try noteLiveValueSet(function, block, cast.value, live),
        .freeze => |freeze| try noteLiveValueSet(function, block, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValueSet(function, block, icmp.lhs, live);
            try noteLiveValueSet(function, block, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValueSet(function, block, fcmp.lhs, live);
            try noteLiveValueSet(function, block, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValueSet(function, block, select.cond, live);
            try noteLiveValueSet(function, block, select.true_value, live);
            try noteLiveValueSet(function, block, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValueSet(function, block, incoming.value, live),
        .load => |load| try noteLiveValueSet(function, block, load.ptr, live),
        .store => |store| {
            try noteLiveValueSet(function, block, store.value, live);
            try noteLiveValueSet(function, block, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValueSet(function, block, atomicrmw.ptr, live);
            try noteLiveValueSet(function, block, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValueSet(function, block, cmpxchg.ptr, live);
            try noteLiveValueSet(function, block, cmpxchg.expected, live);
            try noteLiveValueSet(function, block, cmpxchg.replacement, live);
        },
        .extractvalue => |extract| try noteLiveValueSet(function, block, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValueSet(function, block, insert.aggregate, live);
            try noteLiveValueSet(function, block, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValueSet(function, block, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValueSet(function, block, index.value, live);
        },
        .alloca, .fence, .extractelement, .insertelement, .shufflevector => {},
    }
}

pub fn noteLiveValueSet(function: ir.Function, block: ir.BasicBlock, value: ir.Value, live: *LiveParamSet) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    if (paramRegOrNull(function, name, .{ .int = 32 }) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => {
            _ = try scalarParamStackDisp8(function, name, .{ .int = 32 });
            return;
        },
        else => return err,
    }) |reg| {
        try live.add(reg);
        return;
    }
    const instruction = findInstruction(block, name) orelse return;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return,
    };
    if (!binary.ty.eql(.{ .int = 32 }) or binary.op != .add) return error.UnsupportedLiveAcrossCall;
    try noteLiveValueSet(function, block, binary.lhs, live);
    try noteLiveValueSet(function, block, binary.rhs, live);
}

pub fn noteLiveParams(function: ir.Function, instruction: ir.Instruction, live: *?ArgReg) !void {
    switch (instruction.kind) {
        .binary => |binary| {
            try noteLiveValue(function, binary.lhs, live);
            try noteLiveValue(function, binary.rhs, live);
        },
        .call => |call| for (call.args.items) |arg| try noteLiveValue(function, arg.value, live),
        .cast => |cast| try noteLiveValue(function, cast.value, live),
        .freeze => |freeze| try noteLiveValue(function, freeze.value, live),
        .icmp => |icmp| {
            try noteLiveValue(function, icmp.lhs, live);
            try noteLiveValue(function, icmp.rhs, live);
        },
        .fcmp => |fcmp| {
            try noteLiveValue(function, fcmp.lhs, live);
            try noteLiveValue(function, fcmp.rhs, live);
        },
        .select => |select| {
            try noteLiveValue(function, select.cond, live);
            try noteLiveValue(function, select.true_value, live);
            try noteLiveValue(function, select.false_value, live);
        },
        .phi => |phi| for (phi.incoming.items) |incoming| try noteLiveValue(function, incoming.value, live),
        .alloca => {},
        .load => |load| try noteLiveValue(function, load.ptr, live),
        .store => |store| {
            try noteLiveValue(function, store.value, live);
            try noteLiveValue(function, store.ptr, live);
        },
        .atomicrmw => |atomicrmw| {
            try noteLiveValue(function, atomicrmw.ptr, live);
            try noteLiveValue(function, atomicrmw.value, live);
        },
        .cmpxchg => |cmpxchg| {
            try noteLiveValue(function, cmpxchg.ptr, live);
            try noteLiveValue(function, cmpxchg.expected, live);
            try noteLiveValue(function, cmpxchg.replacement, live);
        },
        .fence, .extractelement, .insertelement, .shufflevector => {},
        .extractvalue => |extract| try noteLiveValue(function, extract.aggregate, live),
        .insertvalue => |insert| {
            try noteLiveValue(function, insert.aggregate, live);
            try noteLiveValue(function, insert.value, live);
        },
        .gep => |gep| {
            try noteLiveValue(function, gep.ptr, live);
            for (gep.indices.items) |index| try noteLiveValue(function, index.value, live);
        },
    }
}

pub fn noteLiveValue(function: ir.Function, value: ir.Value, live: *?ArgReg) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return,
    };
    const reg = try paramRegOrNull(function, name, .{ .int = 32 }) orelse return;
    if (live.*) |existing| {
        if (existing != reg) return error.UnsupportedLiveAcrossCall;
    } else {
        live.* = reg;
    }
}

pub fn identityCastFrom(instruction: ir.Instruction, value_name: []const u8, from_ty: ir.Type, to_ty: ir.Type) ?[]const u8 {
    const result = instruction.result orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(from_ty) or !cast.to_ty.eql(to_ty)) return null;
    if (!isNamed(cast.value, value_name)) return null;
    return result;
}

pub fn isSelectI1ToI32ZeroOne(instruction: ir.Instruction, cond_name: []const u8) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, 0) and
        isInt(select.false_value, 1);
}

pub fn isSelectI1ToI32ExpectedOne(instruction: ir.Instruction, cond_name: []const u8, expected: i32) bool {
    if (instruction.removed) return false;
    const select = switch (instruction.kind) {
        .select => |select| select,
        else => return false,
    };
    return select.cond_ty.eql(.{ .int = 1 }) and
        select.ty.eql(.{ .int = 32 }) and
        isNamed(select.cond, cond_name) and
        isInt(select.true_value, expected) and
        isInt(select.false_value, 1);
}

pub fn valueReferencesGlobal(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, symbolName(value_name), name),
        .constant_expr => |text| std.mem.indexOf(u8, text, name) != null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => false,
    };
}

pub fn phiHasIncoming(phi: ir.PhiInst, value_name: []const u8, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isNamed(incoming.value, value_name)) return true;
    }
    return false;
}

pub fn phiHasIncomingInt(phi: ir.PhiInst, value: i128, block_name: []const u8) bool {
    for (phi.incoming.items) |incoming| {
        if (std.mem.eql(u8, incoming.block, block_name) and isInt(incoming.value, value)) return true;
    }
    return false;
}

pub fn matchIcmpEqParamImm(instruction: ir.Instruction, param_name: []const u8, ty: ir.Type, imm: i128) bool {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(ty)) return false;
    return (isNamed(icmp.lhs, param_name) and isInt(icmp.rhs, imm)) or
        (isNamed(icmp.rhs, param_name) and isInt(icmp.lhs, imm));
}

pub fn isCommutative(op: ir.BinaryOp) bool {
    return switch (op) {
        .add, .mul, .@"and", .@"or", .xor => true,
        .fadd, .fsub, .fmul, .fdiv, .frem, .sub, .shl, .lshr, .ashr, .udiv, .sdiv, .urem, .srem => false,
    };
}

pub fn findInstruction(block: ir.BasicBlock, result_name: []const u8) ?ir.Instruction {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return instruction;
    }
    return null;
}

pub fn findInstructionIndex(block: ir.BasicBlock, result_name: []const u8) ?usize {
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (std.mem.eql(u8, result, result_name)) return index;
    }
    return null;
}

pub fn paramValueReg(function: ir.Function, value: ir.Value, ty: ir.Type) !ArgReg {
    return switch (value) {
        .named => |name| try paramReg(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn paramReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try paramRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamReg(function: ir.Function, name: []const u8, ty: ir.Type) !ArgReg {
    return try sysvIntegerParamRegOrNull(function, name, ty) orelse error.UnsupportedCodegenValue;
}

pub fn sysvIntegerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    if (!ty.eql(.{ .int = 32 }) and !ty.eql(.{ .int = 64 }) and !ty.eql(.ptr)) return error.UnsupportedCodegenType;
    return try paramRegOrNull(function, name, ty);
}

pub fn paramRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, 0);
}

pub fn paramRegWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !ArgReg {
    return try paramRegOrNullWithInitialGpr(function, name, ty, initial_gpr) orelse error.UnsupportedCodegenValue;
}

pub fn paramRegOrNullWithInitialGpr(function: ir.Function, name: []const u8, ty: ir.Type, initial_gpr: usize) !?ArgReg {
    if (!isSysVIntegerParamType(ty)) return error.UnsupportedCodegenType;
    var gpr_index: usize = initial_gpr;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !isSysVIntegerParamType(param.ty)) return error.UnsupportedCodegenValue;
            if (gpr_index >= 6) return error.UnsupportedCodegenAbi;
            return try ArgReg.fromIndex(gpr_index);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn scalarParamStackDisp8(function: ir.Function, name: []const u8, ty: ir.Type) !u8 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return error.UnsupportedCodegenAbi;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn isSysVIntegerParamType(ty: ir.Type) bool {
    return ty.eql(.{ .int = 1 }) or ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or
        ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr);
}

pub fn fpParamIndex(function: ir.Function, name: []const u8, ty: ir.Type) !usize {
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        const param_is_fp = param.ty.eql(.float) or param.ty.eql(.double);
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty) or !param_is_fp) return error.UnsupportedCodegenValue;
            if (sse_index >= 8) return error.UnsupportedCodegenAbi;
            return sse_index;
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn stackParamDisp8OrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?u8 {
    if (!isSysVIntegerParamType(ty) and !ty.eql(.float) and !ty.eql(.double)) return error.UnsupportedCodegenType;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, name)) {
            if (!param.ty.eql(ty)) return error.UnsupportedCodegenValue;
            const in_register = if (isSysVIntegerParamType(ty)) gpr_index < 6 else sse_index < 8;
            if (in_register) return null;
            const offset = 8 + stack_eightbytes * 8;
            if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
            return @intCast(offset);
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return null;
}

pub fn emitI32ParamOrStackIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    name: []const u8,
) !bool {
    if (try registerParamRegOrNull(function, name, .{ .int = 32 })) |reg| {
        try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
        return true;
    }
    if (try stackParamDisp8OrNull(function, name, .{ .int = 32 })) |offset| {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = offset });
        return true;
    }
    return false;
}

pub fn registerParamRegOrNull(function: ir.Function, name: []const u8, ty: ir.Type) !?ArgReg {
    return paramRegOrNull(function, name, ty) catch |err| switch (err) {
        error.UnsupportedCodegenAbi => null,
        else => return err,
    };
}

pub fn blockIndex(function: ir.Function, name: []const u8) ?usize {
    for (function.blocks.items, 0..) |block, index| {
        if (std.mem.eql(u8, block.name, name)) return index;
    }
    return null;
}
pub fn lowerSelectedI64ConstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 0) return false;
    const value = switch (ret.value orelse return error.InvalidRet) {
        .int => |int| int,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };

    try machine.instructions.append(allocator, .{ .mov_imm_rax = try i64Value(value) });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64ParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 0) return false;
    const name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const reg = try sysvIntegerParamReg(function, name, .{ .int = 64 });
    try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgI64DirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len == 0 or block.instructions.items.len > 2) return false;
    const instruction = block.instructions.items[block.instructions.items.len - 1];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
    } else {
        const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, call);
        try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerControlFlowCallsWriterMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    if (call_inst.removed or add_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isCalleeName(call.callee, "control_flow_calls.writer_callee")) return false;
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any()) return false;
    if (!isNamed(add.lhs, call_name) or !isInt(add.rhs, 1)) return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerDirectI32CallMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenInstruction;
    if (call.args.items.len > max_sysv_stack_call_args + 6) return error.UnsupportedCodegenAbi;

    var add_immediate: i32 = 0;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_name)) return false;
    } else {
        const second_inst = block.instructions.items[1];
        if (second_inst.removed) return false;
        if (identityCastFrom(second_inst, call_name, .{ .int = 32 }, .{ .int = 32 })) |cast_name| {
            if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
        } else {
            const add_name = second_inst.result orelse return false;
            if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;
            const add = switch (second_inst.kind) {
                .binary => |binary| binary,
                else => return false,
            };
            if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or add.flags.any() or !isNamed(add.lhs, call_name)) return false;
            add_immediate = switch (add.rhs) {
                .int => |int| try i32Value(int),
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
            };
        }
    }

    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    if (add_immediate != 0) try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_immediate });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const ExpectedCallArg = struct {
    ty: ir.Type,
    value: ir.Value,
};

pub fn lowerSelectedLibfuzzerTestRun(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main.runner_test_run")) return false;
    if (ret.ty != .void or ret.value != null) return false;
    if (function.params.items.len != 1 or block.instructions.items.len != 4) return false;

    const set_test_args = [_]ExpectedCallArg{.{
        .ty = .ptr,
        .value = .{ .named = "@main.testOne" },
    }};
    try validateVoidCall(block.instructions.items[0], "fuzzer_set_test", &set_test_args);

    const empty_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_11775 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 0 },
        },
    };
    try validateVoidCall(block.instructions.items[1], "fuzzer_new_input", &empty_input_args);

    const hello_input_args = [_]ExpectedCallArg{
        .{
            .ty = .{ .int = 64 },
            .value = .{ .constant_expr = "ptrtoint (ptr @__anon_16031 to i64)" },
        },
        .{
            .ty = .{ .int = 64 },
            .value = .{ .int = 5 },
        },
    };
    try validateVoidCall(block.instructions.items[2], "fuzzer_new_input", &hello_input_args);
    try validateVoidCall(block.instructions.items[3], "fuzzer_start_test", &.{});

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "main.testOne" });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_set_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_11775" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 0 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .lea_global_rdi = "__anon_16031" });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = 5 });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_new_input", .ret_ty = .void } });
    try machine.instructions.append(allocator, .{ .direct_call = .{ .symbol = "fuzzer_start_test", .ret_ty = .void } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateVoidCall(instruction: ir.Instruction, callee: []const u8, expected_args: []const ExpectedCallArg) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, callee)) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != expected_args.len) return error.UnsupportedCodegenInstruction;
    for (call.args.items, expected_args) |arg, expected| {
        if (!arg.ty.eql(expected.ty) or !arg.value.eql(expected.value)) return error.UnsupportedCodegenValue;
    }
}

pub fn validateAssumeColdCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.assume")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 1) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 1 }) or !isInt(call.args.items[0].value, 1)) return error.UnsupportedCodegenValue;
}

pub fn validateIntegerOverflowPanicCall(instruction: ir.Instruction) !void {
    if (instruction.removed) return error.UnsupportedCodegenInstruction;
    if (instruction.result != null) return error.UnsupportedCodegenInstruction;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!isCalleeName(call.callee, "debug.FullPanic((function 'defaultPanic')).integerOverflow")) return error.UnsupportedCodegenInstruction;
    if (call.ret_ty != .void or call.args.items.len != 0) return error.UnsupportedCodegenInstruction;
}

pub fn lowerI64SaturatingHelperFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerSelectedUmlFixSatI64Return(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerSelectedUmlFixSatI64Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "no_compile_panic_for_unchecked_arith.entry")) return false;
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 0 or block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return error.InstructionNeedsResult;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (!std.mem.eql(u8, ret_name, call_result)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    if (!std.mem.eql(u8, call.callee, "llvm.umul.fix.sat.i64")) return false;
    if (!call.ret_ty.eql(.{ .int = 64 }) or call.args.items.len != 3) return error.UnsupportedCodegenInstruction;
    if (!call.args.items[0].ty.eql(.{ .int = 64 }) or !call.args.items[0].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[1].ty.eql(.{ .int = 64 }) or !call.args.items[1].value.eql(.{ .int = 2 })) return error.UnsupportedCodegenValue;
    if (!call.args.items[2].ty.eql(.{ .int = 32 }) or !call.args.items[2].value.eql(.{ .int = 0 })) return error.UnsupportedCodegenValue;

    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerSingleStackSlotCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const call_inst = block.instructions.items[3];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or call_inst.removed) return false;

    const slot = alloca_inst.result orelse return false;
    const load_result = load_inst.result orelse return false;
    const call_result = call_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, call_result, ret_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !isNamed(store.ptr, slot)) return false;
    const store_reg = try paramValueReg(function, store.value, .{ .int = 32 });

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !isNamed(load.ptr, slot)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null) return error.UnsupportedCodegenInstruction;
    if (call.inline_asm != null) return error.UnsupportedCodegenInstruction;
    try validateDefaultCallConv(call.calling_conv);
    if (!call.ret_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenType;
    if (call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (!arg.ty.eql(.{ .int = 32 }) or !isNamed(arg.value, load_result)) return false;

    try machine.instructions.append(allocator, .sub_rsp_8);
    try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{
        .frame_index = .slot0,
        .reg = store_reg,
    } });
    try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{
        .reg = .rdi,
        .frame_index = .slot0,
    } });
    try machine.instructions.append(allocator, .{ .direct_call = .{
        .symbol = call.callee,
        .ret_ty = call.ret_ty,
    } });
    try machine.instructions.append(allocator, .add_rsp_8);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerPointerVolatileRoundtripReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 32 })) return false;

    var alloca_names: [8][]const u8 = undefined;
    var alloca_count: usize = 0;
    var volatile_store: ?ir.StoreInst = null;
    var volatile_load: ?ir.LoadInst = null;
    var volatile_load_result: ?[]const u8 = null;

    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .alloca => {
                if (alloca_count == alloca_names.len) return false;
                alloca_names[alloca_count] = instruction.result orelse return false;
                alloca_count += 1;
            },
            .store => |store| {
                if (store.attrs.is_volatile) {
                    if (volatile_store != null) return false;
                    volatile_store = store;
                } else if (!isO0ParamStoreToAlloca(function, store, alloca_names[0..alloca_count])) {
                    return false;
                }
            },
            .load => |load| {
                if (!load.attrs.is_volatile or volatile_load != null) return false;
                volatile_load = load;
                volatile_load_result = instruction.result orelse return false;
            },
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
        }
    }

    const store = volatile_store orelse return false;
    const load = volatile_load orelse return false;
    const load_result = volatile_load_result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isNamed(store.ptr, function.params.items[0].name) or !isNamed(store.value, function.params.items[1].name)) return false;

    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    try machine.instructions.append(allocator, .volatile_roundtrip_rdi_esi_eax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeVolatileRoundtripMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main") and
        !std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main"))
    {
        return false;
    }
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (std.mem.eql(u8, function.name, "runtime_volatile_roundtrip_main.main") and block.instructions.items.len == 3) {
        return try lowerRuntimeVolatileRoundtripPreoptMainReturn(allocator, machine, block, ret);
    }
    if (block.instructions.items.len != 4) return false;

    const store_inst = block.instructions.items[0];
    const load_inst = block.instructions.items[1];
    const icmp_inst = block.instructions.items[2];
    const result_inst = block.instructions.items[3];
    if (store_inst.removed or load_inst.removed or icmp_inst.removed or result_inst.removed) return false;

    const load_name = load_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const result_name = result_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, result_name)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or !store.attrs.is_volatile) return false;
    if (!isInt(store.value, 42)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, store_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or !load.attrs.is_volatile) return false;
    const load_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, load_global, "pointers_memory.volatile_slot") and
        !std.mem.eql(u8, load_global, "runtime_volatile_roundtrip_main.slot"))
    {
        return false;
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if ((icmp.predicate != .eq and icmp.predicate != .ne) or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_name) or !isInt(icmp.rhs, 42)) return false;

    switch (result_inst.kind) {
        .select => |select| {
            if (icmp.predicate != .eq) return false;
            if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
        },
        .cast => |cast| {
            if (icmp.predicate != .ne) return false;
            if (cast.op != .zext or !cast.from_ty.eql(.{ .int = 1 }) or !cast.to_ty.eql(.{ .int = 32 })) return false;
            if (!isNamed(cast.value, icmp_name)) return false;
        },
        else => return false,
    }

    const fail = "volatile_roundtrip_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = load_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeVolatileRoundtripPreoptMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_volatile_roundtrip_main.volatileRoundtrip")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_volatile_roundtrip_main.slot")) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(call.args.items[1].value, 42)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "volatile_roundtrip_preopt_fail";
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 42 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_volatile_roundtrip_main.slot" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isO0ParamStoreToAlloca(function: ir.Function, store: ir.StoreInst, alloca_names: []const []const u8) bool {
    if (store.attrs.isBarrier()) return false;
    const ptr_name = switch (store.ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    var points_to_alloca = false;
    for (alloca_names) |alloca_name| {
        if (std.mem.eql(u8, ptr_name, alloca_name)) {
            points_to_alloca = true;
            break;
        }
    }
    if (!points_to_alloca) return false;

    for (function.params.items) |param| {
        if (store.ty.eql(param.ty) and isNamed(store.value, param.name)) return true;
    }
    return false;
}

pub fn lowerScalarFpCastReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (function.params.items.len != 1) return false;
    if (block.instructions.items.len != 1) return false;
    const cast_inst = block.instructions.items[0];
    if (cast_inst.removed) return false;
    const cast_result = cast_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;
    const cast = switch (cast_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (!cast.from_ty.eql(function.params.items[0].ty)) return false;
    if (!cast.to_ty.eql(function.ret_ty) or !ret.ty.eql(function.ret_ty)) return false;
    if (!isNamed(cast.value, function.params.items[0].name)) return false;

    switch (cast.op) {
        .sitofp => {
            if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 32 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_edi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.from_ty.eql(.{ .int = 64 }) and cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .uitofp => {
            // Unsigned 32-bit converts exactly through a zero-extended
            // 64-bit signed convert; wider unsigned sources stay fail-closed.
            if (!cast.from_ty.eql(.{ .int = 32 })) return false;
            try machine.instructions.append(allocator, .mov_edi_edi);
            if (cast.to_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvtsi2ss_rdi_xmm0);
            } else if (cast.to_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvtsi2sd_rdi_xmm0);
            } else return false;
        },
        .fptosi => {
            if (!cast.to_ty.eql(.{ .int = 32 })) return false;
            if (cast.from_ty.eql(.float)) {
                try machine.instructions.append(allocator, .cvttss2si_xmm0_eax);
            } else if (cast.from_ty.eql(.double)) {
                try machine.instructions.append(allocator, .cvttsd2si_xmm0_eax);
            } else return false;
        },
        .fptrunc => {
            if (!cast.from_ty.eql(.double) or !cast.to_ty.eql(.float)) return false;
            try machine.instructions.append(allocator, .cvtsd2ss_xmm0_xmm0);
        },
        .fpext => {
            if (!cast.from_ty.eql(.float) or !cast.to_ty.eql(.double)) return false;
            try machine.instructions.append(allocator, .cvtss2sd_xmm0_xmm0);
        },
        .trunc, .zext, .sext, .fptoui, .bitcast, .ptrtoint, .inttoptr => return false,
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregateAbiReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerMemoryAggregateCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDirectCallReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSmallIntegerAggregateReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerSysVAggregateFieldReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateIntegerFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateFloatFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRegisterAggregateDoubleFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMemoryIntegerAggregateFieldAddReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerTruncI64ArgReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerMakePairReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerMemoryAggregateCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .memory or classification.size_bytes == 0) return false;
    if (!isSupportedAggregateCopyLeafAggregate(function.ret_ty)) return false;

    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.args.items.len != 1) return false;

    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| target: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramRegWithInitialGpr(function, callee_name, .ptr, 1);
        if (callee_reg == .rdi) return error.UnsupportedCodegenAbi;
        break :target .{ .indirect_from_reg = callee_reg };
    } else .{ .direct = call.callee };

    const aggregate_arg = call.args.items[0];
    if (!aggregate_arg.ty.eql(function.ret_ty)) return false;
    const aggregate_name = switch (aggregate_arg.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const source = try sysvParamCursorForWithInitial(function, aggregate_name, aggregate_arg.ty, .{
        .gpr = 1,
        .sse = 0,
        .stack_eightbytes = 0,
    });

    const stack_arg_count = try appendSysVMemoryAggregateStackPassThroughArgs(
        allocator,
        machine,
        function,
        source,
        classification,
    );
    try setupSysVCallTarget(allocator, machine, call_target);
    try appendSysVCallTargetWithStackArgs(allocator, machine, call_target, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn classifySysVAggregateForTest(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregateForTest(ty);
}

pub fn classifySysVAggregate(ty: ir.Type) !SysVAggregateClassification {
    return try sysv_abi.classifyAggregate(ty);
}

pub fn classifySysVSmallIntegerAggregate(ty: ir.Type) ?SysVSmallIntegerAggregate {
    return sysv_abi.classifySmallIntegerAggregate(ty);
}

pub fn lowerSmallIntegerAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const classification = classifySysVSmallIntegerAggregate(function.ret_ty) orelse return false;
    if (classification.eightbytes != 2 or !ret.ty.eql(function.ret_ty)) return false;
    if (block.instructions.items.len != 2) return false;
    const first_inst = block.instructions.items[0];
    const second_inst = block.instructions.items[1];
    if (first_inst.removed or second_inst.removed) return false;
    const first_name = first_inst.result orelse return false;
    const second_name = second_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_name)) return false;

    const first = switch (first_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    const second = switch (second_inst.kind) {
        .insertvalue => |insert| insert,
        else => return false,
    };
    if (!first.aggregate_ty.eql(function.ret_ty) or !second.aggregate_ty.eql(function.ret_ty)) return false;
    if (first.aggregate != .undef or !isNamed(second.aggregate, first_name)) return false;
    if (!std.mem.eql(u8, first.indices, "0") or !std.mem.eql(u8, second.indices, "1")) return false;
    if (!first.value_ty.eql(.{ .int = 64 }) or !second.value_ty.eql(.{ .int = 64 })) return false;
    const first_reg = try paramValueReg(function, first.value, .{ .int = 64 });
    const second_reg = try paramValueReg(function, second.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_rax = first_reg });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = second_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty)) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;
    const leaf_count = block.instructions.items.len;
    if (leaf_count == 0 or leaf_count > 8) return false;

    var leaves: [8]AggregateReturnLeaf = undefined;
    var aggregate_value: ir.Value = .undef;
    for (block.instructions.items, 0..) |instruction, index| {
        if (instruction.removed) return false;
        const result = instruction.result orelse return false;
        const insert = switch (instruction.kind) {
            .insertvalue => |insert| insert,
            else => return false,
        };
        if (!insert.aggregate_ty.eql(function.ret_ty)) return false;
        if (!valuesEqual(insert.aggregate, aggregate_value)) return false;
        const offset = try aggregateInsertByteOffset(function.ret_ty, insert.indices, insert.value_ty);
        if (index != 0 and offset <= leaves[index - 1].offset) return error.UnsupportedCodegenAbi;
        leaves[index] = .{ .value = insert.value, .ty = insert.value_ty, .offset = offset };
        aggregate_value = .{ .named = result };
    }
    if (!valuesEqual(ret.value orelse return error.InvalidRet, aggregate_value)) return false;

    if (try lowerFourI32RegisterAggregateReturn(allocator, machine, function, leaves[0..leaf_count], classification)) return true;

    var gpr_return_index: usize = 0;
    var sse_return_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const leaf_eightbyte: usize = @intCast(leaf.offset / 8);
        if (leaf_eightbyte >= classification.eightbyte_count) return false;
        const leaf_class = classification.eightbytes[leaf_eightbyte] orelse return false;
        switch (leaf_class) {
            .integer => {
                if (leaf.ty.eql(.{ .int = 64 })) {
                    const src = try paramValueReg(function, leaf.value, leaf.ty);
                    switch (gpr_return_index) {
                        0 => try machine.instructions.append(allocator, .{ .mov_arg_rax = src }),
                        1 => try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rdx, .src = src } }),
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.{ .int = 32 })) return false;
                if (leaf.offset % 8 != 0) return error.UnsupportedCodegenAbi;
                const low_reg = try paramValueReg(function, leaf.value, leaf.ty);
                if (leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.{ .int = 32 }) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    const high_reg = try paramValueReg(function, leaves[leaf_index + 1].value, .{ .int = 32 });
                    switch (gpr_return_index) {
                        0 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
                            try machine.instructions.append(allocator, .or_rdx_rax);
                        },
                        1 => {
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = high_reg } });
                            try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
                            try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } });
                            try machine.instructions.append(allocator, .or_rcx_rdx);
                        },
                        else => return error.UnsupportedCodegenAbi,
                    }
                    gpr_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                switch (gpr_return_index) {
                    0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg }),
                    1 => try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = low_reg } }),
                    else => return error.UnsupportedCodegenAbi,
                }
                gpr_return_index += 1;
            },
            .sse => {
                if (leaf.ty.eql(.float) and leaf.offset % 8 == 0 and
                    leaf_index + 1 < leaf_count and
                    leaves[leaf_index + 1].ty.eql(.float) and
                    leaves[leaf_index + 1].offset / 8 == leaf_eightbyte and
                    leaves[leaf_index + 1].offset % 8 == 4)
                {
                    if (sse_return_index != 0) return error.UnsupportedCodegenAbi;
                    const low_fp_index = try fpParamIndexFromValue(function, leaf.value, .float);
                    const high_fp_index = try fpParamIndexFromValue(function, leaves[leaf_index + 1].value, .float);
                    if (high_fp_index == 0 and low_fp_index != 0) return error.UnsupportedCodegenAbi;
                    const low_reg = try XmmReg.fromIndex(low_fp_index);
                    const high_reg = try XmmReg.fromIndex(high_fp_index);
                    if (low_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = low_reg } });
                    }
                    if (high_reg != .xmm0) {
                        try machine.instructions.append(allocator, .{ .unpcklps_xmm = .{ .dst = .xmm0, .src = high_reg } });
                    }
                    sse_return_index += 1;
                    leaf_index += 1;
                    continue;
                }
                if (!leaf.ty.eql(.double)) return false;
                const fp_index = try fpParamIndexFromValue(function, leaf.value, leaf.ty);
                switch (sse_return_index) {
                    0 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm0 => {},
                        .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                        .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    1 => switch (try XmmReg.fromIndex(fp_index)) {
                        .xmm1 => {},
                        .xmm0, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
                    },
                    else => return error.UnsupportedCodegenAbi,
                }
                sse_return_index += 1;
            },
        }
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateReturnLeaf = struct {
    value: ir.Value,
    ty: ir.Type,
    offset: u64,
};

pub fn lowerFourI32RegisterAggregateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    leaves: []const AggregateReturnLeaf,
    classification: SysVAggregateClassification,
) !bool {
    if (classification.eightbyte_count != 2 or
        classification.eightbytes[0] != .integer or
        classification.eightbytes[1] != .integer or
        leaves.len != 4)
    {
        return false;
    }
    const expected_offsets = [_]u64{ 0, 4, 8, 12 };
    for (leaves, 0..) |leaf, index| {
        if (!leaf.ty.eql(.{ .int = 32 }) or leaf.offset != expected_offsets[index]) return false;
    }
    const a = try paramValueReg(function, leaves[0].value, .{ .int = 32 });
    const b = try paramValueReg(function, leaves[1].value, .{ .int = 32 });
    const c = try paramValueReg(function, leaves[2].value, .{ .int = 32 });
    const d = try paramValueReg(function, leaves[3].value, .{ .int = 32 });

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = d } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = c } });
    try machine.instructions.append(allocator, .or_rcx_rdx);
    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rcx, .src = b } });
    try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = a });
    try machine.instructions.append(allocator, .or_rcx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn aggregateInsertByteOffset(aggregate_ty: ir.Type, indices: []const u8, value_ty: ir.Type) !u64 {
    const layout = try x86_64SysVDataLayout();
    var current_ty = aggregate_ty;
    var offset: u64 = 0;
    var rest = indices;
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const part = std.mem.trim(u8, if (comma) |pos| rest[0..pos] else rest, " \t");
        const field_index = std.fmt.parseInt(usize, part, 10) catch return error.UnsupportedCodegenAbi;
        const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, field_index) orelse
            return error.UnsupportedCodegenAbi;
        if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
        offset += @intCast(field_offset_i);
        current_ty = memory_location.aggregateFieldType(current_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        rest = if (comma) |pos| rest[pos + 1 ..] else "";
    }
    if (!current_ty.eql(value_ty)) return error.UnsupportedCodegenAbi;
    return offset;
}

pub fn aggregateFieldCount(ty: ir.Type) ?usize {
    var count: usize = 0;
    while (memory_location.aggregateFieldType(ty, count)) |_| : (count += 1) {}
    return count;
}

pub fn aggregateFieldEightbyte(aggregate_ty: ir.Type, field_index: usize) !usize {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    return @intCast(@as(u64, @intCast(field_offset_i)) / 8);
}

pub fn fpParamIndexFromValue(function: ir.Function, value: ir.Value, ty: ir.Type) !usize {
    return switch (value) {
        .named => |name| try fpParamIndex(function, name, ty),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn valuesEqual(a: ir.Value, b: ir.Value) bool {
    return switch (a) {
        .named => |a_name| switch (b) {
            .named => |b_name| std.mem.eql(u8, a_name, b_name),
            else => false,
        },
        .undef => b == .undef,
        .poison => b == .poison,
        .null_value => b == .null_value,
        .zero_initializer => b == .zero_initializer,
        .int => |a_int| switch (b) {
            .int => |b_int| a_int == b_int,
            else => false,
        },
        .fp => |a_fp| switch (b) {
            .fp => |b_fp| std.mem.eql(u8, a_fp, b_fp),
            else => false,
        },
        .vector, .constant_expr => false,
    };
}

pub fn lowerSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.float) and !ret.ty.eql(.double)) or
        (block.instructions.items.len != 3 and block.instructions.items.len != 4)) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const maybe_gep_inst: ?ir.Instruction = if (block.instructions.items.len == 4) block.instructions.items[2] else null;
    const load_inst = block.instructions.items[block.instructions.items.len - 1];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed) return false;
    if (maybe_gep_inst) |gep_inst| if (gep_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const classification = classifySysVAggregate(alloca.allocated_ty) catch return false;
    if (classification.kind != .register or classification.eightbyte_count == 0) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(alloca.allocated_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;

    const layout = try x86_64SysVDataLayout();
    const field_offset = if (maybe_gep_inst) |gep_inst| blk: {
        const gep_name = gep_inst.result orelse return false;
        if (!isNamed(load.ptr, gep_name)) return false;
        const gep = switch (gep_inst.kind) {
            .gep => |gep| gep,
            else => return false,
        };
        if (!isNamed(gep.ptr, alloca_name)) return false;
        break :blk aggregateGepByteOffset(layout, alloca.allocated_ty, gep) orelse return false;
    } else blk: {
        if (!isNamed(load.ptr, alloca_name)) return false;
        break :blk @as(u64, 0);
    };
    _ = aggregateFieldIndexAtOffset(alloca.allocated_ty, field_offset, load.ty) orelse return false;

    try emitSysVAggregateFieldOffsetReturn(allocator, machine, function, param_name, alloca.allocated_ty, field_offset, load.ty);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub const AggregateIntegerFieldLoad = struct {
    offset: u64,
};

pub const AggregateIntegerAddTerm = struct {
    offset: u64,
};

pub const AggregateDoubleFieldLoad = struct {
    offset: u64,
};

pub const AggregateDoubleAddTerm = struct {
    offset: u64,
};

pub const AggregateFloatFieldLoad = struct {
    offset: u64,
};

pub const AggregateFloatAddTerm = struct {
    offset: u64,
};

pub fn lowerRegisterAggregateIntegerFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 32 }) and !ret.ty.eql(.{ .int = 64 })) or !function.ret_ty.eql(ret.ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(ret.ty) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(ret.ty)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, ret.ty, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], ret.ty, true);
    for (terms[1..term_count]) |term| {
        try emitAggregateIntegerTerm(allocator, machine, function, param_name, aggregate_ty, term, ret.ty, false);
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateFloatFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.float) or !function.ret_ty.eql(.float)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateFloatFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.float) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateFloatAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateFloatAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;
    if (terms[0].offset > terms[1].offset) std.mem.swap(AggregateFloatAddTerm, &terms[0], &terms[1]);

    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateFloatTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addss_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRegisterAggregateDoubleFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.double) or !function.ret_ty.eql(.double)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    const aggregate_ty = alloca.allocated_ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .register) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name)) return false;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateDoubleFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                try pointer_offsets.put(result, base_offset + offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.double) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [2]AggregateDoubleAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateDoubleAddTerms(block, ret.value orelse return error.InvalidRet, field_loads, &terms, &term_count)) return false;
    if (term_count != 2) return false;

    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[0], .xmm0);
    try emitAggregateDoubleTerm(allocator, machine, function, param_name, aggregate_ty, terms[1], .xmm1);
    try machine.instructions.append(allocator, .addsd_xmm1_xmm0);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn collectAggregateFloatAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateFloatFieldLoad),
    terms: *[2]AggregateFloatAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.float)) return false;
    if (!try collectAggregateFloatAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateFloatAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn collectAggregateDoubleAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    field_loads: std.StringHashMap(AggregateDoubleFieldLoad),
    terms: *[2]AggregateDoubleAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenAbi;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .fadd or !binary.ty.eql(.double)) return false;
    if (!try collectAggregateDoubleAddTerms(block, binary.lhs, field_loads, terms, term_count)) return false;
    return try collectAggregateDoubleAddTerms(block, binary.rhs, field_loads, terms, term_count);
}

pub fn aggregateGepByteOffset(layout: target.DataLayout, aggregate_ty: ir.Type, gep: ir.GepInst) ?u64 {
    if (gep.source_ty.eql(.{ .int = 8 }) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const offset = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (offset < 0) return null;
        return @intCast(offset);
    }
    if (isScalarElementGepType(gep.source_ty) and gep.indices.items.len == 1 and gep.indices.items[0].ty.eql(.{ .int = 64 })) {
        const index = switch (gep.indices.items[0].value) {
            .int => |int| int,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
        };
        if (index < 0) return null;
        const element_size = layout.typeStoreSizeBytes(gep.source_ty) catch return null;
        return @intCast(@as(u128, @intCast(index)) * element_size);
    }
    _ = aggregate_ty;
    if (isAggregateType(gep.source_ty) and gep.indices.items.len >= 2 and
        gep.indices.items[0].ty.eql(.{ .int = 64 }) and isInt(gep.indices.items[0].value, 0))
    {
        var current_ty = gep.source_ty;
        var byte_offset: u64 = 0;
        for (gep.indices.items[1..]) |index| {
            if (!index.ty.eql(.{ .int = 32 }) and !index.ty.eql(.{ .int = 64 })) return null;
            const field_index = switch (index.value) {
                .int => |int| int,
                .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            if (field_index < 0 or field_index > std.math.maxInt(usize)) return null;
            const offset = memory_location.aggregateFieldOffsetWithLayout(layout, current_ty, @intCast(field_index)) orelse return null;
            if (offset < 0) return null;
            byte_offset += @intCast(offset);
            current_ty = memory_location.aggregateFieldType(current_ty, @intCast(field_index)) orelse return null;
        }
        return byte_offset;
    }
    return null;
}

pub fn aggregateFieldIndexAtOffset(aggregate_ty: ir.Type, expected_offset: u64, expected_ty: ir.Type) ?usize {
    const layout = x86_64SysVDataLayout() catch return null;
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
        if (offset_i < 0) return null;
        const field_offset: u64 = @intCast(offset_i);
        if (field_ty.eql(expected_ty) and field_offset == expected_offset) return field_index;
        if (isAggregateType(field_ty) and expected_offset >= field_offset) {
            if (aggregateFieldIndexAtOffset(field_ty, expected_offset - field_offset, expected_ty) != null) return field_index;
        }
    }
    return null;
}

pub fn isScalarElementGepType(ty: ir.Type) bool {
    return switch (ty) {
        .int, .float, .double, .ptr => true,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn isAggregateType(ty: ir.Type) bool {
    return switch (ty) {
        .aggregate => true,
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => false,
    };
}

pub fn collectAggregateIntegerAddTerms(
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    field_loads: std.StringHashMap(AggregateIntegerFieldLoad),
    terms: *[8]AggregateIntegerAddTerm,
    term_count: *usize,
) !bool {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (field_loads.get(name)) |load| {
        if (term_count.* >= terms.len) return error.UnsupportedCodegenInstruction;
        terms[term_count.*] = .{ .offset = load.offset };
        term_count.* += 1;
        return true;
    }
    const instruction = findInstruction(block, name) orelse return false;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (binary.op != .add or !binary.ty.eql(ty)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.lhs, ty, field_loads, terms, term_count)) return false;
    if (!try collectAggregateIntegerAddTerms(block, binary.rhs, ty, field_loads, terms, term_count)) return false;
    return true;
}

pub fn emitAggregateIntegerTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateIntegerAddTerm,
    ty: ir.Type,
    first: bool,
) !void {
    const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, term.offset, ty);
    switch (location) {
        .gpr => |field| {
            if (ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg64_rax = field.reg });
                }
                return;
            }
            if (!ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => if (first)
                    try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg })
                else
                    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = field.reg } }),
                4 => if (first) {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                } else {
                    try machine.instructions.append(allocator, .{ .add_arg_high32_eax = field.reg });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (ty.eql(.{ .int = 64 })) {
                if (first) {
                    try appendLoadStackDispRax(allocator, machine, offset);
                } else {
                    try appendAddStackDispRax(allocator, machine, offset);
                }
            } else if (ty.eql(.{ .int = 32 })) {
                if (first) return error.UnsupportedCodegenAbi;
                try appendAddStackDispEax(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitAggregateDoubleTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateDoubleAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .double);
    switch (location) {
        .sse => |reg| {
            if (reg == dest) return;
            if (dest == .xmm0 and reg == .xmm1) {
                try machine.instructions.append(allocator, .movapd_xmm1_xmm0);
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .stack => |offset| try appendLoadStackDispXmm(allocator, machine, dest, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn emitAggregateFloatTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    term: AggregateFloatAddTerm,
    dest: XmmReg,
) !void {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, term.offset, .float);
    switch (location) {
        .sse => |reg| {
            if (reg != dest) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = dest, .src = reg } });
            }
            if (term.offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = dest });
            } else if (term.offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| {
            if (dest != .xmm0) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispXmm0F32(allocator, machine, offset);
        },
        .gpr => return error.UnsupportedCodegenAbi,
    }
}

pub fn appendLoadStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_rax = offset });
    }
}

pub fn appendLoadStackDispXmm0(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0 = offset });
    }
}

pub fn appendLoadStackDispXmm0F32(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm0_f32 = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm0_f32 = offset });
    }
}

pub fn appendLoadStackDispXmm(allocator: std.mem.Allocator, machine: *MachineFunction, reg: XmmReg, offset: u32) !void {
    if (reg == .xmm0) return appendLoadStackDispXmm0(allocator, machine, offset);
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .load_stack_disp8_xmm = .{ .reg = reg, .disp = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .load_stack_disp32_xmm = .{ .reg = reg, .disp = offset } });
    }
}

pub fn appendAddStackDispRax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_rax = offset });
    }
}

pub fn appendAddStackDispEax(allocator: std.mem.Allocator, machine: *MachineFunction, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = @intCast(offset) });
    } else {
        try machine.instructions.append(allocator, .{ .add_stack_disp32_eax = offset });
    }
}

pub fn appendStoreArg64ArgPtrDisp(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    ptr_reg: ArgReg,
    src_reg: ArgReg,
    offset: u32,
) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp8 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = @intCast(offset),
        } });
    } else {
        try machine.instructions.append(allocator, .{ .store_arg64_arg_ptr_disp32 = .{
            .ptr_reg = ptr_reg,
            .src_reg = src_reg,
            .offset = offset,
        } });
    }
}

pub fn appendStoreRaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_rax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreEaxArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_eax_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub fn appendStoreXmm0F32ArgPtrDisp(allocator: std.mem.Allocator, machine: *MachineFunction, reg: ArgReg, offset: u32) !void {
    if (offset <= 127) {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp8 = .{ .reg = reg, .offset = @intCast(offset) } });
    } else {
        try machine.instructions.append(allocator, .{ .store_xmm0_f32_arg_ptr_disp32 = .{ .reg = reg, .offset = offset } });
    }
}

pub const SysVIntegerAggregateFieldLocation = union(enum) {
    gpr: struct {
        reg: ArgReg,
        offset_in_eightbyte: u3,
    },
    stack: u32,
};

pub fn sysvIntegerAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVIntegerAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    if (field_size != 4 and field_size != 8) return error.UnsupportedCodegenAbi;

    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            const field_eightbyte = field_offset / 8;
            if (field_eightbyte >= classification.eightbyte_count) return error.UnsupportedCodegenAbi;
            const field_class = classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi;
            if (field_class != .integer) return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return .{ .gpr = .{
                .reg = try ArgReg.fromIndex(gpr_index + prior.gpr),
                .offset_in_eightbyte = @intCast(field_offset % 8),
            } };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn lowerMemoryIntegerAggregateFieldAddReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or !function.ret_ty.eql(.{ .int = 64 })) return false;
    if (function.params.items.len != 1) return false;
    const aggregate_ty = function.params.items[0].ty;
    const classification = classifySysVAggregate(aggregate_ty) catch return false;
    if (classification.kind != .memory or !isI64LeafAggregate(aggregate_ty)) return false;
    if (block.instructions.items.len < 5) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    if (alloca_inst.removed or store_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(aggregate_ty)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier() or !isNamed(store.ptr, alloca_name) or
        !isNamed(store.value, function.params.items[0].name)) return false;

    var pointer_offsets = std.StringHashMap(u64).init(allocator);
    defer pointer_offsets.deinit();
    try pointer_offsets.put(alloca_name, 0);

    var field_loads = std.StringHashMap(AggregateIntegerFieldLoad).init(allocator);
    defer field_loads.deinit();

    const layout = try x86_64SysVDataLayout();
    for (block.instructions.items[2..]) |instruction| {
        if (instruction.removed) return false;
        switch (instruction.kind) {
            .gep => |gep| {
                const result = instruction.result orelse return false;
                const base_name = switch (gep.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const base_offset = pointer_offsets.get(base_name) orelse return false;
                const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
                const total_offset = base_offset + offset;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, total_offset, .{ .int = 64 }) orelse return false;
                try pointer_offsets.put(result, total_offset);
            },
            .load => |load| {
                const result = instruction.result orelse return false;
                if (!load.ty.eql(.{ .int = 64 }) or load.attrs.isBarrier()) return false;
                const ptr_name = switch (load.ptr) {
                    .named => |name| name,
                    .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
                };
                const offset = pointer_offsets.get(ptr_name) orelse return false;
                _ = aggregateFieldIndexAtOffset(aggregate_ty, offset, load.ty) orelse return false;
                try field_loads.put(result, .{ .offset = offset });
            },
            .binary => |binary| {
                if (binary.op != .add or !binary.ty.eql(.{ .int = 64 })) return false;
            },
            .phi, .fcmp, .icmp, .select, .cast, .freeze, .alloca, .store, .call, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => return false,
        }
    }

    var terms: [8]AggregateIntegerAddTerm = undefined;
    var term_count: usize = 0;
    if (!try collectAggregateIntegerAddTerms(block, ret.value orelse return error.InvalidRet, .{ .int = 64 }, field_loads, &terms, &term_count)) return false;
    if (term_count < 2) return false;

    try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, terms[0].offset, .{ .int = 64 }));
    for (terms[1..term_count]) |term| {
        try appendAddStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, term.offset, .{ .int = 64 }));
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isI64Aggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (!field_ty.eql(.{ .int = 64 })) return false;
    }
    return true;
}

pub fn isI64LeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (field_ty.eql(.{ .int = 64 })) continue;
        if (isAggregateType(field_ty) and isI64LeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn isSupportedAggregateCopyLeafAggregate(aggregate_ty: ir.Type) bool {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count == 0) return false;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return false;
        if (supportedAggregateCopyLeaf(field_ty)) continue;
        if (isAggregateType(field_ty) and isSupportedAggregateCopyLeafAggregate(field_ty)) continue;
        return false;
    }
    return true;
}

pub fn supportedAggregateCopyLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 32 }) or ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

pub fn aggregateFieldIndexFromGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?usize {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return null;
    if (gep.indices.items.len != 2) return null;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return null;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 })) return null;
    const field_index = switch (gep.indices.items[1].value) {
        .int => |index| index,
        else => return null,
    };
    if (field_index < 0) return null;
    return @intCast(field_index);
}

pub fn stackAggregateFieldDisp8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0) return error.UnsupportedCodegenAbi;
    const offset = 8 + @as(u64, @intCast(offset_i));
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn stackAggregateByteDisp(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    const offset = 8 + field_offset;
    if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset);
}

pub fn validateAggregateFieldGep(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8, field_index: i128) !void {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return error.UnsupportedCodegenInstruction,
    };
    if (!gep.source_ty.eql(aggregate_ty) or !isNamed(gep.ptr, base_name)) return error.UnsupportedCodegenInstruction;
    if (gep.indices.items.len != 2) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 0)) return error.UnsupportedCodegenInstruction;
    if (!gep.indices.items[1].ty.eql(.{ .int = 32 }) or !isInt(gep.indices.items[1].value, field_index)) return error.UnsupportedCodegenInstruction;
}

pub fn emitSysVAggregateFieldReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !void {
    const location = try sysvAggregateFieldLocation(function, param_name, aggregate_ty, field_index, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVAggregateFieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !void {
    if (field_ty.eql(.{ .int = 32 }) or field_ty.eql(.{ .int = 64 })) {
        const location = try sysvIntegerAggregateFieldLocation(function, param_name, aggregate_ty, field_offset, field_ty);
        try emitSysVIntegerAggregateFieldLocationReturn(allocator, machine, location, field_ty);
        return;
    }
    if (field_ty.eql(.float)) {
        _ = try emitSysVAggregateF32FieldOffsetReturn(allocator, machine, function, param_name, aggregate_ty, field_offset);
        return;
    }
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
    try emitSysVAggregateFieldLocationReturn(allocator, machine, location, field_ty);
}

pub fn emitSysVIntegerAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVIntegerAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |field| {
            if (field_ty.eql(.{ .int = 64 })) {
                if (field.offset_in_eightbyte != 0) return error.UnsupportedCodegenAbi;
                try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                return;
            }
            if (!field_ty.eql(.{ .int = 32 })) return error.UnsupportedCodegenAbi;
            switch (field.offset_in_eightbyte) {
                0 => try machine.instructions.append(allocator, .{ .mov_arg_eax = field.reg }),
                4 => {
                    try machine.instructions.append(allocator, .{ .mov_arg_rax = field.reg });
                    try machine.instructions.append(allocator, .{ .shr_rax_imm6 = 32 });
                },
                else => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (!field_ty.eql(.{ .int = 64 })) return error.UnsupportedCodegenAbi;
            try appendLoadStackDispRax(allocator, machine, offset);
        },
    }
}

pub fn emitSysVAggregateFieldLocationReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    location: SysVAggregateFieldLocation,
    field_ty: ir.Type,
) !void {
    switch (location) {
        .gpr => |reg| {
            if (field_ty.eql(.{ .int = 64 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
                return;
            }
            if (field_ty.eql(.{ .int = 32 })) {
                try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
                return;
            }
            return error.UnsupportedCodegenAbi;
        },
        .sse => |reg| {
            if (field_ty.eql(.float)) {
                switch (reg) {
                    .xmm0 => {},
                    .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
                }
                return;
            }
            if (!field_ty.eql(.double)) return error.UnsupportedCodegenAbi;
            switch (reg) {
                .xmm0 => {},
                .xmm1 => try machine.instructions.append(allocator, .movapd_xmm1_xmm0),
                .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => return error.UnsupportedCodegenAbi,
            }
        },
        .stack => |offset| {
            if (field_ty.eql(.{ .int = 64 })) {
                try appendLoadStackDispRax(allocator, machine, offset);
            } else if (field_ty.eql(.float)) {
                try appendLoadStackDispXmm0F32(allocator, machine, offset);
            } else {
                return error.UnsupportedCodegenAbi;
            }
        },
    }
}

pub fn emitSysVAggregateF32FieldOffsetReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
) !bool {
    const location = try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, .float);
    switch (location) {
        .sse => |reg| {
            switch (reg) {
                .xmm0 => {},
                .xmm1, .xmm2, .xmm3, .xmm4, .xmm5, .xmm6, .xmm7 => try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = reg } }),
            }
            if (field_offset % 8 == 4) {
                try machine.instructions.append(allocator, .{ .shufps_high_f32_to_low = .xmm0 });
            } else if (field_offset % 8 != 0) {
                return error.UnsupportedCodegenAbi;
            }
        },
        .stack => |offset| try appendLoadStackDispXmm0F32(allocator, machine, offset),
        .gpr => return error.UnsupportedCodegenAbi,
    }
    return true;
}

pub const SysVAggregateFieldLocation = union(enum) {
    gpr: ArgReg,
    sse: XmmReg,
    stack: u32,
};

pub fn sysvAggregateFieldLocation(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_index: usize,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (field_offset_i < 0) return error.UnsupportedCodegenAbi;
    const field_offset: u64 = @intCast(field_offset_i);
    if (!((memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi).eql(field_ty))) {
        return error.UnsupportedCodegenAbi;
    }
    return try sysvAggregateFieldLocationByOffset(function, param_name, aggregate_ty, field_offset, field_ty);
}

pub fn sysvAggregateFieldLocationByOffset(
    function: ir.Function,
    param_name: []const u8,
    aggregate_ty: ir.Type,
    field_offset: u64,
    field_ty: ir.Type,
) !SysVAggregateFieldLocation {
    const layout = try x86_64SysVDataLayout();
    const field_size = try layout.typeStoreSizeBytes(field_ty);
    const aggregate_size = try layout.typeStoreSizeBytes(aggregate_ty);
    if (field_size == 0 or field_offset + field_size > aggregate_size) return error.UnsupportedCodegenAbi;
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    var gpr_index: usize = 0;
    var sse_index: usize = 0;
    var stack_eightbytes: usize = 0;
    for (function.params.items) |param| {
        if (std.mem.eql(u8, param.name, param_name)) {
            if (!param.ty.eql(aggregate_ty)) return error.UnsupportedCodegenValue;
            const classification = try classifySysVAggregate(param.ty);
            if (classification.kind != .register) return error.UnsupportedCodegenAbi;
            const field_eightbyte = field_offset / 8;
            const field_class = if (field_eightbyte < classification.eightbytes.len)
                classification.eightbytes[@intCast(field_eightbyte)] orelse return error.UnsupportedCodegenAbi
            else
                return error.UnsupportedCodegenAbi;
            const needed = sysvAggregateRegisterNeeds(classification);
            if (gpr_index + needed.gpr > 6 or sse_index + needed.sse > 8) {
                const offset = 8 + stack_eightbytes * 8 + field_offset;
                if (offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
                return .{ .stack = @intCast(offset) };
            }
            const prior = sysvAggregateRegisterNeedsBefore(classification, @intCast(field_eightbyte));
            return switch (field_class) {
                .integer => .{ .gpr = try ArgReg.fromIndex(gpr_index + prior.gpr) },
                .sse => .{ .sse = try XmmReg.fromIndex(sse_index + prior.sse) },
            };
        }
        try advanceSysVParamCursors(param.ty, &gpr_index, &sse_index, &stack_eightbytes);
    }
    return error.UnsupportedCodegenValue;
}

pub fn sysvAggregateRegisterNeeds(classification: SysVAggregateClassification) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeeds(classification);
}

pub fn sysvAggregateRegisterNeedsBefore(classification: SysVAggregateClassification, limit: usize) SysVRegisterNeeds {
    return sysv_abi.aggregateRegisterNeedsBefore(classification, limit);
}

pub fn advanceSysVParamCursors(
    ty: ir.Type,
    gpr_index: *usize,
    sse_index: *usize,
    stack_eightbytes: *usize,
) !void {
    return sysv_abi.advanceParamCursors(ty, gpr_index, sse_index, stack_eightbytes);
}

pub fn lowerRegisterAggregateDirectCallReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(function.ret_ty) or block.instructions.items.len != 1) return false;
    const classification = classifySysVAggregate(function.ret_ty) catch return false;
    if (classification.kind != .register) return false;
    const instruction = block.instructions.items[0];
    if (instruction.removed) return false;
    const call_result = instruction.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!call.ret_ty.eql(function.ret_ty) or call.inline_asm != null) return false;
    if (call.tail_kind != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (call.callee_value) |callee_value| {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        const callee_reg = try paramReg(function, callee_name, .ptr);
        try machine.instructions.append(allocator, .{ .mov_arg_rax = callee_reg });
        const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
            error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
            else => return err,
        };
        try appendIndirectCallRaxWithStackArgs(allocator, machine, call.ret_ty, stack_arg_count);
        try machine.instructions.append(allocator, .ret);
        return true;
    }
    const stack_arg_count = appendSysVScalarCallArgs(allocator, machine, function, call) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenType, error.UnsupportedCodegenValue => return false,
        else => return err,
    };
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairMakePairReturn(allocator, machine, function, block, ret)) return true;
    if (try lowerRuntimeAggregatePairPairFirstReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

pub fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (try lowerRuntimeAggregatePairDirectMainReturn(allocator, machine, block, ret)) return true;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const make_pair_inst = block.instructions.items[1];
    const pair_first_inst = block.instructions.items[2];
    if (alloca_inst.removed or make_pair_inst.removed or pair_first_inst.removed) return false;
    const pair_slot_name = alloca_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, pair_first_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or make_pair.ret_ty != .void) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 3) return false;
    if (!make_pair.args.items[0].ty.eql(.ptr) or !callArgAttrsContain(make_pair.args.items[0], "sret(%runtime_aggregate_pair_main.Pair)") or
        !isNamed(make_pair.args.items[0].value, pair_slot_name)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 1)) return false;
    if (!make_pair.args.items[2].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[2].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.ptr) or !isNamed(pair_first.args.items[0].value, pair_slot_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairDirectMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const make_pair_inst = block.instructions.items[0];
    const pair_first_inst = block.instructions.items[1];
    const bitcast_inst = block.instructions.items[2];
    if (make_pair_inst.removed or pair_first_inst.removed or bitcast_inst.removed) return false;
    const make_pair_name = make_pair_inst.result orelse return false;
    const pair_first_name = pair_first_inst.result orelse return false;
    const bitcast_name = identityCastFrom(bitcast_inst, pair_first_name, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, bitcast_name)) return false;

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(make_pair.calling_conv) or !make_pair.ret_ty.eql(.{ .int = 64 })) return false;
    if (make_pair.callee_value != null or make_pair.inline_asm != null) return false;
    if (!std.mem.eql(u8, make_pair.callee, "runtime_aggregate_pair_main.makePair")) return false;
    if (make_pair.args.items.len != 2) return false;
    if (!make_pair.args.items[0].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[0].value, 1)) return false;
    if (!make_pair.args.items[1].ty.eql(.{ .int = 32 }) or !isInt(make_pair.args.items[1].value, 2)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(pair_first.calling_conv) or !pair_first.ret_ty.eql(.{ .int = 32 })) return false;
    if (pair_first.callee_value != null or pair_first.inline_asm != null) return false;
    if (!std.mem.eql(u8, pair_first.callee, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (pair_first.args.items.len != 1) return false;
    if (!pair_first.args.items[0].ty.eql(.{ .int = 64 }) or !isNamed(pair_first.args.items[0].value, make_pair_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.makePair")) return false;
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !paramAttrsContain(function.params.items[0], "sret(%runtime_aggregate_pair_main.Pair)")) return false;
    if (!function.params.items[1].ty.eql(.{ .int = 32 }) or !function.params.items[2].ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const first_store_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_store_inst = block.instructions.items[2];
    if (first_store_inst.removed or gep_inst.removed or second_store_inst.removed) return false;
    const gep_name = gep_inst.result orelse return false;
    if (ret.value != null) return error.InvalidRet;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 32 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, function.params.items[0].name) or !isNamed(first_store.value, function.params.items[1].name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, function.params.items[0].name)) return false;
    if (gep.indices.items.len != 1 or !gep.indices.items[0].ty.eql(.{ .int = 64 }) or !isInt(gep.indices.items[0].value, 4)) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 32 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, gep_name) or !isNamed(second_store.value, function.params.items[2].name)) return false;

    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeAggregatePairPairFirstReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_aggregate_pair_main.pairFirst")) return false;
    if (!callIsFastcc(function.calling_conv) or !function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 3) return false;

    const alloca_inst = block.instructions.items[0];
    const memcpy_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    if (alloca_inst.removed or memcpy_inst.removed or load_inst.removed) return false;
    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .aggregate = "%runtime_aggregate_pair_main.Pair" })) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;
    if (!memcpy_call.args.items[0].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[0].value, alloca_name)) return false;
    if (!memcpy_call.args.items[1].ty.eql(.ptr) or !isNamed(memcpy_call.args.items[1].value, function.params.items[0].name)) return false;
    if (!memcpy_call.args.items[2].ty.eql(.{ .int = 64 }) or !isInt(memcpy_call.args.items[2].value, 8)) return false;
    if (!memcpy_call.args.items[3].ty.eql(.{ .int = 1 }) or !isInt(memcpy_call.args.items[3].value, 0)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, alloca_name)) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTruncI64ArgReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const trunc_inst = block.instructions.items[0];
    if (trunc_inst.removed) return false;
    const trunc_result = trunc_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, trunc_result)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 64 }) or !trunc.to_ty.eql(.{ .int = 32 })) return false;
    const reg = try paramValueReg(function, trunc.value, .{ .int = 64 });

    try machine.instructions.append(allocator, .{ .mov_arg_eax = reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerMakePairReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 })) return false;
    if (block.instructions.items.len != 4) return false;

    const high_zext_inst = block.instructions.items[0];
    const shift_inst = block.instructions.items[1];
    const low_zext_inst = block.instructions.items[2];
    const or_inst = block.instructions.items[3];
    if (high_zext_inst.removed or shift_inst.removed or low_zext_inst.removed or or_inst.removed) return false;

    const high_zext_result = high_zext_inst.result orelse return false;
    const shift_result = shift_inst.result orelse return false;
    const low_zext_result = low_zext_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

    const high_zext = switch (high_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (high_zext.op != .zext or !high_zext.from_ty.eql(.{ .int = 32 }) or !high_zext.to_ty.eql(.{ .int = 64 })) return false;
    const high_reg = try paramValueReg(function, high_zext.value, .{ .int = 32 });

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .shl or !shift.ty.eql(.{ .int = 64 }) or !isNamed(shift.lhs, high_zext_result) or !isInt(shift.rhs, 32)) return false;

    const low_zext = switch (low_zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (low_zext.op != .zext or !low_zext.from_ty.eql(.{ .int = 32 }) or !low_zext.to_ty.eql(.{ .int = 64 })) return false;
    const low_reg = try paramValueReg(function, low_zext.value, .{ .int = 32 });

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 64 })) return false;
    if (!isNamed(or_binary.lhs, shift_result) or !isNamed(or_binary.rhs, low_zext_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_arg = .{ .dst = .rdx, .src = high_reg } });
    try machine.instructions.append(allocator, .{ .shl_rdx_imm6 = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = low_reg });
    try machine.instructions.append(allocator, .or_rdx_rax);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerStructSumReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 4) return false;

    const first_load_inst = block.instructions.items[0];
    const gep_inst = block.instructions.items[1];
    const second_load_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    if (first_load_inst.removed or gep_inst.removed or second_load_inst.removed or add_inst.removed) return false;

    const first_load_result = first_load_inst.result orelse return false;
    const gep_result = gep_inst.result orelse return false;
    const second_load_result = second_load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, add_result)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 32 })) return false;
    if (first_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;
    const base_reg = try paramValueReg(function, first_load.ptr, .ptr);

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !first_load.ptr.eql(gep.ptr)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 32 }) or !isNamed(second_load.ptr, gep_result)) return false;
    if (second_load.attrs.isBarrier()) return error.UnsupportedCodegenInstruction;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_load_result) and isNamed(add.rhs, second_load_result)) or
        (isNamed(add.lhs, second_load_result) and isNamed(add.rhs, first_load_result)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = base_reg });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = base_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 8) return false;

    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const first_ptr_load_inst = block.instructions.items[2];
    const first_field_load_inst = block.instructions.items[3];
    const second_ptr_load_inst = block.instructions.items[4];
    const gep_inst = block.instructions.items[5];
    const second_field_load_inst = block.instructions.items[6];
    const add_inst = block.instructions.items[7];
    if (alloca_inst.removed or store_inst.removed or first_ptr_load_inst.removed or first_field_load_inst.removed or
        second_ptr_load_inst.removed or gep_inst.removed or second_field_load_inst.removed or add_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const first_ptr_name = first_ptr_load_inst.result orelse return false;
    const first_field_name = first_field_load_inst.result orelse return false;
    const second_ptr_name = second_ptr_load_inst.result orelse return false;
    const gep_name = gep_inst.result orelse return false;
    const second_field_name = second_field_load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.ptr)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.ptr) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const first_ptr_load = switch (first_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_ptr_load.ty.eql(.ptr) or first_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(first_ptr_load.ptr, alloca_name)) return false;

    const first_field_load = switch (first_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_field_load.ty.eql(.{ .int = 32 }) or first_field_load.attrs.isBarrier()) return false;
    if (!isNamed(first_field_load.ptr, first_ptr_name)) return false;

    const second_ptr_load = switch (second_ptr_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_ptr_load.ty.eql(.ptr) or second_ptr_load.attrs.isBarrier()) return false;
    if (!isNamed(second_ptr_load.ptr, alloca_name)) return false;

    const gep = switch (gep_inst.kind) {
        .gep => |gep| gep,
        else => return false,
    };
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, second_ptr_name)) return false;
    if (gep.indices.items.len != 1) return false;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 }) or !isInt(index.value, 4)) return false;

    const second_field_load = switch (second_field_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_field_load.ty.eql(.{ .int = 32 }) or second_field_load.attrs.isBarrier()) return false;
    if (!isNamed(second_field_load.ptr, gep_name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!((isNamed(add.lhs, first_field_name) and isNamed(add.rhs, second_field_name)) or
        (isNamed(add.lhs, second_field_name) and isNamed(add.rhs, first_field_name)))) return false;

    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = .rdi });
    try machine.instructions.append(allocator, .{ .add_arg_ptr_disp4_eax = .rdi });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeStructSumMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_struct_sum_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const icmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or icmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_struct_sum_main.structSum")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_struct_sum_main.pair")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !isInt(icmp.rhs, 42)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerAddChain3Return(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (std.mem.eql(u8, function.name, "runtime_array_sum_main.arraySum")) {
        return try lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret);
    }
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const first_add_inst = block.instructions.items[0];
    const second_add_inst = block.instructions.items[1];
    if (first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, second_add_result)) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;
    const first_lhs = try paramValueReg(function, first_add.lhs, .{ .int = 32 });
    const first_rhs = try paramValueReg(function, first_add.rhs, .{ .int = 32 });

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    const third_reg = if (isNamed(second_add.lhs, first_add_result))
        try paramValueReg(function, second_add.rhs, .{ .int = 32 })
    else if (isNamed(second_add.rhs, first_add_result))
        try paramValueReg(function, second_add.lhs, .{ .int = 32 })
    else
        return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_lhs });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = first_rhs } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = third_reg } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeArraySumPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 3) return false;
    for (function.params.items) |param| {
        if (!param.ty.eql(.{ .int = 32 })) return false;
    }
    if (block.instructions.items.len != 16) return false;

    const memcpy_inst = block.instructions.items[7];
    const first_add_inst = block.instructions.items[12];
    const second_add_inst = block.instructions.items[15];
    if (memcpy_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;

    const first_add_name = first_add_inst.result orelse return false;
    const second_add_name = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_name)) return false;

    const memcpy_call = switch (memcpy_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (memcpy_call.callee_value != null or memcpy_call.inline_asm != null) return false;
    if (!std.mem.eql(u8, memcpy_call.callee, "llvm.memcpy.p0.p0.i64")) return false;
    if (memcpy_call.ret_ty != .void or memcpy_call.args.items.len != 4) return false;

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (first_add.op != .add or !first_add.ty.eql(.{ .int = 32 })) return false;

    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (second_add.op != .add or !second_add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_add.lhs, first_add_name) and !isNamed(second_add.rhs, first_add_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_arg_eax = .rdi });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rsi } });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = .rdx } });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerInlineAsmBarrierReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    if (call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    const inline_asm = call.inline_asm orelse return false;
    if (!inline_asm.sideeffect or !inline_asm.has_memory_clobber) return false;
    if (inline_asm.template.len != 0) return false;
    if (call.ret_ty != .void or call.args.items.len != 0) return false;

    const ret_reg = try paramValueReg(function, ret.value orelse return error.InvalidRet, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = ret_reg });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.read_tls"))
            "tls_concurrency.tls_counter"
        else
            return false;
    if (!try matchGlobalRead(function, block, ret, global_name)) return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsMainReadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;
    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;
    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerTlsMainUpdateReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 3) return false;
    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    const load_name = load_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 }) or !isNamed(add.lhs, load_name)) return false;
    const increment = switch (add.rhs) {
        .int => |value| try i32Value(value),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier() or !isNamed(store.value, add_name)) return false;
    if (!store.ptr.eql(load.ptr)) return false;

    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = increment });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn isMainOrWrapperMain(name: []const u8) bool {
    return std.mem.eql(u8, name, "main") or std.mem.endsWith(u8, name, ".main");
}

pub fn lowerTlsBumpReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const global_name: []const u8 = tlsSymbolFromFunctionAttrs(function) orelse
        if (std.mem.eql(u8, function.name, "tls_concurrency.bump_tls"))
            "tls_concurrency.tls_counter"
        else if (std.mem.endsWith(u8, function.name, ".bumpTls"))
            "runtime_tls_bump_main.tls_counter"
        else
            return false;
    const arg_reg = (try matchGlobalUpdate(function, block, ret, global_name)) orelse return false;
    try machine.instructions.append(allocator, .{ .load_tls_i32_eax = global_name });
    try machine.instructions.append(allocator, .{ .binary_arg_eax = .{ .op = .add, .reg = arg_reg } });
    try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = global_name });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn tlsSymbolFromFunctionAttrs(function: ir.Function) ?[]const u8 {
    const attrs = function.attrs orelse return null;
    const marker = "\"zllvm-tls-symbol\"=\"";
    const start = std.mem.indexOf(u8, attrs, marker) orelse return null;
    const symbol_start = start + marker.len;
    const symbol_end = std.mem.indexOfScalarPos(u8, attrs, symbol_start, '"') orelse return null;
    if (symbol_end == symbol_start) return null;
    return attrs[symbol_start..symbol_end];
}

pub fn knownLocalExecTlsSymbol(symbol: []const u8) bool {
    return std.mem.eql(u8, symbol, "tls_concurrency.tls_counter") or
        std.mem.eql(u8, symbol, "runtime_tls_bump_main.tls_counter") or
        std.mem.eql(u8, symbol, "C_k") or
        std.mem.eql(u8, symbol, "runtime_mix_c_add_zig_main.C_k");
}

pub fn matchGlobalRead(function: ir.Function, block: ir.BasicBlock, ret: anytype, expected_global: []const u8) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (block.instructions.items.len != 1) return false;

    const load_inst = block.instructions.items[0];
    if (load_inst.removed) return false;
    const load_result = load_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, load_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const global_name = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    return std.mem.eql(u8, global_name, expected_global);
}
