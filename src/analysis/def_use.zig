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
                try uses.addInstructionOperands(instruction);
            }
            if (block.terminator) |terminator| try uses.addTerminator(terminator);
        }

        return uses;
    }

    pub fn isUsed(uses: UseCounts, name: []const u8) bool {
        return uses.counts.contains(name);
    }

    // Counts retain their historical structured-value scope. Opaque references
    // are not counted; clients requiring completeness should use ir.operands
    // and inspect Coverage before making a deletion/escape decision.
    pub fn addInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) !void {
        _ = try ir.operands.instruction(&instruction, Adder{ .uses = uses });
    }

    pub fn removeInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) void {
        _ = ir.operands.instruction(&instruction, Remover{ .uses = uses }) catch unreachable;
    }

    pub fn addTerminator(uses: *UseCounts, terminator: ir.Terminator) !void {
        _ = try ir.operands.terminator(&terminator, Adder{ .uses = uses });
    }

    const Adder = struct {
        pub const Error = std.mem.Allocator.Error;
        uses: *UseCounts,

        pub fn visit(visitor: Adder, value: *const ir.Value, _: ir.Type) Error!void {
            try visitor.uses.addValue(value.*);
        }
    };

    const Remover = struct {
        pub const Error = error{};
        uses: *UseCounts,

        pub fn visit(visitor: Remover, value: *const ir.Value, _: ir.Type) Error!void {
            visitor.uses.removeValue(value.*);
        }
    };

    fn addValue(uses: *UseCounts, value: ir.Value) !void {
        switch (value) {
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
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
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => {},
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
