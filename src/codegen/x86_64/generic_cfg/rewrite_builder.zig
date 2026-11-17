//! Construction shared by small private instruction rewrites. The caller owns
//! an arena and keeps source payloads alive and immutable through consumption.
const std = @import("std");
const ir = @import("../../../ir.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");

pub const Builder = struct {
    candidate: Candidate,
    names: forms.TemporaryNames,
    prefixes: std.ArrayList(ir.Instruction) = .empty,

    pub fn init(a: std.mem.Allocator, source: ir.Function, prefix: []const u8) Builder {
        return .{ .candidate = Candidate.init(a, source), .names = .{ .prefix = prefix } };
    }

    pub fn deinit(self: *Builder) void {
        self.names.deinit(self.candidate.allocator);
        self.prefixes.deinit(self.candidate.allocator);
        // Candidate arrays and generated payloads belong to the caller's arena.
        // Kept instructions may still borrow operand arrays from the source.
    }

    pub fn begin(self: *Builder, block: *ir.BasicBlock, block_index: usize, instruction_index: usize) !void {
        try self.candidate.begin(block, block_index, instruction_index);
    }

    pub fn temporary(self: *Builder) ![]const u8 {
        return forms.temporary(self.candidate.allocator, self.candidate.source, &self.names);
    }

    pub fn keep(self: *Builder, block: *ir.BasicBlock, instruction: ir.Instruction) !void {
        try self.candidate.keep(block, instruction);
    }

    pub fn append(self: *Builder, block: *ir.BasicBlock, instruction: ir.Instruction) !void {
        std.debug.assert(self.candidate.started);
        try block.instructions.append(self.candidate.allocator, instruction);
    }

    pub fn entryPrefix(self: *Builder, instruction: ir.Instruction) !void {
        std.debug.assert(self.candidate.started);
        try self.prefixes.append(self.candidate.allocator, instruction);
    }

    pub fn finishBlock(self: *Builder, block: ir.BasicBlock) !void {
        try self.candidate.finishBlock(block);
    }

    /// Publish only after all construction, including the entry prefix, succeeds.
    pub fn finish(self: *Builder) !?ir.Function {
        const result = self.candidate.finish() orelse return null;
        if (self.prefixes.items.len == 0) return result;
        std.debug.assert(result.blocks.items.len != 0);
        const a = self.candidate.allocator;
        const entry = &result.blocks.items[0];
        var instructions: std.ArrayList(ir.Instruction) = .empty;
        var leading: usize = 0;
        while (leading < entry.instructions.items.len and entry.instructions.items[leading].kind == .phi) : (leading += 1) {}
        try instructions.appendSlice(a, entry.instructions.items[0..leading]);
        try instructions.appendSlice(a, self.prefixes.items);
        try instructions.appendSlice(a, entry.instructions.items[leading..]);
        // Candidate.begin makes every instruction-array buffer private. Free
        // only that buffer, without deinitializing borrowed instruction payloads.
        entry.instructions.deinit(a);
        entry.instructions = instructions;
        return result;
    }
};
