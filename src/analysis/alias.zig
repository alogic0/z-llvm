const std = @import("std");
const ir = @import("../ir.zig");
const function_attrs = @import("function_attrs.zig");
const memory_effect = @import("memory_effect.zig");
const memory_location = @import("memory_location.zig");

pub const AliasResult = enum {
    no_alias,
    may_alias,
    partial_alias,
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

pub fn accessAlias(function: ir.Function, a: ir.Value, a_ty: ir.Type, b: ir.Value, b_ty: ir.Type) AliasResult {
    const a_location = memory_location.forAccess(function, a, a_ty) orelse return .may_alias;
    const b_location = memory_location.forAccess(function, b, b_ty) orelse return .may_alias;
    return aliasLocations(a_location, b_location);
}

pub fn accessAliasInModule(module: ir.Module, function: ir.Function, a: ir.Value, a_ty: ir.Type, b: ir.Value, b_ty: ir.Type) AliasResult {
    const layout = moduleLayout(module);
    const a_location = locationForAccess(module, function, layout, a, a_ty) orelse return .may_alias;
    const b_location = locationForAccess(module, function, layout, b, b_ty) orelse return .may_alias;
    return aliasLocations(a_location, b_location);
}

pub fn aliasLocations(a: memory_location.MemoryLocation, b: memory_location.MemoryLocation) AliasResult {
    if (!std.mem.eql(u8, a.root, b.root)) {
        if (a.root_kind == .parameter and b.root_kind == .parameter) return .may_alias;
        if (a.root_kind == .parameter and b.root_kind != .stack) return .may_alias;
        if (b.root_kind == .parameter and a.root_kind != .stack) return .may_alias;
        return .no_alias;
    }
    if (rangesDoNotOverlap(a, b)) return .no_alias;
    if (a.offset != null and b.offset != null and a.offset.? == b.offset.?) {
        if (a.size == null or b.size == null or a.size.? == b.size.?) return .must_alias;
        return .partial_alias;
    }
    if (rangesOverlap(a, b)) return .partial_alias;
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
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .no_mod_ref,
        .atomicrmw, .cmpxchg, .fence, .call => .unknown,
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
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .no_mod_ref,
        .atomicrmw, .cmpxchg, .fence => .unknown,
        .call => |call| callModRefInModule(module, function, layout, call, pointer),
    };
}

pub fn modRefForAccess(function: ir.Function, instruction: ir.Instruction, pointer: ir.Value, access_ty: ir.Type) ModRefInfo {
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesAccess(function, load.ptr, load.ty, pointer, access_ty)) .ref else .no_mod_ref;
        },
        .store => |store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesAccess(function, store.ptr, store.ty, pointer, access_ty)) .mod else .no_mod_ref;
        },
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .no_mod_ref,
        .atomicrmw, .cmpxchg, .fence, .call => .unknown,
    };
}

pub fn modRefInModuleForAccess(module: ir.Module, function: ir.Function, instruction: ir.Instruction, pointer: ir.Value, access_ty: ir.Type) ModRefInfo {
    const layout = moduleLayout(module);
    return switch (instruction.kind) {
        .load => |load| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesAccessInModule(module, function, layout, load.ptr, load.ty, pointer, access_ty)) .ref else .no_mod_ref;
        },
        .store => |store| {
            if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return .unknown;
            return if (accessAliasesAccessInModule(module, function, layout, store.ptr, store.ty, pointer, access_ty)) .mod else .no_mod_ref;
        },
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => .no_mod_ref,
        .atomicrmw, .cmpxchg, .fence => .unknown,
        .call => |call| callModRefInModuleForAccess(module, function, layout, call, pointer, access_ty),
    };
}

fn callModRefInModule(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, call: ir.CallInst, pointer: ir.Value) ModRefInfo {
    return callModRefForLocation(module, function, layout, call, pointer, null);
}

fn callModRefInModuleForAccess(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, call: ir.CallInst, pointer: ir.Value, access_ty: ir.Type) ModRefInfo {
    return callModRefForLocation(module, function, layout, call, pointer, access_ty);
}

fn callModRefForLocation(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, call: ir.CallInst, pointer: ir.Value, access_ty: ?ir.Type) ModRefInfo {
    const attrs = function_attrs.resolvedCallAttributes(module, call) orelse return .unknown;
    const effects = attrs.memory_effects orelse return .unknown;

    var result = toAliasModRef(effects.other);
    if (effects.argmem != .no_mod_ref and callArgMayAliasLocation(module, function, layout, call, pointer, access_ty)) {
        result = mergeModRef(result, toAliasModRef(effects.argmem));
    }
    return result;
}

fn callArgMayAliasLocation(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, call: ir.CallInst, pointer: ir.Value, access_ty: ?ir.Type) bool {
    const query_location = if (access_ty) |ty|
        locationForAccess(module, function, layout, pointer, ty) orelse return true
    else
        locationForPointer(module, function, layout, pointer) orelse return true;

    for (call.args.items) |arg| {
        if (arg.ty != .ptr) continue;
        const arg_location = locationForPointer(module, function, layout, arg.value) orelse return true;
        if (aliasLocations(arg_location, query_location) != .no_alias) return true;
    }
    return false;
}

fn toAliasModRef(value: function_attrs.AttributeSet.ModRef) ModRefInfo {
    return switch (value) {
        .no_mod_ref => .no_mod_ref,
        .ref => .ref,
        .mod => .mod,
        .mod_ref => .mod_ref,
    };
}

fn mergeModRef(a: ModRefInfo, b: ModRefInfo) ModRefInfo {
    if (a == .unknown or b == .unknown) return .unknown;
    const bits = modRefBits(a) | modRefBits(b);
    return modRefFromBits(bits);
}

fn modRefBits(value: ModRefInfo) u2 {
    return switch (value) {
        .no_mod_ref => 0,
        .ref => 1,
        .mod => 2,
        .mod_ref => 3,
        .unknown => 3,
    };
}

fn modRefFromBits(bits: u2) ModRefInfo {
    return switch (bits) {
        0 => .no_mod_ref,
        1 => .ref,
        2 => .mod,
        3 => .mod_ref,
    };
}

fn accessAliasesPointer(function: ir.Function, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value) bool {
    const access_location = memory_location.forAccess(function, ptr, access_ty) orelse return true;
    const pointer_location = memory_location.forPointer(function, pointer) orelse return true;
    return aliasLocations(access_location, pointer_location) != .no_alias;
}

fn accessAliasesAccess(function: ir.Function, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value, pointer_access_ty: ir.Type) bool {
    const access_location = memory_location.forAccess(function, ptr, access_ty) orelse return true;
    const pointer_location = memory_location.forAccess(function, pointer, pointer_access_ty) orelse return true;
    return aliasLocations(access_location, pointer_location) != .no_alias;
}

fn accessAliasesPointerInModule(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value) bool {
    const access_location = locationForAccess(module, function, layout, ptr, access_ty) orelse return true;
    const pointer_location = locationForPointer(module, function, layout, pointer) orelse return true;
    return aliasLocations(access_location, pointer_location) != .no_alias;
}

fn accessAliasesAccessInModule(module: ir.Module, function: ir.Function, layout: ?@import("../target.zig").DataLayout, ptr: ir.Value, access_ty: ir.Type, pointer: ir.Value, pointer_access_ty: ir.Type) bool {
    const access_location = locationForAccess(module, function, layout, ptr, access_ty) orelse return true;
    const pointer_location = locationForAccess(module, function, layout, pointer, pointer_access_ty) orelse return true;
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

fn rangesOverlap(a: memory_location.MemoryLocation, b: memory_location.MemoryLocation) bool {
    const a_begin = a.offset orelse return false;
    const b_begin = b.offset orelse return false;
    const a_end = a.rangeEnd() orelse return false;
    const b_end = b.rangeEnd() orelse return false;
    return a_begin < b_end and b_begin < a_end;
}
