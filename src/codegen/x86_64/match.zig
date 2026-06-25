const std = @import("std");
const ir = @import("../../ir.zig");

pub fn validateDefaultCallConv(calling_conv: ?[]const u8) !void {
    if (calling_conv) |cc| {
        if (!std.mem.eql(u8, cc, "ccc")) return error.UnsupportedCodegenCallingConvention;
    }
}

pub fn isNamed(value: ir.Value, name: []const u8) bool {
    return switch (value) {
        .named => |value_name| std.mem.eql(u8, value_name, name),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn callIsFastcc(calling_conv: ?[]const u8) bool {
    const cc = calling_conv orelse return false;
    return std.mem.eql(u8, cc, "fastcc");
}

pub fn callArgAttrsContain(arg: ir.CallArg, needle: []const u8) bool {
    const attrs = arg.attrs orelse return false;
    return std.mem.indexOf(u8, attrs, needle) != null;
}

pub fn paramAttrsContain(param: ir.Param, needle: []const u8) bool {
    const attrs = param.attrs orelse return false;
    return std.mem.indexOf(u8, attrs, needle) != null;
}

pub fn globalSymbolName(name: []const u8) ![]const u8 {
    if (!std.mem.startsWith(u8, name, "@") or name.len == 1) return error.UnsupportedCodegenValue;
    return symbolName(name);
}

pub fn globalSymbolNameFromValue(value: ir.Value) ![]const u8 {
    return switch (value) {
        .named => |name| try globalSymbolName(name),
        .constant_expr => |text| try globalSymbolNameFromConstantExpr(text),
        .int, .fp, .undef, .poison, .null_value, .zero_initializer, .vector => error.UnsupportedCodegenValue,
    };
}

pub fn globalSymbolNameFromConstantExpr(text: []const u8) ![]const u8 {
    const at_index = std.mem.indexOfScalar(u8, text, '@') orelse return error.UnsupportedCodegenValue;
    const start = at_index + 1;
    var end = start;
    while (end < text.len and text[end] != ' ' and text[end] != ',' and text[end] != '}' and text[end] != ')') : (end += 1) {}
    if (end == start) return error.UnsupportedCodegenValue;
    return symbolName(text[start..end]);
}

pub fn symbolName(name: []const u8) []const u8 {
    const without_at = if (std.mem.startsWith(u8, name, "@")) name[1..] else name;
    if (without_at.len >= 2 and without_at[0] == '"' and without_at[without_at.len - 1] == '"') {
        return without_at[1 .. without_at.len - 1];
    }
    return without_at;
}

pub fn isInt(value: ir.Value, expected: i128) bool {
    return switch (value) {
        .int => |actual| actual == expected,
        .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn i32Value(value: i128) !i32 {
    if (value < std.math.minInt(i32) or value > std.math.maxInt(i32)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn u8Value(value: i128) !u8 {
    if (value < 0 or value > std.math.maxInt(u8)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn i64Value(value: i128) !i64 {
    if (value < std.math.minInt(i64) or value > std.math.maxInt(i64)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn u5Value(value: i128) !u5 {
    if (value < 0 or value > std.math.maxInt(u5)) return error.UnsupportedCodegenValue;
    return @intCast(value);
}

pub fn isFpText(value: ir.Value, expected: []const u8) bool {
    return switch (value) {
        .fp => |text| std.mem.eql(u8, text, expected),
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn fp32TextBits(value: ir.Value) !u32 {
    const text = switch (value) {
        .fp => |text| text,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    // LLVM prints float constants as raw double bit patterns (0x...), not
    // C99 hex-float literals, so raw-hex spellings must be bit-decoded.
    if (rawHexFpBits(text)) |bits| {
        const wide: f64 = @bitCast(bits);
        const narrow: f32 = @floatCast(wide);
        return @bitCast(narrow);
    }
    const parsed = std.fmt.parseFloat(f32, text) catch return error.UnsupportedCodegenValue;
    return @bitCast(parsed);
}

fn rawHexFpBits(text: []const u8) ?u64 {
    if (!std.mem.startsWith(u8, text, "0x") or text.len != 18) return null;
    return std.fmt.parseInt(u64, text[2..], 16) catch null;
}

pub fn fp64TextBits(value: ir.Value) !u64 {
    const text = switch (value) {
        .fp => |text| text,
        .named, .int, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => return error.UnsupportedCodegenValue,
    };
    if (rawHexFpBits(text)) |bits| return bits;
    const parsed = std.fmt.parseFloat(f64, text) catch return error.UnsupportedCodegenValue;
    return @bitCast(parsed);
}

pub fn isCalleeName(actual: []const u8, expected: []const u8) bool {
    const actual_name = symbolName(actual);
    if (std.mem.eql(u8, actual_name, expected)) return true;
    return false;
}
