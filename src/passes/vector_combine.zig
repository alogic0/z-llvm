const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const integer_semantics = @import("../analysis/integer_semantics.zig");
const Dominators = @import("../analysis/dominator.zig").Dominators;

pub const pass: pass_manager.ModulePass = .{
    .name = "vector-combine",
    .category = .vector,
    .target_status = "LLVM-shaped lane-identity subset",
    .upstream_owner = "llvm/lib/Transforms/Vectorize/VectorCombine.cpp and llvm/lib/Transforms/InstCombine/InstCombineVectorOps.cpp",
    .run = run,
};

const Position = struct { block: usize, instruction: usize };

// Only instruction locations are cached. Earlier substitutions may change an
// insert's operands. CFG topology is unchanged throughout this function pass.
const Dominance = struct {
    allocator: std.mem.Allocator,
    function: *const ir.Function,
    tree: ?Dominators = null,

    fn deinit(dom: *Dominance) void {
        if (dom.tree) |*tree| tree.deinit();
    }

    fn before(dom: *Dominance, definition: Position, use: Position) !bool {
        if (definition.block == use.block) return definition.instruction < use.instruction;
        if (dom.tree == null) dom.tree = try Dominators.build(dom.allocator, dom.function.*);
        return dom.tree.?.dominates(definition.block, use.block);
    }

    fn valueAvailable(dom: *Dominance, value: ir.Value, ty: ir.Type, use: Position) !bool {
        const name = switch (value) {
            .named => |name| name,
            .vector, .constant_expr => return false,
            else => return true, // The original typed instruction was verified.
        };
        if (std.mem.startsWith(u8, name, "@")) return ty == .ptr;
        for (dom.function.params.items) |param| {
            if (std.mem.eql(u8, param.name, name)) return param.ty.eql(ty);
        }
        for (dom.function.blocks.items, 0..) |block, bi| {
            for (block.instructions.items, 0..) |inst, ii| {
                const result = inst.result orelse continue;
                if (!std.mem.eql(u8, result, name)) continue;
                if (inst.removed) return false;
                if (!(inst.resultType() orelse return false).eql(ty)) return false;
                return dom.before(.{ .block = bi, .instruction = ii }, use);
            }
        }
        return false;
    }

    fn dominatesUses(dom: *Dominance, definition: Position, name: []const u8) !bool {
        for (dom.function.blocks.items, 0..) |block, bi| {
            for (block.instructions.items, 0..) |*inst, ii| {
                if (ir.operands.instructionUses(inst, name, null).occurrences == 0) continue;
                if (inst.kind == .phi) {
                    // PHI operands are used at the end of the incoming block.
                    for (inst.kind.phi.incoming.items) |incoming| {
                        if (incoming.value != .named or !std.mem.eql(u8, incoming.value.named, name)) continue;
                        const pred = for (dom.function.blocks.items, 0..) |candidate, index| {
                            if (std.mem.eql(u8, candidate.name, incoming.block)) break index;
                        } else return false;
                        if (!try dom.before(definition, .{ .block = pred, .instruction = dom.function.blocks.items[pred].instructions.items.len })) return false;
                    }
                } else if (!try dom.before(definition, .{ .block = bi, .instruction = ii })) return false;
            }
            if (block.terminator) |*term| {
                if (ir.operands.terminatorUses(term, name, null).occurrences != 0 and
                    !try dom.before(definition, .{ .block = bi, .instruction = block.instructions.items.len })) return false;
            }
        }
        return true;
    }
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var inserted_vectors = std.StringHashMap(Position).init(module.allocator);
        defer inserted_vectors.deinit();
        var dom: Dominance = .{ .allocator = module.allocator, .function = function };
        defer dom.deinit();

        for (function.blocks.items, 0..) |*block, bi| {
            for (block.instructions.items, 0..) |*inst, ii| {
                if (inst.removed) continue;
                const position: Position = .{ .block = bi, .instruction = ii };
                switch (inst.kind) {
                    .insertelement => if (inst.result) |result| {
                        try inserted_vectors.put(result, position);
                    },
                    .extractelement => |*extract| {
                        if (try foldExtractAfterInsert(function, position, inst, extract, inserted_vectors, &dom)) changed = true;
                    },
                    else => {},
                }
            }
        }
    }
    return if (changed) .changed else .unchanged;
}

fn foldExtractAfterInsert(
    function: *ir.Function,
    position: Position,
    inst: *ir.Instruction,
    extract: *ir.ExtractElementInst,
    inserted_vectors: std.StringHashMap(Position),
    dom: *Dominance,
) !bool {
    if (extract.vector != .named) return false;
    const record = inserted_vectors.get(extract.vector.named) orelse return false;
    const producer = &function.blocks.items[record.block].instructions.items[record.instruction];
    if (producer.removed or producer.kind != .insertelement) return false;
    const insert = producer.kind.insertelement;
    const extract_lane = integer_semantics.vectorLane(extract.vector_ty, extract.index_ty, extract.index) orelse return false;
    const insert_lane = integer_semantics.vectorLane(insert.vector_ty, insert.index_ty, insert.index) orelse return false;
    if (!extract.vector_ty.eql(insert.vector_ty)) return false;
    const element_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty.elem_ty.toType(),
        else => return false,
    };
    if (!element_ty.eql(insert.value_ty)) return false;
    const producer_name = producer.result orelse return false;
    const producer_uses = ir.operands.functionUses(function, producer_name, insert.vector_ty);
    if (producer_uses.coverage.has_opaque_references or !producer_uses.types_match) return false;
    if (!try dom.before(record, position)) return false;

    if (extract_lane == insert_lane) {
        const result = inst.result orelse return false;
        const uses = ir.operands.functionUses(function, result, element_ty);
        if (uses.coverage.has_opaque_references or !uses.types_match) return false;
        if (!try dom.valueAvailable(insert.value, element_ty, position)) return false;
        if (!try dom.dominatesUses(position, result)) return false;
        // All proofs and allocations precede the first write. Replacement is
        // allocation-free, including list-backed operands and PHI edges.
        _ = ir.operands.replaceAllUses(function, result, insert.value);
        inst.removed = true;
        inst.replacement = insert.value;
    } else {
        if (!try dom.valueAvailable(insert.vector, insert.vector_ty, position)) return false;
        extract.vector = insert.vector;
        extract.index_ty = .{ .int = 64 };
        extract.index = .{ .int = extract_lane };
    }

    const remaining = ir.operands.functionUses(function, producer_name, null);
    if (remaining.occurrences == 0 and !remaining.coverage.has_opaque_references) producer.removed = true;
    return true;
}
