const std = @import("std");
const ir = @import("../ir.zig");
const mem2reg = @import("mem2reg.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "sroa",
    .category = .memory,
    .target_status = "fixture-equivalent for listed fixtures",
    .upstream_owner = "llvm/lib/Transforms/Scalar/SROA.cpp",
    .run = run,
};

fn run(module: *ir.Module, context: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = try forwardZeroOffsetGeps(function) or changed;
    }

    const promotion_result = try mem2reg.pass.run(module, context);
    changed = changed or promotion_result == .changed;
    return if (changed) .changed else .unchanged;
}

fn forwardZeroOffsetGeps(function: *ir.Function) !bool {
    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed or instruction.kind != .gep) continue;
            const result = instruction.result orelse continue;
            const gep = instruction.kind.gep;
            const base = allocaBase(function.*, gep) orelse continue;

            replaceValue(function, result, .{ .named = base });
            instruction.removed = true;
            instruction.replacement = .{ .named = base };
            changed = true;
        }
    }
    return changed;
}

fn allocaBase(function: ir.Function, gep: ir.GepInst) ?[]const u8 {
    if (!allIndicesAreZero(gep)) return null;
    return zeroOffsetAllocaBase(function, gep.ptr);
}

fn zeroOffsetAllocaBase(function: ir.Function, ptr: ir.Value) ?[]const u8 {
    const base_name = switch (ptr) {
        .named => |name| name,
        .int, .undef => return null,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, base_name)) continue;
            return switch (instruction.kind) {
                .alloca => base_name,
                .gep => |gep| if (allIndicesAreZero(gep)) zeroOffsetAllocaBase(function, gep.ptr) else null,
                .binary, .cast, .freeze, .icmp, .select, .phi, .load, .store, .call => null,
            };
        }
    }
    return null;
}

fn allIndicesAreZero(gep: ir.GepInst) bool {
    if (gep.indices.items.len == 0) return false;
    for (gep.indices.items) |index| {
        if (index.value != .int or index.value.int != 0) return false;
    }
    return true;
}

fn replaceValue(function: *ir.Function, name: []const u8, replacement: ir.Value) void {
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .binary => |*binary| {
                    binary.lhs = replaceOperand(binary.lhs, name, replacement);
                    binary.rhs = replaceOperand(binary.rhs, name, replacement);
                },
                .cast => |*cast| cast.value = replaceOperand(cast.value, name, replacement),
                .freeze => |*freeze| freeze.value = replaceOperand(freeze.value, name, replacement),
                .icmp => |*icmp| {
                    icmp.lhs = replaceOperand(icmp.lhs, name, replacement);
                    icmp.rhs = replaceOperand(icmp.rhs, name, replacement);
                },
                .select => |*select| {
                    select.cond = replaceOperand(select.cond, name, replacement);
                    select.true_value = replaceOperand(select.true_value, name, replacement);
                    select.false_value = replaceOperand(select.false_value, name, replacement);
                },
                .phi => |*phi| for (phi.incoming.items) |*incoming| {
                    incoming.value = replaceOperand(incoming.value, name, replacement);
                },
                .alloca => {},
                .load => |*load| load.ptr = replaceOperand(load.ptr, name, replacement),
                .store => |*store| {
                    store.value = replaceOperand(store.value, name, replacement);
                    store.ptr = replaceOperand(store.ptr, name, replacement);
                },
                .gep => |*gep| {
                    gep.ptr = replaceOperand(gep.ptr, name, replacement);
                    for (gep.indices.items) |*index| {
                        index.value = replaceOperand(index.value, name, replacement);
                    }
                },
                .call => |*call| for (call.args.items) |*arg| {
                    arg.value = replaceOperand(arg.value, name, replacement);
                },
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
            .ret => |*ret| {
                if (ret.value) |value| ret.value = replaceOperand(value, name, replacement);
            },
            .br => {},
            .@"unreachable" => {},
            .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .undef => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}
