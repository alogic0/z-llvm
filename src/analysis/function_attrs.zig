const std = @import("std");
const ir = @import("../ir.zig");
const memory_effect = @import("memory_effect.zig");

pub const AttributeSet = struct {
    pub const ModRef = enum {
        no_mod_ref,
        ref,
        mod,
        mod_ref,

        pub fn merge(a: ModRef, b: ModRef) ModRef {
            const bits = modRefBits(a) | modRefBits(b);
            return modRefFromBits(bits);
        }

        pub fn intersect(a: ModRef, b: ModRef) ModRef {
            const bits = modRefBits(a) & modRefBits(b);
            return modRefFromBits(bits);
        }

        pub fn hasRef(value: ModRef) bool {
            return (modRefBits(value) & 1) != 0;
        }

        pub fn hasMod(value: ModRef) bool {
            return (modRefBits(value) & 2) != 0;
        }
    };

    pub const MemoryEffects = struct {
        argmem: ModRef = .no_mod_ref,
        inaccessiblemem: ModRef = .no_mod_ref,
        other: ModRef = .no_mod_ref,

        pub fn none() MemoryEffects {
            return .{};
        }

        pub fn all(value: ModRef) MemoryEffects {
            return .{
                .argmem = value,
                .inaccessiblemem = value,
                .other = value,
            };
        }

        pub fn argMemOnly(value: ModRef) MemoryEffects {
            return .{ .argmem = value };
        }

        pub fn inaccessibleMemOnly(value: ModRef) MemoryEffects {
            return .{ .inaccessiblemem = value };
        }

        pub fn intersect(a: MemoryEffects, b: MemoryEffects) MemoryEffects {
            return .{
                .argmem = a.argmem.intersect(b.argmem),
                .inaccessiblemem = a.inaccessiblemem.intersect(b.inaccessiblemem),
                .other = a.other.intersect(b.other),
            };
        }

        pub fn overall(effects: MemoryEffects) ModRef {
            return effects.argmem.merge(effects.inaccessiblemem).merge(effects.other);
        }

        pub fn accessible(effects: MemoryEffects) ModRef {
            return effects.argmem.merge(effects.other);
        }

        pub fn onlyAccessesArgMemory(effects: MemoryEffects) bool {
            return effects.argmem != .no_mod_ref and effects.inaccessiblemem == .no_mod_ref and effects.other == .no_mod_ref;
        }

        pub fn onlyAccessesInaccessibleMemory(effects: MemoryEffects) bool {
            return effects.inaccessiblemem != .no_mod_ref and effects.argmem == .no_mod_ref and effects.other == .no_mod_ref;
        }
    };

    memory_effects: ?MemoryEffects = null,
    readnone: bool = false,
    readonly: bool = false,
    writeonly: bool = false,
    argmemonly: bool = false,
    inaccessiblememonly: bool = false,
    nofree: bool = false,
    norecurse: bool = false,
    nosync: bool = false,
    nounwind: bool = false,
    willreturn: bool = false,
    @"noinline": bool = false,
    alwaysinline: bool = false,
    cold: bool = false,

    pub fn merge(attrs: *AttributeSet, other: AttributeSet) void {
        if (attrs.memory_effects) |current| {
            if (other.memory_effects) |other_effects| {
                attrs.memory_effects = current.intersect(other_effects);
            }
        } else if (other.memory_effects) |other_effects| {
            attrs.memory_effects = other_effects;
        }
        attrs.readnone = attrs.readnone or other.readnone;
        attrs.readonly = attrs.readonly or other.readonly;
        attrs.writeonly = attrs.writeonly or other.writeonly;
        attrs.argmemonly = attrs.argmemonly or other.argmemonly;
        attrs.inaccessiblememonly = attrs.inaccessiblememonly or other.inaccessiblememonly;
        attrs.nofree = attrs.nofree or other.nofree;
        attrs.norecurse = attrs.norecurse or other.norecurse;
        attrs.nosync = attrs.nosync or other.nosync;
        attrs.nounwind = attrs.nounwind or other.nounwind;
        attrs.willreturn = attrs.willreturn or other.willreturn;
        attrs.@"noinline" = attrs.@"noinline" or other.@"noinline";
        attrs.alwaysinline = attrs.alwaysinline or other.alwaysinline;
        attrs.cold = attrs.cold or other.cold;
    }

    pub fn fromText(text: ?[]const u8) AttributeSet {
        var attrs: AttributeSet = .{};
        const attr_text = text orelse return attrs;
        attrs.memory_effects = parseMemoryEffects(attr_text);
        var it = std.mem.tokenizeAny(u8, attr_text, " \t,");
        while (it.next()) |token| {
            if (std.mem.eql(u8, token, "readnone")) {
                attrs.readnone = true;
            } else if (std.mem.eql(u8, token, "readonly")) {
                attrs.readonly = true;
            } else if (std.mem.eql(u8, token, "writeonly")) {
                attrs.writeonly = true;
            } else if (std.mem.eql(u8, token, "argmemonly")) {
                attrs.argmemonly = true;
            } else if (std.mem.eql(u8, token, "inaccessiblememonly")) {
                attrs.inaccessiblememonly = true;
            } else if (std.mem.eql(u8, token, "nofree")) {
                attrs.nofree = true;
            } else if (std.mem.eql(u8, token, "norecurse")) {
                attrs.norecurse = true;
            } else if (std.mem.eql(u8, token, "nosync")) {
                attrs.nosync = true;
            } else if (std.mem.eql(u8, token, "nounwind")) {
                attrs.nounwind = true;
            } else if (std.mem.eql(u8, token, "willreturn")) {
                attrs.willreturn = true;
            } else if (std.mem.eql(u8, token, "noinline")) {
                attrs.@"noinline" = true;
            } else if (std.mem.eql(u8, token, "alwaysinline")) {
                attrs.alwaysinline = true;
            } else if (std.mem.eql(u8, token, "cold")) {
                attrs.cold = true;
            }
        }
        attrs.applyLegacyMemoryAttributes();
        attrs.syncFlagsFromMemoryEffects();
        return attrs;
    }

    fn applyLegacyMemoryAttributes(attrs: *AttributeSet) void {
        if (attrs.readnone) {
            attrs.memory_effects = .none();
            return;
        }
        if (attrs.memory_effects != null) return;

        var effect: ?ModRef = null;
        if (attrs.readonly and attrs.writeonly) {
            effect = .mod_ref;
        } else if (attrs.readonly) {
            effect = .ref;
        } else if (attrs.writeonly) {
            effect = .mod;
        } else if (attrs.argmemonly or attrs.inaccessiblememonly) {
            effect = .mod_ref;
        }

        const mod_ref = effect orelse return;
        if (attrs.argmemonly and attrs.inaccessiblememonly) {
            attrs.memory_effects = .{
                .argmem = mod_ref,
                .inaccessiblemem = mod_ref,
            };
        } else if (attrs.argmemonly) {
            attrs.memory_effects = .argMemOnly(mod_ref);
        } else if (attrs.inaccessiblememonly) {
            attrs.memory_effects = .inaccessibleMemOnly(mod_ref);
        } else {
            attrs.memory_effects = .all(mod_ref);
        }
    }

    fn syncFlagsFromMemoryEffects(attrs: *AttributeSet) void {
        const effects = attrs.memory_effects orelse return;
        const overall = effects.overall();
        attrs.readnone = attrs.readnone or overall == .no_mod_ref;
        attrs.readonly = attrs.readonly or (overall.hasRef() and !overall.hasMod());
        attrs.writeonly = attrs.writeonly or (overall.hasMod() and !overall.hasRef());
        attrs.argmemonly = attrs.argmemonly or effects.onlyAccessesArgMemory();
        attrs.inaccessiblememonly = attrs.inaccessiblememonly or effects.onlyAccessesInaccessibleMemory();
    }
};

fn modRefBits(value: AttributeSet.ModRef) u2 {
    return switch (value) {
        .no_mod_ref => 0,
        .ref => 1,
        .mod => 2,
        .mod_ref => 3,
    };
}

fn modRefFromBits(bits: u2) AttributeSet.ModRef {
    return switch (bits) {
        0 => .no_mod_ref,
        1 => .ref,
        2 => .mod,
        3 => .mod_ref,
    };
}

fn parseMemoryEffects(text: []const u8) ?AttributeSet.MemoryEffects {
    if (std.mem.indexOf(u8, text, "memory(")) |start| {
        const body_start = start + "memory(".len;
        const body_end = std.mem.indexOfScalarPos(u8, text, body_start, ')') orelse return null;
        var effects = AttributeSet.MemoryEffects.none();
        var fields = std.mem.splitScalar(u8, text[body_start..body_end], ',');
        while (fields.next()) |raw_field| {
            const field = std.mem.trim(u8, raw_field, " \t");
            const colon = std.mem.indexOfScalar(u8, field, ':');
            if (colon) |colon_index| {
                const location = std.mem.trim(u8, field[0..colon_index], " \t");
                const effect = parseModRef(std.mem.trim(u8, field[colon_index + 1 ..], " \t")) orelse {
                    effects.other = .mod_ref;
                    continue;
                };
                if (std.mem.eql(u8, location, "argmem")) {
                    effects.argmem = effect;
                } else if (std.mem.eql(u8, location, "inaccessiblemem")) {
                    effects.inaccessiblemem = effect;
                } else if (std.mem.startsWith(u8, location, "target_mem")) {
                    effects.other = effects.other.merge(effect);
                } else {
                    effects.other = effects.other.merge(effect);
                }
            } else if (parseModRef(field)) |effect| {
                effects = AttributeSet.MemoryEffects.all(effect);
            } else {
                effects = AttributeSet.MemoryEffects.all(.mod_ref);
            }
        }
        return effects;
    }
    return null;
}

fn parseModRef(text: []const u8) ?AttributeSet.ModRef {
    if (std.mem.eql(u8, text, "none")) return .no_mod_ref;
    if (std.mem.eql(u8, text, "read")) return .ref;
    if (std.mem.eql(u8, text, "write")) return .mod;
    if (std.mem.eql(u8, text, "readwrite")) return .mod_ref;
    return null;
}

pub fn functionAttributes(function: ir.Function) AttributeSet {
    return AttributeSet.fromText(function.attrs);
}

pub fn resolvedFunctionAttributes(module: ir.Module, function: ir.Function) AttributeSet {
    return attributesFromModuleText(module, function.attrs);
}

pub fn declarationAttributes(decl: ir.FunctionDecl) AttributeSet {
    return AttributeSet.fromText(decl.attrs);
}

pub fn resolvedDeclarationAttributes(module: ir.Module, decl: ir.FunctionDecl) AttributeSet {
    return attributesFromModuleText(module, decl.attrs);
}

pub fn callMemoryEffect(module: ir.Module, call: ir.CallInst) memory_effect.Effect {
    const attrs = resolvedCallAttributes(module, call) orelse return .unknown;
    const effects = attrs.memory_effects orelse {
        if (attrs.readnone) return .none;
        if (attrs.readonly and !attrs.writeonly) return .readonly_load;
        if (attrs.writeonly and !attrs.readonly) return .memory_write;
        return .unknown;
    };
    const overall = effects.overall();
    if (overall == .no_mod_ref) return .none;
    if (overall.hasRef() and !overall.hasMod()) return .readonly_load;
    if (overall.hasMod() and !overall.hasRef()) return .memory_write;
    return .unknown;
}

pub fn resolvedCallAttributes(module: ir.Module, call: ir.CallInst) ?AttributeSet {
    if (call.inline_asm != null) return null;
    if (call.operand_bundle != null) return null;
    if (call.callee_value != null) return null;
    var attrs = attributesFromModuleText(module, call.attrs);
    if (calleeAttributes(module, call.callee)) |callee_attrs| {
        attrs.merge(callee_attrs);
    } else if (attrs.memory_effects == null and call.attrs == null) {
        return null;
    }
    return attrs;
}

pub fn resolvedCalleeAttributes(module: ir.Module, name: []const u8) ?AttributeSet {
    return calleeAttributes(module, name);
}

fn calleeAttributes(module: ir.Module, name: []const u8) ?AttributeSet {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return attributesFromModuleText(module, function.attrs);
    }
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return attributesFromModuleText(module, decl.attrs);
    }
    return null;
}

fn attributesFromModuleText(module: ir.Module, text: ?[]const u8) AttributeSet {
    var attrs = AttributeSet.fromText(text);
    const attr_text = text orelse return attrs;

    var it = std.mem.tokenizeAny(u8, attr_text, " \t,");
    while (it.next()) |token| {
        if (!std.mem.startsWith(u8, token, "#")) continue;
        const group_text = findAttributeGroup(module, token[1..]) orelse continue;
        attrs.merge(AttributeSet.fromText(group_text));
    }
    return attrs;
}

fn findAttributeGroup(module: ir.Module, group_id: []const u8) ?[]const u8 {
    for (module.attribute_groups.items) |group| {
        var rest = std.mem.trim(u8, group["attributes ".len..], " \t");
        if (!std.mem.startsWith(u8, rest, "#")) continue;
        rest = rest[1..];
        const id_end = std.mem.indexOfAny(u8, rest, " \t") orelse continue;
        if (std.mem.eql(u8, rest[0..id_end], group_id)) return group;
    }
    return null;
}
