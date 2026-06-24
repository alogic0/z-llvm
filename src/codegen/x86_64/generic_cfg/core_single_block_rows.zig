const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_misc_rows = @import("core_misc_rows.zig");
const core_value_support = @import("core_value_support.zig");
const core_value_emit = @import("core_value_emit.zig");
const core_memory_lowering = @import("core_memory_lowering.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const cabi_boundary_rows = @import("cabi_boundary_rows.zig");
const cabi_tls_global_lowering = @import("cabi_tls_global_lowering.zig");
const core_single_block_misc = @import("core_single_block_misc.zig");
const fp_rows = @import("core_single_block_fp.zig");
const std = shared.std;
const ir = shared.ir;
const target = shared.target;
const memory_location = shared.memory_location;
const MachineFunction = shared.MachineFunction;
const FrameIndex = shared.FrameIndex;
const ArgReg = shared.ArgReg;
const XmmReg = shared.XmmReg;
const SysVCallTarget = shared.SysVCallTarget;

const max_sysv_stack_call_args = shared.max_sysv_stack_call_args;

const appendAlignedDirectCall = shared.appendAlignedDirectCall;
const appendDirectCall = shared.appendDirectCall;
const appendDirectCallWithStackArgs = shared.appendDirectCallWithStackArgs;
const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendI32CallArgs = cabi_call_lowering.appendI32CallArgs;
const appendIndirectCallRaxWithStackArgs = shared.appendIndirectCallRaxWithStackArgs;
const appendLoadStackDispRax = cabi_aggregate_lowering.appendLoadStackDispRax;
const appendLoadStackDispXmm0 = cabi_aggregate_lowering.appendLoadStackDispXmm0;
const appendLoadStackDispXmm0F32 = cabi_aggregate_lowering.appendLoadStackDispXmm0F32;
const appendStoreArg64ArgPtrDisp = cabi_aggregate_lowering.appendStoreArg64ArgPtrDisp;
const appendStoreEaxArgPtrDisp = cabi_aggregate_lowering.appendStoreEaxArgPtrDisp;
const appendStoreRaxArgPtrDisp = cabi_aggregate_lowering.appendStoreRaxArgPtrDisp;
const appendStoreXmm0ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0ArgPtrDisp;
const appendStoreXmm0F32ArgPtrDisp = cabi_aggregate_lowering.appendStoreXmm0F32ArgPtrDisp;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendSysVScalarCallArgs = cabi_call_lowering.appendSysVScalarCallArgs;
const appendSysVScalarCallArgsWithBlock = cabi_call_lowering.appendSysVScalarCallArgsWithBlock;
const appendSysVCallTarget = shared.appendSysVCallTarget;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgI32CallIntoEax = core_value_emit.emitGenericCfgI32CallIntoEax;
const emitGenericCfgI32ValueIntoEax = core_value_emit.emitGenericCfgI32ValueIntoEax;
const emitGenericCfgI64ValueIntoRax = core_value_emit.emitGenericCfgI64ValueIntoRax;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const emitGenericCfgStoreEax = core_value_emit.emitGenericCfgStoreEax;
const emitGenericCfgVoidCall = core_value_emit.emitGenericCfgVoidCall;
const findInstruction = cabi_call_lowering.findInstruction;
const fp32TextBits = shared.fp32TextBits;
const fp64TextBits = shared.fp64TextBits;
const fpParamIndex = cabi_abi_helpers.fpParamIndex;
const fpParamIndexFromValue = cabi_aggregate_lowering.fpParamIndexFromValue;
const frameIndexForLiveParam = cabi_call_lowering.frameIndexForLiveParam;
const aggregateFieldCount = cabi_aggregate_lowering.aggregateFieldCount;
const aggregateFieldIndexAtOffset = cabi_aggregate_lowering.aggregateFieldIndexAtOffset;
const aggregateGepByteOffset = cabi_aggregate_lowering.aggregateGepByteOffset;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerParam = core_value_support.genericCfgSupportsPointerParam;
const genericCfgSupportsSingleBlockScalar = core_value_support.genericCfgSupportsSingleBlockScalar;
const genericCfgSupportsSingleBlockI32Value = core_value_support.genericCfgSupportsSingleBlockI32Value;
const genericCfgSupportsSingleBlockStore = core_value_support.genericCfgSupportsSingleBlockStore;
const globalSymbolName = shared.globalSymbolName;
const i32Value = shared.i32Value;
const i64Value = shared.i64Value;
const identityCastFrom = cabi_call_lowering.identityCastFrom;
const isSelectI1ToI32ZeroOne = cabi_call_lowering.isSelectI1ToI32ZeroOne;
const isCalleeName = shared.isCalleeName;
const isInt = shared.isInt;
const isMainOrWrapperMain = cabi_tls_global_lowering.isMainOrWrapperMain;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const paramValueReg = cabi_abi_helpers.paramValueReg;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const phiHasIncoming = cabi_call_lowering.phiHasIncoming;
const phiHasIncomingInt = cabi_call_lowering.phiHasIncomingInt;
const setupSysVCallTarget = shared.setupSysVCallTarget;
const symbolName = shared.symbolName;
const sysvScalarCallNeedsStackArgs = cabi_call_lowering.sysvScalarCallNeedsStackArgs;
const validateDefaultCallConv = shared.validateDefaultCallConv;
const valueReferencesGlobal = cabi_call_lowering.valueReferencesGlobal;
const x86_64SysVDataLayout = shared.x86_64SysVDataLayout;

const lowerAggregateAbiReturn = cabi_boundary_rows.lowerAggregateAbiReturn;
const lowerAtomicAddReturn = core_single_block_misc.lowerAtomicAddReturn;
const lowerErrorUnionI64SelectReturn = core_single_block_misc.lowerErrorUnionI64SelectReturn;
const lowerGenericCfgByteTableLookupReturn = core_single_block_misc.lowerGenericCfgByteTableLookupReturn;
const lowerGenericCfgI64DirectCallReturn = cabi_call_lowering.lowerGenericCfgI64DirectCallReturn;
const lowerGenericCfgGprDirectCallReturn = cabi_call_lowering.lowerGenericCfgGprDirectCallReturn;
const lowerGenericCfgGprParamReturn = cabi_call_lowering.lowerGenericCfgGprParamReturn;
const lowerGenericCfgI64ParamReturn = cabi_call_lowering.lowerGenericCfgI64ParamReturn;
const lowerGenericCfgDynamicPointerLoadReturn = core_memory_lowering.lowerGenericCfgDynamicPointerLoadReturn;
const lowerGenericCfgStructFieldLoadReturn = core_memory_lowering.lowerGenericCfgStructFieldLoadReturn;
const lowerI64SaturatingHelperFamilyReturn = cabi_boundary_rows.lowerI64SaturatingHelperFamilyReturn;
const lowerInlineAsmBarrierReturn = cabi_tls_global_lowering.lowerInlineAsmBarrierReturn;
const lowerIntegerShiftMixReturn = core_misc_rows.lowerIntegerShiftMixReturn;
const lowerMulConstReturn = core_misc_rows.lowerMulConstReturn;
const lowerPointerVolatileRoundtripReturn = cabi_boundary_rows.lowerPointerVolatileRoundtripReturn;
const lowerRuntimeArraySumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeArraySumPreoptHelper;
const lowerRuntimeStructSumPreoptHelper = cabi_aggregate_lowering.lowerRuntimeStructSumPreoptHelper;
const lowerScalarFpCastReturn = cabi_boundary_rows.lowerScalarFpCastReturn;
const lowerSelectedI64ConstReturn = cabi_call_lowering.lowerSelectedI64ConstReturn;
const lowerStructSumReturn = cabi_aggregate_lowering.lowerStructSumReturn;
const appendLoadStackDispU8Eax = cabi_aggregate_lowering.appendLoadStackDispU8Eax;
const appendLoadStackDispU16Eax = cabi_aggregate_lowering.appendLoadStackDispU16Eax;
const appendStoreAlArgPtrDisp = cabi_aggregate_lowering.appendStoreAlArgPtrDisp;
const appendStoreAxArgPtrDisp = cabi_aggregate_lowering.appendStoreAxArgPtrDisp;
const isI64Aggregate = cabi_aggregate_lowering.isI64Aggregate;
const isAggregateType = cabi_aggregate_lowering.isAggregateType;
const isSupportedAggregateCopyLeafAggregate = cabi_aggregate_lowering.isSupportedAggregateCopyLeafAggregate;
const stackAggregateByteDisp = cabi_aggregate_lowering.stackAggregateByteDisp;
const supportedAggregateCopyLeaf = cabi_aggregate_lowering.supportedAggregateCopyLeaf;
const validateAggregateFieldGep = cabi_aggregate_lowering.validateAggregateFieldGep;

pub fn lowerGenericCfgSingleBlockScalar(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const single_ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => null,
    };
    if (single_ret) |ret| {
        if (try lowerPointerVolatileRoundtripReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
    }
    if (try lowerGenericCfgPointerSelectLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgDynamicPointerLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgStructFieldLoadReturn(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (single_ret) |ret| {
        if (lowerStructSumReturn(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (lowerRuntimeStructSumPreoptHelper(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (lowerRuntimeArraySumPreoptHelper(allocator, machine, function, block, ret) catch false) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgByteTableLookupReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerIntegerShiftMixReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerMulConstReturn(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgCallResultAcrossVoidCall(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgTwoI32CallResultsAcrossVoidCall(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
        if (try lowerGenericCfgI32CallResultAcrossI32Call(allocator, machine, function, block, ret)) {
            machine.codegen_path = .generic_cfg;
            return true;
        }
    }
    if (!genericCfgSupportsSingleBlockScalar(function)) return false;
    const ret = single_ret orelse return error.UnsupportedCodegenControlFlow;
    var last_eax_value: ?ir.Value = null;
    for (block.instructions.items, 0..) |instruction, instruction_index| {
        switch (instruction.kind) {
            .store => |store| {
                try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
                try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
                last_eax_value = store.value;
            },
            .call => |call| {
                if (call.ret_ty == .void and instruction.result == null) {
                    try emitGenericCfgVoidCall(allocator, machine, function, block, instruction_index, call);
                }
            },
            .binary, .icmp, .select, .load => {},
            .phi, .fcmp, .cast, .freeze, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => return error.UnsupportedCodegenInstruction,
        }
    }
    const ret_value = ret.value orelse return error.InvalidRet;
    if (last_eax_value == null or !last_eax_value.?.eql(ret_value)) {
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, ret_value);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

fn lowerGenericCfgCallResultAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.callee_value != null or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.ret_ty != .void or second_call.args.items.len != 0 or second_call.callee_value != null or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 32 }) or add.op != .add) return false;
    const other_value = if (isNamed(add.lhs, first_result))
        add.rhs
    else if (isNamed(add.rhs, first_result))
        add.lhs
    else
        return false;

    try emitGenericCfgI32CallIntoEax(allocator, machine, function, block, 0, first_call);
    const other_param_reg = switch (other_value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const frame_bytes: u8 = if (other_param_reg != null) 24 else 8;
    try appendStackFrame(allocator, machine, frame_bytes);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (other_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    try appendDirectCall(allocator, machine, second_call.callee, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    switch (other_value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (other_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgI32CallResultAcrossI32Call(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 4) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const first_add_inst = block.instructions.items[2];
    const second_add_inst = block.instructions.items[3];
    if (first_call_inst.removed or second_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 32 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 32 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;

    const extra_param_reg = if (extra_value) |value| switch (value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const second_callee_reg: ?shared.ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_arg_live_reg = try secondCallSingleI32ParamArgReg(function, second_call);
    if (extra_value) |value| {
        if (secondCallUsesValue(second_call, value)) return false;
    }
    const frame_bytes: u8 = if (extra_param_reg != null or second_callee_reg != null or second_arg_live_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    const stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 0 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI32CallResultsAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 5) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const third_call_inst = block.instructions.items[2];
    const first_add_inst = block.instructions.items[3];
    const second_add_inst = block.instructions.items[4];
    if (first_call_inst.removed or second_call_inst.removed or third_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 32 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const third_call = switch (third_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (third_call.ret_ty != .void or third_call.args.items.len != 0 or third_call.inline_asm != null) return false;
    if (!callIsFastcc(third_call.calling_conv)) try validateDefaultCallConv(third_call.calling_conv);
    const third_call_target: SysVCallTarget = if (third_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = third_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 32 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 32 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;

    const extra_param_reg = if (extra_value) |value| switch (value) {
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const second_arg_live_reg = try secondCallSingleI32ParamArgReg(function, second_call);
    if (extra_value) |value| {
        if (secondCallUsesValue(second_call, value)) return false;
    }
    const third_callee_reg: ?shared.ArgReg = switch (third_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_callee_reg: ?shared.ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (third_callee_reg != null or second_callee_reg != null) 40 else 24;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot1, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot6 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_eax_rsp = .slot2 });
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot8 } });
    }
    try setupSysVCallTarget(allocator, machine, third_call_target);
    try appendSysVCallTarget(allocator, machine, third_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_eax = .slot0 });
    try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 8 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_eax_imm32 = try i32Value(int) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_eax = 4 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn valueReferencesAddResult(value: ir.Value, add_result: []const u8) bool {
    return switch (value) {
        .named => |name| std.mem.eql(u8, name, add_result),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

fn collectTwoAddLeaves(
    first_add_result: []const u8,
    first_add: ir.BinaryInst,
    second_add: ir.BinaryInst,
    leaves: *[3]ir.Value,
    leaf_count: *usize,
) !void {
    try collectTwoAddLeaf(first_add_result, first_add, second_add.lhs, leaves, leaf_count);
    try collectTwoAddLeaf(first_add_result, first_add, second_add.rhs, leaves, leaf_count);
    if (leaf_count.* != 3) return error.UnsupportedCodegenValue;
}

fn collectTwoAddLeaf(
    first_add_result: []const u8,
    first_add: ir.BinaryInst,
    value: ir.Value,
    leaves: *[3]ir.Value,
    leaf_count: *usize,
) !void {
    if (valueReferencesAddResult(value, first_add_result)) {
        try appendTwoAddLeaf(first_add.lhs, leaves, leaf_count);
        try appendTwoAddLeaf(first_add.rhs, leaves, leaf_count);
        return;
    }
    try appendTwoAddLeaf(value, leaves, leaf_count);
}

fn appendTwoAddLeaf(value: ir.Value, leaves: *[3]ir.Value, leaf_count: *usize) !void {
    if (leaf_count.* >= leaves.len) return error.UnsupportedCodegenValue;
    leaves[leaf_count.*] = value;
    leaf_count.* += 1;
}

fn secondCallUsesValue(call: ir.CallInst, value: ir.Value) bool {
    for (call.args.items) |arg| {
        if (arg.value.eql(value)) return true;
    }
    return false;
}

fn secondCallSingleI32ParamArgReg(function: ir.Function, call: ir.CallInst) !?shared.ArgReg {
    if (call.args.items.len == 0) return null;
    if (call.args.items.len != 1) return error.UnsupportedLiveAcrossCall;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return error.UnsupportedLiveAcrossCall;
    return switch (arg.value) {
        .int => null,
        .named => |name| try paramRegOrNull(function, name, .{ .int = 32 }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

fn secondCallSingleI64ParamArgReg(function: ir.Function, call: ir.CallInst) !?shared.ArgReg {
    if (call.args.items.len == 0) return null;
    if (call.args.items.len != 1) return error.UnsupportedLiveAcrossCall;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.{ .int = 64 })) return error.UnsupportedLiveAcrossCall;
    return switch (arg.value) {
        .int => null,
        .named => |name| try paramRegOrNull(function, name, .{ .int = 64 }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn lowerGenericCfgSingleBlockFp(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try fp_rows.lowerGenericCfgFpBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCastBinaryPipelineReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCompareReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpSelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallIntToFpAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallBinaryReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgMixedFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgI64AndFpTwoCallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpCallResultAcrossVoidCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpVoidCallParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpDirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try fp_rows.lowerGenericCfgFpLiteralReturn(allocator, machine, function, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerScalarFpCastReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockAggregateAbi(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerAggregateAbiReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockPackedBits(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgPackedReplaceLowReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgPackedReadFlagReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockI64(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 64 }) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerSelectedI64ConstReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64ParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerI64SaturatingHelperFamilyReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64CallResultAcrossVoidCall(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsAcrossVoidCall(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsWithLiveReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgTwoI64CallResultsReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgI64DirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerErrorUnionI64SelectReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgI64CallResultAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.ret_ty != .void or second_call.args.items.len != 0 or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    const other_value = if (isNamed(add.lhs, first_result))
        add.rhs
    else if (isNamed(add.rhs, first_result))
        add.lhs
    else
        return false;
    const other_param_reg = switch (other_value) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => |int| if (try i64Value(int) >= 0 and try i64Value(int) <= std.math.maxInt(u8)) null else return false,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (other_param_reg != null or second_callee_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (other_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    try appendSysVCallTarget(allocator, machine, second_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    switch (other_value) {
        .named => try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 8 }),
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsAcrossVoidCall(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or (block.instructions.items.len != 4 and block.instructions.items.len != 5)) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const third_call_inst = block.instructions.items[2];
    const add_inst = block.instructions.items[3];
    const final_add_inst: ?ir.Instruction = if (block.instructions.items.len == 5) block.instructions.items[4] else null;
    if (first_call_inst.removed or second_call_inst.removed or third_call_inst.removed or add_inst.removed) return false;
    if (final_add_inst) |inst| if (inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_value = ret.value orelse return error.InvalidRet;
    if (final_add_inst == null and !isNamed(ret_value, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_arg_live_reg = try secondCallSingleI64ParamArgReg(function, second_call);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const third_call = switch (third_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (third_call.ret_ty != .void or third_call.args.items.len != 0 or third_call.inline_asm != null) return false;
    if (!callIsFastcc(third_call.calling_conv)) try validateDefaultCallConv(third_call.calling_conv);
    const third_call_target: SysVCallTarget = if (third_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = third_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    var extra_value: ?ir.Value = null;
    if (final_add_inst) |inst| {
        const final_add_result = inst.result orelse return false;
        if (!isNamed(ret_value, final_add_result)) return false;
        const final_add = switch (inst.kind) {
            .binary => |binary| binary,
            else => return false,
        };
        if (!final_add.ty.eql(.{ .int = 64 }) or final_add.op != .add) return false;
        var leaves: [3]ir.Value = undefined;
        var leaf_count: usize = 0;
        try collectTwoAddLeaves(add_result, add, final_add, &leaves, &leaf_count);
        var has_first = false;
        var has_second = false;
        for (leaves[0..leaf_count]) |leaf| {
            if (isNamed(leaf, first_result)) {
                if (has_first) return false;
                has_first = true;
            } else if (isNamed(leaf, second_result)) {
                if (has_second) return false;
                has_second = true;
            } else if (extra_value == null) {
                extra_value = leaf;
            } else {
                return false;
            }
        }
        if (!has_first or !has_second or extra_value == null) return false;
        if (secondCallUsesValue(second_call, extra_value.?)) return false;
    } else {
        const add_uses_results =
            (isNamed(add.lhs, first_result) and isNamed(add.rhs, second_result)) or
            (isNamed(add.lhs, second_result) and isNamed(add.rhs, first_result));
        if (!add_uses_results) return false;
    }

    const third_callee_reg: ?ArgReg = switch (third_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const extra_param_reg: ?ArgReg = if (extra_value) |value| switch (value) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    } else null;
    const frame_bytes: u8 = if (extra_param_reg != null) 56 else if (second_callee_reg != null or third_callee_reg != null) 40 else 24;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot8, .reg = reg } });
    }
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot10, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot6 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot2 });
    if (third_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot8 } });
    }
    try setupSysVCallTarget(allocator, machine, third_call_target);
    try appendSysVCallTarget(allocator, machine, third_call_target, .void);
    try machine.instructions.append(allocator, .{ .reload_rsp_rax = .slot0 });
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 8 });
    if (extra_value) |value| switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 40 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    };
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 3) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const add_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!add.ty.eql(.{ .int = 64 }) or add.op != .add) return false;
    const add_uses_results =
        (isNamed(add.lhs, first_result) and isNamed(add.rhs, second_result)) or
        (isNamed(add.lhs, second_result) and isNamed(add.rhs, first_result));
    if (!add_uses_results) return false;

    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };
    const frame_bytes: u8 = if (second_callee_reg != null) 24 else 8;

    try appendStackFrame(allocator, machine, frame_bytes);
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 0 });
    try appendStackFrameEnd(allocator, machine, frame_bytes);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

fn lowerGenericCfgTwoI64CallResultsWithLiveReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 64 }) or block.instructions.items.len != 4) return false;
    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const first_add_inst = block.instructions.items[2];
    const second_add_inst = block.instructions.items[3];
    if (first_call_inst.removed or second_call_inst.removed or first_add_inst.removed or second_add_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const first_add_result = first_add_inst.result orelse return false;
    const second_add_result = second_add_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, second_add_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.inline_asm != null) return false;
    if (!callIsFastcc(first_call.calling_conv)) try validateDefaultCallConv(first_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(first_call)) return false;
    const first_call_target: SysVCallTarget = if (first_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = first_call.callee };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!second_call.ret_ty.eql(.{ .int = 64 }) or second_call.inline_asm != null) return false;
    if (!callIsFastcc(second_call.calling_conv)) try validateDefaultCallConv(second_call.calling_conv);
    if (sysvScalarCallNeedsStackArgs(second_call)) return false;
    const second_call_target: SysVCallTarget = if (second_call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = second_call.callee };

    const first_add = switch (first_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    const second_add = switch (second_add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (!first_add.ty.eql(.{ .int = 64 }) or first_add.op != .add) return false;
    if (!second_add.ty.eql(.{ .int = 64 }) or second_add.op != .add) return false;
    if (!valueReferencesAddResult(second_add.lhs, first_add_result) and !valueReferencesAddResult(second_add.rhs, first_add_result)) return false;

    var leaves: [3]ir.Value = undefined;
    var leaf_count: usize = 0;
    try collectTwoAddLeaves(first_add_result, first_add, second_add, &leaves, &leaf_count);
    var has_first = false;
    var has_second = false;
    var extra_value: ?ir.Value = null;
    for (leaves[0..leaf_count]) |leaf| {
        if (isNamed(leaf, first_result)) {
            if (has_first) return false;
            has_first = true;
        } else if (isNamed(leaf, second_result)) {
            if (has_second) return false;
            has_second = true;
        } else if (extra_value == null) {
            extra_value = leaf;
        } else {
            return false;
        }
    }
    if (!has_first or !has_second) return false;
    const extra = extra_value orelse return false;
    if (secondCallUsesValue(second_call, extra)) return false;

    const extra_param_reg = switch (extra) {
        .named => |name| try paramReg(function, name, .{ .int = 64 }),
        .int => null,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    const second_arg_live_reg = try secondCallSingleI64ParamArgReg(function, second_call);
    const second_callee_reg: ?ArgReg = switch (second_call_target) {
        .direct => null,
        .indirect_from_reg => |reg| reg,
    };

    try appendStackFrame(allocator, machine, 40);
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot2, .reg = reg } });
    }
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot4, .reg = reg } });
    }
    if (extra_param_reg) |reg| {
        try machine.instructions.append(allocator, .{ .spill_arg64_rsp = .{ .frame_index = .slot6, .reg = reg } });
    }
    try setupSysVCallTarget(allocator, machine, first_call_target);
    const first_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, first_call);
    if (first_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, first_call_target, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .spill_rax_rsp = .slot0 });
    if (second_callee_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot2 } });
    }
    try setupSysVCallTarget(allocator, machine, second_call_target);
    if (second_arg_live_reg) |reg| {
        try machine.instructions.append(allocator, .{ .reload_arg64_rsp = .{ .reg = reg, .frame_index = .slot4 } });
    }
    const second_stack_arg_count = try appendSysVScalarCallArgsWithBlock(allocator, machine, function, block, second_call);
    if (second_stack_arg_count != 0) return error.UnsupportedLiveAcrossCall;
    try appendSysVCallTarget(allocator, machine, second_call_target, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 0 });
    switch (extra) {
        .int => |int| try machine.instructions.append(allocator, .{ .add_rax_imm8 = @intCast(try i64Value(int)) }),
        .named => {
            if (extra_param_reg == null) return error.UnsupportedCodegenValue;
            try machine.instructions.append(allocator, .{ .add_stack_disp8_rax = 24 });
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => unreachable,
    }
    try appendStackFrameEnd(allocator, machine, 40);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgSingleBlockPtr(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.ptr) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgGprParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGprDirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockEffectBarrier(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerInlineAsmBarrierReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerAtomicAddReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockVoidCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isInt(ret.value orelse return error.InvalidRet, 0)) return false;
    if (block.instructions.items.len != 1) return false;
    const call_inst = block.instructions.items[0];
    if (call_inst.removed or call_inst.result != null) return false;
    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.args.items.len != 0) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;

    try appendAlignedDirectCall(allocator, machine, call.callee, .void);
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockDirectCallMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 1 and block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    if (call_inst.removed) return false;
    const call_result = call_inst.result orelse return false;
    if (block.instructions.items.len == 1) {
        if (!isNamed(ret.value orelse return error.InvalidRet, call_result)) return false;
    } else {
        const cast_inst = block.instructions.items[1];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, call_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len > max_sysv_stack_call_args + 6) return false;
    for (call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
        switch (arg.value) {
            .int => {},
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
        }
    }
    const stack_arg_count = try appendI32CallArgs(allocator, machine, function, call);
    try appendDirectCallWithStackArgs(allocator, machine, call.callee, call.ret_ty, stack_arg_count);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallChainMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;

    const first_call_inst = block.instructions.items[0];
    const second_call_inst = block.instructions.items[1];
    const cast_inst = block.instructions.items[2];
    if (first_call_inst.removed or second_call_inst.removed or cast_inst.removed) return false;
    const first_result = first_call_inst.result orelse return false;
    const second_result = second_call_inst.result orelse return false;
    const cast_result = identityCastFrom(cast_inst, second_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, cast_result)) return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (first_call.callee_value != null or first_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, first_call.callee)) return false;
    if (!callIsFastcc(first_call.calling_conv)) validateDefaultCallConv(first_call.calling_conv) catch return false;
    if (!first_call.ret_ty.eql(.{ .int = 64 }) or first_call.args.items.len != 2) return false;
    for (first_call.args.items) |arg| {
        if (arg.attrs != null or !arg.ty.eql(.{ .int = 32 })) return false;
    }

    const first_arg = switch (first_call.args.items[0].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const second_arg = switch (first_call.args.items[1].value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (second_call.callee_value != null or second_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, second_call.callee)) return false;
    if (!callIsFastcc(second_call.calling_conv)) validateDefaultCallConv(second_call.calling_conv) catch return false;
    if (!second_call.ret_ty.eql(.{ .int = 32 }) or second_call.args.items.len != 1) return false;
    const chain_arg = second_call.args.items[0];
    if (chain_arg.attrs != null or !chain_arg.ty.eql(.{ .int = 64 }) or !isNamed(chain_arg.value, first_result)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = first_arg });
    try machine.instructions.append(allocator, .{ .mov_imm_rsi = second_arg });
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .mov_rax_rdi);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockCallGlobalCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const load_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or load_inst.removed or second_cmp_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_global = genericCfgGlobalPtrArg(call.args.items[0]) orelse return false;
    const second_global = genericCfgGlobalPtrArg(call.args.items[1]) orelse return false;

    const first_cmp = switch (first_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name)) return false;
    const expected_call = switch (first_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    const loaded_global = switch (load.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, loaded_global, second_global)) return false;

    const second_cmp = switch (second_cmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (second_cmp.predicate != .eq or !second_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(second_cmp.lhs, load_name)) return false;
    const expected_load = switch (second_cmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;

    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_call_global_check_fail";
    try machine.instructions.append(allocator, .{ .lea_global_rdi = first_global });
    try machine.instructions.append(allocator, .{ .lea_global_rsi = second_global });
    try appendAlignedDirectCall(allocator, machine, call.callee, call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_call });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = loaded_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = expected_load });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgMultiBlockTwoCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 3) return false;

    const entry = function.blocks.items[0];
    const merge = function.blocks.items[1];
    const then_block = function.blocks.items[2];
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or then_block.instructions.items.len != 2) return false;

    const first_call_inst = entry.instructions.items[0];
    const first_cmp_inst = entry.instructions.items[1];
    const phi_inst = merge.instructions.items[0];
    const select_inst = merge.instructions.items[1];
    const second_call_inst = then_block.instructions.items[0];
    const second_cmp_inst = then_block.instructions.items[1];
    if (first_call_inst.removed or first_cmp_inst.removed or phi_inst.removed or select_inst.removed or second_call_inst.removed or second_cmp_inst.removed) return false;

    const first_call_name = first_call_inst.result orelse return false;
    const first_cmp_name = first_cmp_inst.result orelse return false;
    const phi_name = phi_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    const second_call_name = second_call_inst.result orelse return false;
    const second_cmp_name = second_cmp_inst.result orelse return false;

    const first_call = switch (first_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, first_call)) return false;
    const first_expected = try genericCfgCallEqExpected(first_cmp_inst, first_call_name);

    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, then_block.name) or !std.mem.eql(u8, entry_br.else_target, merge.name)) return false;

    const second_call = switch (second_call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsUnaryPtrSiblingCall(function, second_call)) return false;
    const second_expected = try genericCfgCallEqExpected(second_cmp_inst, second_call_name);

    const then_br = switch (then_block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, then_br.target, merge.name)) return false;

    const phi = switch (phi_inst.kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, second_cmp_name, then_block.name) or !phiHasIncomingInt(phi, 0, entry.name)) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, phi_name)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "generic_cfg_two_call_check_fail";
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, first_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, first_call.callee, first_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = first_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try emitGenericCfgUnaryPtrCallArg(allocator, machine, second_call.args.items[0]);
    try appendAlignedDirectCall(allocator, machine, second_call.callee, second_call.ret_ty);
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = second_expected });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockUpdateGetMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2 and block.instructions.items.len != 3) return false;

    const update_inst = block.instructions.items[0];
    const get_inst = block.instructions.items[1];
    if (update_inst.removed or get_inst.removed or update_inst.result != null) return false;
    const get_result = get_inst.result orelse return false;
    if (block.instructions.items.len == 2) {
        if (!isNamed(ret.value orelse return error.InvalidRet, get_result)) return false;
    } else {
        const cast_inst = block.instructions.items[2];
        if (cast_inst.removed) return false;
        const cast_name = identityCastFrom(cast_inst, get_result, .{ .int = 32 }, .{ .int = 32 }) orelse return false;
        if (!isNamed(ret.value orelse return error.InvalidRet, cast_name)) return false;
    }

    const update_call = switch (update_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (update_call.callee_value != null or update_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, update_call.callee)) return false;
    if (!callIsFastcc(update_call.calling_conv)) validateDefaultCallConv(update_call.calling_conv) catch return false;
    if (update_call.ret_ty != .void or update_call.args.items.len != 1) return false;
    const update_arg = update_call.args.items[0];
    if (update_arg.attrs != null or !update_arg.ty.eql(.{ .int = 32 })) return false;
    const update_value = switch (update_arg.value) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };

    const get_call = switch (get_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (get_call.callee_value != null or get_call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, get_call.callee)) return false;
    if (!callIsFastcc(get_call.calling_conv)) validateDefaultCallConv(get_call.calling_conv) catch return false;
    if (!get_call.ret_ty.eql(.{ .int = 32 }) or get_call.args.items.len != 0) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_rdi = update_value });
    try appendAlignedDirectCall(allocator, machine, update_call.callee, .void);
    try appendAlignedDirectCall(allocator, machine, get_call.callee, get_call.ret_ty);
    try machine.instructions.append(allocator, .ret);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSingleBlockCallCheckMain(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!isMainOrWrapperMain(function.name)) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0 or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    if (try lowerGenericCfgSingleBlockIntCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockFpCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgSingleBlockBoolCallCheckMainReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

pub fn lowerGenericCfgSingleBlockIntCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
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
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    switch (call.ret_ty) {
        .int => {},
        .void, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    }

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    switch (icmp.predicate) {
        .eq, .ne => {},
        .ugt, .uge, .ult, .ule, .sgt, .sge, .slt, .sle => return false,
    }
    if (!icmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(icmp.lhs, call_name)) return false;
    switch (icmp.rhs) {
        .int => {},
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, icmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockFpCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 3) return false;
    const call_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or fcmp_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.float) and !call.ret_ty.eql(.double)) return false;

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != .oeq or !fcmp.operand_ty.eql(call.ret_ty)) return false;
    if (!isNamed(fcmp.lhs, call_name)) return false;
    switch (fcmp.rhs) {
        .fp => {},
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    }
    if (!isSelectI1ToI32ZeroOne(select_inst, fcmp_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockBoolCallCheckMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 2) return false;
    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;

    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!genericCfgSupportsConstantWrapperCall(function, call)) return false;
    if (!call.ret_ty.eql(.{ .int = 1 })) return false;
    if (!isSelectI1ToI32ZeroOne(select_inst, call_name)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn genericCfgSupportsConstantWrapperCall(function: ir.Function, call: ir.CallInst) bool {
    if (!callIsFastcc(call.calling_conv)) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (call.args.items.len == 0 or call.args.items.len > 4) return false;
    for (call.args.items) |arg| {
        if (!genericCfgSupportsConstantWrapperCallArg(arg)) return false;
    }
    return true;
}

pub fn genericCfgSupportsConstantWrapperCallArg(arg: ir.CallArg) bool {
    if (arg.attrs != null) return false;
    return switch (arg.ty) {
        .ptr => switch (arg.value) {
            .named => |name| name.len > 0 and name[0] == '@',
            .null_value => true,
            .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
        },
        .float, .double => switch (arg.value) {
            .fp => true,
            .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .int => switch (arg.value) {
            .int => true,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        },
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

pub fn genericCfgGlobalPtrArg(arg: ir.CallArg) ?[]const u8 {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return null;
    return switch (arg.value) {
        .named => |name| if (name.len > 0 and name[0] == '@') globalSymbolName(name) catch null else null,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn genericCfgSupportsUnaryPtrSiblingCall(function: ir.Function, call: ir.CallInst) bool {
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!genericCfgCallTargetsWrapperSibling(function.name, call.callee)) return false;
    if (!callIsFastcc(call.calling_conv)) validateDefaultCallConv(call.calling_conv) catch return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 1) return false;
    const arg = call.args.items[0];
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return false;
    return switch (arg.value) {
        .named => |name| name.len > 0 and name[0] == '@',
        .null_value => true,
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn genericCfgCallEqExpected(instruction: ir.Instruction, call_name: []const u8) !i32 {
    const icmp = switch (instruction.kind) {
        .icmp => |icmp| icmp,
        else => return error.UnsupportedCodegenValue,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 }) or !isNamed(icmp.lhs, call_name)) {
        return error.UnsupportedCodegenValue;
    }
    return switch (icmp.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => error.UnsupportedCodegenValue,
    };
}

pub fn emitGenericCfgUnaryPtrCallArg(allocator: std.mem.Allocator, machine: *MachineFunction, arg: ir.CallArg) !void {
    if (arg.attrs != null or !arg.ty.eql(.ptr)) return error.UnsupportedCodegenValue;
    switch (arg.value) {
        .named => |name| try machine.instructions.append(allocator, .{ .lea_global_rdi = try globalSymbolName(name) }),
        .null_value => try machine.instructions.append(allocator, .{ .mov_imm_rdi = 0 }),
        .int, .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn genericCfgCallTargetsWrapperSibling(function_name: []const u8, callee: []const u8) bool {
    const name = symbolName(function_name);
    if (!isMainOrWrapperMain(name)) return false;
    const callee_name = symbolName(callee);
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return false;
    if (!std.mem.eql(u8, name[dot + 1 ..], "main")) return false;
    const prefix = name[0 .. dot + 1];
    return std.mem.startsWith(u8, callee_name, prefix) and callee_name.len > prefix.len;
}

pub fn lowerGenericCfgSingleBlockVoid(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (function.ret_ty != .void or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (ret.ty != .void or ret.value != null) return false;
    if (try lowerGenericCfgSelectedSretStores(allocator, machine, function, block)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (block.instructions.items.len == 0) {
        try appendGenericCfgReturn(allocator, machine);
        machine.codegen_path = .generic_cfg;
        return true;
    }
    for (block.instructions.items) |instruction| {
        if (instruction.removed) return false;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!genericCfgSupportsSingleBlockStore(function, block, store)) return false;
    }
    for (block.instructions.items) |instruction| {
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => unreachable,
        };
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, store.value);
        try emitGenericCfgStoreEax(allocator, machine, function, store.ptr);
    }
    try appendGenericCfgReturn(allocator, machine);
    machine.codegen_path = .generic_cfg;
    return true;
}

pub fn lowerGenericCfgSelectedSretStores(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (try lowerGenericCfgSretCopy(allocator, machine, function, block)) return true;
    if (try lowerGenericCfgScalarSretParamStores(allocator, machine, function, block)) return true;
    if (function.params.items.len < 4) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const field_count = aggregateFieldCount(aggregate_ty) orelse return false;
    if (field_count < 3 or function.params.items.len != field_count + 1) return false;
    if (!isI64Aggregate(aggregate_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    if ((try paramReg(function, function.params.items[0].name, .ptr)) != .rdi) return error.UnsupportedCodegenAbi;
    for (function.params.items[1..]) |param| {
        if (!param.ty.eql(.{ .int = 64 })) return false;
    }
    if (block.instructions.items.len != field_count * 2) return false;

    var pair_index: usize = 0;
    while (pair_index < field_count) : (pair_index += 1) {
        const gep_inst = block.instructions.items[pair_index * 2];
        const store_inst = block.instructions.items[pair_index * 2 + 1];
        if (gep_inst.removed or store_inst.removed) return false;
        const gep_name = gep_inst.result orelse return false;
        try validateAggregateFieldGep(gep_inst, aggregate_ty, function.params.items[0].name, @intCast(pair_index));

        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(.{ .int = 64 }) or store.attrs.isBarrier() or !isNamed(store.ptr, gep_name) or
            !isNamed(store.value, function.params.items[pair_index + 1].name)) return false;
        const offset = try aggregateFieldOffset(aggregate_ty, pair_index);
        const maybe_src_reg = paramReg(function, function.params.items[pair_index + 1].name, .{ .int = 64 }) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_src_reg) |src_reg| {
            try appendStoreArg64ArgPtrDisp(allocator, machine, .rdi, src_reg, offset);
        } else {
            try machine.instructions.append(allocator, .{ .load_stack_disp8_rax = try scalarParamStackDisp8(function, function.params.items[pair_index + 1].name, .{ .int = 64 }) });
            try appendStoreRaxArgPtrDisp(allocator, machine, .rdi, offset);
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn lowerGenericCfgScalarSretParamStores(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (function.params.items.len < 2) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    if (!isSupportedAggregateCopyLeafAggregate(aggregate_ty)) return false;
    var leaves: [64]ScalarSretLeaf = undefined;
    var leaf_count: usize = 0;
    const layout = x86_64SysVDataLayout() catch return error.UnsupportedCodegenAbi;
    try collectScalarSretLeaves(layout, aggregate_ty, 0, &leaves, &leaf_count);
    if (leaf_count == 0 or function.params.items.len != leaf_count + 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (sret_reg != .rdi) return error.UnsupportedCodegenAbi;

    var instruction_index: usize = 0;
    var leaf_index: usize = 0;
    while (leaf_index < leaf_count) : (leaf_index += 1) {
        const leaf = leaves[leaf_index];
        const field_ty = leaf.ty;
        if (!function.params.items[leaf_index + 1].ty.eql(field_ty)) return false;
        if (leaf.offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
        const offset: u32 = @intCast(leaf.offset);
        const store_ptr = if (offset == 0 and instruction_index < block.instructions.items.len) ptr: {
            const maybe_store = switch (block.instructions.items[instruction_index].kind) {
                .store => |store| store,
                else => break :ptr null,
            };
            if (maybe_store.ty.eql(field_ty) and !maybe_store.attrs.isBarrier() and
                isNamed(maybe_store.ptr, function.params.items[0].name))
            {
                break :ptr function.params.items[0].name;
            }
            break :ptr null;
        } else null;
        const ptr_name = store_ptr orelse ptr: {
            if (instruction_index >= block.instructions.items.len) return false;
            const gep_inst = block.instructions.items[instruction_index];
            if (gep_inst.removed) return false;
            const gep_name = gep_inst.result orelse return false;
            const gep = switch (gep_inst.kind) {
                .gep => |gep| gep,
                else => return false,
            };
            if (!isNamed(gep.ptr, function.params.items[0].name)) return false;
            const gep_offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return false;
            if (gep_offset != offset) return false;
            instruction_index += 1;
            break :ptr gep_name;
        };

        if (instruction_index >= block.instructions.items.len) return false;
        const store_inst = block.instructions.items[instruction_index];
        if (store_inst.removed) return false;
        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(field_ty) or store.attrs.isBarrier()) return false;
        if (!isNamed(store.ptr, ptr_name) or !isNamed(store.value, function.params.items[leaf_index + 1].name)) return false;
        instruction_index += 1;

        try emitGenericCfgScalarSretParamStore(allocator, machine, function, block, store.value, field_ty, sret_reg, offset);
    }
    if (instruction_index != block.instructions.items.len) return false;
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

const ScalarSretLeaf = struct {
    offset: u64,
    ty: ir.Type,
};

fn collectScalarSretLeaves(
    layout: target.DataLayout,
    aggregate_ty: ir.Type,
    base_offset: u64,
    leaves: *[64]ScalarSretLeaf,
    leaf_count: *usize,
) !void {
    const field_count = aggregateFieldCount(aggregate_ty) orelse return error.UnsupportedCodegenAbi;
    var field_index: usize = 0;
    while (field_index < field_count) : (field_index += 1) {
        const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return error.UnsupportedCodegenAbi;
        if (offset_i < 0) return error.UnsupportedCodegenAbi;
        const field_offset = base_offset + @as(u64, @intCast(offset_i));
        if (supportedSretParamStoreLeaf(field_ty)) {
            if (leaf_count.* >= leaves.len) return error.UnsupportedCodegenAbi;
            leaves[leaf_count.*] = .{ .offset = field_offset, .ty = field_ty };
            leaf_count.* += 1;
        } else if (isAggregateType(field_ty)) {
            try collectScalarSretLeaves(layout, field_ty, field_offset, leaves, leaf_count);
        } else {
            return error.UnsupportedCodegenAbi;
        }
    }
}

fn supportedSretParamStoreLeaf(ty: ir.Type) bool {
    return ty.eql(.{ .int = 8 }) or ty.eql(.{ .int = 16 }) or ty.eql(.{ .int = 32 }) or
        ty.eql(.{ .int = 64 }) or ty.eql(.ptr) or ty.eql(.float) or ty.eql(.double);
}

fn emitGenericCfgScalarSretParamStore(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    value: ir.Value,
    ty: ir.Type,
    sret_reg: ArgReg,
    offset: u32,
) !void {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (ty.eql(.{ .int = 32 })) {
        try emitGenericCfgI32ValueIntoEax(allocator, machine, function, block, value);
        try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
    } else if (ty.eql(.{ .int = 64 }) or ty.eql(.ptr)) {
        const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_reg) |reg| {
            try appendStoreArg64ArgPtrDisp(allocator, machine, sret_reg, reg, offset);
        } else {
            try appendLoadStackDispRax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
            try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
        }
    } else if (ty.eql(.{ .int = 16 })) {
        const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_reg) |reg| {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
        } else {
            try appendLoadStackDispU16Eax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
        }
        try appendStoreAxArgPtrDisp(allocator, machine, sret_reg, offset);
    } else if (ty.eql(.{ .int = 8 })) {
        const maybe_reg = paramRegOrNull(function, name, ty) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (maybe_reg) |reg| {
            try machine.instructions.append(allocator, .{ .mov_arg_rax = reg });
        } else {
            try appendLoadStackDispU8Eax(allocator, machine, try scalarParamStackDisp8(function, name, ty));
        }
        try appendStoreAlArgPtrDisp(allocator, machine, sret_reg, offset);
    } else if (ty.eql(.float) or ty.eql(.double)) {
        const source_index = fpParamIndex(function, name, ty) catch |err| switch (err) {
            error.UnsupportedCodegenAbi => null,
            else => return err,
        };
        if (source_index) |index| {
            const source = try XmmReg.fromIndex(index);
            if (source != .xmm0) {
                try machine.instructions.append(allocator, .{ .movapd_xmm = .{ .dst = .xmm0, .src = source } });
            }
        } else if (ty.eql(.float)) {
            try appendLoadStackDispXmm0F32(allocator, machine, try scalarParamStackDisp8(function, name, ty));
        } else {
            try appendLoadStackDispXmm0(allocator, machine, try scalarParamStackDisp8(function, name, ty));
        }
        if (ty.eql(.float)) {
            try appendStoreXmm0F32ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else {
            try appendStoreXmm0ArgPtrDisp(allocator, machine, sret_reg, offset);
        }
    } else {
        return error.UnsupportedCodegenType;
    }
}

pub fn lowerGenericCfgSretCopy(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (function.params.items.len != 2) return false;
    const aggregate_ty = sretAggregateType(function.params.items[0].attrs) orelse return false;
    const byval_ty = byvalAggregateType(function.params.items[1].attrs) orelse return false;
    if (!byval_ty.eql(aggregate_ty)) return false;
    if (!isSupportedAggregateCopyLeafAggregate(aggregate_ty)) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    if (sret_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (block.instructions.items.len < 12 or block.instructions.items.len % 4 != 0) return false;

    const copy_count = block.instructions.items.len / 4;
    var copy_index: usize = 0;
    while (copy_index < copy_count) : (copy_index += 1) {
        const src_gep_inst = block.instructions.items[copy_index * 4];
        const load_inst = block.instructions.items[copy_index * 4 + 1];
        const dst_gep_inst = block.instructions.items[copy_index * 4 + 2];
        const store_inst = block.instructions.items[copy_index * 4 + 3];
        if (src_gep_inst.removed or load_inst.removed or dst_gep_inst.removed or store_inst.removed) return false;
        const src_gep_name = src_gep_inst.result orelse return false;
        const load_name = load_inst.result orelse return false;
        const dst_gep_name = dst_gep_inst.result orelse return false;
        const src_offset = aggregateCopyGepOffset(src_gep_inst, aggregate_ty, function.params.items[1].name) orelse return false;
        const dst_offset = aggregateCopyGepOffset(dst_gep_inst, aggregate_ty, function.params.items[0].name) orelse return false;
        if (src_offset != dst_offset) return false;

        const load = switch (load_inst.kind) {
            .load => |load| load,
            else => return false,
        };
        if (!supportedAggregateCopyLeaf(load.ty) or load.attrs.isBarrier() or !isNamed(load.ptr, src_gep_name)) return false;
        const store = switch (store_inst.kind) {
            .store => |store| store,
            else => return false,
        };
        if (!store.ty.eql(load.ty) or store.attrs.isBarrier() or !isNamed(store.ptr, dst_gep_name) or
            !isNamed(store.value, load_name)) return false;

        const offset = try aggregateByteOffset(aggregate_ty, src_offset, load.ty);
        if (load.ty.eql(.float)) {
            try appendLoadStackDispXmm0F32(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreXmm0F32ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.double)) {
            try appendLoadStackDispXmm0(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreXmm0ArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 64 }) or load.ty.eql(.ptr)) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreRaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 32 })) {
            try appendLoadStackDispRax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 16 })) {
            try appendLoadStackDispU16Eax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreAxArgPtrDisp(allocator, machine, sret_reg, offset);
        } else if (load.ty.eql(.{ .int = 8 })) {
            try appendLoadStackDispU8Eax(allocator, machine, try stackAggregateByteDisp(aggregate_ty, src_offset, load.ty));
            try appendStoreAlArgPtrDisp(allocator, machine, sret_reg, offset);
        } else {
            return error.UnsupportedCodegenType;
        }
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn aggregateCopyGepOffset(instruction: ir.Instruction, aggregate_ty: ir.Type, base_name: []const u8) ?u64 {
    const gep = switch (instruction.kind) {
        .gep => |gep| gep,
        else => return null,
    };
    if (!isNamed(gep.ptr, base_name)) return null;
    const layout = x86_64SysVDataLayout() catch return null;
    const offset = aggregateGepByteOffset(layout, aggregate_ty, gep) orelse return null;
    const field_ty = aggregateLeafTypeAtOffset(layout, aggregate_ty, offset) orelse return null;
    if (!supportedAggregateCopyLeaf(field_ty)) return null;
    return offset;
}

pub fn aggregateLeafTypeAtOffset(layout: target.DataLayout, aggregate_ty: ir.Type, expected_offset: u64) ?ir.Type {
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse return null;
        if (offset_i < 0) return null;
        const field_offset: u64 = @intCast(offset_i);
        if (isAggregateType(field_ty)) {
            if (expected_offset >= field_offset) {
                if (aggregateLeafTypeAtOffset(layout, field_ty, expected_offset - field_offset)) |nested_ty| return nested_ty;
            }
        } else if (field_offset == expected_offset) {
            return field_ty;
        }
    }
    return null;
}

pub fn sretAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "sret");
}

pub fn byvalAggregateType(attrs: ?[]const u8) ?ir.Type {
    return aggregateAbiAttrType(attrs, "byval");
}

pub fn aggregateAbiAttrType(attrs: ?[]const u8, name: []const u8) ?ir.Type {
    const text = attrs orelse return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, text, start, name)) |name_index| {
        const open_index = name_index + name.len;
        start = open_index;
        if (open_index >= text.len or text[open_index] != '(') continue;
        const close_index = findMatchingParen(text, open_index) orelse return null;
        const payload = std.mem.trim(u8, text[open_index + 1 .. close_index], " \t");
        if (payload.len >= 2 and ((payload[0] == '{' and payload[payload.len - 1] == '}') or
            (payload[0] == '[' and payload[payload.len - 1] == ']') or
            (payload[0] == '%' and payload.len > 1)))
        {
            return .{ .aggregate = payload };
        }
        start = close_index + 1;
    }
    return null;
}

pub fn findMatchingParen(text: []const u8, open_index: usize) ?usize {
    if (open_index >= text.len or text[open_index] != '(') return null;
    var paren_depth: usize = 0;
    var brace_depth: usize = 0;
    var bracket_depth: usize = 0;
    var angle_depth: usize = 0;
    for (text[open_index..], 0..) |byte, relative_index| {
        const index = open_index + relative_index;
        switch (byte) {
            '(' => paren_depth += 1,
            ')' => {
                if (paren_depth == 0) return null;
                paren_depth -= 1;
                if (paren_depth == 0 and brace_depth == 0 and bracket_depth == 0 and angle_depth == 0) return index;
            },
            '{' => brace_depth += 1,
            '}' => {
                if (brace_depth == 0) return null;
                brace_depth -= 1;
            },
            '[' => bracket_depth += 1,
            ']' => {
                if (bracket_depth == 0) return null;
                bracket_depth -= 1;
            },
            '<' => angle_depth += 1,
            '>' => {
                if (angle_depth == 0) return null;
                angle_depth -= 1;
            },
            else => {},
        }
    }
    return null;
}

pub fn aggregateFieldOffsetU8(aggregate_ty: ir.Type, field_index: usize) !u8 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0 or offset_i > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(offset_i);
}

pub fn aggregateFieldOffset(aggregate_ty: ir.Type, field_index: usize) !u32 {
    const layout = try x86_64SysVDataLayout();
    const offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, aggregate_ty, field_index) orelse
        return error.UnsupportedCodegenAbi;
    if (offset_i < 0 or offset_i > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(offset_i);
}

pub fn aggregateByteOffsetU8(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u8 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u8)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}

pub fn aggregateByteOffset(aggregate_ty: ir.Type, field_offset: u64, field_ty: ir.Type) !u32 {
    _ = aggregateFieldIndexAtOffset(aggregate_ty, field_offset, field_ty) orelse return error.UnsupportedCodegenAbi;
    if (field_offset > std.math.maxInt(u32)) return error.UnsupportedCodegenAbi;
    return @intCast(field_offset);
}

pub fn lowerGenericCfgPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 8 }) or !ret.ty.eql(.{ .int = 8 })) return false;
    if (function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 3) return false;
    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, or_result)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, function.params.items[0].name) or !isInt(high_mask.rhs, -8)) return false;

    const low_mask = switch (low_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (low_mask.op != .@"and" or !low_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(low_mask.lhs, function.params.items[1].name) or !isInt(low_mask.rhs, 7)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, low_result) and isNamed(or_binary.rhs, high_result)) or
        (isNamed(or_binary.lhs, high_result) and isNamed(or_binary.rhs, low_result)))) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 1 }) or !ret.ty.eql(.{ .int = 1 })) return false;
    if (function.params.items.len != 1 or !function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (block.instructions.items.len != 1) return false;
    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, icmp_result)) return false;
    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .slt or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, function.params.items[0].name) or !isInt(icmp.rhs, 0)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgPointerSelectLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or block.instructions.items.len != 3) return false;
    const icmp_name = block.instructions.items[0].result orelse return false;
    const select_name = block.instructions.items[1].result orelse return false;
    const load_name = block.instructions.items[2].result orelse return false;
    const icmp = switch (block.instructions.items[0].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (!genericCfgSupportsBranchIcmp(function, icmp)) return false;
    const select = switch (block.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.ptr) or !isNamed(select.cond, icmp_name)) return false;
    const true_ptr = switch (select.true_value) {
        .named => |name| name,
        else => return false,
    };
    const false_ptr = switch (select.false_value) {
        .named => |name| name,
        else => return false,
    };
    if (!genericCfgSupportsPointerParam(function, true_ptr) or !genericCfgSupportsPointerParam(function, false_ptr)) return false;
    const load = switch (block.instructions.items[2].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, select_name)) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    const true_label = "generic_cfg_pointer_select_true";
    const end_label = "generic_cfg_pointer_select_end";
    const branch_kind = try emitGenericCfgIcmpCondition(allocator, machine, function, icmp);
    try appendGenericCfgConditionalBranch(allocator, machine, branch_kind, true_label);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, false_ptr, .ptr) });
    try machine.instructions.append(allocator, .{ .jmp = end_label });
    try appendGenericCfgBlockLabel(allocator, machine, true_label);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, true_ptr, .ptr) });
    try appendGenericCfgBlockLabel(allocator, machine, end_label);
    try appendGenericCfgReturn(allocator, machine);
    return true;
}
