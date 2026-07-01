const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");
const type_layout = @import("zig_air_type_layout.zig");

const parseZigType = air_types.parseZigType;

pub fn lowerTypedAggregateSemanticInstruction(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    switch (air_capabilities.aggregateSemanticOpForOpcode(instruction.opcode)) {
        .init => try self.lowerTypedAggregateInit(instruction),
        .field_val => try self.lowerTypedStructFieldVal(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedAggregateInit(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len == 0 or instruction.operands.len > 8) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (result_type.ir_type != .aggregate) return air_model.LowerError.UnsupportedAir;

    var aggregate_value: ir.Value = .undef;
    var field_index: usize = 0;
    while (field_index < instruction.operands.len) : (field_index += 1) {
        const operand = try self.resolveTypedOperand(instruction, field_index);
        const expected_ty = type_layout.fieldType(result_type.ir_type, field_index) orelse return air_model.LowerError.UnsupportedAir;
        if (!expected_ty.eql(operand.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
        const field_name = try air_model.ownPrint(self.module, "air{}_aggregate_field{}", .{ instruction.index, field_index });
        const index_text = air_model.aggregateIndexPathText(&.{field_index}) orelse return air_model.LowerError.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = field_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = result_type.ir_type,
                .aggregate = aggregate_value,
                .value_ty = operand.ty.ir_type,
                .value = operand.value,
                .indices = index_text,
            } },
        });
        aggregate_value = .{ .named = field_name };
    }
    if (type_layout.fieldType(result_type.ir_type, field_index) != null) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = aggregate_value,
    };
}

pub fn lowerTypedStructFieldVal(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const aggregate = try self.resolveTypedOperand(instruction, 0);
    if (aggregate.ty.ir_type != .aggregate) return air_model.LowerError.UnsupportedAir;
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const field_index = air_model.fieldIndexUsize(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const field_ty = type_layout.fieldType(aggregate.ty.ir_type, field_index) orelse return air_model.LowerError.UnsupportedAir;
    if (!field_ty.eql(result_type.ir_type)) return air_model.LowerError.UnsupportedAir;

    const result_name = try self.resultName(instruction.index);
    const index_text = air_model.aggregateIndexPathText(&.{field_index}) orelse return air_model.LowerError.UnsupportedAir;
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .extractvalue = .{
            .aggregate_ty = aggregate.ty.ir_type,
            .aggregate = aggregate.value,
            .indices = index_text,
            .result_ty = result_type.ir_type,
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}
