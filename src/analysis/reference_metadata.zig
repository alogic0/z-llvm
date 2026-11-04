//! Metadata records remain in the module, so their typed global operands are
//! conservative module roots. Index IDs first, then parse records once: valid
//! recursive debug types need no recursive expansion. Unknown forms stay opaque.
const std = @import("std");
const Cursor = @import("reference_syntax.zig").Cursor;
const constants = @import("reference_constants.zig");
const fields = @import("reference_metadata_fields.zig");

pub const Index = struct {
    allocator: std.mem.Allocator,
    ids: std.AutoHashMapUnmanaged(u32, void) = .empty,
    names: std.StringHashMapUnmanaged(void) = .empty,
    symbols: std.ArrayList([]const u8) = .empty,
    has_unknown: bool = false,

    pub fn init(allocator: std.mem.Allocator, records: []const []const u8) !Index {
        var index: Index = .{ .allocator = allocator };
        errdefer index.deinit();
        for (records) |record| {
            const parsed = header(record) orelse {
                index.has_unknown = true;
                continue;
            };
            const duplicate = switch (parsed.key) {
                .id => |id| (try index.ids.getOrPut(allocator, id)).found_existing,
                .name => |name| (try index.names.getOrPut(allocator, name)).found_existing,
            };
            if (duplicate) index.has_unknown = true;
        }
        for (records) |record| {
            const parsed = header(record) orelse continue;
            // Unknown named metadata may have target-specific string semantics.
            if (parsed.key == .name and !constants.oneOf(parsed.key.name, &.{ "llvm.dbg.cu", "llvm.module.flags", "llvm.ident" })) index.has_unknown = true;
            var cursor = parsed.rhs;
            const distinct = cursor.keyword("distinct");
            // Definitions have a concrete node, never just an ID alias/string.
            const begin = cursor.index;
            if (!cursor.take('!') or cursor.peek() == null or std.ascii.isDigit(cursor.peek().?) or cursor.peek() == '"') {
                index.has_unknown = true;
                continue;
            }
            if (parsed.key == .name and (distinct or cursor.peek() != '{')) {
                index.has_unknown = true;
                continue;
            }
            cursor.index = begin;
            if (!try index.item(&cursor, Collector{ .index = &index }, 0, distinct) or !cursor.done()) index.has_unknown = true;
        }
        return index;
    }

    pub fn deinit(index: *Index) void {
        index.ids.deinit(index.allocator);
        index.names.deinit(index.allocator);
        index.symbols.deinit(index.allocator);
    }

    /// Validate one !kind !node attachment. ID definitions are already walked
    /// at module scope; inline typed operands are emitted to this visitor.
    pub fn attachment(index: *const Index, cursor: *Cursor, visitor: anytype) @TypeOf(visitor).Error!bool {
        if (!cursor.take('!')) return false;
        const name = cursor.identifier() orelse return false;
        if (name[0] == '"' or std.ascii.isDigit(name[0]) or cursor.peek() != '!') return false;
        if (!constants.oneOf(name, &.{ "dbg", "tbaa", "tbaa.struct", "alias.scope", "noalias", "range", "nonnull", "align", "dereferenceable", "dereferenceable_or_null", "noundef", "invariant.load", "invariant.group", "prof", "annotation", "callees", "callback", "associated", "type", "llvm.loop", "unpredictable", "nosanitize", "kcfi_type", "absolute_symbol" })) return false;
        return index.item(cursor, visitor, 0, false);
    }

    pub fn value(index: *const Index, text: []const u8, visitor: anytype) @TypeOf(visitor).Error!bool {
        var cursor: Cursor = .{ .text = text };
        return try index.item(&cursor, visitor, 0, false) and cursor.done();
    }

    fn item(index: *const Index, cursor: *Cursor, visitor: anytype, depth: usize, distinct: bool) @TypeOf(visitor).Error!bool {
        if (depth >= constants.max_depth) return false;
        if (cursor.keyword("null")) return true;
        if (!cursor.take('!')) return constants.typed(cursor, visitor, depth + 1);
        if (cursor.take('{')) {
            if (cursor.take('}')) return true;
            while (true) {
                if (!try index.item(cursor, visitor, depth + 1, false)) return false;
                if (cursor.take('}')) return true;
                if (!cursor.take(',')) return false;
            }
        }
        if (cursor.peek() == '"') return cursor.byteString() != null;
        if (cursor.peek()) |byte| {
            if (std.ascii.isDigit(byte)) {
                const id = cursor.number(u32) orelse return false;
                return index.ids.contains(id);
            }
        }
        const kind = cursor.word() orelse return false;
        if (!cursor.take('(')) return false;
        if (std.mem.eql(u8, kind, "DIExpression")) return cursor.take(')');
        if (std.mem.eql(u8, kind, "DICompileUnit") and !distinct) return false;
        const schema = fields.schema(kind) orelse return false;
        std.debug.assert(schema.len <= 64);
        var seen: u64 = 0;
        if (!cursor.take(')')) {
            while (true) {
                const name = cursor.word() orelse return false;
                const position = for (schema, 0..) |field, i| {
                    if (std.mem.eql(u8, field.name, name)) break i;
                } else return false;
                const bit = @as(u64, 1) << @as(u6, @intCast(position));
                if (seen & bit != 0 or !cursor.take(':')) return false;
                seen |= bit;
                if (!try index.fieldValue(cursor, schema[position].kind, visitor, depth + 1)) return false;
                if (cursor.take(')')) break;
                if (!cursor.take(',')) return false;
            }
        }
        for (schema, 0..) |field, i| {
            if (field.required and seen & (@as(u64, 1) << @as(u6, @intCast(i))) == 0) return false;
        }
        return true;
    }

    fn fieldValue(index: *const Index, cursor: *Cursor, kind: fields.Kind, visitor: anytype, depth: usize) @TypeOf(visitor).Error!bool {
        return switch (kind) {
            .node => index.item(cursor, visitor, depth, false),
            .non_null_node => if (cursor.keyword("null")) false else index.item(cursor, visitor, depth, false),
            .string => cursor.byteString() != null,
            .boolean => cursor.keyword("true") or cursor.keyword("false"),
            .u8 => cursor.number(u8) != null,
            .u16 => cursor.number(u16) != null,
            .u32 => cursor.number(u32) != null,
            .u64 => cursor.number(u64) != null,
            .s32 => signed(cursor, i32),
            .s64 => signed(cursor, i64),
            .integer => cursor.integer() != null,
            .uint_or_node => if (cursor.peek() != null and std.ascii.isDigit(cursor.peek().?)) cursor.number(u64) != null else index.item(cursor, visitor, depth, false),
            .sint_or_node => if (cursor.peek() != null and (std.ascii.isDigit(cursor.peek().?) or cursor.peek() == '-')) signed(cursor, i64) else index.item(cursor, visitor, depth, false),
            .flags, .sp_flags => flags(cursor, kind),
            .tag, .encoding, .language, .emission, .checksum, .name_table => enumerant(cursor, kind),
        };
    }
};

const Header = struct { key: union(enum) { id: u32, name: []const u8 }, rhs: Cursor };

fn header(text: []const u8) ?Header {
    var cursor: Cursor = .{ .text = text };
    if (!cursor.take('!')) return null;
    const key: @FieldType(Header, "key") = if (cursor.peek() != null and std.ascii.isDigit(cursor.peek().?))
        .{ .id = cursor.number(u32) orelse return null }
    else blk: {
        const name = cursor.identifier() orelse return null;
        if (name[0] == '"') return null;
        break :blk .{ .name = name };
    };
    if (!cursor.take('=')) return null;
    return .{ .key = key, .rhs = cursor };
}

const Collector = struct {
    pub const Error = std.mem.Allocator.Error;
    index: *Index,
    pub fn symbol(visitor: Collector, name: []const u8) Error!void {
        try visitor.index.symbols.append(visitor.index.allocator, name);
    }
};

fn signed(cursor: *Cursor, comptime T: type) bool {
    const token = cursor.integer() orelse return false;
    _ = std.fmt.parseInt(T, token, 10) catch return false;
    return true;
}

fn enumerant(cursor: *Cursor, kind: fields.Kind) bool {
    if (cursor.peek() != null and std.ascii.isDigit(cursor.peek().?)) return cursor.number(u32) != null;
    return constants.oneOf(cursor.word() orelse return false, fields.enumerants(kind));
}

fn flags(cursor: *Cursor, kind: fields.Kind) bool {
    while (true) {
        if (!enumerant(cursor, kind)) return false;
        if (!cursor.take('|')) return true;
    }
}
