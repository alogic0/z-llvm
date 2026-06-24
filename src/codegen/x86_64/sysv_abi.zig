const std = @import("std");
const ir = @import("../../ir.zig");
const target = @import("../../target.zig");
const memory_location = @import("../../analysis/memory_location.zig");

pub const AggregateEightbyteClass = enum {
    integer,
    sse,
};

pub const AggregateKind = enum {
    register,
    memory,
};

pub const AggregateClassification = struct {
    kind: AggregateKind,
    eightbytes: [2]?AggregateEightbyteClass = .{ null, null },
    eightbyte_count: u2 = 0,
    size_bytes: u64 = 0,

    pub fn isIntegerOnly(classification: AggregateClassification) bool {
        if (classification.kind != .register or classification.eightbyte_count == 0) return false;
        var index: usize = 0;
        while (index < classification.eightbyte_count) : (index += 1) {
            if (classification.eightbytes[index] != .integer) return false;
        }
        return true;
    }

    pub fn isSseOnly(classification: AggregateClassification) bool {
        if (classification.kind != .register or classification.eightbyte_count == 0) return false;
        var index: usize = 0;
        while (index < classification.eightbyte_count) : (index += 1) {
            if (classification.eightbytes[index] != .sse) return false;
        }
        return true;
    }
};

pub fn dataLayout() !target.DataLayout {
    return target.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128");
}

pub fn classifyAggregateForTest(ty: ir.Type) !AggregateClassification {
    return try classifyAggregate(ty);
}

pub fn classifyAggregate(ty: ir.Type) !AggregateClassification {
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) return .{ .kind = .memory };
        },
        else => {},
    }
    const layout = try dataLayout();
    const size = try layout.typeStoreSizeBytes(ty);
    if (size == 0 or size > 16) return .{ .kind = .memory, .size_bytes = size };

    const classification = try classifyAggregateSized(layout, ty, size);
    return if (classification.kind == .register and classification.eightbyte_count == 0)
        .{ .kind = .memory, .size_bytes = size }
    else
        classification;
}

fn classifyAggregateSized(layout: target.DataLayout, ty: ir.Type, size: u64) !AggregateClassification {
    var classification = AggregateClassification{
        .kind = .register,
        .eightbyte_count = @intCast((size + 7) / 8),
        .size_bytes = size,
    };
    try classifyAggregateInto(layout, ty, 0, &classification);
    return classification;
}

fn classifyAggregateInto(
    layout: target.DataLayout,
    ty: ir.Type,
    base_offset: u64,
    classification: *AggregateClassification,
) !void {
    if (classification.kind == .memory) return;
    switch (ty) {
        .aggregate => |text| {
            const trimmed = std.mem.trim(u8, text, " \t");
            if (std.mem.startsWith(u8, trimmed, "<{")) {
                classification.kind = .memory;
                return;
            }
            var field_index: usize = 0;
            var saw_field = false;
            while (memory_location.aggregateFieldType(ty, field_index)) |field_ty| : (field_index += 1) {
                saw_field = true;
                const field_offset_i = memory_location.aggregateFieldOffsetWithLayout(layout, ty, field_index) orelse {
                    classification.kind = .memory;
                    return;
                };
                if (field_offset_i < 0) {
                    classification.kind = .memory;
                    return;
                }
                const field_offset: u64 = @intCast(field_offset_i);
                const field_size = try layout.typeStoreSizeBytes(field_ty);
                const field_align_bytes = bitsToBytes(try layout.typeAbiAlignmentBits(field_ty));
                if (field_align_bytes != 0 and field_offset % field_align_bytes != 0) {
                    classification.kind = .memory;
                    return;
                }
                try classifyAggregateInto(layout, field_ty, base_offset + field_offset, classification);
                if (base_offset + field_offset + field_size > 16) {
                    classification.kind = .memory;
                    return;
                }
            }
            if (!saw_field) classification.kind = .memory;
        },
        .int, .ptr => {
            const size = try layout.typeStoreSizeBytes(ty);
            try mergeAggregateClass(classification, base_offset, size, .integer);
        },
        .float, .double, .vector => {
            const size = scalarOrVectorSizeBytes(ty) orelse {
                classification.kind = .memory;
                return;
            };
            if (size > 16) {
                classification.kind = .memory;
                return;
            }
            try mergeAggregateClass(classification, base_offset, size, .sse);
        },
        .x86_fp80, .fp128, .void, .metadata => classification.kind = .memory,
    }
}

fn mergeAggregateClass(
    classification: *AggregateClassification,
    offset: u64,
    size: u64,
    class: AggregateEightbyteClass,
) !void {
    if (size == 0) return;
    if (offset + size > 16) {
        classification.kind = .memory;
        return;
    }
    const first = offset / 8;
    const last = (offset + size - 1) / 8;
    var index = first;
    while (index <= last) : (index += 1) {
        if (index >= classification.eightbytes.len) {
            classification.kind = .memory;
            return;
        }
        const slot = &classification.eightbytes[@intCast(index)];
        slot.* = mergeEightbyte(slot.*, class);
    }
}

fn mergeEightbyte(existing: ?AggregateEightbyteClass, incoming: AggregateEightbyteClass) AggregateEightbyteClass {
    const current = existing orelse return incoming;
    if (current == .integer or incoming == .integer) return .integer;
    return .sse;
}

fn scalarOrVectorSizeBytes(ty: ir.Type) ?u64 {
    return switch (ty) {
        .float => 4,
        .double => 8,
        .vector => |vector| vector.len * (switch (vector.elem_ty) {
            .int => |bits| if (bits % 8 == 0) bits / 8 else return null,
            .float => 4,
            .double => 8,
            .ptr => 8,
        }),
        .void, .int, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => null,
    };
}

fn bitsToBytes(bits: u16) u64 {
    return (@as(u64, bits) + 7) / 8;
}

pub const SmallIntegerAggregate = struct {
    eightbytes: u2,
    size_bytes: u8,
};

pub fn classifySmallIntegerAggregate(ty: ir.Type) ?SmallIntegerAggregate {
    const classification = classifyAggregate(ty) catch return null;
    if (!classification.isIntegerOnly()) return null;
    if (classification.size_bytes > std.math.maxInt(u8)) return null;
    return .{ .eightbytes = classification.eightbyte_count, .size_bytes = @intCast(classification.size_bytes) };
}
