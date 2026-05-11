const std = @import("std");
const alias = @import("alias.zig");
const cfg = @import("cfg.zig");
const function_attrs = @import("function_attrs.zig");
const memory_effect = @import("memory_effect.zig");
const memory_location = @import("memory_location.zig");
const ir = @import("../ir.zig");
const target = @import("../target.zig");

pub const InstRef = struct {
    block_index: usize,
    instruction_index: usize,
};

pub const AccessKind = enum {
    use,
    def,
    barrier,
    phi,
};

pub const Access = struct {
    kind: AccessKind,
    block_index: usize,
    instruction_index: ?usize,
    ptr: ?ir.Value = null,
};

pub const MemorySSA = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: ir.Function,
    accesses: std.ArrayList(Access) = .empty,

    pub fn build(allocator: std.mem.Allocator, module: ir.Module, function: ir.Function) !MemorySSA {
        var memory: MemorySSA = .{
            .allocator = allocator,
            .module = module,
            .function = function,
        };
        errdefer memory.deinit();

        var graph = try cfg.Graph.build(allocator, function);
        defer graph.deinit();

        for (function.blocks.items, 0..) |block, block_index| {
            if (graph.predecessors(block_index).len > 1 and blockMayReachMemory(function, graph, block_index)) {
                try memory.accesses.append(allocator, .{
                    .kind = .phi,
                    .block_index = block_index,
                    .instruction_index = null,
                });
            }

            for (block.instructions.items, 0..) |instruction, instruction_index| {
                if (instruction.removed) continue;
                if (classifyAccess(module, instruction)) |kind| {
                    try memory.accesses.append(allocator, .{
                        .kind = kind,
                        .block_index = block_index,
                        .instruction_index = instruction_index,
                        .ptr = accessPointer(instruction),
                    });
                }
            }
        }

        return memory;
    }

    pub fn deinit(memory: *MemorySSA) void {
        memory.accesses.deinit(memory.allocator);
    }

    pub fn hasClobberBetween(memory: MemorySSA, from: InstRef, to: InstRef, ptr: ir.Value) bool {
        return memory.hasClobberBetweenAccess(from, to, ptr, null);
    }

    pub fn hasClobberBetweenAccess(memory: MemorySSA, from: InstRef, to: InstRef, ptr: ir.Value, access_ty: ?ir.Type) bool {
        for (memory.accesses.items) |access| {
            if (!isConservativelyBetween(access, from, to)) continue;
            switch (access.kind) {
                .use => {},
                .def, .barrier => {
                    const instruction_index = access.instruction_index orelse return true;
                    const instruction = memory.function.blocks.items[access.block_index].instructions.items[instruction_index];
                    if (isBarrierForAccess(memory.module, memory.function, instruction, ptr, access_ty)) return true;
                },
                .phi => return true,
            }
        }
        return false;
    }
};

pub fn hasClobberBetween(module: ir.Module, function: ir.Function, from: InstRef, to: InstRef, ptr: ir.Value) bool {
    for (function.blocks.items, 0..) |block, block_index| {
        for (block.instructions.items, 0..) |instruction, instruction_index| {
            if (instruction.removed) continue;
            const access: Access = .{
                .kind = classifyAccess(module, instruction) orelse continue,
                .block_index = block_index,
                .instruction_index = instruction_index,
                .ptr = accessPointer(instruction),
            };
            if (!isConservativelyBetween(access, from, to)) continue;
            if (isBarrier(module, function, instruction, ptr)) return true;
        }
    }
    return false;
}

pub fn isBarrier(module: ir.Module, function: ir.Function, instruction: ir.Instruction, ptr: ir.Value) bool {
    return isBarrierForAccess(module, function, instruction, ptr, null);
}

pub fn isBarrierForAccess(module: ir.Module, function: ir.Function, instruction: ir.Instruction, ptr: ir.Value, access_ty: ?ir.Type) bool {
    if (instruction.kind == .call) {
        return switch (function_attrs.callMemoryEffect(module, instruction.kind.call)) {
            .none, .readonly_load => false,
            .memory_write, .volatile_or_atomic_barrier, .unknown => true,
        };
    }
    const mod_ref = if (access_ty) |ty|
        alias.modRefInModuleForAccess(module, function, instruction, ptr, ty)
    else
        alias.modRefInModule(module, function, instruction, ptr);
    return switch (mod_ref) {
        .mod, .mod_ref, .unknown => true,
        .no_mod_ref, .ref => false,
    };
}

pub fn storeOverwrittenInBlock(function: ir.Function, layout: ?target.DataLayout, block: ir.BasicBlock, store_index: usize) bool {
    if (store_index >= block.instructions.items.len) return false;
    const store_instruction = block.instructions.items[store_index];
    const store = switch (store_instruction.kind) {
        .store => |store| store,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .gep, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .call => return false,
    };
    if (memory_effect.classify(store_instruction) == .volatile_or_atomic_barrier) return false;

    const location = accessLocation(function, layout, store.ptr, store.ty) orelse return false;

    for (block.instructions.items[store_index + 1 ..]) |instruction| {
        if (instruction.removed) continue;
        switch (instruction.kind) {
            .store => |later_store| {
                if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return false;
                const later = accessLocation(function, layout, later_store.ptr, later_store.ty) orelse return false;
                switch (alias.aliasLocations(later, location)) {
                    .must_alias => return true,
                    .may_alias => return false,
                    .no_alias => {},
                }
            },
            .load => |load| {
                if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return false;
                const later = accessLocation(function, layout, load.ptr, load.ty) orelse return false;
                if (alias.aliasLocations(later, location) != .no_alias) return false;
            },
            .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .call => return false,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => {},
        }
    }
    return false;
}

fn classifyAccess(module: ir.Module, instruction: ir.Instruction) ?AccessKind {
    return switch (instruction.kind) {
        .load => |load| if (load.attrs.isBarrier()) .barrier else .use,
        .store => |store| if (store.attrs.isBarrier()) .barrier else .def,
        .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector => .barrier,
        .call => |call| switch (function_attrs.callMemoryEffect(module, call)) {
            .none => null,
            .readonly_load => .use,
            .memory_write, .volatile_or_atomic_barrier, .unknown => .barrier,
        },
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep => null,
    };
}

fn accessPointer(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .load => |load| load.ptr,
        .store => |store| store.ptr,
        .atomicrmw => |atomicrmw| atomicrmw.ptr,
        .cmpxchg => |cmpxchg| cmpxchg.ptr,
        .fence, .extractelement, .insertelement, .shufflevector => null,
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .call => null,
    };
}

fn isConservativelyBetween(access: Access, from: InstRef, to: InstRef) bool {
    if (from.block_index != to.block_index) {
        if (access.block_index == from.block_index) {
            const instruction_index = access.instruction_index orelse return true;
            return instruction_index > from.instruction_index;
        }
        if (access.block_index == to.block_index) {
            const instruction_index = access.instruction_index orelse return true;
            return instruction_index < to.instruction_index;
        }
        return true;
    }

    if (access.block_index == from.block_index) {
        const instruction_index = access.instruction_index orelse return access.block_index != to.block_index;
        if (instruction_index <= from.instruction_index) return false;
    }
    if (access.block_index == to.block_index) {
        const instruction_index = access.instruction_index orelse return true;
        if (instruction_index >= to.instruction_index) return false;
    }
    return access.block_index == from.block_index;
}

fn blockMayReachMemory(function: ir.Function, graph: cfg.Graph, block_index: usize) bool {
    if (blockHasMemoryAccess(function.blocks.items[block_index])) return true;
    for (graph.predecessors(block_index)) |predecessor| {
        if (blockHasMemoryAccess(function.blocks.items[predecessor])) return true;
    }
    return false;
}

fn blockHasMemoryAccess(block: ir.BasicBlock) bool {
    for (block.instructions.items) |instruction| {
        if (instruction.removed) continue;
        if (instruction.kind == .load or instruction.kind == .store or instruction.kind == .atomicrmw or instruction.kind == .cmpxchg or instruction.kind == .fence or instruction.kind == .call) return true;
    }
    return false;
}

fn accessLocation(function: ir.Function, layout: ?target.DataLayout, ptr: ir.Value, ty: ir.Type) ?memory_location.MemoryLocation {
    if (layout) |target_layout| return memory_location.forAccessWithLayout(function, target_layout, ptr, ty);
    return memory_location.forAccess(function, ptr, ty);
}
