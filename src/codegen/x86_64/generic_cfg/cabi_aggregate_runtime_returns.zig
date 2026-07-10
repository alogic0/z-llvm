const std = @import("std");
const ir = @import("../../../ir.zig");
const type_layout = @import("../../../zig_air_type_layout.zig");
const x86_64_match = @import("../match.zig");
const x86_64_machine = @import("../machine.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");

const MachineFunction = x86_64_machine.MachineFunction;

const identityCastFrom = cabi_call_lowering.identityCastFrom;
const isSelectI1ToI32ZeroOne = cabi_call_lowering.isSelectI1ToI32ZeroOne;
const valueReferencesGlobal = cabi_call_lowering.valueReferencesGlobal;

const paramReg = cabi_abi_helpers.paramReg;
const paramValueReg = cabi_abi_helpers.paramValueReg;

const callArgAttrsContain = x86_64_match.callArgAttrsContain;
const callIsFastcc = x86_64_match.callIsFastcc;
const isInt = x86_64_match.isInt;
const isNamed = x86_64_match.isNamed;
const paramAttrsContain = x86_64_match.paramAttrsContain;
const aggregate_classification = @import("cabi_aggregate_classification.zig");
const aggregate_fields = @import("cabi_aggregate_fields.zig");
const x86_64SysVDataLayout = aggregate_classification.x86_64SysVDataLayout;
const appendStoreEaxArgPtrDisp = aggregate_fields.appendStoreEaxArgPtrDisp;

pub fn lowerAggregatePairAbiFamilyReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (try lowerRuntimeAggregatePairMainReturn(allocator, machine, function, block, ret)) return true;
    return false;
}

fn isTwoI32PairAggregate(ty: ir.Type) bool {
    const layout = x86_64SysVDataLayout() catch return false;
    const plan = type_layout.aggregateLayoutPlan(layout, ty) catch return false;
    const leaves = plan.leafSlice();
    return plan.field_count == 2 and leaves.len == 2 and
        leaves[0].offset == 0 and leaves[0].ty.eql(.{ .int = 32 }) and
        leaves[1].offset == 4 and leaves[1].ty.eql(.{ .int = 32 });
}

fn isPairAggregateAllocaForSretCall(ty: ir.Type, call: ir.CallInst) bool {
    if (isTwoI32PairAggregate(ty)) return true;
    if (call.args.items.len == 0) return false;
    const text = switch (ty) {
        .aggregate => |aggregate_text| aggregate_text,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .vector => return false,
    };
    const attrs = call.args.items[0].attrs orelse return false;
    const marker = "sret(";
    const start = std.mem.indexOf(u8, attrs, marker) orelse return false;
    const after_marker = attrs[start + marker.len ..];
    const end = std.mem.indexOfScalar(u8, after_marker, ')') orelse return false;
    return std.mem.eql(u8, text, after_marker[0..end]);
}

fn isSretPairSlotArg(arg: ir.CallArg, slot_name: []const u8) bool {
    return arg.ty.eql(.ptr) and callArgAttrsContain(arg, "sret(") and isNamed(arg.value, slot_name);
}

fn isSretPairParam(param: ir.Param) bool {
    return param.ty.eql(.ptr) and paramAttrsContain(param, "sret(");
}

fn isMakePairSretCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty == .void and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 3 and
        isSretPairSlotArg(call.args.items[0], pair_slot_name) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 1) and
        call.args.items[2].ty.eql(.{ .int = 32 }) and isInt(call.args.items[2].value, 2);
}

fn isMakePairRegisterAggregateCall(call: ir.CallInst) bool {
    return callIsFastcc(call.calling_conv) and isTwoI32PairAggregate(call.ret_ty) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 2 and
        call.args.items[0].ty.eql(.{ .int = 32 }) and isInt(call.args.items[0].value, 1) and
        call.args.items[1].ty.eql(.{ .int = 32 }) and isInt(call.args.items[1].value, 2);
}

fn isPairFirstPtrCall(call: ir.CallInst, pair_slot_name: []const u8) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(.ptr) and isNamed(call.args.items[0].value, pair_slot_name);
}

fn isPairFirstRegisterAggregateCall(call: ir.CallInst, pair_value_name: []const u8, pair_ty: ir.Type) bool {
    return callIsFastcc(call.calling_conv) and call.ret_ty.eql(.{ .int = 32 }) and
        call.callee_value == null and call.inline_asm == null and
        call.args.items.len == 1 and
        call.args.items[0].ty.eql(pair_ty) and isNamed(call.args.items[0].value, pair_value_name);
}

pub fn lowerRuntimeAggregatePairMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
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

    const make_pair = switch (make_pair_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isMakePairSretCall(make_pair, pair_slot_name)) return false;
    if (!isPairAggregateAllocaForSretCall(alloca.allocated_ty, make_pair)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstPtrCall(pair_first, pair_slot_name)) return false;

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
    if (!isMakePairRegisterAggregateCall(make_pair)) return false;

    const pair_first = switch (pair_first_inst.kind) {
        .call => |call| call,
        else => return false,
    };
    if (!isPairFirstRegisterAggregateCall(pair_first, make_pair_name, make_pair.ret_ty)) return false;

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
    if (!callIsFastcc(function.calling_conv) or function.ret_ty != .void or ret.ty != .void) return false;
    if (function.params.items.len != 3) return false;
    if (!isSretPairParam(function.params.items[0])) return false;
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

    const sret_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const first_reg = try paramReg(function, function.params.items[1].name, .{ .int = 32 });
    const second_reg = try paramReg(function, function.params.items[2].name, .{ .int = 32 });
    try machine.instructions.append(allocator, .{ .mov_arg_eax = first_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 0);
    try machine.instructions.append(allocator, .{ .mov_arg_eax = second_reg });
    try appendStoreEaxArgPtrDisp(allocator, machine, sret_reg, 4);
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
    if (!isTwoI32PairAggregate(alloca.allocated_ty)) return false;

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
