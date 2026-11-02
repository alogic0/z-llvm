const std = @import("std");
const air_model = @import("zig_air_model.zig");
const enum_facts = @import("zig_air_enum_facts.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const sib = @import("structured_ir_builder.zig");

const ZigType = air_model.ZigType;
const TypedValue = air_model.TypedValue;

const parseZigType = air_types.parseZigType;
const parseStaticIntegerType = air_types.parseStaticIntegerType;

pub fn parseConstant(text: []const u8) ?TypedValue {
    if (std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        var fields = air_text.splitTopLevel(text[1 .. text.len - 1], ',');
        const type_text = fields.next() orelse return null;
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(std.mem.trim(u8, type_text, " ")) orelse return null;
        if (enum_facts.enumeratorValue(type_text, value_text)) |code| return .{
            .ty = ty,
            .value = .{ .int = code },
        };
        if (std.mem.eql(u8, value_text, "null")) return .{
            .ty = ty,
            .value = if (ty.ir_type == .ptr) .null_value else .{ .int = 0 },
        };
        if (errorSetConstantCode(type_text, value_text)) |code| return .{
            .ty = ty,
            .value = .{ .int = code },
        };
        if (errorUnionConstantCode(type_text, value_text)) |code| return .{
            .ty = ty,
            .value = .{ .int = code },
        };
        if (air_semantics.isFpType(ty.ir_type)) return .{ .ty = ty, .value = .{ .fp = canonicalFpLiteral(value_text) orelse value_text } };
        if (std.mem.startsWith(u8, value_text, "@fromBackingInt(") and std.mem.endsWith(u8, value_text, ")")) {
            const inner = std.mem.trim(u8, value_text["@fromBackingInt(".len .. value_text.len - 1], " ");
            const value = std.fmt.parseInt(i128, inner, 0) catch return null;
            return .{ .ty = ty, .value = .{ .int = value } };
        }
        const value = std.fmt.parseInt(i128, value_text, 10) catch return null;
        return .{ .ty = ty, .value = .{ .int = value } };
    }
    if (std.mem.startsWith(u8, text, "@.zero_")) {
        const ty = parseStaticIntegerType(text["@.zero_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 0 } };
    }
    if (std.mem.startsWith(u8, text, "@.one_")) {
        const ty = parseStaticIntegerType(text["@.one_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 1 } };
    }
    if (std.mem.startsWith(u8, text, "@.four_")) {
        const ty = parseStaticIntegerType(text["@.four_".len..]) orelse return null;
        return .{ .ty = ty, .value = .{ .int = 4 } };
    }
    if (std.mem.eql(u8, text, "@.bool_true")) {
        return .{ .ty = .{ .ir_type = .{ .int = 1 } }, .value = .{ .int = 1 } };
    }
    if (std.mem.eql(u8, text, "@.bool_false")) {
        return .{ .ty = .{ .ir_type = .{ .int = 1 } }, .value = .{ .int = 0 } };
    }
    return null;
}

pub fn canonicalFpLiteral(text: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, text, "0")) return "0.000000e+00";
    if (std.mem.eql(u8, text, "1")) return "1.000000e+00";
    if (std.mem.eql(u8, text, "1.5")) return "1.500000e+00";
    if (std.mem.eql(u8, text, "2")) return "2.000000e+00";
    if (std.mem.eql(u8, text, "2.25")) return "2.250000e+00";
    if (std.mem.eql(u8, text, "3")) return "3.000000e+00";
    if (std.mem.eql(u8, text, "4")) return "4.000000e+00";
    if (std.mem.eql(u8, text, "5")) return "5.000000e+00";
    if (std.mem.eql(u8, text, "5.5")) return "5.500000e+00";
    if (std.mem.eql(u8, text, "6")) return "6.000000e+00";
    if (std.mem.eql(u8, text, "7")) return "7.000000e+00";
    if (std.mem.eql(u8, text, "8")) return "8.000000e+00";
    if (std.mem.eql(u8, text, "9")) return "9.000000e+00";
    return null;
}

fn errorSetConstantCode(type_text: []const u8, value_text: []const u8) ?i128 {
    const ty = std.mem.trim(u8, type_text, " ");
    const value = std.mem.trim(u8, value_text, " ");
    if (!std.mem.startsWith(u8, ty, "error{") or !std.mem.endsWith(u8, ty, "}")) return null;
    if (!std.mem.startsWith(u8, value, "error.")) return null;
    const wanted = value["error.".len..];
    var fields = air_text.splitTopLevel(ty["error{".len .. ty.len - 1], ',');
    var code: i128 = 1;
    while (fields.next()) |field| : (code += 1) {
        const name = std.mem.trim(u8, field, " ");
        if (std.mem.eql(u8, name, wanted)) return code;
    }
    return null;
}

fn errorUnionConstantCode(type_text: []const u8, value_text: []const u8) ?i128 {
    const ty = std.mem.trim(u8, type_text, " ");
    const value = std.mem.trim(u8, value_text, " ");
    if (std.mem.eql(u8, ty, "anyerror!void")) {
        if (std.mem.startsWith(u8, value, "error.")) return 1;
        if (std.mem.eql(u8, value, "{}")) return 0;
    }
    if (std.mem.startsWith(u8, ty, "anyerror!")) {
        if (std.mem.startsWith(u8, value, "error.")) return 1;
    }
    const marker = std.mem.indexOf(u8, ty, "}!") orelse return null;
    if (!std.mem.startsWith(u8, ty, "error{")) return null;
    if (std.mem.startsWith(u8, value, "error.")) {
        const error_set_text = ty[0 .. marker + 1];
        return errorSetConstantCode(error_set_text, value);
    }
    if (std.mem.eql(u8, value, "{}")) {
        const payload_type = std.mem.trim(u8, ty[marker + 2 ..], " ");
        if (std.mem.eql(u8, payload_type, "void")) return 0;
    }
    const payload = std.fmt.parseInt(i128, value, 10) catch return null;
    return payload << 16;
}

pub const SymbolPointer = struct {
    ty: ZigType,
    symbol: []const u8,
};

pub fn parseSymbolPointer(text: []const u8) ?SymbolPointer {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    var fields = air_text.splitTopLevel(text[1 .. text.len - 1], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null) return null;
    const ty = parseZigType(type_text) orelse return null;
    if (ty.ir_type != .ptr) return null;
    if (std.mem.startsWith(u8, value_text, "&") and value_text.len > 1) {
        if (value_text[1] == '.') return null;
        return .{ .ty = ty, .symbol = value_text[1..] };
    }
    if (ptrCastSymbol(value_text)) |symbol| {
        return .{ .ty = ty, .symbol = symbol };
    }
    return null;
}

pub fn ptrCastSymbol(text: []const u8) ?[]const u8 {
    const marker = "@ptrCast(&";
    const marker_start = std.mem.indexOf(u8, text, marker) orelse return null;
    const symbol_start = marker_start + marker.len;
    const symbol_end = std.mem.indexOfScalarPos(u8, text, symbol_start, ')') orelse return null;
    if (symbol_end == symbol_start) return null;
    return text[symbol_start..symbol_end];
}

pub fn materializedGlobalInitializer(ty: ir.Type, initializer_text: ?[]const u8) ir.GlobalInitializer {
    if (initializer_text) |text| {
        const trimmed = std.mem.trim(u8, text, " \t");
        if (!std.mem.eql(u8, trimmed, "-")) {
            const parsed = sib.parseGlobalInitializer(ty, trimmed);
            if (parsed != .@"opaque") return parsed;
        }
    }
    return switch (ty) {
        .int => .{ .scalar = .{ .int = 0 } },
        .ptr => .{ .scalar = .null_value },
        .half, .float, .double, .x86_fp80, .fp128 => .{ .scalar = .{ .fp = "0.0" } },
        .void, .metadata, .aggregate, .vector => .none,
    };
}

pub fn cStringLiteralByteLen(body: []const u8) ?usize {
    var index: usize = 0;
    var len: usize = 0;
    while (index < body.len) {
        if (body[index] != '\\') {
            len += 1;
            index += 1;
            continue;
        }
        index += 1;
        if (index >= body.len) return null;
        switch (body[index]) {
            '\\', '"' => {
                len += 1;
                index += 1;
            },
            'n', 'r', 't', '0' => {
                len += 1;
                index += 1;
            },
            'x' => {
                if (index + 2 >= body.len) return null;
                _ = std.fmt.parseInt(u8, body[index + 1 .. index + 3], 16) catch return null;
                len += 1;
                index += 3;
            },
            else => return null,
        }
    }
    return len;
}

test "parse static AIR constants" {
    const parsed = parseConstant("<i32, 42>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(@as(i128, 42), parsed.value.int);
    const error_union_void = parseConstant("<error{Bad}!void, {}>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(@as(i128, 0), error_union_void.value.int);
    const enum_literal = parseConstant("<Io.Event, .unset>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, enum_literal.ty.ir_type);
    try std.testing.expectEqual(@as(i128, 0), enum_literal.value.int);
    const limit_literal = parseConstant("<Io.Limit, .nothing>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, limit_literal.ty.ir_type);
    try std.testing.expectEqual(@as(i128, 0), limit_literal.value.int);
    const chunk_len_literal = parseConstant("<http.Reader.RemainingChunkLen, .rn>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, chunk_len_literal.ty.ir_type);
    try std.testing.expectEqual(@as(i128, 2), chunk_len_literal.value.int);
    const optional_token_literal = parseConstant("<zig.Ast.OptionalTokenIndex, .none>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, optional_token_literal.ty.ir_type);
    try std.testing.expectEqual(@as(i128, std.math.maxInt(u32)), optional_token_literal.value.int);
}

test "parse symbol pointers" {
    const parsed = parseSymbolPointer("<*const i8, &panic_message>") orelse return error.TestExpectedEqual;
    try std.testing.expectEqualStrings("panic_message", parsed.symbol);
}

test "materialize default global initializers and C string literal lengths" {
    try std.testing.expectEqual(ir.GlobalInitializer{ .scalar = .{ .int = 0 } }, materializedGlobalInitializer(.{ .int = 32 }, null));
    try std.testing.expectEqual(ir.GlobalInitializer{ .scalar = .null_value }, materializedGlobalInitializer(.ptr, "-"));
    try std.testing.expectEqual(@as(?usize, 3), cStringLiteralByteLen("abc"));
    try std.testing.expectEqual(@as(?usize, 2), cStringLiteralByteLen("a\\n"));
    try std.testing.expectEqual(@as(?usize, 1), cStringLiteralByteLen("\\x41"));
    try std.testing.expect(cStringLiteralByteLen("\\x4") == null);
}
