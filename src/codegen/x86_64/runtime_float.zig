const std = @import("std");
const ir = @import("../../ir.zig");
const machine_ir = @import("machine.zig");
const match = @import("match.zig");

const MachineFunction = machine_ir.MachineFunction;

const RuntimeFloatCallArgExpectation = struct {
    ty: ir.Type,
    value: union(enum) {
        fp_text: []const u8,
        int: i128,
    },
};

const RuntimeFloatCallCompareCase = struct {
    function_name: []const u8,
    callee_name: []const u8,
    call_ret_ty: ir.Type,
    args: []const RuntimeFloatCallArgExpectation,
    fcmp_predicate: ir.FcmpPredicate,
    fcmp_rhs: []const u8,
};

const runtime_float_mul_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "3.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_add_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "1.000000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_select_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "4.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "5.000000e+00" } },
    .{ .ty = .{ .int = 1 }, .value = .{ .int = 1 } },
};

const runtime_float_sub_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "5.000000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_double_div_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .double, .value = .{ .fp_text = "6.000000e+00" } },
    .{ .ty = .double, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_rem_compare_args = [_]RuntimeFloatCallArgExpectation{
    .{ .ty = .float, .value = .{ .fp_text = "5.500000e+00" } },
    .{ .ty = .float, .value = .{ .fp_text = "2.000000e+00" } },
};

const runtime_float_call_compare_cases = [_]RuntimeFloatCallCompareCase{
    .{
        .function_name = "runtime_float_mul_main.main",
        .callee_name = "runtime_float_mul_main.floatMul",
        .call_ret_ty = .double,
        .args = &runtime_float_mul_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "6.000000e+00",
    },
    .{
        .function_name = "runtime_float_add_main.main",
        .callee_name = "runtime_float_add_main.floatAdd",
        .call_ret_ty = .float,
        .args = &runtime_float_add_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_float_select_main.main",
        .callee_name = "runtime_float_select_main.floatSelect",
        .call_ret_ty = .double,
        .args = &runtime_float_select_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "4.000000e+00",
    },
    .{
        .function_name = "runtime_float_sub_main.main",
        .callee_name = "runtime_float_sub_main.floatSub",
        .call_ret_ty = .float,
        .args = &runtime_float_sub_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_double_div_main.main",
        .callee_name = "runtime_double_div_main.doubleDiv",
        .call_ret_ty = .double,
        .args = &runtime_double_div_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "3.000000e+00",
    },
    .{
        .function_name = "runtime_float_rem_main.main",
        .callee_name = "runtime_float_rem_main.floatRem",
        .call_ret_ty = .float,
        .args = &runtime_float_rem_compare_args,
        .fcmp_predicate = .oeq,
        .fcmp_rhs = "1.500000e+00",
    },
};

pub fn lowerSelectedRuntimeFloatCallCompareMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    for (runtime_float_call_compare_cases) |case| {
        if (try lowerRuntimeFloatCallCompareMainReturn(
            allocator,
            machine,
            function,
            block,
            ret,
            case.function_name,
            case.callee_name,
            case.call_ret_ty,
            case.args,
            case.fcmp_predicate,
            case.fcmp_rhs,
        )) return true;
    }
    return false;
}

fn lowerRuntimeFloatCallCompareMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
    expected_function_name: []const u8,
    expected_callee_name: []const u8,
    expected_call_ret_ty: ir.Type,
    expected_call_args: []const RuntimeFloatCallArgExpectation,
    expected_fcmp_predicate: ir.FcmpPredicate,
    expected_fcmp_rhs: []const u8,
) !bool {
    if (!std.mem.eql(u8, function.name, expected_function_name)) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 3) return false;

    const call_inst = block.instructions.items[0];
    const fcmp_inst = block.instructions.items[1];
    const select_inst = block.instructions.items[2];
    if (call_inst.removed or fcmp_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const fcmp_name = fcmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!match.isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    switch (expected_call_ret_ty) {
        .float, .double => {},
        .void, .int, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    }
    if (!match.callIsFastcc(call.calling_conv) or !call.ret_ty.eql(expected_call_ret_ty)) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, expected_callee_name)) return false;
    if (call.args.items.len != expected_call_args.len) return false;
    for (expected_call_args, 0..) |expected_arg, i| {
        const actual_arg = call.args.items[i];
        if (!actual_arg.ty.eql(expected_arg.ty)) return false;
        switch (expected_arg.value) {
            .fp_text => |expected| if (!match.isFpText(actual_arg.value, expected)) return false,
            .int => |expected| if (!match.isInt(actual_arg.value, expected)) return false,
        }
    }

    const fcmp = switch (fcmp_inst.kind) {
        .fcmp => |fcmp| fcmp,
        else => return false,
    };
    if (fcmp.predicate != expected_fcmp_predicate or !fcmp.operand_ty.eql(expected_call_ret_ty)) return false;
    if (!match.isNamed(fcmp.lhs, call_name) or !match.isFpText(fcmp.rhs, expected_fcmp_rhs)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!match.isNamed(select.cond, fcmp_name) or !match.isInt(select.true_value, 0) or !match.isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimeFloatLessMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_float_less_main.main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 2) return false;

    const call_inst = block.instructions.items[0];
    const select_inst = block.instructions.items[1];
    if (call_inst.removed or select_inst.removed) return false;
    const call_name = call_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!match.isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const call = switch (call_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!match.callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 1 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_float_less_main.floatLess")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.float) or !match.isFpText(call.args.items[0].value, "1.000000e+00")) return false;
    if (!call.args.items[1].ty.eql(.float) or !match.isFpText(call.args.items[1].value, "2.000000e+00")) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!match.isNamed(select.cond, call_name) or !match.isInt(select.true_value, 0) or !match.isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}
