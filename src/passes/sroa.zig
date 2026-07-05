const std = @import("std");
const memory_location = @import("../analysis/memory_location.zig");
const ir = @import("../ir.zig");
const mem2reg = @import("mem2reg.zig");
const pass_manager = @import("../pass_manager.zig");
const target = @import("../target.zig");

pub const pass: pass_manager.ModulePass = .{
    .name = "sroa",
    .category = .memory,
    .target_status = "LLVM-shaped algorithm subset",
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
    var slices = try AllocaSlices.collect(module.allocator, moduleLayout(module.*), function.*);
    defer slices.deinit();

    var partitions = try slices.partitionsForAlloca(module.allocator, slot);
    defer partitions.deinit(module.allocator);
    if (partitions.items.len == 0 and hasWholeAggregateAllocaAccess(function.*, slot, aggregate_ty)) {
        if (!try appendWholeAggregatePartitions(module.allocator, moduleLayout(module.*), &partitions, slot, aggregate_ty)) return false;
    }

    if (partitions.items.len == 0) return false;
    const layout = moduleLayout(module.*);
    if (!try aggregateAllocaOnlyUsesPartitions(module.allocator, layout, function.*, slot, aggregate_ty, partitions.items)) return false;
    if (!validateAggregatePartitionConsumers(function.*, slot, aggregate_ty, partitions.items)) return false;

    var replacements: std.ArrayList(FieldReplacement) = .empty;
    defer replacements.deinit(module.allocator);

    for (partitions.items) |partition| {
        const field_index = partition.field_index orelse return false;
        const field_ty = partition.field_ty orelse return false;
        if (fieldReplacementFor(replacements.items, field_index) != null) continue;
        const name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.sroa.{}", .{ slot, field_index }));
        try replacements.append(module.allocator, .{
            .field_index = field_index,
            .ty = field_ty,
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

    try rewriteWholeAggregateMemoryUses(module, function, slot, aggregate_ty, replacements.items);
    try rewriteAggregateSubobjectStores(module, function, slot, partitions.items, replacements.items);
    try rewriteAggregateSubobjectLoads(module, function, slot, partitions.items, replacements.items);

    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            switch (inst.kind) {
                .load => |*load| {
                    const partition = partitionForPointer(partitions.items, load.ptr) orelse continue;
                    const replacement = fieldReplacementFor(replacements.items, partition.field_index orelse continue) orelse continue;
                    const old_result = inst.result;
                    load.ptr = .{ .named = replacement.alloca_name };
                    if (old_result) |result| {
                        const new_result = try sroaLoadName(module, replacement.alloca_name, result);
                        inst.result = new_result;
                        replaceValue(function, result, .{ .named = new_result });
                    }
                },
                .store => |*store| {
                    const partition = partitionForPointer(partitions.items, store.ptr) orelse continue;
                    const replacement = fieldReplacementFor(replacements.items, partition.field_index orelse continue) orelse continue;
                    store.ptr = .{ .named = replacement.alloca_name };
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => {},
            }
        }
    }

    for (function.blocks.items) |*block| {
        for (block.instructions.items) |*inst| {
            if (inst.removed) continue;
            const result = inst.result orelse continue;
            for (partitions.items) |partition| {
                if (std.mem.eql(u8, result, partition.value)) {
                    inst.removed = true;
                    break;
                }
            }
        }
    }
    removeDeadAllocaRootedGeps(function, slot);
    function.blocks.items[alloca_block_index].instructions.items[alloca_instruction_index].removed = true;
    return true;
}

fn aggregateAllocaOnlyUsesPartitions(
    allocator: std.mem.Allocator,
    layout: ?target.DataLayout,
    function: ir.Function,
    slot: []const u8,
    aggregate_ty: ir.Type,
    partitions: []const SlicePartition,
) !bool {
    var partition_values = std.StringHashMap(void).init(allocator);
    defer partition_values.deinit();
    for (partitions) |partition| {
        if (!partition.source_ty.eql(aggregate_ty)) return false;
        try partition_values.put(partition.value, {});
    }

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
                        if (!partition_values.contains(result) and !gepResultFeedsOnlyPartitions(layout, function, result, partitions, &partition_values)) return false;
                    } else if (instructionUsesName(instruction, slot)) {
                        return false;
                    }
                },
                .load => |load| {
                    if (isNamed(load.ptr, slot)) {
                        if (!load.ty.eql(aggregate_ty) or load.attrs.isBarrier()) return false;
                    } else if (instructionUsesName(instruction, slot)) {
                        return false;
                    }
                },
                .store => |store| {
                    if (isNamed(store.ptr, slot)) {
                        if (!store.ty.eql(aggregate_ty) or store.attrs.isBarrier()) return false;
                        if (isNamed(store.value, slot)) return false;
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

fn gepResultFeedsOnlyPartitions(
    layout: ?target.DataLayout,
    function: ir.Function,
    value: []const u8,
    partitions: []const SlicePartition,
    partition_values: *const std.StringHashMap(void),
) bool {
    var saw_use = false;
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, value)) continue;
            }
            if (!instructionUsesName(instruction, value)) continue;
            switch (instruction.kind) {
                .gep => {
                    const result = instruction.result orelse return false;
                    if (!partition_values.contains(result) and !gepResultFeedsOnlyPartitions(layout, function, result, partitions, partition_values)) return false;
                },
                .store => |store| {
                    if (!isNamed(store.ptr, value)) return false;
                    if (!aggregateSubobjectAccessHasPartition(layout, function, value, store.ty, partitions)) return false;
                },
                .load => |load| {
                    if (!isNamed(load.ptr, value)) return false;
                    if (load.attrs.isBarrier()) return false;
                    if (!aggregateSubobjectAccessHasPartition(layout, function, value, load.ty, partitions)) return false;
                },
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => return false,
            }
            saw_use = true;
        }
    }
    return saw_use;
}

fn aggregateSubobjectAccessHasPartition(
    layout: ?target.DataLayout,
    function: ir.Function,
    ptr: []const u8,
    aggregate_ty: ir.Type,
    partitions: []const SlicePartition,
) bool {
    if (aggregate_ty != .aggregate) return false;
    const location = pointerLocation(layout, function, .{ .named = ptr }) orelse return false;
    const base_offset = location.offset orelse return false;
    for (partitions) |partition| {
        if (sourceFieldIndexForPartition(layout, aggregate_ty, base_offset, partition) != null) return true;
    }
    return false;
}

fn moduleLayout(module: ir.Module) ?target.DataLayout {
    const text = module.target_datalayout orelse default_data_layout;
    return target.DataLayout.parse(text) catch null;
}

const default_data_layout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128";

fn aggregateFieldSlice(layout: ?target.DataLayout, function: ir.Function, result: []const u8, alloca_root: []const u8, aggregate_ty: ir.Type, gep: ir.GepInst) ?AllocaSlice {
    if (gep.indices.items.len < 2) return null;
    const base_index = gep.indices.items[0].value;
    if (base_index != .int or base_index.int != 0) return null;
    const path = aggregateFieldPath(gep) orelse return null;
    const field_ty = aggregateLeafFieldType(gep.source_ty, path) orelse return null;
    if (!isScalarizableAggregateField(field_ty, layout != null)) return null;
    const base_location = if (layout) |target_layout|
        memory_location.forPointerWithLayout(function, target_layout, gep.ptr) orelse return null
    else
        memory_location.forPointer(function, gep.ptr) orelse return null;
    if (base_location.root_kind != .stack or !std.mem.eql(u8, base_location.root, alloca_root)) return null;
    const base_offset = base_location.offset orelse return null;
    const offset = if (layout) |target_layout|
        base_offset + (memory_location.gepOffsetWithLayout(target_layout, gep) orelse return null)
    else
        base_offset + (memory_location.gepOffset(gep) orelse return null);
    const size = if (layout) |target_layout|
        memory_location.typeSizeWithLayout(target_layout, field_ty) orelse return null
    else
        memory_location.typeSize(field_ty) orelse return null;
    return .{
        .kind = .aggregate_field,
        .alloca_root = alloca_root,
        .value = result,
        .source_ty = aggregate_ty,
        .field_index = aggregateFieldPathId(aggregate_ty, gep.source_ty, path, offset) orelse return null,
        .field_ty = field_ty,
        .offset = offset,
        .size = size,
        .zero_offset_compatible = false,
    };
}

fn aggregateFieldPath(gep: ir.GepInst) ?[]const ir.GepIndex {
    if (gep.indices.items.len < 2) return null;
    for (gep.indices.items[1..]) |index| {
        if (index.value != .int or index.value.int < 0) return null;
    }
    return gep.indices.items[1..];
}

fn aggregateLeafFieldType(root_ty: ir.Type, path: []const ir.GepIndex) ?ir.Type {
    var current_ty = root_ty;
    for (path) |index| {
        const field_index: usize = @intCast(index.value.int);
        current_ty = memory_location.aggregateFieldType(current_ty, field_index) orelse return null;
    }
    return current_ty;
}

fn aggregateFieldPathId(root_ty: ir.Type, source_ty: ir.Type, path: []const ir.GepIndex, offset: i128) ?usize {
    if (path.len == 0) return null;
    if (source_ty.eql(root_ty) and path.len == 1) return @intCast(path[0].value.int);

    if (offset < 0) return null;
    const offset_id: usize = @intCast(offset);
    if (offset_id > std.math.maxInt(usize) - 4096) return null;
    return 4096 + offset_id;
}

fn isScalarizableAggregateField(field_ty: ir.Type, has_layout: bool) bool {
    return switch (field_ty) {
        .int => true,
        .ptr => has_layout,
        .void, .half, .float, .double, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
    };
}

fn validateAggregatePartitionConsumers(function: ir.Function, slot: []const u8, aggregate_ty: ir.Type, partitions: []const SlicePartition) bool {
    for (partitions) |partition| {
        const field_ty = partition.field_ty orelse return false;
        var saw_memory_use = false;
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed) continue;
                if (instruction.result) |result| {
                    if (std.mem.eql(u8, result, partition.value)) continue;
                }
                if (!instructionUsesName(instruction, partition.value)) continue;
                switch (instruction.kind) {
                    .load => |load| {
                        if (std.mem.eql(u8, partition.value, slot) and isNamed(load.ptr, slot) and load.ty.eql(aggregate_ty) and !load.attrs.isBarrier()) {
                            saw_memory_use = true;
                            continue;
                        }
                        if (!isNamed(load.ptr, partition.value)) return false;
                        if (load.attrs.isAtomic()) return false;
                        if (!load.ty.eql(field_ty)) return false;
                        saw_memory_use = true;
                    },
                    .store => |store| {
                        if (std.mem.eql(u8, partition.value, slot) and isNamed(store.ptr, slot) and store.ty.eql(aggregate_ty) and !store.attrs.isBarrier()) {
                            saw_memory_use = true;
                            continue;
                        }
                        if (!isNamed(store.ptr, partition.value)) return false;
                        if (store.attrs.isAtomic()) return false;
                        if (!store.ty.eql(field_ty)) return false;
                        if (isNamed(store.value, slot)) return false;
                        saw_memory_use = true;
                    },
                    .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => return false,
                }
            }
        }
        if (!saw_memory_use) return false;
    }
    return true;
}

fn hasWholeAggregateAllocaAccess(function: ir.Function, slot: []const u8, aggregate_ty: ir.Type) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .load => |load| if (isNamed(load.ptr, slot) and load.ty.eql(aggregate_ty)) return true,
                .store => |store| if (isNamed(store.ptr, slot) and store.ty.eql(aggregate_ty)) return true,
                else => {},
            }
        }
    }
    return false;
}

fn appendWholeAggregatePartitions(
    allocator: std.mem.Allocator,
    layout: ?target.DataLayout,
    partitions: *std.ArrayList(SlicePartition),
    slot: []const u8,
    aggregate_ty: ir.Type,
) !bool {
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        if (!isScalarizableAggregateField(field_ty, layout != null)) return false;
        const offset = if (layout) |target_layout|
            memory_location.aggregateFieldOffsetWithLayout(target_layout, aggregate_ty, field_index) orelse return false
        else
            memory_location.aggregateFieldOffset(aggregate_ty, field_index) orelse return false;
        const size = if (layout) |target_layout|
            memory_location.typeSizeWithLayout(target_layout, field_ty) orelse return false
        else
            memory_location.typeSize(field_ty) orelse return false;
        const partition: SlicePartition = .{
            .kind = .aggregate_field,
            .alloca_root = slot,
            .value = slot,
            .source_ty = aggregate_ty,
            .offset = offset,
            .size = size,
            .zero_offset_compatible = false,
            .field_index = field_index,
            .field_ty = field_ty,
        };
        if (partitionOverlapsDifferentField(partitions.items, partition)) return false;
        try partitions.append(allocator, partition);
    }
    return field_index != 0;
}

fn rewriteWholeAggregateMemoryUses(
    module: *ir.Module,
    function: *ir.Function,
    slot: []const u8,
    aggregate_ty: ir.Type,
    replacements: []const FieldReplacement,
) !void {
    for (function.blocks.items) |*block| {
        var instruction_index: usize = 0;
        while (instruction_index < block.instructions.items.len) : (instruction_index += 1) {
            const instruction = &block.instructions.items[instruction_index];
            if (instruction.removed) continue;
            switch (instruction.kind) {
                .store => |store| {
                    if (!isNamed(store.ptr, slot) or !store.ty.eql(aggregate_ty)) continue;
                    const inserted = try rewriteWholeAggregateStore(module, block, instruction_index, aggregate_ty, store.value, replacements);
                    block.instructions.items[instruction_index + inserted].removed = true;
                    instruction_index += inserted;
                },
                .load => |load| {
                    if (!isNamed(load.ptr, slot) or !load.ty.eql(aggregate_ty)) continue;
                    const result = instruction.result orelse continue;
                    const rewrite = try rewriteWholeAggregateLoad(module, block, instruction_index, result, aggregate_ty, replacements);
                    replaceValue(function, result, .{ .named = rewrite.value });
                    block.instructions.items[instruction_index + rewrite.inserted].removed = true;
                    block.instructions.items[instruction_index + rewrite.inserted].replacement = .{ .named = rewrite.value };
                    instruction_index += rewrite.inserted;
                },
                else => {},
            }
        }
    }
}

fn rewriteWholeAggregateStore(
    module: *ir.Module,
    block: *ir.BasicBlock,
    instruction_index: usize,
    aggregate_ty: ir.Type,
    aggregate_value: ir.Value,
    replacements: []const FieldReplacement,
) !usize {
    var insert_index = instruction_index;
    for (replacements) |replacement| {
        const aggregate_name = switch (aggregate_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => replacement.alloca_name,
        };
        const extract_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.fca.{}.extract", .{ aggregate_name, replacement.field_index }));
        const index_text = try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{replacement.field_index}));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = extract_name,
            .kind = .{ .extractvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .indices = index_text,
                .result_ty = replacement.ty,
            } },
        });
        insert_index += 1;
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = replacement.ty,
                .value = .{ .named = extract_name },
                .ptr = .{ .named = replacement.alloca_name },
            } },
        });
        insert_index += 1;
    }
    return insert_index - instruction_index;
}

fn sroaLoadName(module: *ir.Module, alloca_name: []const u8, original_name: []const u8) ![]const u8 {
    return try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.0.{s}.0.{s}", .{ alloca_name, alloca_name, original_name }));
}

const AggregateLoadRewrite = struct {
    value: []const u8,
    inserted: usize,
};

fn rewriteWholeAggregateLoad(
    module: *ir.Module,
    block: *ir.BasicBlock,
    instruction_index: usize,
    load_name: []const u8,
    aggregate_ty: ir.Type,
    replacements: []const FieldReplacement,
) !AggregateLoadRewrite {
    var insert_index = instruction_index;
    var aggregate_value: ir.Value = .poison;
    var final_name: ?[]const u8 = null;
    for (replacements) |replacement| {
        const scalar_load_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.sroa.load.{}", .{ load_name, replacement.field_index }));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = scalar_load_name,
            .kind = .{ .load = .{
                .ty = replacement.ty,
                .ptr = .{ .named = replacement.alloca_name },
            } },
        });
        insert_index += 1;

        const insert_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.fca.{}.insert", .{ load_name, replacement.field_index }));
        const index_text = try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{replacement.field_index}));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = insert_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = replacement.ty,
                .value = .{ .named = scalar_load_name },
                .indices = index_text,
            } },
        });
        insert_index += 1;
        aggregate_value = .{ .named = insert_name };
        final_name = insert_name;
    }
    return .{
        .value = final_name orelse load_name,
        .inserted = insert_index - instruction_index,
    };
}

const AggregateStoreField = struct {
    source_field_index: usize,
    ty: ir.Type,
    alloca_name: []const u8,
};

fn rewriteAggregateSubobjectStores(
    module: *ir.Module,
    function: *ir.Function,
    slot: []const u8,
    partitions: []const SlicePartition,
    replacements: []const FieldReplacement,
) !void {
    const layout = moduleLayout(module.*);
    for (function.blocks.items) |*block| {
        var instruction_index: usize = 0;
        while (instruction_index < block.instructions.items.len) : (instruction_index += 1) {
            const instruction = &block.instructions.items[instruction_index];
            if (instruction.removed or instruction.kind != .store) continue;
            const store = instruction.kind.store;
            if (store.ty != .aggregate or store.attrs.isBarrier()) continue;
            const location = pointerLocation(layout, function.*, store.ptr) orelse continue;
            if (location.root_kind != .stack or !std.mem.eql(u8, location.root, slot)) continue;
            const base_offset = location.offset orelse continue;

            var fields: std.ArrayList(AggregateStoreField) = .empty;
            defer fields.deinit(module.allocator);
            for (partitions) |partition| {
                const source_field_index = sourceFieldIndexForPartition(layout, store.ty, base_offset, partition) orelse continue;
                const replacement = fieldReplacementFor(replacements, partition.field_index orelse continue) orelse continue;
                try fields.append(module.allocator, .{
                    .source_field_index = source_field_index,
                    .ty = partition.field_ty orelse continue,
                    .alloca_name = replacement.alloca_name,
                });
            }
            if (fields.items.len == 0) continue;

            const inserted = try rewriteAggregateSubobjectStore(module, block, instruction_index, store.ty, store.value, fields.items);
            block.instructions.items[instruction_index + inserted].removed = true;
            instruction_index += inserted;
        }
    }
}

fn rewriteAggregateSubobjectStore(
    module: *ir.Module,
    block: *ir.BasicBlock,
    instruction_index: usize,
    aggregate_ty: ir.Type,
    aggregate_value: ir.Value,
    fields: []const AggregateStoreField,
) !usize {
    var insert_index = instruction_index;
    for (fields) |field| {
        const aggregate_name = switch (aggregate_value) {
            .named => |name| name,
            .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => field.alloca_name,
        };
        const extract_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.fca.{}.extract", .{ aggregate_name, field.source_field_index }));
        const index_text = try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{field.source_field_index}));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = extract_name,
            .kind = .{ .extractvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .indices = index_text,
                .result_ty = field.ty,
            } },
        });
        insert_index += 1;
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = field.ty,
                .value = .{ .named = extract_name },
                .ptr = .{ .named = field.alloca_name },
            } },
        });
        insert_index += 1;
    }
    return insert_index - instruction_index;
}

fn rewriteAggregateSubobjectLoads(
    module: *ir.Module,
    function: *ir.Function,
    slot: []const u8,
    partitions: []const SlicePartition,
    replacements: []const FieldReplacement,
) !void {
    const layout = moduleLayout(module.*);
    for (function.blocks.items) |*block| {
        var instruction_index: usize = 0;
        while (instruction_index < block.instructions.items.len) : (instruction_index += 1) {
            const instruction = &block.instructions.items[instruction_index];
            if (instruction.removed or instruction.kind != .load) continue;
            const load = instruction.kind.load;
            if (load.ty != .aggregate or load.attrs.isBarrier()) continue;
            const result = instruction.result orelse continue;
            const location = pointerLocation(layout, function.*, load.ptr) orelse continue;
            if (location.root_kind != .stack or !std.mem.eql(u8, location.root, slot)) continue;
            const base_offset = location.offset orelse continue;

            var fields: std.ArrayList(AggregateStoreField) = .empty;
            defer fields.deinit(module.allocator);
            for (partitions) |partition| {
                const source_field_index = sourceFieldIndexForPartition(layout, load.ty, base_offset, partition) orelse continue;
                const replacement = fieldReplacementFor(replacements, partition.field_index orelse continue) orelse continue;
                try fields.append(module.allocator, .{
                    .source_field_index = source_field_index,
                    .ty = partition.field_ty orelse continue,
                    .alloca_name = replacement.alloca_name,
                });
            }
            if (fields.items.len == 0) continue;

            const rewrite = try rewriteAggregateSubobjectLoad(module, block, instruction_index, result, load.ty, fields.items);
            replaceValue(function, result, .{ .named = rewrite.value });
            block.instructions.items[instruction_index + rewrite.inserted].removed = true;
            block.instructions.items[instruction_index + rewrite.inserted].replacement = .{ .named = rewrite.value };
            instruction_index += rewrite.inserted;
        }
    }
}

fn rewriteAggregateSubobjectLoad(
    module: *ir.Module,
    block: *ir.BasicBlock,
    instruction_index: usize,
    load_name: []const u8,
    aggregate_ty: ir.Type,
    fields: []const AggregateStoreField,
) !AggregateLoadRewrite {
    var insert_index = instruction_index;
    var aggregate_value: ir.Value = .poison;
    var final_name: ?[]const u8 = null;
    for (fields) |field| {
        const scalar_load_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.sroa.load.{}", .{ load_name, field.source_field_index }));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = scalar_load_name,
            .kind = .{ .load = .{
                .ty = field.ty,
                .ptr = .{ .named = field.alloca_name },
            } },
        });
        insert_index += 1;

        const insert_name = try module.ownString(try std.fmt.allocPrint(module.allocator, "{s}.fca.{}.insert", .{ load_name, field.source_field_index }));
        const index_text = try module.ownString(try std.fmt.allocPrint(module.allocator, "{}", .{field.source_field_index}));
        try block.instructions.insert(module.allocator, insert_index, .{
            .result = insert_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = aggregate_ty,
                .aggregate = aggregate_value,
                .value_ty = field.ty,
                .value = .{ .named = scalar_load_name },
                .indices = index_text,
            } },
        });
        insert_index += 1;
        aggregate_value = .{ .named = insert_name };
        final_name = insert_name;
    }
    return .{
        .value = final_name orelse load_name,
        .inserted = insert_index - instruction_index,
    };
}

fn sourceFieldIndexForPartition(layout: ?target.DataLayout, aggregate_ty: ir.Type, base_offset: i128, partition: SlicePartition) ?usize {
    var field_index: usize = 0;
    while (memory_location.aggregateFieldType(aggregate_ty, field_index)) |field_ty| : (field_index += 1) {
        if (!field_ty.eql(partition.field_ty orelse return null)) continue;
        const field_offset = if (layout) |target_layout|
            memory_location.aggregateFieldOffsetWithLayout(target_layout, aggregate_ty, field_index) orelse return null
        else
            memory_location.aggregateFieldOffset(aggregate_ty, field_index) orelse return null;
        if (base_offset + field_offset == partition.offset) return field_index;
    }
    return null;
}

fn pointerLocation(layout: ?target.DataLayout, function: ir.Function, ptr: ir.Value) ?memory_location.MemoryLocation {
    if (layout) |target_layout| return memory_location.forPointerWithLayout(function, target_layout, ptr);
    return memory_location.forPointer(function, ptr);
}

fn partitionForPointer(partitions: []const SlicePartition, ptr: ir.Value) ?SlicePartition {
    const name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };
    for (partitions) |partition| {
        if (std.mem.eql(u8, partition.value, name)) return partition;
    }
    return null;
}

fn fieldReplacementFor(replacements: []const FieldReplacement, field_index: usize) ?FieldReplacement {
    for (replacements) |replacement| {
        if (replacement.field_index == field_index) return replacement;
    }
    return null;
}

fn removeDeadAllocaRootedGeps(function: *ir.Function, slot: []const u8) void {
    var changed = true;
    while (changed) {
        changed = false;
        for (function.blocks.items) |*block| {
            for (block.instructions.items) |*instruction| {
                if (instruction.removed or instruction.kind != .gep) continue;
                const result = instruction.result orelse continue;
                const root = gepAllocaRoot(function.*, instruction.kind.gep) orelse continue;
                if (!std.mem.eql(u8, root, slot)) continue;
                if (valueHasUses(function.*, result)) continue;
                instruction.removed = true;
                changed = true;
            }
        }
    }
}

fn valueHasUses(function: ir.Function, name: []const u8) bool {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            if (instruction.result) |result| {
                if (std.mem.eql(u8, result, name)) continue;
            }
            if (instructionUsesName(instruction, name)) return true;
        }
        if (block.terminator) |terminator| {
            if (terminatorUsesName(terminator, name)) return true;
        }
    }
    return false;
}

fn forwardZeroOffsetGeps(allocator: std.mem.Allocator, function: *ir.Function) !bool {
    var slices = try AllocaSlices.collect(allocator, null, function.*);
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
    const Kind = enum {
        pointer_gep,
        aggregate_field,
    };

    kind: Kind,
    alloca_root: []const u8,
    value: []const u8,
    source_ty: ir.Type,
    offset: i128,
    size: ?u64,
    zero_offset_compatible: bool,
    field_index: ?usize = null,
    field_ty: ?ir.Type = null,
};

const SlicePartition = struct {
    kind: AllocaSlice.Kind,
    alloca_root: []const u8,
    value: []const u8,
    source_ty: ir.Type,
    offset: i128,
    size: ?u64,
    zero_offset_compatible: bool,
    field_index: ?usize = null,
    field_ty: ?ir.Type = null,
};

const AllocaSlices = struct {
    allocator: std.mem.Allocator,
    slices: std.ArrayList(AllocaSlice),

    fn collect(allocator: std.mem.Allocator, layout: ?target.DataLayout, function: ir.Function) !AllocaSlices {
        var slices: std.ArrayList(AllocaSlice) = .empty;
        errdefer slices.deinit(allocator);

        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                if (instruction.removed or instruction.kind != .gep) continue;
                const result = instruction.result orelse continue;
                const gep = instruction.kind.gep;
                const base = gepAllocaRoot(function, gep) orelse continue;
                if (rootAllocaType(function, base)) |root_ty| {
                    if (root_ty == .aggregate) {
                        if (aggregateFieldSlice(layout, function, result, base, root_ty, gep)) |slice| {
                            try slices.append(allocator, slice);
                        }
                    }
                }
                if (memory_location.forPointer(function, .{ .named = result })) |location| {
                    try slices.append(allocator, .{
                        .kind = .pointer_gep,
                        .alloca_root = base,
                        .value = result,
                        .source_ty = gep.source_ty,
                        .offset = location.offset orelse continue,
                        .size = location.size,
                        .zero_offset_compatible = allIndicesAreZero(gep),
                    });
                }
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
            return partitionFromSlice(slice);
        }
        return null;
    }

    fn partitionsForAlloca(alloca_slices: AllocaSlices, allocator: std.mem.Allocator, alloca_root: []const u8) !std.ArrayList(SlicePartition) {
        var partitions: std.ArrayList(SlicePartition) = .empty;
        errdefer partitions.deinit(allocator);

        for (alloca_slices.slices.items) |slice| {
            if (slice.kind != .aggregate_field) continue;
            if (!std.mem.eql(u8, slice.alloca_root, alloca_root)) continue;
            const partition = partitionFromSlice(slice);
            if (partitionOverlapsDifferentField(partitions.items, partition)) return error.OverlappingSroaPartition;
            try partitions.append(allocator, partition);
        }

        sortPartitions(partitions.items);
        return partitions;
    }
};

fn partitionFromSlice(slice: AllocaSlice) SlicePartition {
    return .{
        .kind = slice.kind,
        .alloca_root = slice.alloca_root,
        .value = slice.value,
        .source_ty = slice.source_ty,
        .offset = slice.offset,
        .size = slice.size,
        .zero_offset_compatible = slice.zero_offset_compatible,
        .field_index = slice.field_index,
        .field_ty = slice.field_ty,
    };
}

fn partitionOverlapsDifferentField(partitions: []const SlicePartition, candidate: SlicePartition) bool {
    const candidate_size = candidate.size orelse return true;
    const candidate_end = candidate.offset + @as(i128, @intCast(candidate_size));
    for (partitions) |partition| {
        const size = partition.size orelse return true;
        const end = partition.offset + @as(i128, @intCast(size));
        const overlaps = candidate.offset < end and partition.offset < candidate_end;
        if (overlaps and !optionalUsizeEql(partition.field_index, candidate.field_index)) return true;
    }
    return false;
}

fn sortPartitions(items: []SlicePartition) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        const value = items[i];
        var j = i;
        while (j > 0 and items[j - 1].offset > value.offset) : (j -= 1) {
            items[j] = items[j - 1];
        }
        items[j] = value;
    }
}

fn optionalUsizeEql(a: ?usize, b: ?usize) bool {
    if (a == null or b == null) return a == null and b == null;
    return a.? == b.?;
}

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
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, base_name)) continue;
            return switch (instruction.kind) {
                .alloca => base_name,
                .gep => |gep| pointerAllocaRoot(function, gep.ptr),
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => null,
            };
        }
    }
    return null;
}

fn rootAllocaType(function: ir.Function, alloca_root: []const u8) ?ir.Type {
    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, alloca_root)) continue;
            return switch (instruction.kind) {
                .alloca => |alloca| alloca.allocated_ty,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .gep, .call => null,
            };
        }
    }
    return null;
}

fn zeroOffsetAllocaBase(function: ir.Function, ptr: ir.Value) ?[]const u8 {
    const base_name = switch (ptr) {
        .named => |name| name,
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return null,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, base_name)) continue;
            return switch (instruction.kind) {
                .alloca => base_name,
                .gep => |gep| if (allIndicesAreZero(gep)) zeroOffsetAllocaBase(function, gep.ptr) else null,
                .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .load, .store, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => null,
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
                .fence, .extractelement, .insertelement, .shufflevector => {},
                .extractvalue => |*extract| extract.aggregate = replaceOperand(extract.aggregate, name, replacement),
                .insertvalue => |*insert| {
                    insert.aggregate = replaceOperand(insert.aggregate, name, replacement);
                    insert.value = replaceOperand(insert.value, name, replacement);
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
            .indirectbr => |*indirectbr| indirectbr.addr = replaceOperand(indirectbr.addr, name, replacement),
            .@"switch" => |*switch_term| {
                switch_term.cond = replaceOperand(switch_term.cond, name, replacement);
                for (switch_term.cases.items) |*case| {
                    case.value = replaceOperand(case.value, name, replacement);
                }
            },
        };
    }
}

fn replaceOperand(value: ir.Value, name: []const u8, replacement: ir.Value) ir.Value {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => value,
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
        .fence, .extractelement, .insertelement, .shufflevector => return false,
        .extractvalue => |extract| return isNamed(extract.aggregate, name),
        .insertvalue => |insert| return isNamed(insert.aggregate, name) or isNamed(insert.value, name),
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

fn terminatorUsesName(terminator: ir.Terminator, name: []const u8) bool {
    return switch (terminator) {
        .ret => |ret| if (ret.value) |value| isNamed(value, name) else false,
        .br, .@"unreachable" => false,
        .condbr => |condbr| isNamed(condbr.cond, name),
        .indirectbr => |indirectbr| isNamed(indirectbr.addr, name),
        .@"switch" => |switch_term| {
            if (isNamed(switch_term.cond, name)) return true;
            for (switch_term.cases.items) |case| {
                if (isNamed(case.value, name)) return true;
            }
            return false;
        },
    };
}

fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        .named => |value_name| std.mem.eql(u8, value_name, name),
    };
}
