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

pub const ClobberResult = union(enum) {
    live_on_entry,
    access: Access,

    pub fn found(result: ClobberResult) bool {
        return switch (result) {
            .live_on_entry => false,
            .access => true,
        };
    }
};

pub const Walker = struct {
    memory: MemorySSA,

    pub fn getClobberingMemoryAccess(walker: Walker, query: InstRef, ptr: ir.Value, access_ty: ?ir.Type) ClobberResult {
        return walker.getClobberingMemoryAccessBefore(query, ptr, access_ty);
    }

    pub fn getClobberingMemoryAccessForAccess(walker: Walker, access_index: usize, ptr: ir.Value, access_ty: ?ir.Type) ClobberResult {
        if (access_index >= walker.memory.accesses.items.len) return .live_on_entry;
        const access = walker.memory.accesses.items[access_index];
        const instruction_index = access.instruction_index orelse 0;
        return walker.getClobberingMemoryAccessBefore(.{
            .block_index = access.block_index,
            .instruction_index = instruction_index,
        }, ptr, access_ty);
    }

    pub fn getClobberBetween(walker: Walker, from: InstRef, to: InstRef, ptr: ir.Value, access_ty: ?ir.Type) ClobberResult {
        var index = walker.memory.accesses.items.len;
        while (index > 0) {
            index -= 1;
            const access = walker.memory.accesses.items[index];
            if (!walker.memory.isPathAwareBetween(access, from, to)) continue;
            if (walker.accessClobbers(access, ptr, access_ty)) return .{ .access = access };
        }
        return .live_on_entry;
    }

    fn getClobberingMemoryAccessBefore(walker: Walker, query: InstRef, ptr: ir.Value, access_ty: ?ir.Type) ClobberResult {
        var index = walker.memory.accesses.items.len;
        while (index > 0) {
            index -= 1;
            const access = walker.memory.accesses.items[index];
            if (!walker.accessCanReachQuery(access, query)) continue;
            if (walker.accessClobbers(access, ptr, access_ty)) return .{ .access = access };
        }
        return .live_on_entry;
    }

    fn accessCanReachQuery(walker: Walker, access: Access, query: InstRef) bool {
        if (access.block_index == query.block_index) {
            const instruction_index = access.instruction_index orelse return true;
            return instruction_index < query.instruction_index;
        }
        return walker.memory.canReach(access.block_index, query.block_index);
    }

    fn accessClobbers(walker: Walker, access: Access, ptr: ir.Value, access_ty: ?ir.Type) bool {
        return switch (access.kind) {
            .use => false,
            .def, .barrier => {
                const instruction_index = access.instruction_index orelse return true;
                const instruction = walker.memory.function.blocks.items[access.block_index].instructions.items[instruction_index];
                return isBarrierForAccess(walker.memory.module, walker.memory.function, instruction, ptr, access_ty);
            },
            .phi => true,
        };
    }
};

pub const MemorySSA = struct {
    allocator: std.mem.Allocator,
    module: ir.Module,
    function: ir.Function,
    graph: cfg.Graph,
    accesses: std.ArrayList(Access) = .empty,

    pub fn build(allocator: std.mem.Allocator, module: ir.Module, function: ir.Function) !MemorySSA {
        var graph = try cfg.Graph.build(allocator, function);

        var memory: MemorySSA = .{
            .allocator = allocator,
            .module = module,
            .function = function,
            .graph = graph,
        };
        errdefer memory.deinit();

        const reachable = try graph.reachableFromEntry(allocator);
        defer allocator.free(reachable);

        for (function.blocks.items, 0..) |block, block_index| {
            if (graph.predecessors(block_index).len > 1 and blockMayReachMemory(function, graph, reachable, block_index)) {
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
        memory.graph.deinit();
    }

    pub fn hasClobberBetween(memory: MemorySSA, from: InstRef, to: InstRef, ptr: ir.Value) bool {
        return memory.hasClobberBetweenAccess(from, to, ptr, null);
    }

    pub fn hasClobberBetweenAccess(memory: MemorySSA, from: InstRef, to: InstRef, ptr: ir.Value, access_ty: ?ir.Type) bool {
        return memory.getWalker().getClobberBetween(from, to, ptr, access_ty).found();
    }

    pub fn getWalker(memory: MemorySSA) Walker {
        return .{ .memory = memory };
    }

    pub fn findAccessIndex(memory: MemorySSA, ref: InstRef) ?usize {
        for (memory.accesses.items, 0..) |access, index| {
            if (access.block_index != ref.block_index) continue;
            if (access.instruction_index == null or access.instruction_index.? != ref.instruction_index) continue;
            return index;
        }
        return null;
    }

    pub fn deleteAccess(memory: *MemorySSA, block_index: usize, instruction_index: usize) bool {
        for (memory.accesses.items, 0..) |access, index| {
            if (access.block_index != block_index) continue;
            if (access.instruction_index == null or access.instruction_index.? != instruction_index) continue;
            _ = memory.accesses.orderedRemove(index);
            return true;
        }
        return false;
    }

    pub fn replaceInstructionAccess(memory: *MemorySSA, block_index: usize, instruction_index: usize, instruction: ir.Instruction) !bool {
        const new_kind = classifyAccess(memory.module, instruction);
        const new_ptr = accessPointer(instruction);
        for (memory.accesses.items) |*access| {
            if (access.block_index != block_index) continue;
            if (access.instruction_index == null or access.instruction_index.? != instruction_index) continue;
            if (new_kind) |kind| {
                access.kind = kind;
                access.ptr = new_ptr;
                return true;
            }
            return memory.deleteAccess(block_index, instruction_index);
        }
        if (new_kind) |kind| {
            try memory.accesses.append(memory.allocator, .{
                .kind = kind,
                .block_index = block_index,
                .instruction_index = instruction_index,
                .ptr = new_ptr,
            });
            return true;
        }
        return false;
    }

    pub fn verifyConsistent(memory: MemorySSA) !void {
        var rebuilt = try MemorySSA.build(memory.allocator, memory.module, memory.function);
        defer rebuilt.deinit();
        if (memory.accesses.items.len != rebuilt.accesses.items.len) return error.MemorySSAOutOfDate;
        for (memory.accesses.items, rebuilt.accesses.items) |actual, expected| {
            if (!sameAccess(actual, expected)) return error.MemorySSAOutOfDate;
        }
    }

    pub fn dump(memory: MemorySSA, writer: anytype) !void {
        for (memory.accesses.items) |access| {
            try writer.print("{s} block={} inst=", .{ @tagName(access.kind), access.block_index });
            if (access.instruction_index) |instruction_index| {
                try writer.print("{}", .{instruction_index});
            } else {
                try writer.writeAll("phi");
            }
            if (access.ptr) |ptr| {
                try writer.writeAll(" ptr=");
                try ptr.format(writer);
            }
            try writer.writeByte('\n');
        }
    }

    fn isPathAwareBetween(memory: MemorySSA, access: Access, from: InstRef, to: InstRef) bool {
        if (from.block_index == to.block_index) {
            return isConservativelyBetween(access, from, to);
        }
        if (access.block_index == from.block_index) {
            const instruction_index = access.instruction_index orelse return true;
            return instruction_index > from.instruction_index and memory.canReach(from.block_index, to.block_index);
        }
        if (access.block_index == to.block_index) {
            const instruction_index = access.instruction_index orelse return true;
            return instruction_index < to.instruction_index and memory.canReach(from.block_index, to.block_index);
        }
        return memory.canReach(from.block_index, access.block_index) and
            memory.canReach(access.block_index, to.block_index);
    }

    fn canReach(memory: MemorySSA, start: usize, target_block: usize) bool {
        if (start == target_block) return true;
        var seen = memory.allocator.alloc(bool, memory.function.blocks.items.len) catch return true;
        defer memory.allocator.free(seen);
        @memset(seen, false);

        var worklist: std.ArrayList(usize) = .empty;
        defer worklist.deinit(memory.allocator);
        worklist.append(memory.allocator, start) catch return true;
        seen[start] = true;

        while (worklist.pop()) |block_index| {
            for (memory.graph.successors(block_index)) |successor| {
                if (successor == target_block) return true;
                if (seen[successor]) continue;
                seen[successor] = true;
                worklist.append(memory.allocator, successor) catch return true;
            }
        }
        return false;
    }
};

pub const VerifyError = error{MemorySSAOutOfDate};

pub fn verifyFunction(allocator: std.mem.Allocator, module: ir.Module, function: ir.Function) !void {
    var memory = try MemorySSA.build(allocator, module, function);
    defer memory.deinit();
    try memory.verifyConsistent();
}

fn sameAccess(a: Access, b: Access) bool {
    if (a.kind != b.kind) return false;
    if (a.block_index != b.block_index) return false;
    if (a.instruction_index != b.instruction_index) return false;
    if (a.ptr == null and b.ptr == null) return true;
    if (a.ptr == null or b.ptr == null) return false;
    return a.ptr.?.eql(b.ptr.?);
}

pub fn hasClobberBetween(module: ir.Module, function: ir.Function, from: InstRef, to: InstRef, ptr: ir.Value) bool {
    var memory = MemorySSA.build(module.allocator, module, function) catch return true;
    defer memory.deinit();
    return memory.hasClobberBetween(from, to, ptr);
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
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .load, .gep, .atomicrmw, .cmpxchg, .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue, .call => return false,
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
                    .must_alias => return fullyOverwrites(later, location),
                    .partial_alias, .may_alias => return false,
                    .no_alias => {},
                }
            },
            .load => |load| {
                if (memory_effect.classify(instruction) == .volatile_or_atomic_barrier) return false;
                const later = accessLocation(function, layout, load.ptr, load.ty) orelse return false;
                if (alias.aliasLocations(later, location) != .no_alias) return false;
            },
            .atomicrmw, .cmpxchg, .fence, .call => return false,
            .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => {},
        }
    }
    return false;
}

fn fullyOverwrites(later: memory_location.MemoryLocation, earlier: memory_location.MemoryLocation) bool {
    const later_start = later.offset orelse return false;
    const earlier_start = earlier.offset orelse return false;
    const later_end = later.rangeEnd() orelse return false;
    const earlier_end = earlier.rangeEnd() orelse return false;
    return later_start <= earlier_start and later_end >= earlier_end;
}

fn classifyAccess(module: ir.Module, instruction: ir.Instruction) ?AccessKind {
    return switch (instruction.kind) {
        .load => |load| if (load.attrs.isBarrier()) .barrier else .use,
        .store => |store| if (store.attrs.isBarrier()) .barrier else .def,
        .atomicrmw, .cmpxchg, .fence => .barrier,
        .call => |call| switch (function_attrs.callMemoryEffect(module, call)) {
            .none => null,
            .readonly_load => .use,
            .memory_write, .volatile_or_atomic_barrier, .unknown => .barrier,
        },
        .binary, .cast, .freeze, .icmp, .fcmp, .select, .phi, .alloca, .gep, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => null,
    };
}

fn accessPointer(instruction: ir.Instruction) ?ir.Value {
    return switch (instruction.kind) {
        .load => |load| load.ptr,
        .store => |store| store.ptr,
        .atomicrmw => |atomicrmw| atomicrmw.ptr,
        .cmpxchg => |cmpxchg| cmpxchg.ptr,
        .fence, .extractelement, .insertelement, .shufflevector, .extractvalue, .insertvalue => null,
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

fn blockMayReachMemory(function: ir.Function, graph: cfg.Graph, reachable: []const bool, block_index: usize) bool {
    for (graph.predecessors(block_index)) |predecessor| {
        if (!reachable[predecessor]) continue;
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
