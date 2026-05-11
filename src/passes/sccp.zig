const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");
const inst_simplify = @import("inst_simplify.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "sccp",
    .category = .scalar,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/SCCP.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try propagateFunction(module.allocator, module.*, function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn propagateFunction(allocator: std.mem.Allocator, module: ir.Module, function: *ir.Function) !bool {
    var aliases = std.StringHashMap(ir.Value).init(allocator);
    defer aliases.deinit();

    var changed = false;
    var local_changed = true;
    while (local_changed) {
        local_changed = false;
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed) continue;
                instruction.mapOperands(aliases);
                if (simplifyPhi(instruction.*)) |replacement| {
                    local_changed = try replaceInstruction(&aliases, instruction, replacement) or local_changed;
                    changed = true;
                    continue;
                }
                if (simplifyCall(module, instruction.*)) |replacement| {
                    local_changed = try replaceInstruction(&aliases, instruction, replacement) or local_changed;
                    changed = true;
                    continue;
                }
                if (inst_simplify.simplify(instruction.*)) |replacement| {
                    local_changed = try replaceInstruction(&aliases, instruction, replacement) or local_changed;
                    changed = true;
                }
            }
            if (block.terminator) |*terminator| switch (terminator.*) {
                .ret => |*ret| {
                    if (ret.value) |value| ret.value = resolveValue(aliases, value);
                },
                .br, .@"unreachable" => {},
                .condbr => |*condbr| condbr.cond = resolveValue(aliases, condbr.cond),
            };
        }
    }
    return changed;
}

fn simplifyCall(module: ir.Module, instruction: ir.Instruction) ?ir.Value {
    const call = switch (instruction.kind) {
        .call => |call| call,
        .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .store, .gep => return null,
    };
    if (call.ret_ty == .void) return null;
    const callee = findFunction(module, call.callee) orelse return null;
    if (!callee.ret_ty.eql(call.ret_ty)) return null;
    if (callee.blocks.items.len != 1) return null;
    const block = callee.blocks.items[0];
    if (block.instructions.items.len != 0) return null;
    return switch (block.terminator orelse return null) {
        .ret => |ret| ret.value,
        .br, .condbr, .@"unreachable" => null,
    };
}

fn findFunction(module: ir.Module, name: []const u8) ?ir.Function {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return function;
    }
    return null;
}

fn replaceInstruction(aliases: *std.StringHashMap(ir.Value), instruction: *ir.Instruction, replacement: ir.Value) !bool {
    const result = instruction.result orelse return false;
    const old = aliases.get(result);
    if (old != null and old.?.eql(replacement)) return false;
    instruction.removed = true;
    instruction.replacement = replacement;
    try aliases.put(result, replacement);
    return true;
}

fn simplifyPhi(instruction: ir.Instruction) ?ir.Value {
    const phi = switch (instruction.kind) {
        .phi => |phi| phi,
        .binary, .cast, .freeze, .icmp, .select, .alloca, .load, .store, .gep, .call => return null,
    };
    if (phi.incoming.items.len == 0) return null;
    const first = phi.incoming.items[0].value;
    if (first != .int and first != .undef) return null;
    for (phi.incoming.items[1..]) |incoming| {
        if (!first.eql(incoming.value)) return null;
    }
    return first;
}

fn resolveValue(aliases: std.StringHashMap(ir.Value), value: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |name| aliases.get(name) orelse value,
    };
}
