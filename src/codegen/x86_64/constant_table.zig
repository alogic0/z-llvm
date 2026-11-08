const std = @import("std");
const ir = @import("../../ir.zig");
const match = @import("match.zig");

pub const ReadOnlyModuleContext = struct {
    globals: []const ir.Global,
    named_types: []const ir.NamedTypeDefinition,
    target_datalayout: ?[]const u8,
    /// The caller has selected a complete module dependency closure. Retain
    /// its globals even when only another object refers to an exported root.
    emit_all_globals: bool = false,
    require_resolved_aliases: bool = false,
    functions: []const ir.Function = &.{},
    declarations: []const ir.FunctionDecl = &.{},
    aliases: []const ir.GlobalAlias = &.{},

    pub const DataAddress = struct { symbol: []const u8, global: ir.Global };

    /// Prove an alias chain reaches ordinary data while retaining the original
    /// symbol for relocation, visibility and interposition. Alias emission is
    /// owned by the complete dependency route; cycles and weak links stay closed.
    pub fn dataAddress(context: ReadOnlyModuleContext, symbol: []const u8) ?DataAddress {
        if (context.findGlobal(symbol)) |global| return .{ .symbol = global.name, .global = global };
        if (!context.require_resolved_aliases) return null;
        var current = if (std.mem.startsWith(u8, symbol, "@")) symbol[1..] else symbol;
        var original: ?[]const u8 = null;
        for (0..context.aliases.len) |_| {
            const alias = for (context.aliases) |candidate| {
                if (ir.identifiers.eql(candidate.name, current)) break candidate;
            } else return null;
            switch (alias.linkage) {
                .default, .external, .internal, .private => {},
                else => return null,
            }
            if (original == null) original = alias.name;
            current = alias.target;
            if (context.findGlobal(current)) |global| return .{ .symbol = original.?, .global = global };
        }
        return null;
    }

    /// Return a module-owned name only for an admitted function definition or
    /// declaration. Unknown and weak symbols keep their separate boundaries.
    pub fn functionAddress(context: ReadOnlyModuleContext, symbol: []const u8) ?[]const u8 {
        const name = if (std.mem.startsWith(u8, symbol, "@")) symbol[1..] else symbol;
        if (context.findGlobal(name) != null) return null;
        var found: ?[]const u8 = null;
        for (context.functions) |function| if (ir.identifiers.eql(function.name, name)) {
            if (found != null) return null;
            switch (function.linkage) {
                .default, .external, .internal, .private => {},
                else => return null,
            }
            found = function.name;
        };
        for (context.declarations) |declaration| if (ir.identifiers.eql(declaration.name, name)) {
            if (found != null) return null;
            switch (declaration.linkage) {
                .default, .external => {},
                else => return null,
            }
            found = declaration.name;
        };
        return found;
    }

    pub fn findGlobal(context: ReadOnlyModuleContext, symbol: []const u8) ?ir.Global {
        const name = if (std.mem.startsWith(u8, symbol, "@")) symbol[1..] else symbol;
        for (context.globals) |global| {
            if (std.mem.eql(u8, global.name, name)) return global;
        }
        return null;
    }

    fn findNamedType(context: ReadOnlyModuleContext, name: []const u8) ?ir.NamedTypeDefinition {
        const bare_name = if (std.mem.startsWith(u8, name, "%")) name[1..] else name;
        for (context.named_types) |named_type| {
            if (std.mem.eql(u8, named_type.name, bare_name)) return named_type;
        }
        return null;
    }
};

pub const Shape = enum {
    i16_128,
    f64_16,
    f64_512_pairs,
    f64_pair_128,

    pub fn stride(shape: Shape) u8 {
        return switch (shape) {
            .i16_128 => 2,
            .f64_16, .f64_512_pairs => 8,
            .f64_pair_128 => 16,
        };
    }

    pub fn count(shape: Shape) usize {
        return switch (shape) {
            .i16_128, .f64_pair_128 => 128,
            .f64_16 => 16,
            .f64_512_pairs => 512,
        };
    }

    pub fn alignment(shape: Shape) u32 {
        return switch (shape) {
            .i16_128 => 2,
            .f64_16, .f64_512_pairs, .f64_pair_128 => 8,
        };
    }

    pub fn allowsOffset(shape: Shape, offset: u8) bool {
        return switch (shape) {
            .i16_128, .f64_16 => offset == 0,
            .f64_512_pairs, .f64_pair_128 => offset == 0 or offset == 8,
        };
    }
};

pub const Decoded = struct {
    symbol: []const u8,
    linkage: ir.FunctionLinkage,
    shape: Shape,
    element_count: usize,
    serialized_size: usize,
    alignment: u32,
    bytes: []u8,

    pub fn deinit(decoded: *Decoded, allocator: std.mem.Allocator) void {
        allocator.free(decoded.bytes);
    }
};

pub fn decodeSymbol(
    allocator: std.mem.Allocator,
    context: ReadOnlyModuleContext,
    symbol: []const u8,
) !?Decoded {
    const global = context.findGlobal(symbol) orelse return null;
    return decodeGlobal(allocator, context, global);
}

pub fn decodeGlobal(
    allocator: std.mem.Allocator,
    context: ReadOnlyModuleContext,
    global: ir.Global,
) !?Decoded {
    if (!supportsCapturedDataLayout(context.target_datalayout)) return null;
    if (global.kind != .constant) return null;
    if (global.linkage != .internal and global.linkage != .private) return null;
    if (global.address_attrs) |attrs| {
        if (std.mem.indexOf(u8, attrs, "thread_local") != null) return null;
    }

    const classified = classify(context, global.ty) orelse return null;
    const declared_alignment = parseAlignment(global.attrs) orelse return null;
    if (declared_alignment < classified.shape.alignment() or !std.math.isPowerOfTwo(declared_alignment)) return null;

    var bytes: std.ArrayList(u8) = .empty;
    errdefer bytes.deinit(allocator);
    switch (classified.shape) {
        .i16_128 => try appendI16Array(&bytes, allocator, global.initializer, classified.shape.count()),
        .f64_16, .f64_512_pairs => try appendF64Array(&bytes, allocator, global.initializer, classified.shape.count()),
        .f64_pair_128 => try appendF64PairArray(
            &bytes,
            allocator,
            global.initializer,
            classified.element_type,
            classified.shape.count(),
        ),
    }
    const owned = try bytes.toOwnedSlice(allocator);
    return .{
        .symbol = global.name,
        .linkage = global.linkage,
        .shape = classified.shape,
        .element_count = classified.shape.count(),
        .serialized_size = owned.len,
        .alignment = declared_alignment,
        .bytes = owned,
    };
}

const Classified = struct {
    shape: Shape,
    element_type: []const u8,
};

fn classify(context: ReadOnlyModuleContext, ty: ir.Type) ?Classified {
    const text = switch (ty) {
        .aggregate => |aggregate| std.mem.trim(u8, aggregate, " \t"),
        else => return null,
    };
    if (std.mem.eql(u8, text, "[128 x i16]")) return .{ .shape = .i16_128, .element_type = "i16" };
    if (std.mem.eql(u8, text, "[16 x double]")) return .{ .shape = .f64_16, .element_type = "double" };
    if (std.mem.eql(u8, text, "[512 x double]")) return .{ .shape = .f64_512_pairs, .element_type = "double" };

    const element_type = parseExactArrayElement(text, 128) orelse return null;
    if (!std.mem.startsWith(u8, element_type, "%")) return null;
    const named_type = context.findNamedType(element_type) orelse return null;
    if (!std.mem.eql(u8, std.mem.trim(u8, named_type.body, " \t"), "{ double, double }")) return null;
    return .{ .shape = .f64_pair_128, .element_type = element_type };
}

fn parseExactArrayElement(text: []const u8, expected_count: usize) ?[]const u8 {
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const separator = std.mem.indexOf(u8, body, " x ") orelse return null;
    const count = std.fmt.parseUnsigned(usize, std.mem.trim(u8, body[0..separator], " \t"), 10) catch return null;
    if (count != expected_count) return null;
    return std.mem.trim(u8, body[separator + 3 ..], " \t");
}

fn supportsCapturedDataLayout(datalayout: ?[]const u8) bool {
    const text = datalayout orelse return false;
    return std.mem.startsWith(u8, text, "e-") and std.mem.indexOf(u8, text, "i64:64") != null;
}

fn parseAlignment(attrs: ?[]const u8) ?u32 {
    var tokens = std.mem.tokenizeAny(u8, attrs orelse return null, " \t,");
    while (tokens.next()) |token| {
        if (!std.mem.eql(u8, token, "align")) continue;
        return std.fmt.parseUnsigned(u32, tokens.next() orelse return null, 10) catch null;
    }
    return null;
}

fn appendI16Array(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    initializer: ir.GlobalInitializer,
    count: usize,
) !void {
    const array = switch (initializer) {
        .array => |array| array,
        else => return error.UnsupportedGlobalVariable,
    };
    if (!array.elem_ty.eql(.{ .int = 16 }) or array.values.items.len != count) return error.UnsupportedGlobalVariable;
    for (array.values.items) |value| {
        const int = switch (value) {
            .int => |int| int,
            else => return error.UnsupportedGlobalVariable,
        };
        if (int < std.math.minInt(i16) or int > std.math.maxInt(u16)) return error.UnsupportedGlobalVariable;
        try appendU16(bytes, allocator, @truncate(@as(u128, @bitCast(int))));
    }
}

fn appendF64Array(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    initializer: ir.GlobalInitializer,
    count: usize,
) !void {
    const text = switch (initializer) {
        .@"opaque" => |text| text,
        else => return error.UnsupportedGlobalVariable,
    };
    var cursor = ArrayCursor.init(text) orelse return error.UnsupportedGlobalVariable;
    var seen: usize = 0;
    while (cursor.next()) |item| {
        if (seen == count) return error.UnsupportedGlobalVariable;
        const literal = typedValue(item, "double") orelse return error.UnsupportedGlobalVariable;
        try appendU64(bytes, allocator, try match.fp64TextBits(.{ .fp = literal }));
        seen += 1;
    }
    if (!cursor.finished() or seen != count) return error.UnsupportedGlobalVariable;
}

fn appendF64PairArray(
    bytes: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    initializer: ir.GlobalInitializer,
    element_type: []const u8,
    count: usize,
) !void {
    const text = switch (initializer) {
        .@"opaque" => |text| text,
        else => return error.UnsupportedGlobalVariable,
    };
    var cursor = ArrayCursor.init(text) orelse return error.UnsupportedGlobalVariable;
    var seen: usize = 0;
    while (cursor.next()) |item| {
        if (seen == count) return error.UnsupportedGlobalVariable;
        const body = typedBracedValue(item, element_type) orelse return error.UnsupportedGlobalVariable;
        var fields = ArrayCursor.initWithDelimiters(body, '{', '}') orelse return error.UnsupportedGlobalVariable;
        const first = fields.next() orelse return error.UnsupportedGlobalVariable;
        const second = fields.next() orelse return error.UnsupportedGlobalVariable;
        if (fields.next() != null or !fields.finished()) return error.UnsupportedGlobalVariable;
        const first_literal = typedValue(first, "double") orelse return error.UnsupportedGlobalVariable;
        const second_literal = typedValue(second, "double") orelse return error.UnsupportedGlobalVariable;
        try appendU64(bytes, allocator, try match.fp64TextBits(.{ .fp = first_literal }));
        try appendU64(bytes, allocator, try match.fp64TextBits(.{ .fp = second_literal }));
        seen += 1;
    }
    if (!cursor.finished() or seen != count) return error.UnsupportedGlobalVariable;
}

fn typedValue(item: []const u8, expected_type: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, item, " \t");
    if (!std.mem.startsWith(u8, trimmed, expected_type)) return null;
    if (trimmed.len == expected_type.len or !std.ascii.isWhitespace(trimmed[expected_type.len])) return null;
    const value = std.mem.trim(u8, trimmed[expected_type.len..], " \t");
    return if (value.len == 0 or std.mem.indexOfAny(u8, value, " \t") != null) null else value;
}

fn typedBracedValue(item: []const u8, expected_type: []const u8) ?[]const u8 {
    const trimmed = std.mem.trim(u8, item, " \t");
    if (!std.mem.startsWith(u8, trimmed, expected_type)) return null;
    if (trimmed.len == expected_type.len or !std.ascii.isWhitespace(trimmed[expected_type.len])) return null;
    const body = std.mem.trim(u8, trimmed[expected_type.len..], " \t");
    if (body.len < 2 or body[0] != '{' or body[body.len - 1] != '}') return null;
    return body;
}

const ArrayCursor = struct {
    rest: []const u8,
    valid: bool = true,

    fn init(text: []const u8) ?ArrayCursor {
        return initWithDelimiters(text, '[', ']');
    }

    fn initWithDelimiters(text: []const u8, open: u8, close: u8) ?ArrayCursor {
        const trimmed = std.mem.trim(u8, text, " \t");
        if (trimmed.len < 2 or trimmed[0] != open or trimmed[trimmed.len - 1] != close) return null;
        return .{ .rest = std.mem.trim(u8, trimmed[1 .. trimmed.len - 1], " \t") };
    }

    fn next(cursor: *ArrayCursor) ?[]const u8 {
        if (!cursor.valid or cursor.rest.len == 0) return null;
        var square: usize = 0;
        var brace: usize = 0;
        var angle: usize = 0;
        var paren: usize = 0;
        for (cursor.rest, 0..) |byte, index| {
            switch (byte) {
                '[' => square += 1,
                ']' => {
                    if (square == 0) {
                        cursor.valid = false;
                        return null;
                    }
                    square -= 1;
                },
                '{' => brace += 1,
                '}' => {
                    if (brace == 0) {
                        cursor.valid = false;
                        return null;
                    }
                    brace -= 1;
                },
                '<' => angle += 1,
                '>' => {
                    if (angle == 0) {
                        cursor.valid = false;
                        return null;
                    }
                    angle -= 1;
                },
                '(' => paren += 1,
                ')' => {
                    if (paren == 0) {
                        cursor.valid = false;
                        return null;
                    }
                    paren -= 1;
                },
                ',' => {
                    if (square == 0 and brace == 0 and angle == 0 and paren == 0) {
                        const item = std.mem.trim(u8, cursor.rest[0..index], " \t");
                        cursor.rest = std.mem.trim(u8, cursor.rest[index + 1 ..], " \t");
                        if (item.len == 0) cursor.valid = false;
                        return if (item.len == 0) null else item;
                    }
                },
                else => {},
            }
        }
        if (square != 0 or brace != 0 or angle != 0 or paren != 0) {
            cursor.valid = false;
            return null;
        }
        const item = cursor.rest;
        cursor.rest = "";
        return item;
    }

    fn finished(cursor: ArrayCursor) bool {
        return cursor.valid and cursor.rest.len == 0;
    }
};

fn appendU16(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u16) !void {
    try bytes.appendSlice(allocator, &.{ @truncate(value), @truncate(value >> 8) });
}

fn appendU64(bytes: *std.ArrayList(u8), allocator: std.mem.Allocator, value: u64) !void {
    inline for (0..8) |index| try bytes.append(allocator, @truncate(value >> (index * 8)));
}
