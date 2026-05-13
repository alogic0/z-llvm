const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const function_attrs = @import("../analysis/function_attrs.zig");
const memory_effect = @import("../analysis/memory_effect.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "function-attrs",
    .category = .ipo,
    .target_status = "LLVM-shaped direct-call algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/FunctionAttrs.cpp",
    .run = run,
};

const VisitState = enum {
    unvisited,
    visiting,
    done,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;

    const memory_memo = try module.allocator.alloc(?memory_effect.Effect, module.functions.items.len);
    defer module.allocator.free(memory_memo);
    @memset(memory_memo, null);

    const memory_state = try module.allocator.alloc(VisitState, module.functions.items.len);
    defer module.allocator.free(memory_state);
    @memset(memory_state, .unvisited);

    for (module.functions.items, 0..) |*function, index| {
        const inferred = computeFunctionMemoryEffect(module.*, index, memory_memo, memory_state);
        if (try applyMemoryAttribute(module, function, inferred)) changed = true;
    }

    const norecurse_memo = try module.allocator.alloc(?bool, module.functions.items.len);
    defer module.allocator.free(norecurse_memo);
    @memset(norecurse_memo, null);

    const norecurse_state = try module.allocator.alloc(VisitState, module.functions.items.len);
    defer module.allocator.free(norecurse_state);
    @memset(norecurse_state, .unvisited);

    for (module.functions.items, 0..) |*function, index| {
        const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
        if (attrs.norecurse) continue;
        if (mayHaveRecursiveCallee(module.*, index, norecurse_memo, norecurse_state)) continue;
        if (try appendFunctionAttr(module, function, "norecurse")) changed = true;
    }

    return if (changed) .changed else .unchanged;
}

fn computeFunctionMemoryEffect(
    module: ir.Module,
    function_index: usize,
    memo: []?memory_effect.Effect,
    state: []VisitState,
) memory_effect.Effect {
    if (memo[function_index]) |effect| return effect;
    if (state[function_index] == .visiting) return .unknown;
    if (state[function_index] == .done) return memo[function_index] orelse .unknown;

    state[function_index] = .visiting;
    var effect: memory_effect.Effect = .none;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const inst_effect = switch (instruction.kind) {
                .call => |call| callMemoryEffect(module, call, memo, state),
                else => memory_effect.classify(instruction),
            };
            effect = mergeEffects(effect, inst_effect);
            if (effect == .unknown) {
                state[function_index] = .done;
                memo[function_index] = .unknown;
                return .unknown;
            }
        }
    }

    state[function_index] = .done;
    memo[function_index] = effect;
    return effect;
}

fn callMemoryEffect(
    module: ir.Module,
    call: ir.CallInst,
    memo: []?memory_effect.Effect,
    state: []VisitState,
) memory_effect.Effect {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return .unknown;
    if (findFunctionIndex(module, call.callee)) |index| {
        return computeFunctionMemoryEffect(module, index, memo, state);
    }
    return function_attrs.callMemoryEffect(module, call);
}

fn mergeEffects(a: memory_effect.Effect, b: memory_effect.Effect) memory_effect.Effect {
    if (a == .unknown or b == .unknown) return .unknown;
    if (a == .volatile_or_atomic_barrier or b == .volatile_or_atomic_barrier) return .unknown;
    if (a == .side_effect or b == .side_effect) return .unknown;
    if (a == .readonly_side_effect or b == .readonly_side_effect) return .unknown;
    if (a == .memory_write or b == .memory_write) {
        if (a == .readonly_load or b == .readonly_load) return .unknown;
        return .memory_write;
    }
    if (a == .readonly_load or b == .readonly_load) return .readonly_load;
    return .none;
}

fn applyMemoryAttribute(module: *ir.Module, function: *ir.Function, effect: memory_effect.Effect) !bool {
    const attrs = function_attrs.resolvedFunctionAttributes(module.*, function.*);
    if (attrs.memory_effects != null or attrs.readnone or attrs.readonly or attrs.writeonly) return false;
    return switch (effect) {
        .none => appendFunctionAttr(module, function, "memory(none)"),
        .readonly_load => appendFunctionAttr(module, function, "memory(read)"),
        .side_effect, .readonly_side_effect, .memory_write, .volatile_or_atomic_barrier, .unknown => false,
    };
}

fn mayHaveRecursiveCallee(
    module: ir.Module,
    function_index: usize,
    memo: []?bool,
    state: []VisitState,
) bool {
    if (memo[function_index]) |value| return value;
    if (state[function_index] == .visiting) return true;
    if (state[function_index] == .done) return memo[function_index] orelse true;

    state[function_index] = .visiting;
    const function = module.functions.items[function_index];
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            if (callMayRecurse(module, call, memo, state)) {
                state[function_index] = .done;
                memo[function_index] = true;
                return true;
            }
        }
    }

    state[function_index] = .done;
    memo[function_index] = false;
    return false;
}

fn callMayRecurse(
    module: ir.Module,
    call: ir.CallInst,
    memo: []?bool,
    state: []VisitState,
) bool {
    if (call.inline_asm != null or call.operand_bundle != null or call.callee_value != null) return true;
    if (findFunctionIndex(module, call.callee)) |index| {
        return mayHaveRecursiveCallee(module, index, memo, state);
    }
    const attrs = function_attrs.resolvedCalleeAttributes(module, call.callee) orelse return true;
    return !attrs.norecurse;
}

fn appendFunctionAttr(module: *ir.Module, function: *ir.Function, attr: []const u8) !bool {
    if (hasRawAttr(function.attrs, attr)) return false;
    const new_attrs = if (function.attrs) |existing|
        try std.fmt.allocPrint(module.allocator, "{s} {s}", .{ existing, attr })
    else
        try std.fmt.allocPrint(module.allocator, "{s}", .{attr});
    function.attrs = try module.ownString(new_attrs);
    return true;
}

fn hasRawAttr(attrs: ?[]const u8, attr: []const u8) bool {
    const text = attrs orelse return false;
    var it = std.mem.tokenizeAny(u8, text, " \t,{}");
    while (it.next()) |token| {
        if (std.mem.eql(u8, token, attr)) return true;
    }
    return false;
}

fn findFunctionIndex(module: ir.Module, name: []const u8) ?usize {
    for (module.functions.items, 0..) |function, index| {
        if (std.mem.eql(u8, function.name, name)) return index;
    }
    return null;
}
