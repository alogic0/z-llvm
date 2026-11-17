//! Backend admission for exact module-aware memory geometry. Knowing storage
//! layout does not establish a register ABI or admit another lowering family.
const std = @import("std");
const ir = @import("../../../ir.zig");
const geometry = @import("../../../target/module_layout.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");

pub const Layout = struct { bytes: u32, alignment: u32 };
// Keep the separate legacy small-object/frame threshold unchanged.
pub const max_bytes: u32 = 4 * 1024 * 1024;
const native_x86_64_layout = "e-p:64:64-i64:64-i128:128-f80:128";

pub const Field = struct { ty: ir.Type, offset: u32 };

pub fn fieldOffset(context: ?*const machine.ReadOnlyModuleContext, source: ir.Type, index: usize) ?u32 {
    return (fieldInfo(context, source, index) orelse return null).offset;
}

pub fn fieldInfo(context: ?*const machine.ReadOnlyModuleContext, source: ir.Type, index: usize) ?Field {
    const field = (queryContext(context) orelse return null).field(source, index) orelse return null;
    return .{ .ty = field.ty, .offset = @intCast(field.offset) };
}

pub fn query(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type) ?Layout {
    const facts = (queryContext(context) orelse return null).query(ty) orelse return null;
    return .{ .bytes = @intCast(facts.allocation_bytes), .alignment = @intCast(facts.abi_alignment) };
}

fn queryContext(context: ?*const machine.ReadOnlyModuleContext) ?geometry.Query {
    if (!pairs.supportsLayout(context)) return null;
    const text = if (context) |ctx| ctx.target_datalayout orelse native_x86_64_layout else native_x86_64_layout;
    // Preserve this owner's native floating support envelope, including global
    // rejection of overrides it cannot execute. The shared query is broader.
    var parts = std.mem.splitScalar(u8, text, '-');
    while (parts.next()) |part| {
        if (part.len == 0 or part[0] != 'f') continue;
        var fields = std.mem.splitScalar(u8, part[1..], ':');
        const width = std.fmt.parseUnsigned(u16, fields.next() orelse return null, 10) catch return null;
        const expected: u16 = switch (width) {
            16, 32, 64 => width,
            80, 128 => 128,
            else => return null,
        };
        const bits = std.fmt.parseUnsigned(u16, fields.next() orelse return null, 10) catch return null;
        if (bits != expected) return null;
        if (fields.next()) |field| {
            const preferred = std.fmt.parseUnsigned(u16, field, 10) catch return null;
            if (preferred < bits or !std.math.isPowerOfTwo(preferred)) return null;
        }
        if (fields.next() != null) return null;
    }
    return geometry.Query.init(text, if (context) |ctx| ctx.named_types else &.{}, .{
        .identifier_equality = .decoded,
        .max_extent = max_bytes,
        .max_array_count = std.math.maxInt(u32),
        .admit = admitsNode,
    });
}

fn admitsNode(text: []const u8, ty: ir.Type, facts: geometry.Facts) bool {
    return switch (ty) {
        .int => |bits| bits > 0 and bits <= 128 and facts.abi_alignment <= 16,
        .ptr, .half, .float, .double, .x86_fp80, .fp128 => facts.abi_alignment <= 16,
        .aggregate => true,
        .vector => |vector| blk: {
            const bits: u32 = switch (vector.elem_ty) {
                .int => |width| width,
                .half => 16,
                .float => 32,
                .double => 64,
                else => break :blk false,
            };
            if (bits == 0 or bits > 64 or vector.len == 0 or vector.len > 64) break :blk false;
            var parts = std.mem.splitScalar(u8, text, '-');
            while (parts.next()) |part| if (part.len != 0 and part[0] == 'v') break :blk false;
            break :blk true;
        },
        .void, .metadata => false,
    };
}
