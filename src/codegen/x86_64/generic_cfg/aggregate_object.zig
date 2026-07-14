const std = @import("std");
const ir = @import("../../../ir.zig");
const x86_64_types = @import("../types.zig");

pub const byte_size: u8 = 8;
pub const alignment: u8 = 4;

pub const PointerView = struct {
    offset: u8,

    pub fn allows(view: PointerView, access_size: u8) bool {
        return view.offset <= byte_size and access_size <= byte_size - view.offset;
    }
};

pub fn isF32PairType(context: ?*const x86_64_types.ReadOnlyModuleContext, ty: ir.Type) bool {
    if (ty != .aggregate) return false;
    const body = resolveBody(context, ty.aggregate) orelse return false;
    return compactEql(body, "{float,float}");
}

pub fn pointerView(
    function: ir.Function,
    context: ?*const x86_64_types.ReadOnlyModuleContext,
    value: ir.Value,
) ?PointerView {
    return pointerViewDepth(function, context, value, 0);
}

fn pointerViewDepth(
    function: ir.Function,
    context: ?*const x86_64_types.ReadOnlyModuleContext,
    value: ir.Value,
    depth: u8,
) ?PointerView {
    if (depth >= 8 or value != .named) return null;
    const instruction = findInstruction(function, value.named) orelse return null;
    return switch (instruction.kind) {
        .alloca => |alloca| if (alloca.allocated_ty_addrspace == null and isF32PairType(context, alloca.allocated_ty))
            .{ .offset = 0 }
        else
            null,
        .gep => |gep| blk: {
            if (gep.ptr_addrspace != null or !isByteSource(gep.source_ty) or gep.indices.items.len != 1) break :blk null;
            const index = gep.indices.items[0];
            if (!index.ty.eql(.{ .int = 64 }) or index.value != .int) break :blk null;
            const offset = std.math.cast(u8, index.value.int) orelse break :blk null;
            const base = pointerViewDepth(function, context, gep.ptr, depth + 1) orelse break :blk null;
            const total = std.math.add(u8, base.offset, offset) catch break :blk null;
            if (total > byte_size) break :blk null;
            break :blk .{ .offset = total };
        },
        .phi => |phi| blk: {
            if (phi.ty != .ptr or phi.incoming.items.len == 0) break :blk null;
            var result: ?PointerView = null;
            for (phi.incoming.items) |incoming| {
                const incoming_view = pointerViewDepth(function, context, incoming.value, depth + 1) orelse break :blk null;
                if (result) |known| {
                    if (known.offset != incoming_view.offset) break :blk null;
                } else result = incoming_view;
            }
            break :blk result;
        },
        else => null,
    };
}

fn resolveBody(context: ?*const x86_64_types.ReadOnlyModuleContext, text: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, text, " \t");
    if (!std.mem.startsWith(u8, trimmed, "%")) return trimmed;
    const module_context = context orelse return null;
    const name = trimmed[1..];
    for (module_context.named_types) |named_type| {
        if (std.mem.eql(u8, named_type.name, name)) return named_type.body;
    }
    return null;
}

fn compactEql(text: []const u8, expected: []const u8) bool {
    var expected_index: usize = 0;
    for (text) |byte| {
        if (std.ascii.isWhitespace(byte)) continue;
        if (expected_index >= expected.len or byte != expected[expected_index]) return false;
        expected_index += 1;
    }
    return expected_index == expected.len;
}

fn isByteSource(ty: ir.Type) bool {
    if (ty.eql(.{ .int = 8 })) return true;
    return ty == .aggregate and compactEql(ty.aggregate, "[1xi8]");
}

fn findInstruction(function: ir.Function, name: []const u8) ?ir.Instruction {
    for (function.blocks.items) |block| for (block.instructions.items) |instruction| {
        if (instruction.result) |result| if (std.mem.eql(u8, result, name)) return instruction;
    };
    return null;
}
