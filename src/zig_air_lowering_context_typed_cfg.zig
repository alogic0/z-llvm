const std = @import("std");
const air_export = @import("zig_air_export.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_text = @import("zig_air_text.zig");
const air_values = @import("zig_air_values.zig");
const air_types = @import("zig_air_types.zig");
const ir = @import("ir.zig");

const TypedBranchMergeResult = air_model.TypedBranchMergeResult;
const ZigType = air_model.ZigType;
const parseConstant = air_values.parseConstant;
const parseZigType = air_types.parseZigType;
const functionReturnTypeText = air_types.functionReturnTypeText;
const isErrorUnionTypeText = air_types.isErrorUnionTypeText;
const errorUnionPayloadType = air_types.errorUnionPayloadType;
const ownPrint = air_model.ownPrint;

pub fn lowerTypedCfgInstruction(self: anytype, instruction: air_export.TypedInstruction) !void {
    switch (air_capabilities.cfgLoweringOpForOpcode(instruction.opcode)) {
        .block => try self.lowerTypedBlock(instruction),
        .cond_br => {
            const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
            if (!view.terminalErrorUnionCondBr(instruction.index)) return air_model.LowerError.UnsupportedAir;
            try self.lowerTypedCondBrReturn(instruction);
        },
        .ret => try self.lowerTypedReturn(instruction),
        .unreach => self.block.terminator = .{ .@"unreachable" = {} },
        .none => return air_model.LowerError.UnsupportedAir,
    }
}

pub fn lowerTypedBlock(self: anytype, instruction: air_export.TypedInstruction) air_model.LowerError!void {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const block_body = view.body(.block, instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    if (try self.lowerTypedSwitchValueBlock(instruction, block_body)) return;
    const cond_instruction = try self.lowerTypedBlockBodyUntilCond(block_body);
    if (!air_capabilities.isCondBrOpcode(cond_instruction.opcode) or cond_instruction.operands.len != 1) {
        return air_model.LowerError.UnsupportedAir;
    }
    const cond = try self.resolveTypedOperand(cond_instruction, 0);
    if (!cond.ty.ir_type.eql(.{ .int = 1 })) return air_model.LowerError.UnsupportedAir;

    const then_body = view.body(.then_body, cond_instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    const else_body = view.body(.else_body, cond_instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    if (view.voidGuardBlock(instruction.index, then_body, else_body)) {
        const panic_body = if (view.noreturnBody(then_body)) then_body else else_body;
        const panic_is_then = view.noreturnBody(then_body);
        try self.lowerTypedVoidGuard(instruction, cond, panic_body, panic_is_then);
        return;
    }
    if (view.bodyHasReturn(then_body) and view.bodyHasReturn(else_body)) {
        try self.lowerTypedCondBodiesReturn(cond, cond_instruction.index, then_body, else_body);
        return;
    }
    if (try self.lowerTypedBranchReturnContinueValueBlock(instruction, cond, then_body, else_body)) {
        return;
    }
    if (try self.lowerTypedBranchReturnContinueBlock(instruction, cond, then_body, else_body)) {
        return;
    }
    if (self.typedBlockBranchValue(instruction.index, then_body)) |true_value| {
        if (self.typedBlockBranchValue(instruction.index, else_body)) |false_value| {
            if (true_value.ty.ir_type.eql(false_value.ty.ir_type)) {
                const result_name = try self.resultName(instruction.index);
                try self.block.instructions.append(self.allocator, .{
                    .result = result_name,
                    .kind = .{ .select = .{
                        .cond_ty = cond.ty.ir_type,
                        .cond = cond.value,
                        .ty = true_value.ty.ir_type,
                        .true_value = true_value.value,
                        .false_value = false_value.value,
                    } },
                });
                self.values[instruction.index] = .{
                    .ty = true_value.ty,
                    .value = .{ .named = result_name },
                };
                return;
            }
        } else |_| {}
    } else |_| {}

    try self.lowerTypedBranchMergeBlock(instruction, cond, then_body, else_body);
}

pub fn lowerTypedSwitchValueBlock(
    self: anytype,
    instruction: air_export.TypedInstruction,
    body: air_export.StructuredBody,
) air_model.LowerError!bool {
    const switch_instruction = try singleSwitchInstruction(self, body) orelse return false;
    const cond_index = switchInputIndexFromAirText(self.air_function.air_text, switch_instruction.index) orelse
        return air_model.LowerError.UnsupportedAir;
    if (cond_index >= self.values.len) return air_model.LowerError.UnsupportedAir;
    const cond = self.values[cond_index] orelse return air_model.LowerError.UnsupportedAir;
    if (!cond.ty.ir_type.eql(.{ .int = 32 }) and !cond.ty.ir_type.eql(.{ .int = 16 })) return air_model.LowerError.UnsupportedAir;
    const merge_type = self.typedBlockResultType(instruction) orelse return air_model.LowerError.UnsupportedAir;
    if (merge_type.ir_type == .void) return air_model.LowerError.UnsupportedAir;

    var arms: std.ArrayList(SwitchArm) = .empty;
    defer {
        for (arms.items) |*arm| arm.values.deinit(self.allocator);
        arms.deinit(self.allocator);
    }
    try collectSwitchCaseArms(self.allocator, &arms, self.air_function.air_text, switch_instruction.index);
    if (arms.items.len == 0) return air_model.LowerError.UnsupportedAir;
    for (arms.items) |arm| {
        for (arm.values.items) |case_value| {
            if (!case_value.ty.ir_type.eql(cond.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
        }
    }
    const has_else_arm = switchHasElseArm(self.air_function.air_text, switch_instruction.index);

    var branch_instructions: std.ArrayList(air_export.TypedInstruction) = .empty;
    defer branch_instructions.deinit(self.allocator);
    try self.collectBlockValueBranches(instruction.index, &branch_instructions);
    const expected_branches = arms.items.len + @intFromBool(has_else_arm);
    if (branch_instructions.items.len != expected_branches) return air_model.LowerError.UnsupportedAir;

    var labels: std.ArrayList([]const u8) = .empty;
    defer labels.deinit(self.allocator);
    for (arms.items, 0..) |_, arm_index| {
        try labels.append(self.allocator, try ownPrint(self.module, "block{}_case{}", .{ instruction.index, arm_index }));
    }
    const default_label = if (has_else_arm)
        try ownPrint(self.module, "block{}_default", .{instruction.index})
    else
        try ownPrint(self.module, "block{}_default_unreachable", .{instruction.index});
    if (has_else_arm) try labels.append(self.allocator, default_label);
    const merge_label = try ownPrint(self.module, "block{}_switch_merge", .{instruction.index});

    var switch_term: ir.SwitchTerminator = .{
        .cond_ty = cond.ty.ir_type,
        .cond = cond.value,
        .default_target = default_label,
        .cases = .empty,
    };
    errdefer switch_term.cases.deinit(self.allocator);
    for (arms.items, 0..) |arm, arm_index| {
        for (arm.values.items) |case_value| {
            try switch_term.cases.append(self.allocator, .{
                .value_ty = cond.ty.ir_type,
                .value = case_value.value,
                .target = labels.items[arm_index],
            });
        }
    }

    var finished = self.block.*;
    finished.terminator = .{ .@"switch" = switch_term };
    switch_term.cases = .empty;
    self.block.* = ir.BasicBlock.init(labels.items[0]);
    try self.function.blocks.append(self.allocator, finished);

    var phi: ir.PhiInst = .{ .ty = merge_type.ir_type, .incoming = .empty };
    errdefer phi.deinit(self.allocator);
    for (branch_instructions.items, 0..) |branch_instruction, branch_index| {
        const label = labels.items[branch_index];
        self.block.* = ir.BasicBlock.init(label);
        const branch_value = try self.lowerTypedSwitchBranchValue(instruction.index, branch_instruction, merge_type);
        try phi.incoming.append(self.allocator, .{ .value = branch_value.value.value, .block = branch_value.block_name });
        var branch_block = self.block.*;
        branch_block.terminator = .{ .br = .{ .target = merge_label } };
        try self.function.blocks.append(self.allocator, branch_block);
    }
    if (!has_else_arm) {
        var default_block = ir.BasicBlock.init(default_label);
        default_block.terminator = .{ .@"unreachable" = {} };
        try self.function.blocks.append(self.allocator, default_block);
    }

    self.block.* = ir.BasicBlock.init(merge_label);
    const result_name = try self.resultName(instruction.index);
    try self.block.instructions.append(self.allocator, .{
        .result = result_name,
        .kind = .{ .phi = phi },
    });
    self.values[instruction.index] = .{
        .ty = merge_type,
        .value = .{ .named = result_name },
    };
    return true;
}

fn singleSwitchInstruction(self: anytype, body: air_export.StructuredBody) air_model.LowerError!?air_export.TypedInstruction {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    var switch_instruction: ?air_export.TypedInstruction = null;
    for (body.instructions) |instruction_index| {
        const child = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (!air_capabilities.isSwitchBrOpcode(child.opcode)) return null;
        if (switch_instruction != null) return air_model.LowerError.UnsupportedAir;
        switch_instruction = child;
    }
    return switch_instruction;
}

pub fn collectBlockValueBranches(
    self: anytype,
    target_block: u32,
    branches: *std.ArrayList(air_export.TypedInstruction),
) !void {
    const structured_air_v2 = self.structured_air_v2 orelse return air_model.LowerError.UnsupportedAir;
    for (structured_air_v2.instructions) |candidate| {
        if (!air_capabilities.isBrOpcode(candidate.opcode) or candidate.operands.len != 2) continue;
        const target = air_model.blockTarget(candidate.operands[0]) orelse continue;
        if (target == target_block) try branches.append(self.allocator, candidate);
    }
}

const TypedSwitchBranchValue = struct {
    value: air_model.TypedValue,
    block_name: []const u8,
};

pub fn lowerTypedSwitchBranchValue(
    self: anytype,
    target_block: u32,
    branch_instruction: air_export.TypedInstruction,
    merge_type: ZigType,
) air_model.LowerError!TypedSwitchBranchValue {
    if (branch_instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    if (air_model.typedInstOperandIndex(branch_instruction.operands[1])) |value_index| {
        const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
        const value_instruction = view.instruction(value_index) orelse return air_model.LowerError.UnsupportedAir;
        if (air_capabilities.isBlockOpcode(value_instruction.opcode)) {
            return try self.lowerTypedNestedBlockSwitchBranchValue(value_instruction.index, merge_type);
        }
    }
    if (air_model.typedInstOperandIndex(branch_instruction.operands[1])) |value_index| {
        try self.lowerTypedValueDependency(value_index);
    }
    const value = (try self.resolveTypedBranchOperand(branch_instruction, 1)) orelse return air_model.LowerError.UnsupportedAir;
    return .{
        .value = try self.coerceTypedBranchValueToMerge(target_block, self.block.name, value, merge_type),
        .block_name = self.block.name,
    };
}

pub fn lowerTypedNestedBlockSwitchBranchValue(
    self: anytype,
    target_block: u32,
    merge_type: ZigType,
) air_model.LowerError!TypedSwitchBranchValue {
    var branch_instructions: std.ArrayList(air_export.TypedInstruction) = .empty;
    defer branch_instructions.deinit(self.allocator);
    try self.collectBlockValueBranches(target_block, &branch_instructions);
    if (branch_instructions.items.len != 1) return air_model.LowerError.UnsupportedAir;
    const branch_instruction = branch_instructions.items[0];
    if (branch_instruction.operands.len != 2) return air_model.LowerError.UnsupportedAir;
    if (air_model.typedInstOperandIndex(branch_instruction.operands[1])) |value_index| {
        try self.lowerTypedValueDependency(value_index);
    }
    const value = (try self.resolveTypedBranchOperand(branch_instruction, 1)) orelse return air_model.LowerError.UnsupportedAir;
    return .{
        .value = try self.coerceTypedBranchValueToMerge(target_block, self.block.name, value, merge_type),
        .block_name = self.block.name,
    };
}

pub fn lowerTypedValueDependency(self: anytype, instruction_index: u32) air_model.LowerError!void {
    if (instruction_index >= self.values.len) return air_model.LowerError.UnsupportedAir;
    if (self.values[instruction_index] != null) return;
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const instruction = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
    if (view.capability(instruction).status == .ignored_metadata) return;
    if (air_capabilities.cfgLoweringOpForOpcode(instruction.opcode) != .none) return air_model.LowerError.UnsupportedAir;
    for (instruction.operands) |operand| {
        const operand_index = air_model.typedInstOperandIndex(operand) orelse continue;
        try self.lowerTypedValueDependency(operand_index);
    }
    try self.lowerTypedInstruction(instruction);
}

pub fn lowerTypedCondBrReturn(self: anytype, instruction: air_export.TypedInstruction) air_model.LowerError!void {
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const cond = try self.resolveTypedOperand(instruction, 0);
    if (!cond.ty.ir_type.eql(.{ .int = 1 })) return air_model.LowerError.UnsupportedAir;
    const then_body = view.body(.then_body, instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    const else_body = view.body(.else_body, instruction.index) orelse return air_model.LowerError.UnsupportedAir;
    if (!view.bodyHasReturn(then_body) or !view.bodyHasReturn(else_body)) {
        return air_model.LowerError.UnsupportedAir;
    }

    try self.lowerTypedCondBodiesReturn(cond, instruction.index, then_body, else_body);
}

pub fn lowerTypedCondBodiesReturn(
    self: anytype,
    cond: anytype,
    instruction_index: u32,
    then_body: air_export.StructuredBody,
    else_body: air_export.StructuredBody,
) air_model.LowerError!void {
    const then_label = try ownPrint(self.module, "cond{}_then", .{instruction_index});
    const else_label = try ownPrint(self.module, "cond{}_else", .{instruction_index});
    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = cond.value,
        .then_target = then_label,
        .else_target = else_label,
    } };
    self.block.* = ir.BasicBlock.init(then_label);
    try self.function.blocks.append(self.allocator, finished);

    try self.lowerTypedBodyToTerminalBlock(then_label, then_body);
    try self.lowerTypedBodyToTerminalBlock(else_label, else_body);

    self.block.* = ir.BasicBlock.init(try ownPrint(self.module, "cond{}_after_unreachable", .{instruction_index}));
    self.block.terminator = .{ .@"unreachable" = {} };
}

pub fn lowerTypedBodyToTerminalBlock(
    self: anytype,
    label: []const u8,
    body: air_export.StructuredBody,
) air_model.LowerError!void {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    self.block.* = ir.BasicBlock.init(label);
    for (body.instructions) |instruction_index| {
        const child = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (self.block.terminator != null) return air_model.LowerError.UnsupportedAir;
        try self.lowerTypedInstruction(child);
    }
    if (self.block.terminator == null) return air_model.LowerError.UnsupportedAir;
    const terminal = self.block.*;
    try self.function.blocks.append(self.allocator, terminal);
}

pub fn lowerTypedBranchReturnContinueBlock(
    self: anytype,
    instruction: air_export.TypedInstruction,
    cond: anytype,
    then_body: air_export.StructuredBody,
    else_body: air_export.StructuredBody,
) air_model.LowerError!bool {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const then_returns = view.bodyHasReturn(then_body);
    const else_returns = view.bodyHasReturn(else_body);
    if (then_returns == else_returns) return false;

    const continue_body = if (then_returns) else_body else then_body;
    if (!view.voidBranchBody(continue_body, instruction.index)) return false;

    const return_body = if (then_returns) then_body else else_body;
    const return_label = try ownPrint(self.module, "block{}_return", .{instruction.index});
    const cont_label = try ownPrint(self.module, "block{}_cont", .{instruction.index});

    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = cond.value,
        .then_target = if (then_returns) return_label else cont_label,
        .else_target = if (then_returns) cont_label else return_label,
    } };
    self.block.* = ir.BasicBlock.init(return_label);
    try self.function.blocks.append(self.allocator, finished);

    for (return_body.instructions) |return_index| {
        const child = view.instruction(return_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        try self.lowerTypedInstruction(child);
        if (self.block.terminator != null and !air_capabilities.isReturnOpcode(child.opcode)) {
            return air_model.LowerError.UnsupportedAir;
        }
    }
    if (self.block.terminator == null) return air_model.LowerError.UnsupportedAir;
    const return_block = self.block.*;
    self.block.* = ir.BasicBlock.init(cont_label);
    try self.function.blocks.append(self.allocator, return_block);
    return true;
}

pub fn lowerTypedBranchReturnContinueValueBlock(
    self: anytype,
    instruction: air_export.TypedInstruction,
    cond: anytype,
    then_body: air_export.StructuredBody,
    else_body: air_export.StructuredBody,
) air_model.LowerError!bool {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const then_returns = view.bodyHasReturn(then_body);
    const else_returns = view.bodyHasReturn(else_body);
    if (then_returns == else_returns) return false;

    const merge_type = self.typedBlockResultType(instruction) orelse return false;
    if (merge_type.ir_type == .void) return false;

    const continue_body = if (then_returns) else_body else then_body;
    if (view.voidBranchBody(continue_body, instruction.index)) return false;
    const return_body = if (then_returns) then_body else else_body;
    const return_label = try ownPrint(self.module, "block{}_return", .{instruction.index});
    const cont_label = try ownPrint(self.module, "block{}_cont", .{instruction.index});

    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = cond.value,
        .then_target = if (then_returns) return_label else cont_label,
        .else_target = if (then_returns) cont_label else return_label,
    } };
    self.block.* = ir.BasicBlock.init(return_label);
    try self.function.blocks.append(self.allocator, finished);

    try self.lowerTypedBodyToTerminalBlock(return_label, return_body);

    self.block.* = ir.BasicBlock.init(cont_label);
    const continue_value = try self.lowerTypedBranchBodyToOpenContinuation(
        instruction.index,
        continue_body,
        merge_type,
    );
    self.values[instruction.index] = continue_value;
    return true;
}

pub fn lowerTypedVoidGuard(
    self: anytype,
    instruction: air_export.TypedInstruction,
    cond: anytype,
    panic_body: air_export.StructuredBody,
    panic_is_then: bool,
) air_model.LowerError!void {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const panic_label = try ownPrint(self.module, "guard{}_panic", .{instruction.index});
    const cont_label = try ownPrint(self.module, "guard{}_cont", .{instruction.index});

    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = cond.value,
        .then_target = if (panic_is_then) panic_label else cont_label,
        .else_target = if (panic_is_then) cont_label else panic_label,
    } };
    self.block.* = ir.BasicBlock.init(panic_label);
    try self.function.blocks.append(self.allocator, finished);

    for (panic_body.instructions) |panic_index| {
        const child = view.instruction(panic_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (air_capabilities.isUnreachOpcode(child.opcode)) continue;
        try self.lowerTypedInstruction(child);
    }
    var panic_block = self.block.*;
    panic_block.terminator = .{ .@"unreachable" = {} };
    self.block.* = ir.BasicBlock.init(cont_label);
    try self.function.blocks.append(self.allocator, panic_block);
}

pub fn typedBlockBranchValue(
    self: anytype,
    target_block: u32,
    body: air_export.StructuredBody,
) air_model.LowerError!air_model.TypedValue {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    const branch_index = view.singleSemanticInstruction(body) orelse return air_model.LowerError.UnsupportedAir;
    const branch_instruction = view.instruction(branch_index) orelse return air_model.LowerError.UnsupportedAir;
    if (!air_capabilities.isBrOpcode(branch_instruction.opcode) or branch_instruction.operands.len != 2) {
        return air_model.LowerError.UnsupportedAir;
    }
    const target_operand = branch_instruction.operands[0];
    const target = air_model.blockTarget(target_operand) orelse return air_model.LowerError.UnsupportedAir;
    if (target != target_block) return air_model.LowerError.UnsupportedAir;
    return self.resolveTypedOperand(branch_instruction, 1);
}

pub fn lowerTypedBranchMergeBlock(
    self: anytype,
    instruction: air_export.TypedInstruction,
    cond: anytype,
    then_body: air_export.StructuredBody,
    else_body: air_export.StructuredBody,
) air_model.LowerError!void {
    const then_label = try ownPrint(self.module, "block{}_then", .{instruction.index});
    const else_label = try ownPrint(self.module, "block{}_else", .{instruction.index});
    const merge_label = try ownPrint(self.module, "block{}_merge", .{instruction.index});
    const merge_type_or_null: ?ZigType = if (parseZigType(instruction.result_type)) |merge_type|
        if (merge_type.ir_type == .void) null else merge_type
    else blk: {
        const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse break :blk null;
        if (isErrorUnionTypeText(return_type_text) and self.function_type.return_type.ir_type.eql(.{ .int = 64 })) {
            break :blk self.function_type.return_type;
        }
        break :blk null;
    };

    const entry_error_union_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_error_union_slots.len);
    defer self.allocator.free(entry_error_union_slots);
    @memcpy(entry_error_union_slots, self.synthetic_error_union_slots);
    const true_error_union_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_error_union_slots.len);
    defer self.allocator.free(true_error_union_slots);
    const false_error_union_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_error_union_slots.len);
    defer self.allocator.free(false_error_union_slots);
    const entry_union_tag_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_union_tag_slots.len);
    defer self.allocator.free(entry_union_tag_slots);
    @memcpy(entry_union_tag_slots, self.synthetic_union_tag_slots);
    const true_union_tag_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_union_tag_slots.len);
    defer self.allocator.free(true_union_tag_slots);
    const false_union_tag_slots = try self.allocator.alloc(?air_model.TypedValue, self.synthetic_union_tag_slots.len);
    defer self.allocator.free(false_union_tag_slots);

    var finished = self.block.*;
    finished.terminator = .{ .condbr = .{
        .cond_ty = .{ .int = 1 },
        .cond = cond.value,
        .then_target = then_label,
        .else_target = else_label,
    } };
    self.block.* = ir.BasicBlock.init(then_label);
    try self.function.blocks.append(self.allocator, finished);

    @memcpy(self.synthetic_error_union_slots, entry_error_union_slots);
    @memcpy(self.synthetic_union_tag_slots, entry_union_tag_slots);
    const true_result = try self.lowerTypedBranchBodyToMerge(instruction.index, then_body, then_label, merge_label, merge_type_or_null);
    @memcpy(true_error_union_slots, self.synthetic_error_union_slots);
    @memcpy(true_union_tag_slots, self.synthetic_union_tag_slots);
    @memcpy(self.synthetic_error_union_slots, entry_error_union_slots);
    @memcpy(self.synthetic_union_tag_slots, entry_union_tag_slots);
    const false_result = try self.lowerTypedBranchBodyToMerge(instruction.index, else_body, else_label, merge_label, merge_type_or_null);
    @memcpy(false_error_union_slots, self.synthetic_error_union_slots);
    @memcpy(false_union_tag_slots, self.synthetic_union_tag_slots);

    self.block.* = ir.BasicBlock.init(merge_label);
    if (true_result.value) |true_branch| {
        const false_branch = false_result.value orelse return air_model.LowerError.UnsupportedAir;
        if (!true_branch.ty.ir_type.eql(false_branch.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        var phi: ir.PhiInst = .{ .ty = true_branch.ty.ir_type, .incoming = .empty };
        errdefer phi.deinit(self.allocator);
        try phi.incoming.append(self.allocator, .{ .value = true_branch.value, .block = true_result.predecessor_label });
        try phi.incoming.append(self.allocator, .{ .value = false_branch.value, .block = false_result.predecessor_label });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .phi = phi },
        });
        self.values[instruction.index] = .{
            .ty = true_branch.ty,
            .value = .{ .named = result_name },
        };
    } else if (false_result.value != null) {
        return air_model.LowerError.UnsupportedAir;
    }
    try self.mergeSyntheticErrorUnionSlots(
        instruction.index,
        true_result.predecessor_label,
        false_result.predecessor_label,
        true_error_union_slots,
        false_error_union_slots,
    );
    try self.mergeSyntheticUnionTagSlots(
        instruction.index,
        true_result.predecessor_label,
        false_result.predecessor_label,
        true_union_tag_slots,
        false_union_tag_slots,
    );
}

pub fn mergeSyntheticErrorUnionSlots(
    self: anytype,
    block_index: u32,
    true_predecessor_label: []const u8,
    false_predecessor_label: []const u8,
    true_slots: []const ?air_model.TypedValue,
    false_slots: []const ?air_model.TypedValue,
) air_model.LowerError!void {
    if (true_slots.len != self.synthetic_error_union_slots.len or
        false_slots.len != self.synthetic_error_union_slots.len)
        return air_model.LowerError.UnsupportedAir;
    for (self.synthetic_error_union_slots, 0..) |*merged_slot, slot_index| {
        const true_slot = true_slots[slot_index];
        const false_slot = false_slots[slot_index];
        if (true_slot) |true_value| {
            const false_value = false_slot orelse return air_model.LowerError.UnsupportedAir;
            if (!true_value.ty.ir_type.eql(false_value.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
            if (true_value.value.eql(false_value.value)) {
                merged_slot.* = true_value;
                continue;
            }
            const result_name = try ownPrint(self.module, "air{}_slot{}_merge", .{ block_index, slot_index });
            var phi: ir.PhiInst = .{ .ty = true_value.ty.ir_type, .incoming = .empty };
            errdefer phi.deinit(self.allocator);
            try phi.incoming.append(self.allocator, .{ .value = true_value.value, .block = true_predecessor_label });
            try phi.incoming.append(self.allocator, .{ .value = false_value.value, .block = false_predecessor_label });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .phi = phi },
            });
            merged_slot.* = .{
                .ty = true_value.ty,
                .value = .{ .named = result_name },
            };
        } else {
            if (false_slot != null) return air_model.LowerError.UnsupportedAir;
            merged_slot.* = null;
        }
    }
}

pub fn mergeSyntheticUnionTagSlots(
    self: anytype,
    block_index: u32,
    true_predecessor_label: []const u8,
    false_predecessor_label: []const u8,
    true_slots: []const ?air_model.TypedValue,
    false_slots: []const ?air_model.TypedValue,
) air_model.LowerError!void {
    if (true_slots.len != self.synthetic_union_tag_slots.len or
        false_slots.len != self.synthetic_union_tag_slots.len)
        return air_model.LowerError.UnsupportedAir;
    for (self.synthetic_union_tag_slots, 0..) |*merged_slot, slot_index| {
        const true_slot = true_slots[slot_index];
        const false_slot = false_slots[slot_index];
        if (true_slot) |true_value| {
            const false_value = false_slot orelse return air_model.LowerError.UnsupportedAir;
            if (!true_value.ty.ir_type.eql(false_value.ty.ir_type)) return air_model.LowerError.UnsupportedAir;
            if (true_value.value.eql(false_value.value)) {
                merged_slot.* = true_value;
                continue;
            }
            const result_name = try ownPrint(self.module, "air{}_union_slot{}_merge", .{ block_index, slot_index });
            var phi: ir.PhiInst = .{ .ty = true_value.ty.ir_type, .incoming = .empty };
            errdefer phi.deinit(self.allocator);
            try phi.incoming.append(self.allocator, .{ .value = true_value.value, .block = true_predecessor_label });
            try phi.incoming.append(self.allocator, .{ .value = false_value.value, .block = false_predecessor_label });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .phi = phi },
            });
            merged_slot.* = .{
                .ty = true_value.ty,
                .value = .{ .named = result_name },
            };
        } else {
            if (false_slot != null) return air_model.LowerError.UnsupportedAir;
            merged_slot.* = null;
        }
    }
}

pub fn typedBlockResultType(self: anytype, instruction: air_export.TypedInstruction) ?ZigType {
    if (parseZigType(instruction.result_type)) |merge_type| return merge_type;
    if (blockLineResultType(self.air_function.air_text, instruction.index)) |merge_type| return merge_type;
    if (switchLineResultType(self.air_function.air_text, instruction.index)) |merge_type| return merge_type;
    const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse return null;
    if (isErrorUnionTypeText(return_type_text) and self.function_type.return_type.ir_type.eql(.{ .int = 64 })) {
        return self.function_type.return_type;
    }
    return null;
}

pub fn lowerTypedBranchBodyToMerge(
    self: anytype,
    target_block: u32,
    body: air_export.StructuredBody,
    label: []const u8,
    merge_label: []const u8,
    merge_type: ?ZigType,
) air_model.LowerError!TypedBranchMergeResult {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    self.block.* = ir.BasicBlock.init(label);
    var branch_value: ?air_model.TypedValue = null;
    var saw_branch = false;
    for (body.instructions) |instruction_index| {
        const child = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (air_capabilities.isBrOpcode(child.opcode)) {
            if (child.operands.len != 2) return air_model.LowerError.UnsupportedAir;
            const target = air_model.blockTarget(child.operands[0]) orelse return air_model.LowerError.UnsupportedAir;
            if (target != target_block) return air_model.LowerError.UnsupportedAir;
            branch_value = try self.resolveTypedBranchOperand(child, 1);
            saw_branch = true;
            continue;
        }
        if (saw_branch) return air_model.LowerError.UnsupportedAir;
        try self.lowerTypedInstruction(child);
    }
    if (!saw_branch) return air_model.LowerError.UnsupportedAir;
    if (branch_value) |value| {
        if (merge_type) |target_type| {
            branch_value = try self.coerceTypedBranchValueToMerge(target_block, label, value, target_type);
        }
    }
    var branch_block = self.block.*;
    branch_block.terminator = .{ .br = .{ .target = merge_label } };
    const predecessor_label = branch_block.name;
    self.block.* = ir.BasicBlock.init(merge_label);
    try self.function.blocks.append(self.allocator, branch_block);
    return .{
        .value = branch_value,
        .predecessor_label = predecessor_label,
    };
}

pub fn lowerTypedBranchBodyToOpenContinuation(
    self: anytype,
    target_block: u32,
    body: air_export.StructuredBody,
    merge_type: ZigType,
) air_model.LowerError!air_model.TypedValue {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    var branch_value: ?air_model.TypedValue = null;
    var saw_branch = false;
    for (body.instructions) |instruction_index| {
        const child = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (air_capabilities.isBrOpcode(child.opcode)) {
            if (child.operands.len != 2) return air_model.LowerError.UnsupportedAir;
            const target = air_model.blockTarget(child.operands[0]) orelse return air_model.LowerError.UnsupportedAir;
            if (target != target_block) return air_model.LowerError.UnsupportedAir;
            branch_value = (try self.resolveTypedBranchOperand(child, 1)) orelse return air_model.LowerError.UnsupportedAir;
            saw_branch = true;
            continue;
        }
        if (saw_branch) return air_model.LowerError.UnsupportedAir;
        try self.lowerTypedInstruction(child);
    }
    const value = if (saw_branch) branch_value orelse return air_model.LowerError.UnsupportedAir else return air_model.LowerError.UnsupportedAir;
    return try self.coerceTypedBranchValueToMerge(target_block, self.block.name, value, merge_type);
}

pub fn coerceTypedBranchValueToMerge(
    self: anytype,
    target_block: u32,
    label: []const u8,
    value: air_model.TypedValue,
    target_type: ZigType,
) air_model.LowerError!air_model.TypedValue {
    if (value.ty.ir_type.eql(target_type.ir_type)) return value;
    if (!target_type.ir_type.eql(.{ .int = 64 })) return air_model.LowerError.UnsupportedAir;
    const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse return air_model.LowerError.UnsupportedAir;
    if (!isErrorUnionTypeText(return_type_text)) return air_model.LowerError.UnsupportedAir;
    const payload_type = errorUnionPayloadType(return_type_text) orelse return air_model.LowerError.UnsupportedAir;
    const prefix = try ownPrint(self.module, "air{}_{s}", .{ target_block, label });
    if (value.ty.ir_type.eql(payload_type.ir_type)) {
        const wrapped_name = try self.encodeErrorUnionPayloadWithPrefix(prefix, value.value);
        return .{ .ty = target_type, .value = .{ .named = wrapped_name } };
    }
    if (value.ty.ir_type.eql(.{ .int = 16 })) {
        try self.block.instructions.append(self.allocator, .{
            .result = prefix,
            .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = .{ .int = 16 },
                .value = value.value,
                .to_ty = .{ .int = 64 },
            } },
        });
        return .{ .ty = target_type, .value = .{ .named = prefix } };
    }
    return air_model.LowerError.UnsupportedAir;
}

pub fn resolveTypedBranchOperand(
    self: anytype,
    instruction: air_export.TypedInstruction,
    operand_index: usize,
) air_model.LowerError!?air_model.TypedValue {
    if (operand_index >= instruction.operands.len) return air_model.LowerError.UnsupportedAir;
    if (air_model.typedVoidConstOperand(instruction, operand_index) orelse return air_model.LowerError.UnsupportedAir) {
        return null;
    }
    return try self.resolveTypedOperand(instruction, operand_index);
}

pub fn lowerTypedBlockBodyUntilCond(
    self: anytype,
    body: air_export.StructuredBody,
) air_model.LowerError!air_export.TypedInstruction {
    const view = self.typed_view orelse return air_model.LowerError.UnsupportedAir;
    var cond_instruction: ?air_export.TypedInstruction = null;
    for (body.instructions) |instruction_index| {
        const child = view.instruction(instruction_index) orelse return air_model.LowerError.UnsupportedAir;
        if (view.capability(child).status == .ignored_metadata) continue;
        if (air_capabilities.isCondBrOpcode(child.opcode)) {
            if (cond_instruction != null) return air_model.LowerError.UnsupportedAir;
            cond_instruction = child;
            continue;
        }
        if (cond_instruction != null) return air_model.LowerError.UnsupportedAir;
        try self.lowerTypedInstruction(child);
    }
    return cond_instruction orelse air_model.LowerError.UnsupportedAir;
}

pub fn lowerTypedReturn(self: anytype, instruction: air_export.TypedInstruction) !void {
    if (self.function_type.return_type.ir_type == .void) {
        self.block.terminator = .{ .ret = .{ .ty = .void } };
        return;
    }
    if (instruction.operands.len != 1) return air_model.LowerError.UnsupportedAir;
    var value = try self.resolveTypedOperand(instruction, 0);
    if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) {
        const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse return air_model.LowerError.UnsupportedAir;
        if (!isErrorUnionTypeText(return_type_text) or
            !self.function_type.return_type.ir_type.eql(.{ .int = 64 }))
        {
            return air_model.LowerError.UnsupportedAir;
        }
        const payload_type = errorUnionPayloadType(return_type_text) orelse return air_model.LowerError.UnsupportedAir;
        if (value.ty.ir_type.eql(payload_type.ir_type)) {
            const wrapped_name = try self.encodeErrorUnionPayload(instruction.index, value.value);
            value = .{ .ty = self.function_type.return_type, .value = .{ .named = wrapped_name } };
        } else if (value.ty.ir_type.eql(.{ .int = 16 })) {
            const wrapped_name = try self.resultName(instruction.index);
            try self.block.instructions.append(self.allocator, .{
                .result = wrapped_name,
                .kind = .{ .cast = .{
                    .op = .zext,
                    .from_ty = .{ .int = 16 },
                    .value = value.value,
                    .to_ty = .{ .int = 64 },
                } },
            });
            value = .{ .ty = self.function_type.return_type, .value = .{ .named = wrapped_name } };
        } else {
            return air_model.LowerError.UnsupportedAir;
        }
    }
    self.block.terminator = .{ .ret = .{
        .ty = self.function_type.return_type.ir_type,
        .value = value.value,
    } };
}

fn switchInputIndexFromAirText(function_air_text: []const u8, switch_index: u32) ?u32 {
    const line = switchLine(function_air_text, switch_index) orelse return null;
    const open = std.mem.indexOfScalar(u8, line, '(') orelse return null;
    const close = std.mem.indexOfScalarPos(u8, line, open + 1, ',') orelse
        std.mem.indexOfScalarPos(u8, line, open + 1, ')') orelse return null;
    return air_text.instructionRef(std.mem.trim(u8, line[open + 1 .. close], " !"));
}

const SwitchArm = struct {
    values: std.ArrayList(air_model.TypedValue),
};

fn collectSwitchCaseArms(
    allocator: std.mem.Allocator,
    arms: *std.ArrayList(SwitchArm),
    function_air_text: []const u8,
    switch_index: u32,
) !void {
    const text = switchText(function_air_text, switch_index) orelse return air_model.LowerError.UnsupportedAir;
    var offset: usize = 0;
    while (std.mem.indexOfPos(u8, text, offset, "[")) |start| {
        const close = std.mem.indexOfPos(u8, text, start + 1, "] =>") orelse return air_model.LowerError.UnsupportedAir;
        const arm_text = text[start + 1 .. close];
        var arm: SwitchArm = .{ .values = .empty };
        errdefer arm.values.deinit(allocator);

        var fields = air_text.splitTopLevel(arm_text, ',');
        while (fields.next()) |field| {
            const trimmed = std.mem.trim(u8, field, " \t\r\n");
            if (trimmed.len == 0) continue;
            const value = air_values_parse_constant_or_error(function_air_text, trimmed, 0, trimmed.len) orelse
                return air_model.LowerError.UnsupportedAir;
            try arm.values.append(allocator, value);
        }
        if (arm.values.items.len == 0) return air_model.LowerError.UnsupportedAir;
        try arms.append(allocator, arm);
        offset = close + "] =>".len;
    }
}

fn switchHasElseArm(function_air_text: []const u8, switch_index: u32) bool {
    const text = switchText(function_air_text, switch_index) orelse return false;
    return std.mem.indexOf(u8, text, "else =>") != null;
}

fn switchLine(function_air_text: []const u8, switch_index: u32) ?[]const u8 {
    var needle_buffer: [32]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buffer, "%{}", .{switch_index}) catch return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, function_air_text, start, needle)) |needle_pos| {
        const line_start = std.mem.lastIndexOfScalar(u8, function_air_text[0..needle_pos], '\n') orelse 0;
        const adjusted_start = if (line_start == 0) 0 else line_start + 1;
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, needle_pos, '\n') orelse function_air_text.len;
        const line = function_air_text[adjusted_start..line_end];
        if (std.mem.indexOf(u8, line, "switch_br(") != null) return line;
        start = needle_pos + needle.len;
    }
    return null;
}

fn switchLineResultType(function_air_text: []const u8, switch_index: u32) ?ZigType {
    const line = switchLine(function_air_text, switch_index) orelse return null;
    const switch_start = std.mem.indexOf(u8, line, "switch(") orelse return null;
    const type_start = switch_start + "switch(".len;
    var fields = air_text.splitTopLevel(line[type_start..], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    return parseZigType(type_text);
}

fn blockLineResultType(function_air_text: []const u8, block_index: u32) ?ZigType {
    const line = blockLine(function_air_text, block_index) orelse return null;
    const block_start = std.mem.indexOf(u8, line, "block(") orelse return null;
    const type_start = block_start + "block(".len;
    var fields = air_text.splitTopLevel(line[type_start..], ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    return parseZigType(type_text);
}

fn blockLine(function_air_text: []const u8, block_index: u32) ?[]const u8 {
    var needle_buffer: [32]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buffer, "%{} = block(", .{block_index}) catch return null;
    const start: usize = 0;
    while (std.mem.indexOfPos(u8, function_air_text, start, needle)) |needle_pos| {
        const line_start = std.mem.lastIndexOfScalar(u8, function_air_text[0..needle_pos], '\n') orelse 0;
        const adjusted_start = if (line_start == 0) 0 else line_start + 1;
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, needle_pos, '\n') orelse function_air_text.len;
        return function_air_text[adjusted_start..line_end];
    }
    return null;
}

fn switchText(function_air_text: []const u8, switch_index: u32) ?[]const u8 {
    const line = switchLine(function_air_text, switch_index) orelse return null;
    const start = @intFromPtr(line.ptr) - @intFromPtr(function_air_text.ptr);
    var pos = start;
    while (pos < function_air_text.len) {
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, pos, '\n') orelse function_air_text.len;
        const candidate = function_air_text[pos..line_end];
        if (std.mem.eql(u8, std.mem.trim(u8, candidate, " \t"), ")")) {
            return function_air_text[start..line_end];
        }
        if (line_end == function_air_text.len) break;
        pos = line_end + 1;
    }
    return null;
}

fn air_values_parse_constant_or_error(
    function_air_text: []const u8,
    text: []const u8,
    start: usize,
    end: usize,
) ?air_model.TypedValue {
    _ = function_air_text;
    const raw = std.mem.trim(u8, text[start..end], " ");
    return parseConstant(raw);
}
