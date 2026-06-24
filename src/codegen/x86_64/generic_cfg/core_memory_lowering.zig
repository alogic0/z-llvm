const impl = @import("core_impl.zig");
const std = impl.std;
const ir = impl.ir;
const MachineFunction = impl.MachineFunction;
const ArgReg = impl.ArgReg;

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
    const ret_instruction = impl.findInstruction(block, ret_name) orelse return null;
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
    if (impl.paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = impl.findInstruction(block, name) orelse impl.findInstruction(entry, name) orelse return null;
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
    if (impl.paramRegOrNull(function, name, .{ .int = 64 }) catch null) |reg| return reg;
    const instruction = impl.findInstruction(block, name) orelse return null;
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
    const instruction = impl.findInstruction(block, name) orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    return genericCfgDynamicI32LoadAddress(function, block, load);
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
    if (impl.paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .index_reg = .rsi, .offset_elems = 0 };
    }
    const instruction = impl.findInstruction(block, name) orelse return null;
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
                    const index_reg = impl.paramRegOrNull(function, index_name, .{ .int = 64 }) catch null;
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
        if (!store.ty.eql(.ptr) or store.attrs.isBarrier() or !impl.isNamed(store.ptr, slot_name)) continue;
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
    if (impl.genericCfgSupportsPointerParam(function, name)) return .{ .param = name };
    if (name.len == 0 or name[0] != '@') return null;
    const symbol = impl.globalSymbolName(name) catch return null;
    if (impl.tlsSymbolFromFunctionAttrs(function)) |tls_symbol| {
        if (std.mem.eql(u8, tls_symbol, symbol)) return .{ .tls = symbol };
    }
    if (impl.knownLocalExecTlsSymbol(symbol)) return .{ .tls = symbol };
    return .{ .global = symbol };
}

pub fn emitGenericCfgLoadI32IntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    ptr: ir.Value,
) !void {
    switch (genericCfgI32Address(function, ptr) orelse return error.UnsupportedCodegenValue) {
        .param => |name| try machine.instructions.append(allocator, .{ .load_arg_ptr_eax = try impl.paramReg(function, name, .ptr) }),
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
        .param => |name| try machine.instructions.append(allocator, .{ .store_eax_arg_ptr = try impl.paramReg(function, name, .ptr) }),
        .global => |symbol| try machine.instructions.append(allocator, .{ .store_eax_global_i32 = symbol }),
        .tls => |symbol| try machine.instructions.append(allocator, .{ .store_eax_tls_i32 = symbol }),
    }
}
