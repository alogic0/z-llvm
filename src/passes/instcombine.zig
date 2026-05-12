const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "instcombine",
    .category = .canonicalization,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/InstCombine/",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var aliases = std.StringHashMap(ir.Value).init(module.allocator);
        defer aliases.deinit();
        var inserted_vectors = std.StringHashMap(ir.InsertElementInst).init(module.allocator);
        defer inserted_vectors.deinit();

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                instruction.mapOperands(aliases);

                if (canonicalize(instruction)) changed = true;

                if (foldWithContext(instruction.*, inserted_vectors) orelse fold(instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    const result = instruction.result orelse return error.InstructionWithoutResult;
                    try aliases.put(result, replacement);
                    changed = true;
                    continue;
                }

                if (instruction.kind == .insertelement) {
                    if (instruction.result) |result| {
                        try inserted_vectors.put(result, instruction.kind.insertelement);
                    }
                }
            }

            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| {
                    if (ret.value) |value| ret.value = resolveValue(aliases, value);
                },
                .br => {},
                .@"unreachable" => {},
                .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
                .@"switch" => |*switch_term| {
                    switch_term.cond = resolveValue(aliases, switch_term.cond);
                    for (switch_term.cases.items) |*case| {
                        case.value = resolveValue(aliases, case.value);
                    }
                },
            };
        }
    }
    return if (changed) .changed else .unchanged;
}

fn canonicalize(instruction: *ir.Instruction) bool {
    return switch (instruction.kind) {
        .binary => |*binary| inst_simplify.canonicalizeCommutativeConstantRhs(binary),
        .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn fold(instruction: ir.Instruction) ?ir.Value {
    return inst_simplify.simplify(instruction);
}

fn foldWithContext(instruction: ir.Instruction, inserted_vectors: std.StringHashMap(ir.InsertElementInst)) ?ir.Value {
    return switch (instruction.kind) {
        .extractelement => |extract| foldExtractAfterInsert(extract, inserted_vectors),
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
    };
}

fn foldExtractAfterInsert(extract: ir.ExtractElementInst, inserted_vectors: std.StringHashMap(ir.InsertElementInst)) ?ir.Value {
    if (extract.vector != .named) return null;
    const insert = inserted_vectors.get(extract.vector.named) orelse return null;
    if (extract.index != .int or insert.index != .int) return null;
    if (extract.index.int != insert.index.int) return null;
    if (!extract.vector_ty.eql(insert.vector_ty)) return null;
    const vector_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .float, .double, .metadata, .ptr, .aggregate => return null,
    };
    if (!vector_ty.elem_ty.toType().eql(insert.value_ty)) return null;
    return insert.value;
}
