const std = @import("std");
const ir = @import("../ir/core.zig");
const datalayout = @import("datalayout.zig");
const triple = @import("triple.zig");

pub const ValueClass = enum {
    ignore,
    integer,
    pointer,
};

pub const Slot = enum {
    ret,
    param,
};

pub const Classification = struct {
    target: triple.SupportedTarget,
    slot: Slot,
    value_class: ValueClass,
    size_bits: u16 = 0,
};

pub const FunctionSignature = struct {
    return_value: Classification,
    params: std.ArrayList(Classification),

    pub fn deinit(signature: *FunctionSignature, allocator: std.mem.Allocator) void {
        signature.params.deinit(allocator);
    }
};

pub fn classifyReturn(target_triple: triple.Triple, layout: datalayout.DataLayout, ty: ir.Type) !Classification {
    return classify(target_triple, layout, .ret, ty);
}

pub fn classifyParam(target_triple: triple.Triple, layout: datalayout.DataLayout, ty: ir.Type) !Classification {
    if (ty == .void) return error.UnsupportedAbiType;
    return classify(target_triple, layout, .param, ty);
}

pub fn classifyFunction(
    allocator: std.mem.Allocator,
    target_triple: triple.Triple,
    layout: datalayout.DataLayout,
    function: ir.Function,
) !FunctionSignature {
    var signature: FunctionSignature = .{
        .return_value = try classifyReturn(target_triple, layout, function.ret_ty),
        .params = .empty,
    };
    errdefer signature.deinit(allocator);

    for (function.params.items) |param| {
        try signature.params.append(allocator, try classifyParam(target_triple, layout, param.ty));
    }

    return signature;
}

fn classify(target_triple: triple.Triple, layout: datalayout.DataLayout, slot: Slot, ty: ir.Type) !Classification {
    const supported = target_triple.supportedTarget() orelse return error.UnsupportedTarget;
    return switch (ty) {
        .void => .{
            .target = supported,
            .slot = slot,
            .value_class = .ignore,
        },
        .int => |bits| .{
            .target = supported,
            .slot = slot,
            .value_class = .integer,
            .size_bits = bits,
        },
        .ptr => .{
            .target = supported,
            .slot = slot,
            .value_class = .pointer,
            .size_bits = try layout.pointerSizeBits(),
        },
        .float, .double, .aggregate => return error.UnsupportedType,
    };
}
