const std = @import("std");
const ir = @import("../ir.zig");

pub const UseCounts = struct {
    allocator: std.mem.Allocator,
    counts: std.StringHashMap(usize),

    pub fn init(allocator: std.mem.Allocator) UseCounts {
        return .{
            .allocator = allocator,
            .counts = std.StringHashMap(usize).init(allocator),
        };
    }

    pub fn deinit(uses: *UseCounts) void {
        uses.counts.deinit();
    }

    pub fn collectFunction(allocator: std.mem.Allocator, function: ir.Function) !UseCounts {
        var uses = UseCounts.init(allocator);
        errdefer uses.deinit();

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                try uses.addValue(instruction.lhs);
                try uses.addValue(instruction.rhs);
            }
            if (block.terminator) |terminator| try uses.addTerminator(terminator);
        }

        return uses;
    }

    pub fn isUsed(uses: UseCounts, name: []const u8) bool {
        return uses.counts.contains(name);
    }

    pub fn addInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) !void {
        try uses.addValue(instruction.lhs);
        try uses.addValue(instruction.rhs);
    }

    pub fn removeInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) void {
        uses.removeValue(instruction.lhs);
        uses.removeValue(instruction.rhs);
    }

    pub fn addTerminator(uses: *UseCounts, terminator: ir.Terminator) !void {
        switch (terminator) {
            .ret => |ret| try uses.addValue(ret.value),
            .br => {},
            .condbr => |condbr| try uses.addValue(condbr.cond),
        }
    }

    fn addValue(uses: *UseCounts, value: ir.Value) !void {
        switch (value) {
            .int => {},
            .named => |name| {
                const gop = try uses.counts.getOrPut(name);
                if (gop.found_existing) {
                    gop.value_ptr.* += 1;
                } else {
                    gop.value_ptr.* = 1;
                }
            },
        }
    }

    fn removeValue(uses: *UseCounts, value: ir.Value) void {
        switch (value) {
            .int => {},
            .named => |name| {
                const count_ptr = uses.counts.getPtr(name) orelse return;
                if (count_ptr.* <= 1) {
                    _ = uses.counts.remove(name);
                } else {
                    count_ptr.* -= 1;
                }
            },
        }
    }
};
