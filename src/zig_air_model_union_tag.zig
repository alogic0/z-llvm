const std = @import("std");
const air_export = @import("zig_air_export.zig");
const core = @import("zig_air_model_base.zig");
const typed_recognizers = @import("zig_air_model_typed_recognizers.zig");

pub const TypedUnionTagPayloadSwitchSummary = core.TypedUnionTagPayloadSwitchSummary;
pub const TypedUnionTagGetSummary = core.TypedUnionTagGetSummary;
pub const TypedUnionTagSetSummary = core.TypedUnionTagSetSummary;
pub const typedUnionTagPayloadSwitchSummary = typed_recognizers.typedUnionTagPayloadSwitchSummary;

pub fn typedUnionTagSetSummary(instruction: air_export.TypedInstruction) ?TypedUnionTagSetSummary {
    if (!std.mem.eql(u8, instruction.opcode, "set_union_tag")) return null;
    if (instruction.operands.len != 2) return null;
    const pointer_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const tag_index_text = core.detail(instruction, "tag_index") orelse return null;
    const bit_width_text = core.detail(instruction, "bit_width") orelse return null;
    const tag_index = std.fmt.parseInt(u32, tag_index_text, 10) catch return null;
    const bit_width = std.fmt.parseInt(u16, bit_width_text, 10) catch return null;
    switch (bit_width) {
        8, 16, 32, 64 => {},
        else => return null,
    }
    return .{
        .pointer_index = pointer_index,
        .tag_index = tag_index,
        .bit_width = bit_width,
    };
}

pub fn typedUnionTagGetSummary(instruction: air_export.TypedInstruction) ?TypedUnionTagGetSummary {
    if (!std.mem.eql(u8, instruction.opcode, "get_union_tag")) return null;
    if (instruction.operands.len != 1) return null;
    const operand_index = core.typedInstOperandIndex(instruction.operands[0]) orelse return null;
    const bit_width_text = core.detail(instruction, "bit_width") orelse return null;
    const bit_width = std.fmt.parseInt(u16, bit_width_text, 10) catch return null;
    switch (bit_width) {
        8, 16, 32, 64 => {},
        else => return null,
    }
    return .{
        .operand_index = operand_index,
        .bit_width = bit_width,
    };
}

test "typed AIR model recognizes set union tag summary" {
    var operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "3", .type_text = "*TaggedValue" },
        .{ .kind = "const", .value = "small", .type_text = "TaggedValue.Tag" },
    };
    var details = [_]air_export.TypedDetail{
        .{ .key = "tag_index", .value = "1" },
        .{ .key = "bit_width", .value = "8" },
    };
    const summary = typedUnionTagSetSummary(.{
        .index = 8,
        .opcode = "set_union_tag",
        .result_type = "void",
        .data_kind = "bin_op",
        .operands = @constCast(&operands),
        .details = @constCast(&details),
    }).?;
    try std.testing.expectEqual(@as(u32, 3), summary.pointer_index);
    try std.testing.expectEqual(@as(u32, 1), summary.tag_index);
    try std.testing.expectEqual(@as(u16, 8), summary.bit_width);

    details[0].value = "not-int";
    try std.testing.expect(typedUnionTagSetSummary(.{
        .index = 8,
        .opcode = "set_union_tag",
        .result_type = "void",
        .data_kind = "bin_op",
        .operands = @constCast(&operands),
        .details = @constCast(&details),
    }) == null);
}

test "typed AIR model recognizes get union tag summary" {
    var operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "7", .type_text = "TaggedValue" },
    };
    var details = [_]air_export.TypedDetail{
        .{ .key = "bit_width", .value = "8" },
    };
    const summary = typedUnionTagGetSummary(.{
        .index = 9,
        .opcode = "get_union_tag",
        .result_type = "TaggedValue.Tag",
        .data_kind = "ty_op",
        .operands = @constCast(&operands),
        .details = @constCast(&details),
    }).?;
    try std.testing.expectEqual(@as(u32, 7), summary.operand_index);
    try std.testing.expectEqual(@as(u16, 8), summary.bit_width);

    details[0].value = "24";
    try std.testing.expect(typedUnionTagGetSummary(.{
        .index = 9,
        .opcode = "get_union_tag",
        .result_type = "TaggedValue.Tag",
        .data_kind = "ty_op",
        .operands = @constCast(&operands),
        .details = @constCast(&details),
    }) == null);
}
