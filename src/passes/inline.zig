const std = @import("std");
const function_attrs = @import("../analysis/function_attrs.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const always_inline = @import("always_inline.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "inline",
    .category = .ipo,
    .target_status = "LLVM-shaped direct-call cost-gated subset",
    .upstream_owner = "llvm/lib/Transforms/IPO/Inliner.cpp",
    .run = run,
};

const InlineBudget = 3;

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var inlined_callees = std.StringHashMap(void).init(module.allocator);
    defer inlined_callees.deinit();

    var changed = false;
    var function_index: usize = 0;
    while (function_index < module.functions.items.len) : (function_index += 1) {
        changed = try inlineInFunction(module, function_index, &inlined_callees) or changed;
    }
    changed = removeDeadInlinedFunctions(module, inlined_callees) or changed;
    return if (changed) .changed else .unchanged;
}

fn inlineInFunction(
    module: *ir.Module,
    caller_index: usize,
    inlined_callees: *std.StringHashMap(void),
) !bool {
    var changed = false;
    while (findInlineableCall(module.*, caller_index)) |site| {
        const callee_name = module.functions.items[site.callee_index].name;
        try always_inline.inlineCall(module, caller_index, site);
        try inlined_callees.put(callee_name, {});
        changed = true;
    }
    return changed;
}

fn findInlineableCall(module: ir.Module, caller_index: usize) ?always_inline.CallSite {
    const caller = module.functions.items[caller_index];
    for (caller.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items, 0..) |instruction, instruction_index| {
            if (instruction.removed) continue;
            const call = switch (instruction.kind) {
                .call => |call| call,
                else => continue,
            };
            const callee_index = inlineableCalleeIndex(module, caller.name, call) orelse continue;
            return .{
                .block_index = block_index,
                .instruction_index = instruction_index,
                .callee_index = callee_index,
            };
        }
    }
    return null;
}

fn inlineableCalleeIndex(module: ir.Module, caller_name: []const u8, call: ir.CallInst) ?usize {
    if (call.inline_asm != null or call.callee_value != null) return null;
    if (call.operand_bundle != null) return null;
    if (call.attrs != null) return null;

    for (module.functions.items, 0..) |function, index| {
        if (!std.mem.eql(u8, function.name, call.callee)) continue;
        if (std.mem.eql(u8, caller_name, function.name)) return null;
        if (!always_inline.isLocalLinkage(function.linkage)) return null;
        if (function.params.items.len != call.args.items.len) return null;
        if (function.calling_conv != null or call.calling_conv != null) {
            if (function.calling_conv == null or call.calling_conv == null) return null;
            if (!std.mem.eql(u8, function.calling_conv.?, call.calling_conv.?)) return null;
        }
        if (!call.ret_ty.eql(function.ret_ty)) return null;
        const attrs = function_attrs.resolvedFunctionAttributes(module, function);
        if (attrs.@"noinline") return null;
        if (!always_inline.isSupportedCalleeBody(function)) return null;
        if (!isProfitable(function)) return null;
        return index;
    }
    return null;
}

fn isProfitable(function: ir.Function) bool {
    var cost: usize = 0;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            cost += instructionCost(instruction);
            if (cost > InlineBudget) return false;
        }
    }
    return true;
}

fn instructionCost(instruction: ir.Instruction) usize {
    return switch (instruction.kind) {
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep => 1,
        .load => 2,
        .phi, .alloca, .store, .atomicrmw, .cmpxchg, .fence, .call => InlineBudget + 1,
    };
}

fn removeDeadInlinedFunctions(module: *ir.Module, inlined_callees: std.StringHashMap(void)) bool {
    var changed = false;
    var index = module.functions.items.len;
    while (index > 0) {
        index -= 1;
        const function = module.functions.items[index];
        if (!inlined_callees.contains(function.name)) continue;
        if (!always_inline.isLocalLinkage(function.linkage)) continue;
        if (always_inline.hasDirectCallUse(module.*, function.name)) continue;
        if (always_inline.hasNonCallFunctionUse(module.*, function.name)) continue;
        var removed = module.functions.orderedRemove(index);
        removed.deinit(module.allocator);
        changed = true;
    }
    return changed;
}
