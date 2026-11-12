//! Bounded default-address-space global objects and symbolic pointer fields.
const std = @import("std");
const ir = @import("../ir.zig");
const parser = @import("../ir/parser_helpers.zig");
const target = @import("../target.zig");
const constants = @import("../codegen/x86_64/constant_table.zig");
const addresses = @import("../codegen/x86_64/symbol_address.zig");

pub const max_object_bytes = 1024 * 1024;
pub const Diagnostic = struct {
    pub const Phase = enum { properties, layout, initializer };
    pub const Reason = enum { unspecified, unsupported_properties, unsupported_layout, unsupported_initializer, type_depth, named_type, integer_width, scalar_alignment, scalar_type, integer_value, integer_range, pointer_value, tls_pointer, string_escape, string_length, object_limit };
    phase: Phase = .properties,
    reason: Reason = .unspecified,
    ty: ?ir.Type = null,
    value_kind: ?std.meta.Tag(ir.Value) = null,
    offset: ?u32 = null,
    requested: ?u64 = null,
    limit: ?u64 = null,
};
pub const Relocation = struct {
    pub const Kind = enum { absolute64, relative32 };
    offset: u32,
    address: addresses.Address,
    block: ?[]const u8 = null,
    kind: Kind = .absolute64,
    bias: i64 = 0,
};
pub const Decoded = struct {
    bytes: []u8,
    relocations: []Relocation,
    alignment: u32,
    local: bool,
    visibility: u8,
    tls: bool,

    pub fn deinit(value: *Decoded, allocator: std.mem.Allocator) void {
        allocator.free(value.relocations);
        allocator.free(value.bytes);
    }
};

const Layout = struct { size: u32, alignment: u32 };
const Array = struct { count: u32, element: ir.Type };
const Fields = @import("../ir/structure.zig").Fields;

fn floatingBits(ty: ir.Type, text: []const u8) !u128 {
    return @import("../analysis/fp_semantics.zig").scalarLiteralBits(ty, text) catch error.UnsupportedGlobalData;
}

fn trim(text: []const u8) []const u8 {
    return std.mem.trim(u8, text, " \t");
}

fn bounded(size: u64) !u32 {
    if (size > max_object_bytes) return error.UnsupportedGlobalData;
    return @intCast(size);
}

fn aligned(size: u32, alignment: u32) !u32 {
    return bounded(std.mem.alignForward(u64, size, alignment));
}

fn dataType(text: []const u8) !ir.Type {
    return parser.parseType(trim(text)) catch error.UnsupportedGlobalData;
}

fn typedField(text: []const u8) !struct { ty: ir.Type, after: []const u8 } {
    const input = trim(text);
    const parsed = parser.parseLeadingType(input) catch return error.UnsupportedGlobalData;
    return .{ .ty = parsed.ty, .after = parsed.after };
}

fn arrayType(ty: ir.Type) !Array {
    if (ty != .aggregate) return error.UnsupportedGlobalData;
    const text = trim(ty.aggregate);
    if (text.len < 5 or text[0] != '[' or text[text.len - 1] != ']') return error.UnsupportedGlobalData;
    const body = trim(text[1 .. text.len - 1]);
    const separator = std.mem.indexOf(u8, body, " x ") orelse return error.UnsupportedGlobalData;
    const count = std.fmt.parseUnsigned(u32, trim(body[0..separator]), 10) catch return error.UnsupportedGlobalData;
    return .{ .count = count, .element = try dataType(body[separator + 3 ..]) };
}

fn fields(text: []const u8) !Fields {
    return Fields.init(text) orelse error.UnsupportedGlobalData;
}

const Encoder = struct {
    allocator: std.mem.Allocator,
    context: constants.ReadOnlyModuleContext,
    layout: target.DataLayout,
    aggregate_alignment: u32 = 1,
    bytes: []u8,
    global_name: []const u8,
    relocations: std.ArrayList(Relocation) = .empty,
    diagnostic: ?*Diagnostic = null,

    fn reject(encoder: *const Encoder, reason: Diagnostic.Reason, ty: ir.Type) error{UnsupportedGlobalData} {
        if (encoder.diagnostic) |diagnostic| {
            diagnostic.reason = reason;
            diagnostic.ty = ty;
        }
        return error.UnsupportedGlobalData;
    }

    fn checkedSize(encoder: *const Encoder, size: u64) !u32 {
        return bounded(size) catch {
            if (encoder.diagnostic) |diagnostic| {
                diagnostic.reason = .object_limit;
                diagnostic.requested = size;
                diagnostic.limit = max_object_bytes;
            }
            return error.UnsupportedGlobalData;
        };
    }

    fn alignedSize(encoder: *const Encoder, size: u32, alignment: u32) !u32 {
        return encoder.checkedSize(std.mem.alignForward(u64, size, alignment));
    }

    fn resolved(encoder: *const Encoder, ty: ir.Type, depth: u8) anyerror!ir.Type {
        if (depth >= 32) return encoder.reject(.type_depth, ty);
        if (ty == .aggregate and std.mem.startsWith(u8, trim(ty.aggregate), "%")) {
            const name = trim(ty.aggregate)[1..];
            for (encoder.context.named_types) |named| if (std.mem.eql(u8, named.name, name))
                return encoder.resolved(.{ .aggregate = named.body }, depth + 1);
            return encoder.reject(.named_type, ty);
        }
        return ty;
    }

    fn typeLayout(encoder: *const Encoder, ty: ir.Type, depth: u8) anyerror!Layout {
        if (encoder.diagnostic) |diagnostic| diagnostic.ty = ty;
        if (depth >= 32) return encoder.reject(.type_depth, ty);
        if (ty == .aggregate and std.mem.startsWith(u8, trim(ty.aggregate), "%")) {
            const name = trim(ty.aggregate)[1..];
            for (encoder.context.named_types) |named| if (std.mem.eql(u8, named.name, name))
                return encoder.typeLayout(.{ .aggregate = named.body }, depth + 1);
            return encoder.reject(.named_type, ty);
        }
        if (ty == .int or ty == .ptr) {
            const bits: u16 = if (ty == .ptr) 64 else ty.int;
            if (bits != 1 and bits != 8 and bits != 16 and bits != 32 and bits != 64 and bits != 128) return encoder.reject(.integer_width, ty);
            const alignment_bits = encoder.layout.typeAbiAlignmentBits(ty) catch return error.UnsupportedGlobalData;
            // Only the native scalar allocation envelope is admitted here.
            if (alignment_bits != @max(@as(u16, 8), bits)) return encoder.reject(.scalar_alignment, ty);
            const alignment: u32 = alignment_bits / 8;
            if (alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return error.UnsupportedGlobalData;
            return .{ .size = try encoder.alignedSize((@as(u32, bits) + 7) / 8, alignment), .alignment = alignment };
        }
        if (ty == .half or ty == .float or ty == .double or ty == .x86_fp80 or ty == .fp128) {
            const bits: u16 = if (ty == .half) 16 else if (ty == .float) 32 else if (ty == .double) 64 else if (ty == .x86_fp80) 80 else 128;
            const alignment_bits: u16 = if (bits == 80) 128 else bits;
            // DataLayout's floating queries currently use native defaults.
            // Reject explicit incompatible ABI specs rather than ignoring them.
            var parts = std.mem.splitScalar(u8, encoder.layout.text, '-');
            while (parts.next()) |part| {
                if (part.len < 2 or part[0] != 'f') continue;
                var spec = std.mem.splitScalar(u8, part[1..], ':');
                const width = std.fmt.parseUnsigned(u16, spec.next() orelse return encoder.reject(.scalar_alignment, ty), 10) catch return encoder.reject(.scalar_alignment, ty);
                if (width != bits) continue;
                const abi = std.fmt.parseUnsigned(u16, spec.next() orelse return encoder.reject(.scalar_alignment, ty), 10) catch return encoder.reject(.scalar_alignment, ty);
                if (abi != alignment_bits) return encoder.reject(.scalar_alignment, ty);
            }
            return .{ .size = alignment_bits / 8, .alignment = alignment_bits / 8 };
        }
        if (ty == .vector) {
            const scalar = ty.vector.elem_ty.toType();
            if (scalar != .half and scalar != .float and scalar != .double and scalar != .x86_fp80 and scalar != .fp128)
                return encoder.reject(.scalar_type, ty);
            _ = try encoder.typeLayout(scalar, depth + 1);
            const alignment_bits = try encoder.layout.typeAbiAlignmentBits(ty);
            if (alignment_bits < 8 or alignment_bits / 8 > 4096) return encoder.reject(.scalar_alignment, ty);
            return .{
                .size = try encoder.checkedSize(try encoder.layout.typeAllocSizeBytes(ty)),
                .alignment = alignment_bits / 8,
            };
        }
        if (ty != .aggregate) return encoder.reject(.scalar_type, ty);
        if (std.mem.startsWith(u8, trim(ty.aggregate), "[")) {
            const array = try arrayType(ty);
            _ = try encoder.checkedSize(array.count);
            const element = try encoder.typeLayout(array.element, depth + 1);
            return .{ .size = try encoder.checkedSize(@as(u64, element.size) * array.count), .alignment = element.alignment };
        }
        var items = try fields(ty.aggregate);
        var size: u32 = 0;
        var alignment: u32 = if (items.packed_type) 1 else encoder.aggregate_alignment;
        while (items.next()) |field| {
            const layout = try encoder.typeLayout(try dataType(field), depth + 1);
            size = try encoder.checkedSize(@as(u64, if (items.packed_type) size else try encoder.alignedSize(size, layout.alignment)) + layout.size);
            if (!items.packed_type) alignment = @max(alignment, layout.alignment);
        }
        return .{ .size = try encoder.alignedSize(size, alignment), .alignment = alignment };
    }

    fn value(encoder: *Encoder, ty: ir.Type, input: ir.Value, offset: u32) !void {
        if (encoder.diagnostic) |diagnostic| {
            diagnostic.ty = ty;
            diagnostic.value_kind = @as(std.meta.Tag(ir.Value), input);
            diagnostic.offset = offset;
        }
        // Global poison/undef cells may be refined to any concrete value. The
        // zero-filled allocation supplies that refinement without changing
        // defined neighboring cells or materializing a symbolic relocation.
        if (input == .zero_initializer or input == .undef or input == .poison) return;
        if (ty == .vector) {
            if (input != .vector) return encoder.reject(.scalar_type, ty);
            return encoder.vector(ty, input.vector, offset, 0);
        }
        if (ty.eql(.{ .int = 32 }) and (input == .constant_expr or input == .fp)) {
            // The parser's broad floating spelling recognizer may classify a
            // constant expression containing 'e' as .fp. Admit this structural
            // integer expression independently of that advisory value tag.
            const expression = if (input == .constant_expr) input.constant_expr else input.fp;
            if (std.mem.startsWith(u8, trim(expression), "trunc ")) return encoder.relative32(trim(expression), offset);
        }
        if (ty == .ptr) {
            if (input == .constant_expr) {
                const expression = trim(input.constant_expr);
                if (std.mem.startsWith(u8, expression, "blockaddress(")) {
                    var names: @import("../ir/opaque_names.zig").Iterator = .{ .raw = expression };
                    const token = (try names.next()) orelse return error.UnsupportedGlobalData;
                    if (token != .block_address or names.index != expression.len) return error.UnsupportedGlobalData;
                    const address = token.block_address;
                    const symbol = encoder.context.functionAddress(address.function) orelse return error.UnsupportedGlobalData;
                    try encoder.relocations.append(encoder.allocator, .{ .offset = offset, .address = .{ .symbol = symbol }, .block = address.block });
                    return;
                }
            }
            if (addresses.fromValue(input)) |address| {
                if (encoder.context.dataAddress(address.symbol)) |data| {
                    if ((try addresses.globalProperties(data.global)).tls) return encoder.reject(.tls_pointer, ty);
                }
                try encoder.relocations.append(encoder.allocator, .{ .offset = offset, .address = address });
                return;
            }
            const bits = addresses.pointerBits(input) orelse return encoder.reject(.pointer_value, ty);
            std.mem.writeInt(u64, encoder.bytes[offset..][0..8], bits, .little);
            return;
        }
        if (ty == .half or ty == .float or ty == .double or ty == .x86_fp80 or ty == .fp128) {
            if (input != .fp) return encoder.reject(.scalar_type, ty);
            const pattern = floatingBits(ty, trim(input.fp)) catch return encoder.reject(.scalar_type, ty);
            const count: usize = if (ty == .half) 2 else if (ty == .float) 4 else if (ty == .double) 8 else if (ty == .x86_fp80) 10 else 16;
            for (0..count) |index| encoder.bytes[offset + index] = @truncate(pattern >> @intCast(index * 8));
            return;
        }
        if (ty != .int or input != .int) return encoder.reject(.integer_value, ty);
        const bits = ty.int;
        var pattern: u128 = @bitCast(input.int);
        if (bits < 128) {
            const mask = (@as(u128, 1) << @intCast(bits)) - 1;
            const minimum = -(@as(i128, 1) << @intCast(bits - 1));
            if (input.int < minimum or (input.int >= 0 and @as(u128, @intCast(input.int)) > mask)) return encoder.reject(.integer_range, ty);
            pattern &= mask;
        }
        for (0..(@as(usize, bits) + 7) / 8) |index|
            encoder.bytes[offset + index] = @truncate(pattern >> @intCast(index * 8));
    }

    fn relative32(encoder: *Encoder, expression: []const u8, offset: u32) !void {
        const prefix = "trunc (i64 sub (";
        const suffix = ") to i32)";
        if (!std.mem.startsWith(u8, expression, prefix) or !std.mem.endsWith(u8, expression, suffix)) return encoder.reject(.integer_value, .{ .int = 32 });
        var operands: Fields = .{ .rest = expression[prefix.len .. expression.len - suffix.len], .packed_type = false };
        const target_field = try typedField(operands.next() orelse return error.UnsupportedGlobalData);
        const base_field = try typedField(operands.next() orelse return error.UnsupportedGlobalData);
        if (operands.next() != null) return error.UnsupportedGlobalData;
        const address = addresses.fromIntegerValue(target_field.ty, .{ .constant_expr = target_field.after }) orelse return error.UnsupportedGlobalData;
        const base = addresses.fromIntegerValue(base_field.ty, .{ .constant_expr = base_field.after }) orelse return error.UnsupportedGlobalData;
        // R_X86_64_PC32 computes S+A-P. P is the field address, whereas
        // the expression subtracts this object's base plus its byte addend.
        if (!ir.identifiers.eql(base.symbol, encoder.global_name)) return error.UnsupportedGlobalData;
        if (encoder.context.dataAddress(address.symbol)) |data| {
            if ((try addresses.globalProperties(data.global)).tls) return encoder.reject(.tls_pointer, .{ .int = 32 });
        }
        try encoder.relocations.append(encoder.allocator, .{
            .offset = offset,
            .address = address,
            .kind = .relative32,
            .bias = @as(i64, offset) - base.addend,
        });
    }

    fn vector(encoder: *Encoder, ty: ir.Type, input: []const u8, offset: u32, depth: u8) anyerror!void {
        const element = ty.vector.elem_ty.toType();
        const stride = try encoder.layout.typeStoreSizeBytes(element);
        const splat = std.mem.startsWith(u8, input, "splat (") and std.mem.endsWith(u8, input, ")");
        if (!splat and (input.len < 2 or input[0] != '<' or input[input.len - 1] != '>')) return error.UnsupportedGlobalData;
        var items: Fields = .{ .rest = if (splat) input[7 .. input.len - 1] else input[1 .. input.len - 1], .packed_type = false };
        const repeated = if (splat) try typedField(items.next() orelse return error.UnsupportedGlobalData) else null;
        for (0..ty.vector.len) |index| {
            const item = repeated orelse try typedField(items.next() orelse return error.UnsupportedGlobalData);
            if (!item.ty.eql(element)) return error.UnsupportedGlobalData;
            try encoder.text(element, item.after, offset + @as(u32, @intCast(index * stride)), depth + 1);
        }
        if (items.next() != null) return error.UnsupportedGlobalData;
    }

    fn text(encoder: *Encoder, ty: ir.Type, raw: []const u8, offset: u32, depth: u8) anyerror!void {
        if (depth >= 32) return error.UnsupportedGlobalData;
        const input = trim(raw);
        if (std.mem.eql(u8, input, "zeroinitializer") or std.mem.eql(u8, input, "undef") or std.mem.eql(u8, input, "poison")) return;
        const actual = try encoder.resolved(ty, depth);
        if (actual == .vector) return encoder.vector(actual, input, offset, depth);
        if (actual == .ptr and std.mem.startsWith(u8, input, "blockaddress("))
            return encoder.value(actual, .{ .constant_expr = input }, offset);
        if (actual == .int or actual == .ptr or actual == .half or actual == .float or actual == .double or actual == .x86_fp80 or actual == .fp128) return encoder.value(actual, parser.parseValue(input) catch return error.UnsupportedGlobalData, offset);
        if (actual != .aggregate) return error.UnsupportedGlobalData;
        if (std.mem.startsWith(u8, trim(actual.aggregate), "[")) {
            const array = try arrayType(actual);
            const element = try encoder.typeLayout(array.element, depth + 1);
            if (std.mem.startsWith(u8, input, "c\"") and std.mem.endsWith(u8, input, "\"")) {
                if (!array.element.eql(.{ .int = 8 })) return error.UnsupportedGlobalData;
                var cursor: usize = 2;
                var written: u32 = 0;
                while (cursor < input.len - 1) {
                    if (written >= array.count) return encoder.reject(.string_length, ty);
                    const byte = if (input[cursor] == '\\') blk: {
                        if (cursor + 1 < input.len - 1 and input[cursor + 1] == '\\') {
                            cursor += 2;
                            break :blk @as(u8, '\\');
                        }
                        if (cursor + 2 >= input.len - 1) return encoder.reject(.string_escape, ty);
                        const parsed = std.fmt.parseUnsigned(u8, input[cursor + 1 ..][0..2], 16) catch return encoder.reject(.string_escape, ty);
                        cursor += 3;
                        break :blk parsed;
                    } else blk: {
                        const byte = input[cursor];
                        if (byte == '"') return encoder.reject(.string_escape, ty);
                        cursor += 1;
                        break :blk byte;
                    };
                    encoder.bytes[offset + written] = byte;
                    written += 1;
                }
                if (written != array.count) return encoder.reject(.string_length, ty);
                return;
            }
            if (input.len < 2 or input[0] != '[' or input[input.len - 1] != ']') return error.UnsupportedGlobalData;
            var values: Fields = .{ .rest = input[1 .. input.len - 1], .packed_type = false };
            for (0..array.count) |index| {
                const field = try typedField(values.next() orelse return error.UnsupportedGlobalData);
                if (!field.ty.eql(array.element)) return error.UnsupportedGlobalData;
                try encoder.text(array.element, field.after, offset + @as(u32, @intCast(index)) * element.size, depth + 1);
            }
            if (values.next() != null) return error.UnsupportedGlobalData;
            return;
        }
        var types = try fields(actual.aggregate);
        var values = try fields(input);
        if (types.packed_type != values.packed_type) return error.UnsupportedGlobalData;
        var position: u32 = 0;
        while (types.next()) |field_text| {
            const field_ty = try dataType(field_text);
            const layout = try encoder.typeLayout(field_ty, depth + 1);
            const field = try typedField(values.next() orelse return error.UnsupportedGlobalData);
            if (!field.ty.eql(field_ty)) return error.UnsupportedGlobalData;
            if (!types.packed_type) position = try aligned(position, layout.alignment);
            try encoder.text(field_ty, field.after, offset + position, depth + 1);
            position += layout.size;
        }
        if (values.next() != null) return error.UnsupportedGlobalData;
    }
};

pub fn decode(allocator: std.mem.Allocator, context: constants.ReadOnlyModuleContext, global: ir.Global) !Decoded {
    return decodeObserved(allocator, context, global, null);
}

pub fn decodeObserved(allocator: std.mem.Allocator, context: constants.ReadOnlyModuleContext, global: ir.Global, diagnostic: ?*Diagnostic) !Decoded {
    if (diagnostic) |out| out.* = .{ .ty = global.ty };
    errdefer if (diagnostic) |out| {
        if (out.reason == .unspecified) out.reason = switch (out.phase) {
            .properties => .unsupported_properties,
            .layout => .unsupported_layout,
            .initializer => .unsupported_initializer,
        };
    };
    if (!addresses.supportsLayout(context.target_datalayout) or global.initializer == .none) return error.UnsupportedGlobalData;
    const properties = addresses.globalProperties(global) catch return error.UnsupportedGlobalData;
    var encoder: Encoder = .{ .allocator = allocator, .context = context, .layout = try target.DataLayout.parse(context.target_datalayout orelse ""), .bytes = &.{}, .global_name = global.name, .diagnostic = diagnostic };
    var layout_parts = std.mem.splitScalar(u8, context.target_datalayout orelse "", '-');
    while (layout_parts.next()) |part| if (std.mem.startsWith(u8, part, "a:")) {
        var values = std.mem.splitScalar(u8, part[2..], ':');
        const bits = std.fmt.parseUnsigned(u16, values.next() orelse return error.UnsupportedGlobalData, 10) catch return error.UnsupportedGlobalData;
        if (bits != 0) {
            if (bits % 8 != 0 or !std.math.isPowerOfTwo(bits)) return error.UnsupportedGlobalData;
            encoder.aggregate_alignment = bits / 8;
        }
    };
    if (diagnostic) |out| out.phase = .layout;
    const layout = try encoder.typeLayout(global.ty, 0);
    encoder.bytes = try allocator.alloc(u8, layout.size);
    errdefer allocator.free(encoder.bytes);
    @memset(encoder.bytes, 0);
    errdefer encoder.relocations.deinit(allocator);
    if (diagnostic) |out| out.phase = .initializer;
    switch (global.initializer) {
        .scalar => |value| if (value == .constant_expr and global.ty == .aggregate)
            try encoder.text(global.ty, value.constant_expr, 0, 0)
        else
            try encoder.value(global.ty, value, 0),
        .array => |array| {
            const actual = try arrayType(try encoder.resolved(global.ty, 0));
            if (!actual.element.eql(array.elem_ty) or actual.count != array.values.items.len) return error.UnsupportedGlobalData;
            const element = try encoder.typeLayout(actual.element, 1);
            for (array.values.items, 0..) |value, index| try encoder.value(actual.element, value, @as(u32, @intCast(index)) * element.size);
        },
        .@"opaque", .c_string => |text| try encoder.text(global.ty, text, 0, 0),
        .none => unreachable,
    }
    return .{ .bytes = encoder.bytes, .relocations = try encoder.relocations.toOwnedSlice(allocator), .alignment = properties.alignment orelse layout.alignment, .local = properties.local, .visibility = properties.visibility, .tls = properties.tls };
}

test "global data floating vectors preserve packed lanes payloads and tail padding" {
    const source =
        \\@nan = constant <1 x float> splat (float 0x7FF8000000000000)
        \\@extended = constant <3 x x86_fp80> <x86_fp80 0xK00000000000000000001, x86_fp80 0xK80000000000000000000, x86_fp80 0xK7FFF8000000000000001>
        \\@nested = constant { i8, <3 x float>, i8 } { i8 7, <3 x float> <float 1.0, float -0.0, float 0x7FF0000020000000>, i8 9 }
        \\@"source object" = global i64 7
        \\@"pointer cell" = global ptr @"source object"
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    try module.verify();
    const context: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null };
    var nan = try decode(std.testing.allocator, context, module.globals.items[0]);
    defer nan.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 0, 0, 192, 127 }, nan.bytes);
    var extended = try decode(std.testing.allocator, context, module.globals.items[1]);
    defer extended.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 32), extended.bytes.len);
    try std.testing.expectEqual(@as(u32, 32), extended.alignment);
    try std.testing.expectEqual(@as(u80, 1), std.mem.readInt(u80, extended.bytes[0..10], .little));
    try std.testing.expectEqual(@as(u80, 1) << 79, std.mem.readInt(u80, extended.bytes[10..20], .little));
    try std.testing.expectEqual(@as(u80, 0x7fff8000000000000001), std.mem.readInt(u80, extended.bytes[20..30], .little));
    try std.testing.expectEqualSlices(u8, &.{ 0, 0 }, extended.bytes[30..]);
    var nested = try decode(std.testing.allocator, context, module.globals.items[2]);
    defer nested.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 48), nested.bytes.len);
    try std.testing.expectEqual(@as(u8, 7), nested.bytes[0]);
    try std.testing.expectEqual(@as(u32, 0x3f800000), std.mem.readInt(u32, nested.bytes[16..20], .little));
    try std.testing.expectEqual(@as(u32, 0x80000000), std.mem.readInt(u32, nested.bytes[20..24], .little));
    try std.testing.expectEqual(@as(u32, 0x7f800001), std.mem.readInt(u32, nested.bytes[24..28], .little));
    try std.testing.expectEqual(@as(u8, 9), nested.bytes[32]);
    var pointer = try decode(std.testing.allocator, context, module.globals.items[4]);
    defer pointer.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("\"source object\"", pointer.relocations[0].address.symbol);
}

test "global data decodes the compiler terminal string with a literal backslash" {
    const source =
        \\@escape = constant [13 x i8] c"\1B[J\1B]9;4;0\1B\\\00"
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 27, '[', 'J', 27, ']', '9', ';', '4', ';', '0', 27, '\\', 0 }, data.bytes);
    try std.testing.expectEqual(@as(usize, 0), data.relocations.len);
}

test "global data diagnoses malformed string escapes and lengths" {
    for ([_][]const u8{
        "@bad = constant [1 x i8] c\"\\0Z\"",
        "@bad = constant [1 x i8] c\"\\0\"",
        "@bad = constant [1 x i8] c\"\\\"",
        "@bad = constant [1 x i8] c\"AB\"",
    }, 0..) |source, index| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        var diagnostic: Diagnostic = .{};
        try std.testing.expectError(error.UnsupportedGlobalData, decodeObserved(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0], &diagnostic));
        try std.testing.expectEqual(if (index == 3) Diagnostic.Reason.string_length else Diagnostic.Reason.string_escape, diagnostic.reason);
        try std.testing.expectEqual(Diagnostic.Phase.initializer, diagnostic.phase);
    }
}

test "global data refines poison cells while preserving defined neighbors and relocations" {
    const source =
        \\@table = constant { [3 x i32], [3 x ptr] } { [3 x i32] [i32 287454020, i32 poison, i32 -1], [3 x ptr] [ptr @left, ptr poison, ptr @right] }
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 40), data.bytes.len);
    try std.testing.expectEqualSlices(u8, &.{ 0x44, 0x33, 0x22, 0x11, 0, 0, 0, 0, 255, 255, 255, 255 }, data.bytes[0..12]);
    try std.testing.expectEqual(@as(usize, 2), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 16), data.relocations[0].offset);
    try std.testing.expectEqual(@as(u32, 32), data.relocations[1].offset);
    try std.testing.expectEqualStrings("left", data.relocations[0].address.symbol);
    try std.testing.expectEqualStrings("right", data.relocations[1].address.symbol);
}

test "global data diagnostics identify a nested unsupported scalar layout" {
    var module = try ir.Module.parse(std.testing.allocator, "@table = constant [1 x <2 x ptr>] zeroinitializer\n");
    defer module.deinit();
    var diagnostic: Diagnostic = .{};
    try std.testing.expectError(error.UnsupportedGlobalData, decodeObserved(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0], &diagnostic));
    try std.testing.expectEqual(Diagnostic.Reason.scalar_type, diagnostic.reason);
    try std.testing.expect(diagnostic.ty.? == .vector);
    try std.testing.expectEqual(Diagnostic.Phase.layout, diagnostic.phase);
}

test "global data half and x87 tables preserve raw bits and allocation strides" {
    const source =
        \\@half = constant [3 x half] [half 0xH8000, half 0xH7C01, half 0xH0001]
        \\@extended = constant [2 x x86_fp80] [x86_fp80 0xK7FFF8000000000000001, x86_fp80 0xK80000000000000000000]
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null };
    var half = try decode(std.testing.allocator, ctx, module.globals.items[0]);
    defer half.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 2), half.alignment);
    try std.testing.expectEqualSlices(u8, &.{ 0, 128, 1, 124, 1, 0 }, half.bytes);
    var extended = try decode(std.testing.allocator, ctx, module.globals.items[1]);
    defer extended.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 16), extended.alignment);
    try std.testing.expectEqual(@as(usize, 32), extended.bytes.len);
    try std.testing.expectEqual(@as(u80, 0x7fff8000000000000001), std.mem.readInt(u80, extended.bytes[0..10], .little));
    try std.testing.expectEqual(@as(u80, 0x80000000000000000000), std.mem.readInt(u80, extended.bytes[16..26], .little));
    for (extended.bytes[10..16]) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
}

test "global data diagnoses the exact object byte limit" {
    var module = try ir.Module.parse(std.testing.allocator, "@too_large = constant [524289 x i16] zeroinitializer");
    defer module.deinit();
    var diagnostic: Diagnostic = .{};
    try std.testing.expectError(error.UnsupportedGlobalData, decodeObserved(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0], &diagnostic));
    try std.testing.expectEqual(Diagnostic.Reason.object_limit, diagnostic.reason);
    try std.testing.expectEqual(@as(?u64, 1048578), diagnostic.requested);
    try std.testing.expectEqual(@as(?u64, max_object_bytes), diagnostic.limit);
}

test "global data relative table relocations retain field and pointer addends" {
    const source =
        \\@table = constant [3 x i32] [i32 trunc (i64 sub (i64 ptrtoint (ptr @first to i64), i64 ptrtoint (ptr @table to i64)) to i32), i32 287454020, i32 trunc (i64 sub (i64 ptrtoint (ptr getelementptr (i8, ptr @second, i64 -7) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @table, i64 3) to i64)) to i32)]
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 12), data.bytes.len);
    try std.testing.expectEqual(@as(u32, 0x11223344), std.mem.readInt(u32, data.bytes[4..8], .little));
    try std.testing.expectEqual(@as(usize, 2), data.relocations.len);
    try std.testing.expectEqual(Relocation.Kind.relative32, data.relocations[0].kind);
    try std.testing.expectEqualStrings("first", data.relocations[0].address.symbol);
    try std.testing.expectEqual(@as(i64, 0), data.relocations[0].bias);
    try std.testing.expectEqual(@as(u32, 8), data.relocations[1].offset);
    try std.testing.expectEqualStrings("second", data.relocations[1].address.symbol);
    try std.testing.expectEqual(@as(i32, -7), data.relocations[1].address.addend);
    try std.testing.expectEqual(@as(i64, 5), data.relocations[1].bias);
}

test "global data rejects relative differences with an unproved base or width" {
    for ([_][]const u8{
        "@table = constant [1 x i32] [i32 trunc (i64 sub (i64 ptrtoint (ptr @first to i64), i64 ptrtoint (ptr @other to i64)) to i32)]",
        "@table = constant [1 x i32] [i32 trunc (i64 sub (i32 ptrtoint (ptr @first to i32), i64 ptrtoint (ptr @table to i64)) to i32)]",
        "@table = constant [1 x i32] [i32 trunc (i64 add (i64 ptrtoint (ptr @first to i64), i64 ptrtoint (ptr @table to i64)) to i32)]",
        "@table = constant [1 x i16] [i16 trunc (i64 sub (i64 ptrtoint (ptr @first to i64), i64 ptrtoint (ptr @table to i64)) to i16)]",
        "@tls = thread_local global i8 1\n@table = constant [1 x i32] [i32 trunc (i64 sub (i64 ptrtoint (ptr @tls to i64), i64 ptrtoint (ptr @table to i64)) to i32)]",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.UnsupportedGlobalData, decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[module.globals.items.len - 1]));
    }
}

test "global data preserves floating table bits and named aggregate offsets" {
    const source =
        \\%Floats = type { i8, [2 x float], [3 x double], fp128, ptr }
        \\@table = constant %Floats { i8 90, [2 x float] [float 0x7FF0000020000000, float 0x36A0000000000000], [3 x double] [double 0x8000000000000000, double 0x1, double 0xFFF0000000000123], fp128 0xL0123456789ABCDEF7FFF000000000123, ptr @neighbor }
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = null }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 80), data.bytes.len);
    try std.testing.expectEqual(@as(u32, 16), data.alignment);
    try std.testing.expectEqual(@as(u8, 90), data.bytes[0]);
    try std.testing.expectEqual(@as(u32, 0x7f800001), std.mem.readInt(u32, data.bytes[4..8], .little));
    try std.testing.expectEqual(@as(u32, 1), std.mem.readInt(u32, data.bytes[8..12], .little));
    try std.testing.expectEqual(@as(u64, 0x8000000000000000), std.mem.readInt(u64, data.bytes[16..24], .little));
    try std.testing.expectEqual(@as(u64, 1), std.mem.readInt(u64, data.bytes[24..32], .little));
    try std.testing.expectEqual(@as(u64, 0xfff0000000000123), std.mem.readInt(u64, data.bytes[32..40], .little));
    try std.testing.expectEqual(@as(u128, 0x7fff0000000001230123456789abcdef), std.mem.readInt(u128, data.bytes[48..64], .little));
    try std.testing.expectEqual(@as(usize, 1), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 64), data.relocations[0].offset);
    try std.testing.expectEqualStrings("neighbor", data.relocations[0].address.symbol);
}

test "global data lays out named nested arrays and symbolic pointer fields" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-i128:128"
        \\%"pair.type" = type { ptr, i16 }
        \\%Container = type { i8, [2 x %"pair.type"], i32 }
        \\@object = internal global %Container { i8 255, [2 x %"pair.type"] [%"pair.type" { ptr null, i16 -1 }, %"pair.type" { ptr getelementptr (i8, ptr @other, i64 888), i16 123 }], i32 4294967295 }, align 1
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    var data = try decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    var expected: [48]u8 = @splat(0);
    expected[0] = 255;
    std.mem.writeInt(u16, expected[16..18], 65535, .little);
    std.mem.writeInt(u16, expected[32..34], 123, .little);
    std.mem.writeInt(u32, expected[40..44], 4294967295, .little);
    try std.testing.expectEqualSlices(u8, &expected, data.bytes);
    try std.testing.expectEqual(@as(u32, 1), data.alignment);
    try std.testing.expect(data.local);
    try std.testing.expectEqual(@as(usize, 1), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 24), data.relocations[0].offset);
    try std.testing.expectEqualStrings("other", data.relocations[0].address.symbol);
    try std.testing.expectEqual(@as(i32, 888), data.relocations[0].address.addend);
}

test "global data preserves full integer and numeric pointer bits" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-i128:128"
        \\@wide = global i128 -1, align 16
        \\@pointer = global ptr inttoptr (i64 18446744073709551615 to ptr), align 8
        \\@function = private constant ptr @callee, align 8
        \\@empty = global [0 x ptr] zeroinitializer
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    for (module.globals.items, 0..) |global, index| {
        var data = try decode(std.testing.allocator, ctx, global);
        defer data.deinit(std.testing.allocator);
        if (index < 2) {
            try std.testing.expectEqual(@as(usize, if (index == 0) 16 else 8), data.bytes.len);
            for (data.bytes) |byte| try std.testing.expectEqual(@as(u8, 255), byte);
            try std.testing.expectEqual(@as(usize, 0), data.relocations.len);
        } else if (index == 2) {
            try std.testing.expectEqual(@as(usize, 1), data.relocations.len);
            try std.testing.expectEqualStrings("callee", data.relocations[0].address.symbol);
            try std.testing.expect(data.local);
        } else try std.testing.expectEqual(@as(usize, 0), data.bytes.len);
    }
}

test "global data decodes escaped byte strings and aggregate zero fill" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64"
        \\@string = private constant [4 x i8] c"A\00\5c\ff", align 8
        \\@zeros = global { i8, [3 x ptr], i16 } zeroinitializer
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var string = try decode(std.testing.allocator, ctx, module.globals.items[0]);
    defer string.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 65, 0, 92, 255 }, string.bytes);
    var zeros = try decode(std.testing.allocator, ctx, module.globals.items[1]);
    defer zeros.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 40), zeros.bytes.len);
    for (zeros.bytes) |byte| try std.testing.expectEqual(@as(u8, 0), byte);
}

test "global data rejects incomplete unsupported and unbounded definitions" {
    for ([_][]const u8{
        "@bad = global i8 256",
        "@bad = global ptr inttoptr (i32 1 to ptr)",
        "@bad = global [2 x i8] c\"A\"",
        "@bad = global [2 x i8] [i8 1]",
        "@bad = global { i8, i64 } { i8 1 }",
        "@bad = global { i8 } { i16 1 }",
        "@bad = global <2 x i32> zeroinitializer",
        "@bad = global float 0x3FF0000000000001",
        "@bad = global fp128 0xL1234",
        "target datalayout = \"e-f64:32\"\n@bad = global double 1.0",
        "@bad = global [1048577 x i8] zeroinitializer",
        "%Recursive = type { %Recursive }\n@bad = global %Recursive zeroinitializer",
        "@bad = external global i64",
        "@bad = thread_local(initialexec) global i64 0",
        "@bad = weak global i64 0",
        "@bad = global i64 0, section \"custom\"",
        "target datalayout = \"e-p:32:32\"\n@bad = global ptr null",
        "target datalayout = \"e-p:64:64-i8:64\"\n@bad = global [2 x i8] c\"AB\"",
    }) |source| {
        var module = try ir.Module.parse(std.testing.allocator, source);
        defer module.deinit();
        try std.testing.expectError(error.UnsupportedGlobalData, decode(std.testing.allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]));
    }
}

test "global data preserves nested packed field offsets and unaligned relocations" {
    const source =
        \\target datalayout = "e-p:64:64-i64:64-a:64"
        \\%Packed = type <{ i8, ptr, i16 }>
        \\@packed = global { i8, [2 x %Packed], i64 } { i8 127, [2 x %Packed] [%Packed <{ i8 1, ptr @first, i16 4660 }>, %Packed <{ i8 2, ptr @second, i16 -1 }>], i64 72623859790382856 }
        \\@inline = global { i8, <{ i8, i64 }>, i16 } { i8 9, <{ i8, i64 }> <{ i8 10, i64 123 }>, i16 17 }
    ;
    var module = try ir.Module.parse(std.testing.allocator, source);
    defer module.deinit();
    const ctx: constants.ReadOnlyModuleContext = .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout };
    var data = try decode(std.testing.allocator, ctx, module.globals.items[0]);
    defer data.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 32), data.bytes.len);
    try std.testing.expectEqualSlices(u8, &.{ 127, 1 }, data.bytes[0..2]);
    try std.testing.expectEqualSlices(u8, &.{ 0x34, 0x12, 2 }, data.bytes[10..13]);
    try std.testing.expectEqualSlices(u8, &.{ 255, 255, 0 }, data.bytes[21..24]);
    try std.testing.expectEqual(@as(u64, 72623859790382856), std.mem.readInt(u64, data.bytes[24..32], .little));
    try std.testing.expectEqual(@as(u32, 8), data.alignment);
    try std.testing.expectEqual(@as(usize, 2), data.relocations.len);
    try std.testing.expectEqual(@as(u32, 2), data.relocations[0].offset);
    try std.testing.expectEqual(@as(u32, 13), data.relocations[1].offset);
    try std.testing.expectEqualStrings("first", data.relocations[0].address.symbol);
    try std.testing.expectEqualStrings("second", data.relocations[1].address.symbol);
    var inline_data = try decode(std.testing.allocator, ctx, module.globals.items[1]);
    defer inline_data.deinit(std.testing.allocator);
    try std.testing.expectEqualSlices(u8, &.{ 9, 10, 123, 0, 0, 0, 0, 0, 0, 0, 17, 0, 0, 0, 0, 0 }, inline_data.bytes);
    const malformed: ir.Global = .{ .name = "mismatch", .kind = .global, .ty = .{ .aggregate = "<{ i8, i64 }>" }, .initializer = .{ .@"opaque" = "{ i8 1, i64 2 }" } };
    try std.testing.expectError(error.UnsupportedGlobalData, decode(std.testing.allocator, ctx, malformed));
}

test "global data releases partial output after allocation failures" {
    const Test = struct {
        fn run(allocator: std.mem.Allocator) !void {
            var module = try ir.Module.parse(allocator, "@object = internal global { ptr, ptr } { ptr @left, ptr @right }, align 8");
            defer module.deinit();
            var data = try decode(allocator, .{ .globals = module.globals.items, .named_types = module.named_types.items, .target_datalayout = module.target_datalayout }, module.globals.items[0]);
            defer data.deinit(allocator);
        }
    };
    try std.testing.checkAllAllocationFailures(std.testing.allocator, Test.run, .{});
}
