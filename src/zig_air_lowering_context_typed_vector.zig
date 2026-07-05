const std = @import("std");

const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const parseZigType = air_types.parseZigType;
const ownPrint = air_model.ownPrint;

pub fn lowerTypedVectorSemanticInstruction(
    self: anytype,
    instruction: air_export.TypedInstruction,
) !bool {
    switch (air_capabilities.vectorSemanticOpForOpcode(instruction.opcode)) {
        .reduce => try self.lowerTypedReduce(instruction),
        .splat => try self.lowerTypedSplat(instruction),
        .shuffle_one => try self.lowerTypedShuffleOne(instruction),
        .none => return false,
    }
    return true;
}

pub fn lowerTypedReduce(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedReduceSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (!std.mem.eql(u8, summary.operation, "Add")) return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const vector_ty = switch (source.ty.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(vector_ty.elem_ty.toType())) return air_model.LowerError.UnsupportedAir;
    if (summary.vector_len != vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const elem_bits = switch (vector_ty.elem_ty) {
        .int => |bits| bits,
        .float, .double, .ptr => return air_model.LowerError.UnsupportedAir,
    };
    if (summary.elem_bit_width != elem_bits) return air_model.LowerError.UnsupportedAir;
    if (vector_ty.len < 2 or vector_ty.len > 8) return air_model.LowerError.UnsupportedAir;

    var accumulator_name: []const u8 = undefined;
    for (0..vector_ty.len) |lane| {
        const lane_name = try ownPrint(self.module, "air{}_reduce_lane{}", .{ instruction.index, lane });
        try self.block.instructions.append(self.allocator, .{
            .result = lane_name,
            .kind = .{ .extractelement = .{
                .vector_ty = source.ty.ir_type,
                .vector = source.value,
                .index_ty = .{ .int = 64 },
                .index = .{ .int = @intCast(lane) },
            } },
        });
        if (lane == 0) {
            accumulator_name = lane_name;
            continue;
        }
        const add_name = if (lane + 1 == vector_ty.len)
            try self.resultName(instruction.index)
        else
            try ownPrint(self.module, "air{}_reduce_add{}", .{ instruction.index, lane });
        try self.block.instructions.append(self.allocator, .{
            .result = add_name,
            .kind = .{ .binary = .{
                .op = .add,
                .ty = result_type.ir_type,
                .lhs = .{ .named = accumulator_name },
                .rhs = .{ .named = lane_name },
            } },
        });
        accumulator_name = add_name;
    }
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = accumulator_name },
    };
}

pub fn lowerTypedSplat(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedSplatSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    const vector_ty = switch (result_type.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    if (summary.vector_len != vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const elem_bits = switch (vector_ty.elem_ty) {
        .int => |bits| bits,
        .float, .double, .ptr => return air_model.LowerError.UnsupportedAir,
    };
    if (summary.elem_bit_width != elem_bits) return air_model.LowerError.UnsupportedAir;
    if (!source.ty.ir_type.eql(vector_ty.elem_ty.toType())) return air_model.LowerError.UnsupportedAir;

    const seed_name = try ownPrint(self.module, "air{}_splat_seed", .{instruction.index});
    try self.block.instructions.append(self.allocator, .{
        .result = seed_name,
        .kind = .{ .insertelement = .{
            .vector_ty = result_type.ir_type,
            .vector = .undef,
            .value_ty = source.ty.ir_type,
            .value = source.value,
            .index_ty = .{ .int = 64 },
            .index = .{ .int = 0 },
        } },
    });

    const mask_text = try splatMaskText(self.module, vector_ty.len);
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .shufflevector = .{
            .lhs_ty = result_type.ir_type,
            .lhs = .{ .named = seed_name },
            .rhs_ty = result_type.ir_type,
            .rhs = .poison,
            .mask_ty = .{ .vector = .{ .len = vector_ty.len, .elem_ty = .{ .int = 32 } } },
            .mask = .{ .vector = mask_text },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

pub fn lowerTypedShuffleOne(self: anytype, instruction: air_export.TypedInstruction) !void {
    const summary = air_model.typedShuffleOneSummary(instruction) orelse return air_model.LowerError.UnsupportedAir;
    const source = try self.resolveTypedOperand(instruction, 0);
    const vector_ty = switch (source.ty.ir_type) {
        .vector => |vector_ty| vector_ty,
        .void, .int, .half, .float, .double, .x86_fp80, .fp128, .metadata, .ptr, .aggregate => return air_model.LowerError.UnsupportedAir,
    };
    const result_type = parseZigType(instruction.result_type) orelse return air_model.LowerError.UnsupportedAir;
    if (!result_type.ir_type.eql(source.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
    if (summary.vector_len != vector_ty.len) return air_model.LowerError.UnsupportedAir;
    const elem_bits = switch (vector_ty.elem_ty) {
        .int => |bits| bits,
        .float, .double, .ptr => return air_model.LowerError.UnsupportedAir,
    };
    if (summary.elem_bit_width != elem_bits) return air_model.LowerError.UnsupportedAir;
    if (summary.mask_len != vector_ty.len) return air_model.LowerError.UnsupportedAir;

    const mask_text = try shuffleMaskText(self.module, summary);
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .shufflevector = .{
            .lhs_ty = source.ty.ir_type,
            .lhs = source.value,
            .rhs_ty = source.ty.ir_type,
            .rhs = .poison,
            .mask_ty = .{ .vector = .{ .len = vector_ty.len, .elem_ty = .{ .int = 32 } } },
            .mask = .{ .vector = mask_text },
        } },
    });
    self.values[instruction.index] = .{
        .ty = result_type,
        .value = .{ .named = result_name },
    };
}

fn splatMaskText(module: *ir.Module, vector_len: u32) ![]const u8 {
    var buffer: std.ArrayList(u8) = .empty;
    defer buffer.deinit(module.allocator);
    try buffer.append(module.allocator, '<');
    for (0..vector_len) |index| {
        if (index != 0) try buffer.appendSlice(module.allocator, ", ");
        try buffer.appendSlice(module.allocator, "i32 0");
    }
    try buffer.append(module.allocator, '>');
    return ownPrint(module, "{s}", .{buffer.items});
}

fn shuffleMaskText(module: *ir.Module, summary: air_model.TypedShuffleOneSummary) ![]const u8 {
    var buffer: std.ArrayList(u8) = .empty;
    defer buffer.deinit(module.allocator);
    try buffer.append(module.allocator, '<');
    for (summary.mask[0..summary.mask_len], 0..) |lane, index| {
        if (index != 0) try buffer.appendSlice(module.allocator, ", ");
        const lane_text = try std.fmt.allocPrint(module.allocator, "i32 {}", .{lane});
        defer module.allocator.free(lane_text);
        try buffer.appendSlice(module.allocator, lane_text);
    }
    try buffer.append(module.allocator, '>');
    return ownPrint(module, "{s}", .{buffer.items});
}
