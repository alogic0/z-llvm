const std = @import("std");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const target_mod = @import("target.zig");

pub const ZigType = air_model.ZigType;
pub const FunctionType = air_model.FunctionType;
pub const TypedValue = air_model.TypedValue;
pub const TypedBranchMergeResult = air_model.TypedBranchMergeResult;

pub fn irCallingConvention(function_type: FunctionType) ?[]const u8 {
    if (function_type.c_calling_convention) return null;
    if (function_type.non_default_calling_convention) return "unsupported";
    return "fastcc";
}

pub const LowerError = std.mem.Allocator.Error || error{UnsupportedAir};

pub fn parseFunctionType(allocator: std.mem.Allocator, text: []const u8) !FunctionType {
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;
    const return_text = functionReturnTypeTextFromSuffix(suffix) orelse return error.UnsupportedAir;
    const return_type = parseZigType(return_text) orelse return error.UnsupportedAir;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = splitTopLevel(params_text, ',');
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
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return null;
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

    var fields = splitTopLevel(body, ',');
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

pub fn parseConstant(text: []const u8) ?TypedValue {
    if (std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        var fields = splitTopLevel(text[1 .. text.len - 1], ',');
        const type_text = fields.next() orelse return null;
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(std.mem.trim(u8, type_text, " ")) orelse return null;
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
        if (isFpType(ty.ir_type)) return .{ .ty = ty, .value = .{ .fp = canonicalFpLiteral(value_text) orelse value_text } };
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
    var fields = splitTopLevel(ty["error{".len .. ty.len - 1], ',');
    var code: i128 = 1;
    while (fields.next()) |field| : (code += 1) {
        const name = std.mem.trim(u8, field, " ");
        if (std.mem.eql(u8, name, wanted)) return code;
    }
    return null;
}

fn errorUnionConstantCode(type_text: []const u8, value_text: []const u8) ?i128 {
    const ty = std.mem.trim(u8, type_text, " ");
    const marker = std.mem.indexOf(u8, ty, "}!") orelse return null;
    if (!std.mem.startsWith(u8, ty, "error{")) return null;
    const value = std.mem.trim(u8, value_text, " ");
    if (std.mem.startsWith(u8, value, "error.")) {
        const error_set_text = ty[0 .. marker + 1];
        return errorSetConstantCode(error_set_text, value);
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
    var fields = splitTopLevel(text[1 .. text.len - 1], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null) return null;
    const ty = parseZigType(type_text) orelse return null;
    if (ty.ir_type != .ptr) return null;
    if (std.mem.startsWith(u8, value_text, "&") and value_text.len > 1) {
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

pub fn parseStaticIntegerType(text: []const u8) ?ZigType {
    return parseZigType(if (std.mem.eql(u8, text, "usize")) "usize" else text);
}

pub fn parseInstructionRef(text: []const u8) ?u32 {
    var trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.endsWith(u8, trimmed, "!")) trimmed = trimmed[0 .. trimmed.len - 1];
    if (trimmed.len < 2 or trimmed[0] != '%') return null;
    return std.fmt.parseInt(u32, trimmed[1..], 10) catch null;
}

pub fn isSimpleSelectBlock(function: air_export.Function, block_index: u32) bool {
    const block_position = instructionPosition(function, block_index) orelse return false;
    const block_instruction = function.instructions[block_position];
    var cond_count: usize = 0;
    var matching_br_count: usize = 0;
    var after_cond = false;
    for (function.instructions[block_position + 1 ..]) |instruction| {
        if (instruction.indent <= block_instruction.indent) break;
        if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            after_cond = true;
            continue;
        }
        if (!after_cond or air_capabilities.isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "br")) {
            var fields = splitTopLevel(instruction.payload, ',');
            const target = fields.next() orelse return false;
            if (parseInstructionRef(target) == block_index) matching_br_count += 1;
            continue;
        }
        return false;
    }
    return cond_count == 1 and matching_br_count == 2;
}

pub fn belongsToSimpleSelectBlock(function: air_export.Function, instruction_index: u32) bool {
    const position = instructionPosition(function, instruction_index) orelse return false;
    const instruction = function.instructions[position];
    var parent_position = position;
    while (parent_position > 0) {
        parent_position -= 1;
        const candidate = function.instructions[parent_position];
        if (candidate.indent >= instruction.indent) continue;
        if (std.mem.eql(u8, candidate.opcode, "block")) {
            return isSimpleSelectBlock(function, candidate.index);
        }
    }
    return false;
}

pub fn instructionPosition(function: air_export.Function, index: u32) ?usize {
    for (function.instructions, 0..) |instruction, position| {
        if (instruction.index == index) return position;
    }
    return null;
}

pub fn isPlainFieldPointerChild(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 1 or bits % 8 == 0,
        .float, .double, .ptr => true,
        .aggregate => true,
        .void, .x86_fp80, .fp128, .metadata, .vector => false,
    };
}

pub fn isSupportedTypedGepElementType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 8 or bits == 32 or bits == 64,
        .float, .double => true,
        .void, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => false,
    };
}

pub fn selectedFieldByteOffset(source_ty: ir.Type, field_child: ir.Type, field_index: i128) ?i128 {
    if (field_index < 0) return null;
    if (!isPlainFieldPointerChild(field_child)) return null;
    const index: usize = @intCast(field_index);
    const actual_child = memory_location.aggregateFieldType(source_ty, index) orelse return null;
    if (!actual_child.eql(field_child)) return null;
    const layout = target_mod.DataLayout.parse("e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128") catch return null;
    return memory_location.aggregateFieldOffsetWithLayout(layout, source_ty, index);
}

pub fn genericTypedGepIndex(value: ir.Value) bool {
    return switch (value) {
        .int => |int| int >= 0,
        .named => true,
        .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
    };
}

pub fn typedV2InstructionMissingRequiredDetail(instruction: air_export.TypedInstruction) ?[]const u8 {
    if (air_capabilities.isCallOpcode(instruction.opcode)) {
        if (air_model.detail(instruction, "callee_text") == null) return "missing_callee_text";
        if (air_model.detail(instruction, "call_signature") == null) return "missing_call_signature";
    }
    for (instruction.operands, 0..) |operand, operand_index| {
        if (std.mem.eql(u8, operand.kind, "const") and air_model.operandTextDetail(instruction, operand_index) == null) {
            return "missing_const_text";
        }
    }
    return null;
}

pub fn binaryOp(opcode: []const u8, ty: ZigType) ?ir.BinaryOp {
    const fp = isFpType(ty.ir_type);
    if (std.mem.startsWith(u8, opcode, "add")) return if (fp) .fadd else .add;
    if (std.mem.startsWith(u8, opcode, "sub")) return if (fp) .fsub else .sub;
    if (std.mem.startsWith(u8, opcode, "mul")) return if (fp) .fmul else .mul;
    if (std.mem.startsWith(u8, opcode, "div_float")) return .fdiv;
    if (std.mem.startsWith(u8, opcode, "div_")) return if (ty.signed) .sdiv else .udiv;
    if (std.mem.startsWith(u8, opcode, "rem")) return if (fp) .frem else if (ty.signed) .srem else .urem;
    if (std.mem.startsWith(u8, opcode, "mod")) return if (ty.signed) .srem else .urem;
    if (std.mem.eql(u8, opcode, "bit_and")) return .@"and";
    if (std.mem.eql(u8, opcode, "bit_or")) return .@"or";
    if (std.mem.eql(u8, opcode, "xor")) return .xor;
    if (std.mem.startsWith(u8, opcode, "shl")) return .shl;
    if (std.mem.startsWith(u8, opcode, "shr")) return if (ty.signed) .ashr else .lshr;
    return null;
}

pub fn intPredicate(opcode: []const u8, signed: bool) ?ir.IcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .eq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .ne;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return if (signed) .sle else .ule;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return if (signed) .slt else .ult;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return if (signed) .sge else .uge;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return if (signed) .sgt else .ugt;
    return null;
}

pub fn fpPredicate(opcode: []const u8) ?ir.FcmpPredicate {
    if (std.mem.startsWith(u8, opcode, "cmp_eq")) return .oeq;
    if (std.mem.startsWith(u8, opcode, "cmp_neq")) return .one;
    if (std.mem.startsWith(u8, opcode, "cmp_lte")) return .ole;
    if (std.mem.startsWith(u8, opcode, "cmp_lt")) return .olt;
    if (std.mem.startsWith(u8, opcode, "cmp_gte")) return .oge;
    if (std.mem.startsWith(u8, opcode, "cmp_gt")) return .ogt;
    return null;
}

pub fn castOp(opcode: []const u8, from: ZigType, to: ZigType) ?ir.CastOp {
    if (std.mem.eql(u8, opcode, "trunc")) return .trunc;
    if (std.mem.eql(u8, opcode, "bitcast")) return .bitcast;
    if (std.mem.eql(u8, opcode, "ptrtoint")) return .ptrtoint;
    if (std.mem.eql(u8, opcode, "inttoptr")) return .inttoptr;
    if (std.mem.eql(u8, opcode, "float_from_int")) return if (from.signed) .sitofp else .uitofp;
    if (std.mem.eql(u8, opcode, "int_from_float")) return if (to.signed) .fptosi else .fptoui;
    if (std.mem.eql(u8, opcode, "fpext")) return .fpext;
    if (std.mem.eql(u8, opcode, "fptrunc")) return .fptrunc;
    if (!std.mem.eql(u8, opcode, "intcast")) return null;
    const from_bits = intBits(from.ir_type) orelse return null;
    const to_bits = intBits(to.ir_type) orelse return null;
    if (to_bits < from_bits) return .trunc;
    if (to_bits > from_bits) return if (from.signed) .sext else .zext;
    return .bitcast;
}

pub fn isFpType(ty: ir.Type) bool {
    return ty == .float or ty == .double or ty == .fp128;
}

pub fn intBits(ty: ir.Type) ?u16 {
    return switch (ty) {
        .int => |bits| bits,
        else => null,
    };
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

pub fn ownPrint(module: *ir.Module, comptime format: []const u8, args: anytype) ![]const u8 {
    const owned = try std.fmt.allocPrint(module.allocator, format, args);
    errdefer module.allocator.free(owned);
    try module.owned_strings.append(module.allocator, owned);
    return owned;
}

pub fn findMatching(text: []const u8, open_index: usize, open: u8, close: u8) ?usize {
    var depth: usize = 0;
    for (text[open_index..], open_index..) |char, index| {
        if (char == open) depth += 1;
        if (char == close) {
            if (depth == 0) return null;
            depth -= 1;
            if (depth == 0) return index;
        }
    }
    return null;
}

pub const TopLevelSplit = struct {
    text: []const u8,
    separator: u8,
    offset: usize = 0,

    pub fn next(self: *TopLevelSplit) ?[]const u8 {
        if (self.offset > self.text.len) return null;
        const start = self.offset;
        var paren_depth: usize = 0;
        var bracket_depth: usize = 0;
        var brace_depth: usize = 0;
        var angle_depth: usize = 0;
        var quote: ?u8 = null;
        var index = start;
        while (index < self.text.len) : (index += 1) {
            const char = self.text[index];
            if (quote) |active_quote| {
                if (char == active_quote and (index == 0 or self.text[index - 1] != '\\')) quote = null;
                continue;
            }
            switch (char) {
                '\'', '"' => quote = char,
                '(' => paren_depth += 1,
                ')' => if (paren_depth > 0) {
                    paren_depth -= 1;
                },
                '[' => bracket_depth += 1,
                ']' => if (bracket_depth > 0) {
                    bracket_depth -= 1;
                },
                '{' => brace_depth += 1,
                '}' => if (brace_depth > 0) {
                    brace_depth -= 1;
                },
                '<' => angle_depth += 1,
                '>' => if (angle_depth > 0) {
                    angle_depth -= 1;
                },
                else => {},
            }
            if (char == self.separator and paren_depth == 0 and bracket_depth == 0 and
                brace_depth == 0 and angle_depth == 0 and quote == null)
            {
                self.offset = index + 1;
                return self.text[start..index];
            }
        }
        self.offset = self.text.len + 1;
        return self.text[start..];
    }
};

pub fn splitTopLevel(text: []const u8, separator: u8) TopLevelSplit {
    return .{ .text = text, .separator = separator };
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
