//! Instruction rewrites allocate a private candidate only after their first
//! change. Unchanged attempts allocate nothing. Successful candidates still
//! own separate block and instruction arrays, including untouched prefixes.
const std = @import("std");
const ir = @import("../../../ir.zig");

pub const Candidate = struct {
    allocator: std.mem.Allocator,
    source: ir.Function,
    result: ir.Function,
    started: bool = false,

    pub fn init(allocator: std.mem.Allocator, source: ir.Function) Candidate {
        var result = source;
        result.blocks = .empty;
        return .{ .allocator = allocator, .source = source, .result = result };
    }

    /// Call before emitting the first replacement for the current instruction.
    /// The caller visits every source block/instruction in its original order.
    pub fn begin(candidate: *Candidate, block: *ir.BasicBlock, block_index: usize, instruction_index: usize) !void {
        if (candidate.started) return;
        for (candidate.source.blocks.items[0..block_index]) |original| {
            var copy = original;
            copy.instructions = try original.instructions.clone(candidate.allocator);
            try candidate.result.blocks.append(candidate.allocator, copy);
        }
        try block.instructions.appendSlice(candidate.allocator, candidate.source.blocks.items[block_index].instructions.items[0..instruction_index]);
        candidate.started = true;
    }

    pub fn keep(candidate: *Candidate, block: *ir.BasicBlock, instruction: ir.Instruction) !void {
        if (candidate.started) try block.instructions.append(candidate.allocator, instruction);
    }

    pub fn finishBlock(candidate: *Candidate, block: ir.BasicBlock) !void {
        if (candidate.started) try candidate.result.blocks.append(candidate.allocator, block);
    }

    pub fn finish(candidate: Candidate) ?ir.Function {
        return if (candidate.started) candidate.result else null;
    }
};
