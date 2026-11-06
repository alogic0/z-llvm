//! Split ordinary i128 memory operations into two little-endian words. Loads
//! capture both words at the original instruction, rather than aliasing a slot
//! that a later store or call could change. Atomic and volatile accesses stay
//! outside this expansion.
const std = @import("std");
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
    serial: *usize,

    fn emit(b: Builder, kind: @FieldType(ir.Instruction, "kind")) !ir.Value {
        const name = try forms.temporary(b.allocator, b.function, b.serial);
        try b.block.instructions.append(b.allocator, .{ .result = name, .kind = kind });
        return .{ .named = name };
    }
    fn upper(b: Builder, ptr: ir.Value) !ir.Value {
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.allocator, .{ .ty = word, .value = .{ .int = 8 } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }
    fn cast(b: Builder, op: ir.CastOp, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        return b.emit(.{ .cast = .{ .op = op, .from_ty = from, .value = value, .to_ty = to } });
    }
};

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
    var result = function;
    result.blocks = .empty;
    var serial: usize = 0;
    var changed = false;
    for (function.blocks.items) |original| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items, 0..) |inst, index| {
            if (!inst.removed and inst.kind == .load and inst.result != null and supported(inst.kind.load) and
                !finalStackRead(function, original, index, inst.kind.load.ptr))
            {
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
                changed = true;
            } else if (!inst.removed and inst.kind == .store and supported(inst.kind.store) and (inst.kind.store.value == .named or inst.kind.store.value == .int)) {
                const access = inst.kind.store;
                var high_attrs = access.attrs;
                high_attrs.@"align" = @min(access.attrs.@"align" orelse 8, 8);
                const hi_ptr = try b.upper(access.ptr);
                const lo = if (access.value == .int) ir.Value{ .int = @as(u64, @truncate(@as(u128, @bitCast(access.value.int)))) } else try b.cast(.trunc, pair, access.value, word);
                const hi = if (access.value == .int) ir.Value{ .int = @as(u64, @truncate(@as(u128, @bitCast(access.value.int)) >> 64)) } else try b.cast(.trunc, pair, try b.emit(.{ .binary = .{ .op = .lshr, .ty = pair, .lhs = access.value, .rhs = .{ .int = 64 } } }), word);
                try block.instructions.append(allocator, .{ .result = null, .metadata = inst.metadata, .kind = .{ .store = .{ .ty = word, .value = lo, .ptr = access.ptr, .attrs = access.attrs } } });
                try block.instructions.append(allocator, .{ .result = null, .metadata = inst.metadata, .kind = .{ .store = .{ .ty = word, .value = hi, .ptr = hi_ptr, .attrs = high_attrs } } });
                changed = true;
            } else try block.instructions.append(allocator, inst);
        }
        try result.blocks.append(allocator, block);
    }
    return if (changed) result else null;
}
