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

pub fn classifyReturn(target_triple: triple.Triple, layout: datalayout.DataLayout, ty: ir.Type) !Classification {
    return classify(target_triple, layout, .ret, ty);
}

pub fn classifyParam(target_triple: triple.Triple, layout: datalayout.DataLayout, ty: ir.Type) !Classification {
    if (ty == .void) return error.UnsupportedAbiType;
    return classify(target_triple, layout, .param, ty);
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
    };
}
