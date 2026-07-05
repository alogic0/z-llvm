const std = @import("std");
const def_use = @import("../analysis/def_use.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
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

const InsertRecord = struct {
    block_index: usize,
    instruction_index: usize,
    insert: ir.InsertElementInst,
};

const ShuffleRecord = struct {
    shuffle: ir.ShuffleVectorInst,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        var aliases = std.StringHashMap(ir.Value).init(module.allocator);
        defer aliases.deinit();
        var debug_aliases = std.StringHashMap([]const u8).init(module.allocator);
        defer debug_aliases.deinit();
        var inserted_vectors = std.StringHashMap(InsertRecord).init(module.allocator);
        defer inserted_vectors.deinit();
        var shuffled_vectors = std.StringHashMap(ShuffleRecord).init(module.allocator);
        defer shuffled_vectors.deinit();

        for (function.blocks.items, 0..) |*block, block_index| {
            for (block.instructions.items, 0..) |*instruction, instruction_index| {
                salvageDebugMetadata(instruction, debug_aliases);
                instruction.mapOperands(aliases);

                if (canonicalize(instruction)) changed = true;

                if (try rewriteWithContext(module.allocator, function, instruction, inserted_vectors, shuffled_vectors)) changed = true;

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
                        try inserted_vectors.put(result, .{
                            .block_index = block_index,
                            .instruction_index = instruction_index,
                            .insert = instruction.kind.insertelement,
                        });
                    }
                }
                if (instruction.kind == .shufflevector) {
                    if (instruction.result) |result| {
                        try shuffled_vectors.put(result, .{
                            .shuffle = instruction.kind.shufflevector,
                        });
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
        changed = try removeTriviallyDeadInstructions(module.allocator, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn removeTriviallyDeadInstructions(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var changed = false;
    while (try removeOneDeadInstructionLayer(allocator, function)) {
        changed = true;
    }
    return changed;
}

fn removeOneDeadInstructionLayer(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var uses = try def_use.UseCounts.collectFunction(allocator, function.*);
    defer uses.deinit();

    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (uses.isUsed(result) or !isTriviallyDeadInstCombineInstruction(instruction.*)) continue;
            instruction.removed = true;
            changed = true;
        }
    }
    return changed;
}

fn isTriviallyDeadInstCombineInstruction(instruction: ir.Instruction) bool {
    if (!memory_effect.isSafeToDelete(instruction)) return false;
    return switch (instruction.kind) {
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .load, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => true,
        .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .call => false,
    };
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
        .fcmp => |*fcmp| canonicalizeStrictSelfFcmp(fcmp),
        .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn canonicalizeStrictSelfFcmp(fcmp: *ir.FcmpInst) bool {
    if (fcmp.predicate != .oeq) return false;
    if (!fcmp.lhs.eql(fcmp.rhs)) return false;
    if (fcmp.fp_flags.any()) return false;
    const zero = switch (fcmp.operand_ty) {
        .half, .float, .double => ir.Value{ .fp = "0.000000e+00" },
        .void, .int, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => return false,
    };
    fcmp.predicate = .ord;
    fcmp.rhs = zero;
    return true;
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

fn rewriteWithContext(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    instruction: *ir.Instruction,
    inserted_vectors: std.StringHashMap(InsertRecord),
    shuffled_vectors: std.StringHashMap(ShuffleRecord),
) !bool {
    return switch (instruction.kind) {
        .extractelement => |*extract| try rewriteExtractElement(allocator, function, extract, inserted_vectors, shuffled_vectors),
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => false,
    };
}

fn foldWithContext(instruction: ir.Instruction, inserted_vectors: std.StringHashMap(InsertRecord)) ?ir.Value {
    return switch (instruction.kind) {
        .extractelement => |extract| foldExtractAfterInsert(extract, inserted_vectors),
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
    };
}

fn foldExtractAfterInsert(extract: ir.ExtractElementInst, inserted_vectors: std.StringHashMap(InsertRecord)) ?ir.Value {
    if (extract.vector != .named) return null;
    const insert = (inserted_vectors.get(extract.vector.named) orelse return null).insert;
    if (extract.index != .int or insert.index != .int) return null;
    if (extract.index.int != insert.index.int) return null;
    if (!extract.vector_ty.eql(insert.vector_ty)) return null;
    const vector_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return null,
    };
    if (!vector_ty.elem_ty.toType().eql(insert.value_ty)) return null;
    return insert.value;
}

fn rewriteExtractElement(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    extract: *ir.ExtractElementInst,
    inserted_vectors: std.StringHashMap(InsertRecord),
    shuffled_vectors: std.StringHashMap(ShuffleRecord),
) !bool {
    var changed = false;
    if (rewriteExtractAfterShuffle(extract, shuffled_vectors)) changed = true;
    if (try rewriteExtractAfterInsert(allocator, function, extract, inserted_vectors)) changed = true;
    return changed;
}

fn rewriteExtractAfterShuffle(
    extract: *ir.ExtractElementInst,
    shuffled_vectors: std.StringHashMap(ShuffleRecord),
) bool {
    if (extract.vector != .named) return false;
    if (extract.index != .int) return false;
    if (extract.index.int < 0) return false;
    const record = shuffled_vectors.get(extract.vector.named) orelse return false;
    const shuffle = record.shuffle;
    const extract_vector_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return false,
    };
    const mask_vector_ty = switch (shuffle.mask_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return false,
    };
    const lhs_vector_ty = switch (shuffle.lhs_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return false,
    };
    if (extract_vector_ty.len != mask_vector_ty.len) return false;
    if (!extract_vector_ty.elem_ty.toType().eql(lhs_vector_ty.elem_ty.toType())) return false;
    if (!shuffle.lhs_ty.eql(shuffle.rhs_ty)) return false;
    if (shuffle.rhs != .poison and shuffle.rhs != .undef) return false;
    if (extract.index.int > std.math.maxInt(usize)) return false;
    const target_lane = shuffleMaskLane(shuffle.mask, @intCast(extract.index.int)) orelse return false;
    if (target_lane >= lhs_vector_ty.len) return false;
    extract.vector_ty = shuffle.lhs_ty;
    extract.vector = shuffle.lhs;
    extract.index_ty = .{ .int = 64 };
    extract.index = .{ .int = target_lane };
    return true;
}

fn shuffleMaskLane(mask: ir.Value, index: usize) ?i128 {
    const text = switch (mask) {
        .vector => |text| text,
        .named, .int, .fp, .undef, .poison, .null_value, .zero_initializer, .constant_expr => return null,
    };
    const inner = std.mem.trim(u8, text, " \t\r\n<>");
    var parts = std.mem.splitScalar(u8, inner, ',');
    var current: usize = 0;
    while (parts.next()) |raw_part| : (current += 1) {
        if (current != index) continue;
        const part = std.mem.trim(u8, raw_part, " \t\r\n");
        if (!std.mem.startsWith(u8, part, "i32 ")) return null;
        return std.fmt.parseInt(i128, std.mem.trim(u8, part["i32 ".len..], " \t\r\n"), 10) catch null;
    }
    return null;
}

fn rewriteExtractAfterInsert(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    extract: *ir.ExtractElementInst,
    inserted_vectors: std.StringHashMap(InsertRecord),
) !bool {
    if (extract.vector != .named) return false;
    const record = inserted_vectors.get(extract.vector.named) orelse return false;
    const insert = record.insert;
    if (extract.index != .int or insert.index != .int) return false;
    if (extract.index.int == insert.index.int) return false;
    if (!extract.vector_ty.eql(insert.vector_ty)) return false;
    const vector_ty = switch (extract.vector_ty) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return false,
    };
    if (!vector_ty.elem_ty.toType().eql(insert.value_ty)) return false;

    extract.vector = insert.vector;
    extract.index_ty = .{ .int = 64 };
    try removeInsertIfDead(allocator, function, record);
    return true;
}

fn removeInsertIfDead(allocator: std.mem.Allocator, function: *ir.Function, record: InsertRecord) !void {
    const result = function.blocks.items[record.block_index].instructions.items[record.instruction_index].result orelse return;
    var uses = try def_use.UseCounts.collectFunction(allocator, function.*);
    defer uses.deinit();
    if (!uses.isUsed(result)) function.blocks.items[record.block_index].instructions.items[record.instruction_index].removed = true;
}
