const shared = @import("core_shared.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");
const core_value_support = @import("core_value_support.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const cabi_aggregate_lowering = @import("cabi_aggregate_lowering.zig");
const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const Instruction = shared.x86_64_machine.Instruction;
const SysVCallTarget = shared.SysVCallTarget;

const appendGenericCfgBlockLabel = core_cfg_emit.appendGenericCfgBlockLabel;
const appendGenericCfgConditionalBranch = core_cfg_emit.appendGenericCfgConditionalBranch;
const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const appendLoadStackDispRax = cabi_aggregate_lowering.appendLoadStackDispRax;
const appendStackFrame = shared.appendStackFrame;
const appendStackFrameEnd = shared.appendStackFrameEnd;
const appendSysVCallTarget = shared.appendSysVCallTarget;
const callIsFastcc = shared.callIsFastcc;
const emitGenericCfgIcmpCondition = cabi_call_lowering.emitGenericCfgIcmpCondition;
const genericCfgSupportsBranchIcmp = core_value_support.genericCfgSupportsBranchIcmp;
const genericCfgSupportsPointerParam = core_value_support.genericCfgSupportsPointerParam;
const isNamed = shared.isNamed;
const paramReg = cabi_abi_helpers.paramReg;
const scalarParamStackDisp8 = cabi_abi_helpers.scalarParamStackDisp8;
const setupSysVCallTarget = shared.setupSysVCallTarget;
const validateDefaultCallConv = shared.validateDefaultCallConv;

const lowerGenericCfgGprDirectCallReturn = cabi_call_lowering.lowerGenericCfgGprDirectCallReturn;
const lowerGenericCfgGprParamReturn = cabi_call_lowering.lowerGenericCfgGprParamReturn;

pub fn lowerGenericCfgGprVoidCallStackParamReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if ((!ret.ty.eql(.{ .int = 64 }) and !ret.ty.eql(.ptr)) or block.instructions.items.len != 1) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    const stack_disp = scalarParamStackDisp8(function, ret_name, ret.ty) catch |err| switch (err) {
        error.UnsupportedCodegenAbi, error.UnsupportedCodegenValue => return false,
        else => return err,
    };
    const instruction = block.instructions.items[0];
    if (instruction.removed or instruction.result != null) return false;
    const call = switch (instruction.kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.ret_ty != .void or call.args.items.len != 0 or call.inline_asm != null) return false;
    if (!callIsFastcc(call.calling_conv)) try validateDefaultCallConv(call.calling_conv);
    if (call.ret_attrs != null or call.attrs != null) return error.UnsupportedCodegenAbi;
    if (call.callee_function_ty) |function_ty| {
        if (std.mem.indexOf(u8, function_ty, "...") != null) return error.UnsupportedCodegenAbi;
    }
    const call_target: SysVCallTarget = if (call.callee_value) |callee_value| blk: {
        const callee_name = switch (callee_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
        };
        break :blk .{ .indirect_from_reg = try paramReg(function, callee_name, .ptr) };
    } else .{ .direct = call.callee };
    try appendStackFrame(allocator, machine, 8);
    try setupSysVCallTarget(allocator, machine, call_target);
    try appendSysVCallTarget(allocator, machine, call_target, call.ret_ty);
    try appendStackFrameEnd(allocator, machine, 8);
    try appendLoadStackDispRax(allocator, machine, stack_disp);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerGenericCfgSingleBlockPtr(allocator: std.mem.Allocator, machine: *MachineFunction, function: ir.Function) !bool {
    if (!function.ret_ty.eql(.ptr) or function.blocks.items.len != 1) return false;
    const block = function.blocks.items[0];
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (try lowerGenericCfgPtrNullReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGprParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGprVoidCallStackParamReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    if (try lowerGenericCfgGprDirectCallReturn(allocator, machine, function, block, ret)) {
        machine.codegen_path = .generic_cfg;
        return true;
    }
    return false;
}

fn lowerGenericCfgPtrNullReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!function.ret_ty.eql(.ptr) or !ret.ty.eql(.ptr)) return false;
    if (block.instructions.items.len != 0) return false;
    if ((ret.value orelse return error.InvalidRet) != .null_value) return false;
    try machine.instructions.append(allocator, .{ .mov_imm_rax = 0 });
    try appendGenericCfgReturn(allocator, machine);
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
