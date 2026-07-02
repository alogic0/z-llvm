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
