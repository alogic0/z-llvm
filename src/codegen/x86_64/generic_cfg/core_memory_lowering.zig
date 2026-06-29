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
const i32Value = shared.i32Value;
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
    index_reg: ?ArgReg,
    offset_elems: i128,
};

pub const GenericCfgScalarWidth = enum {
    i8,
    i16,
    i32,
    i64,

    pub fn fromType(value_ty: ir.Type) ?GenericCfgScalarWidth {
        if (value_ty.eql(.{ .int = 8 })) return .i8;
        if (value_ty.eql(.{ .int = 16 })) return .i16;
        if (value_ty.eql(.{ .int = 32 })) return .i32;
        if (value_ty.eql(.{ .int = 64 })) return .i64;
        return null;
    }

    pub fn bytes(width: GenericCfgScalarWidth) i128 {
        return switch (width) {
            .i8 => 1,
            .i16 => 2,
            .i32 => 4,
            .i64 => 8,
        };
    }

    pub fn shift(width: GenericCfgScalarWidth) u6 {
        return switch (width) {
            .i8 => 0,
            .i16 => 1,
            .i32 => 2,
            .i64 => 3,
        };
    }

    pub fn ty(width: GenericCfgScalarWidth) ir.Type {
        return switch (width) {
            .i8 => .{ .int = 8 },
            .i16 => .{ .int = 16 },
            .i32 => .{ .int = 32 },
            .i64 => .{ .int = 64 },
        };
    }
};

pub const GenericCfgTypedAddress = struct {
    base_reg: ArgReg,
    add_index_reg: ?ArgReg,
    sub_index_reg: ?ArgReg = null,
    offset_bytes: i128,
    width: GenericCfgScalarWidth,
};

const GenericCfgAddressResolverOptions = struct {
    entry: ?ir.BasicBlock = null,
    extra_entry: ?ir.BasicBlock = null,
    allow_loaded_pointer_slots: bool = true,
    allow_slice_aggregate_extraction: bool = true,
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

fn findInstructionInAddressScope(block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, name: []const u8) ?ir.Instruction {
    if (findInstruction(block, name)) |instruction| return instruction;
    if (options.entry) |entry| {
        if (findInstruction(entry, name)) |instruction| return instruction;
    }
    if (options.extra_entry) |entry| {
        if (findInstruction(entry, name)) |instruction| return instruction;
    }
    return null;
}

fn genericCfgStoredValueInAddressScope(block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    if (genericCfgStoredValue(block, slot_name, ty)) |value| return value;
    if (options.entry) |entry| {
        if (genericCfgStoredValue(entry, slot_name, ty)) |value| return value;
    }
    if (options.extra_entry) |entry| {
        if (genericCfgStoredValue(entry, slot_name, ty)) |value| return value;
    }
    return null;
}

fn genericCfgStoredPointerValueInAddressScope(block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, slot_name: []const u8) ?ir.Value {
    if (genericCfgStoredPointerValue(block, slot_name)) |value| return value;
    if (options.entry) |entry| {
        if (genericCfgStoredPointerValue(entry, slot_name)) |value| return value;
    }
    if (options.extra_entry) |entry| {
        if (genericCfgStoredPointerValue(entry, slot_name)) |value| return value;
    }
    return null;
}

fn genericCfgI64ParamRegThroughAddressScope(function: ir.Function, block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, value: ir.Value) ?ArgReg {
    if (genericCfgI64ParamRegThroughIdentityCast(function, block, value)) |reg| return reg;
    if (options.entry) |entry| {
        if (genericCfgI64ParamRegThroughIdentityCast(function, entry, value)) |reg| return reg;
    }
    if (options.extra_entry) |entry| {
        if (genericCfgI64ParamRegThroughIdentityCast(function, entry, value)) |reg| return reg;
    }
    return null;
}

fn genericCfgI64NegatedParamRegThroughAddressScope(function: ir.Function, block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, value: ir.Value) ?ArgReg {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstructionInAddressScope(block, options, name) orelse return null;
    const binary = switch (instruction.kind) {
        .binary => |binary| binary,
        else => return null,
    };
    if (binary.op != .sub or !binary.ty.eql(.{ .int = 64 })) return null;
    switch (binary.lhs) {
        .int => |int| if (int != 0) return null,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    }
    return genericCfgI64ParamRegThroughAddressScope(function, block, options, binary.rhs);
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

pub fn genericCfgTypedScalarLoadValueAddress(function: ir.Function, block: ir.BasicBlock, value: ir.Value, width: GenericCfgScalarWidth) ?GenericCfgTypedAddress {
    const name = switch (value) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstruction(block, name) orelse return null;
    const load = switch (instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    return genericCfgTypedScalarLoadAddress(function, block, load, width);
}

pub fn genericCfgTypedScalarLoadReturnAddressAcrossBlocks(
    function: ir.Function,
    entry: ir.BasicBlock,
    block: ir.BasicBlock,
    width: GenericCfgScalarWidth,
) ?GenericCfgTypedAddress {
    const ret = switch (block.terminator orelse return null) {
        .ret => |ret| ret,
        else => return null,
    };
    if (!ret.ty.eql(width.ty())) return null;
    const ret_name = switch (ret.value orelse return null) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse findInstruction(entry, ret_name) orelse return null;
    const load = switch (ret_instruction.kind) {
        .load => |load| load,
        else => return null,
    };
    return genericCfgTypedScalarLoadAddressAcrossBlocks(function, entry, block, load, width);
}

pub fn genericCfgTypedScalarLoadAddress(function: ir.Function, block: ir.BasicBlock, load: ir.LoadInst, width: GenericCfgScalarWidth) ?GenericCfgTypedAddress {
    if (!load.ty.eql(width.ty()) or load.attrs.isBarrier()) return null;
    return genericCfgTypedScalarAddress(function, block, load.ptr, width);
}

pub fn genericCfgTypedScalarLoadAddressAcrossBlocks(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, load: ir.LoadInst, width: GenericCfgScalarWidth) ?GenericCfgTypedAddress {
    if (!load.ty.eql(width.ty()) or load.attrs.isBarrier()) return null;
    return genericCfgTypedScalarAddressResolved(function, block, load.ptr, width, .{ .entry = entry });
}

pub fn genericCfgTypedScalarLoadAddressAcrossScopes(
    function: ir.Function,
    entry: ir.BasicBlock,
    extra_entry: ir.BasicBlock,
    block: ir.BasicBlock,
    load: ir.LoadInst,
    width: GenericCfgScalarWidth,
) ?GenericCfgTypedAddress {
    if (!load.ty.eql(width.ty()) or load.attrs.isBarrier()) return null;
    return genericCfgTypedScalarAddressResolved(function, block, load.ptr, width, .{ .entry = entry, .extra_entry = extra_entry });
}

pub fn genericCfgTypedScalarAddress(function: ir.Function, block: ir.BasicBlock, ptr: ir.Value, width: GenericCfgScalarWidth) ?GenericCfgTypedAddress {
    return genericCfgTypedScalarAddressResolved(function, block, ptr, width, .{});
}

pub fn genericCfgTypedScalarAddressAcrossBlocks(function: ir.Function, entry: ir.BasicBlock, block: ir.BasicBlock, ptr: ir.Value, width: GenericCfgScalarWidth) ?GenericCfgTypedAddress {
    return genericCfgTypedScalarAddressResolved(function, block, ptr, width, .{ .entry = entry });
}

fn genericCfgTypedScalarAddressResolved(
    function: ir.Function,
    block: ir.BasicBlock,
    ptr: ir.Value,
    width: GenericCfgScalarWidth,
    options: GenericCfgAddressResolverOptions,
) ?GenericCfgTypedAddress {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    if (paramRegOrNull(function, name, .ptr) catch null) |reg| {
        return .{ .base_reg = reg, .add_index_reg = null, .offset_bytes = 0, .width = width };
    }
    const instruction = findInstructionInAddressScope(block, options, name) orelse return null;
    switch (instruction.kind) {
        .gep => |gep| {
            if (!gep.source_ty.eql(width.ty()) or gep.indices.items.len != 1) return null;
            var address = genericCfgTypedScalarAddressResolved(function, block, gep.ptr, width, options) orelse return null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 })) return null;
            switch (index.value) {
                .int => |int| address.offset_bytes += int * width.bytes(),
                .named => |index_name| {
                    if (genericCfgI64ParamRegThroughAddressScope(function, block, options, .{ .named = index_name })) |reg| {
                        if (address.add_index_reg != null) return null;
                        address.add_index_reg = reg;
                    } else if (genericCfgI64NegatedParamRegThroughAddressScope(function, block, options, .{ .named = index_name })) |reg| {
                        if (address.sub_index_reg != null) return null;
                        address.sub_index_reg = reg;
                    } else {
                        return null;
                    }
                },
                .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            }
            return address;
        },
        .load => |load| {
            if (!options.allow_loaded_pointer_slots) return null;
            if (!load.ty.eql(.ptr) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredPointerValueInAddressScope(block, options, slot_name) orelse return null;
            return genericCfgTypedScalarAddressResolved(function, block, stored, width, options);
        },
        .extractvalue => |extract| {
            if (!options.allow_slice_aggregate_extraction) return null;
            if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, "0") or extract.result_ty != .ptr) return null;
            const slice_ptr = genericCfgSlicePointerValueResolved(block, options, extract.aggregate) orelse return null;
            return genericCfgTypedScalarAddressResolved(function, block, slice_ptr, width, options);
        },
        .cast => |cast| {
            if (cast.op != .bitcast or !cast.to_ty.eql(.ptr)) return null;
            return genericCfgTypedScalarAddressResolved(function, block, cast.value, width, options);
        },
        else => return null,
    }
}

pub fn lowerGenericCfgDynamicPointerLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
) !bool {
    const ret_width = GenericCfgScalarWidth.fromType(function.ret_ty) orelse return false;
    if (function.params.items.len < 1) return false;
    if (!function.params.items[0].ty.eql(.ptr)) return false;
    const ret = switch (block.terminator orelse return error.BlockWithoutTerminator) {
        .ret => |ret| ret,
        else => return false,
    };
    if (!ret.ty.eql(function.ret_ty)) return false;
    const ret_name = switch (ret.value orelse return error.InvalidRet) {
        .named => |name| name,
        else => return false,
    };
    const ret_instruction = findInstruction(block, ret_name) orelse return false;
    if (try lowerGenericCfgDynamicPointerStoreThenLoadReturn(allocator, machine, function, block, ret_instruction, ret_width)) return true;
    switch (ret_instruction.kind) {
        .load => |load| {
            const address = genericCfgTypedScalarLoadAddress(function, block, load, ret_width) orelse return false;
            try emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, address);
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

fn lowerGenericCfgDynamicPointerStoreThenLoadReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    block: ir.BasicBlock,
    ret_instruction: ir.Instruction,
    width: GenericCfgScalarWidth,
) !bool {
    const ret_load = switch (ret_instruction.kind) {
        .load => |load| load,
        else => return false,
    };
    const ret_address = genericCfgTypedScalarLoadAddress(function, block, ret_load, width) orelse return false;
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(width.ty())) continue;
        if (store.attrs.isBarrier()) return false;
        const store_address = genericCfgTypedScalarAddress(function, block, store.ptr, width) orelse return false;
        if (!sameGenericCfgTypedAddress(store_address, ret_address)) return false;
        try emitGenericCfgScalarValueIntoReturnReg(allocator, machine, function, store.value, width);
        try emitGenericCfgTypedAddressIntoRcx(allocator, machine, store_address);
        try emitGenericCfgTypedScalarStoreReturnReg(allocator, machine, width);
        try emitGenericCfgTypedScalarLoadIntoReturn(allocator, machine, ret_address);
        try appendGenericCfgReturn(allocator, machine);
        return true;
    }
    return false;
}

pub fn sameGenericCfgTypedAddress(lhs: GenericCfgTypedAddress, rhs: GenericCfgTypedAddress) bool {
    return lhs.base_reg == rhs.base_reg and lhs.add_index_reg == rhs.add_index_reg and lhs.sub_index_reg == rhs.sub_index_reg and lhs.offset_bytes == rhs.offset_bytes and lhs.width == rhs.width;
}

fn sameGenericCfgDynamicI32Address(lhs: GenericCfgDynamicI32Address, rhs: GenericCfgDynamicI32Address) bool {
    return lhs.base_reg == rhs.base_reg and lhs.index_reg == rhs.index_reg and lhs.offset_elems == rhs.offset_elems;
}

fn emitGenericCfgI32ValueIntoEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
) !void {
    switch (value) {
        .int => |int| try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
        .named => |name| try machine.instructions.append(allocator, .{ .mov_arg_eax = try paramReg(function, name, .{ .int = 32 }) }),
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
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
        return .{ .base_reg = reg, .index_reg = null, .offset_elems = 0 };
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
                    if (address.index_reg != null) return null;
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
        .extractvalue => |extract| {
            if (!extract.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or !std.mem.eql(u8, extract.indices, "0") or extract.result_ty != .ptr) return null;
            const slice_ptr = genericCfgSlicePointerValue(block, extract.aggregate) orelse return null;
            return genericCfgDynamicI32Address(function, block, slice_ptr);
        },
        else => return null,
    }
}

fn genericCfgSlicePointerValue(block: ir.BasicBlock, aggregate: ir.Value) ?ir.Value {
    return genericCfgSlicePointerValueResolved(block, .{}, aggregate);
}

fn genericCfgSlicePointerValueResolved(block: ir.BasicBlock, options: GenericCfgAddressResolverOptions, aggregate: ir.Value) ?ir.Value {
    const name = switch (aggregate) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    const instruction = findInstructionInAddressScope(block, options, name) orelse return null;
    const insert = switch (instruction.kind) {
        .insertvalue => |insert| insert,
        .load => |load| {
            if (!load.ty.eql(.{ .aggregate = "{ ptr, i64 }" }) or load.attrs.isBarrier()) return null;
            const slot_name = switch (load.ptr) {
                .named => |slot| slot,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
            };
            const stored = genericCfgStoredValueInAddressScope(block, options, slot_name, .{ .aggregate = "{ ptr, i64 }" }) orelse return null;
            return genericCfgSlicePointerValueResolved(block, options, stored);
        },
        else => return null,
    };
    if (!insert.aggregate_ty.eql(.{ .aggregate = "{ ptr, i64 }" })) return null;
    if (std.mem.eql(u8, insert.indices, "0")) {
        if (insert.value_ty != .ptr) return null;
        return insert.value;
    }
    if (std.mem.eql(u8, insert.indices, "1")) {
        return genericCfgSlicePointerValueResolved(block, options, insert.aggregate);
    }
    return null;
}

fn genericCfgStoredValue(block: ir.BasicBlock, slot_name: []const u8, ty: ir.Type) ?ir.Value {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const store = switch (instruction.kind) {
            .store => |store| store,
            else => continue,
        };
        if (!store.ty.eql(ty) or store.attrs.isBarrier() or !isNamed(store.ptr, slot_name)) continue;
        return store.value;
    }
    return null;
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

pub fn emitGenericCfgTypedScalarLoadIntoReturn(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgTypedAddress,
) !void {
    try emitGenericCfgTypedAddressIntoRcx(allocator, machine, address);
    switch (address.width) {
        .i8 => try machine.instructions.append(allocator, .load_rcx_ptr_u8_eax),
        .i16 => try machine.instructions.append(allocator, .load_rcx_ptr_u16_eax),
        .i32 => try machine.instructions.append(allocator, .load_rcx_ptr_eax),
        .i64 => try machine.instructions.append(allocator, .load_rcx_ptr_rax),
    }
}

pub fn emitGenericCfgTypedAddressIntoRcx(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgTypedAddress,
) !void {
    if (address.offset_bytes < std.math.minInt(i32) or address.offset_bytes > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    const index_count: u2 = @as(u2, @intFromBool(address.add_index_reg != null)) + @as(u2, @intFromBool(address.sub_index_reg != null));
    if (index_count == 1) {
        const term = if (address.add_index_reg) |reg|
            IndexTerm{ .reg = reg, .direction = .add }
        else
            IndexTerm{ .reg = address.sub_index_reg.?, .direction = .sub };
        if (term.reg == .rcx and address.base_reg == .r8) {
            if (term.direction == .sub) return error.UnsupportedCodegenValue;
            const shift = address.width.shift();
            if (shift != 0) try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = shift });
            try machine.instructions.append(allocator, .add_r8_rcx);
        } else {
            if (term.reg == .rcx) {
                try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rcx } });
                try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.base_reg } });
                try emitGenericCfgTypedAddressPreparedIndexTerm(allocator, machine, address.width, term.direction);
            } else {
                try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.base_reg } });
                try emitGenericCfgTypedAddressIndexTerm(allocator, machine, address.width, term.reg, term.direction);
            }
        }
    } else {
        if (address.add_index_reg == .rcx) {
            try emitGenericCfgTypedAddressRcxIndexFirst(allocator, machine, address, .add);
            if (address.sub_index_reg) |reg| try emitGenericCfgTypedAddressIndexTerm(allocator, machine, address.width, reg, .sub);
        } else if (address.sub_index_reg == .rcx) {
            try emitGenericCfgTypedAddressRcxIndexFirst(allocator, machine, address, .sub);
            if (address.add_index_reg) |reg| try emitGenericCfgTypedAddressIndexTerm(allocator, machine, address.width, reg, .add);
        } else {
            try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.base_reg } });
            if (address.add_index_reg) |reg| try emitGenericCfgTypedAddressIndexTerm(allocator, machine, address.width, reg, .add);
            if (address.sub_index_reg) |reg| try emitGenericCfgTypedAddressIndexTerm(allocator, machine, address.width, reg, .sub);
        }
    }
    if (address.offset_bytes != 0) {
        try machine.instructions.append(allocator, .{ .add_rcx_imm32 = @intCast(address.offset_bytes) });
    }
}

const IndexDirection = enum { add, sub };

const IndexTerm = struct {
    reg: ArgReg,
    direction: IndexDirection,
};

fn emitGenericCfgTypedAddressRcxIndexFirst(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgTypedAddress,
    direction: IndexDirection,
) !void {
    const other_reg = switch (direction) {
        .add => address.sub_index_reg,
        .sub => address.add_index_reg,
    };
    if (other_reg == .r8) return error.UnsupportedCodegenValue;
    if (address.base_reg == .r8) {
        if (direction == .sub) return error.UnsupportedCodegenValue;
        const shift = address.width.shift();
        if (shift != 0) try machine.instructions.append(allocator, .{ .shl_rcx_imm6 = shift });
        try machine.instructions.append(allocator, .add_r8_rcx);
        return;
    }
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .r8, .src = .rcx } });
    try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = address.base_reg } });
    try emitGenericCfgTypedAddressPreparedIndexTerm(allocator, machine, address.width, direction);
}

fn emitGenericCfgTypedAddressIndexTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    width: GenericCfgScalarWidth,
    index_reg: ArgReg,
    direction: IndexDirection,
) !void {
    if (index_reg == .rcx) return error.UnsupportedCodegenValue;
    if (index_reg != .r8) {
        try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .r8, .src = index_reg } });
    }
    try emitGenericCfgTypedAddressPreparedIndexTerm(allocator, machine, width, direction);
}

fn emitGenericCfgTypedAddressPreparedIndexTerm(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    width: GenericCfgScalarWidth,
    direction: IndexDirection,
) !void {
    const shift = width.shift();
    if (shift != 0) try machine.instructions.append(allocator, .{ .shl_r8_imm6 = shift });
    try machine.instructions.append(allocator, if (direction == .add) .add_r8_rcx else .sub_r8_rcx);
}

pub fn emitGenericCfgScalarValueIntoReturnReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    function: ir.Function,
    value: ir.Value,
    width: GenericCfgScalarWidth,
) !void {
    switch (value) {
        .int => |int| switch (width) {
            .i8, .i16, .i32 => try machine.instructions.append(allocator, .{ .mov_imm_eax = try i32Value(int) }),
            .i64 => try machine.instructions.append(allocator, .{ .mov_imm_rax = @intCast(int) }),
        },
        .named => |name| switch (width) {
            .i8, .i16, .i32 => try machine.instructions.append(allocator, .{ .mov_arg_eax = try paramReg(function, name, width.ty()) }),
            .i64 => try machine.instructions.append(allocator, .{ .mov_arg_rax = try paramReg(function, name, width.ty()) }),
        },
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    }
}

pub fn emitGenericCfgTypedScalarStoreReturnReg(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    width: GenericCfgScalarWidth,
) !void {
    switch (width) {
        .i8 => try machine.instructions.append(allocator, .store_al_rcx_ptr),
        .i16 => try machine.instructions.append(allocator, .store_ax_rcx_ptr),
        .i32 => try machine.instructions.append(allocator, .store_eax_rcx_ptr),
        .i64 => try machine.instructions.append(allocator, .store_rax_rcx_ptr),
    }
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
    try emitGenericCfgDynamicAddressIndexIntoRcx(allocator, machine, address);
    try machine.instructions.append(allocator, .load_rdi_rcx4_ptr_r8d);
    try machine.instructions.append(allocator, .add_r8d_eax);
}

fn emitGenericCfgDynamicAddressIndexIntoRcx(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    if (address.offset_elems < 0 or address.offset_elems > 8) return error.UnsupportedCodegenValue;
    if (address.index_reg) |index_reg| {
        try machine.instructions.append(allocator, .{ .mov_arg64_arg = .{ .dst = .rcx, .src = index_reg } });
    } else {
        try machine.instructions.append(allocator, .xor_ecx_ecx);
    }
    var offset: i128 = 0;
    while (offset < address.offset_elems) : (offset += 1) {
        try machine.instructions.append(allocator, .inc_rcx);
    }
}

pub fn emitGenericCfgDynamicI32StoreEax(
    allocator: std.mem.Allocator,
    machine: *MachineFunction,
    address: GenericCfgDynamicI32Address,
) !void {
    if (address.base_reg != .rdi) return error.UnsupportedCodegenAbi;
    try emitGenericCfgDynamicAddressIndexIntoRcx(allocator, machine, address);
    try machine.instructions.append(allocator, .store_eax_rdi_rcx4_ptr);
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
