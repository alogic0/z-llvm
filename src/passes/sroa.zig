const std = @import("std");
const memory_location = @import("../analysis/memory_location.zig");
const ir = @import("../ir.zig");
const mem2reg = @import("mem2reg.zig");
const pass_manager = @import("../pass_manager.zig");
const target = @import("../target.zig");

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
        changed = try forwardZeroOffsetGeps(module.allocator, function) or changed;
        changed = try scalarizeSimpleAggregateAllocas(module, function) or changed;
    }

    const promotion_result = try mem2reg.pass.run(module, context);
    changed = changed or promotion_result == .changed;
    return if (changed) .changed else .unchanged;
}

fn scalarizeSimpleAggregateAllocas(module: *ir.Module, function: *ir.Function) !bool {
    var changed = false;
    while (try scalarizeOneAggregateAlloca(module, function)) {
        changed = true;
    }
    return changed;
}

fn scalarizeOneAggregateAlloca(module: *ir.Module, function: *ir.Function) !bool {
    if (function.blocks.items.len == 0) return false;
    const entry_block = &function.blocks.items[0];
    for (entry_block.instructions.items, 0..) |instruction, instruction_index| {
        if (instruction.removed or instruction.kind != .alloca) continue;
        if (instruction.kind.alloca.allocated_ty != .aggregate) continue;
        const slot = instruction.result orelse continue;
        if (!try tryScalarizeAggregateAlloca(module, function, 0, instruction_index, slot, instruction.kind.alloca.allocated_ty)) continue;
        return true;
    }
    return false;
}

const AggregateGepUse = struct {
    const Kind = enum {
        field_gep,
    };

    gep_name: []const u8,
    field_index: usize,
    field_ty: ir.Type,
    offset: i128,
    size: u64,
    kind: Kind = .field_gep,
};

const FieldReplacement = struct {
    field_index: usize,
    ty: ir.Type,
    alloca_name: []const u8,
};

fn tryScalarizeAggregateAlloca(
    module: *ir.Module,
    function: *ir.Function,
    alloca_block_index: usize,
    alloca_instruction_index: usize,
    slot: []const u8,
    aggregate_ty: ir.Type,
) !bool {
    var gep_uses: std.ArrayList(AggregateGepUse) = .empty;
    defer gep_uses.deinit(module.allocator);

    if (!try collectAggregateGepUses(module.allocator, moduleLayout(module.*), function.*, slot, aggregate_ty, &gep_uses)) return false;
    if (gep_uses.items.len == 0) return false;
    if (!validateAggregateGepConsumers(function.*, slot, gep_uses.items)) return false;

    var replacements: std.ArrayList(FieldReplacement) = .empty;
    defer replacements.deinit(module.allocator);

    for (gep_uses.items) |gep_use| {
        if (fieldReplacementFor(replacements.items, gep_use.field_index) != null) continue;
        const name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.sroa.{}", .{ slot, gep_use.field_index }));
        try replacements.append(module.allocator, .{
            .field_index = gep_use.field_index,
            .ty = gep_use.field_ty,
            .alloca_name = name,
        });
    }

    var insertion_index = alloca_instruction_index + 1;
    for (replacements.items) |replacement| {
        try function.blocks.items[alloca_block_index].instructions.insert(module.allocator, insertion_index, .{
            .result = replacement.alloca_name,
            .kind = .{ .alloca = .{ .allocated_ty = replacement.ty } },
        });
        insertion_index += 1;
    }

    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .load => |*load| {
                    const gep_use = gepUseForPointer(gep_uses.items, load.ptr) orelse continue;
                    const replacement = fieldReplacementFor(replacements.items, gep_use.field_index) orelse continue;
                    load.ptr = .{ .named = replacement.alloca_name };
                },
                .store => |*store| {
                    const gep_use = gepUseForPointer(gep_uses.items, store.ptr) orelse continue;
                    const replacement = fieldReplacementFor(replacements.items, gep_use.field_index) orelse continue;
                    store.ptr = .{ .named = replacement.alloca_name };
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .atomicrmw, .cmpxchg, .fence, .gep, .call => {},
            }
        }
    }

    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            const result = inst.result orelse continue;
            for (gep_uses.items) |gep_use| {
                if (std.mem.eql(u8, result, gep_use.gep_name)) {
                    inst.removed = true;
                    break;
                }
            }
        }
    }
    function.blocks.items[alloca_block_index].instructions.items[alloca_instruction_index].removed = true;
    return true;
}

fn collectAggregateGepUses(
    allocator: std.mem.Allocator,
    layout: ?target.DataLayout,
    function: ir.Function,
    slot: []const u8,
    aggregate_ty: ir.Type,
    gep_uses: *std.ArrayList(AggregateGepUse),
) !bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, slot)) continue;
            }

            switch (instruction.kind) {
                .gep => |gep| {
                    if (isNamed(gep.ptr, slot)) {
                        const result = instruction.result orelse return false;
                        const use = aggregateFieldGep(layout, result, aggregate_ty, gep) orelse return false;
                        try gep_uses.append(allocator, use);
                    } else if (instructionUsesName(instruction, slot)) {
                        return false;
                    }
                },
                else => if (instructionUsesName(instruction, slot)) return false,
            }
        }
    }
    return true;
}

fn moduleLayout(module: ir.Module) ?target.DataLayout {
    const text = module.target_datalayout orelse return null;
    return target.DataLayout.parse(text) catch null;
}

fn aggregateFieldGep(layout: ?target.DataLayout, result: []const u8, aggregate_ty: ir.Type, gep: ir.GepInst) ?AggregateGepUse {
    if (!gep.source_ty.eql(aggregate_ty)) return null;
    if (gep.indices.items.len != 2) return null;
    const base_index = gep.indices.items[0].value;
    if (base_index != .int or base_index.int != 0) return null;
    const field_value = gep.indices.items[1].value;
    if (field_value != .int or field_value.int < 0) return null;
    const field_index: usize = @intCast(field_value.int);
    const field_ty = memory_location.aggregateFieldType(aggregate_ty, field_index) orelse return null;
    if (field_ty != .int) return null;
    const offset = if (layout) |target_layout|
        memory_location.aggregateFieldOffsetWithLayout(target_layout, aggregate_ty, field_index) orelse return null
    else
        memory_location.aggregateFieldOffset(aggregate_ty, field_index) orelse return null;
    const size = if (layout) |target_layout|
        memory_location.typeSizeWithLayout(target_layout, field_ty) orelse return null
    else
        memory_location.typeSize(field_ty) orelse return null;
    return .{
        .gep_name = result,
        .field_index = field_index,
        .field_ty = field_ty,
        .offset = offset,
        .size = size,
    };
}

fn validateAggregateGepConsumers(function: ir.Function, slot: []const u8, gep_uses: []const AggregateGepUse) bool {
    for (gep_uses) |gep_use| {
        var saw_memory_use = false;
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.result) |result| {
                    if (std.mem.eql(u8, result, gep_use.gep_name)) continue;
                }
                if (!instructionUsesName(instruction, gep_use.gep_name)) continue;
                switch (instruction.kind) {
                    .load => |load| {
                        if (!isNamed(load.ptr, gep_use.gep_name)) return false;
                        if (load.attrs.isBarrier()) return false;
                        if (!load.ty.eql(gep_use.field_ty)) return false;
                        saw_memory_use = true;
                    },
                    .store => |store| {
                        if (!isNamed(store.ptr, gep_use.gep_name)) return false;
                        if (store.attrs.isBarrier()) return false;
                        if (!store.ty.eql(gep_use.field_ty)) return false;
                        if (isNamed(store.value, slot)) return false;
                        saw_memory_use = true;
                    },
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .atomicrmw, .cmpxchg, .fence, .gep, .call => return false,
                }
            }
        }
        if (!saw_memory_use) return false;
    }
    return true;
}

fn gepUseForPointer(gep_uses: []const AggregateGepUse, ptr: ir.Value) ?AggregateGepUse {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .undef, .null_value => return null,
    };
    for (gep_uses) |gep_use| {
        if (std.mem.eql(u8, gep_use.gep_name, name)) return gep_use;
    }
    return null;
}

fn fieldReplacementFor(replacements: []const FieldReplacement, field_index: usize) ?FieldReplacement {
    for (replacements) |replacement| {
        if (replacement.field_index == field_index) return replacement;
    }
    return null;
}

fn forwardZeroOffsetGeps(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var slices = try AllocaSlices.collect(allocator, function.*);
    defer slices.deinit();

    var changed = false;
    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*instruction| {
            if (instruction.removed or instruction.kind != .gep) continue;
            const result = instruction.result orelse continue;
            const partition = slices.partitionFor(result) orelse continue;
            if (partition.offset != 0 or !partition.zero_offset_compatible) continue;
            if (instruction.kind.gep.source_ty == .aggregate) continue;
            const base = partition.alloca_root;

            replaceValue(function, result, .{ .named = base });
            instruction.removed = true;
            instruction.replacement = .{ .named = base };
            changed = true;
        }
    }
    return changed;
}

const AllocaSlice = struct {
    alloca_root: []const u8,
    value: []const u8,
    offset: i128,
    size: ?u64,
    zero_offset_compatible: bool,
};

const SlicePartition = struct {
    alloca_root: []const u8,
    offset: i128,
    size: ?u64,
    zero_offset_compatible: bool,
};

const AllocaSlices = struct {
    allocator: std.mem.Allocator,
    slices: std.ArrayList(AllocaSlice),

    fn collect(allocator: std.mem.Allocator, function: ir.Function) !AllocaSlices {
        var slices: std.ArrayList(AllocaSlice) = .empty;
        errdefer slices.deinit(allocator);

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed or instruction.kind != .gep) continue;
                const result = instruction.result orelse continue;
                const gep = instruction.kind.gep;
                const base = gepAllocaRoot(function, gep) orelse continue;
                const location = memory_location.forPointer(function, .{ .named = result }) orelse continue;
                try slices.append(allocator, .{
                    .alloca_root = base,
                    .value = result,
                    .offset = location.offset orelse continue,
                    .size = location.size,
                    .zero_offset_compatible = allIndicesAreZero(gep),
                });
            }
        }

        return .{
            .allocator = allocator,
            .slices = slices,
        };
    }

    fn deinit(alloca_slices: *AllocaSlices) void {
        alloca_slices.slices.deinit(alloca_slices.allocator);
    }

    fn partitionFor(alloca_slices: AllocaSlices, value: []const u8) ?SlicePartition {
        for (alloca_slices.slices.items) |slice| {
            if (!std.mem.eql(u8, slice.value, value)) continue;
            return .{
                .alloca_root = slice.alloca_root,
                .offset = slice.offset,
                .size = slice.size,
                .zero_offset_compatible = slice.zero_offset_compatible,
            };
        }
        return null;
    }
};

fn allocaBase(function: ir.Function, gep: ir.GepInst) ?[]const u8 {
    if (!allIndicesAreZero(gep)) return null;
    return zeroOffsetAllocaBase(function, gep.ptr);
}

fn gepAllocaRoot(function: ir.Function, gep: ir.GepInst) ?[]const u8 {
    return pointerAllocaRoot(function, gep.ptr);
}

fn pointerAllocaRoot(function: ir.Function, ptr: ir.Value) ?[]const u8 {
    const base_name = switch (ptr) {
        .named => |name| name,
        .int, .undef, .null_value => return null,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, base_name)) continue;
            return switch (instruction.kind) {
                .alloca => base_name,
                .gep => |gep| pointerAllocaRoot(function, gep.ptr),
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .call => null,
            };
        }
    }
    return null;
}

fn zeroOffsetAllocaBase(function: ir.Function, ptr: ir.Value) ?[]const u8 {
    const base_name = switch (ptr) {
        .named => |name| name,
        .int, .undef, .null_value => return null,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, base_name)) continue;
            return switch (instruction.kind) {
                .alloca => base_name,
                .gep => |gep| if (allIndicesAreZero(gep)) zeroOffsetAllocaBase(function, gep.ptr) else null,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .call => null,
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
                .fcmp => |*fcmp| {
                    fcmp.lhs = replaceOperand(fcmp.lhs, name, replacement);
                    fcmp.rhs = replaceOperand(fcmp.rhs, name, replacement);
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
                .atomicrmw => |*atomicrmw| {
                    atomicrmw.ptr = replaceOperand(atomicrmw.ptr, name, replacement);
                    atomicrmw.value = replaceOperand(atomicrmw.value, name, replacement);
                },
                .cmpxchg => |*cmpxchg| {
                    cmpxchg.ptr = replaceOperand(cmpxchg.ptr, name, replacement);
                    cmpxchg.expected = replaceOperand(cmpxchg.expected, name, replacement);
                    cmpxchg.replacement = replaceOperand(cmpxchg.replacement, name, replacement);
                },
                .fence => {},
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
        .int, .undef, .null_value => value,
        .named => |value_name| if (std.mem.eql(u8, value_name, name)) replacement else value,
    };
}

fn instructionUsesName(instruction: ir.Instruction, name: []const u8) bool {
    switch (instruction.kind) {
        .binary => |binary| return isNamed(binary.lhs, name) or isNamed(binary.rhs, name),
        .cast => |cast| return isNamed(cast.value, name),
        .freeze => |freeze| return isNamed(freeze.value, name),
        .icmp => |icmp| return isNamed(icmp.lhs, name) or isNamed(icmp.rhs, name),
        .fcmp => |fcmp| return isNamed(fcmp.lhs, name) or isNamed(fcmp.rhs, name),
        .select => |select| return isNamed(select.cond, name) or isNamed(select.true_value, name) or isNamed(select.false_value, name),
        .phi => |phi| {
            for (phi.incoming.items) |incoming| {
                if (isNamed(incoming.value, name)) return true;
            }
            return false;
        },
        .alloca => return false,
        .load => |load| return isNamed(load.ptr, name),
        .store => |store| return isNamed(store.value, name) or isNamed(store.ptr, name),
        .atomicrmw => |atomicrmw| return isNamed(atomicrmw.ptr, name) or isNamed(atomicrmw.value, name),
        .cmpxchg => |cmpxchg| return isNamed(cmpxchg.ptr, name) or isNamed(cmpxchg.expected, name) or isNamed(cmpxchg.replacement, name),
        .fence => return false,
        .gep => |gep| {
            if (isNamed(gep.ptr, name)) return true;
            for (gep.indices.items) |index| {
                if (isNamed(index.value, name)) return true;
            }
            return false;
        },
        .call => |call| {
            for (call.args.items) |arg| {
                if (isNamed(arg.value, name)) return true;
            }
            return false;
        },
    }
}

fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .undef, .null_value => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}
