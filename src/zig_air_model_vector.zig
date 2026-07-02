const std = @import("std");

const core = @import("zig_air_model_base.zig");
const air_export = @import("zig_air_export.zig");

pub const TypedShuffleOneSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    vector_len: u32,
    elem_bit_width: u32,
    mask: [8]u32,
    mask_len: usize,
};

pub const TypedSplatSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    vector_len: u32,
    elem_bit_width: u32,
};

pub const TypedReduceSummary = struct {
    instruction_index: u32,
    operand_index: u32,
    operation: []const u8,
    vector_len: u32,
    elem_bit_width: u32,
};

pub fn typedReduceSummary(instruction: air_export.TypedInstruction) ?TypedReduceSummary {
    if (!std.mem.eql(u8, instruction.opcode, "reduce") and !std.mem.eql(u8, instruction.opcode, "reduce_optimized")) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "reduce")) return null;
    if (instruction.operands.len != 1) return null;
    const contract = core.detail(instruction, "reduce_contract") orelse return null;
    if (!std.mem.eql(u8, contract, "zllvm-reduce-v1")) return null;
    if (core.detail(instruction, "unsupported_non_vector") != null) return null;
    const operation = core.detail(instruction, "reduce_operation") orelse return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const vector_len = parseU32Detail(instruction, "vector_len") orelse return null;
    const elem_bit_width = parseU32Detail(instruction, "elem_bit_width") orelse return null;
    if (vector_len == 0 or vector_len > 8) return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .operation = operation,
        .vector_len = vector_len,
        .elem_bit_width = elem_bit_width,
    };
}

pub fn typedSplatSummary(instruction: air_export.TypedInstruction) ?TypedSplatSummary {
    if (!std.mem.eql(u8, instruction.opcode, "splat")) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "ty_op")) return null;
    if (instruction.operands.len != 1) return null;
    const contract = core.detail(instruction, "splat_contract") orelse return null;
    if (!std.mem.eql(u8, contract, "zllvm-splat-v1")) return null;
    if (core.detail(instruction, "unsupported_non_vector") != null) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const vector_len = parseU32Detail(instruction, "vector_len") orelse return null;
    const elem_bit_width = parseU32Detail(instruction, "elem_bit_width") orelse return null;
    if (vector_len == 0 or vector_len > 8) return null;
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .vector_len = vector_len,
        .elem_bit_width = elem_bit_width,
    };
}

pub fn typedShuffleOneSummary(instruction: air_export.TypedInstruction) ?TypedShuffleOneSummary {
    if (!std.mem.eql(u8, instruction.opcode, "shuffle_one")) return null;
    if (!std.mem.eql(u8, instruction.data_kind, "shuffle_one")) return null;
    if (instruction.operands.len != 1) return null;
    const contract = core.detail(instruction, "shuffle_one_contract") orelse return null;
    if (!std.mem.eql(u8, contract, "zllvm-shuffle-one-v1")) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const vector_len = parseU32Detail(instruction, "vector_len") orelse return null;
    const elem_bit_width = parseU32Detail(instruction, "elem_bit_width") orelse return null;
    if (vector_len == 0 or vector_len > 8) return null;
    var mask: [8]u32 = undefined;
    for (0..vector_len) |index| {
        var key_buffer: [32]u8 = undefined;
        const kind_key = std.fmt.bufPrint(&key_buffer, "mask{}_kind", .{index}) catch return null;
        if (core.detail(instruction, kind_key)) |_| return null;
        const elem_key = std.fmt.bufPrint(&key_buffer, "mask{}_elem", .{index}) catch return null;
        const elem_index = parseU32Detail(instruction, elem_key) orelse return null;
        if (elem_index >= vector_len) return null;
        mask[index] = elem_index;
    }
    return .{
        .instruction_index = instruction.index,
        .operand_index = operand_index,
        .vector_len = vector_len,
        .elem_bit_width = elem_bit_width,
        .mask = mask,
        .mask_len = vector_len,
    };
}

fn parseU32Detail(instruction: air_export.TypedInstruction, key: []const u8) ?u32 {
    const text = core.detail(instruction, key) orelse return null;
    return std.fmt.parseInt(u32, text, 10) catch null;
}

test "typed splat summary accepts vector integer splat" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "11", .type_text = "u8" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "splat_contract", .value = "zllvm-splat-v1" },
        .{ .key = "vector_len", .value = "4" },
        .{ .key = "elem_bit_width", .value = "8" },
        .{ .key = "elem_type", .value = "int" },
        .{ .key = "operand_type", .value = "int" },
    };
    const summary = typedSplatSummary(.{
        .index = 12,
        .opcode = "splat",
        .result_type = "@Vector(4, u8)",
        .data_kind = "ty_op",
        .operands = &operands,
        .details = &details,
    }) orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(@as(u32, 11), summary.operand_index);
    try std.testing.expectEqual(@as(u32, 4), summary.vector_len);
    try std.testing.expectEqual(@as(u32, 8), summary.elem_bit_width);
}

test "typed reduce summary accepts vector add reduce" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "21", .type_text = "@Vector(4, u32)" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "reduce_contract", .value = "zllvm-reduce-v1" },
        .{ .key = "reduce_operation", .value = "Add" },
        .{ .key = "vector_len", .value = "4" },
        .{ .key = "elem_bit_width", .value = "32" },
        .{ .key = "elem_type", .value = "int" },
        .{ .key = "result_type", .value = "int" },
    };
    const summary = typedReduceSummary(.{
        .index = 22,
        .opcode = "reduce",
        .result_type = "u32",
        .data_kind = "reduce",
        .operands = &operands,
        .details = &details,
    }) orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(@as(u32, 21), summary.operand_index);
    try std.testing.expectEqualStrings("Add", summary.operation);
    try std.testing.expectEqual(@as(u32, 4), summary.vector_len);
    try std.testing.expectEqual(@as(u32, 32), summary.elem_bit_width);
}

test "typed reduce summary rejects non-vector operand" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "21", .type_text = "u32" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "reduce_contract", .value = "zllvm-reduce-v1" },
        .{ .key = "reduce_operation", .value = "Add" },
        .{ .key = "unsupported_non_vector", .value = "1" },
    };
    try std.testing.expect(typedReduceSummary(.{
        .index = 22,
        .opcode = "reduce",
        .result_type = "u32",
        .data_kind = "reduce",
        .operands = &operands,
        .details = &details,
    }) == null);
}

test "typed splat summary rejects unsupported non-vector result" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "11", .type_text = "u8" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "splat_contract", .value = "zllvm-splat-v1" },
        .{ .key = "unsupported_non_vector", .value = "1" },
    };
    try std.testing.expect(typedSplatSummary(.{
        .index = 12,
        .opcode = "splat",
        .result_type = "u8",
        .data_kind = "ty_op",
        .operands = &operands,
        .details = &details,
    }) == null);
}

test "typed shuffle_one summary accepts element mask" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "17", .type_text = "@Vector(4, u8)" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "shuffle_one_contract", .value = "zllvm-shuffle-one-v1" },
        .{ .key = "vector_len", .value = "4" },
        .{ .key = "elem_bit_width", .value = "8" },
        .{ .key = "mask0_elem", .value = "3" },
        .{ .key = "mask1_elem", .value = "2" },
        .{ .key = "mask2_elem", .value = "1" },
        .{ .key = "mask3_elem", .value = "0" },
    };
    const summary = typedShuffleOneSummary(.{
        .index = 18,
        .opcode = "shuffle_one",
        .result_type = "@Vector(4, u8)",
        .data_kind = "shuffle_one",
        .operands = &operands,
        .details = &details,
    }) orelse return error.TestExpectedEqual;
    try std.testing.expectEqual(@as(u32, 17), summary.operand_index);
    try std.testing.expectEqual(@as(u32, 4), summary.vector_len);
    try std.testing.expectEqual(@as(u32, 8), summary.elem_bit_width);
    try std.testing.expectEqual(@as(u32, 3), summary.mask[0]);
}

test "typed shuffle_one summary rejects value mask" {
    var operands = [_]air_export.TypedOperand{.{ .kind = "inst", .value = "17", .type_text = "@Vector(4, u8)" }};
    var details = [_]air_export.TypedDetail{
        .{ .key = "shuffle_one_contract", .value = "zllvm-shuffle-one-v1" },
        .{ .key = "vector_len", .value = "4" },
        .{ .key = "elem_bit_width", .value = "8" },
        .{ .key = "mask0_kind", .value = "value" },
        .{ .key = "mask0_value", .value = "1" },
        .{ .key = "mask1_elem", .value = "2" },
        .{ .key = "mask2_elem", .value = "1" },
        .{ .key = "mask3_elem", .value = "0" },
    };
    try std.testing.expect(typedShuffleOneSummary(.{
        .index = 18,
        .opcode = "shuffle_one",
        .result_type = "@Vector(4, u8)",
        .data_kind = "shuffle_one",
        .operands = &operands,
        .details = &details,
    }) == null);
}
