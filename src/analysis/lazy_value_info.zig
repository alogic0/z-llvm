const std = @import("std");
const cfg = @import("cfg.zig");
const dominator = @import("dominator.zig");
const ir = @import("../ir.zig");

pub const IcmpFact = struct {
    value: []const u8,
    predicate: ir.IcmpPredicate,
    constant: ir.Value,
};

pub const PredicateResult = enum {
    unknown,
    always_true,
    always_false,
};

pub const FactTable = struct {
    allocator: std.mem.Allocator,
    facts: std.ArrayList(std.ArrayList(IcmpFact)),

    pub fn build(allocator: std.mem.Allocator, function: ir.Function) !FactTable {
        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        var dom = try dominator.Dominators.build(allocator, function);
        defer dom.deinit();

        var table: FactTable = .{
            .allocator = allocator,
            .facts = .empty,
        };
        errdefer table.deinit();

        try table.facts.appendNTimes(allocator, .empty, function.blocks.items.len);

        for (function.blocks.items, 0..) |block, branch_index| {
            const condbr = switch (block.terminator orelse continue) {
                .condbr => |condbr| condbr,
                .ret, .br, .@"switch", .indirectbr, .@"unreachable" => continue,
            };
            const cond_name = switch (condbr.cond) {
                .named => |name| name,
                .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => continue,
            };
            const branch_icmp = findIcmpByResult(block, cond_name) orelse continue;
            const fact = icmpFact(branch_icmp) orelse continue;

            try table.addEdgeFact(function, graph, dom, branch_index, condbr.then_target, fact);
            try table.addEdgeFact(function, graph, dom, branch_index, condbr.else_target, .{
                .value = fact.value,
                .predicate = inversePredicate(fact.predicate),
                .constant = fact.constant,
            });
        }

        return table;
    }

    pub fn deinit(table: *FactTable) void {
        for (table.facts.items) |*facts| facts.deinit(table.allocator);
        table.facts.deinit(table.allocator);
    }

    pub fn predicateAt(table: FactTable, block_index: usize, icmp: ir.IcmpInst) PredicateResult {
        const query = icmpFact(icmp) orelse return .unknown;
        for (table.facts.items[block_index].items) |fact| {
            if (!sameValueFact(fact, query)) continue;
            if (fact.predicate == query.predicate) return .always_true;
            if (inversePredicate(fact.predicate) == query.predicate) return .always_false;
        }
        return .unknown;
    }

    fn addEdgeFact(
        table: *FactTable,
        function: ir.Function,
        graph: cfg.Graph,
        dom: dominator.Dominators,
        branch_index: usize,
        edge_target: []const u8,
        fact: IcmpFact,
    ) !void {
        const target_index = function.blockIndex(edge_target) orelse return;
        if (graph.predecessors(target_index).len != 1) return;
        if (graph.predecessors(target_index)[0] != branch_index) return;

        for (function.blocks.items, 0..) |_, block_index| {
            if (!dom.dominates(target_index, block_index)) continue;
            try table.facts.items[block_index].append(table.allocator, fact);
        }
    }
};

fn findIcmpByResult(block: ir.BasicBlock, result_name: []const u8) ?ir.IcmpInst {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        const result = instruction.result orelse continue;
        if (!std.mem.eql(u8, result, result_name)) continue;
        return switch (instruction.kind) {
            .icmp => |icmp| icmp,
            .binary, .cast, .freeze, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
        };
    }
    return null;
}

fn icmpFact(icmp: ir.IcmpInst) ?IcmpFact {
    const value = switch (icmp.lhs) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    return switch (icmp.rhs) {
        .int => .{
            .value = value,
            .predicate = icmp.predicate,
            .constant = icmp.rhs,
        },
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn sameValueFact(a: IcmpFact, b: IcmpFact) bool {
    return std.mem.eql(u8, a.value, b.value) and a.constant.eql(b.constant);
}

pub fn inversePredicate(predicate: ir.IcmpPredicate) ir.IcmpPredicate {
    return switch (predicate) {
        .eq => .ne,
        .ne => .eq,
        .sgt => .sle,
        .sge => .slt,
        .slt => .sge,
        .sle => .sgt,
        .ugt => .ule,
        .uge => .ult,
        .ult => .uge,
        .ule => .ugt,
    };
}
