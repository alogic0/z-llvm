//! Scalar floating RMWs use an integer compare/exchange loop. The returned
//! payload is the successful old value; retry observations feed the next try.
const std = @import("std");
const ir = @import("../../../ir.zig");
const forms = @import("scalar_forms.zig");
const atomics = @import("composed_selector_atomic.zig");

fn supported(x: @import("../../../ir/core.zig").AtomicRmwInst) bool {
    if (x.ty != .float and x.ty != .double) return false;
    if (!atomics.supportedScope(x.syncscope)) return false;
    if (x.@"align") |alignment| if (!std.math.isPowerOfTwo(alignment) or alignment < (if (x.ty == .float) @as(u64, 4) else 8)) return false;
    var ordered = false;
    for ([_][]const u8{ "monotonic", "acquire", "release", "acq_rel", "seq_cst" }) |name| ordered = ordered or std.mem.eql(u8, name, x.ordering);
    if (!ordered) return false;
    for ([_][]const u8{ "fadd", "fsub", "fmax", "fmin" }) |name| if (std.mem.eql(u8, name, x.op)) return true;
    return false;
}

const Builder = struct {
    a: std.mem.Allocator,
    source: ir.Function,
    names: *forms.TemporaryNames,
    block: *ir.BasicBlock,

    fn name(b: Builder) ![]const u8 {
        return forms.temporary(b.a, b.source, b.names);
    }
    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const next = try b.name();
        try b.block.instructions.append(b.a, .{ .result = next, .kind = kind });
        return .{ .named = next };
    }
    fn cast(b: Builder, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = .bitcast, .from_ty = from, .value = value, .to_ty = to } });
    }
    fn select(b: Builder, condition: ir.Value, ty: ir.Type, yes: ir.Value, no: ir.Value) !ir.Value {
        return b.emit(.{ .select = .{ .cond_ty = .{ .int = 1 }, .cond = condition, .ty = ty, .true_value = yes, .false_value = no } });
    }
};

pub fn legalize(a: std.mem.Allocator, function: ir.Function) !?ir.Function {
    for (function.blocks.items, 0..) |original, block_index| for (original.instructions.items, 0..) |inst, instruction_index| {
        if (inst.removed or inst.kind != .atomicrmw or !supported(inst.kind.atomicrmw)) continue;
        const x = inst.kind.atomicrmw;
        const result_name = inst.result orelse return null;
        const word: ir.Type = .{ .int = if (x.ty == .float) 32 else 64 };
        var names: forms.TemporaryNames = .{ .prefix = "__zllvm_float_atomic_" };
        defer names.deinit(a);
        var prefix = original;
        prefix.instructions = .empty;
        try prefix.instructions.appendSlice(a, original.instructions.items[0..instruction_index]);
        var b: Builder = .{ .a = a, .source = function, .names = &names, .block = &prefix };
        const loop_name = try b.name();
        const tail_name = try b.name();
        const initial = try b.emit(.{ .load = .{ .ty = word, .ptr = x.ptr, .attrs = .{
            .atomic_ordering = "monotonic",
            .syncscope = x.syncscope,
            .@"align" = x.@"align",
        } } });
        prefix.terminator = .{ .br = .{ .target = loop_name } };
        var loop = ir.BasicBlock.init(loop_name);
        b.block = &loop;
        const observed = try b.name();
        var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
        try incoming.appendSlice(a, &.{ .{ .value = initial, .block = original.name }, .{ .value = .{ .named = observed }, .block = loop_name } });
        const expected = try b.emit(.{ .phi = .{ .ty = word, .incoming = incoming } });
        const old = try b.cast(word, expected, x.ty);
        const operand: ir.Value = if (x.value == .undef or x.value == .poison) .{ .fp = "0.000000e+00" } else x.value;
        const next = if (std.mem.eql(u8, x.op, "fadd") or std.mem.eql(u8, x.op, "fsub")) next: {
            const computed = try b.emit(.{ .binary = .{ .op = if (std.mem.eql(u8, x.op, "fadd")) .fadd else .fsub, .ty = x.ty, .lhs = old, .rhs = operand } });
            break :next try b.cast(x.ty, computed, word);
        } else next: {
            // maxnum/minnum choose the numeric operand when exactly one is a
            // NaN. For equal zeros use +0 for maxnum and -0 for minnum.
            const maximum = std.mem.eql(u8, x.op, "fmax");
            const better = try b.emit(.{ .fcmp = .{ .predicate = if (maximum) .ogt else .olt, .operand_ty = x.ty, .lhs = old, .rhs = operand } });
            const other = try b.cast(x.ty, operand, word);
            const chosen = try b.select(better, word, expected, other);
            const equal = try b.emit(.{ .fcmp = .{ .predicate = .oeq, .operand_ty = x.ty, .lhs = old, .rhs = operand } });
            const tied = try b.emit(.{ .binary = .{ .op = if (maximum) .@"and" else .@"or", .ty = word, .lhs = expected, .rhs = other } });
            const numeric = try b.select(equal, word, tied, chosen);
            const other_nan = try b.emit(.{ .fcmp = .{ .predicate = .uno, .operand_ty = x.ty, .lhs = operand, .rhs = operand } });
            break :next try b.select(other_nan, word, expected, numeric);
        };
        const tuple: ir.Type = .{ .aggregate = if (x.ty == .float) "{ i32, i1 }" else "{ i64, i1 }" };
        const exchanged = try b.emit(.{ .cmpxchg = .{
            .ptr = x.ptr,
            .ty = word,
            .result_ty = tuple,
            .expected = expected,
            .replacement = next,
            .success_ordering = x.ordering,
            .failure_ordering = "monotonic",
            .syncscope = x.syncscope,
            .is_volatile = x.is_volatile,
            .@"align" = x.@"align",
        } });
        try loop.instructions.append(a, .{ .result = observed, .kind = .{ .extractvalue = .{ .aggregate_ty = tuple, .aggregate = exchanged, .indices = "0", .result_ty = word } } });
        const success = try b.emit(.{ .extractvalue = .{ .aggregate_ty = tuple, .aggregate = exchanged, .indices = "1", .result_ty = .{ .int = 1 } } });
        loop.terminator = .{ .condbr = .{ .cond_ty = .{ .int = 1 }, .cond = success, .then_target = tail_name, .else_target = loop_name } };
        var tail = ir.BasicBlock.init(tail_name);
        try tail.instructions.append(a, .{ .result = result_name, .metadata = inst.metadata, .kind = .{ .cast = .{ .op = .bitcast, .from_ty = word, .value = expected, .to_ty = x.ty } } });
        try tail.instructions.appendSlice(a, original.instructions.items[instruction_index + 1 ..]);
        tail.terminator = original.terminator;
        var result = function;
        result.blocks = .empty;
        for (function.blocks.items, 0..) |source_block, index| {
            if (index == block_index) {
                try result.blocks.append(a, prefix);
            } else {
                var copy = source_block;
                copy.instructions = try source_block.instructions.clone(a);
                try result.blocks.append(a, copy);
            }
        }
        try result.blocks.appendSlice(a, &.{ loop, tail });
        // Every original outgoing edge now leaves the tail, including edges
        // back to this block. Clone PHI arrays before changing predecessors.
        for (result.blocks.items) |*block| {
            if (std.mem.eql(u8, block.name, loop_name)) continue;
            for (block.instructions.items) |*instruction| {
                if (instruction.removed or instruction.kind != .phi) continue;
                var phi = &instruction.kind.phi;
                phi.incoming = try phi.incoming.clone(a);
                for (phi.incoming.items) |*edge| if (ir.identifiers.eql(edge.block, original.name)) {
                    edge.block = tail_name;
                };
            }
        }
        return result;
    };
    return null;
}
