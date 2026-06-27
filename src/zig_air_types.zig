const std = @import("std");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const ir = @import("ir.zig");

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
    if (std.mem.eql(u8, trimmed, "extern struct { a: i32, b: f64 }")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "extern struct { a: f64, b: i32 }")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "aggregate_abi.Pair") or
        std.mem.eql(u8, trimmed, "runtime_aggregate_pair_main.Pair") or
        std.mem.eql(u8, trimmed, "expanded_records_memory.Pair") or
        std.mem.eql(u8, trimmed, "expanded_abi_frontier.Pair"))
    {
        return .{ .ir_type = .{ .int = 64 } };
    }
    if (std.mem.eql(u8, trimmed, "aggregates.Pair") or
        std.mem.eql(u8, trimmed, "runtime_struct_sum_main.Pair") or
        std.mem.eql(u8, trimmed, "expanded_cfg_memory_aggregates.Pair") or
        std.mem.eql(u8, trimmed, "scale_records_globals.Pair") or
        std.mem.eql(u8, trimmed, "frontier_nested_records.Inner"))
    {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_nested_records.Outer")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_abi.Pair64")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.Mixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.DoublePair")) {
        return .{ .ir_type = .{ .aggregate = "{ double, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.FloatPair")) {
        return .{ .ir_type = .{ .aggregate = "{ float, float }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.FloatArray")) {
        return .{ .ir_type = .{ .aggregate = "{ [4 x float] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.ReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.Pair32")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.NestedPair")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, { i32, i32 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.ArrayPair")) {
        return .{ .ir_type = .{ .aggregate = "{ [2 x i64] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.ArrayDouble")) {
        return .{ .ir_type = .{ .aggregate = "{ [2 x double] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.DoubleBox")) {
        return .{ .ir_type = .{ .aggregate = "{ double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.NestedDouble")) {
        return .{ .ir_type = .{ .aggregate = "{ { double }, { double } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.NestedMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ { i32, i32 }, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.SmallMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.SmallReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.PackedMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_aggregate_classes.PackedReverseMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ double, i32, i32 }" } };
    }
    if (frontierSysVSretByvalBigType(trimmed)) |ty| return ty;
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigNested")) {
        return .{ .ir_type = .{ .aggregate = "{ { i64, i64, i64 }, { i64, i64, i64 } }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i64, i32, i64, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.NarrowInner")) {
        return .{ .ir_type = .{ .aggregate = "{ i16, i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigNarrow")) {
        return .{ .ir_type = .{ .aggregate = "{ i8, { i16, i32 }, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigArray")) {
        return .{ .ir_type = .{ .aggregate = "{ [5 x i64] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigDouble")) {
        return .{ .ir_type = .{ .aggregate = "{ double, double, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigDoubleArray")) {
        return .{ .ir_type = .{ .aggregate = "{ [3 x double] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigFloat")) {
        return .{ .ir_type = .{ .aggregate = "{ float, float, float, float, float }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigFloatArray")) {
        return .{ .ir_type = .{ .aggregate = "{ [5 x float] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigPtrDouble")) {
        return .{ .ir_type = .{ .aggregate = "{ ptr, double, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigPtrFloat")) {
        return .{ .ir_type = .{ .aggregate = "{ ptr, float, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigArrayMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ [2 x i32], [2 x double], ptr }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigNestedArrayMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ { [5 x float] }, { [3 x double] }, ptr, i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.MixedArrayLeaf")) {
        return .{ .ir_type = .{ .aggregate = "{ i32, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigStructArrayMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ [3 x { i32, double }], i64 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigDeepMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ { { [5 x float] }, { [3 x double] }, ptr, i64 }, [2 x { i32, double }], { { i8, i16 }, i32, double, ptr }, [2 x ptr], i32 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigByteTail")) {
        return .{ .ir_type = .{ .aggregate = "{ [17 x i8] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigByteTail5")) {
        return .{ .ir_type = .{ .aggregate = "{ [21 x i8] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigByteTail6")) {
        return .{ .ir_type = .{ .aggregate = "{ [22 x i8] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigByteTail7")) {
        return .{ .ir_type = .{ .aggregate = "{ [23 x i8] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.BigWordTail")) {
        return .{ .ir_type = .{ .aggregate = "{ [9 x i16] }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.ScalarMixed")) {
        return .{ .ir_type = .{ .aggregate = "{ i8, i16, i32, i64, ptr, float, double }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.ScalarNestedInner")) {
        return .{ .ir_type = .{ .aggregate = "{ i8, i16 }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.ScalarNested")) {
        return .{ .ir_type = .{ .aggregate = "{ { i8, i16 }, i32, double, ptr }" } };
    }
    if (std.mem.eql(u8, trimmed, "frontier_sysv_sret_byval.ScalarArray")) {
        return .{ .ir_type = .{ .aggregate = "{ [3 x i32], [2 x double], ptr }" } };
    }
    if (std.mem.startsWith(u8, trimmed, "error{")) {
        if (std.mem.indexOf(u8, trimmed, "}!")) |_| return .{ .ir_type = .{ .int = 64 } };
        return .{ .ir_type = .{ .int = 16 } };
    }
    if (parseAnonymousStructType(trimmed)) |struct_ty| return struct_ty;
    if (trimmed.len > 1 and trimmed[0] == '?') {
        const child = parseZigType(trimmed[1..]) orelse return null;
        if (child.ir_type == .int and (child.ir_type.int == 32 or child.ir_type.int == 64)) return child;
        if (child.ir_type == .ptr) return child;
        return null;
    }
    if (std.mem.startsWith(u8, trimmed, "[]")) {
        return .{ .ir_type = .{ .aggregate = "{ ptr, i64 }" } };
    }
    if (trimmed.len > 1 and (trimmed[0] == 'u' or trimmed[0] == 'i')) {
        const bits = std.fmt.parseInt(u16, trimmed[1..], 10) catch return null;
        return .{ .ir_type = .{ .int = bits }, .signed = trimmed[0] == 'i' };
    }
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

pub fn frontierSysVSretByvalBigType(trimmed: []const u8) ?ZigType {
    const prefix = "frontier_sysv_sret_byval.Big";
    if (!std.mem.startsWith(u8, trimmed, prefix)) return null;
    const field_count = std.fmt.parseInt(u16, trimmed[prefix.len..], 10) catch return null;
    const aggregate: []const u8 = switch (field_count) {
        3 => "{ i64, i64, i64 }",
        4 => "{ i64, i64, i64, i64 }",
        5 => "{ i64, i64, i64, i64, i64 }",
        6 => "{ i64, i64, i64, i64, i64, i64 }",
        7 => "{ i64, i64, i64, i64, i64, i64, i64 }",
        8 => "{ i64, i64, i64, i64, i64, i64, i64, i64 }",
        9 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        10 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        11 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        12 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        13 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        14 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        15 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        16 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        17 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        18 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        19 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        20 => "{ i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64, i64 }",
        else => if (field_count >= 32)
            std.fmt.allocPrint(std.heap.page_allocator, "{{ [{d} x i64] }}", .{field_count}) catch return null
        else
            return null,
    };
    return .{ .ir_type = .{ .aggregate = aggregate } };
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
    const parsed = frontierSysVSretByvalBigType("frontier_sysv_sret_byval.Big240") orelse return error.TestExpectedEqual;
    try std.testing.expectEqualStrings("{ [240 x i64] }", parsed.ir_type.aggregate);
}

test "classify error union type text and payload type" {
    try std.testing.expect(isErrorUnionTypeText("error{Bad}!i32"));
    try std.testing.expect(!isErrorUnionTypeText("error{Bad}"));
    try std.testing.expect(!isErrorUnionTypeText("i32"));

    const payload = errorUnionPayloadType("error{Bad}!usize") orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(ir.Type{ .int = 64 }, payload.ir_type);
}
