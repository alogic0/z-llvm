//! Split switch edges into PHI blocks so ordinary unconditional-edge parallel
//! copies own the moves. Duplicate switch destinations share one edge block.
const std = @import("std");
const ir = @import("../../../ir.zig");
const names = @import("scalar_forms.zig");
const helpers = @import("composed_helpers.zig");
const machine = @import("../machine.zig");

const Edge = struct { from: usize, to: usize, name: []const u8 };

// Original block names borrow the module's lifetime. Added block names borrow
// the private legalization arena, so selected machine branches must own them.
pub fn retainLabels(allocator: std.mem.Allocator, output: *machine.MachineFunction, blocks: []const ir.BasicBlock) !void {
    for (blocks) |block| {
        const label = try allocator.dupe(u8, block.name);
        errdefer allocator.free(label);
        try output.owned_labels.append(allocator, label);
        for (output.instructions.items) |*inst| switch (inst.*) {
            .label, .je, .jne, .jo, .jc, .jp, .js, .jae, .jle, .jmp => |*target| {
                if (std.mem.eql(u8, target.*, block.name)) target.* = label;
            },
            else => {},
        };
    }
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function) !?ir.Function {
    var edges: std.ArrayList(Edge) = .empty;
    var serial: names.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |block, from| {
        const term = block.terminator orelse continue;
        if (term != .@"switch") continue;
        for (0..term.@"switch".cases.items.len + 1) |index| {
            const target = if (index == 0) term.@"switch".default_target else term.@"switch".cases.items[index - 1].target;
            const to = function.blockIndex(target) orelse return null;
            if (!helpers.blockHasPhiIncomingFrom(function.blocks.items[to], block.name)) continue;
            var duplicate = false;
            for (edges.items) |edge| if (edge.from == from and edge.to == to) {
                duplicate = true;
            };
            if (duplicate) continue;
            try edges.append(allocator, .{ .from = from, .to = to, .name = try names.temporary(allocator, function, &serial) });
        }
    }
    if (edges.items.len == 0) return null;
    var result = function;
    result.blocks = .empty;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        for (original.instructions.items) |inst| try block.instructions.append(allocator, try inst.clone(allocator));
        if (block.terminator) |*term| if (term.* == .@"switch") {
            term.@"switch".cases = try term.@"switch".cases.clone(allocator);
        };
        try result.blocks.append(allocator, block);
    }
    for (edges.items) |edge| {
        const predecessor = function.blocks.items[edge.from].name;
        const target = function.blocks.items[edge.to].name;
        const term = &result.blocks.items[edge.from].terminator.?.@"switch";
        if (ir.identifiers.eql(term.default_target, target)) term.default_target = edge.name;
        for (term.cases.items) |*case| if (ir.identifiers.eql(case.target, target)) {
            case.target = edge.name;
        };
        for (result.blocks.items[edge.to].instructions.items) |*inst| {
            if (inst.removed or inst.kind != .phi) continue;
            const phi = &inst.kind.phi;
            var value: ?ir.Value = null;
            var index: usize = 0;
            while (index < phi.incoming.items.len) {
                const incoming = phi.incoming.items[index];
                if (!ir.identifiers.eql(incoming.block, predecessor)) {
                    index += 1;
                    continue;
                }
                if (value) |previous| {
                    if (!previous.eql(incoming.value)) return null;
                    _ = phi.incoming.orderedRemove(index);
                } else {
                    value = incoming.value;
                    phi.incoming.items[index].block = edge.name;
                    index += 1;
                }
            }
            if (value == null) return null;
        }
        var block = ir.BasicBlock.init(edge.name);
        block.terminator = .{ .br = .{ .target = target } };
        try result.blocks.append(allocator, block);
    }
    return result;
}
