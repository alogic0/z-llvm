const std = @import("std");
const ir = @import("../ir.zig");
const memory_effect = @import("memory_effect.zig");

pub const AttributeSet = struct {
    readnone: bool = false,
    readonly: bool = false,
    nounwind: bool = false,
    @"noinline": bool = false,
    alwaysinline: bool = false,
    cold: bool = false,

    pub fn fromText(text: ?[]const u8) AttributeSet {
        var attrs: AttributeSet = .{};
        const attr_text = text orelse return attrs;
        var it = std.mem.tokenizeAny(u8, attr_text, " \t,");
        while (it.next()) |token| {
            if (std.mem.eql(u8, token, "readnone")) {
                attrs.readnone = true;
            } else if (std.mem.eql(u8, token, "readonly")) {
                attrs.readonly = true;
            } else if (std.mem.eql(u8, token, "nounwind")) {
                attrs.nounwind = true;
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

pub fn functionAttributes(function: ir.Function) AttributeSet {
    return AttributeSet.fromText(function.attrs);
}

pub fn declarationAttributes(decl: ir.FunctionDecl) AttributeSet {
    return AttributeSet.fromText(decl.attrs);
}

pub fn callMemoryEffect(module: ir.Module, call: ir.CallInst) memory_effect.Effect {
    const attrs = calleeAttributes(module, call.callee) orelse return .unknown;
    if (attrs.readnone) return .none;
    if (attrs.readonly) return .readonly_load;
    return .unknown;
}

fn calleeAttributes(module: ir.Module, name: []const u8) ?AttributeSet {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return functionAttributes(function);
    }
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return declarationAttributes(decl);
    }
    return null;
}
