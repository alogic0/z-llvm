const std = @import("std");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "mem2reg",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items) |*function| {
        changed = promoteFunction(function) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn promoteFunction(function: *ir.Function) bool {
    var changed = false;
    var block_index: usize = 0;
    while (block_index < function.blocks.items.len) : (block_index += 1) {
        var instruction_index: usize = 0;
        while (instruction_index < function.blocks.items[block_index].instructions.items.len) : (instruction_index += 1) {
            const instruction = function.blocks.items[block_index].instructions.items[instruction_index];
            if (instruction.removed or instruction.kind != .alloca) continue;
            const slot = instruction.result orelse continue;
            if (!isPromotableSingleBlockSlot(function.*, block_index, slot)) continue;

            promoteSingleBlockSlot(function, block_index, slot);
            changed = true;
        }
    }
    return changed;
}

fn isPromotableSingleBlockSlot(function: ir.Function, slot_block_index: usize, slot: []const u8) bool {
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, slot)) continue;
            }

            switch (instruction.kind) {
                .load => |load| {
                    if (!isNamed(load.ptr, slot)) continue;
                    if (block_index != slot_block_index) return false;
                },
                .store => |store| {
                    if (isNamed(store.value, slot)) return false;
                    if (!isNamed(store.ptr, slot)) continue;
                    if (block_index != slot_block_index) return false;
                },
                .binary => |binary| {
                    if (isNamed(binary.lhs, slot) or isNamed(binary.rhs, slot)) return false;
                },
                .icmp => |icmp| {
                    if (isNamed(icmp.lhs, slot) or isNamed(icmp.rhs, slot)) return false;
                },
                .phi => |phi| for (phi.incoming.items) |incoming| {
                    if (isNamed(incoming.value, slot)) return false;
                },
                .alloca => {},
            }
        }
        if (block.terminator) |terminator| switch (terminator) {
            .ret => |ret| if (isNamed(ret.value, slot)) return false,
            .br => {},
            .condbr => |condbr| if (isNamed(condbr.cond, slot)) return false,
        };
    }

    var has_current_value = false;
    for (function.blocks.items[slot_block_index].instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .store => |store| {
                if (isNamed(store.ptr, slot)) has_current_value = true;
            },
            .load => |load| {
                if (isNamed(load.ptr, slot) and !has_current_value) return false;
            },
            .binary, .icmp, .phi, .alloca => {},
        }
    }
    return true;
}

fn promoteSingleBlockSlot(function: *ir.Function, block_index: usize, slot: []const u8) void {
    var current_value: ?ir.Value = null;

    var instruction_index: usize = 0;
    while (instruction_index < function.blocks.items[block_index].instructions.items.len) : (instruction_index += 1) {
        var replacement: ?struct { name: []const u8, value: ir.Value } = null;
        {
            const instruction = &function.blocks.items[block_index].instructions.items[instruction_index];
            if (instruction.removed) continue;

            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, slot)) {
                    instruction.removed = true;
                    continue;
                }
            }

            switch (instruction.kind) {
                .store => |store| {
                    if (!isNamed(store.ptr, slot)) continue;
                    current_value = store.value;
                    instruction.removed = true;
                },
                .load => |load| {
                    if (!isNamed(load.ptr, slot)) continue;
                    const result = instruction.result orelse continue;
                    const value = current_value orelse continue;
                    instruction.removed = true;
                    instruction.replacement = value;
                    replacement = .{ .name = result, .value = value };
                },
                .binary, .icmp, .phi, .alloca => {},
            }
        }
        if (replacement) |item| replaceValue(function, item.name, item.value);
    }
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
                .icmp => |*icmp| {
                    icmp.lhs = replaceOperand(icmp.lhs, name, replacement);
                    icmp.rhs = replaceOperand(icmp.rhs, name, replacement);
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
            }
        }
        if (block.terminator) |*terminator| switch (terminator.*) {
            .ret => |*ret| ret.value = replaceOperand(ret.value, name, replacement),
            .br => {},
            .condbr => |*condbr| condbr.cond = replaceOperand(condbr.cond, name, replacement),
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}

fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}
