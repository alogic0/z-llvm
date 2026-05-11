const std = @import("std");
const ir = @import("../ir.zig");
const memory_effect = @import("memory_effect.zig");

pub const AttributeSet = struct {
    readnone: bool = false,
    readonly: bool = false,
    writeonly: bool = false,
    argmemonly: bool = false,
    nofree: bool = false,
    norecurse: bool = false,
    nosync: bool = false,
    nounwind: bool = false,
    willreturn: bool = false,
    @"noinline": bool = false,
    alwaysinline: bool = false,
    cold: bool = false,

    pub fn merge(attrs: *AttributeSet, other: AttributeSet) void {
        attrs.readnone = attrs.readnone or other.readnone;
        attrs.readonly = attrs.readonly or other.readonly;
        attrs.writeonly = attrs.writeonly or other.writeonly;
        attrs.argmemonly = attrs.argmemonly or other.argmemonly;
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
        if (hasMemoryEffect(attr_text, "none")) attrs.readnone = true;
        if (hasMemoryEffect(attr_text, "read")) attrs.readonly = true;
        if (hasMemoryEffect(attr_text, "write")) attrs.writeonly = true;
        if (std.mem.indexOf(u8, attr_text, "argmem: read") != null) attrs.readonly = true;
        if (std.mem.indexOf(u8, attr_text, "argmem: write") != null) attrs.writeonly = true;
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
        return attrs;
    }
};

fn hasMemoryEffect(text: []const u8, effect: []const u8) bool {
    var search_start: usize = 0;
    while (std.mem.indexOfPos(u8, text, search_start, "memory(")) |start| {
        const body_start = start + "memory(".len;
        const body_end = std.mem.indexOfScalarPos(u8, text, body_start, ')') orelse return false;
        var fields = std.mem.splitScalar(u8, text[body_start..body_end], ',');
        while (fields.next()) |raw_field| {
            const field = std.mem.trim(u8, raw_field, " \t");
            if (std.mem.eql(u8, field, effect)) return true;
        }
        search_start = body_end + 1;
    }
    return false;
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
    const attrs = calleeAttributes(module, call.callee) orelse return .unknown;
    if (attrs.readnone) return .none;
    if (attrs.readonly and !attrs.writeonly) return .readonly_load;
    if (attrs.writeonly and !attrs.readonly) return .memory_write;
    return .unknown;
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
