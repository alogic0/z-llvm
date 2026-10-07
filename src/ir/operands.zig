//! Structured value operands, in source order. Labels, result definitions and
//! replacement bookkeeping are not operands. Direct call symbols live in
//! CallInst.callee; only the optional value callee is visited here. This is not
//! a module symbol-reference graph.
//!
//! Visitors declare Error and visit(value, ty). A const input provides *const
//! Value, including list-backed operands; a mutable input provides *Value.
//! Mutation borrows the original storage and does not clone operand lists.
const std = @import("std");
const ir = @import("core.zig");

pub const Coverage = struct {
    /// Opaque values/syntax may contain references that were not traversed.
    /// This is conservative (even a literal vector is opaque), not a use count
    /// or proof of absence. Clients needing complete references must handle it.
    has_opaque_references: bool = false,

    pub fn merge(coverage: *Coverage, other: Coverage) void {
        coverage.has_opaque_references = coverage.has_opaque_references or other.has_opaque_references;
    }
};

fn Walker(comptime Pointer: type, comptime Visitor: type) type {
    return struct {
        visitor: Visitor,
        coverage: Coverage = .{},

        // Explicitly propagate constness through ArrayList slices, whose items
        // would otherwise remain mutable through a const instruction pointer.
        fn value(w: *@This(), slot: if (@typeInfo(Pointer).pointer.attrs.@"const") *const ir.Value else *ir.Value, ty: ir.Type) Visitor.Error!void {
            switch (slot.*) {
                .vector, .constant_expr => w.coverage.has_opaque_references = true,
                else => {},
            }
            try w.visitor.visit(slot, ty);
            switch (slot.*) {
                .vector, .constant_expr => w.coverage.has_opaque_references = true,
                else => {},
            }
        }

        fn opaqueText(w: *@This(), text: ?[]const u8) void {
            if (text) |s| {
                if (s.len != 0) w.coverage.has_opaque_references = true;
            }
        }
    };
}

/// Visits even removed instructions; the enclosing function walk decides
/// whether removed instructions belong to its view of the IR.
pub fn instruction(inst: anytype, visitor: anytype) @TypeOf(visitor).Error!Coverage {
    comptime std.debug.assert(@TypeOf(inst) == *ir.Instruction or @TypeOf(inst) == *const ir.Instruction);
    var w: Walker(@TypeOf(inst), @TypeOf(visitor)) = .{ .visitor = visitor };
    w.opaqueText(inst.metadata);
    switch (inst.kind) {
        .binary => |*x| {
            try w.value(&x.lhs, x.ty);
            try w.value(&x.rhs, x.ty);
        },
        .cast => |*x| try w.value(&x.value, x.from_ty),
        .freeze => |*x| try w.value(&x.value, x.ty),
        .icmp => |*x| {
            try w.value(&x.lhs, x.operand_ty);
            try w.value(&x.rhs, x.operand_ty);
        },
        .fcmp => |*x| {
            try w.value(&x.lhs, x.operand_ty);
            try w.value(&x.rhs, x.operand_ty);
        },
        .select => |*x| {
            try w.value(&x.cond, x.cond_ty);
            try w.value(&x.true_value, x.ty);
            try w.value(&x.false_value, x.ty);
        },
        .phi => |*x| for (x.incoming.items) |*incoming| {
            try w.value(&incoming.value, x.ty);
        },
        .alloca => |*x| {
            if (x.count) |*count| try w.value(&count.value, count.ty);
            w.opaqueText(x.attrs);
        },
        .load => |*x| try w.value(&x.ptr, .ptr),
        .store => |*x| {
            try w.value(&x.value, x.ty);
            try w.value(&x.ptr, .ptr);
        },
        .atomicrmw => |*x| {
            try w.value(&x.ptr, .ptr);
            try w.value(&x.value, x.ty);
        },
        .cmpxchg => |*x| {
            try w.value(&x.ptr, .ptr);
            try w.value(&x.expected, x.ty);
            try w.value(&x.replacement, x.ty);
        },
        .fence => {},
        .extractelement => |*x| {
            try w.value(&x.vector, x.vector_ty);
            try w.value(&x.index, x.index_ty);
        },
        .insertelement => |*x| {
            try w.value(&x.vector, x.vector_ty);
            try w.value(&x.value, x.value_ty);
            try w.value(&x.index, x.index_ty);
        },
        .shufflevector => |*x| {
            try w.value(&x.lhs, x.lhs_ty);
            try w.value(&x.rhs, x.rhs_ty);
            try w.value(&x.mask, x.mask_ty);
        },
        .extractvalue => |*x| try w.value(&x.aggregate, x.aggregate_ty),
        .insertvalue => |*x| {
            try w.value(&x.aggregate, x.aggregate_ty);
            try w.value(&x.value, x.value_ty);
        },
        .gep => |*x| {
            try w.value(&x.ptr, .ptr);
            for (x.indices.items) |*index| try w.value(&index.value, index.ty);
        },
        .call => |*x| {
            if (x.callee_value) |*callee| try w.value(callee, .ptr);
            for (x.args.items) |*arg| {
                try w.value(&arg.value, arg.ty);
                w.opaqueText(arg.attrs);
            }
            w.opaqueText(x.raw_args);
            w.opaqueText(x.operand_bundle);
            w.opaqueText(x.attrs);
            w.opaqueText(x.ret_attrs);
            if (x.inline_asm != null) w.coverage.has_opaque_references = true;
        },
    }
    return w.coverage;
}

pub fn terminator(term: anytype, visitor: anytype) @TypeOf(visitor).Error!Coverage {
    comptime std.debug.assert(@TypeOf(term) == *ir.Terminator or @TypeOf(term) == *const ir.Terminator);
    var w: Walker(@TypeOf(term), @TypeOf(visitor)) = .{ .visitor = visitor };
    switch (term.*) {
        .ret => |*x| if (x.value) |*value| try w.value(value, x.ty),
        .br => |*x| w.opaqueText(x.metadata),
        .condbr => |*x| {
            try w.value(&x.cond, x.cond_ty);
            w.opaqueText(x.metadata);
        },
        .@"switch" => |*x| {
            try w.value(&x.cond, x.cond_ty);
            for (x.cases.items) |*case| try w.value(&case.value, case.value_ty);
            w.opaqueText(x.metadata);
        },
        .indirectbr => |*x| {
            try w.value(&x.addr, x.addr_ty);
            w.opaqueText(x.metadata);
        },
        .@"unreachable" => {},
    }
    return w.coverage;
}

const AliasMapper = struct {
    pub const Error = error{};
    aliases: std.StringHashMap(ir.Value),

    pub fn visit(mapper: AliasMapper, value: *ir.Value, _: ir.Type) Error!void {
        if (value.* == .named) value.* = mapper.aliases.get(value.named) orelse value.*;
    }
};

/// One lookup per operand, as in Instruction.mapOperands. Does not chase chains
/// or cycles. Callers retain responsibility for canonicalizing their maps.
pub fn mapInstruction(inst: *ir.Instruction, aliases: std.StringHashMap(ir.Value)) Coverage {
    return instruction(inst, AliasMapper{ .aliases = aliases }) catch unreachable;
}

pub const ReplacementResult = struct {
    replaced: usize = 0,
    coverage: Coverage = .{},
};

const Replacer = struct {
    pub const Error = error{};
    name: []const u8,
    replacement: ir.Value,
    result: *ReplacementResult,

    pub fn visit(replacer: Replacer, value: *ir.Value, _: ir.Type) Error!void {
        if (value.* == .named and std.mem.eql(u8, value.named, replacer.name)) {
            value.* = replacer.replacement;
            replacer.result.replaced += 1;
        }
    }
};

/// Replace exact named value uses in live instructions and all terminators.
/// Skips removed instructions and their replacement bookkeeping. Does not
/// rewrite opaque text, labels, direct call symbols, or chase replacements.
/// The caller must ensure matching types, dominance and appropriate coverage.
pub fn replaceAllUses(function: *ir.Function, name: []const u8, replacement: ir.Value) ReplacementResult {
    var result: ReplacementResult = .{};
    const visitor: Replacer = .{ .name = name, .replacement = replacement, .result = &result };
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            result.coverage.merge(instruction(inst, visitor) catch unreachable);
        }
        if (block.terminator) |*term| result.coverage.merge(terminator(term, visitor) catch unreachable);
    }
    return result;
}
