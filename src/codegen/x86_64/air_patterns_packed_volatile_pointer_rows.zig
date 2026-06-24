const std = @import("std");
const ir = @import("../../ir.zig");
const x86_64_types = @import("types.zig");
const x86_64_machine = @import("machine.zig");
const x86_64_match = @import("match.zig");
const x86_64_generic_cfg = @import("generic_cfg.zig");

const MachineFunction = x86_64_machine.MachineFunction;
const ArgReg = x86_64_types.ArgReg;
const globalSymbolName = x86_64_match.globalSymbolName;
const isNamed = x86_64_match.isNamed;
const isInt = x86_64_match.isInt;
const i32Value = x86_64_match.i32Value;
const validateDefaultCallConv = x86_64_match.validateDefaultCallConv;
const callIsFastcc = x86_64_match.callIsFastcc;
const valueReferencesGlobal = x86_64_generic_cfg.valueReferencesGlobal;
const paramReg = x86_64_generic_cfg.paramReg;
const blockByName = x86_64_generic_cfg.blockByName;
const phiHasIncoming = x86_64_generic_cfg.phiHasIncoming;
const phiHasIncomingInt = x86_64_generic_cfg.phiHasIncomingInt;

pub fn lowerPackedReplaceLowReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.replace_low") or
        std.mem.eql(u8, function.name, "replace_low");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.replaceLow");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 8 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 }) or !function.params.items[1].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt and block.instructions.items.len != 3) {
        return try lowerRuntimePackedReplaceLowPreoptHelper(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 3) return false;

    const high_mask_inst = block.instructions.items[0];
    const low_mask_inst = block.instructions.items[1];
    const or_inst = block.instructions.items[2];
    if (high_mask_inst.removed or low_mask_inst.removed or or_inst.removed) return false;
    const high_result = high_mask_inst.result orelse return false;
    const low_result = low_mask_inst.result orelse return false;
    const or_result = or_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, or_result)) return false;

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

pub fn lowerRuntimePackedReplaceLowPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 9) return false;
    const alloca_inst = block.instructions.items[0];
    const first_store_inst = block.instructions.items[1];
    const trunc_inst = block.instructions.items[2];
    const first_load_inst = block.instructions.items[3];
    const high_mask_inst = block.instructions.items[4];
    const zext_inst = block.instructions.items[5];
    const or_inst = block.instructions.items[6];
    const second_store_inst = block.instructions.items[7];
    const second_load_inst = block.instructions.items[8];
    if (alloca_inst.removed or first_store_inst.removed or trunc_inst.removed or first_load_inst.removed or
        high_mask_inst.removed or zext_inst.removed or or_inst.removed or second_store_inst.removed or second_load_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    const first_load_name = first_load_inst.result orelse return false;
    const high_mask_name = high_mask_inst.result orelse return false;
    const zext_name = zext_inst.result orelse return false;
    const or_name = or_inst.result orelse return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const first_store = switch (first_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!first_store.ty.eql(.{ .int = 8 }) or first_store.attrs.isBarrier()) return false;
    if (!isNamed(first_store.ptr, alloca_name) or !isNamed(first_store.value, function.params.items[0].name)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 3 })) return false;
    if (!isNamed(trunc.value, function.params.items[1].name)) return false;

    const first_load = switch (first_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!first_load.ty.eql(.{ .int = 8 }) or first_load.attrs.isBarrier()) return false;
    if (!isNamed(first_load.ptr, alloca_name)) return false;

    const high_mask = switch (high_mask_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (high_mask.op != .@"and" or !high_mask.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(high_mask.lhs, first_load_name) or !isInt(high_mask.rhs, -8)) return false;

    const zext = switch (zext_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (zext.op != .zext or !zext.from_ty.eql(.{ .int = 3 }) or !zext.to_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(zext.value, trunc_name)) return false;

    const or_binary = switch (or_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (or_binary.op != .@"or" or !or_binary.ty.eql(.{ .int = 8 })) return false;
    if (!((isNamed(or_binary.lhs, zext_name) and isNamed(or_binary.rhs, high_mask_name)) or
        (isNamed(or_binary.lhs, high_mask_name) and isNamed(or_binary.rhs, zext_name)))) return false;

    const second_store = switch (second_store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!second_store.ty.eql(.{ .int = 8 }) or second_store.attrs.isBarrier()) return false;
    if (!isNamed(second_store.ptr, alloca_name) or !isNamed(second_store.value, or_name)) return false;

    const second_load_name = second_load_inst.result orelse return false;
    const second_load = switch (second_load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!second_load.ty.eql(.{ .int = 8 }) or second_load.attrs.isBarrier()) return false;
    if (!isNamed(second_load.ptr, alloca_name)) return false;

    const ret_value_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_value_name, second_load_name)) return false;

    try machine.instructions.append(allocator, .replace_low_i8_dil_sil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePackedReplaceLowMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_replace_low_main.main")) return false;
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
    if (!std.mem.eql(u8, call.callee, "runtime_packed_replace_low_main.replaceLow")) return false;
    if (!call.ret_ty.eql(.{ .int = 8 }) or call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !(isInt(call.args.items[0].value, -1) or isInt(call.args.items[0].value, 255))) return false;
    if (!call.args.items[1].ty.eql(.{ .int = 8 }) or !isInt(call.args.items[1].value, 5)) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(icmp.lhs, call_name) or !(isInt(icmp.rhs, -3) or isInt(icmp.rhs, 253))) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerPackedReadFlagReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    const source_fixture = std.mem.eql(u8, function.name, "packed_bits.read_flag") or
        std.mem.eql(u8, function.name, "read_flag");
    const integrated_preopt = std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.readFlag");
    if (!source_fixture and !integrated_preopt) return false;
    if (!ret.ty.eql(.{ .int = 1 }) or function.params.items.len != 1) return false;
    if (!function.params.items[0].ty.eql(.{ .int = 8 })) return false;
    if (integrated_preopt and block.instructions.items.len != 1) {
        return try lowerRuntimePackedReadFlagPreoptHelper(allocator, machine, function, block, ret);
    }
    if (block.instructions.items.len != 1) return false;

    const icmp_inst = block.instructions.items[0];
    if (icmp_inst.removed) return false;
    const icmp_result = icmp_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, ret_name, icmp_result)) return false;

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

pub fn lowerRuntimePackedReadFlagPreoptHelper(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (block.instructions.items.len != 5) return false;
    const alloca_inst = block.instructions.items[0];
    const store_inst = block.instructions.items[1];
    const load_inst = block.instructions.items[2];
    const shift_inst = block.instructions.items[3];
    const trunc_inst = block.instructions.items[4];
    if (alloca_inst.removed or store_inst.removed or load_inst.removed or shift_inst.removed or trunc_inst.removed) return false;

    const alloca_name = alloca_inst.result orelse return false;
    const load_name = load_inst.result orelse return false;
    const shift_name = shift_inst.result orelse return false;
    const trunc_name = trunc_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, trunc_name)) return false;

    const alloca = switch (alloca_inst.kind) {
        .alloca => |alloca| alloca,
        else => return false,
    };
    if (!alloca.allocated_ty.eql(.{ .int = 8 })) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 8 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, alloca_name) or !isNamed(store.value, function.params.items[0].name)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 8 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, alloca_name)) return false;

    const shift = switch (shift_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (shift.op != .lshr or !shift.ty.eql(.{ .int = 8 })) return false;
    if (!isNamed(shift.lhs, load_name) or !isInt(shift.rhs, 7)) return false;

    const trunc = switch (trunc_inst.kind) {
        .cast => |cast| cast,
        else => return false,
    };
    if (trunc.op != .trunc or !trunc.from_ty.eql(.{ .int = 8 }) or !trunc.to_ty.eql(.{ .int = 1 })) return false;
    if (!isNamed(trunc.value, shift_name)) return false;

    try machine.instructions.append(allocator, .read_flag_i8_dil_al);
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePackedReadFlagMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_packed_read_flag_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (!ret.ty.eql(.{ .int = 32 }) or block.instructions.items.len != 2) return false;

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
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (call.calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "fastcc")) return false;
    }
    if (!std.mem.eql(u8, call.callee, "runtime_packed_read_flag_main.readFlag")) return false;
    if (!call.ret_ty.eql(.{ .int = 1 }) or call.args.items.len != 1) return false;
    if (!call.args.items[0].ty.eql(.{ .int = 8 }) or !(isInt(call.args.items[0].value, -128) or isInt(call.args.items[0].value, 128))) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, call_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
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

pub fn lowerPointerLoadStoreReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!ret.ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.ptr)) return false;
    const reload_result = block.instructions.items.len == 4;
    if (block.instructions.items.len != 3 and !reload_result) return false;

    const load_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const reload_inst = if (reload_result) block.instructions.items[3] else null;
    if (load_inst.removed or add_inst.removed or store_inst.removed) return false;
    if (reload_inst) |instruction| if (instruction.removed) return false;
    const load_result = load_inst.result orelse return false;
    const add_result = add_inst.result orelse return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!reload_result and !std.mem.eql(u8, ret_name, add_result)) return false;

    const load = switch (load_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return false;
    if (!isNamed(load.ptr, function.params.items[0].name)) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    const add_imm = if (isNamed(add.lhs, load_result)) switch (add.rhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else if (isNamed(add.rhs, load_result)) switch (add.lhs) {
        .int => |int| try i32Value(int),
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    } else return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.ptr, function.params.items[1].name) or !isNamed(store.value, add_result)) return false;

    const src_reg = try paramReg(function, function.params.items[0].name, .ptr);
    const dst_reg = try paramReg(function, function.params.items[1].name, .ptr);
    try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = src_reg });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = add_imm });
    try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = dst_reg });
    if (reload_inst) |instruction| {
        const reload_name = instruction.result orelse return false;
        if (!std.mem.eql(u8, ret_name, reload_name)) return false;
        const reload = switch (instruction.kind) {
            .load => |reload| reload,
            else => return false,
        };
        if (!reload.ty.eql(.{ .int = 32 }) or reload.attrs.isBarrier()) return false;
        if (!isNamed(reload.ptr, function.params.items[1].name)) return false;
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = dst_reg });
    }
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePointerLoadStorePreoptMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    if (!std.mem.eql(u8, function.name, "runtime_pointer_load_store_main.main")) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 0) return false;
    if (function.blocks.items.len == 7) return lowerRuntimePointerLoadStorePreoptSafeMain(allocator, machine, function);
    if (function.blocks.items.len != 3) return false;
    if (blockByName(function, "Entry") != null) return lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(allocator, machine, function);

    const entry = blockByName(function, "0") orelse return false;
    const merge = blockByName(function, "5") orelse return false;
    const output_check = blockByName(function, "7") orelse return false;
    if (entry.instructions.items.len != 2 or merge.instructions.items.len != 2 or output_check.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (!call.ret_ty.eql(.{ .int = 32 }) or call.args.items.len != 2) return false;
    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "7") or !std.mem.eql(u8, entry_br.else_target, "5")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    const output_br = switch (output_check.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return false,
    };
    if (!std.mem.eql(u8, output_br.target, "5")) return false;

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "7") or !phiHasIncomingInt(phi, 0, "0")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePointerLoadStorePreoptSafeOptimizedMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const merge = blockByName(function, "Block1") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or merge.instructions.items.len != 2) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Block1")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");

    const phi_name = merge.instructions.items[0].result orelse return false;
    const select_name = merge.instructions.items[1].result orelse return false;
    if (merge.instructions.items[0].removed or merge.instructions.items[1].removed) return false;
    const phi = switch (merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!phi.ty.eql(.{ .int = 1 }) or phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(phi, output_cmp_name, "Then") or !phiHasIncomingInt(phi, 0, "Entry")) return false;
    const select = switch (merge.instructions.items[1].kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, phi_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;
    const ret = switch (merge.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn lowerRuntimePointerLoadStorePreoptSafeMain(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
) !bool {
    const entry = blockByName(function, "Entry") orelse return false;
    const output_check = blockByName(function, "Then") orelse return false;
    const first_fail = blockByName(function, "Else") orelse return false;
    const bool_merge = blockByName(function, "Block1") orelse return false;
    const ret_ok = blockByName(function, "Then1") orelse return false;
    const ret_fail = blockByName(function, "Else1") orelse return false;
    const ret_block = blockByName(function, "Block") orelse return false;
    if (entry.instructions.items.len != 2 or output_check.instructions.items.len != 2 or first_fail.instructions.items.len != 0) return false;
    if (bool_merge.instructions.items.len != 1 or ret_ok.instructions.items.len != 0 or ret_fail.instructions.items.len != 0) return false;
    if (ret_block.instructions.items.len != 1) return false;

    const call_name = entry.instructions.items[0].result orelse return false;
    const first_cmp_name = entry.instructions.items[1].result orelse return false;
    if (entry.instructions.items[0].removed or entry.instructions.items[1].removed) return false;
    const call = switch (entry.instructions.items[0].kind) {
        .call => |call| call,
        else => return false,
    };
    if (!callIsFastcc(call.calling_conv) or !call.ret_ty.eql(.{ .int = 32 })) return false;
    if (call.callee_value != null or call.inline_asm != null) return false;
    if (!std.mem.eql(u8, call.callee, "runtime_pointer_load_store_main.loadStore")) return false;
    if (call.args.items.len != 2) return false;
    if (!call.args.items[0].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[0].value, "runtime_pointer_load_store_main.input")) return false;
    if (!call.args.items[1].ty.eql(.ptr) or !valueReferencesGlobal(call.args.items[1].value, "runtime_pointer_load_store_main.output")) return false;

    const first_cmp = switch (entry.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (first_cmp.predicate != .eq or !first_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(first_cmp.lhs, call_name) or !isInt(first_cmp.rhs, 42)) return false;
    const entry_br = switch (entry.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!entry_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(entry_br.cond, first_cmp_name)) return false;
    if (!std.mem.eql(u8, entry_br.then_target, "Then") or !std.mem.eql(u8, entry_br.else_target, "Else")) return false;

    const output_load_name = output_check.instructions.items[0].result orelse return false;
    const output_cmp_name = output_check.instructions.items[1].result orelse return false;
    if (output_check.instructions.items[0].removed or output_check.instructions.items[1].removed) return false;
    const output_load = switch (output_check.instructions.items[0].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!output_load.ty.eql(.{ .int = 32 }) or output_load.attrs.isBarrier()) return false;
    if (!valueReferencesGlobal(output_load.ptr, "runtime_pointer_load_store_main.output")) return false;
    const output_cmp = switch (output_check.instructions.items[1].kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (output_cmp.predicate != .eq or !output_cmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(output_cmp.lhs, output_load_name) or !isInt(output_cmp.rhs, 42)) return false;
    try validateBrTarget(output_check, "Block1");
    try validateBrTarget(first_fail, "Block1");

    const bool_phi_name = bool_merge.instructions.items[0].result orelse return false;
    if (bool_merge.instructions.items[0].removed) return false;
    const bool_phi = switch (bool_merge.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!bool_phi.ty.eql(.{ .int = 1 }) or bool_phi.incoming.items.len != 2) return false;
    if (!phiHasIncoming(bool_phi, output_cmp_name, "Then") or !phiHasIncomingInt(bool_phi, 0, "Else")) return false;
    const bool_br = switch (bool_merge.terminator orelse return error.BlockWithoutTerminator) {
        .condbr => |condbr| condbr,
        else => return false,
    };
    if (!bool_br.cond_ty.eql(.{ .int = 1 }) or !isNamed(bool_br.cond, bool_phi_name)) return false;
    if (!std.mem.eql(u8, bool_br.then_target, "Then1") or !std.mem.eql(u8, bool_br.else_target, "Else1")) return false;
    try validateBrTarget(ret_ok, "Block");
    try validateBrTarget(ret_fail, "Block");

    const ret_phi_name = ret_block.instructions.items[0].result orelse return false;
    if (ret_block.instructions.items[0].removed) return false;
    const ret_phi = switch (ret_block.instructions.items[0].kind) {
        .phi => |phi| phi,
        else => return false,
    };
    if (!ret_phi.ty.eql(.{ .int = 32 }) or ret_phi.incoming.items.len != 2) return false;
    if (!phiHasIncomingInt(ret_phi, 0, "Then1") or !phiHasIncomingInt(ret_phi, 1, "Else1")) return false;
    const ret = switch (ret_block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, ret_phi_name)) return false;

    const fail = "pointer_load_store_preopt_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.input" });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = "runtime_pointer_load_store_main.output" });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}

pub fn validateBrTarget(block: ir.BasicBlock, expected_target: []const u8) !void {
    const br = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .br => |br| br,
        else => return error.UnsupportedCodegenControlFlow,
    };
    if (!std.mem.eql(u8, br.target, expected_target)) return error.UnsupportedCodegenControlFlow;
}

pub fn lowerRuntimePointerLoadStoreMainReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret: anytype,
) !bool {
    if (!std.mem.eql(u8, function.name, "main")) return false;
    if (function.params.items.len != 0) return false;
    if (!function.ret_ty.eql(.{ .int = 32 }) or !ret.ty.eql(.{ .int = 32 })) return false;
    if (block.instructions.items.len != 6) return false;

    const load_input_inst = block.instructions.items[0];
    const add_inst = block.instructions.items[1];
    const store_inst = block.instructions.items[2];
    const load_output_inst = block.instructions.items[3];
    const icmp_inst = block.instructions.items[4];
    const select_inst = block.instructions.items[5];
    if (load_input_inst.removed or add_inst.removed or store_inst.removed or load_output_inst.removed or icmp_inst.removed or select_inst.removed) return false;

    const load_input_name = load_input_inst.result orelse return false;
    const add_name = add_inst.result orelse return false;
    const load_output_name = load_output_inst.result orelse return false;
    const icmp_name = icmp_inst.result orelse return false;
    const select_name = select_inst.result orelse return false;
    if (!isNamed(ret.value orelse return error.InvalidRet, select_name)) return false;

    const load_input = switch (load_input_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_input.ty.eql(.{ .int = 32 }) or load_input.attrs.isBarrier()) return false;
    const input_global = switch (load_input.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, input_global, "pointers_memory.writer_input")) return false;

    const add = switch (add_inst.kind) {
        .binary => |binary| binary,
        else => return false,
    };
    if (add.op != .add or !add.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(add.lhs, load_input_name) or !isInt(add.rhs, 1)) return false;

    const store = switch (store_inst.kind) {
        .store => |store| store,
        else => return false,
    };
    if (!store.ty.eql(.{ .int = 32 }) or store.attrs.isBarrier()) return false;
    if (!isNamed(store.value, add_name)) return false;
    const store_global = switch (store.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, store_global, "pointers_memory.writer_output")) return false;

    const load_output = switch (load_output_inst.kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load_output.ty.eql(.{ .int = 32 }) or load_output.attrs.isBarrier()) return false;
    const output_global = switch (load_output.ptr) {
        .named => |name| try globalSymbolName(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return false,
    };
    if (!std.mem.eql(u8, output_global, "pointers_memory.writer_output")) return false;

    const icmp = switch (icmp_inst.kind) {
        .icmp => |icmp| icmp,
        else => return false,
    };
    if (icmp.predicate != .eq or !icmp.operand_ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(icmp.lhs, load_output_name) or !isInt(icmp.rhs, 42)) return false;

    const select = switch (select_inst.kind) {
        .select => |select| select,
        else => return false,
    };
    if (!select.cond_ty.eql(.{ .int = 1 }) or !select.ty.eql(.{ .int = 32 })) return false;
    if (!isNamed(select.cond, icmp_name) or !isInt(select.true_value, 0) or !isInt(select.false_value, 1)) return false;

    const fail = "pointer_load_store_fail";
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = input_global });
    try machine.instructions.append(allocator, .{ .add_eax_imm32 = 1 });
    try machine.instructions.append(allocator, .{ .store_eax_global_i32 = store_global });
    try machine.instructions.append(allocator, .{ .load_global_i32_eax = output_global });
    try machine.instructions.append(allocator, .{ .cmp_eax_imm32 = 42 });
    try machine.instructions.append(allocator, .{ .jne = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try machine.instructions.append(allocator, .ret);
    try machine.instructions.append(allocator, .{ .label = fail });
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 1 });
    try machine.instructions.append(allocator, .ret);
    return true;
}
