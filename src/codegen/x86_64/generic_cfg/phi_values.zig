//! Pick concrete scalar values for undef/poison PHI inputs in the private IR.
//! This valid refinement initializes every edge home without relying on stale
//! register or stack bytes. Defined incoming edges remain unchanged.
const std = @import("std");
const ir = @import("../../../ir.zig");

fn admitted(ty: ir.Type) bool {
    return ty == .ptr or (ty == .int and ty.int > 0 and ty.int <= 128);
}

pub fn requiresNormalization(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .phi and admitted(inst.kind.phi.ty)) {
            for (inst.kind.phi.incoming.items) |incoming| if (incoming.value == .undef or incoming.value == .poison) return true;
        }
    };
    return false;
}

pub fn normalize(allocator: std.mem.Allocator, function: ir.Function) !ir.Function {
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.kind == .phi and admitted(inst.kind.phi.ty)) {
                copy.kind.phi.incoming = try inst.kind.phi.incoming.clone(allocator);
                for (copy.kind.phi.incoming.items) |*incoming| if (incoming.value == .undef or incoming.value == .poison) {
                    incoming.value = if (inst.kind.phi.ty == .ptr) .null_value else .{ .int = 0 };
                };
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
