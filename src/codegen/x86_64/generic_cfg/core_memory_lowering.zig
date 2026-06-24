const shared = @import("core_shared.zig");
const cabi_abi_helpers = @import("cabi_abi_helpers.zig");
const cabi_call_lowering = @import("cabi_call_lowering.zig");
const tls_global = @import("cabi_tls_global_lowering.zig");
const core_cfg_emit = @import("core_cfg_emit.zig");

const std = shared.std;
const ir = shared.ir;
const MachineFunction = shared.MachineFunction;
const ArgReg = shared.ArgReg;

const appendGenericCfgReturn = core_cfg_emit.appendGenericCfgReturn;
const findInstruction = cabi_call_lowering.findInstruction;
const globalSymbolName = shared.globalSymbolName;
const isNamed = shared.isNamed;
const knownLocalExecTlsSymbol = tls_global.knownLocalExecTlsSymbol;
const paramReg = cabi_abi_helpers.paramReg;
const paramRegOrNull = cabi_abi_helpers.paramRegOrNull;
const tlsSymbolFromFunctionAttrs = tls_global.tlsSymbolFromFunctionAttrs;
const u8Value = shared.u8Value;

fn genericCfgSupportsPointerParam(function: ir.Function, name: []const u8) bool {
    return (paramRegOrNull(function, name, .ptr) catch null) != null;
}

pub const GenericCfgDynamicI32Address = struct {
    base_reg: ArgReg,
    index_reg: ArgReg,
    offset_elems: i128,
};

pub const GenericCfgAddress = union(enum) {
    param: []const u8,
    global: []const u8,
    tls: []const u8,
};

pub fn genericCfgDynamicI32LoadReturnAddress(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
) ?GenericCfgDynamicI32Address {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return null;
    const ret_name = switch (ret.value orelse return null) {
        .named => |name| name,
        else => return null,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return null;
    const load = switch (ret_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, load.ptr);
}

pub fn genericCfgDynamicI32AddressAcrossBlocks(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    ptr: ir.Value,
) ?GenericCfgDynamicI32Address {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = findInstruction(block, name) orelse findInstruction(entry, name) orelse return null;
    switch (instruction.kind) {
        .gep => |gep| {
            if (!gep.source_ty.eql(.{ .int = 32 }) or gep.indices.items.len != 1) return null;
            var address = genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, gep.ptr) orelse return null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 })) return null;
            switch (index.value) {
                .int => |int| address.offset_elems += int,
                .named => |index_name| {
                    if (address.offset_elems != 0) return null;
                    address.index_reg = genericCfgI64ParamRegThroughIdentityCast(function, entry, .{ .named = index_name }) orelse return null;
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            }
            return address;
        },
        .load => |load| {
            if (!load.ty.eql(.ptr) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredPointerValue(block, slot_name) orelse
                genericCfgStoredPointerValue(entry, slot_name) orelse return null;
            return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, stored);
        },
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.to_ty.eql(.ptr)) return null;
            return genericCfgDynamicI32AddressAcrossBlocks(function, entry, block, cast.value);
        },
        else => return null,
    }
}

pub fn genericCfgI64ParamRegThroughIdentityCast(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return reg;
    const instruction = findInstruction(block, name) orelse return null;
    const cast = switch (instruction.kind) {
        .cast => |cast| cast,
        else => return null,
    };
    if (cast.op != .bitcast or !cast.from_ty.eql(.{ .int = 64 }) or !cast.to_ty.eql(.{ .int = 64 })) return null;
    return genericCfgI64ParamRegThroughIdentityCast(function, block, cast.value);
}

pub fn genericCfgDynamicI32LoadValueAddress(function: ir.Function, block: ir.BasicBlock, value: ir.Value) ?GenericCfgDynamicI32Address {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    return genericCfgDynamicI32LoadAddress(function, block, load);
}

pub fn lowerGenericCfgDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 2) return false;
    if (!function.params.items[0].ty.eql(.ptr) or !function.params.items[1].ty.eql(.{ .int = 64 })) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 })) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return false;
    switch (ret_instruction.kind) {
        .load => |load| {
            const address = genericCfgDynamicI32LoadAddress(function, block, load) orelse return false;
            try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, address);
        },
        .binary => |binary| {
            if (binary.op != .add or !binary.ty.eql(.{ .int = 32 })) return false;
            const lhs = genericCfgDynamicI32LoadValueAddress(function, block, binary.lhs) orelse return false;
            const rhs = genericCfgDynamicI32LoadValueAddress(function, block, binary.rhs) orelse return false;
            try emitGenericCfgDynamicI32LoadIntoEax(allocator, machine, lhs);
            try emitGenericCfgDynamicI32AddIntoEax(allocator, machine, rhs);
        },
        else => return false,
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}

pub fn genericCfgDynamicI32LoadAddress(function: ir.Function, block: ir.BasicBlock, load: ir.LoadInst) ?GenericCfgDynamicI32Address {
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier()) return null;
    return genericCfgDynamicI32Address(function, block, load.ptr);
}

pub fn genericCfgDynamicI32Address(function: ir.Function, block: ir.BasicBlock, ptr: ir.Value) ?GenericCfgDynamicI32Address {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = findInstruction(block, name) orelse return null;
    switch (instruction.kind) {
        .gep => |gep| {
            if (!gep.source_ty.eql(.{ .int = 32 }) or gep.indices.items.len != 1) return null;
            var address = genericCfgDynamicI32Address(function, block, gep.ptr) orelse return null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 })) return null;
            switch (index.value) {
                .int => |int| address.offset_elems += int,
                .named => |index_name| {
                    if (address.offset_elems != 0) return null;
                    const index_reg = paramRegOrNull(function, index_name, .{ .int = 64 }) catch null;
                    address.index_reg = index_reg orelse return null;
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            }
            return address;
        },
        .load => |load| {
            if (!load.ty.eql(.ptr) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredPointerValue(block, slot_name) orelse return null;
            return genericCfgDynamicI32Address(function, block, stored);
        },
        else => return null,
    }
}

pub fn genericCfgStoredPointerValue(block: ir.BasicBlock, slot_name: []const u8) ?ir.Value {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(.ptr) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        return store.value;
    }
    return null;
}

pub fn emitGenericCfgDynamicI32LoadIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    try machine.instructions.append(allocator, .{ .mov_imm_eax = 0 });
    try emitGenericCfgDynamicI32AddIntoEax(allocator, machine, address);
}

pub fn emitGenericCfgDynamicI32AddIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    if (address.base_reg != .rdi) return error.UnsupportedCodegenAbi;
    if (address.offset_elems < 0 or address.offset_elems > 1) return error.UnsupportedCodegenValue;
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.index_reg } });
    if (address.offset_elems == 1) try machine.instructions.append(allocator, .inc_rcx);
    try machine.instructions.append(allocator, .load_rdi_rcx4_ptr_r8d);
    try machine.instructions.append(allocator, .add_r8d_eax);
}

pub fn genericCfgI32Address(function: ir.Function, ptr: ir.Value) ?GenericCfgAddress {
    const name = switch (ptr) {
        .named => |name| name,
        else => return null,
    };
    if (genericCfgSupportsPointerParam(function, name)) return .{ .param = name };
    if (name.len == 0 or name[0] != '@') return null;
    const symbol = globalSymbolName(name) catch return null;
    if (tlsSymbolFromFunctionAttrs(function)) |tls_symbol| {
        if (std.mem.eql(u8, tls_symbol, symbol)) return .{ .tls = symbol };
    }
    if (knownLocalExecTlsSymbol(symbol)) return .{ .tls = symbol };
    return .{ .global = symbol };
}

pub fn emitGenericCfgLoadI32IntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ptr: ir.Value,
) !void {
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .load_global_i32_eax = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .load_tls_i32_eax = symbol }),
    }
}

pub fn emitGenericCfgStoreEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ptr: ir.Value,
) !void {
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = try paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .store_eax_global_i32 = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = symbol }),
    }
}

pub const GenericCfgPointerSlotParam = struct {
    slot_name: []const u8,
    param_name: []const u8,
    param_reg: ArgReg,
};

pub fn genericCfgPointerSlotParam(
    function: ir.Function,
    alloca_instruction: ir.Instruction,
    store_instruction: ir.Instruction,
) ?GenericCfgPointerSlotParam {
    if (alloca_instruction.removed or store_instruction.removed) return null;
    const slot_name = alloca_instruction.result orelse return null;
    const alloca = switch (alloca_instruction.kind) {
        .alloca => |alloca| alloca,
        else => return null,
    };
    if (!alloca.allocated_ty.eql(.ptr) or alloca.allocated_ty_addrspace != null) return null;
    const store = switch (store_instruction.kind) {
        .store => |store| store,
        else => return null,
    };
    if (!store.ty.eql(.ptr) or store.ty_addrspace != null or store.ptr_addrspace != null or store.attrs.isBarrier()) return null;
    if (!isNamed(store.ptr, slot_name)) return null;
    const param_name = switch (store.value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const param_reg = paramRegOrNull(function, param_name, .ptr) catch return null;
    return .{ .slot_name = slot_name, .param_name = param_name, .param_reg = param_reg orelse return null };
}

pub fn genericCfgLoadPtrFromSlot(instruction: ir.Instruction, slot_name: []const u8) ?[]const u8 {
    if (instruction.removed) return null;
    const load_name = instruction.result orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    if (!load.ty.eql(.ptr) or load.ty_addrspace != null or load.ptr_addrspace != null or load.attrs.isBarrier()) return null;
    if (!isNamed(load.ptr, slot_name)) return null;
    return load_name;
}

pub const GenericCfgFieldLoadPtr = struct {
    name: []const u8,
    offset: i128,
};

pub fn genericCfgI8GepOffset(gep: ir.GepInst, ptr_name: []const u8, offset: i128) bool {
    return (genericCfgI8GepOffsetValue(gep, ptr_name) orelse return false) == offset;
}

pub fn genericCfgI8GepOffsetValue(gep: ir.GepInst, ptr_name: []const u8) ?i128 {
    if (!gep.source_ty.eql(.{ .int = 8 }) or !isNamed(gep.ptr, ptr_name)) return null;
    if (gep.indices.items.len != 1) return null;
    const index = gep.indices.items[0];
    if (!index.ty.eql(.{ .int = 64 })) return null;
    return switch (index.value) {
        .int => |int| if (int == 0 or int == 4 or int == 8) int else null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

pub fn lowerGenericCfgStructFieldLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    if (!function.ret_ty.eql(.{ .int = 32 }) or function.params.items.len != 1) return false;
    if (block.instructions.items.len != 4 and block.instructions.items.len != 5) return false;
    const slot = genericCfgPointerSlotParam(function, block.instructions.items[0], block.instructions.items[1]) orelse return false;
    const loaded_ptr = genericCfgLoadPtrFromSlot(block.instructions.items[2], slot.slot_name) orelse return false;

    const load_index: usize = if (block.instructions.items.len == 4) 3 else 4;
    const load_ptr = if (block.instructions.items.len == 4) GenericCfgFieldLoadPtr{ .name = loaded_ptr, .offset = 0 } else blk: {
        const gep_name = block.instructions.items[3].result orelse return false;
        const gep = switch (block.instructions.items[3].kind) {
            .gep => |gep| gep,
            else => return false,
        };
        const offset = genericCfgI8GepOffsetValue(gep, loaded_ptr) orelse return false;
        break :blk GenericCfgFieldLoadPtr{ .name = gep_name, .offset = offset };
    };

    const load_name = block.instructions.items[load_index].result orelse return false;
    const load = switch (block.instructions.items[load_index].kind) {
        .load => |load| load,
        else => return false,
    };
    if (!load.ty.eql(.{ .int = 32 }) or load.attrs.isBarrier() or !isNamed(load.ptr, load_ptr.name)) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(.{ .int = 32 }) or !isNamed(ret.value orelse return error.InvalidRet, load_name)) return false;

    if (load_ptr.offset == 0) {
        try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = slot.param_reg });
    } else {
        try machine.instructions.append(allocator, .{ .mov_arg_rax = slot.param_reg });
        try machine.instructions.append(allocator, .{ .load_rax_ptr_disp8_rax = try u8Value(load_ptr.offset) });
    }
    try appendGenericCfgReturn(allocator, machine);
    return true;
}
