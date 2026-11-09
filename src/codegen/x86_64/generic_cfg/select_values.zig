//! Choose concrete values for explicit undefined scalar select arms in the
//! private graph. The condition and every defined arm retain their semantics.
const std = @import("std");
const ir = @import("../../../ir.zig");

fn undefinedValue(value: ir.Value) bool {
    return value == .undef or value == .poison;
}

fn needsSelect(select: ir.SelectInst) bool {
    return (select.ty == .ptr or (select.ty == .int and select.ty.int > 0 and select.ty.int <= 128)) and
        (undefinedValue(select.true_value) or undefinedValue(select.false_value));
}

pub fn requiresNormalization(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .select and needsSelect(inst.kind.select)) return true;
    };
    return false;
}

pub fn normalize(allocator: std.mem.Allocator, function: ir.Function) !ir.Function {
    if (!requiresNormalization(function)) return function;
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.kind == .select and needsSelect(inst.kind.select)) {
                const concrete: ir.Value = if (inst.kind.select.ty == .ptr) .null_value else .{ .int = 0 };
                if (undefinedValue(copy.kind.select.true_value)) copy.kind.select.true_value = concrete;
                if (undefinedValue(copy.kind.select.false_value)) copy.kind.select.false_value = concrete;
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
