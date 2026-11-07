//! Lower ordinary i128, scalar FP and two-lane FP memory to exact-width words. Loads
//! capture both words at the original instruction, rather than aliasing a slot
//! that a later store or call could change. Atomic and volatile accesses stay
//! outside this expansion.
const std = @import("std");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const addresses = @import("../symbol_address.zig");
const forms = @import("scalar_forms.zig");
const word: ir.Type = .{ .int = 64 };
const pair: ir.Type = .{ .int = 128 };

const Builder = struct {
    allocator: std.mem.Allocator,
    function: ir.Function,
    block: *ir.BasicBlock,
    serial: *forms.TemporaryNames,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn upper(b: Builder, ptr: ir.Value) !ir.Value {
        return b.offset(ptr, 8);
    }
    fn offset(b: Builder, ptr: ir.Value, bytes: u16) !ir.Value {
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.allocator, .{ .ty = word, .value = .{ .int = bytes } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }

    fn floatScalar(b: Builder, inst: ir.Instruction) !void {
        var access = inst;
        if (inst.kind == .load) {
            const scalar = inst.kind.load.ty;
            const integer: ir.Type = .{ .int = if (scalar == .float) 32 else 64 };
            access.result = try forms.temporary(b.allocator, b.function, b.serial);
            access.kind.load.ty = integer;
            try b.block.instructions.append(b.allocator, access);
            try b.block.instructions.append(b.allocator, .{ .result = inst.result, .kind = .{ .cast = .{
                .op = .bitcast,
                .from_ty = integer,
                .value = .{ .named = access.result.? },
                .to_ty = scalar,
            } } });
        } else {
            const scalar = inst.kind.store.ty;
            const integer: ir.Type = .{ .int = if (scalar == .float) 32 else 64 };
            access.kind.store.value = try b.cast(.bitcast, scalar, inst.kind.store.value, integer);
            access.kind.store.ty = integer;
            try b.block.instructions.append(b.allocator, access);
        }
    }

    fn floatPair(b: Builder, inst: ir.Instruction) !void {
        const load = inst.kind == .load;
        const ty = if (load) inst.kind.load.ty else inst.kind.store.ty;
        const ptr = if (load) inst.kind.load.ptr else inst.kind.store.ptr;
        const attrs = if (load) inst.kind.load.attrs else inst.kind.store.attrs;
        const scalar = ty.vector.elem_ty.toType();
        const stride: u16 = if (scalar == .float) 4 else 8;
        const integer: ir.Type = .{ .int = stride * 8 };
        const high_ptr = try b.offset(ptr, stride);
        var value: ir.Value = .poison;
        for (0..2) |lane| {
            var access = inst;
            var lane_attrs = attrs;
            if (lane == 1) lane_attrs.@"align" = @min(attrs.@"align" orelse stride, stride);
            const lane_ptr = if (lane == 0) ptr else high_ptr;
            if (load) {
                access.result = try forms.temporary(b.allocator, b.function, b.serial);
                access.kind.load = .{ .ty = integer, .ptr = lane_ptr, .attrs = lane_attrs };
                try b.block.instructions.append(b.allocator, access);
                const part = try b.cast(.bitcast, integer, .{ .named = access.result.? }, scalar);
                const name = if (lane == 1) inst.result.? else try forms.temporary(b.allocator, b.function, b.serial);
                try b.block.instructions.append(b.allocator, .{ .result = name, .kind = .{ .insertelement = .{
                    .vector_ty = ty,
                    .vector = value,
                    .value_ty = scalar,
                    .value = part,
                    .index_ty = word,
                    .index = .{ .int = @intCast(lane) },
                } } });
                value = .{ .named = name };
            } else {
                const part = try b.emit(.{ .extractelement = .{
                    .vector_ty = ty,
                    .vector = inst.kind.store.value,
                    .index_ty = word,
                    .index = .{ .int = @intCast(lane) },
                } });
                const bits = try b.cast(.bitcast, scalar, part, integer);
                access.kind.store = .{ .ty = integer, .value = bits, .ptr = lane_ptr, .attrs = lane_attrs };
                try b.block.instructions.append(b.allocator, access);
            }
        }
    }
};

fn supportedFloatPair(access: anytype) bool {
    return access.ty == .vector and access.ty.vector.len == 2 and
        (access.ty.vector.elem_ty == .float or access.ty.vector.elem_ty == .double) and
        access.ty_addrspace == null and access.ptr_addrspace == null and
        !access.attrs.isBarrier() and access.attrs.syncscope == null;
}

/// Symbolic globals and typed scalar stack objects retain their existing
/// owners, including addresses derived through unordered blocks and PHIs.
/// A worklist propagates these roots in linear graph work; no per-load scan.
const PreservedPointers = struct {
    allocator: std.mem.Allocator,
    roots: std.StringHashMap(void),
    dependents: std.StringHashMap(std.ArrayList([]const u8)),
    queue: std.ArrayList([]const u8) = .empty,
    initialized: bool = false,

    fn init(allocator: std.mem.Allocator) PreservedPointers {
        return .{ .allocator = allocator, .roots = .init(allocator), .dependents = .init(allocator) };
    }
    fn deinit(p: *PreservedPointers) void {
        var lists = p.dependents.valueIterator();
        while (lists.next()) |list| list.deinit(p.allocator);
        p.dependents.deinit();
        p.roots.deinit();
        p.queue.deinit(p.allocator);
    }
    fn root(p: *PreservedPointers, name: []const u8) !void {
        const entry = try p.roots.getOrPut(name);
        if (!entry.found_existing) try p.queue.append(p.allocator, name);
    }
    fn edge(p: *PreservedPointers, parent: ir.Value, child: []const u8) !void {
        if (parent == .constant_expr or (parent == .named and std.mem.startsWith(u8, parent.named, "@"))) return p.root(child);
        if (parent != .named) return;
        const entry = try p.dependents.getOrPut(parent.named);
        if (!entry.found_existing) entry.value_ptr.* = .empty;
        try entry.value_ptr.append(p.allocator, child);
    }
    fn collect(p: *PreservedPointers, function: ir.Function) !void {
        if (p.initialized) return;
        for (function.blocks.items) |block| for (block.instructions.items) |inst| {
            if (inst.removed) continue;
            const name = inst.result orelse continue;
            switch (inst.kind) {
                .alloca => |alloca| if (alloca.allocated_ty != .aggregate and alloca.allocated_ty != .vector and alloca.isSingleObject()) try p.root(name),
                .gep => |gep| try p.edge(gep.ptr, name),
                .cast => |cast| if (cast.from_ty == .ptr and cast.to_ty == .ptr) try p.edge(cast.value, name),
                .freeze => |freeze| if (freeze.ty == .ptr) try p.edge(freeze.value, name),
                .select => |select| if (select.ty == .ptr) {
                    try p.edge(select.true_value, name);
                    try p.edge(select.false_value, name);
                },
                .phi => |phi| if (phi.ty == .ptr) {
                    for (phi.incoming.items) |incoming| try p.edge(incoming.value, name);
                },
                else => {},
            }
        };
        var next: usize = 0;
        while (next < p.queue.items.len) : (next += 1) {
            if (p.dependents.get(p.queue.items[next])) |children|
                for (children.items) |child| try p.root(child);
        }
        p.initialized = true;
    }
    fn contains(p: *const PreservedPointers, value: ir.Value) bool {
        if (value == .constant_expr) return true;
        if (value != .named) return false;
        return std.mem.startsWith(u8, value.named, "@") or p.roots.contains(value.named);
    }
};

fn supportedFloatScalar(function: ir.Function, access: anytype, preserved: *PreservedPointers) !bool {
    if ((access.ty != .float and access.ty != .double) or
        access.ty_addrspace != null or access.ptr_addrspace != null or
        access.attrs.isBarrier() or access.attrs.syncscope != null) return false;
    try preserved.collect(function);
    return !preserved.contains(access.ptr);
}

fn supported(access: anytype) bool {
    return access.ty.eql(pair) and access.ty_addrspace == null and access.ptr_addrspace == null and
        !access.attrs.isBarrier() and access.attrs.syncscope == null;
}

fn finalStackRead(function: ir.Function, block: ir.BasicBlock, index: usize, ptr: ir.Value) bool {
    if (ptr != .named or block.terminator == null or block.terminator.? != .ret) return false;
    var local_slot = false;
    for (function.blocks.items) |candidate| for (candidate.instructions.items) |inst| {
        if (!inst.removed and inst.result != null and ir.identifiers.eql(inst.result.?, ptr.named) and
            inst.kind == .alloca and inst.kind.alloca.allocated_ty.eql(pair) and inst.kind.alloca.isSingleObject()) local_slot = true;
    };
    if (!local_slot) return false;
    // The existing stack-value owner may defer reads until a use. That is
    // equivalent only when no later operation can modify the local slot or
    // transfer control elsewhere. Retain that compact, proven leaf form.
    for (block.instructions.items[index + 1 ..]) |inst| {
        if (inst.removed) continue;
        switch (inst.kind) {
            .binary, .cast, .icmp, .fcmp, .select, .freeze => {},
            else => return false,
        }
    }
    return true;
}

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    var preserved = PreservedPointers.init(allocator);
    defer preserved.deinit();
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed and ((inst.kind == .load and inst.result != null and try supportedFloatScalar(function, inst.kind.load, &preserved)) or
                (inst.kind == .store and try supportedFloatScalar(function, inst.kind.store, &preserved))))
            {
                try candidate.begin(&block, block_index, instruction_index);
                try b.floatScalar(inst);
            } else if (!inst.removed and ((inst.kind == .load and inst.result != null and supportedFloatPair(inst.kind.load)) or
                (inst.kind == .store and supportedFloatPair(inst.kind.store))))
            {
                try candidate.begin(&block, block_index, instruction_index);
                try b.floatPair(inst);
            } else if (!inst.removed and inst.kind == .load and inst.result != null and supported(inst.kind.load) and
                !finalStackRead(function, original, instruction_index, inst.kind.load.ptr))
            {
                try candidate.begin(&block, block_index, instruction_index);
                const access = inst.kind.load;
                var high_attrs = access.attrs;
                high_attrs.@"align" = @min(access.attrs.@"align" orelse 8, 8);
                const hi_ptr = try b.upper(access.ptr);
                const lo = try b.emit(.{ .load = .{ .ty = word, .ptr = access.ptr, .attrs = access.attrs } });
                const hi = try b.emit(.{ .load = .{ .ty = word, .ptr = hi_ptr, .attrs = high_attrs } });
                const low_pair = try b.cast(.zext, word, lo, pair);
                const high_pair = try b.cast(.zext, word, hi, pair);
                const shifted = try b.emit(.{ .binary = .{ .op = .shl, .ty = pair, .lhs = high_pair, .rhs = .{ .int = 64 } } });
                try block.instructions.append(allocator, .{ .result = inst.result, .metadata = inst.metadata, .kind = .{ .binary = .{ .op = .@"or", .ty = pair, .lhs = low_pair, .rhs = shifted } } });
            } else if (!inst.removed and inst.kind == .store and supported(inst.kind.store) and (inst.kind.store.value == .named or inst.kind.store.value == .int)) {
                try candidate.begin(&block, block_index, instruction_index);
                const access = inst.kind.store;
                var high_attrs = access.attrs;
                high_attrs.@"align" = @min(access.attrs.@"align" orelse 8, 8);
                const hi_ptr = try b.upper(access.ptr);
                const lo = if (access.value == .int) ir.Value{ .int = @as(u64, @truncate(@as(u128, @bitCast(access.value.int)))) } else try b.cast(.trunc, pair, access.value, word);
                const hi = if (access.value == .int) ir.Value{ .int = @as(u64, @truncate(@as(u128, @bitCast(access.value.int)) >> 64)) } else try b.cast(.trunc, pair, try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = access.value, .rhs = .{ .int = 64 } } }), word);
                try block.instructions.append(allocator, .{ .result = null, .metadata = inst.metadata, .kind = .{ .store = .{ .ty = word, .value = lo, .ptr = access.ptr, .attrs = access.attrs } } });
                try block.instructions.append(allocator, .{ .result = null, .metadata = inst.metadata, .kind = .{ .store = .{ .ty = word, .value = hi, .ptr = hi_ptr, .attrs = high_attrs } } });
            } else try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
