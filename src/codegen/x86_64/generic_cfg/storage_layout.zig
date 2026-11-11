//! Exact bounded storage layout for scalar aggregates. Named types
//! come only from the current module; unresolved or cyclic shapes fail closed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const parser = @import("../../../ir/parser_types_values.zig");
const syntax = @import("../../../ir/parser_syntax.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");
const Fields = @import("../../../ir/structure.zig").Fields;

pub const Layout = struct { bytes: u32, alignment: u32 };
// Larger source objects still enter the existing large-frame address authority,
// which checks their complete extent against the allocated frame. Its separate
// legacy small-object threshold must not grow along with this layout envelope.
pub const max_bytes: u32 = 4 * 1024 * 1024;

/// Exact field displacement, with the same complete-layout admission as frame
/// storage and pointer strides. Resolve names only from the current module.
pub fn fieldOffset(context: ?*const machine.ReadOnlyModuleContext, source: ir.Type, index: usize) ?u32 {
    return (fieldInfo(context, source, index) orelse return null).offset;
}

pub const Field = struct { ty: ir.Type, offset: u32 };

pub fn fieldInfo(context: ?*const machine.ReadOnlyModuleContext, source: ir.Type, index: usize) ?Field {
    _ = query(context, source) orelse return null;
    var ty = source;
    var depth: usize = 0;
    while (depth < 32) : (depth += 1) {
        if (ty != .aggregate) return null;
        const text = trim(ty.aggregate);
        if (text.len == 0) return null;
        if (text[0] == '%') {
            const ctx = context orelse return null;
            var resolved: ?[]const u8 = null;
            for (ctx.named_types) |named| if (ir.identifiers.eql(named.name, text[1..])) {
                if (resolved != null) return null;
                resolved = named.body;
            };
            ty = parse(resolved orelse return null) orelse return null;
            continue;
        }
        var fields = Fields.init(text) orelse return null;
        var offset: u32 = 0;
        var field_index: usize = 0;
        while (fields.next()) |field_text| : (field_index += 1) {
            const child_ty = parse(field_text) orelse return null;
            const child = query(context, child_ty) orelse return null;
            if (!fields.packed_type) offset = std.mem.alignForward(u32, offset, child.alignment);
            if (field_index == index) return .{ .ty = child_ty, .offset = offset };
            offset = std.math.add(u32, offset, child.bytes) catch return null;
        }
        return null;
    }
    return null;
}

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t\r\n");
}

fn parse(text: []const u8) ?ir.Type {
    return parser.parseType(trim(text)) catch null;
}

pub fn query(context: ?*const machine.ReadOnlyModuleContext, ty: ir.Type) ?Layout {
    if (!pairs.supportsLayout(context)) return null;
    const text = if (context) |ctx| ctx.target_datalayout orelse "" else "";
    const dl = target.DataLayout.parse(text) catch return null;
    var aggregate_alignment: u32 = 1;
    var parts = std.mem.splitScalar(u8, text, '-');
    while (parts.next()) |part| {
        if (std.mem.startsWith(u8, part, "a:")) {
            const end = std.mem.indexOfScalarPos(u8, part, 2, ':') orelse part.len;
            const bits = std.fmt.parseUnsigned(u32, part[2..end], 10) catch return null;
            if (bits != 0 and (bits < 8 or bits > 128 or !std.math.isPowerOfTwo(bits))) return null;
            aggregate_alignment = @max(1, bits / 8);
        }
        // DataLayout's floating queries use the native x86 allocation widths.
        // Do not admit an explicit override that those queries cannot describe.
        if (part.len != 0 and part[0] == 'f') {
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
    }
    return queryDepth(context, dl, aggregate_alignment, ty, 0);
}

fn queryDepth(context: ?*const machine.ReadOnlyModuleContext, dl: target.DataLayout, aggregate_alignment: u32, ty: ir.Type, depth: u8) ?Layout {
    if (depth >= 32) return null;
    if (ty == .vector) {
        const vector = ty.vector;
        const bits: u32 = switch (vector.elem_ty) {
            .int => |width| width,
            .half => 16,
            .float => 32,
            .double => 64,
            else => return null,
        };
        if (bits == 0 or bits > 64 or vector.len == 0 or vector.len > 16 or vector.len * bits > 128) return null;
        if (context) |ctx| if (ctx.target_datalayout) |text| {
            var parts = std.mem.splitScalar(u8, text, '-');
            while (parts.next()) |part| if (part.len != 0 and part[0] == 'v') return null;
        };
        const bytes = std.math.ceilPowerOfTwo(u32, (vector.len * bits + 7) / 8) catch return null;
        return .{ .bytes = bytes, .alignment = bytes };
    }
    if (ty == .ptr or ty == .int or ty == .half or ty == .float or ty == .double or ty == .x86_fp80 or ty == .fp128) {
        if (ty == .int and (ty.int == 0 or ty.int > 128)) return null;
        const bytes = dl.typeAllocSizeBytes(ty) catch return null;
        const bits = dl.typeAbiAlignmentBits(ty) catch return null;
        if (bytes > max_bytes or bits < 8 or bits > 128 or !std.math.isPowerOfTwo(bits)) return null;
        return .{ .bytes = @intCast(bytes), .alignment = bits / 8 };
    }
    if (ty != .aggregate) return null;
    const text = trim(ty.aggregate);
    if (text.len == 0 or (syntax.findTopLevelTokenEnd(text) orelse return null) != text.len) return null;
    if (text[0] == '%') {
        const ctx = context orelse return null;
        var body: ?[]const u8 = null;
        for (ctx.named_types) |named| if (ir.identifiers.eql(named.name, text[1..])) {
            if (body != null) return null;
            body = named.body;
        };
        return queryDepth(context, dl, aggregate_alignment, parse(body orelse return null) orelse return null, depth + 1);
    }
    if (text[0] == '[' and text[text.len - 1] == ']') {
        const inside = trim(text[1 .. text.len - 1]);
        var tokens = std.mem.tokenizeAny(u8, inside, " \t\r\n");
        const count = std.fmt.parseUnsigned(u32, tokens.next() orelse return null, 10) catch return null;
        if (!std.mem.eql(u8, tokens.next() orelse return null, "x")) return null;
        const element = parse(tokens.rest()) orelse return null;
        const child = queryDepth(context, dl, aggregate_alignment, element, depth + 1) orelse return null;
        const bytes = std.math.mul(u32, child.bytes, count) catch return null;
        if (bytes > max_bytes) return null;
        return .{ .bytes = bytes, .alignment = child.alignment };
    }
    var fields = Fields.init(text) orelse return null;
    var bytes: u32 = 0;
    var alignment: u32 = if (fields.packed_type) 1 else aggregate_alignment;
    while (fields.next()) |field| {
        const child = queryDepth(context, dl, aggregate_alignment, parse(field) orelse return null, depth + 1) orelse return null;
        if (!fields.packed_type) {
            alignment = @max(alignment, child.alignment);
            bytes = std.mem.alignForward(u32, bytes, child.alignment);
        }
        bytes = std.math.add(u32, bytes, child.bytes) catch return null;
        if (bytes > max_bytes) return null;
    }
    bytes = std.mem.alignForward(u32, bytes, alignment);
    if (bytes > max_bytes) return null;
    return .{ .bytes = bytes, .alignment = alignment };
}
