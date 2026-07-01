const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_model = @import("zig_air_model.zig");
const ir = @import("ir.zig");

pub fn lowerTypedUnionTagSemanticInstruction(self: anytype, instruction: air_export.TypedInstruction) !bool {
    switch (air_capabilities.unionTagSemanticOpForOpcode(instruction.opcode)) {
        .set_tag => try self.lowerTypedSetUnionTag(instruction),
        .get_tag => try self.lowerTypedGetUnionTag(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedSetUnionTag(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedUnionTagSetSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (summary.pointer_index >= self.synthetic_union_tag_slots.len) return air_model.LowerError.UnsupportedAir;
    const tag_ty: ir.Type = .{ .int = summary.bit_width };
    self.synthetic_union_tag_slots[summary.pointer_index] = .{
        .ty = .{ .ir_type = tag_ty },
        .value = .{ .int = summary.tag_index },
    };
}

pub fn lowerTypedGetUnionTag(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedUnionTagGetSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (summary.operand_index >= self.values.len) return air_model.LowerError.UnsupportedAir;
    const source = self.values[summary.operand_index] orelse return air_model.LowerError.UnsupportedAir;
    const expected_ty: ir.Type = .{ .int = summary.bit_width };
    if (!source.ty.ir_type.eql(expected_ty)) return air_model.LowerError.UnsupportedAir;
    self.values[instruction.index] = .{
        .ty = .{ .ir_type = expected_ty },
        .value = source.value,
    };
}
