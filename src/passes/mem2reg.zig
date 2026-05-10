const std = @import("std");
const cfg = @import("../analysis/cfg.zig");
const dominator = @import("../analysis/dominator.zig");
const ir = @import("../ir.zig");
const pass_manager = @import("../pass_manager.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "mem2reg",
    .category = .canonicalization,
    .target_status = "LLVM-shaped algorithm subset",
    .upstream_owner = "llvm/lib/Transforms/Utils/Mem2Reg.cpp",
    .run = run,
};

fn run(module: *ir.Module, _: *pass_manager.Context) !pass_manager.PassResult {
    var changed = false;
    for (module.functions.items, 0..) |_, function_index| {
        changed = try promoteFunction(module, function_index) or changed;
    }
    return if (changed) .changed else .unchanged;
}

fn promoteFunction(module: *ir.Module, function_index: usize) !bool {
    var changed = false;
    while (try promoteOneFunctionSlot(module, function_index)) {
        changed = true;
    }
    return changed;
}

fn promoteOneFunctionSlot(module: *ir.Module, function_index: usize) !bool {
    const function = &module.functions.items[function_index];
    if (function.blocks.items.len == 0) return false;

    const entry_block_index: usize = 0;
    const entry_block = &function.blocks.items[entry_block_index];
    var changed = false;
    var instruction_index: usize = 0;
    while (instruction_index < entry_block.instructions.items.len) : (instruction_index += 1) {
        const instruction = entry_block.instructions.items[instruction_index];
        if (instruction.removed or instruction.kind != .alloca) continue;
        const slot = instruction.result orelse continue;
        if (!isPromotableSingleBlockSlot(function.*, entry_block_index, slot)) continue;

        promoteSingleBlockSlot(function, entry_block_index, slot);
        changed = true;
    }
    if (changed) return true;

    instruction_index = 0;
    while (instruction_index < entry_block.instructions.items.len) : (instruction_index += 1) {
        const instruction = entry_block.instructions.items[instruction_index];
        if (instruction.removed or instruction.kind != .alloca) continue;
        const slot = instruction.result orelse continue;
        if (!isPromotableStackSlot(function.*, slot)) continue;

        try promoteMultiBlockSlot(module, function_index, entry_block_index, instruction_index, slot, instruction.kind.alloca.allocated_ty);
        return true;
    }
    return changed;
}

fn isPromotableStackSlot(function: ir.Function, slot: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, slot)) continue;
            }

            switch (instruction.kind) {
                .load => |load| {
                    if (!isNamed(load.ptr, slot)) continue;
                    if (load.attrs.isBarrier()) return false;
                },
                .store => |store| {
                    if (isNamed(store.value, slot)) return false;
                    if (!isNamed(store.ptr, slot)) continue;
                    if (store.attrs.isBarrier()) return false;
                },
                .binary => |binary| {
                    if (isNamed(binary.lhs, slot) or isNamed(binary.rhs, slot)) return false;
                },
                .cast => |cast| {
                    if (isNamed(cast.value, slot)) return false;
                },
                .freeze => |freeze| {
                    if (isNamed(freeze.value, slot)) return false;
                },
                .icmp => |icmp| {
                    if (isNamed(icmp.lhs, slot) or isNamed(icmp.rhs, slot)) return false;
                },
                .select => |select| {
                    if (isNamed(select.cond, slot) or
                        isNamed(select.true_value, slot) or
                        isNamed(select.false_value, slot)) return false;
                },
                .phi => |phi| for (phi.incoming.items) |incoming| {
                    if (isNamed(incoming.value, slot)) return false;
                },
                .gep => |gep| {
                    if (isNamed(gep.ptr, slot)) return false;
                    for (gep.indices.items) |index| {
                        if (isNamed(index.value, slot)) return false;
                    }
                },
                .call => |call| for (call.args.items) |arg| {
                    if (isNamed(arg.value, slot)) return false;
                },
                .alloca => {},
            }
        }
        if (block.terminator) |terminator| switch (terminator) {
            .ret => |ret| if (ret.value) |value| if (isNamed(value, slot)) return false,
            .br => {},
            .@"unreachable" => {},
            .condbr => |condbr| if (isNamed(condbr.cond, slot)) return false,
        };
    }
    return true;
}

fn promoteMultiBlockSlot(
    module: *ir.Module,
    function_index: usize,
    alloca_block_index: usize,
    alloca_instruction_index: usize,
    slot: []const u8,
    ty: ir.Type,
) !void {
    const allocator = module.allocator;
    const function = &module.functions.items[function_index];
    var dom = try dominator.Dominators.build(allocator, function.*);
    defer dom.deinit();

    var frontiers = try dominator.DominanceFrontiers.build(allocator, function.*, dom);
    defer frontiers.deinit();

    const block_count = function.blocks.items.len;
    const has_phi = try allocator.alloc(bool, block_count);
    defer allocator.free(has_phi);
    @memset(has_phi, false);

    const phi_names = try allocator.alloc(?[]const u8, block_count);
    defer allocator.free(phi_names);
    @memset(phi_names, null);

    const defines = try allocator.alloc(bool, block_count);
    defer allocator.free(defines);
    @memset(defines, false);

    var worklist: std.ArrayList(usize) = .empty;
    defer worklist.deinit(allocator);

    for (function.blocks.items, 0..) |block, block_index| {
        if (blockStoresSlot(block, slot)) {
            defines[block_index] = true;
            try worklist.append(allocator, block_index);
        }
    }

    while (worklist.pop()) |def_block| {
        for (frontiers.frontier(def_block)) |frontier_block| {
            if (has_phi[frontier_block]) continue;
            const phi_name = try newPhiName(module, slot, countPhis(phi_names));
            try insertSlotPhi(allocator, function, frontier_block, ty, phi_name);
            has_phi[frontier_block] = true;
            phi_names[frontier_block] = phi_name;
            if (!defines[frontier_block]) try worklist.append(allocator, frontier_block);
        }
    }

    var graph = try cfg.Graph.build(allocator, function.*);
    defer graph.deinit();

    var children = try buildDominatorChildren(allocator, dom);
    defer deinitChildren(allocator, &children);

    function.blocks.items[alloca_block_index].instructions.items[alloca_instruction_index].removed = true;
    try renameSlot(allocator, function, graph, children.items, phi_names, slot, 0, null);
}

fn blockStoresSlot(block: ir.BasicBlock, slot: []const u8) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .store => |store| if (isNamed(store.ptr, slot)) return true,
            .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .load, .gep, .call => {},
        }
    }
    return false;
}

fn newPhiName(module: *ir.Module, slot: []const u8, index: usize) ![]const u8 {
    return module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.{}", .{ slot, index }));
}

fn countPhis(phi_names: []const ?[]const u8) usize {
    var count: usize = 0;
    for (phi_names) |name| {
        if (name != null) count += 1;
    }
    return count;
}

fn insertSlotPhi(allocator: std.mem.Allocator, function: *ir.Function, block_index: usize, ty: ir.Type, phi_name: []const u8) !void {
    var incoming: std.ArrayList(ir.PhiIncoming) = .empty;
    errdefer incoming.deinit(allocator);

    try function.blocks.items[block_index].instructions.insert(allocator, 0, .{
        .result = phi_name,
        .kind = .{ .phi = .{
            .ty = ty,
            .incoming = incoming,
        } },
    });
}

fn buildDominatorChildren(allocator: std.mem.Allocator, dom: dominator.Dominators) !std.ArrayList(std.ArrayList(usize)) {
    var children: std.ArrayList(std.ArrayList(usize)) = .empty;
    errdefer deinitChildren(allocator, &children);
    try children.appendNTimes(allocator, .empty, dom.block_count);

    for (1..dom.block_count) |block_index| {
        const parent = dom.immediateDominator(block_index) orelse continue;
        try children.items[parent].append(allocator, block_index);
    }
    return children;
}

fn deinitChildren(allocator: std.mem.Allocator, children: *std.ArrayList(std.ArrayList(usize))) void {
    for (children.items) |*child_list| child_list.deinit(allocator);
    children.deinit(allocator);
}

fn renameSlot(
    allocator: std.mem.Allocator,
    function: *ir.Function,
    graph: cfg.Graph,
    children: []const std.ArrayList(usize),
    phi_names: []const ?[]const u8,
    slot: []const u8,
    block_index: usize,
    incoming_value: ?ir.Value,
) !void {
    var current_value = incoming_value;
    if (phi_names[block_index]) |phi_name| current_value = .{ .named = phi_name };

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
                    const value = current_value orelse .undef;
                    instruction.removed = true;
                    instruction.replacement = value;
                    replacement = .{ .name = result, .value = value };
                },
                .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep, .call => {},
            }
        }
        if (replacement) |item| replaceValue(function, item.name, item.value);
    }

    const outgoing_value = current_value orelse .undef;
    for (graph.successors(block_index)) |successor| {
        const phi_name = phi_names[successor] orelse continue;
        try addPhiIncoming(allocator, function, successor, phi_name, outgoing_value, function.blocks.items[block_index].name);
    }

    for (children[block_index].items) |child| {
        try renameSlot(allocator, function, graph, children, phi_names, slot, child, current_value);
    }
}

fn addPhiIncoming(allocator: std.mem.Allocator, function: *ir.Function, block_index: usize, phi_name: []const u8, value: ir.Value, predecessor: []const u8) !void {
    for (function.blocks.items[block_index].instructions.items) |*instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .phi => |*phi| {
                const result = instruction.result orelse continue;
                if (!std.mem.eql(u8, result, phi_name)) continue;
                try phi.incoming.append(allocator, .{
                    .value = value,
                    .block = predecessor,
                });
                return;
            },
            .binary, .cast, .freeze, .icmp, .select, .alloca, .load, .store, .gep, .call => return,
        }
    }
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
                    if (load.attrs.isBarrier()) return false;
                    if (block_index != slot_block_index) return false;
                },
                .store => |store| {
                    if (isNamed(store.value, slot)) return false;
                    if (!isNamed(store.ptr, slot)) continue;
                    if (store.attrs.isBarrier()) return false;
                    if (block_index != slot_block_index) return false;
                },
                .binary => |binary| {
                    if (isNamed(binary.lhs, slot) or isNamed(binary.rhs, slot)) return false;
                },
                .cast => |cast| {
                    if (isNamed(cast.value, slot)) return false;
                },
                .freeze => |freeze| {
                    if (isNamed(freeze.value, slot)) return false;
                },
                .icmp => |icmp| {
                    if (isNamed(icmp.lhs, slot) or isNamed(icmp.rhs, slot)) return false;
                },
                .select => |select| {
                    if (isNamed(select.cond, slot) or
                        isNamed(select.true_value, slot) or
                        isNamed(select.false_value, slot)) return false;
                },
                .phi => |phi| for (phi.incoming.items) |incoming| {
                    if (isNamed(incoming.value, slot)) return false;
                },
                .gep => |gep| {
                    if (isNamed(gep.ptr, slot)) return false;
                    for (gep.indices.items) |index| {
                        if (isNamed(index.value, slot)) return false;
                    }
                },
                .call => |call| for (call.args.items) |arg| {
                    if (isNamed(arg.value, slot)) return false;
                },
                .alloca => {},
            }
        }
        if (block.terminator) |terminator| switch (terminator) {
            .ret => |ret| if (ret.value) |value| if (isNamed(value, slot)) return false,
            .br => {},
            .@"unreachable" => {},
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
            .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep, .call => {},
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
                    const value = current_value orelse .undef;
                    instruction.removed = true;
                    instruction.replacement = value;
                    replacement = .{ .name = result, .value = value };
                },
                .binary, .cast, .freeze, .icmp, .select, .phi, .alloca, .gep, .call => {},
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

fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .undef => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}
