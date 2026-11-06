//! Exact bounded storage layout for scalar aggregates. Named types
//! come only from the current module; unresolved or cyclic shapes fail closed.
const std = @import("std");
const ir = @import("../../../ir.zig");
const parser = @import("../../../ir/parser_types_values.zig");
const syntax = @import("../../../ir/parser_syntax.zig");
const target = @import("../../../target.zig");
const machine = @import("../machine.zig");
const pairs = @import("word_pair_memory.zig");

pub const Layout = struct { bytes: u32, alignment: u32 };
pub const max_bytes: u32 = @import("selector_types.zig").max_stack_object_bytes;

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t\r\n");
}

fn parse(text: []const u8) ?ir.Type {
    const body = trim(text);
    if (std.mem.startsWith(u8, body, "<{")) return .{ .aggregate = body };
    return parser.parseType(body) catch null;
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
    const packed_type = std.mem.startsWith(u8, text, "<{") and std.mem.endsWith(u8, text, "}>");
    if (!packed_type and !(text[0] == '{' and text[text.len - 1] == '}')) return null;
    const edge: usize = if (packed_type) 2 else 1;
    var rest = trim(text[edge .. text.len - edge]);
    var bytes: u32 = 0;
    var alignment: u32 = if (packed_type) 1 else aggregate_alignment;
    while (rest.len != 0) {
        const comma = syntax.findTopLevelComma(rest);
        const field = trim(if (comma) |index| rest[0..index] else rest);
        const child = queryDepth(context, dl, aggregate_alignment, parse(field) orelse return null, depth + 1) orelse return null;
        if (!packed_type) {
            alignment = @max(alignment, child.alignment);
            bytes = std.mem.alignForward(u32, bytes, child.alignment);
        }
        bytes = std.math.add(u32, bytes, child.bytes) catch return null;
        if (bytes > max_bytes) return null;
        rest = if (comma) |index| trim(rest[index + 1 ..]) else "";
        if (comma != null and rest.len == 0) return null;
    }
    bytes = std.mem.alignForward(u32, bytes, alignment);
    if (bytes > max_bytes) return null;
    return .{ .bytes = bytes, .alignment = alignment };
}
