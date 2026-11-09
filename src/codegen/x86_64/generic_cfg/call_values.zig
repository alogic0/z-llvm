//! Refine explicit undefined scalar call operands in the private IR. Choosing
//! zero/null avoids consuming uninitialized machine state; defined operands,
//! call facts, and the public ABI remain unchanged.
const std = @import("std");
const ir = @import("../../../ir.zig");

fn needsValue(arg: ir.CallArg) bool {
    return (arg.value == .undef or arg.value == .poison) and
        (arg.ty == .ptr or (arg.ty == .int and arg.ty.int > 0 and arg.ty.int <= 128));
}

fn needsCall(call: ir.CallInst) bool {
    for (call.args.items) |arg| if (needsValue(arg)) return true;
    return false;
}

pub fn requiresNormalization(function: ir.Function) bool {
    for (function.blocks.items) |block| for (block.instructions.items) |inst| {
        if (!inst.removed and inst.kind == .call and needsCall(inst.kind.call)) return true;
    };
    return false;
}

/// Lists are owned by the caller's private arena. All unchanged calls and the
/// source module retain their original argument-list ownership.
pub fn normalize(allocator: std.mem.Allocator, function: ir.Function) !ir.Function {
    if (!requiresNormalization(function)) return function;
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| {
            var copy = inst;
            if (!inst.removed and inst.kind == .call and needsCall(inst.kind.call)) {
                copy.kind.call.args = try inst.kind.call.args.clone(allocator);
                for (copy.kind.call.args.items) |*arg| if (needsValue(arg.*)) {
                    arg.value = if (arg.ty == .ptr) .null_value else .{ .int = 0 };
                };
            }
            try block.instructions.append(allocator, copy);
        }
        try result.blocks.append(allocator, block);
    }
    return result;
}
