const std = @import("std");
const alias = @import("../analysis/alias.zig");
const dominator = @import("../analysis/dominator.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

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

    return try visitBlock(allocator, module, function, dom, &aliases, &available, &stores, 0);
}

fn visitBlock(
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: *ir.Function,
    dom: dominator.Dominators,
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

        if (forwardStoreToLoad(function.*, stores.items, instruction)) |replacement| {
            instruction.removed = true;
            instruction.replacement = replacement;
            const result = instruction.result orelse return error.InstructionWithoutResult;
            try aliases.put(result, replacement);
            changed = true;
            continue;
        }

        if (isCseCandidate(module, instruction.*)) {
            if (findAvailableEquivalent(module, function.*, available.items, block_index, instruction_index, instruction.*)) |replacement| {
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
        changed = try visitBlock(allocator, module, function, dom, aliases, available, stores, child_index) or changed;
    }

    return changed;
}

fn forwardStoreToLoad(function: ir.Function, stores: []const AvailableStore, instruction: *ir.Instruction) ?ir.Value {
    const load = switch (instruction.kind) {
        .load => |load| load,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .store, .gep, .call => return null,
    };
    if (load.attrs.isBarrier()) return null;

    var index = stores.len;
    while (index > 0) {
        index -= 1;
        const store = stores[index];
        if (!store.ty.eql(load.ty)) continue;
        if (alias.alias(function, store.ptr, load.ptr) != .must_alias) continue;
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
            pruneMayAliasStores(function, stores, store.ptr);
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
        .load => |load| if (load.attrs.isBarrier()) stores.clearRetainingCapacity(),
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep => {},
    }
}

fn pruneMayAliasStores(function: ir.Function, stores: *std.ArrayList(AvailableStore), ptr: ir.Value) void {
    var index = stores.items.len;
    while (index > 0) {
        index -= 1;
        if (alias.alias(function, stores.items[index].ptr, ptr) == .no_alias) continue;
        _ = stores.orderedRemove(index);
    }
}

fn findAvailableEquivalent(
    module: ir.Module,
    function: ir.Function,
    available: []const AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) ?ir.Value {
    var index = available.len;
    while (index > 0) {
        index -= 1;
        const candidate = available[index];
        if (!sameAvailableExpression(module, function, candidate, block_index, instruction_index, instruction)) continue;
        return .{ .named = candidate.instruction.result orelse return null };
    }
    return null;
}

fn sameAvailableExpression(
    module: ir.Module,
    function: ir.Function,
    candidate: AvailableInstruction,
    block_index: usize,
    instruction_index: usize,
    instruction: ir.Instruction,
) bool {
    if (inst_simplify.sameExpression(candidate.instruction, instruction)) return true;
    if (sameReadnoneCall(module, candidate.instruction, instruction)) return true;
    if (candidate.instruction.kind != .load or instruction.kind != .load) return false;
    const candidate_load = candidate.instruction.kind.load;
    const load = instruction.kind.load;
    if (!candidate_load.ty.eql(load.ty)) return false;
    if (alias.alias(function, candidate_load.ptr, load.ptr) != .must_alias) return false;
    return !hasClobber(function, candidate, block_index, instruction_index, load.ptr);
}

fn sameReadnoneCall(module: ir.Module, a: ir.Instruction, b: ir.Instruction) bool {
    const a_call = switch (a.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    const b_call = switch (b.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return false,
    };
    if (function_attrs.callMemoryEffect(module, a_call) != .none) return false;
    if (function_attrs.callMemoryEffect(module, b_call) != .none) return false;
    if (!a_call.ret_ty.eql(b_call.ret_ty)) return false;
    if (!std.mem.eql(u8, a_call.callee, b_call.callee)) return false;
    if (a_call.calling_conv == null and b_call.calling_conv != null) return false;
    if (a_call.calling_conv != null and b_call.calling_conv == null) return false;
    if (a_call.calling_conv) |calling_conv| {
        if (!std.mem.eql(u8, calling_conv, b_call.calling_conv.?)) return false;
    }
    if (a_call.args.items.len != b_call.args.items.len) return false;
    for (a_call.args.items, b_call.args.items) |a_arg, b_arg| {
        if (!a_arg.ty.eql(b_arg.ty)) return false;
        if (!a_arg.value.eql(b_arg.value)) return false;
    }
    return true;
}

fn hasClobber(function: ir.Function, candidate: AvailableInstruction, block_index: usize, instruction_index: usize, ptr: ir.Value) bool {
    for (function.blocks.items, 0..) |block, current_block_index| {
        for (block.instructions.items, 0..) |instruction, current_instruction_index| {
            if (instruction.removed) continue;
            if (current_block_index == candidate.block_index and current_instruction_index <= candidate.instruction_index) continue;
            if (current_block_index == block_index and current_instruction_index >= instruction_index) continue;
            switch (alias.modRef(function, instruction, ptr)) {
                .mod, .mod_ref, .unknown => return true,
                .no_mod_ref, .ref => {},
            }
        }
    }
    return false;
}

fn isCseCandidate(module: ir.Module, instruction: ir.Instruction) bool {
    if (!memory_effect.isSafeToDelete(instruction)) {
        const call = switch (instruction.kind) {
            .call => |call| call,
            .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return false,
        };
        return call.ret_ty != .void and function_attrs.callMemoryEffect(module, call) == .none;
    }
    return switch (instruction.kind) {
        .binary, .cast, .icmp, .load => true,
        .freeze, .select, .phi, .alloca, .store, .gep, .call => false,
    };
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
