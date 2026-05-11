const alias = @import("alias.zig");
const ir = @import("../ir.zig");

pub const InstRef = struct {
    block_index: usize,
    instruction_index: usize,
};

pub fn hasClobberBetween(function: ir.Function, from: InstRef, to: InstRef, ptr: ir.Value) bool {
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items, 0..) |instruction, instruction_index| {
            if (instruction.removed) continue;
            if (block_index == from.block_index and instruction_index <= from.instruction_index) continue;
            if (block_index == to.block_index and instruction_index >= to.instruction_index) continue;
            if (isBarrier(function, instruction, ptr)) return true;
        }
    }
    return false;
}

pub fn isBarrier(function: ir.Function, instruction: ir.Instruction, ptr: ir.Value) bool {
    return switch (alias.modRef(function, instruction, ptr)) {
        .mod, .mod_ref, .unknown => true,
        .no_mod_ref, .ref => false,
    };
}
