const std = @import("std");
const ir = @import("../../ir.zig");
const match = @import("match.zig");
const target = @import("../../target.zig");
const addresses = @import("symbol_address.zig");

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
        // Most references retain their definition's spelling. Keep that lookup
        // cheap before comparing alternate quoted/escaped spellings.
        for (context.globals) |global| {
            if (std.mem.eql(u8, global.name, name)) return if (ir.identifiers.isValid(name)) global else null;
        }
        for (context.globals) |global| {
            if (ir.identifiers.eql(global.name, name)) return global;
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

/// Facts for the admitted x86-64 read-only data layouts. Allowed index bits are
/// a bit envelope, including parity for paired scalar accesses, not a range.
pub const Description = struct {
    pub const Element = enum { i16, f64, f64_pair };
    element: Element,
    element_count: usize,
    stride_bytes: u8,
    alignment_bytes: u32,
    serialized_extent: usize,
    access_widths: u16,
    allowed_index_bits: u64,
    paired_scalar_indices: bool,

    // Compatibility constants for existing callers. The integer family also
    // admits other power-of-two lengths through the same description.
    pub const max_i16_elements: usize = 65536;
    pub const i16_128 = init(.i16, 128, false).?;
    pub const f64_16 = init(.f64, 16, false).?;
    pub const f64_512_pairs = init(.f64, 512, true).?;
    pub const f64_pair_128 = init(.f64_pair, 128, false).?;

    pub fn init(element: Element, elements: usize, paired: bool) ?Description {
        if (elements == 0 or !std.math.isPowerOfTwo(elements)) return null;
        const step: u8 = switch (element) {
            .i16 => 2,
            .f64 => 8,
            .f64_pair => 16,
        };
        const extent = std.math.mul(usize, elements, step) catch return null;
        // Keep every derived displacement and serialized object span within
        // the existing signed x86 displacement envelope.
        if (extent > std.math.maxInt(i32)) return null;
        if (paired) {
            if (element != .f64 or elements != 512) return null;
        } else switch (element) {
            .i16 => if (elements < 2 or elements > max_i16_elements) return null,
            .f64_pair => if (elements != 128) return null,
            .f64 => if (elements != 16) return null,
        }
        const width: u8 = if (element == .i16) 2 else 8;
        return .{
            .element = element,
            .element_count = elements,
            .stride_bytes = step,
            .alignment_bytes = width,
            .serialized_extent = extent,
            .access_widths = @as(u16, 1) << @as(u4, @intCast(width)),
            .allowed_index_bits = @intCast(elements - @as(usize, if (paired) 2 else 1)),
            .paired_scalar_indices = paired,
        };
    }

    pub fn eql(description: Description, other: Description) bool {
        return std.meta.eql(description, other);
    }

    /// Internal intents/snapshots may carry descriptions by value. A forged
    /// derived field never grants additional access or address capability.
    pub fn valid(description: Description) bool {
        const canonical = init(description.element, description.element_count, description.paired_scalar_indices) orelse return false;
        return description.eql(canonical);
    }

    pub fn stride(description: Description) u8 {
        return description.stride_bytes;
    }
    pub fn count(description: Description) usize {
        return description.element_count;
    }
    pub fn alignment(description: Description) u32 {
        return description.alignment_bytes;
    }

    pub fn allowsOffset(description: Description, offset: u8) bool {
        return description.valid() and (offset == 0 or
            (offset == 8 and (description.paired_scalar_indices or description.element == .f64_pair)));
    }

    /// Check the final byte of every admitted index, not just a table tag.
    pub fn allowsAccess(description: Description, offset: u8, width: u8) bool {
        if (!description.allowsOffset(offset) or width >= 16 or
            description.access_widths & (@as(u16, 1) << @as(u4, @intCast(width))) == 0) return false;
        const base = std.math.mul(u64, description.allowed_index_bits, description.stride_bytes) catch return false;
        const field = std.math.add(u64, base, offset) catch return false;
        const end = std.math.add(u64, field, width) catch return false;
        return end <= description.serialized_extent and end <= std.math.maxInt(i32);
    }
};

pub fn sourceStrideMatches(datalayout: ?[]const u8, source_ty: ir.Type, shape: Description) bool {
    if (!shape.valid()) return false;
    const expected = switch (shape.stride()) {
        2 => "[2 x i8]",
        8 => "[8 x i8]",
        16 => "[16 x i8]",
        else => return false,
    };
    if (source_ty != .aggregate or !std.mem.eql(u8, std.mem.trim(u8, source_ty.aggregate, " \t"), expected)) return false;
    const text = datalayout orelse return false;
    if (!addresses.supportsLayout(text) or !nativeAlignmentOverrides(text, "i8:", 8)) return false;
    const layout = target.DataLayout.parse(text) catch return false;
    return (layout.typeAllocSizeBytes(source_ty) catch return false) == shape.stride();
}

pub const Decoded = struct {
    symbol: []const u8,
    linkage: ir.FunctionLinkage,
    shape: Description,
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
    if (!serializedLayoutMatches(context.target_datalayout, global.ty, classified.shape)) return null;
    const declared_alignment = parseAlignment(global.attrs) orelse return null;
    if (declared_alignment < classified.shape.alignment() or !std.math.isPowerOfTwo(declared_alignment)) return null;

    // Newly considered integer counts are an optional specialization of the
    // existing global emitter. Do not claim unsupported payloads and turn a
    // previously harmless unused global into an object-emission failure.
    // The original four layouts keep their closed codec/error boundaries.
    if (classified.shape.element == .i16 and !classified.shape.eql(Description.i16_128) and
        !hasLiteralI16Payload(global.initializer, classified.shape.count())) return null;

    var bytes: std.ArrayList(u8) = .empty;
    errdefer bytes.deinit(allocator);
    switch (classified.shape.element) {
        .i16 => try appendI16Array(&bytes, allocator, global.initializer, classified.shape.count()),
        .f64 => try appendF64Array(&bytes, allocator, global.initializer, classified.shape.count()),
        .f64_pair => try appendF64PairArray(
            &bytes,
            allocator,
            global.initializer,
            classified.element_type,
            classified.shape.count(),
        ),
    }
    if (bytes.items.len != classified.shape.serialized_extent) return error.TableExtentMismatch;
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
    shape: Description,
    element_type: []const u8,
};

fn classify(context: ReadOnlyModuleContext, ty: ir.Type) ?Classified {
    const text = switch (ty) {
        .aggregate => |aggregate| std.mem.trim(u8, aggregate, " \t"),
        else => return null,
    };
    if (std.mem.eql(u8, text, "[16 x double]")) return .{ .shape = Description.f64_16, .element_type = "double" };
    if (std.mem.eql(u8, text, "[512 x double]")) return .{ .shape = Description.f64_512_pairs, .element_type = "double" };

    const array = parseArray(text) orelse return null;
    const element_type = array.element;
    if (std.mem.eql(u8, element_type, "i16")) return .{
        .shape = Description.init(.i16, array.count, false) orelse return null,
        .element_type = element_type,
    };
    if (array.count != 128) return null;
    if (!std.mem.startsWith(u8, element_type, "%")) return null;
    const named_type = context.findNamedType(element_type) orelse return null;
    if (!std.mem.eql(u8, std.mem.trim(u8, named_type.body, " \t"), "{ double, double }")) return null;
    return .{ .shape = Description.f64_pair_128, .element_type = element_type };
}

const Array = struct { count: usize, element: []const u8 };

fn parseArray(text: []const u8) ?Array {
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return null;
    const body = std.mem.trim(u8, text[1 .. text.len - 1], " \t");
    const separator = std.mem.indexOf(u8, body, " x ") orelse return null;
    const count = std.fmt.parseUnsigned(usize, std.mem.trim(u8, body[0..separator], " \t"), 10) catch return null;
    return .{ .count = count, .element = std.mem.trim(u8, body[separator + 3 ..], " \t") };
}

fn supportsCapturedDataLayout(datalayout: ?[]const u8) bool {
    const text = datalayout orelse return false;
    return std.mem.startsWith(u8, text, "e-") and std.mem.indexOf(u8, text, "i64:64") != null and
        addresses.supportsLayout(text) and nativeAlignmentOverrides(text, "i64:", 64);
}

fn nativeAlignmentOverrides(text: []const u8, prefix: []const u8, expected: u16) bool {
    var parts = std.mem.splitScalar(u8, text, '-');
    while (parts.next()) |part| {
        if (!std.mem.startsWith(u8, part, prefix)) continue;
        var fields = std.mem.splitScalar(u8, part[prefix.len..], ':');
        const abi = std.fmt.parseUnsigned(u16, fields.next() orelse return false, 10) catch return false;
        if (abi != expected) return false;
        if (fields.next()) |value| {
            const preferred = std.fmt.parseUnsigned(u16, value, 10) catch return false;
            if (preferred < abi or !std.math.isPowerOfTwo(preferred)) return false;
        }
        if (fields.next() != null) return false;
    }
    return true;
}

fn serializedLayoutMatches(datalayout: ?[]const u8, ty: ir.Type, shape: Description) bool {
    const text = datalayout orelse return false;
    const layout = target.DataLayout.parse(text) catch return false;
    const element: ir.Type = switch (shape.element) {
        .i16 => .{ .int = 16 },
        .f64 => .double,
        .f64_pair => .{ .aggregate = "{ double, double }" },
    };
    if (!nativeAlignmentOverrides(text, if (shape.element == .i16) "i16:" else "f64:", if (shape.element == .i16) 16 else 64)) return false;
    if (shape.element == .f64_pair) {
        // The shared layout query uses natural struct alignment. An explicit
        // aggregate floor up to 16 bytes still leaves this exact pair's two
        // field offsets and 16-byte allocation unchanged; larger floors do not.
        var parts = std.mem.splitScalar(u8, text, '-');
        while (parts.next()) |part| {
            if (!std.mem.startsWith(u8, part, "a:")) continue;
            var fields = std.mem.splitScalar(u8, part[2..], ':');
            const abi = std.fmt.parseUnsigned(u16, fields.next() orelse return false, 10) catch return false;
            if (abi != 0 and (abi < 8 or abi > 128 or !std.math.isPowerOfTwo(abi))) return false;
            if (fields.next()) |value| {
                const preferred = std.fmt.parseUnsigned(u16, value, 10) catch return false;
                if (preferred != 0 and (preferred < abi or !std.math.isPowerOfTwo(preferred))) return false;
            }
            if (fields.next() != null) return false;
        }
    }
    if ((layout.typeAllocSizeBytes(element) catch return false) != shape.stride()) return false;
    // classify resolved the sole named-pair spelling to this exact body. Use
    // that body for the shared query, which does not resolve module type names.
    const storage_ty: ir.Type = if (shape.element == .f64_pair)
        .{ .aggregate = "[128 x { double, double }]" }
    else
        ty;
    return (layout.typeAllocSizeBytes(storage_ty) catch return false) == shape.serialized_extent;
}

fn parseAlignment(attrs: ?[]const u8) ?u32 {
    var tokens = std.mem.tokenizeAny(u8, attrs orelse return null, " \t,");
    while (tokens.next()) |token| {
        if (!std.mem.eql(u8, token, "align")) continue;
        return std.fmt.parseUnsigned(u32, tokens.next() orelse return null, 10) catch null;
    }
    return null;
}

fn hasLiteralI16Payload(initializer: ir.GlobalInitializer, count: usize) bool {
    const array = switch (initializer) {
        .array => |array| array,
        else => return false,
    };
    if (!array.elem_ty.eql(.{ .int = 16 }) or array.values.items.len != count) return false;
    for (array.values.items) |value| {
        if (value != .int or value.int < std.math.minInt(i16) or value.int > std.math.maxInt(u16)) return false;
    }
    return true;
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

test "constant table description preserves four original access envelopes" {
    const cases = [_]struct { description: Description, extent: usize, mask: u64, width: u8, tail: bool }{
        .{ .description = Description.i16_128, .extent = 256, .mask = 127, .width = 2, .tail = false },
        .{ .description = Description.f64_16, .extent = 128, .mask = 15, .width = 8, .tail = false },
        .{ .description = Description.f64_512_pairs, .extent = 4096, .mask = 510, .width = 8, .tail = true },
        .{ .description = Description.f64_pair_128, .extent = 2048, .mask = 127, .width = 8, .tail = true },
    };
    for (cases) |case| {
        const description = case.description;
        try std.testing.expect(description.valid());
        try std.testing.expectEqual(case.extent, description.serialized_extent);
        try std.testing.expectEqual(case.mask, description.allowed_index_bits);
        try std.testing.expect(description.allowsAccess(0, case.width));
        try std.testing.expectEqual(case.tail, description.allowsAccess(8, case.width));
        try std.testing.expect(!description.allowsAccess(1, case.width));
        try std.testing.expect(!description.allowsAccess(16, case.width));
        try std.testing.expect(!description.allowsAccess(0, 16));
        try std.testing.expect(!description.allowsAccess(0, if (case.width == 2) 8 else 2));
    }
    // 510 admits the final even pair base, but excludes odd in-range values.
    const bits = Description.f64_512_pairs.allowed_index_bits;
    try std.testing.expect(510 & ~bits == 0);
    try std.testing.expect(509 & ~bits != 0);
    try std.testing.expect(511 & ~bits != 0);
}

test "constant table description rejects altered derived facts before access" {
    inline for (.{ "element_count", "stride_bytes", "alignment_bytes", "serialized_extent", "access_widths", "allowed_index_bits" }) |field| {
        var description = Description.i16_128;
        @field(description, field) += 1;
        try std.testing.expect(!description.valid());
        try std.testing.expect(!description.allowsAccess(0, 2));
        try std.testing.expect(!sourceStrideMatches("e-i64:64", .{ .aggregate = "[2 x i8]" }, description));
    }
    var description = Description.i16_128;
    description.paired_scalar_indices = true;
    try std.testing.expect(!description.valid());
    description = Description.i16_128;
    description.element = .f64;
    try std.testing.expect(!description.valid());
}

test "constant table description rejects unsupported counts and checked extent overflow" {
    try std.testing.expect(Description.init(.i16, 0, false) == null);
    try std.testing.expect(Description.init(.i16, 1, false) == null);
    try std.testing.expect(Description.init(.i16, 63, false) == null);
    try std.testing.expect(Description.init(.i16, 192, false) == null);
    try std.testing.expect(Description.init(.i16, 131072, false) == null);
    try std.testing.expect(Description.init(.f64, 128, false) == null);
    try std.testing.expect(Description.init(.f64, 512, false) == null);
    try std.testing.expect(Description.init(.f64_pair, 128, true) == null);
    try std.testing.expect(Description.init(.i16, std.math.maxInt(usize) / 2 + 1, false) == null);
    try std.testing.expect(Description.init(.i16, 1 << 30, false) == null);
}

test "constant table integer descriptions derive every admitted power-of-two envelope" {
    for (1..17) |shift| {
        const count = @as(usize, 1) << @intCast(shift);
        const description = Description.init(.i16, count, false).?;
        try std.testing.expect(description.valid());
        try std.testing.expectEqual(count * 2, description.serialized_extent);
        try std.testing.expectEqual(count - 1, description.allowed_index_bits);
        try std.testing.expect(description.allowsAccess(0, 2));
        try std.testing.expect(!description.allowsAccess(1, 2));
        try std.testing.expect(!description.allowsAccess(0, 4));
        try std.testing.expect(!description.allowsAccess(8, 2));
        try std.testing.expect(!description.allowsAccess(0, 255));
    }
}

test "constant table new integer counts decline unsupported payloads without allocation" {
    for ([_]usize{ 8, 16, 64, 256 }) |count| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\"\n@unused_words = internal constant [{d} x i16] zeroinitializer, align 2\n", .{count});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const context: ReadOnlyModuleContext = .{
            .globals = module.globals.items,
            .named_types = module.named_types.items,
            .target_datalayout = module.target_datalayout,
        };
        try std.testing.expect(try decodeSymbol(std.testing.failing_allocator, context, "unused_words") == null);
    }
    var text: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer text.deinit();
    try text.writer.writeAll("target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\"\n@partial_words = internal constant [64 x i16] [");
    for (0..64) |index| {
        if (index != 0) try text.writer.writeAll(", ");
        try text.writer.writeAll(if (index == 63) "i16 undef" else "i16 7");
    }
    try text.writer.writeAll("], align 2\n");
    var module = try ir.Module.parse(std.testing.allocator, text.written());
    defer module.deinit();
    try module.verify();
    const context: ReadOnlyModuleContext = .{
        .globals = module.globals.items,
        .named_types = module.named_types.items,
        .target_datalayout = module.target_datalayout,
    };
    try std.testing.expect(try decodeSymbol(std.testing.failing_allocator, context, "partial_words") == null);
}

test "constant table original layouts retain unsupported initializer errors" {
    for ([_][]const u8{ "[128 x i16]", "[16 x double]", "[512 x double]", "[128 x %pair]" }) |ty| {
        const text = try std.fmt.allocPrint(std.testing.allocator, "target datalayout = \"e-m:e-i64:64-n8:16:32:64-S128\"\n%pair = type {{ double, double }}\n@original_table = internal constant {s} zeroinitializer, align 8\n", .{ty});
        defer std.testing.allocator.free(text);
        var module = try ir.Module.parse(std.testing.allocator, text);
        defer module.deinit();
        try module.verify();
        const context: ReadOnlyModuleContext = .{
            .globals = module.globals.items,
            .named_types = module.named_types.items,
            .target_datalayout = module.target_datalayout,
        };
        try std.testing.expectError(error.UnsupportedGlobalVariable, decodeSymbol(std.testing.allocator, context, "original_table"));
    }
}
