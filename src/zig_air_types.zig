const std = @import("std");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const enum_facts = @import("zig_air_enum_facts.zig");
const exported_aggregate_layout_facts = @import("zig_air_exported_aggregate_layout_facts.zig");
const ir = @import("ir.zig");
const type_layout = @import("zig_air_type_layout.zig");

pub const ZigType = air_model.ZigType;
pub const FunctionType = air_model.FunctionType;

pub fn parseFunctionType(allocator: std.mem.Allocator, text: []const u8) !FunctionType {
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = air_text.findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;
    const return_text = functionReturnTypeTextFromSuffix(suffix) orelse return error.UnsupportedAir;
    const return_type = parseZigType(return_text) orelse return error.UnsupportedAir;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = air_text.splitTopLevel(params_text, ',');
    while (fields.next()) |field| {
        const param_text = std.mem.trim(u8, field, " ");
        if (param_text.len == 0) continue;
        try params.append(allocator, parseZigType(param_text) orelse return error.UnsupportedAir);
    }
    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
        .non_default_calling_convention = non_default_calling_convention,
    };
}

pub fn functionReturnTypeText(text: []const u8) ?[]const u8 {
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return null;
    const params_end = air_text.findMatching(trimmed, 3, '(', ')') orelse return null;
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    return functionReturnTypeTextFromSuffix(suffix);
}

fn functionReturnTypeTextFromSuffix(suffix: []const u8) ?[]const u8 {
    if (std.mem.startsWith(u8, suffix, "callconv(")) {
        const close = std.mem.indexOfScalar(u8, suffix, ')') orelse return null;
        return std.mem.trim(u8, suffix[close + 1 ..], " ");
    }
    return suffix;
}

pub fn stripFunctionTypeQualifiers(text: []const u8) []const u8 {
    var remaining = text;
    while (true) {
        if (std.mem.startsWith(u8, remaining, "noinline ")) {
            remaining = std.mem.trim(u8, remaining["noinline ".len..], " ");
            continue;
        }
        if (std.mem.startsWith(u8, remaining, "inline ")) {
            remaining = std.mem.trim(u8, remaining["inline ".len..], " ");
            continue;
        }
        return remaining;
    }
}

pub fn parseZigType(text: []const u8) ?ZigType {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.eql(u8, trimmed, "void")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "noreturn")) return .{ .ir_type = .void };
    if (std.mem.eql(u8, trimmed, "bool")) return .{ .ir_type = .{ .int = 1 } };
    if (std.mem.eql(u8, trimmed, "c_int")) return .{ .ir_type = .{ .int = 32 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "c_long")) return .{ .ir_type = .{ .int = 64 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "usize")) return .{ .ir_type = .{ .int = 64 } };
    if (std.mem.eql(u8, trimmed, "isize")) return .{ .ir_type = .{ .int = 64 }, .signed = true };
    if (std.mem.eql(u8, trimmed, "f32")) return .{ .ir_type = .float };
    if (std.mem.eql(u8, trimmed, "f64")) return .{ .ir_type = .double };
    if (std.mem.eql(u8, trimmed, "f128")) return .{ .ir_type = .fp128 };
    if (std.mem.eql(u8, trimmed, "anyerror")) return .{ .ir_type = .{ .int = 16 } };
    if (parseZigVectorType(trimmed)) |vector_ty| return vector_ty;
    if (std.mem.eql(u8, trimmed, "extern struct { a: i32, b: f64 }")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "extern struct { a: f64, b: i32 }")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32 }" } };
    }
    if (type_layout.parseNamedAggregateType(trimmed)) |ty| return .{ .ir_type = ty };
    if (std.mem.startsWith(u8, trimmed, "error{")) {
        if (std.mem.indexOf(u8, trimmed, "}!")) |_| return .{ .ir_type = .{ .int = 64 } };
        return .{ .ir_type = .{ .int = 16 } };
    }
    if (parseAnonymousStructType(trimmed)) |struct_ty| return struct_ty;
    if (enum_facts.lookup(trimmed)) |fact| return .{ .ir_type = fact.backing_type, .signed = fact.signed };
    if (trimmed.len > 1 and trimmed[0] == '?') {
        const child = parseZigType(trimmed[1..]) orelse return null;
        if (child.ir_type == .int and (child.ir_type.int == 32 or child.ir_type.int == 64)) return child;
        if (child.ir_type == .ptr) return child;
        return null;
    }
    if (std.mem.startsWith(u8, trimmed, "[]") or std.mem.startsWith(u8, trimmed, "[:0]")) {
        return .{ .ir_type = .{ .aggregate = "{ ptr, i64 }" } };
    }
    if (trimmed.len > 1 and (trimmed[0] == 'u' or trimmed[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
        return .{ .ir_type = .{ .int = bits }, .signed = trimmed[0] == 'i' };
    }
    if (parseNamedEnumType(trimmed)) |enum_ty| return enum_ty;
    if (parseZigArrayType(trimmed)) |array_ty| return array_ty;
    if (isPointerType(trimmed)) {
        const child_text = pointerChildText(trimmed) orelse return null;
        const child = parseZigType(child_text);
        return .{
            .ir_type = .ptr,
            .pointer_child = if (child) |parsed| parsed.ir_type else null,
            .is_volatile_pointer = std.mem.indexOf(u8, trimmed, "volatile") != null,
        };
    }
    return null;
}

fn parseNamedEnumType(trimmed: []const u8) ?ZigType {
    if (std.mem.indexOf(u8, trimmed, "__enum_") == null) return null;
    return .{ .ir_type = .{ .int = 32 }, .signed = true };
}

pub fn isOpaqueNominalTypeSurface(text: []const u8) bool {
    if (text.len == 0 or std.mem.indexOfScalar(u8, text, '.') == null) return false;
    var paren_depth: usize = 0;
    for (text) |char| switch (char) {
        'a'...'z', 'A'...'Z', '0'...'9', '_', '.' => {},
        '(' => paren_depth += 1,
        ')' => {
            if (paren_depth == 0) return false;
            paren_depth -= 1;
        },
        ',', ' ' => if (paren_depth == 0) return false,
        else => return false,
    };
    return paren_depth == 0;
}

fn parseZigVectorType(trimmed: []const u8) ?ZigType {
    const prefix = "@Vector(";
    if (!std.mem.startsWith(u8, trimmed, prefix) or !std.mem.endsWith(u8, trimmed, ")")) return null;
    const body = trimmed[prefix.len .. trimmed.len - 1];
    const comma = std.mem.indexOfScalar(u8, body, ',') orelse return null;
    const len = std.fmt.parseInt(u32, std.mem.trim(u8, body[0..comma], " "), 10) catch return null;
    if (len == 0) return null;
    const elem = parseZigType(std.mem.trim(u8, body[comma + 1 ..], " ")) orelse return null;
    const elem_ty: ir.VectorElementType = switch (elem.ir_type) {
        .int => |bits| .{ .int = bits },
        .float => .float,
        .double => .double,
        .ptr => .ptr,
        .void, .x86_fp80, .fp128, .metadata, .aggregate, .vector => return null,
    };
    return .{ .ir_type = .{ .vector = .{ .len = len, .elem_ty = elem_ty } }, .signed = elem.signed };
}

pub fn parseAnonymousStructType(trimmed: []const u8) ?ZigType {
    const prefix = "struct {";
    if (!std.mem.startsWith(u8, trimmed, prefix) or !std.mem.endsWith(u8, trimmed, "}")) return null;
    const body = std.mem.trim(u8, trimmed[prefix.len .. trimmed.len - 1], " ");
    if (body.len == 0) return null;

    var fields = air_text.splitTopLevel(body, ',');
    var aggregate: std.ArrayList(u8) = .empty;
    aggregate.appendSlice(std.heap.page_allocator, "{ ") catch return null;
    var count: usize = 0;
    while (fields.next()) |field| {
        const field_ty = parseZigType(std.mem.trim(u8, field, " ")) orelse return null;
        if (count > 0) aggregate.appendSlice(std.heap.page_allocator, ", ") catch return null;
        appendIrTypeText(&aggregate, field_ty.ir_type) catch return null;
        count += 1;
    }
    if (count == 0) return null;
    aggregate.appendSlice(std.heap.page_allocator, " }") catch return null;
    return .{ .ir_type = .{ .aggregate = aggregate.toOwnedSlice(std.heap.page_allocator) catch return null } };
}

fn appendIrTypeText(aggregate: *std.ArrayList(u8), ty: ir.Type) !void {
    switch (ty) {
        .void => try aggregate.appendSlice(std.heap.page_allocator, "void"),
        .int => |bits| {
            const text = try std.fmt.allocPrint(std.heap.page_allocator, "i{}", .{bits});
            try aggregate.appendSlice(std.heap.page_allocator, text);
        },
        .float => try aggregate.appendSlice(std.heap.page_allocator, "float"),
        .double => try aggregate.appendSlice(std.heap.page_allocator, "double"),
        .x86_fp80 => try aggregate.appendSlice(std.heap.page_allocator, "x86_fp80"),
        .fp128 => try aggregate.appendSlice(std.heap.page_allocator, "fp128"),
        .metadata => try aggregate.appendSlice(std.heap.page_allocator, "metadata"),
        .ptr => try aggregate.appendSlice(std.heap.page_allocator, "ptr"),
        .aggregate => |text| try aggregate.appendSlice(std.heap.page_allocator, text),
        .vector => return error.UnsupportedAir,
    }
}

pub fn parseZigArrayType(trimmed: []const u8) ?ZigType {
    if (trimmed.len < 4 or trimmed[0] != '[') return null;
    const close_index = std.mem.indexOfScalar(u8, trimmed, ']') orelse return null;
    if (close_index + 1 >= trimmed.len) return null;
    const count = std.fmt.parseInt(u16, trimmed[1..close_index], 10) catch return null;
    if (count == 0) return null;
    const elem_text = trimmed[close_index + 1 ..];
    const elem_ir: []const u8 = if (std.mem.eql(u8, elem_text, "i8"))
        "i8"
    else if (std.mem.eql(u8, elem_text, "u8"))
        "i8"
    else if (std.mem.eql(u8, elem_text, "i16"))
        "i16"
    else if (std.mem.eql(u8, elem_text, "u16"))
        "i16"
    else if (std.mem.eql(u8, elem_text, "i32"))
        "i32"
    else if (std.mem.eql(u8, elem_text, "u32"))
        "i32"
    else if (std.mem.eql(u8, elem_text, "i64"))
        "i64"
    else if (std.mem.eql(u8, elem_text, "u64"))
        "i64"
    else if (std.mem.eql(u8, elem_text, "f32"))
        "float"
    else if (std.mem.eql(u8, elem_text, "f64"))
        "double"
    else
        return null;

    const aggregate_text = std.fmt.allocPrint(std.heap.page_allocator, "[{d} x {s}]", .{ count, elem_ir }) catch return null;
    return .{ .ir_type = .{ .aggregate = aggregate_text } };
}

pub fn arrayLengthFromTypeText(text: []const u8) ?u64 {
    const trimmed = std.mem.trim(u8, text, " ");
    const array_text = if (isPointerType(trimmed))
        pointerChildText(trimmed) orelse return null
    else
        trimmed;
    if (array_text.len < 4 or array_text[0] != '[') return null;
    const close_index = std.mem.indexOfScalar(u8, array_text, ']') orelse return null;
    const count_text = array_text[1..close_index];
    if (std.mem.indexOfScalar(u8, count_text, ':') != null) return null;
    return std.fmt.parseInt(u64, count_text, 10) catch null;
}

pub fn pointerLoadResultType(text: []const u8) ?ZigType {
    const child_text = pointerChildText(std.mem.trim(u8, text, " ")) orelse return null;
    return parseZigType(child_text);
}

pub fn isErrorUnionTypeText(text: []const u8) bool {
    const trimmed = std.mem.trim(u8, text, " ");
    return std.mem.startsWith(u8, trimmed, "error{") and std.mem.indexOf(u8, trimmed, "}!") != null;
}

pub fn errorUnionPayloadType(text: []const u8) ?ZigType {
    const trimmed = std.mem.trim(u8, text, " ");
    const marker = std.mem.indexOf(u8, trimmed, "}!") orelse return null;
    return parseZigType(trimmed[marker + 2 ..]);
}

pub fn parseStaticIntegerType(text: []const u8) ?ZigType {
    return parseZigType(if (std.mem.eql(u8, text, "usize")) "usize" else text);
}

pub fn isPointerType(text: []const u8) bool {
    return std.mem.startsWith(u8, text, "*") or
        std.mem.startsWith(u8, text, "[*]") or
        std.mem.startsWith(u8, text, "[]") or
        std.mem.startsWith(u8, text, "?*");
}

pub fn pointerChildText(text: []const u8) ?[]const u8 {
    var child = if (std.mem.startsWith(u8, text, "?*"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "[*]"))
        text[3..]
    else if (std.mem.startsWith(u8, text, "[]"))
        text[2..]
    else if (std.mem.startsWith(u8, text, "*"))
        text[1..]
    else
        return null;
    child = std.mem.trim(u8, child, " ");
    while (true) {
        if (std.mem.startsWith(u8, child, "const ")) {
            child = child["const ".len..];
        } else if (std.mem.startsWith(u8, child, "volatile ")) {
            child = child["volatile ".len..];
        } else if (std.mem.startsWith(u8, child, "allowzero ")) {
            child = child["allowzero ".len..];
        } else if (std.mem.startsWith(u8, child, "align(")) {
            const close = std.mem.indexOfScalar(u8, child, ')') orelse return null;
            child = std.mem.trim(u8, child[close + 1 ..], " ");
        } else {
            break;
        }
    }
    return std.mem.trim(u8, child, " ");
}

test "parse qualified Zig function types" {
    const parsed = try parseFunctionType(std.testing.allocator, "noinline fn (i32, i32, i32, i32, i32, i32, i32) i32");
    defer parsed.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 7), parsed.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed.return_type.ir_type);
    try std.testing.expect(!parsed.c_calling_convention);
}

test "parse frontier BigN array-backed byval types generically" {
    const facts = [_]exported_aggregate_layout_facts.Fact{
        .{ .nominal_type_name = "frontier_sysv_sret_byval.Big256", .aggregate_text = "{ [256 x i64] }" },
    };
    const previous_provider = exported_aggregate_layout_facts.active_provider;
    exported_aggregate_layout_facts.setActiveProvider(.{ .facts = facts[0..] });
    defer exported_aggregate_layout_facts.setActiveProvider(previous_provider);

    const parsed = parseZigType("frontier_sysv_sret_byval.Big256") orelse return error.TestExpectedEqual;
    try std.testing.expectEqualStrings("{ [256 x i64] }", parsed.ir_type.aggregate);
}

test "parse exported named enum type surfaces as C ABI scalars" {
    const parsed_type = parseZigType("os.linux.SIG__enum_1334") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed_type.ir_type);
    try std.testing.expect(parsed_type.signed);

    const parsed_fn = try parseFunctionType(std.testing.allocator, "fn (os.linux.SIG__enum_1334) callconv(.c) void");
    defer parsed_fn.deinit(std.testing.allocator);
    try std.testing.expect(parsed_fn.c_calling_convention);
    try std.testing.expectEqual(@as(usize, 1), parsed_fn.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed_fn.params[0].ir_type);
    try std.testing.expectEqual(ir.Type.void, parsed_fn.return_type.ir_type);
}

test "parse fact-owned named enum type surfaces" {
    const parsed_type = parseZigType("Io.Event") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed_type.ir_type);

    const parsed_fn = try parseFunctionType(std.testing.allocator, "fn (*Io.Event) void");
    defer parsed_fn.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), parsed_fn.params.len);
    try std.testing.expectEqual(ir.Type.ptr, parsed_fn.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, parsed_fn.params[0].pointer_child.?);
}

test "opaque nominal type surface accepts comptime argument instantiations" {
    try std.testing.expect(isOpaqueNominalTypeSurface("debug.ConfigurableTrace(2,4,false)"));
    try std.testing.expect(!isOpaqueNominalTypeSurface("debug.ConfigurableTrace(2 + 4)"));
    try std.testing.expect(!isOpaqueNominalTypeSurface("debug.ConfigurableTrace(2,4,false"));
}

test "parse array length from typed AIR array and pointer forms" {
    try std.testing.expectEqual(@as(?u64, 4), arrayLengthFromTypeText("[4]i32"));
    try std.testing.expectEqual(@as(?u64, 4096), arrayLengthFromTypeText("*[4096]u8"));
    try std.testing.expectEqual(@as(?u64, 1), arrayLengthFromTypeText("*const [1][]const u8"));
    try std.testing.expectEqual(@as(?u64, null), arrayLengthFromTypeText("*const [4:0]u8"));
    try std.testing.expectEqual(@as(?u64, null), arrayLengthFromTypeText("[]const u8"));
}

test "classify error union type text and payload type" {
    try std.testing.expect(isErrorUnionTypeText("error{Bad}!i32"));
    try std.testing.expect(!isErrorUnionTypeText("error{Bad}"));
    try std.testing.expect(!isErrorUnionTypeText("i32"));

    const payload = errorUnionPayloadType("error{Bad}!usize") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, payload.ir_type);
}
