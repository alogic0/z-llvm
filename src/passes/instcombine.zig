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
        var debug_aliases = std.StringHashMap([]const u8).init(module.allocator);
        defer debug_aliases.deinit();
        var inserted_vectors = std.StringHashMap(ir.InsertElementInst).init(module.allocator);
        defer inserted_vectors.deinit();

        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                salvageDebugMetadata(instruction, debug_aliases);
                instruction.mapOperands(aliases);

                if (canonicalize(instruction)) changed = true;

                if (foldWithContext(instruction.*, inserted_vectors) orelse fold(instruction.*)) |replacement| {
                    instruction.removed = true;
                    instruction.replacement = replacement;
                    const result = instruction.result orelse return error.InstructionWithoutResult;
                    try aliases.put(result, replacement);
                    if (debugMetadata(instruction.metadata)) |dbg| try debug_aliases.put(result, dbg);
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
                .indirectbr => |*indirectbr| indirectbr.addr = resolveValue(aliases, indirectbr.addr),
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

fn salvageDebugMetadata(instruction: *ir.Instruction, debug_aliases: std.StringHashMap([]const u8)) void {
    if (instruction.metadata != null) return;
    instruction.metadata = switch (instruction.kind) {
        .binary => |binary| debugForValue(debug_aliases, binary.lhs) orelse debugForValue(debug_aliases, binary.rhs),
        .cast => |cast| debugForValue(debug_aliases, cast.value),
        .freeze => |freeze| debugForValue(debug_aliases, freeze.value),
        .icmp => |icmp| debugForValue(debug_aliases, icmp.lhs) orelse debugForValue(debug_aliases, icmp.rhs),
        .fcmp => |fcmp| debugForValue(debug_aliases, fcmp.lhs) orelse debugForValue(debug_aliases, fcmp.rhs),
        .select => |select| debugForValue(debug_aliases, select.cond) orelse
            debugForValue(debug_aliases, select.true_value) orelse
            debugForValue(debug_aliases, select.false_value),
        .phi => |phi| debugForIncoming(debug_aliases, phi),
        .alloca => null,
        .load => |load| debugForValue(debug_aliases, load.ptr),
        .store => |store| debugForValue(debug_aliases, store.value) orelse debugForValue(debug_aliases, store.ptr),
        .atomicrmw => |atomicrmw| debugForValue(debug_aliases, atomicrmw.ptr) orelse debugForValue(debug_aliases, atomicrmw.value),
        .cmpxchg => |cmpxchg| debugForValue(debug_aliases, cmpxchg.ptr) orelse
            debugForValue(debug_aliases, cmpxchg.expected) orelse
            debugForValue(debug_aliases, cmpxchg.replacement),
        .fence => null,
        .extractelement => |extract| debugForValue(debug_aliases, extract.vector) orelse debugForValue(debug_aliases, extract.index),
        .insertelement => |insert| debugForValue(debug_aliases, insert.vector) orelse
            debugForValue(debug_aliases, insert.value) orelse
            debugForValue(debug_aliases, insert.index),
        .shufflevector => |shuffle| debugForValue(debug_aliases, shuffle.lhs) orelse
            debugForValue(debug_aliases, shuffle.rhs) orelse
            debugForValue(debug_aliases, shuffle.mask),
        .extractvalue => |extract| debugForValue(debug_aliases, extract.aggregate),
        .insertvalue => |insert| debugForValue(debug_aliases, insert.aggregate) orelse debugForValue(debug_aliases, insert.value),
        .gep => |gep| debugForGep(debug_aliases, gep),
        .call => |call| debugForCall(debug_aliases, call),
    };
}

fn debugForIncoming(debug_aliases: std.StringHashMap([]const u8), phi: ir.PhiInst) ?[]const u8 {
    for (phi.incoming.items) |incoming| {
        if (debugForValue(debug_aliases, incoming.value)) |dbg| return dbg;
    }
    return null;
}

fn debugForGep(debug_aliases: std.StringHashMap([]const u8), gep: ir.GepInst) ?[]const u8 {
    if (debugForValue(debug_aliases, gep.ptr)) |dbg| return dbg;
    for (gep.indices.items) |index| {
        if (debugForValue(debug_aliases, index.value)) |dbg| return dbg;
    }
    return null;
}

fn debugForCall(debug_aliases: std.StringHashMap([]const u8), call: ir.CallInst) ?[]const u8 {
    if (call.callee_value) |callee_value| {
        if (debugForValue(debug_aliases, callee_value)) |dbg| return dbg;
    }
    for (call.args.items) |arg| {
        if (debugForValue(debug_aliases, arg.value)) |dbg| return dbg;
    }
    return null;
}

fn debugForValue(debug_aliases: std.StringHashMap([]const u8), value: ir.Value) ?[]const u8 {
    return switch (value) {
        .named => |name| debug_aliases.get(name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => null,
    };
}

fn debugMetadata(metadata: ?[]const u8) ?[]const u8 {
    var rest = std.mem.trim(u8, metadata orelse return null, " \t");
    while (rest.len != 0) {
        const comma = std.mem.indexOfScalar(u8, rest, ',');
        const attachment = std.mem.trim(u8, if (comma) |index| rest[0..index] else rest, " \t");
        if (std.mem.startsWith(u8, attachment, "!dbg ")) return attachment;
        rest = if (comma) |index| std.mem.trim(u8, rest[index + 1 ..], " \t") else "";
    }
    return null;
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
        .void, .int, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return null,
    };
    if (!vector_ty.elem_ty.toType().eql(insert.value_ty)) return null;
    return insert.value;
}
