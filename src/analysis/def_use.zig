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
            .cast => |cast| try uses.addValue(cast.value),
            .freeze => |freeze| try uses.addValue(freeze.value),
            .icmp => |icmp| {
                try uses.addValue(icmp.lhs);
                try uses.addValue(icmp.rhs);
            },
            .fcmp => |fcmp| {
                try uses.addValue(fcmp.lhs);
                try uses.addValue(fcmp.rhs);
            },
            .select => |select| {
                try uses.addValue(select.cond);
                try uses.addValue(select.true_value);
                try uses.addValue(select.false_value);
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
            .atomicrmw => |atomicrmw| {
                try uses.addValue(atomicrmw.ptr);
                try uses.addValue(atomicrmw.value);
            },
            .cmpxchg => |cmpxchg| {
                try uses.addValue(cmpxchg.ptr);
                try uses.addValue(cmpxchg.expected);
                try uses.addValue(cmpxchg.replacement);
            },
            .fence => {},
            .extractelement => |extract| {
                try uses.addValue(extract.vector);
                try uses.addValue(extract.index);
            },
            .insertelement => |insert| {
                try uses.addValue(insert.vector);
                try uses.addValue(insert.value);
                try uses.addValue(insert.index);
            },
            .shufflevector => |shuffle| {
                try uses.addValue(shuffle.lhs);
                try uses.addValue(shuffle.rhs);
                try uses.addValue(shuffle.mask);
            },
            .gep => |gep| {
                try uses.addValue(gep.ptr);
                for (gep.indices.items) |index| try uses.addValue(index.value);
            },
            .call => |call| for (call.args.items) |arg| {
                try uses.addValue(arg.value);
            },
        }
    }

    pub fn removeInstructionOperands(uses: *UseCounts, instruction: ir.Instruction) void {
        switch (instruction.kind) {
            .binary => |binary| {
                uses.removeValue(binary.lhs);
                uses.removeValue(binary.rhs);
            },
            .cast => |cast| uses.removeValue(cast.value),
            .freeze => |freeze| uses.removeValue(freeze.value),
            .icmp => |icmp| {
                uses.removeValue(icmp.lhs);
                uses.removeValue(icmp.rhs);
            },
            .fcmp => |fcmp| {
                uses.removeValue(fcmp.lhs);
                uses.removeValue(fcmp.rhs);
            },
            .select => |select| {
                uses.removeValue(select.cond);
                uses.removeValue(select.true_value);
                uses.removeValue(select.false_value);
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
            .atomicrmw => |atomicrmw| {
                uses.removeValue(atomicrmw.ptr);
                uses.removeValue(atomicrmw.value);
            },
            .cmpxchg => |cmpxchg| {
                uses.removeValue(cmpxchg.ptr);
                uses.removeValue(cmpxchg.expected);
                uses.removeValue(cmpxchg.replacement);
            },
            .fence => {},
            .extractelement => |extract| {
                uses.removeValue(extract.vector);
                uses.removeValue(extract.index);
            },
            .insertelement => |insert| {
                uses.removeValue(insert.vector);
                uses.removeValue(insert.value);
                uses.removeValue(insert.index);
            },
            .shufflevector => |shuffle| {
                uses.removeValue(shuffle.lhs);
                uses.removeValue(shuffle.rhs);
                uses.removeValue(shuffle.mask);
            },
            .gep => |gep| {
                uses.removeValue(gep.ptr);
                for (gep.indices.items) |index| uses.removeValue(index.value);
            },
            .call => |call| for (call.args.items) |arg| {
                uses.removeValue(arg.value);
            },
        }
    }

    pub fn addTerminator(uses: *UseCounts, terminator: ir.Terminator) !void {
        switch (terminator) {
            .ret => |ret| if (ret.value) |value| try uses.addValue(value),
            .br => {},
            .@"unreachable" => {},
            .condbr => |condbr| try uses.addValue(condbr.cond),
        }
    }

    fn addValue(uses: *UseCounts, value: ir.Value) !void {
        switch (value) {
            .int, .fp, .undef, .null_value, .zero_initializer, .vector => {},
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
            .int, .fp, .undef, .null_value, .zero_initializer, .vector => {},
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
