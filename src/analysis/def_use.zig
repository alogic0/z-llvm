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

    pub fn addInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) !void {
        switch (instruction.kind) {
            .binary => |binary| {
                try uses.addValue(binary.lhs);
                try uses.addValue(binary.rhs);
            },
            .icmp => |icmp| {
                try uses.addValue(icmp.lhs);
                try uses.addValue(icmp.rhs);
            },
            .phi => |phi| for (phi.incoming.items) |incoming| {
                try uses.addValue(incoming.value);
            },
            .alloca => {},
            .load => |load| try uses.addValue(load.ptr),
            .store => |store| {
                try uses.addValue(store.value);
                try uses.addValue(store.ptr);
            },
        }
    }

    pub fn removeInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) void {
        switch (instruction.kind) {
            .binary => |binary| {
                uses.removeValue(binary.lhs);
                uses.removeValue(binary.rhs);
            },
            .icmp => |icmp| {
                uses.removeValue(icmp.lhs);
                uses.removeValue(icmp.rhs);
            },
            .phi => |phi| for (phi.incoming.items) |incoming| {
                uses.removeValue(incoming.value);
            },
            .alloca => {},
            .load => |load| uses.removeValue(load.ptr),
            .store => |store| {
                uses.removeValue(store.value);
                uses.removeValue(store.ptr);
            },
        }
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
