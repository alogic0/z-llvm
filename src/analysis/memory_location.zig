const std = @import("std");
const ir = @import("../ir.zig");

pub const MemoryLocation = struct {
    ptr: ir.Value,
    root: []const u8,
    offset: ?i128,
    size: ?u64,

    pub fn rangeEnd(location: MemoryLocation) ?i128 {
        const offset = location.offset orelse return null;
        const size = location.size orelse return null;
        return offset + @as(i128, @intCast(size));
    }
};

pub fn forPointer(function: ir.Function, ptr: ir.Value) ?MemoryLocation {
    return build(function, ptr, null);
}

pub fn forAccess(function: ir.Function, ptr: ir.Value, access_ty: ir.Type) ?MemoryLocation {
    return build(function, ptr, typeSize(access_ty));
}

fn build(function: ir.Function, ptr: ir.Value, access_size: ?u64) ?MemoryLocation {
    const name = switch (ptr) {
        .int, .undef => return null,
        .named => |name| name,
    };

    for (function.blocks.items) |block| {
        for (block.instructions.items) |instruction| {
            if (instruction.removed) continue;
            const result = instruction.result orelse continue;
            if (!std.mem.eql(u8, result, name)) continue;

            switch (instruction.kind) {
                .alloca => |alloca| return .{
                    .ptr = ptr,
                    .root = result,
                    .offset = 0,
                    .size = access_size orelse typeSize(alloca.allocated_ty),
                },
                .gep => |gep| {
                    var base = build(function, gep.ptr, null) orelse return null;
                    base.ptr = ptr;
                    base.offset = addOffsets(base.offset, gepOffset(gep));
                    base.size = access_size orelse typeSize(gep.source_ty);
                    return base;
                },
                .binary, .cast, .freeze, .icmp, .select, .phi, .load, .store => return null,
            }
        }
    }
    return null;
}

fn addOffsets(a: ?i128, b: ?i128) ?i128 {
    return (a orelse return null) + (b orelse return null);
}

fn gepOffset(gep: ir.GepInst) ?i128 {
    const element_size = typeSize(gep.source_ty) orelse return null;
    var offset: i128 = 0;
    for (gep.indices.items) |index| {
        const value = switch (index.value) {
            .int => |value| value,
            .named, .undef => return null,
        };
        offset += value * @as(i128, @intCast(element_size));
    }
    return offset;
}

fn typeSize(ty: ir.Type) ?u64 {
    return switch (ty) {
        .int => |bits| if (bits % 8 == 0) bits / 8 else null,
        .ptr => null,
    };
}
