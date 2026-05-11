const std = @import("std");
const ir = @import("../ir.zig");
const memory_effect = @import("memory_effect.zig");
const memory_location = @import("memory_location.zig");

pub const AliasResult = enum {
    no_alias,
    may_alias,
    must_alias,
};

pub const ModRefInfo = enum {
    no_mod_ref,
    ref,
    mod,
    mod_ref,
    unknown,
};

pub fn alias(function: ir.Function, a: ir.Value, b: ir.Value) AliasResult {
    if (a.eql(b)) return .must_alias;

    const a_location = memory_location.forPointer(function, a) orelse return .may_alias;
    const b_location = memory_location.forPointer(function, b) orelse return .may_alias;

    return aliasLocations(a_location, b_location);
}

pub fn aliasInModule(module: ir.Module, function: ir.Function, a: ir.Value, b: ir.Value) AliasResult {
    if (a.eql(b)) return .must_alias;

    const layout = moduleLayout(module);
    const a_location = locationForPointer(module, function, layout, a) orelse return .may_alias;
    const b_location = locationForPointer(module, function, layout, b) orelse return .may_alias;

    return aliasLocations(a_location, b_location);
}

pub fn aliasLocations(a: memory_location.MemoryLocation, b: memory_location.MemoryLocation) AliasResult {
    if (!std.mem.eql(u8, a.root, b.root)) return .no_alias;
    if (a.offset != null and b.offset != null and a.offset.? == b.offset.?) return .must_alias;
    if (rangesDoNotOverlap(a, b)) return .no_alias;
    return .may_alias;
}

pub fn modRef(function: ir.Function, instruction: ir.Instruction, pointer: ir.Value) ModRefInfo {
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesPointer(function, load.ptr, load.ty, pointer)) .ref else .no_mod_ref;
        },
        .store => |store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesPointer(function, store.ptr, store.ty, pointer)) .mod else .no_mod_ref;
        },
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => .no_mod_ref,
        .call => .unknown,
    };
}

pub fn modRefInModule(module: ir.Module, function: ir.Function, instruction: ir.Instruction, pointer: ir.Value) ModRefInfo {
    const layout = moduleLayout(module);
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesPointerInModule(module, function, layout, load.ptr, load.ty, pointer)) .ref else .no_mod_ref;
        },
        .store => |store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesPointerInModule(module, function, layout, store.ptr, store.ty, pointer)) .mod else .no_mod_ref;
        },
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => .no_mod_ref,
        .call => .unknown,
    };
}

fn accessAliasesPointer(function: ir.Function, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value) bool {
    const access_location = memory_location.forAccess(function, ptr, access_ty) orelse return true;
    const pointer_location = memory_location.forPointer(function, pointer) orelse return true;
    return aliasLocations(access_location, pointer_location) != .no_alias;
}

fn accessAliasesPointerInModule(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value) bool {
    const access_location = locationForAccess(module, function, layout, ptr, access_ty) orelse return true;
    const pointer_location = locationForPointer(module, function, layout, pointer) orelse return true;
    return aliasLocations(access_location, pointer_location) != .no_alias;
}

fn locationForPointer(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, ptr: ir.Value) ?memory_location.MemoryLocation {
    if (layout) |target_layout| return memory_location.forPointerInModuleWithLayout(module, function, target_layout, ptr);
    return memory_location.forPointerInModule(module, function, ptr);
}

fn locationForAccess(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, ptr: ir.Value, access_ty: ir.Type) ?memory_location.MemoryLocation {
    if (layout) |target_layout| return memory_location.forAccessInModuleWithLayout(module, function, target_layout, ptr, access_ty);
    return memory_location.forAccessInModule(module, function, ptr, access_ty);
}

fn moduleLayout(module: ir.Module) ?@import("../target.zig").DataLayout {
    const text = module.target_datalayout orelse return null;
    return @import("../target.zig").DataLayout.parse(text) catch null;
}

fn rangesDoNotOverlap(a: memory_location.MemoryLocation, b: memory_location.MemoryLocation) bool {
    const a_begin = a.offset orelse return false;
    const b_begin = b.offset orelse return false;
    const a_end = a.rangeEnd() orelse return false;
    const b_end = b.rangeEnd() orelse return false;
    return a_end <= b_begin or b_end <= a_begin;
}
