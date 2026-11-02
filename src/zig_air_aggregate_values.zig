const std = @import("std");
const ir = @import("ir.zig");
const model = @import("zig_air_model.zig");
const type_layout = @import("zig_air_type_layout.zig");
const target = @import("target.zig");

const layout_text = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128";

// Aggregate values are SSA snapshots. Only explicit pointers may defer a read.
pub fn load(self: anytype, index: u32, ty: ir.Type, ptr: ir.Value) model.LowerError!ir.Value {
    var serial: usize = 0;
    return loadAt(self, index, ty, ptr, 0, &serial, 0);
}

fn address(self: anytype, index: u32, ptr: ir.Value, offset: u64, serial: *usize) !ir.Value {
    if (offset == 0) return ptr;
    const name = try model.ownPrint(self.module, "air{}_snapshot_ptr_{}", .{ index, serial.* });
    serial.* += 1;
    var gep: ir.GepInst = .{ .source_ty = .{ .int = 8 }, .ptr = ptr, .indices = .empty };
    errdefer gep.deinit(self.allocator);
    try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
    try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .gep = gep } });
    return .{ .named = name };
}

fn loadAt(self: anytype, index: u32, ty: ir.Type, ptr: ir.Value, offset: u64, serial: *usize, depth: usize) model.LowerError!ir.Value {
    if (depth > 16 or serial.* > 4096) return error.UnsupportedAir;
    const dl = target.DataLayout.parse(self.module.target_datalayout orelse layout_text) catch return error.UnsupportedAir;
    if (ty != .aggregate) {
        const src = try address(self, index, ptr, offset, serial);
        const name = try model.ownPrint(self.module, "air{}_snapshot_leaf_{}", .{ index, serial.* });
        serial.* += 1;
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .load = .{ .ty = ty, .ptr = src } } });
        return .{ .named = name };
    }
    const normalized = type_layout.normalizeAggregateTypeChecked(ty) catch return error.UnsupportedAir;
    const count = type_layout.fieldCount(normalized);
    if (count == 0 or count > type_layout.max_aggregate_layout_leaves) return error.UnsupportedAir;
    var value: ir.Value = .undef;
    for (0..count) |field| {
        const field_ty = type_layout.fieldType(normalized, field) orelse return error.UnsupportedAir;
        const field_offset = type_layout.fieldByteOffset(dl, normalized, field) orelse return error.UnsupportedAir;
        const leaf = try loadAt(self, index, field_ty, ptr, std.math.add(u64, offset, field_offset) catch return error.UnsupportedAir, serial, depth + 1);
        const name = try model.ownPrint(self.module, "air{}_snapshot_value_{}", .{ index, serial.* });
        serial.* += 1;
        try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .insertvalue = .{
            .aggregate_ty = normalized,
            .aggregate = value,
            .value_ty = field_ty,
            .value = leaf,
            .indices = try model.ownPrint(self.module, "{d}", .{field}),
        } } });
        value = .{ .named = name };
    }
    return value;
}

pub fn store(self: anytype, index: u32, ty: ir.Type, value: ir.Value, ptr: ir.Value) model.LowerError!void {
    var serial: usize = 8192;
    try storeAt(self, index, ty, value, ptr, 0, &serial, 0);
}

fn constructedField(self: anytype, value: ir.Value, field: usize) ?ir.Value {
    var current = value;
    var budget = self.block.instructions.items.len + 1;
    while (budget > 0) : (budget -= 1) {
        if (current == .undef or current == .poison) return current;
        if (current == .zero_initializer or current == .null_value) return .zero_initializer;
        if (current != .named) return null;
        var previous: ?ir.Value = null;
        for (self.block.instructions.items) |instruction| {
            if (instruction.removed or instruction.result == null or !std.mem.eql(u8, instruction.result.?, current.named)) continue;
            if (instruction.kind != .insertvalue) return null;
            const insert = instruction.kind.insertvalue;
            const inserted = std.fmt.parseUnsigned(usize, insert.indices, 10) catch return null;
            if (inserted == field) return insert.value;
            previous = insert.aggregate;
            break;
        }
        current = previous orelse return null;
    }
    return null;
}

fn storeAt(self: anytype, index: u32, ty: ir.Type, value: ir.Value, ptr: ir.Value, offset: u64, serial: *usize, depth: usize) model.LowerError!void {
    if (depth > 16 or serial.* > 12288) return error.UnsupportedAir;
    if (ty != .aggregate) {
        const dst = try address(self, index, ptr, offset, serial);
        try self.block.instructions.append(self.allocator, .{ .result = null, .kind = .{ .store = .{ .ty = ty, .value = value, .ptr = dst } } });
        return;
    }
    const normalized = type_layout.normalizeAggregateTypeChecked(ty) catch return error.UnsupportedAir;
    const dl = target.DataLayout.parse(self.module.target_datalayout orelse layout_text) catch return error.UnsupportedAir;
    const count = type_layout.fieldCount(normalized);
    if (count == 0 or count > type_layout.max_aggregate_layout_leaves) return error.UnsupportedAir;
    for (0..count) |field| {
        const field_ty = type_layout.fieldType(normalized, field) orelse return error.UnsupportedAir;
        const field_offset = type_layout.fieldByteOffset(dl, normalized, field) orelse return error.UnsupportedAir;
        const leaf = constructedField(self, value, field) orelse blk: {
            const name = try model.ownPrint(self.module, "air{}_snapshot_extract_{}", .{ index, serial.* });
            serial.* += 1;
            try self.block.instructions.append(self.allocator, .{ .result = name, .kind = .{ .extractvalue = .{
                .aggregate_ty = normalized,
                .aggregate = value,
                .indices = try model.ownPrint(self.module, "{d}", .{field}),
                .result_ty = field_ty,
            } } });
            break :blk ir.Value{ .named = name };
        };
        try storeAt(self, index, field_ty, leaf, ptr, std.math.add(u64, offset, field_offset) catch return error.UnsupportedAir, serial, depth + 1);
    }
}
