//! Exact-byte private accesses for non-native integer widths. Register carriers
//! may be wider; every memory operation stays inside ceil(source_bits / 8).
const std = @import("std");
const ir = @import("../../../ir.zig");
const machine = @import("../machine.zig");
const Candidate = @import("rewrite_candidate.zig").Candidate;
const forms = @import("scalar_forms.zig");
const addresses = @import("../symbol_address.zig");
const Integer = @import("../../../analysis/integer_semantics.zig").Integer;

fn nonNative(ty: ir.Type) bool {
    if (ty != .int or ty.int == 0 or ty.int > 128) return false;
    return switch (ty.int) {
        1, 8, 16, 32, 64, 128 => false,
        else => true,
    };
}

fn supported(access: anytype) bool {
    return nonNative(access.ty) and !access.attrs.isBarrier() and
        access.attrs.syncscope == null and access.ty_addrspace == null and access.ptr_addrspace == null;
}

fn carrier(ty: ir.Type) ir.Type {
    return .{ .int = if (ty.int <= 32) 32 else if (ty.int <= 64) 64 else 128 };
}

fn chunkBytes(remaining: u16) u16 {
    return if (remaining >= 8) 8 else if (remaining >= 4) 4 else if (remaining >= 2) 2 else 1;
}

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

    fn resize(b: Builder, from: ir.Type, value: ir.Value, to: ir.Type) !ir.Value {
        if (value == .undef or value == .poison or value == .zero_initializer) return .{ .int = 0 };
        if (from.eql(to)) return value;
        if (value == .int) {
            const bits = (Integer.init(from) orelse unreachable).unsigned(value.int);
            return .{ .int = @bitCast((Integer.init(to) orelse unreachable).unsigned(@bitCast(bits))) };
        }
        return b.emit(.{ .cast = .{ .op = if (from.int > to.int) .trunc else .zext, .from_ty = from, .value = value, .to_ty = to } });
    }

    fn shift(b: Builder, op: ir.BinaryOp, ty: ir.Type, value: ir.Value, bits: u16) !ir.Value {
        if (bits == 0) return value;
        if (value == .int) {
            const raw = (Integer.init(ty) orelse unreachable).unsigned(value.int);
            return .{ .int = @bitCast(if (op == .lshr) raw >> @as(u7, @intCast(bits)) else raw << @as(u7, @intCast(bits))) };
        }
        return b.emit(.{ .binary = .{ .op = op, .ty = ty, .lhs = value, .rhs = .{ .int = bits } } });
    }

    fn offset(b: Builder, ptr: ir.Value, bytes: u16) !ir.Value {
        if (bytes == 0) return ptr;
        var indices: std.ArrayList(ir.GepIndex) = .empty;
        try indices.append(b.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = bytes } });
        return b.emit(.{ .gep = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = indices } });
    }

    fn load(b: Builder, inst: ir.Instruction) !void {
        const original = inst.kind.load;
        const wide = carrier(original.ty);
        const bytes = (original.ty.int + 7) / 8;
        var offset_bytes: u16 = 0;
        var result: ir.Value = .{ .int = 0 };
        while (offset_bytes < bytes) {
            const count = chunkBytes(bytes - offset_bytes);
            const ty: ir.Type = .{ .int = count * 8 };
            const part = try b.emit(.{ .load = .{ .ty = ty, .ptr = try b.offset(original.ptr, offset_bytes), .attrs = .{ .@"align" = 1 } } });
            const shifted = try b.shift(.shl, wide, try b.resize(ty, part, wide), offset_bytes * 8);
            result = if (offset_bytes == 0) shifted else try b.emit(.{ .binary = .{ .op = .@"or", .ty = wide, .lhs = result, .rhs = shifted } });
            offset_bytes += count;
        }
        // Source metadata stays on the source instruction. In particular,
        // !range for the original width cannot decorate a cast or smaller load.
        try b.block.instructions.append(b.allocator, .{ .result = inst.result, .kind = .{ .cast = .{
            .op = .trunc,
            .from_ty = wide,
            .value = result,
            .to_ty = original.ty,
        } } });
    }

    fn store(b: Builder, inst: ir.Instruction) !void {
        const original = inst.kind.store;
        const wide = carrier(original.ty);
        const value = try b.resize(original.ty, original.value, wide);
        const bytes = (original.ty.int + 7) / 8;
        var offset_bytes: u16 = 0;
        while (offset_bytes < bytes) {
            const count = chunkBytes(bytes - offset_bytes);
            const ty: ir.Type = .{ .int = count * 8 };
            const shifted = try b.shift(.lshr, wide, value, offset_bytes * 8);
            try b.block.instructions.append(b.allocator, .{ .result = null, .kind = .{ .store = .{
                .ty = ty,
                .value = try b.resize(wide, shifted, ty),
                .ptr = try b.offset(original.ptr, offset_bytes),
                .attrs = .{ .@"align" = 1 },
            } } });
            offset_bytes += count;
        }
    }
};

pub fn legalize(allocator: std.mem.Allocator, function: ir.Function, context: ?*const machine.ReadOnlyModuleContext) !?ir.Function {
    if (!addresses.supportsLayout(if (context) |ctx| ctx.target_datalayout else null)) return null;
    var candidate = Candidate.init(allocator, function);
    var serial: forms.TemporaryNames = .{};
    defer serial.deinit(allocator);
    for (function.blocks.items, 0..) |original, block_index| {
        var block = original;
        block.instructions = .empty;
        const b: Builder = .{ .allocator = allocator, .function = function, .block = &block, .serial = &serial };
        for (original.instructions.items, 0..) |inst, instruction_index| {
            if (!inst.removed) switch (inst.kind) {
                .load => |load| if (inst.result != null and supported(load)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    try b.load(inst);
                    continue;
                },
                .store => |store| if (supported(store)) {
                    try candidate.begin(&block, block_index, instruction_index);
                    try b.store(inst);
                    continue;
                },
                else => {},
            };
            try candidate.keep(&block, inst);
        }
        try candidate.finishBlock(block);
    }
    return candidate.finish();
}
