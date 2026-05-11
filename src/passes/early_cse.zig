const std = @import("std");
const alias = @import("../analysis/alias.zig");
const dominator = @import("../analysis/dominator.zig");
const expression_key = @import("../analysis/expression_key.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const memory_ssa = @import("../analysis/memory_ssa.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "early-cse",
    .category = .canonicalization,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Scalar/EarlyCSE.cpp",
    .run = run,
};

const AvailableInstruction = struct {
    block_index: usize,
    instruction_index: usize,
    hash: u64,
    instruction: ir.Instruction,
};

const AvailableStore = struct {
    ptr: ir.Value,
    ty: ir.Type,
    value: ir.Value,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try eliminateFunction(module.allocator, module.*, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn eliminateFunction(allocator: std.mem.Allocator, module: ir.Module, function: *ir.Function) !bool {
    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var available: std.ArrayList(AvailableInstruction) = .empty;
    defer available.deinit(allocator);

    var stores: std.ArrayList(AvailableStore) = .empty;
    defer stores.deinit(allocator);

    var memory = try memory_ssa.MemorySSA.build(allocator, module, function.*);
    defer memory.deinit();

    return try visitBlock(allocator, module, function, dom, memory, &aliases, &available, &stores, 0);
}

fn visitBlock(
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: *ir.Function,
    dom: dominator.Dominators,
    memory: memory_ssa.MemorySSA,
    aliases: *std.StringHashMap(ir.Value),
    available: *std.ArrayList(AvailableInstruction),
    stores: *std.ArrayList(AvailableStore),
    block_index: usize,
) !bool {
    const old_available_len = available.items.len;
    defer available.shrinkRetainingCapacity(old_available_len);
    const old_store_len = stores.items.len;
    defer stores.shrinkRetainingCapacity(old_store_len);

    var changed = false;
    const block = &function.blocks.items[block_index];
    for (block.instructions.items, 0..) |*instruction, instruction_index| {
        instruction.mapOperands(aliases.*);
        if (instruction.removed) continue;

        if (forwardStoreToLoad(module, function.*, stores.items, instruction)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            changed = true;
            continue;
        }

        if (isCseCandidate(module, instruction.*)) {
            if (findAvailableEquivalent(module, function.*, memory, available.items, block_index, instruction_index, instruction.*)) |replacement| {
                instruction.removed = true;
                instruction.replacement = replacement;
                const result = instruction.result orelse return error.InstructionWithoutResult;
                try aliases.put(result, replacement);
                changed = true;
                continue;
            }

            try available.append(allocator, .{
                .block_index = block_index,
                .instruction_index = instruction_index,
                .hash = expression_key.hash(instruction.*),
                .instruction = instruction.*,
            });
        }

        try updateMemoryAvailability(allocator, module, function.*, stores, instruction.*);
    }

    if (block.terminator) |*terminator| switch (terminator.*) {
        .ret => |*ret| {
            if (ret.value) |value| ret.value = resolveValue(aliases.*, value);
        },
        .br => {},
        .@"unreachable" => {},
        .condbr => |*condbr| condbr.cond = resolveValue(aliases.*, condbr.cond),
    };

    for (0..function.blocks.items.len) |child_index| {
        if (dom.immediateDominator(child_index) != block_index) continue;
        changed = try visitBlock(allocator, module, function, dom, memory, aliases, available, stores, child_index) or changed;
    }

    return changed;
}

fn forwardStoreToLoad(module: ir.Module, function: ir.Function, stores: []const AvailableStore, instruction: *ir.Instruction) ?ir.Value {
    const load = switch (instruction.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .gep, .call => return null,
    };
    if (load.attrs.isBarrier()) return null;

    var index = stores.len;
    while (index > 0) {
        index -= 1;
        const store = stores[index];
        if (!store.ty.eql(load.ty)) continue;
        if (alias.accessAliasInModule(module, function, store.ptr, store.ty, load.ptr, load.ty) != .must_alias) continue;
        return store.value;
    }
    return null;
}

fn updateMemoryAvailability(
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: ir.Function,
    stores: *std.ArrayList(AvailableStore),
    instruction: ir.Instruction,
) !void {
    switch (instruction.kind) {
        .store => |store| {
            if (store.attrs.isBarrier()) {
                stores.clearRetainingCapacity();
                return;
            }
            pruneMayAliasStores(module, function, stores, store.ptr, store.ty);
            try stores.append(allocator, .{
                .ptr = store.ptr,
                .ty = store.ty,
                .value = store.value,
            });
        },
        .call => |call| switch (function_attrs.callMemoryEffect(module, call)) {
            .none, .readonly_load => {},
            .memory_write, .volatile_or_atomic_barrier, .unknown => stores.clearRetainingCapacity(),
        },
        .atomicrmw, .cmpxchg, .fence => stores.clearRetainingCapacity(),
        .load => |load| if (load.attrs.isBarrier()) stores.clearRetainingCapacity(),
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => {},
    }
}

fn pruneMayAliasStores(module: ir.Module, function: ir.Function, stores: *std.ArrayList(AvailableStore), ptr: ir.Value, ty: ir.Type) void {
    var index = stores.items.len;
    while (index > 0) {
        index -= 1;
        const store = stores.items[index];
        if (alias.accessAliasInModule(module, function, store.ptr, store.ty, ptr, ty) == .no_alias) continue;
        _ = stores.orderedRemove(index);
    }
}

fn findAvailableEquivalent(
    module: ir.Module,
    function: ir.Function,
    memory: memory_ssa.MemorySSA,
    available: []const AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    var index = available.len;
    while (index > 0) {
        index -= 1;
        const candidate = available[index];
        if (candidate.hash != expression_key.hash(instruction)) continue;
        if (!sameAvailableExpression(module, function, memory, candidate, block_index, instruction_index, instruction)) continue;
        return .{ .named = candidate.instruction.result orelse return null };
    }
    return null;
}

fn sameAvailableExpression(
    module: ir.Module,
    function: ir.Function,
    memory: memory_ssa.MemorySSA,
    candidate: AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) bool {
    if (candidate.instruction.kind == .load or instruction.kind == .load) {
        if (candidate.instruction.kind != .load or instruction.kind != .load) return false;
        const candidate_load = candidate.instruction.kind.load;
        const load = instruction.kind.load;
        if (!candidate_load.ty.eql(load.ty)) return false;
        if (alias.alias(function, candidate_load.ptr, load.ptr) != .must_alias) return false;
        return !memory.hasClobberBetweenAccess(
            .{ .block_index = candidate.block_index, .instruction_index = candidate.instruction_index },
            .{ .block_index = block_index, .instruction_index = instruction_index },
            load.ptr,
            load.ty,
        );
    }
    return expression_key.sameValueExpression(module, function, candidate.instruction, instruction);
}

fn isCseCandidate(module: ir.Module, instruction: ir.Instruction) bool {
    if (!memory_effect.isSafeToDelete(instruction)) {
        const call = switch (instruction.kind) {
            .call => |call| call,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .store, .atomicrmw, .cmpxchg, .fence, .gep => return false,
        };
        return call.ret_ty != .void and function_attrs.callMemoryEffect(module, call) == .none;
    }
    return switch (instruction.kind) {
        .binary => |binary| !isFpBinary(binary.op),
        .cast, .icmp, .load => true,
        .freeze, .fcmp, .select, .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .gep, .call => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef, .null_value, .zero_initializer, .vector => value,
        .named => |name| aliases.get(name) orelse value,
    };
}

fn isFpBinary(op: ir.BinaryOp) bool {
    return op == .fadd or op == .fmul;
}
