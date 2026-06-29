const std = @import("std");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_text = @import("zig_air_text.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const target_mod = @import("target.zig");

pub const ZigType = struct {
    ir_type: ir.Type,
    signed: bool = false,
    pointer_child: ?ir.Type = null,
    is_volatile_pointer: bool = false,
};

pub const FunctionType = struct {
    params: []ZigType,
    return_type: ZigType,
    c_calling_convention: bool,
    non_default_calling_convention: bool,

    pub fn deinit(self: FunctionType, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
    }
};

pub fn irCallingConvention(function_type: FunctionType) ?[]const u8 {
    if (function_type.c_calling_convention) return null;
    if (function_type.non_default_calling_convention) return "unsupported";
    return "fastcc";
}

pub const TypedValue = struct {
    ty: ZigType,
    value: ir.Value,
};

pub const TypedBranchMergeResult = struct {
    value: ?TypedValue,
    predecessor_label: []const u8,
};

pub const LowerError = std.mem.Allocator.Error || error{UnsupportedAir};

pub const TypedFunctionView = struct {
    function: air_export.Function,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,

    pub fn init(function: air_export.Function) ?TypedFunctionView {
        return .{
            .function = function,
            .structured_air = function.structured_air orelse return null,
            .structured_air_v2 = function.structured_air_v2 orelse return null,
        };
    }

    pub fn resultCoverage(self: TypedFunctionView) bool {
        return typedResultCoverage(self.function, self.structured_air_v2);
    }

    pub fn operandCoverage(self: TypedFunctionView) bool {
        return typedOperandCoverage(self.structured_air_v2);
    }

    pub fn body(
        self: TypedFunctionView,
        kind: air_export.StructuredBodyKind,
        owner: ?u32,
    ) ?air_export.StructuredBody {
        return self.structured_air.body(kind, owner);
    }

    pub fn instruction(self: TypedFunctionView, index: u32) ?air_export.TypedInstruction {
        for (self.structured_air_v2.instructions) |candidate| {
            if (candidate.index == index) return candidate;
        }
        return null;
    }

    pub fn capability(
        self: TypedFunctionView,
        typed_instruction: air_export.TypedInstruction,
    ) air_capabilities.OpcodeCapability {
        _ = self;
        return air_capabilities.opcodeCapability(typed_instruction.opcode);
    }

    pub fn hasAnyOpcode(self: TypedFunctionView, opcodes: []const []const u8) bool {
        for (self.structured_air_v2.instructions) |typed_instruction| {
            for (opcodes) |opcode| {
                if (std.mem.eql(u8, typed_instruction.opcode, opcode)) return true;
            }
        }
        return false;
    }

    pub fn opcodeCount(self: TypedFunctionView, opcode: []const u8) usize {
        return typedOpcodeCount(self.structured_air_v2, opcode);
    }

    pub fn fieldPtrIndexCount(self: TypedFunctionView, expected_index: usize) usize {
        return typedFieldPtrIndexCount(self.structured_air_v2, expected_index);
    }

    pub fn calleeNameCount(self: TypedFunctionView, callee_name: []const u8) usize {
        return typedCalleeNameCount(self.structured_air_v2, callee_name);
    }

    pub fn storeOpcodeCount(self: TypedFunctionView) usize {
        return typedStoreOpcodeCount(self.structured_air_v2);
    }

    pub fn hasReturnOpcode(self: TypedFunctionView) bool {
        return typedHasReturnOpcode(self.structured_air_v2);
    }

    pub fn returnOpcodeCount(self: TypedFunctionView) usize {
        return typedReturnOpcodeCount(self.structured_air_v2);
    }

    pub fn retPtrIndex(self: TypedFunctionView) ?u32 {
        return typedRetPtrIndex(self.structured_air_v2);
    }

    pub fn lastBranchI32ConstValue(self: TypedFunctionView) ?i32 {
        return typedLastBranchI32ConstValue(self.structured_air_v2);
    }

    pub fn branchI32ConstValues(self: TypedFunctionView, values: []i32) ?usize {
        return typedBranchI32ConstValues(self.structured_air_v2, values);
    }

    pub fn firstI32ConstOperandForOpcodes(
        self: TypedFunctionView,
        opcodes: []const []const u8,
        operand_index: usize,
    ) ?i32 {
        return typedFirstI32ConstOperandForOpcodes(self.structured_air_v2, opcodes, operand_index);
    }

    pub fn terminalErrorUnionCondBr(self: TypedFunctionView, instruction_index: u32) bool {
        if (!self.hasAnyOpcode(&.{
            "is_non_err",
            "wrap_errunion_payload",
            "wrap_errunion_err",
            "unwrap_errunion_payload",
            "unwrap_errunion_err",
        })) return false;
        const cond_br = self.instruction(instruction_index) orelse return false;
        if (!air_capabilities.isCondBrOpcode(cond_br.opcode) or cond_br.operands.len != 1) return false;
        const then_body = self.body(.then_body, cond_br.index) orelse return false;
        const else_body = self.body(.else_body, cond_br.index) orelse return false;
        return self.bodyHasReturn(then_body) and self.bodyHasReturn(else_body);
    }

    pub fn singleSemanticInstruction(self: TypedFunctionView, structured_body: air_export.StructuredBody) ?u32 {
        var result: ?u32 = null;
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return null;
            if (self.capability(typed_instruction).status == .ignored_metadata) continue;
            if (result != null) return null;
            result = instruction_index;
        }
        return result;
    }

    pub fn containsInstruction(
        self: TypedFunctionView,
        structured_body: air_export.StructuredBody,
        instruction_index: u32,
    ) bool {
        _ = self;
        for (structured_body.instructions) |candidate| {
            if (candidate == instruction_index) return true;
        }
        return false;
    }

    pub fn returnBody(self: TypedFunctionView, structured_body: air_export.StructuredBody) bool {
        const return_index = self.singleSemanticInstruction(structured_body) orelse return false;
        const return_instruction = self.instruction(return_index) orelse return false;
        return air_capabilities.isReturnOpcode(return_instruction.opcode);
    }

    pub fn bodyEndsInReturn(self: TypedFunctionView, structured_body: air_export.StructuredBody) bool {
        var saw_return = false;
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            const typed_capability = self.capability(typed_instruction);
            if (typed_capability.status == .ignored_metadata) continue;
            if (air_capabilities.isReturnOpcode(typed_instruction.opcode)) {
                saw_return = true;
                continue;
            }
            if (saw_return) return false;
            if (!air_capabilities.typedV2CanLower(typed_capability) or
                air_capabilities.isBlockOpcode(typed_instruction.opcode))
            {
                return false;
            }
        }
        return saw_return;
    }

    pub fn bodyHasReturn(self: TypedFunctionView, structured_body: air_export.StructuredBody) bool {
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            if (air_capabilities.isReturnOpcode(typed_instruction.opcode)) {
                return true;
            }
        }
        return false;
    }

    pub fn noreturnBody(self: TypedFunctionView, structured_body: air_export.StructuredBody) bool {
        var saw_call = false;
        var saw_unreach = false;
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            if (self.capability(typed_instruction).status == .ignored_metadata) continue;
            if (!saw_call) {
                if (!air_capabilities.isCallOpcode(typed_instruction.opcode)) return false;
                const signature = detail(typed_instruction, "call_signature") orelse return false;
                if (!std.mem.endsWith(u8, std.mem.trim(u8, signature, " "), "noreturn")) return false;
                saw_call = true;
                continue;
            }
            if (!saw_unreach and air_capabilities.isUnreachOpcode(typed_instruction.opcode)) {
                saw_unreach = true;
                continue;
            }
            return false;
        }
        return saw_call and saw_unreach;
    }

    pub fn voidBranchBody(
        self: TypedFunctionView,
        structured_body: air_export.StructuredBody,
        target_block: u32,
    ) bool {
        const branch_index = self.singleSemanticInstruction(structured_body) orelse return false;
        const branch = self.instruction(branch_index) orelse return false;
        if (!air_capabilities.isBrOpcode(branch.opcode) or branch.operands.len != 2) return false;
        const target = blockTarget(branch.operands[0]) orelse return false;
        if (target != target_block) return false;
        return typedVoidConstOperand(branch, 1) orelse false;
    }

    pub fn voidGuardBlock(
        self: TypedFunctionView,
        target_block: u32,
        then_body: air_export.StructuredBody,
        else_body: air_export.StructuredBody,
    ) bool {
        return (self.voidBranchBody(then_body, target_block) and self.noreturnBody(else_body)) or
            (self.voidBranchBody(else_body, target_block) and self.noreturnBody(then_body));
    }

    pub fn voidGuardBlockByIndex(self: TypedFunctionView, block_index: u32) bool {
        const block_body = self.body(.block, block_index) orelse return false;
        const cond_index = self.singleSemanticInstruction(block_body) orelse return false;
        const cond = self.instruction(cond_index) orelse return false;
        if (!air_capabilities.isCondBrOpcode(cond.opcode)) return false;
        const then_body = self.body(.then_body, cond.index) orelse return false;
        const else_body = self.body(.else_body, cond.index) orelse return false;
        return self.voidGuardBlock(block_index, then_body, else_body);
    }

    pub fn containsVoidGuardBlockInstruction(self: TypedFunctionView, instruction_index: u32) bool {
        for (self.structured_air.bodies) |structured_body| {
            if (structured_body.kind != .block) continue;
            const owner = structured_body.owner orelse continue;
            for (structured_body.instructions) |body_instruction| {
                if (body_instruction == instruction_index and self.voidGuardBlockByIndex(owner)) return true;
            }
            const cond_index = self.singleSemanticInstruction(structured_body) orelse continue;
            const then_body = self.body(.then_body, cond_index) orelse continue;
            const else_body = self.body(.else_body, cond_index) orelse continue;
            for (then_body.instructions) |then_instruction| {
                if (then_instruction == instruction_index and self.voidGuardBlockByIndex(owner)) return true;
            }
            for (else_body.instructions) |else_instruction| {
                if (else_instruction == instruction_index and self.voidGuardBlockByIndex(owner)) return true;
            }
        }
        return false;
    }

    pub fn genericCfgBlock(self: TypedFunctionView, block_index: u32) bool {
        if (self.genericCfgSwitchBlock(block_index)) return true;
        const block_body = self.body(.block, block_index) orelse return false;
        var cond_index: ?u32 = null;
        for (block_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            const typed_capability = self.capability(typed_instruction);
            if (typed_capability.status == .ignored_metadata) continue;
            if (air_capabilities.isCondBrOpcode(typed_instruction.opcode)) {
                if (cond_index != null or typed_instruction.operands.len != 1) return false;
                cond_index = instruction_index;
                continue;
            }
            if (cond_index != null) return false;
            if (!air_capabilities.typedV2CanLower(typed_capability) or air_capabilities.isBlockOpcode(typed_instruction.opcode)) return false;
        }
        const cond = cond_index orelse return false;
        const then_body = self.body(.then_body, cond) orelse return false;
        const else_body = self.body(.else_body, cond) orelse return false;
        return self.genericCfgBranchBody(block_index, then_body) and
            self.genericCfgBranchBody(block_index, else_body);
    }

    pub fn genericCfgSwitchBlock(self: TypedFunctionView, block_index: u32) bool {
        const block_body = self.body(.block, block_index) orelse return false;
        var switch_count: usize = 0;
        for (block_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            const typed_capability = self.capability(typed_instruction);
            if (typed_capability.status == .ignored_metadata) continue;
            if (!air_capabilities.isSwitchBrOpcode(typed_instruction.opcode)) return false;
            switch_count += 1;
        }
        if (switch_count != 1) return false;
        var branch_count: usize = 0;
        for (self.structured_air_v2.instructions) |candidate| {
            if (!air_capabilities.isBrOpcode(candidate.opcode) or candidate.operands.len != 2) continue;
            const target = blockTarget(candidate.operands[0]) orelse continue;
            if (target == block_index) branch_count += 1;
        }
        return branch_count >= 2;
    }

    pub fn genericCfgBranchBody(
        self: TypedFunctionView,
        target_block: u32,
        structured_body: air_export.StructuredBody,
    ) bool {
        if (self.returnBody(structured_body)) return true;
        if (self.bodyEndsInReturn(structured_body)) return true;
        if (self.noreturnBody(structured_body)) return true;
        var saw_branch = false;
        var saw_return = false;
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            const typed_capability = self.capability(typed_instruction);
            if (typed_capability.status == .ignored_metadata) continue;
            if (air_capabilities.isBrOpcode(typed_instruction.opcode)) {
                if (saw_branch or saw_return or typed_instruction.operands.len != 2) return false;
                const target = blockTarget(typed_instruction.operands[0]) orelse return false;
                if (target != target_block) return false;
                saw_branch = true;
                continue;
            }
            if (air_capabilities.isReturnOpcode(typed_instruction.opcode)) {
                if (saw_branch or saw_return or typed_instruction.operands.len != 1) return false;
                saw_return = true;
                continue;
            }
            if (saw_branch or saw_return) return false;
            if (air_capabilities.isBlockOpcode(typed_instruction.opcode)) {
                if (!self.genericCfgBlock(typed_instruction.index) and
                    !self.voidGuardBlockByIndex(typed_instruction.index))
                {
                    return false;
                }
                continue;
            }
            if (!air_capabilities.typedV2CanLower(typed_capability) or
                air_capabilities.isUnreachOpcode(typed_instruction.opcode))
            {
                return false;
            }
        }
        return saw_branch or saw_return;
    }

    pub fn containsGenericCfgBlockInstruction(self: TypedFunctionView, instruction_index: u32) bool {
        for (self.function.instructions) |instruction_record| {
            if (!air_capabilities.isBlockOpcode(instruction_record.opcode)) continue;
            if (!self.genericCfgBlock(instruction_record.index)) continue;
            const block_body = self.body(.block, instruction_record.index) orelse return false;
            if (self.containsInstruction(block_body, instruction_index)) return true;
            if (self.genericCfgSwitchBlock(instruction_record.index) and
                self.switchBlockBranchInstruction(instruction_record.index, instruction_index))
            {
                return true;
            }
            if (self.genericCfgSwitchBlock(instruction_record.index) and
                self.switchBlockValueInstruction(instruction_record.index, instruction_index))
            {
                return true;
            }
            for (block_body.instructions) |child_index| {
                const child = self.instruction(child_index) orelse return false;
                if (!air_capabilities.isCondBrOpcode(child.opcode)) continue;
                const then_body = self.body(.then_body, child.index) orelse return false;
                const else_body = self.body(.else_body, child.index) orelse return false;
                return self.genericCfgBodyContains(then_body, instruction_index) or
                    self.genericCfgBodyContains(else_body, instruction_index);
            }
        }
        return false;
    }

    pub fn genericCfgBodyContains(
        self: TypedFunctionView,
        structured_body: air_export.StructuredBody,
        instruction_index: u32,
    ) bool {
        if (self.containsInstruction(structured_body, instruction_index)) return true;
        for (structured_body.instructions) |candidate| {
            const typed_instruction = self.instruction(candidate) orelse return false;
            if (!air_capabilities.isBlockOpcode(typed_instruction.opcode)) continue;
            if (self.voidGuardBlockByIndex(typed_instruction.index)) {
                const nested_body = self.body(.block, typed_instruction.index) orelse return false;
                if (self.containsInstruction(nested_body, instruction_index)) return true;
                for (nested_body.instructions) |nested_candidate| {
                    const nested_instruction = self.instruction(nested_candidate) orelse return false;
                    if (!air_capabilities.isCondBrOpcode(nested_instruction.opcode)) continue;
                    const then_body = self.body(.then_body, nested_instruction.index) orelse return false;
                    const else_body = self.body(.else_body, nested_instruction.index) orelse return false;
                    if (self.containsInstruction(then_body, instruction_index) or
                        self.containsInstruction(else_body, instruction_index))
                    {
                        return true;
                    }
                }
                continue;
            }
            if (!self.genericCfgBlock(typed_instruction.index)) continue;
            const nested_body = self.body(.block, typed_instruction.index) orelse return false;
            if (self.containsInstruction(nested_body, instruction_index)) return true;
            if (self.genericCfgSwitchBlock(typed_instruction.index) and
                self.switchBlockBranchInstruction(typed_instruction.index, instruction_index))
            {
                return true;
            }
            if (self.genericCfgSwitchBlock(typed_instruction.index) and
                self.switchBlockValueInstruction(typed_instruction.index, instruction_index))
            {
                return true;
            }
            for (nested_body.instructions) |nested_candidate| {
                const nested_instruction = self.instruction(nested_candidate) orelse return false;
                if (!air_capabilities.isCondBrOpcode(nested_instruction.opcode)) continue;
                const then_body = self.body(.then_body, nested_instruction.index) orelse return false;
                const else_body = self.body(.else_body, nested_instruction.index) orelse return false;
                if (self.genericCfgBodyContains(then_body, instruction_index) or
                    self.genericCfgBodyContains(else_body, instruction_index))
                {
                    return true;
                }
            }
        }
        return false;
    }

    fn switchBlockBranchInstruction(self: TypedFunctionView, block_index: u32, instruction_index: u32) bool {
        const candidate = self.instruction(instruction_index) orelse return false;
        if (!air_capabilities.isBrOpcode(candidate.opcode) or candidate.operands.len != 2) return false;
        const target = blockTarget(candidate.operands[0]) orelse return false;
        return target == block_index;
    }

    fn switchBlockValueInstruction(self: TypedFunctionView, block_index: u32, instruction_index: u32) bool {
        if (self.switchBlockValueBlock(block_index, instruction_index)) return true;
        for (self.structured_air_v2.instructions) |candidate| {
            if (!air_capabilities.isBlockOpcode(candidate.opcode)) continue;
            if (!self.switchBlockValueBlock(block_index, candidate.index)) continue;
            if (self.linearValueBlockContains(candidate.index, instruction_index)) return true;
        }
        return false;
    }

    fn switchBlockValueBlock(self: TypedFunctionView, block_index: u32, value_block_index: u32) bool {
        const value_block = self.instruction(value_block_index) orelse return false;
        if (!air_capabilities.isBlockOpcode(value_block.opcode)) return false;
        for (self.structured_air_v2.instructions) |candidate| {
            if (!air_capabilities.isBrOpcode(candidate.opcode) or candidate.operands.len != 2) continue;
            const target = blockTarget(candidate.operands[0]) orelse continue;
            if (target != block_index) continue;
            const value_index = typedInstOperandIndex(candidate.operands[1]) orelse continue;
            if (value_index == value_block_index) return true;
        }
        return false;
    }

    fn linearValueBlockContains(self: TypedFunctionView, value_block_index: u32, instruction_index: u32) bool {
        if (instruction_index == value_block_index) return true;
        for (self.structured_air_v2.instructions) |candidate| {
            if (!air_capabilities.isBrOpcode(candidate.opcode) or candidate.operands.len != 2) continue;
            const target = blockTarget(candidate.operands[0]) orelse continue;
            if (target != value_block_index) continue;
            return instruction_index > value_block_index and instruction_index <= candidate.index;
        }
        return false;
    }
};

pub const TypedCallee = struct {
    name: []const u8,
    external: bool,
};

pub const TypedCallDetails = struct {
    signature_text: []const u8,
    callee_text: []const u8,
    callee: ?TypedCallee,
    callee_name: ?[]const u8,
};

pub fn callDetails(instruction: air_export.TypedInstruction) ?TypedCallDetails {
    const signature_text = detail(instruction, "call_signature") orelse return null;
    const callee_text = detail(instruction, "callee_text") orelse return null;
    return .{
        .signature_text = signature_text,
        .callee_text = callee_text,
        .callee = callee(callee_text),
        .callee_name = calleeName(callee_text),
    };
}

pub fn runtimeNavFqn(instruction: air_export.TypedInstruction) ?[]const u8 {
    return detail(instruction, "nav_fqn");
}

pub fn fieldIndex(instruction: air_export.TypedInstruction) ?i128 {
    const field_index_text = detail(instruction, "field_index") orelse return null;
    return std.fmt.parseInt(i128, field_index_text, 10) catch null;
}

pub fn fieldIndexUsize(instruction: air_export.TypedInstruction) ?usize {
    const index = fieldIndex(instruction) orelse return null;
    if (index < 0) return null;
    return @intCast(index);
}

pub fn arrayElemTableText(instruction: air_export.TypedInstruction) ?[]const u8 {
    return operandTextDetail(instruction, 0);
}

pub fn calleeName(callee_text: []const u8) ?[]const u8 {
    return (callee(callee_text) orelse return null).name;
}

pub fn callee(callee_text: []const u8) ?TypedCallee {
    if (calleeWithMarker(callee_text, "function '", false)) |typed_callee| return typed_callee;
    if (calleeWithMarker(callee_text, "extern '", true)) |typed_callee| return typed_callee;
    return null;
}

pub fn calleeWithMarker(callee_text: []const u8, marker: []const u8, external: bool) ?TypedCallee {
    const start = std.mem.indexOf(u8, callee_text, marker) orelse return null;
    const name_start = start + marker.len;
    const name_end = std.mem.indexOf(u8, callee_text[name_start..], "'") orelse return null;
    if (name_end == 0) return null;
    return .{
        .name = callee_text[name_start .. name_start + name_end],
        .external = external,
    };
}

pub fn shortFunctionName(name: []const u8) []const u8 {
    return name;
}

pub fn instructionRecordPosition(function: air_export.Function, index: u32) ?usize {
    for (function.instructions, 0..) |instruction, position| {
        if (instruction.index == index) return position;
    }
    return null;
}

pub fn simpleSelectBlock(function: air_export.Function, block_index: u32) bool {
    const block_position = instructionRecordPosition(function, block_index) orelse return false;
    const block_instruction = function.instructions[block_position];
    var cond_count: usize = 0;
    var matching_br_count: usize = 0;
    var after_cond = false;
    for (function.instructions[block_position + 1 ..]) |instruction| {
        if (instruction.indent <= block_instruction.indent) break;
        if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
            cond_count += 1;
            after_cond = true;
            continue;
        }
        if (!after_cond or air_capabilities.isIgnoredOpcode(instruction.opcode)) continue;
        if (air_capabilities.isBrOpcode(instruction.opcode)) {
            var fields = air_text.splitTopLevel(instruction.payload, ',');
            const target = fields.next() orelse return false;
            if (air_text.instructionRef(target) == block_index) matching_br_count += 1;
            continue;
        }
        return false;
    }
    return cond_count == 1 and matching_br_count == 2;
}

pub fn belongsToSimpleSelectBlock(function: air_export.Function, instruction_index: u32) bool {
    const position = instructionRecordPosition(function, instruction_index) orelse return false;
    const instruction = function.instructions[position];
    var parent_position = position;
    while (parent_position > 0) {
        parent_position -= 1;
        const candidate = function.instructions[parent_position];
        if (candidate.indent >= instruction.indent) continue;
        if (air_capabilities.isBlockOpcode(candidate.opcode)) {
            return simpleSelectBlock(function, candidate.index);
        }
    }
    return false;
}

pub fn ownPrint(module: *ir.Module, comptime format: []const u8, args: anytype) ![]const u8 {
    const owned = try std.fmt.allocPrint(module.allocator, format, args);
    errdefer module.allocator.free(owned);
    try module.owned_strings.append(module.allocator, owned);
    return owned;
}

pub fn detail(instruction: air_export.TypedInstruction, key: []const u8) ?[]const u8 {
    for (instruction.details) |entry| {
        if (std.mem.eql(u8, entry.key, key)) return entry.value;
    }
    return null;
}

pub fn operandTextDetail(instruction: air_export.TypedInstruction, operand_index: usize) ?[]const u8 {
    var key_buffer: [32]u8 = undefined;
    const key = std.fmt.bufPrint(&key_buffer, "operand{}_text", .{operand_index}) catch return null;
    if (detail(instruction, key)) |value| return value;
    const legacy_key = std.fmt.bufPrint(&key_buffer, "operand{}", .{operand_index}) catch return null;
    return detail(instruction, legacy_key);
}

pub fn instructionMissingRequiredDetail(instruction: air_export.TypedInstruction) ?[]const u8 {
    if (air_capabilities.isCallOpcode(instruction.opcode)) {
        if (detail(instruction, "callee_text") == null) return "missing_callee_text";
        if (detail(instruction, "call_signature") == null) return "missing_call_signature";
    }
    for (instruction.operands, 0..) |operand, operand_index| {
        if (isTypedConstOperand(operand) and operandTextDetail(instruction, operand_index) == null) {
            return "missing_const_text";
        }
    }
    return null;
}

pub fn typedOpcodeCount(structured_air_v2: air_export.StructuredAirV2, opcode: []const u8) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) count += 1;
    }
    return count;
}

pub fn functionHasOpcode(function: air_export.Function, opcode: []const u8) bool {
    for (function.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, opcode)) return true;
    }
    return false;
}

pub fn functionHasScalarOp(function: air_export.Function, op: air_capabilities.ScalarSemanticOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasMemoryOp(function: air_export.Function, op: air_capabilities.MemorySemanticOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasOptionalOp(function: air_export.Function, op: air_capabilities.OptionalSemanticOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasErrorUnionOp(function: air_export.Function, op: air_capabilities.ErrorUnionSemanticOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.errorUnionSemanticOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasPointerAggregateOp(function: air_export.Function, op: air_capabilities.PointerAggregateSemanticOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasCallOp(function: air_export.Function) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.isCallOpcode(instruction.opcode)) return true;
    }
    return false;
}

pub fn functionHasCfgOp(function: air_export.Function, op: air_capabilities.CfgLoweringOp) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.cfgLoweringOpForOpcode(instruction.opcode) == op) return true;
    }
    return false;
}

pub fn functionHasReturnOp(function: air_export.Function) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.isReturnOpcode(instruction.opcode)) return true;
    }
    return false;
}

pub fn functionHasStoreOp(function: air_export.Function) bool {
    return functionHasMemoryOp(function, .store);
}

pub fn functionHasFieldPtrIndex(function: air_export.Function, index: usize) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.isFieldPtrIndexOpcode(instruction.opcode, index)) return true;
    }
    return false;
}

pub fn functionHasRetPtrOp(function: air_export.Function) bool {
    for (function.instructions) |instruction| {
        if (air_capabilities.isRetPtrOpcode(instruction.opcode)) return true;
    }
    return false;
}

pub const TableLookupSummary = struct {
    index_source: u32,
    mask_or_narrow: u32,
    index_cast: u32,
    table_access: u32,
    return_value: u32,
};

pub const ErrorSwitchSummary = struct {
    kind: enum { payload, maybe_error, switch_dispatch, classify },
    condition: ?u32 = null,
    error_union_value: ?u32 = null,
    extracted_value: ?u32 = null,
    switch_br: ?u32 = null,
    return_value: ?u32 = null,
};

pub const RuntimeWrapperSummary = struct {
    kind: enum { optional_pointer_main, pointer_load_store_main },
    call: u32,
    compare: u32,
    cond_br: u32,
    block: u32,
    load: ?u32 = null,
    return_value: ?u32 = null,
};

pub const PanicEdgeSummary = struct {
    predicate: u32,
    cond_br: u32,
    panic_call: u32,
    unreach: u32,
    load: u32,
    add: u32,
    return_value: u32,
};

pub const AggregatePairSummary = struct {
    kind: enum { first, make },
    base_ptr: u32,
    field0_ptr: u32,
    field1_ptr: ?u32 = null,
    field0_value: ?u32 = null,
    field1_value: ?u32 = null,
    return_value: u32,
};

pub const ArraySumSummary = struct {
    aggregate_init: u32,
    elem_ptr_count: usize,
    load_count: usize,
    add_count: usize,
};

pub const StructSumSummary = struct {
    field0_ptr: u32,
    field1_ptr: u32,
    load_count: usize,
    add_count: usize,
};

pub const PackedFieldSummary = struct {
    kind: enum { read_flag, replace_low },
    field_ptr: u32,
    load: ?u32 = null,
    bitcast: ?u32 = null,
    trunc: ?u32 = null,
    store: ?u32 = null,
};

pub const SliceSumSummary = struct {
    slice: u32,
    slice_elem_ptr: u32,
    ptr_slice_len_ptr: u32,
    loop: u32,
};

pub const OptionalShapeSummary = struct {
    kind: enum { pointer_payload, scalar_payload },
    optional_value: ?u32 = null,
    condition: u32,
    payload: u32,
    wrap: ?u32 = null,
    load: ?u32 = null,
    return_value: ?u32 = null,
};

pub const IntegerSwitchSummary = struct {
    switch_br: u32,
    block_count: usize,
    branch_count: usize,
    has_default_arm_text: bool,
};

pub const IntegerSwitchArm = struct {
    first: u8,
    last: u8,
    result: i32,
};

const IntegerSwitchRange = struct {
    first: u8,
    last: u8,
};

pub const IntegerSwitchPlan = struct {
    switch_br: u32,
    arms: []IntegerSwitchArm,
    default_result: i32,

    pub fn deinit(self: IntegerSwitchPlan, allocator: std.mem.Allocator) void {
        allocator.free(self.arms);
    }
};

pub const PointerSliceAddressSummary = struct {
    ptr_add_count: usize = 0,
    ptr_sub_count: usize = 0,
    slice_count: usize = 0,
    slice_ptr_count: usize = 0,
    slice_len_count: usize = 0,
    slice_elem_ptr_count: usize = 0,
    ptr_slice_len_ptr_count: usize = 0,
    ptr_slice_ptr_ptr_count: usize = 0,
    load_count: usize = 0,
    store_count: usize = 0,
    bounds_check_count: usize = 0,
    base_pointer_operand: ?[]const u8 = null,
    dynamic_index_operand: ?[]const u8 = null,
    constant_index: ?i128 = null,
    scalar_width_bits: ?u16 = null,
    slice_source_index: ?u32 = null,

    pub fn hasPointerOrSliceAddress(self: PointerSliceAddressSummary) bool {
        return self.ptr_add_count != 0 or
            self.ptr_sub_count != 0 or
            self.slice_count != 0 or
            self.slice_ptr_count != 0 or
            self.slice_len_count != 0 or
            self.slice_elem_ptr_count != 0 or
            self.ptr_slice_len_ptr_count != 0 or
            self.ptr_slice_ptr_ptr_count != 0;
    }
};

pub const TypedUnionTagPayloadSwitchSummary = struct {
    tag0_return_add: i32,
    tag1_store_add: i32,
    tag1_return_add: i32,
};

pub const TypedOptionalPayloadBranchSummary = struct {
    threshold: i32,
    fallback: i32,
};

pub const TypedOptionalPayloadSummary = struct {
    fallback: i32,
};

pub const TypedOptionalPointerSummary = struct {
    add_imm: i32,
    fallback: i32,
    checked_unwrap: bool,
};

pub const TypedCheckedIntFromFloatSummary = struct {
    operand_ty: ir.Type,
    low_value: []const u8,
    high_value: []const u8,
};

pub const TypedMixCAddMayPanicSummary = struct {
    checked_add: bool,
};

pub const TypedRuntimeWrapperSummary = struct {
    kind: enum { optional_pointer_main, pointer_load_store_main },
};

pub const TypedPackedFieldSummary = struct {
    kind: enum { read_flag, replace_low },
};

pub const TypedSliceLoopSummary = struct {
    kind: enum { plain_sum, conditional_sum },
};

pub const TypedScalarControlSummary = struct {
    kind: enum { accumulator_loop, conditional_slot_update },
};

pub const TypedLoopTrySummary = struct {
    callee_name: []const u8,
    callee_external: bool,
    call_signature: []const u8,
    error_return: i32,
};

pub const TypedInlineAsmSummary = struct {
    memory_barrier: bool,
};

pub const TypedAtomicRmwSummary = struct {
    instruction: air_export.TypedInstruction,
};

pub const TypedDenseIntegerSwitchSummary = struct {
    results: [5]i32,
};

pub const TypedErrorSwitchSummary = struct {
    kind: enum { switch_dispatch, classify },
};

pub const TypedErrorUnionSummary = struct {
    kind: enum { payload, maybe_error },
};

pub fn pointerSliceAddressSummary(function: air_export.Function) ?PointerSliceAddressSummary {
    const view = TypedFunctionView.init(function) orelse return null;
    if (!view.operandCoverage()) return null;
    var summary: PointerSliceAddressSummary = .{};
    for (view.structured_air_v2.instructions) |instruction| {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .ptr_gep => {
                if (std.mem.eql(u8, instruction.opcode, "ptr_sub")) {
                    summary.ptr_sub_count += 1;
                } else {
                    summary.ptr_add_count += 1;
                }
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice => {
                summary.slice_count += 1;
                summary.slice_source_index = instruction.index;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_ptr => {
                summary.slice_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_ptr_ptr => {
                summary.ptr_slice_ptr_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_elem_ptr => {
                summary.slice_elem_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_len => {
                summary.slice_len_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .slice_len_ptr => {
                summary.ptr_slice_len_ptr_count += 1;
                updatePointerSliceAddressOperands(&summary, instruction);
            },
            .none, .runtime_nav_ptr, .array_elem_val, .field_ptr => {},
        }
        switch (air_capabilities.memorySemanticOpForOpcode(instruction.opcode)) {
            .load => {
                summary.load_count += 1;
                summary.scalar_width_bits = summary.scalar_width_bits orelse scalarWidthFromText(instruction.result_type);
            },
            .store => summary.store_count += 1,
            .alloc, .none => {},
        }
        if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
            summary.bounds_check_count += pointerSliceBoundsCheckOperandCount(instruction);
        }
    }
    return if (summary.hasPointerOrSliceAddress()) summary else null;
}

fn updatePointerSliceAddressOperands(summary: *PointerSliceAddressSummary, instruction: air_export.TypedInstruction) void {
    summary.scalar_width_bits = summary.scalar_width_bits orelse scalarWidthFromText(instruction.result_type);
    for (instruction.operands, 0..) |operand, operand_index| {
        if (summary.base_pointer_operand == null and operandLooksPointer(operand)) {
            summary.base_pointer_operand = operandTextDetail(instruction, operand_index) orelse operand.value;
        }
        if (summary.dynamic_index_operand == null and operandLooksRuntimeIndex(operand)) {
            summary.dynamic_index_operand = operandTextDetail(instruction, operand_index) orelse operand.value;
        }
        if (summary.constant_index == null and operandLooksIntegerConst(operand)) {
            const text = operandTextDetail(instruction, operand_index) orelse operand.value;
            summary.constant_index = parseIntegerText(text);
        }
    }
}

fn pointerSliceBoundsCheckOperandCount(instruction: air_export.TypedInstruction) usize {
    var count: usize = 0;
    for (instruction.operands) |operand| {
        if (operandLooksPointer(operand) or operandLooksRuntimeIndex(operand)) count += 1;
    }
    return count;
}

fn operandLooksPointer(operand: air_export.TypedOperand) bool {
    return std.mem.indexOf(u8, operand.type_text, "*") != null or
        std.mem.indexOf(u8, operand.type_text, "ptr") != null or
        std.mem.indexOf(u8, operand.kind, "ptr") != null;
}

fn operandLooksRuntimeIndex(operand: air_export.TypedOperand) bool {
    if (!isIntegerTypeText(operand.type_text)) return false;
    return !operandLooksIntegerConst(operand);
}

fn operandLooksIntegerConst(operand: air_export.TypedOperand) bool {
    return std.mem.eql(u8, operand.kind, "int") or
        std.mem.eql(u8, operand.kind, "comptime_int") or
        std.mem.eql(u8, operand.kind, "constant");
}

fn parseIntegerText(text: []const u8) ?i128 {
    const trimmed = std.mem.trim(u8, text, " ");
    if (trimmed.len == 0) return null;
    return std.fmt.parseInt(i128, trimmed, 10) catch null;
}

fn scalarWidthFromText(text: []const u8) ?u16 {
    const trimmed = std.mem.trim(u8, text, " ");
    if (std.mem.eql(u8, trimmed, "i8") or std.mem.eql(u8, trimmed, "u8")) return 8;
    if (std.mem.eql(u8, trimmed, "i16") or std.mem.eql(u8, trimmed, "u16")) return 16;
    if (std.mem.eql(u8, trimmed, "i32") or std.mem.eql(u8, trimmed, "u32")) return 32;
    if (std.mem.eql(u8, trimmed, "i64") or std.mem.eql(u8, trimmed, "u64") or std.mem.eql(u8, trimmed, "usize")) return 64;
    return null;
}

fn isIntegerTypeText(text: []const u8) bool {
    return scalarWidthFromText(text) != null or std.mem.indexOf(u8, text, "comptime_int") != null;
}

fn untypedFieldPtrIndex(instruction: air_export.Instruction) ?usize {
    const prefix = "struct_field_ptr_index_";
    if (!std.mem.startsWith(u8, instruction.opcode, prefix)) return null;
    return std.fmt.parseInt(usize, instruction.opcode[prefix.len..], 10) catch null;
}

fn untypedFirstRefOperand(instruction: air_export.Instruction) ?u32 {
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return air_text.instructionRef(fields.next() orelse return null);
}

fn untypedSecondRefOperand(instruction: air_export.Instruction) ?u32 {
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    return air_text.instructionRef(fields.next() orelse return null);
}

fn untypedFieldPtrBase(instruction: air_export.Instruction, field_index: usize) ?u32 {
    if (untypedFieldPtrIndex(instruction) != field_index) return null;
    return untypedFirstRefOperand(instruction);
}

fn untypedCastSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) != .cast) return null;
    return untypedSecondRefOperand(instruction);
}

fn untypedSwitchInput(instruction: air_export.Instruction) ?u32 {
    if (!air_capabilities.isSwitchBrOpcode(instruction.opcode)) return null;
    return untypedFirstRefOperand(instruction);
}

fn untypedCondBrInput(instruction: air_export.Instruction) ?u32 {
    return untypedBranchConditionRef(instruction);
}

fn untypedArrayElemIndex(instruction: air_export.Instruction) ?u32 {
    if (!std.mem.eql(u8, instruction.opcode, "array_elem_val")) return null;
    return untypedSecondRefOperand(instruction);
}

fn untypedValueFeedsReturn(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedReturnRef(instruction)) |returned| {
            if (returned == value) return returned;
            const returned_instruction = untypedInstructionByIndex(function, returned) orelse continue;
            if (untypedCastSource(returned_instruction) == value) return returned;
        }
    }
    return null;
}

fn untypedFindFieldPtrFromBase(function: air_export.Function, base: u32, field_index: usize) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedFieldPtrBase(instruction, field_index) == base) return instruction.index;
    }
    return null;
}

fn untypedFindStoreToSlot(function: air_export.Function, slot: u32) ?UntypedStore {
    for (function.instructions) |instruction| {
        const store = untypedStore(instruction) orelse continue;
        if (store.slot == slot) return store;
    }
    return null;
}

pub fn aggregatePairFirstSummary(function: air_export.Function) ?AggregatePairSummary {
    for (function.instructions) |alloc| {
        if (!air_capabilities.isAllocOpcode(alloc.opcode)) continue;
        const field0 = untypedFindFieldPtrFromBase(function, alloc.index, 0) orelse continue;
        const load = untypedFindAnyLoadFromSlot(function, field0) orelse continue;
        const returned = untypedValueFeedsReturn(function, load) orelse continue;
        return .{
            .kind = .first,
            .base_ptr = alloc.index,
            .field0_ptr = field0,
            .field0_value = load,
            .return_value = returned,
        };
    }
    return null;
}

pub fn arraySumSummary(function: air_export.Function) ?ArraySumSummary {
    var aggregate_init: ?u32 = null;
    var elem_ptr_count: usize = 0;
    var load_count: usize = 0;
    var add_count: usize = 0;
    for (function.instructions) |instruction| {
        if (air_capabilities.isAggregateInitOpcode(instruction.opcode)) {
            if (aggregate_init != null or !selectedThreeI32AggregateInit(instruction)) return null;
            aggregate_init = instruction.index;
        } else if (air_capabilities.isPtrElemPtrOpcode(instruction.opcode)) {
            elem_ptr_count += 1;
        } else if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) == .load) {
            load_count += 1;
        } else if (air_capabilities.isAddOpcodeFamily(instruction.opcode)) {
            add_count += 1;
        }
    }
    const init = aggregate_init orelse return null;
    if (elem_ptr_count != 3 or load_count != 3 or add_count != 2) return null;
    return .{
        .aggregate_init = init,
        .elem_ptr_count = elem_ptr_count,
        .load_count = load_count,
        .add_count = add_count,
    };
}

fn selectedThreeI32AggregateInit(instruction: air_export.Instruction) bool {
    return std.mem.indexOf(u8, instruction.payload, "[3]i32") != null and
        std.mem.indexOf(u8, instruction.payload, "[%0!, %1!, %2!]") != null;
}

pub fn selectedArraySumShape(function: air_export.Function) bool {
    return arraySumSummary(function) != null;
}

pub fn structSumSummary(function: air_export.Function) ?StructSumSummary {
    const field_zero = functionFieldPtrIndex(function, 0) orelse return null;
    const field_one = functionFieldPtrIndex(function, 1) orelse return null;
    var i32_loads: usize = 0;
    var adds: usize = 0;
    for (function.instructions) |instruction| {
        if (untypedLoadResultType(instruction)) |ty| {
            if (std.mem.eql(u8, ty, "i32")) i32_loads += 1;
        }
        if (air_capabilities.isAddOpcodeFamily(instruction.opcode)) adds += 1;
    }
    if (i32_loads != 2 or adds != 1) return null;
    return .{
        .field0_ptr = field_zero,
        .field1_ptr = field_one,
        .load_count = i32_loads,
        .add_count = adds,
    };
}

fn functionFieldPtrIndex(function: air_export.Function, expected_index: usize) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedFieldPtrIndex(instruction) == expected_index) return instruction.index;
    }
    return null;
}

fn untypedLoadResultType(instruction: air_export.Instruction) ?[]const u8 {
    if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) != .load) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return std.mem.trim(u8, fields.next() orelse return null, " ");
}

pub fn selectedStructSumShape(function: air_export.Function) bool {
    return structSumSummary(function) != null;
}

pub fn packedReadFlagSummary(function: air_export.Function) ?PackedFieldSummary {
    const field2 = functionFieldPtrIndex(function, 2) orelse return null;
    const load = untypedFindAnyLoadFromSlot(function, field2) orelse return null;
    const bitcast = untypedFindCastOf(function, "bitcast", load) orelse return null;
    return .{
        .kind = .read_flag,
        .field_ptr = field2,
        .load = load,
        .bitcast = bitcast,
    };
}

pub fn selectedPackedReadFlagShape(function: air_export.Function) bool {
    return packedReadFlagSummary(function) != null;
}

pub fn packedReplaceLowSummary(function: air_export.Function) ?PackedFieldSummary {
    const field0 = functionFieldPtrIndex(function, 0) orelse return null;
    const trunc = for (function.instructions) |instruction| {
        if (std.mem.startsWith(u8, instruction.opcode, "trunc")) break instruction.index;
    } else return null;
    const store = for (function.instructions) |instruction| {
        const candidate = untypedStore(instruction) orelse continue;
        if (candidate.slot != field0) continue;
        switch (candidate.value) {
            .ref => |value| if (value == trunc) break instruction.index,
            .int => {},
        }
    } else return null;
    return .{
        .kind = .replace_low,
        .field_ptr = field0,
        .trunc = trunc,
        .store = store,
    };
}

pub fn selectedPackedReplaceLowShape(function: air_export.Function) bool {
    return packedReplaceLowSummary(function) != null;
}

pub fn sliceSumSummary(function: air_export.Function) ?SliceSumSummary {
    var slice: ?u32 = null;
    var slice_elem_ptr: ?u32 = null;
    var ptr_slice_len_ptr: ?u32 = null;
    var loop: ?u32 = null;
    for (function.instructions) |instruction| {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .slice => slice = slice orelse instruction.index,
            .slice_elem_ptr => slice_elem_ptr = slice_elem_ptr orelse instruction.index,
            .slice_len_ptr => ptr_slice_len_ptr = ptr_slice_len_ptr orelse instruction.index,
            .none, .runtime_nav_ptr, .array_elem_val, .field_ptr, .ptr_gep, .slice_ptr, .slice_ptr_ptr, .slice_len => {},
        }
        if (loop == null and std.mem.eql(u8, instruction.opcode, "loop")) {
            loop = instruction.index;
        }
    }
    return .{
        .slice = slice orelse return null,
        .slice_elem_ptr = slice_elem_ptr orelse return null,
        .ptr_slice_len_ptr = ptr_slice_len_ptr orelse return null,
        .loop = loop orelse return null,
    };
}

pub fn selectedSliceSumShape(function: air_export.Function) bool {
    return sliceSumSummary(function) != null;
}

fn optionalSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode) == .none) return null;
    return untypedFirstRefOperand(instruction);
}

pub fn optionalPointerSummary(function: air_export.Function) ?OptionalShapeSummary {
    for (function.instructions) |condition| {
        if (air_capabilities.optionalSemanticOpForOpcode(condition.opcode) != .is_non_null) continue;
        const source = optionalSource(condition);
        for (function.instructions) |payload| {
            if (air_capabilities.optionalSemanticOpForOpcode(payload.opcode) != .optional_payload) continue;
            if (source != null and optionalSource(payload) != source) continue;
            const load = untypedFindAnyLoadFromSlot(function, payload.index) orelse continue;
            const returned = for (function.instructions) |ret| {
                if (untypedReturnRef(ret)) |value| break value;
            } else continue;
            return .{
                .kind = .pointer_payload,
                .optional_value = source,
                .condition = condition.index,
                .payload = payload.index,
                .load = load,
                .return_value = returned,
            };
        }
    }
    return null;
}

pub fn selectedOptionalPointerShape(function: air_export.Function) bool {
    return optionalPointerSummary(function) != null;
}

pub fn optionalPayloadSummary(function: air_export.Function) ?OptionalShapeSummary {
    for (function.instructions) |wrap| {
        if (air_capabilities.optionalSemanticOpForOpcode(wrap.opcode) != .wrap_optional) continue;
        for (function.instructions) |condition| {
            if (air_capabilities.optionalSemanticOpForOpcode(condition.opcode) != .is_non_null) continue;
            if (optionalSource(condition) != wrap.index) continue;
            for (function.instructions) |payload| {
                if (air_capabilities.optionalSemanticOpForOpcode(payload.opcode) != .optional_payload) continue;
                if (optionalSource(payload) != wrap.index) continue;
                return .{
                    .kind = .scalar_payload,
                    .optional_value = wrap.index,
                    .condition = condition.index,
                    .payload = payload.index,
                    .wrap = wrap.index,
                };
            }
        }
    }
    return null;
}

pub fn selectedOptionalPayloadShape(function: air_export.Function) bool {
    return optionalPayloadSummary(function) != null;
}

pub fn integerSwitchSummary(function: air_export.Function) ?IntegerSwitchSummary {
    var switch_br: ?u32 = null;
    var block_count: usize = 0;
    var branch_count: usize = 0;
    for (function.instructions) |instruction| {
        if (air_capabilities.isIgnoredOpcode(instruction.opcode) or
            air_capabilities.isArgOpcode(instruction.opcode) or
            air_capabilities.isReturnOpcode(instruction.opcode))
        {
            continue;
        }
        if (air_capabilities.isBlockOpcode(instruction.opcode)) {
            block_count += 1;
        } else if (air_capabilities.isSwitchBrOpcode(instruction.opcode)) {
            if (switch_br != null) return null;
            switch_br = instruction.index;
        } else if (air_capabilities.isBrOpcode(instruction.opcode)) {
            branch_count += 1;
        } else {
            return null;
        }
    }
    if (block_count != 1 or branch_count < 2) return null;
    const default_arm = std.mem.indexOf(u8, function.air_text, "else => {") != null;
    if (!default_arm) return null;
    return .{
        .switch_br = switch_br orelse return null,
        .block_count = block_count,
        .branch_count = branch_count,
        .has_default_arm_text = default_arm,
    };
}

pub fn selectedIntegerSwitchShape(function: air_export.Function) bool {
    return integerSwitchSummary(function) != null;
}

pub fn integerSwitchPlan(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) std.mem.Allocator.Error!?IntegerSwitchPlan {
    const summary = integerSwitchSummary(function) orelse return null;
    var arms: std.ArrayList(IntegerSwitchArm) = .empty;
    errdefer arms.deinit(allocator);
    var default_result: ?i32 = null;
    var pending_range: ?IntegerSwitchRange = null;
    var pending_default = false;
    var lines = std.mem.splitScalar(u8, function.air_text, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " ");
        if (std.mem.indexOf(u8, line, "=> {") != null) {
            if (std.mem.indexOf(u8, line, "else => {") != null) {
                pending_default = true;
                pending_range = null;
            } else if (parseIntegerSwitchRange(line)) |range| {
                pending_range = range;
                pending_default = false;
            }
        }
        const result = parseIntegerSwitchBranchResult(line) orelse continue;
        if (pending_default) {
            default_result = result;
            pending_default = false;
        } else if (pending_range) |range| {
            try arms.append(allocator, .{ .first = range.first, .last = range.last, .result = result });
            pending_range = null;
        }
    }
    const fallback = default_result orelse return null;
    if (arms.items.len == 0) return null;
    return .{
        .switch_br = summary.switch_br,
        .arms = try arms.toOwnedSlice(allocator),
        .default_result = fallback,
    };
}

fn parseIntegerSwitchRange(line: []const u8) ?IntegerSwitchRange {
    if (std.mem.indexOf(u8, line, "@.zero_u8") != null) return .{ .first = 0, .last = 0 };
    if (std.mem.indexOf(u8, line, "@.one_u8") != null) return .{ .first = 1, .last = 1 };
    const first_marker = std.mem.indexOf(u8, line, "<u8, ") orelse return null;
    const first_start = first_marker + "<u8, ".len;
    const first_end = std.mem.indexOfScalarPos(u8, line, first_start, '>') orelse return null;
    const first = std.fmt.parseInt(u8, std.mem.trim(u8, line[first_start..first_end], " "), 10) catch return null;
    const range_marker = std.mem.indexOfPos(u8, line, first_end, "...<u8, ") orelse
        return .{ .first = first, .last = first };
    const last_start = range_marker + "...<u8, ".len;
    const last_end = std.mem.indexOfScalarPos(u8, line, last_start, '>') orelse return null;
    const last = std.fmt.parseInt(u8, std.mem.trim(u8, line[last_start..last_end], " "), 10) catch return null;
    if (last < first) return null;
    return .{ .first = first, .last = last };
}

fn parseIntegerSwitchBranchResult(line: []const u8) ?i32 {
    if (std.mem.indexOf(u8, line, "br(") == null) return null;
    const marker = std.mem.lastIndexOf(u8, line, "<i32, ") orelse return null;
    const value_start = marker + "<i32, ".len;
    const value_end = std.mem.indexOfScalarPos(u8, line, value_start, '>') orelse return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, line[value_start..value_end], " "), 10) catch null;
}

pub fn aggregateMakePairSummary(function: air_export.Function) ?AggregatePairSummary {
    for (function.instructions) |ret_ptr| {
        if (!air_capabilities.isRetPtrOpcode(ret_ptr.opcode)) continue;
        const field0 = untypedFindFieldPtrFromBase(function, ret_ptr.index, 0) orelse continue;
        const field1 = untypedFindFieldPtrFromBase(function, ret_ptr.index, 1) orelse continue;
        const field0_store = untypedFindStoreToSlot(function, field0) orelse continue;
        const field1_store = untypedFindStoreToSlot(function, field1) orelse continue;
        for (function.instructions) |ret_load| {
            if (!std.mem.eql(u8, ret_load.opcode, "ret_load")) continue;
            if (untypedFirstRefOperand(ret_load) != ret_ptr.index) continue;
            return .{
                .kind = .make,
                .base_ptr = ret_ptr.index,
                .field0_ptr = field0,
                .field1_ptr = field1,
                .field0_value = switch (field0_store.value) {
                    .ref => |value| value,
                    .int => null,
                },
                .field1_value = switch (field1_store.value) {
                    .ref => |value| value,
                    .int => null,
                },
                .return_value = ret_load.index,
            };
        }
    }
    return null;
}

pub fn selectedAggregatePairFirstShape(function: air_export.Function) bool {
    return aggregatePairFirstSummary(function) != null;
}

pub fn selectedAggregateMakePairShape(function: air_export.Function) bool {
    return aggregateMakePairSummary(function) != null;
}

pub fn tableLookupSummary(function: air_export.Function) ?TableLookupSummary {
    for (function.instructions) |mask| {
        const masked = untypedBinaryRefAndInt(mask) orelse continue;
        if (!std.mem.eql(u8, mask.opcode, "bit_and")) continue;
        for (function.instructions) |cast| {
            if (untypedCastSource(cast) != mask.index) continue;
            if (!std.mem.startsWith(u8, cast.opcode, "intcast")) continue;
            for (function.instructions) |table_access| {
                if (untypedArrayElemIndex(table_access) != cast.index) continue;
                const returned = untypedValueFeedsReturn(function, table_access.index) orelse continue;
                return .{
                    .index_source = masked.lhs,
                    .mask_or_narrow = mask.index,
                    .index_cast = cast.index,
                    .table_access = table_access.index,
                    .return_value = returned,
                };
            }
        }
    }
    return null;
}

pub fn selectedBase64TableLookupShape(function: air_export.Function) bool {
    return tableLookupSummary(function) != null;
}

fn errorUnionSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.errorUnionSemanticOpForOpcode(instruction.opcode) == .none) return null;
    return untypedFirstRefOperand(instruction);
}

pub fn errorUnionPayloadSummary(function: air_export.Function) ?ErrorSwitchSummary {
    for (function.instructions) |is_non_err| {
        if (air_capabilities.errorUnionSemanticOpForOpcode(is_non_err.opcode) != .is_non_err) continue;
        const source = errorUnionSource(is_non_err) orelse continue;
        for (function.instructions) |payload| {
            if (air_capabilities.errorUnionSemanticOpForOpcode(payload.opcode) != .unwrap_payload) continue;
            if (errorUnionSource(payload) != source) continue;
            const returned = untypedValueFeedsReturn(function, payload.index) orelse continue;
            if (functionHasCallOp(function) or functionHasOpcode(function, "switch_br")) return null;
            return .{
                .kind = .payload,
                .condition = is_non_err.index,
                .error_union_value = source,
                .extracted_value = payload.index,
                .return_value = returned,
            };
        }
    }
    return null;
}

pub fn selectedErrorUnionPayloadShape(function: air_export.Function) bool {
    return errorUnionPayloadSummary(function) != null;
}

pub fn maybeErrorSummary(function: air_export.Function) ?ErrorSwitchSummary {
    for (function.instructions) |compare| {
        if (!std.mem.eql(u8, compare.opcode, "cmp_neq")) continue;
        for (function.instructions) |cond| {
            if (untypedCondBrInput(cond) != compare.index) continue;
            if (functionHasOpcode(function, "switch_br")) return null;
            const returned = for (function.instructions) |ret| {
                if (untypedReturnRef(ret)) |value| break value;
            } else continue;
            return .{
                .kind = .maybe_error,
                .condition = compare.index,
                .switch_br = cond.index,
                .return_value = returned,
            };
        }
    }
    return null;
}

pub fn selectedMaybeErrorShape(function: air_export.Function) bool {
    return maybeErrorSummary(function) != null;
}

pub fn errorSwitchSummary(function: air_export.Function) ?ErrorSwitchSummary {
    for (function.instructions) |call| {
        if (!air_capabilities.isCallOpcode(call.opcode)) continue;
        for (function.instructions) |is_non_err| {
            if (air_capabilities.errorUnionSemanticOpForOpcode(is_non_err.opcode) != .is_non_err) continue;
            if (errorUnionSource(is_non_err) != call.index) continue;
            for (function.instructions) |payload| {
                if (air_capabilities.errorUnionSemanticOpForOpcode(payload.opcode) != .unwrap_payload) continue;
                if (errorUnionSource(payload) != call.index) continue;
                for (function.instructions) |switch_br| {
                    if (untypedSwitchInput(switch_br) != payload.index) continue;
                    const returned = untypedValueFeedsReturn(function, payload.index) orelse continue;
                    return .{
                        .kind = .switch_dispatch,
                        .condition = is_non_err.index,
                        .error_union_value = call.index,
                        .extracted_value = payload.index,
                        .switch_br = switch_br.index,
                        .return_value = returned,
                    };
                }
            }
        }
    }
    return null;
}

pub fn selectedErrorSwitchShape(function: air_export.Function) bool {
    return errorSwitchSummary(function) != null;
}

pub fn errorClassifySummary(function: air_export.Function) ?ErrorSwitchSummary {
    if (functionHasCallOp(function) or
        functionHasErrorUnionOp(function, .is_non_err) or
        functionHasErrorUnionOp(function, .unwrap_payload))
    {
        return null;
    }
    for (function.instructions) |switch_br| {
        const switch_input = untypedSwitchInput(switch_br) orelse continue;
        const returned = for (function.instructions) |ret| {
            if (untypedReturnRef(ret)) |value| break value;
        } else continue;
        return .{
            .kind = .classify,
            .extracted_value = switch_input,
            .switch_br = switch_br.index,
            .return_value = returned,
        };
    }
    return null;
}

pub fn selectedErrorClassifyShape(function: air_export.Function) bool {
    return errorClassifySummary(function) != null;
}

fn findCmpEqUsingValue(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cmp_eq")) continue;
        var fields = air_text.splitTopLevel(instruction.payload, ',');
        const lhs = air_text.instructionRef(fields.next() orelse continue) orelse continue;
        const rhs_text = std.mem.trim(u8, fields.next() orelse continue, " ");
        if (fields.next() != null) continue;
        if (lhs == value) return instruction.index;
        if (air_text.instructionRef(rhs_text) == value) return instruction.index;
    }
    return null;
}

fn findCondBrUsingValue(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedCondBrInput(instruction) == value) return instruction.index;
    }
    return null;
}

fn findBlockBefore(function: air_export.Function, instruction_index: u32) ?u32 {
    var result: ?u32 = null;
    for (function.instructions) |instruction| {
        if (instruction.index >= instruction_index) continue;
        if (air_capabilities.isBlockOpcode(instruction.opcode)) result = instruction.index;
    }
    return result;
}

pub fn runtimeOptionalPointerMainSummary(function: air_export.Function) ?RuntimeWrapperSummary {
    if (functionHasMemoryOp(function, .load)) return null;
    for (function.instructions) |call_instruction| {
        if (!air_capabilities.isCallOpcode(call_instruction.opcode)) continue;
        const compare = findCmpEqUsingValue(function, call_instruction.index) orelse continue;
        const cond_br = findCondBrUsingValue(function, compare) orelse continue;
        const returned = untypedValueFeedsReturn(function, call_instruction.index) orelse continue;
        return .{
            .kind = .optional_pointer_main,
            .call = call_instruction.index,
            .compare = compare,
            .cond_br = cond_br,
            .block = findBlockBefore(function, cond_br) orelse return null,
            .return_value = returned,
        };
    }
    return null;
}

pub fn selectedRuntimeOptionalPointerMainShape(function: air_export.Function) bool {
    return runtimeOptionalPointerMainSummary(function) != null;
}

pub fn runtimePointerLoadStoreMainSummary(function: air_export.Function) ?RuntimeWrapperSummary {
    for (function.instructions) |call_instruction| {
        if (!air_capabilities.isCallOpcode(call_instruction.opcode)) continue;
        const load = untypedFindAnyLoadFromSlot(function, call_instruction.index) orelse continue;
        const compare = findCmpEqUsingValue(function, load) orelse continue;
        const cond_br = findCondBrUsingValue(function, compare) orelse continue;
        const returned = untypedValueFeedsReturn(function, load) orelse continue;
        return .{
            .kind = .pointer_load_store_main,
            .call = call_instruction.index,
            .compare = compare,
            .cond_br = cond_br,
            .block = findBlockBefore(function, cond_br) orelse return null,
            .load = load,
            .return_value = returned,
        };
    }
    return null;
}

pub fn selectedRuntimePointerLoadStoreMainShape(function: air_export.Function) bool {
    return runtimePointerLoadStoreMainSummary(function) != null;
}

fn findUnreachAfter(function: air_export.Function, instruction_index: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (instruction.index <= instruction_index) continue;
        if (air_capabilities.isUnreachOpcode(instruction.opcode)) return instruction.index;
    }
    return null;
}

pub fn panicEdgeSummary(function: air_export.Function) ?PanicEdgeSummary {
    for (function.instructions) |predicate| {
        if (!std.mem.eql(u8, predicate.opcode, "cmp_lt")) continue;
        const cond_br = findCondBrUsingValue(function, predicate.index) orelse continue;
        for (function.instructions) |panic_call| {
            if (!air_capabilities.isCallOpcode(panic_call.opcode)) continue;
            const unreach = findUnreachAfter(function, panic_call.index) orelse continue;
            for (function.instructions) |load| {
                if (air_capabilities.memorySemanticOpForOpcode(load.opcode) != .load) continue;
                for (function.instructions) |add| {
                    if (!air_capabilities.isAddOpcodeFamily(add.opcode)) continue;
                    const refs = untypedBinaryRefs(add) orelse continue;
                    if (refs.lhs != load.index and refs.rhs != load.index) continue;
                    const returned = untypedValueFeedsReturn(function, add.index) orelse continue;
                    return .{
                        .predicate = predicate.index,
                        .cond_br = cond_br,
                        .panic_call = panic_call.index,
                        .unreach = unreach,
                        .load = load.index,
                        .add = add.index,
                        .return_value = returned,
                    };
                }
            }
        }
    }
    return null;
}

pub fn selectedMixCAddMayPanicShape(function: air_export.Function) bool {
    return panicEdgeSummary(function) != null;
}

pub const UntypedValueSource = union(enum) {
    int: i128,
    ref: u32,
};

pub const UntypedStore = struct {
    slot: u32,
    value: UntypedValueSource,
};

pub const UntypedBinaryRefs = struct {
    lhs: u32,
    rhs: u32,
};

pub fn untypedArgIndexOfType(instruction: air_export.Instruction, expected_type: []const u8, expected_index: []const u8) bool {
    if (!air_capabilities.isArgOpcode(instruction.opcode)) return false;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    const type_text = std.mem.trim(u8, fields.next() orelse return false, " ");
    const param_index = std.mem.trim(u8, fields.next() orelse return false, " ");
    return fields.next() == null and
        std.mem.eql(u8, type_text, expected_type) and
        std.mem.eql(u8, param_index, expected_index);
}

pub fn untypedAllocType(instruction: air_export.Instruction) ?[]const u8 {
    if (!air_capabilities.isAllocOpcode(instruction.opcode)) return null;
    return std.mem.trim(u8, instruction.payload, " ");
}

pub fn untypedLoadSourceSlot(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) != .load) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    const slot = air_text.instructionRef(fields.next() orelse return null) orelse return null;
    return if (fields.next() == null) slot else null;
}

pub fn untypedStore(instruction: air_export.Instruction) ?UntypedStore {
    if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) != .store) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    const slot = air_text.instructionRef(fields.next() orelse return null) orelse return null;
    const value_text = fields.next() orelse return null;
    if (fields.next() != null) return null;
    return .{
        .slot = slot,
        .value = parseUntypedValueSource(std.mem.trim(u8, value_text, " ")) orelse return null,
    };
}

pub fn untypedBinaryRefs(instruction: air_export.Instruction) ?UntypedBinaryRefs {
    if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) != .binary) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    const lhs = air_text.instructionRef(fields.next() orelse return null) orelse return null;
    const rhs = air_text.instructionRef(fields.next() orelse return null) orelse return null;
    return if (fields.next() == null) .{ .lhs = lhs, .rhs = rhs } else null;
}

pub fn untypedBinaryRefAndInt(instruction: air_export.Instruction) ?struct { lhs: u32, value: i128 } {
    if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) != .binary) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    const lhs = air_text.instructionRef(fields.next() orelse return null) orelse return null;
    const value = parseUntypedIntConstant(std.mem.trim(u8, fields.next() orelse return null, " ")) orelse return null;
    return if (fields.next() == null) .{ .lhs = lhs, .value = value } else null;
}

pub fn untypedReturnRef(instruction: air_export.Instruction) ?u32 {
    if (!air_capabilities.isReturnOpcode(instruction.opcode)) return null;
    return air_text.instructionRef(instruction.payload);
}

pub fn untypedBranchConditionRef(instruction: air_export.Instruction) ?u32 {
    if (!air_capabilities.isCondBrOpcode(instruction.opcode)) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return air_text.instructionRef(fields.next() orelse return null);
}

pub fn untypedInstructionByIndex(function: air_export.Function, index: u32) ?air_export.Instruction {
    for (function.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

pub fn untypedLoadReferencesSlot(instruction: air_export.Instruction, slot: u32) bool {
    return untypedLoadSourceSlot(instruction) == slot;
}

pub fn untypedFindCompareAgainstArg(function: air_export.Function, slot: u32, arg: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!air_capabilities.isCmpLtOpcode(instruction.opcode)) continue;
        var fields = air_text.splitTopLevel(instruction.payload, ',');
        const lhs = air_text.instructionRef(fields.next() orelse continue) orelse continue;
        const rhs = air_text.instructionRef(fields.next() orelse continue) orelse continue;
        if (fields.next() != null or rhs != arg) continue;
        const load = untypedInstructionByIndex(function, lhs) orelse continue;
        if (untypedLoadReferencesSlot(load, slot)) return instruction.index;
    }
    return null;
}

pub fn untypedFindAnyLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedLoadReferencesSlot(instruction, slot)) return instruction.index;
    }
    return null;
}

pub fn untypedFindLastLoadFromSlot(function: air_export.Function, slot: u32) ?u32 {
    var result: ?u32 = null;
    for (function.instructions) |instruction| {
        if (untypedLoadReferencesSlot(instruction, slot)) result = instruction.index;
    }
    return result;
}

pub fn untypedFindCastOf(function: air_export.Function, opcode: []const u8, source: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        var fields = air_text.splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse continue;
        if (air_text.instructionRef(fields.next() orelse continue) == source and fields.next() == null) {
            return instruction.index;
        }
    }
    return null;
}

pub fn untypedFindCastFromSlot(function: air_export.Function, opcode: []const u8, slot: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!untypedLoadReferencesSlot(instruction, slot)) continue;
        if (untypedFindCastOf(function, opcode, instruction.index)) |cast| return cast;
    }
    return null;
}

pub fn untypedFindBinaryUsing(function: air_export.Function, opcode: []const u8, lhs: u32, rhs: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        const refs = untypedBinaryRefs(instruction) orelse continue;
        const first = refs.lhs;
        const second = refs.rhs;
        if ((first == lhs and second == rhs) or (first == rhs and second == lhs)) return instruction.index;
    }
    return null;
}

pub fn untypedFindBinaryUsingConstant(function: air_export.Function, opcode: []const u8, lhs: u32, value: i128) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode)) continue;
        const ref_and_int = untypedBinaryRefAndInt(instruction) orelse continue;
        if (ref_and_int.lhs == lhs and ref_and_int.value == value) return instruction.index;
    }
    return null;
}

pub fn untypedFindBinaryFromSlotUsingConstant(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    value: i128,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!untypedLoadReferencesSlot(instruction, slot)) continue;
        if (untypedFindBinaryUsingConstant(function, opcode, instruction.index, value)) |binary| return binary;
    }
    return null;
}

pub fn untypedFindSlotBinaryUpdate(
    function: air_export.Function,
    opcode: []const u8,
    slot: u32,
    rhs: u32,
) ?u32 {
    for (function.instructions) |instruction| {
        if (!untypedLoadReferencesSlot(instruction, slot)) continue;
        for (function.instructions) |candidate| {
            if (!std.mem.startsWith(u8, candidate.opcode, opcode)) continue;
            var fields = air_text.splitTopLevel(candidate.payload, ',');
            if (air_text.instructionRef(fields.next() orelse continue) != instruction.index) continue;
            if (air_text.instructionRef(fields.next() orelse continue) == rhs and fields.next() == null) {
                return candidate.index;
            }
        }
    }
    return null;
}

pub fn untypedReturnUses(function: air_export.Function, value: u32) bool {
    for (function.instructions) |instruction| {
        if (untypedReturnRef(instruction)) |returned| return returned == value;
    }
    return false;
}

pub fn runtimeNavSymbol(function: air_export.Function) ?[]const u8 {
    for (function.instructions) |instruction| {
        if (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode) != .runtime_nav_ptr) continue;
        var fields = air_text.splitTopLevel(instruction.payload, ',');
        _ = fields.next() orelse return null;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return null;
        }
        return symbol_text[1 .. symbol_text.len - 1];
    }
    return null;
}

fn parseUntypedValueSource(text: []const u8) ?UntypedValueSource {
    if (air_text.instructionRef(text)) |index| return .{ .ref = index };
    if (parseUntypedIntConstant(text)) |value| return .{ .int = value };
    return null;
}

fn parseUntypedIntConstant(text: []const u8) ?i128 {
    if (std.mem.startsWith(u8, text, "<") and std.mem.endsWith(u8, text, ">")) {
        var fields = air_text.splitTopLevel(text[1 .. text.len - 1], ',');
        _ = fields.next() orelse return null;
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        return std.fmt.parseInt(i128, value_text, 10) catch null;
    }
    return std.fmt.parseInt(i128, text, 10) catch null;
}

pub fn typedFieldPtrIndexCount(structured_air_v2: air_export.StructuredAirV2, expected_index: usize) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!isTypedFieldPtrDataKind(instruction.data_kind)) continue;
        const field_index = fieldIndexUsize(instruction) orelse continue;
        if (field_index == expected_index) count += 1;
    }
    return count;
}

pub fn typedCalleeNameCount(structured_air_v2: air_export.StructuredAirV2, callee_name: []const u8) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isCallOpcode(instruction.opcode)) continue;
        const callee_text = detail(instruction, "callee_text") orelse continue;
        const name = calleeName(callee_text) orelse continue;
        if (std.mem.eql(u8, name, callee_name)) count += 1;
    }
    return count;
}

pub fn typedStoreOpcodeCount(structured_air_v2: air_export.StructuredAirV2) usize {
    return typedOpcodeCount(structured_air_v2, "store") + typedOpcodeCount(structured_air_v2, "store_safe");
}

pub fn typedReturnOpcodeCount(structured_air_v2: air_export.StructuredAirV2) usize {
    return typedOpcodeCount(structured_air_v2, "ret") + typedOpcodeCount(structured_air_v2, "ret_safe");
}

pub fn typedHasReturnOpcode(structured_air_v2: air_export.StructuredAirV2) bool {
    return typedReturnOpcodeCount(structured_air_v2) != 0;
}

pub fn typedRetPtrIndex(structured_air_v2: air_export.StructuredAirV2) ?u32 {
    for (structured_air_v2.instructions) |instruction| {
        if (air_capabilities.isRetPtrOpcode(instruction.opcode)) return instruction.index;
    }
    return null;
}

pub fn typedConstUsizeOperand(instruction: air_export.TypedInstruction, operand_index: usize) ?usize {
    const text = operandTextDetail(instruction, operand_index) orelse return null;
    if (std.mem.eql(u8, text, "@.zero_usize")) return 0;
    if (std.mem.eql(u8, text, "@.one_usize")) return 1;
    if (std.mem.startsWith(u8, text, "<usize, ") and std.mem.endsWith(u8, text, ">")) {
        return std.fmt.parseInt(usize, text["<usize, ".len .. text.len - 1], 10) catch null;
    }
    return null;
}

pub fn typedConstI32Operand(instruction: air_export.TypedInstruction, operand_index: usize) ?i32 {
    const text = operandTextDetail(instruction, operand_index) orelse return null;
    if (!std.mem.startsWith(u8, text, "<i32, ") or !std.mem.endsWith(u8, text, ">")) return null;
    return std.fmt.parseInt(i32, std.mem.trim(u8, text["<i32, ".len .. text.len - 1], " "), 10) catch null;
}

pub fn isTypedI32ConstOperand(operand: air_export.TypedOperand) bool {
    return isTypedConstOperand(operand) and std.mem.eql(u8, operand.type_text, "i32");
}

pub fn isTypedPtrU32ConstOperand(operand: air_export.TypedOperand) bool {
    return isTypedConstOperand(operand) and std.mem.eql(u8, operand.type_text, "*u32");
}

pub fn typedVoidConstOperand(instruction: air_export.TypedInstruction, operand_index: usize) ?bool {
    if (operand_index >= instruction.operands.len) return null;
    const operand = instruction.operands[operand_index];
    if (!isTypedConstOperand(operand)) return false;
    if (!std.mem.eql(u8, operand.type_text, "void")) return false;
    const text = operandTextDetail(instruction, operand_index) orelse return null;
    return std.mem.eql(u8, text, "@.void_value");
}

pub fn typedInstOperandIndex(operand: air_export.TypedOperand) ?u32 {
    if (!std.mem.eql(u8, operand.kind, "inst")) return null;
    return std.fmt.parseInt(u32, operand.value, 10) catch null;
}

pub fn typedI32InstOperandIndex(operand: air_export.TypedOperand) ?u32 {
    if (!std.mem.eql(u8, operand.type_text, "i32")) return null;
    return typedInstOperandIndex(operand);
}

pub fn isTypedConstOperand(operand: air_export.TypedOperand) bool {
    return std.mem.eql(u8, operand.kind, "const");
}

pub fn typedConstOperandText(instruction: air_export.TypedInstruction, operand_index: usize) ?[]const u8 {
    if (operand_index >= instruction.operands.len) return null;
    if (!isTypedConstOperand(instruction.operands[operand_index])) return null;
    return operandTextDetail(instruction, operand_index);
}

pub fn typedConstantOperandValueText(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
) ?[]const u8 {
    const instruction = singleInstructionByOpcode(structured_air_v2, opcode) orelse return null;
    const text = operandTextDetail(instruction, 1) orelse return null;
    return typedAngleConstantValue(text);
}

pub fn typedAngleConstantValue(text: []const u8) ?[]const u8 {
    if (!std.mem.startsWith(u8, text, "<") or !std.mem.endsWith(u8, text, ">")) return null;
    const inner = text[1 .. text.len - 1];
    const comma = std.mem.indexOfScalar(u8, inner, ',') orelse return null;
    return std.mem.trim(u8, inner[comma + 1 ..], " ");
}

pub fn isTypedNoneOperand(operand: air_export.TypedOperand) bool {
    return std.mem.eql(u8, operand.kind, "none");
}

pub fn hasKnownTypedText(type_text: []const u8) bool {
    return !std.mem.eql(u8, type_text, "-");
}

pub fn isTypedBlockOperand(operand: air_export.TypedOperand) bool {
    return std.mem.eql(u8, operand.kind, "block");
}

pub fn isTypedFieldPtrDataKind(data_kind: []const u8) bool {
    return std.mem.eql(u8, data_kind, "field_ptr");
}

pub fn isTypedPayloadOpDataKind(data_kind: []const u8) bool {
    return std.mem.eql(u8, data_kind, "pl_op");
}

fn typedBlockOperandTargetText(operand: air_export.TypedOperand) ?[]const u8 {
    if (!isTypedBlockOperand(operand)) return null;
    return if (std.mem.eql(u8, operand.value, "block"))
        operand.type_text
    else
        operand.value;
}

pub fn typedBranchI32ConstValue(instruction: air_export.TypedInstruction) ?i32 {
    if (!air_capabilities.isBrOpcode(instruction.opcode)) return null;
    if (instruction.operands.len != 2) return null;
    if (!isTypedI32ConstOperand(instruction.operands[1])) return null;
    return typedConstI32Operand(instruction, 1);
}

pub fn typedReturnI32ConstValue(instruction: air_export.TypedInstruction) ?i32 {
    if (!air_capabilities.isReturnOpcode(instruction.opcode)) return null;
    if (instruction.operands.len != 1) return null;
    if (!isTypedI32ConstOperand(instruction.operands[0])) return null;
    return typedConstI32Operand(instruction, 0);
}

pub fn typedLastBranchI32ConstValue(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var result: ?i32 = null;
    for (structured_air_v2.instructions) |instruction_record| {
        if (typedBranchI32ConstValue(instruction_record)) |value| result = value;
    }
    return result;
}

pub fn typedLastBranchOrReturnI32ConstValue(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var result: ?i32 = null;
    for (structured_air_v2.instructions) |instruction_record| {
        if (typedBranchI32ConstValue(instruction_record) orelse typedReturnI32ConstValue(instruction_record)) |value| {
            result = value;
        }
    }
    return result;
}

pub fn typedBranchI32ConstValues(structured_air_v2: air_export.StructuredAirV2, values: []i32) ?usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction_record| {
        const value = typedBranchI32ConstValue(instruction_record) orelse continue;
        if (count >= values.len) return null;
        values[count] = value;
        count += 1;
    }
    return count;
}

pub fn typedFirstI32ConstOperandForOpcodes(
    structured_air_v2: air_export.StructuredAirV2,
    opcodes: []const []const u8,
    operand_index: usize,
) ?i32 {
    for (structured_air_v2.instructions) |instruction_record| {
        var opcode_matches = false;
        for (opcodes) |opcode| {
            if (std.mem.eql(u8, instruction_record.opcode, opcode)) {
                opcode_matches = true;
                break;
            }
        }
        if (!opcode_matches) continue;
        if (instruction_record.operands.len <= operand_index) return null;
        return typedConstI32Operand(instruction_record, operand_index);
    }
    return null;
}

pub fn typedAggregatePointerPath(
    structured_air_v2: air_export.StructuredAirV2,
    instruction_index: u32,
    ret_ptr_index: u32,
    path: *[4]usize,
) ?usize {
    const typed_instruction = instructionByIndex(structured_air_v2, instruction_index) orelse return null;
    if (typed_instruction.index == ret_ptr_index and air_capabilities.isRetPtrOpcode(typed_instruction.opcode)) return 0;
    if (isTypedFieldPtrDataKind(typed_instruction.data_kind)) {
        if (typed_instruction.operands.len != 1) return null;
        const base_index = typedInstOperandIndex(typed_instruction.operands[0]) orelse return null;
        const len = typedAggregatePointerPath(structured_air_v2, base_index, ret_ptr_index, path) orelse return null;
        if (len >= path.len) return null;
        path[len] = fieldIndexUsize(typed_instruction) orelse return null;
        return len + 1;
    }
    if (air_capabilities.isPtrElemPtrOpcode(typed_instruction.opcode)) {
        if (typed_instruction.operands.len != 2) return null;
        const base_index = typedInstOperandIndex(typed_instruction.operands[0]) orelse return null;
        const len = typedAggregatePointerPath(structured_air_v2, base_index, ret_ptr_index, path) orelse return null;
        if (len >= path.len) return null;
        path[len] = typedConstUsizeOperand(typed_instruction, 1) orelse return null;
        return len + 1;
    }
    return null;
}

pub fn aggregateIndexPathText(path: []const usize) ?[]const u8 {
    if (path.len == 1) return switch (path[0]) {
        0 => "0",
        1 => "1",
        2 => "2",
        3 => "3",
        4 => "4",
        5 => "5",
        6 => "6",
        7 => "7",
        else => null,
    };
    if (path.len == 2) {
        if (path[0] == 0 and path[1] == 0) return "0, 0";
        if (path[0] == 0 and path[1] == 1) return "0, 1";
        if (path[0] == 0 and path[1] == 2) return "0, 2";
        if (path[0] == 0 and path[1] == 3) return "0, 3";
        if (path[0] == 0 and path[1] == 4) return "0, 4";
        if (path[0] == 0 and path[1] == 5) return "0, 5";
        if (path[0] == 0 and path[1] == 6) return "0, 6";
        if (path[0] == 0 and path[1] == 7) return "0, 7";
        if (path[0] == 1 and path[1] == 0) return "1, 0";
        if (path[0] == 1 and path[1] == 1) return "1, 1";
    }
    return null;
}

pub fn plainFieldPointerChild(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 1 or bits % 8 == 0,
        .float, .double, .ptr => true,
        .aggregate => true,
        .void, .x86_fp80, .fp128, .metadata, .vector => false,
    };
}

pub fn supportedTypedGepElementType(ty: ir.Type) bool {
    return switch (ty) {
        .int => |bits| bits == 8 or bits == 16 or bits == 32 or bits == 64,
        .float, .double => true,
        .void, .x86_fp80, .fp128, .metadata, .ptr, .aggregate, .vector => false,
    };
}

pub fn aggregateFieldByteOffset(source_ty: ir.Type, field_child: ir.Type, field_index: i128) ?i128 {
    if (field_index < 0) return null;
    if (!plainFieldPointerChild(field_child)) return null;
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

pub fn blockTarget(operand: air_export.TypedOperand) ?u32 {
    const target_text = typedBlockOperandTargetText(operand) orelse return null;
    return std.fmt.parseInt(u32, target_text, 10) catch null;
}

pub fn typedResultCoverage(
    function: air_export.Function,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (structured_air_v2.instructions.len != function.instruction_count) return false;
    for (structured_air_v2.instructions) |instruction| {
        if (!hasKnownTypedText(instruction.result_type)) return false;
    }
    return true;
}

pub fn typedOperandCoverage(structured_air_v2: air_export.StructuredAirV2) bool {
    for (structured_air_v2.instructions) |instruction| {
        for (instruction.operands) |operand| {
            if (!hasKnownTypedText(operand.type_text)) return false;
        }
    }
    return true;
}

pub fn instructionByIndex(
    structured_air_v2: air_export.StructuredAirV2,
    index: u32,
) ?air_export.TypedInstruction {
    for (structured_air_v2.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

pub fn singleInstructionByOpcode(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
}

pub fn typedUnionTagPayloadSwitchSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedUnionTagPayloadSwitchSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        typedOpcodeCount(structured_air_v2, "set_union_tag") != 2 or
        typedOpcodeCount(structured_air_v2, "get_union_tag") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        typedOpcodeCount(structured_air_v2, "struct_field_val") != 2 or
        typedStoreOpcodeCount(structured_air_v2) != 2 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }

    const alloc = singleInstructionByOpcode(structured_air_v2, "alloc") orelse return null;
    if (!std.mem.startsWith(u8, alloc.result_type, "*")) return null;

    var saw_tag0 = false;
    var saw_tag1 = false;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "set_union_tag")) continue;
        if (instruction.operands.len != 2) return null;
        if (typedInstOperandIndex(instruction.operands[0]) != alloc.index) return null;
        const tag_index = typedDetailU32(instruction, "tag_index") orelse return null;
        switch (tag_index) {
            0 => saw_tag0 = true,
            1 => saw_tag1 = true,
            else => return null,
        }
    }
    if (!saw_tag0 or !saw_tag1) return null;

    const get_tag = singleInstructionByOpcode(structured_air_v2, "get_union_tag") orelse return null;
    const switch_br = singleInstructionByOpcode(structured_air_v2, "switch_br") orelse return null;
    if (switch_br.operands.len != 1 or typedInstOperandIndex(switch_br.operands[0]) != get_tag.index) return null;
    if ((typedDetailU32(switch_br, "cases_len") orelse return null) != 2) return null;
    if ((typedDetailU32(switch_br, "case0_item0_tag_index") orelse return null) != 0) return null;
    if ((typedDetailU32(switch_br, "case1_item0_tag_index") orelse return null) != 1) return null;

    const field0 = typedUnionFieldVal(structured_air_v2, 0) orelse return null;
    const field1 = typedUnionFieldVal(structured_air_v2, 1) orelse return null;
    if (field0.operands.len != 1 or field1.operands.len != 1) return null;
    const union_value_index0 = typedInstOperandIndex(field0.operands[0]) orelse return null;
    const union_value_index1 = typedInstOperandIndex(field1.operands[0]) orelse return null;
    if (union_value_index0 != union_value_index1) return null;

    const tag0_return_add = typedAddConstUsing(structured_air_v2, field0.index) orelse return null;
    const tag1_return_add = typedAddConstUsing(structured_air_v2, field1.index) orelse return null;
    const tag1_store_add = typedAddConstUsingSecondI32Arg(structured_air_v2) orelse return null;
    if (tag0_return_add == 0 or tag1_return_add == 0 or tag1_store_add == 0) return null;
    return .{
        .tag0_return_add = tag0_return_add,
        .tag1_store_add = tag1_store_add,
        .tag1_return_add = tag1_return_add,
    };
}

pub fn typedOptionalPayloadBranchSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPayloadBranchSummary {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "wrap_optional") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_null") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 3 or
        typedReturnOpcodeCount(structured_air_v2) != 3)
    {
        return null;
    }

    const arg0 = typedNthI32ArgIndex(structured_air_v2, 0) orelse return null;
    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;
    const arg2 = typedNthI32ArgIndex(structured_air_v2, 2) orelse return null;

    const maybe_guard = typedBinaryInstConstRhs(structured_air_v2, "cmp_neq", arg0, 0) orelse return null;
    if (!typedCondBrUses(structured_air_v2, maybe_guard)) return null;

    const wrap_optional = singleInstructionByOpcode(structured_air_v2, "wrap_optional") orelse return null;
    if (wrap_optional.operands.len != 1 or typedInstOperandIndex(wrap_optional.operands[0]) != arg1) return null;

    const is_non_null = singleInstructionByOpcode(structured_air_v2, "is_non_null") orelse return null;
    const optional_payload = singleInstructionByOpcode(structured_air_v2, "optional_payload") orelse return null;
    if (is_non_null.operands.len != 1 or optional_payload.operands.len != 1) return null;
    const optional_value = typedInstOperandIndex(is_non_null.operands[0]) orelse return null;
    if (typedInstOperandIndex(optional_payload.operands[0]) != optional_value) return null;
    if (!typedCondBrUses(structured_air_v2, is_non_null.index)) return null;

    const threshold = typedBinaryInstConstRhsValue(structured_air_v2, "cmp_gt", optional_payload.index) orelse return null;
    const payload_guard = typedBinaryInstConstRhs(structured_air_v2, "cmp_gt", optional_payload.index, threshold) orelse return null;
    if (!typedCondBrUses(structured_air_v2, payload_guard)) return null;
    _ = typedBinaryInstInstRhsPrefix(structured_air_v2, "add", optional_payload.index, arg2) orelse return null;
    _ = typedBinaryInstInstRhsPrefix(structured_air_v2, "sub", optional_payload.index, arg2) orelse return null;

    const fallback = typedRetI32Const(structured_air_v2) orelse return null;
    return .{ .threshold = threshold, .fallback = fallback };
}

pub fn typedOptionalPayloadSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPayloadSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "block") != 2 or
        typedOpcodeCount(structured_air_v2, "cmp_neq") != 1 or
        typedOpcodeCount(structured_air_v2, "wrap_optional") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_null") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 4 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .fallback = typedLastBranchI32ConstValue(structured_air_v2) orelse return null };
}

pub fn typedOptionalPointerSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedOptionalPointerSummary {
    if (function_type.params.len != 1 or function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }

    const ret_count = typedReturnOpcodeCount(structured_air_v2);
    const block_count = typedOpcodeCount(structured_air_v2, "block");
    const non_null_count = typedOpcodeCount(structured_air_v2, "is_non_null");
    const br_count = typedOpcodeCount(structured_air_v2, "br");
    const cond_br_count = typedOpcodeCount(structured_air_v2, "cond_br");
    const release_fast_shape = block_count == 1 and non_null_count == 1 and br_count == 1 and cond_br_count == 1;
    const checked_unwrap_shape = block_count == 2 and
        non_null_count == 2 and
        br_count == 2 and
        cond_br_count == 2 and
        typedCalleeNameCount(structured_air_v2, "unwrapNull") == 1 and
        typedOpcodeCount(structured_air_v2, "unreach") == 1;
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "optional_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        ret_count != 2 or
        !(release_fast_shape or checked_unwrap_shape))
    {
        return null;
    }

    return .{
        .add_imm = typedFirstI32ConstOperandForOpcodes(structured_air_v2, &.{ "add", "add_safe" }, 1) orelse 0,
        .fallback = typedLastBranchOrReturnI32ConstValue(structured_air_v2) orelse return null,
        .checked_unwrap = checked_unwrap_shape,
    };
}

pub fn typedCheckedIntFromFloatSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedCheckedIntFromFloatSummary {
    if (function_type.params.len != 1) return null;
    const operand_ty = function_type.params[0].ir_type;
    if (!operand_ty.eql(.float) and !operand_ty.eql(.double)) return null;
    if (!function_type.return_type.ir_type.eql(.{ .int = 32 })) return null;
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lte") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_gte") != 1 or
        typedOpcodeCount(structured_air_v2, "bit_or") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "int_from_float") != 1 or
        typedCalleeNameCount(structured_air_v2, "integerPartOutOfBounds") != 1 or
        typedOpcodeCount(structured_air_v2, "unreach") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{
        .operand_ty = operand_ty,
        .low_value = typedConstantOperandValueText(structured_air_v2, "cmp_lte") orelse return null,
        .high_value = typedConstantOperandValueText(structured_air_v2, "cmp_gte") orelse return null,
    };
}

pub fn typedMixCAddMayPanicSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedMixCAddMayPanicSummary {
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        add_count != 1 or
        typedCalleeNameCount(structured_air_v2, "defaultPanic") != 1 or
        typedOpcodeCount(structured_air_v2, "unreach") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .checked_add = typedOpcodeCount(structured_air_v2, "add_safe") == 1 };
}

pub fn typedRuntimeOptionalPointerMainSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedRuntimeWrapperSummary {
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) return null;
    if (typedOpcodeCount(structured_air_v2, "call") != 2 or
        typedCalleeNameCount(structured_air_v2, "optionalPtrValue") != 2 or
        typedOpcodeCount(structured_air_v2, "cmp_eq") != 2 or
        typedOpcodeCount(structured_air_v2, "block") != 2 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        typedOpcodeCount(structured_air_v2, "br") != 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .optional_pointer_main };
}

pub fn typedRuntimePointerLoadStoreMainSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedRuntimeWrapperSummary {
    if (function_type.params.len != 0 or !function_type.return_type.ir_type.eql(.{ .int = 32 })) return null;
    if (typedOpcodeCount(structured_air_v2, "call") != 1 or
        typedCalleeNameCount(structured_air_v2, "loadStore") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_eq") != 2 or
        typedOpcodeCount(structured_air_v2, "block") != 2 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        typedOpcodeCount(structured_air_v2, "br") != 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .pointer_load_store_main };
}

pub fn typedPackedReadFlagSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedPackedFieldSummary {
    if (function_type.params.len != 1 or !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        typedOpcodeCount(structured_air_v2, "bitcast") != 2 or
        typedStoreOpcodeCount(structured_air_v2) != 1 or
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_2") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .read_flag };
}

pub fn typedPackedReplaceLowSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedPackedFieldSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 8 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        typedOpcodeCount(structured_air_v2, "bitcast") != 2 or
        typedStoreOpcodeCount(structured_air_v2) != 2 or
        typedOpcodeCount(structured_air_v2, "struct_field_ptr_index_0") != 1 or
        typedOpcodeCount(structured_air_v2, "trunc") != 1 or
        typedOpcodeCount(structured_air_v2, "load") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .replace_low };
}

pub fn typedSliceSumSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedSliceLoopSummary {
    if (function_type.params.len != 2 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "ptr_add") != 1 or
        typedOpcodeCount(structured_air_v2, "slice") != 1 or
        typedOpcodeCount(structured_air_v2, "ptr_slice_len_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "slice_elem_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") < 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") < 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 6 or
        typedStoreOpcodeCount(structured_air_v2) < 5 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .plain_sum };
}

pub fn typedConditionalSliceSumSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedSliceLoopSummary {
    if (function_type.params.len != 3 or function_type.params[0].ir_type != .ptr or
        !function_type.params[1].ir_type.eql(.{ .int = 64 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "alloc") != 3 or
        typedOpcodeCount(structured_air_v2, "ptr_elem_ptr") != 1 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "block") < 3 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 2 or
        typedOpcodeCount(structured_air_v2, "br") < 4 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_gt") != 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 6 or
        typedStoreOpcodeCount(structured_air_v2) < 5 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .conditional_sum };
}

pub fn typedAccumulatorLoopSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedScalarControlSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const intcast_count = typedOpcodeCount(structured_air_v2, "intcast") + typedOpcodeCount(structured_air_v2, "intcast_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "alloc") != 2 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        intcast_count != 1 or
        add_count != 2 or
        typedOpcodeCount(structured_air_v2, "load") < 4 or
        typedStoreOpcodeCount(structured_air_v2) < 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .accumulator_loop };
}

pub fn typedConditionalSlotUpdateSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedScalarControlSummary {
    if (function_type.params.len != 3 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[2].ir_type.eql(.{ .int = 1 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
    const sub_count = typedOpcodeCount(structured_air_v2, "sub") + typedOpcodeCount(structured_air_v2, "sub_safe");
    if (typedOpcodeCount(structured_air_v2, "arg") != 3 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 2 or
        add_count != 1 or
        sub_count != 1 or
        typedOpcodeCount(structured_air_v2, "load") < 3 or
        typedStoreOpcodeCount(structured_air_v2) < 4 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .conditional_slot_update };
}

pub fn typedLoopTrySummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedLoopTrySummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "alloc") != 2 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "call") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_eq") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 3 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedReturnOpcodeCount(structured_air_v2) != 2)
    {
        return null;
    }

    const call_instruction = singleInstructionByOpcode(structured_air_v2, "call") orelse return null;
    const details = callDetails(call_instruction) orelse return null;
    const typed_callee = details.callee orelse return null;
    if (std.mem.indexOf(u8, details.signature_text, "error{") == null) return null;
    if (!std.mem.endsWith(u8, details.signature_text, "!i32")) return null;
    if (call_instruction.operands.len != 3) return null;
    _ = typedI32InstOperandIndex(call_instruction.operands[1]) orelse return null;
    _ = typedI32InstOperandIndex(call_instruction.operands[2]) orelse return null;

    const is_non_err = singleInstructionByOpcode(structured_air_v2, "is_non_err") orelse return null;
    if (is_non_err.operands.len != 1 or typedInstOperandIndex(is_non_err.operands[0]) != call_instruction.index) return null;
    const payload = singleInstructionByOpcode(structured_air_v2, "unwrap_errunion_payload") orelse return null;
    if (payload.operands.len != 1 or typedInstOperandIndex(payload.operands[0]) != call_instruction.index) return null;
    const err = singleInstructionByOpcode(structured_air_v2, "unwrap_errunion_err") orelse return null;
    if (err.operands.len != 1 or typedInstOperandIndex(err.operands[0]) != call_instruction.index) return null;

    var error_return: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isReturnOpcode(instruction.opcode)) continue;
        if (typedConstI32Operand(instruction, 0)) |value| {
            if (error_return != null) return null;
            error_return = value;
        }
    }
    return .{
        .callee_name = typed_callee.name,
        .callee_external = typed_callee.external,
        .call_signature = details.signature_text,
        .error_return = error_return orelse return null,
    };
}

pub fn typedInlineAsmBarrierSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedInlineAsmSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "assembly") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .memory_barrier = true };
}

pub fn typedAtomicAddSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedAtomicRmwSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "atomic_rmw") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isAtomicRmwOpcode(instruction.opcode)) continue;
        if (!isTypedPayloadOpDataKind(instruction.data_kind) or instruction.operands.len != 1) return null;
        if (!isTypedPtrU32ConstOperand(instruction.operands[0])) return null;
        return .{ .instruction = instruction };
    }
    return null;
}

pub fn typedDenseIntegerSwitchSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedDenseIntegerSwitchSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    var results: [5]i32 = undefined;
    const result_count = typedBranchI32ConstValues(structured_air_v2, &results) orelse return null;
    if (result_count != results.len) return null;
    return .{ .results = results };
}

pub fn typedErrorSwitchSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedErrorSwitchSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "call") < 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 3 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .switch_dispatch };
}

pub fn typedErrorClassifierSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedErrorSwitchSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 8 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 1 or
        typedOpcodeCount(structured_air_v2, "br") != 3 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .classify };
}

pub fn typedErrorUnionPayloadSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedErrorUnionSummary {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "call") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 1 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 0 or
        typedOpcodeCount(structured_air_v2, "br") != 2 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{ .kind = .payload };
}

pub fn typedMaybeErrorSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedErrorUnionSummary {
    if (function_type.params.len != 1 or
        !function_type.return_type.ir_type.eql(.{ .int = 64 }) or
        !(function_type.params[0].ir_type.eql(.{ .int = 32 }) or function_type.params[0].ir_type.eql(.{ .int = 8 })) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "call") != 0 or
        typedOpcodeCount(structured_air_v2, "block") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_neq") != 1 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 0 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 0 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 0 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 0 or
        typedOpcodeCount(structured_air_v2, "br") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        typedReturnOpcodeCount(structured_air_v2) != 2)
    {
        return null;
    }
    return .{ .kind = .maybe_error };
}

fn typedUnionFieldVal(structured_air_v2: air_export.StructuredAirV2, field_index: usize) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "struct_field_val")) continue;
        if (fieldIndexUsize(instruction) != field_index) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
}

fn typedAddConstUsing(structured_air_v2: air_export.StructuredAirV2, operand_index: u32) ?i32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, "add")) continue;
        if (instruction.operands.len != 2) continue;
        const lhs_index = typedInstOperandIndex(instruction.operands[0]) orelse continue;
        if (lhs_index != operand_index) continue;
        return typedConstI32Operand(instruction, 1);
    }
    return null;
}

fn typedAddConstUsingSecondI32Arg(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;
    return typedAddConstUsing(structured_air_v2, arg1);
}

fn typedBinaryInstConstRhs(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
    lhs_index: u32,
    rhs_value: i32,
) ?u32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        const constant = typedConstI32Operand(instruction, 1) orelse continue;
        if (constant != rhs_value) continue;
        return instruction.index;
    }
    return null;
}

fn typedBinaryInstConstRhsValue(
    structured_air_v2: air_export.StructuredAirV2,
    opcode: []const u8,
    lhs_index: u32,
) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        const constant = typedConstI32Operand(instruction, 1) orelse continue;
        if (found != null) return null;
        found = constant;
    }
    return found;
}

fn typedBinaryInstInstRhsPrefix(
    structured_air_v2: air_export.StructuredAirV2,
    opcode_prefix: []const u8,
    lhs_index: u32,
    rhs_index: u32,
) ?u32 {
    var found: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, opcode_prefix)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != lhs_index) continue;
        if (typedInstOperandIndex(instruction.operands[1]) != rhs_index) continue;
        if (found != null) return null;
        found = instruction.index;
    }
    return found;
}

fn typedCondBrUses(structured_air_v2: air_export.StructuredAirV2, condition_index: u32) bool {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        if (instruction.operands.len == 0) continue;
        if (typedInstOperandIndex(instruction.operands[0]) == condition_index) return true;
    }
    return false;
}

fn typedRetI32Const(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and !std.mem.eql(u8, instruction.opcode, "ret_safe")) continue;
        if (instruction.operands.len != 1) continue;
        const constant = typedConstI32Operand(instruction, 0) orelse continue;
        if (found != null) return null;
        found = constant;
    }
    return found;
}

fn typedNthI32ArgIndex(structured_air_v2: air_export.StructuredAirV2, wanted: usize) ?u32 {
    var seen: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "arg")) continue;
        if (!std.mem.eql(u8, instruction.result_type, "i32")) continue;
        if (seen == wanted) return instruction.index;
        seen += 1;
    }
    return null;
}

fn typedDetailU32(instruction: air_export.TypedInstruction, key: []const u8) ?u32 {
    const text = detail(instruction, key) orelse return null;
    return std.fmt.parseInt(u32, text, 10) catch null;
}

test "typed AIR model parses instruction details and block operands" {
    var details = [_]air_export.TypedDetail{
        .{ .key = "callee_text", .value = "function 'helper'" },
        .{ .key = "operand1", .value = "@.void_value" },
    };
    const instruction = air_export.TypedInstruction{
        .index = 4,
        .opcode = "br",
        .result_type = "void",
        .data_kind = "br",
        .operands = &.{},
        .details = &details,
    };
    try std.testing.expectEqualStrings("function 'helper'", detail(instruction, "callee_text").?);
    try std.testing.expectEqualStrings("@.void_value", operandTextDetail(instruction, 1).?);

    try std.testing.expectEqual(@as(u32, 12), blockTarget(.{
        .kind = "block",
        .value = "block",
        .type_text = "12",
    }).?);
    try std.testing.expectEqual(@as(u32, 7), blockTarget(.{
        .kind = "block",
        .value = "7",
        .type_text = "ignored",
    }).?);
}

test "typed AIR model recognizes union tag payload switch summary" {
    var function_params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &function_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };

    var add_store_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "i32" },
        .{ .kind = "const", .value = "tag1_store_add", .type_text = "i32" },
    };
    var add_store_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 5>" },
    };
    var set_tag0_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*TaggedValue" },
        .{ .kind = "const", .value = "small", .type_text = "TaggedValue.Tag" },
    };
    var set_tag0_details = [_]air_export.TypedDetail{
        .{ .key = "tag_index", .value = "0" },
    };
    var set_tag1_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*TaggedValue" },
        .{ .kind = "const", .value = "large", .type_text = "TaggedValue.Tag" },
    };
    var set_tag1_details = [_]air_export.TypedDetail{
        .{ .key = "tag_index", .value = "1" },
    };
    var get_tag_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "12", .type_text = "TaggedValue" },
    };
    var switch_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "7", .type_text = "TaggedValue.Tag" },
    };
    var switch_details = [_]air_export.TypedDetail{
        .{ .key = "cases_len", .value = "2" },
        .{ .key = "case0_item0_tag_index", .value = "0" },
        .{ .key = "case1_item0_tag_index", .value = "1" },
    };
    var field0_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "12", .type_text = "TaggedValue" },
    };
    var field0_details = [_]air_export.TypedDetail{
        .{ .key = "field_index", .value = "0" },
    };
    var field1_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "12", .type_text = "TaggedValue" },
    };
    var field1_details = [_]air_export.TypedDetail{
        .{ .key = "field_index", .value = "1" },
    };
    var add_tag0_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "9", .type_text = "i32" },
        .{ .kind = "const", .value = "tag0_return_add", .type_text = "i32" },
    };
    var add_tag0_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 7>" },
    };
    var add_tag1_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "10", .type_text = "i32" },
        .{ .kind = "const", .value = "tag1_return_add", .type_text = "i32" },
    };
    var add_tag1_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 11>" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "13", .type_text = "i32" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "alloc", .result_type = "*TaggedValue", .data_kind = "ty", .operands = &.{} },
        .{ .index = 3, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_store_operands), .details = @constCast(&add_store_details) },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 5, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 6, .opcode = "set_union_tag", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&set_tag0_operands), .details = @constCast(&set_tag0_details) },
        .{ .index = 7, .opcode = "get_union_tag", .result_type = "TaggedValue.Tag", .data_kind = "ty_op", .operands = @constCast(&get_tag_operands) },
        .{ .index = 8, .opcode = "switch_br", .result_type = "noreturn", .data_kind = "switch_br", .operands = @constCast(&switch_operands), .details = @constCast(&switch_details) },
        .{ .index = 9, .opcode = "struct_field_val", .result_type = "i32", .data_kind = "ty_pl", .operands = @constCast(&field0_operands), .details = @constCast(&field0_details) },
        .{ .index = 10, .opcode = "struct_field_val", .result_type = "i32", .data_kind = "ty_pl", .operands = @constCast(&field1_operands), .details = @constCast(&field1_details) },
        .{ .index = 11, .opcode = "set_union_tag", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&set_tag1_operands), .details = @constCast(&set_tag1_details) },
        .{ .index = 12, .opcode = "load", .result_type = "TaggedValue", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 13, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_tag0_operands), .details = @constCast(&add_tag0_details) },
        .{ .index = 14, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_tag1_operands), .details = @constCast(&add_tag1_details) },
        .{ .index = 15, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = @constCast(&ret_operands) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = @constCast(&instructions) };

    const summary = typedUnionTagPayloadSwitchSummary(function_type, structured_air_v2).?;
    try std.testing.expectEqual(@as(i32, 7), summary.tag0_return_add);
    try std.testing.expectEqual(@as(i32, 5), summary.tag1_store_add);
    try std.testing.expectEqual(@as(i32, 11), summary.tag1_return_add);

    switch_operands[0].value = "0";
    try std.testing.expect(typedUnionTagPayloadSwitchSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model recognizes error switch and classifier summaries" {
    var error_switch_params = [_]ZigType{
        .{ .ir_type = .{ .int = 8 } },
    };
    const error_switch_type = FunctionType{
        .params = &error_switch_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const error_switch_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "call", .result_type = "error_union", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 2, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 3, .opcode = "is_non_err", .result_type = "i1", .data_kind = "un_op", .operands = &.{} },
        .{ .index = 4, .opcode = "unwrap_errunion_payload", .result_type = "i8", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 5, .opcode = "unwrap_errunion_err", .result_type = "i16", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 6, .opcode = "switch_br", .result_type = "noreturn", .data_kind = "switch_br", .operands = &.{} },
        .{ .index = 7, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 8, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 9, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 10, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 11, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const error_switch_air = air_export.StructuredAirV2{ .instructions = @constCast(&error_switch_instructions) };
    try std.testing.expectEqual(.switch_dispatch, typedErrorSwitchSummary(error_switch_type, error_switch_air).?.kind);

    const wrong_error_switch_type = FunctionType{
        .params = &error_switch_params,
        .return_type = .{ .ir_type = .{ .int = 64 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    try std.testing.expect(typedErrorSwitchSummary(wrong_error_switch_type, error_switch_air) == null);

    const classifier_type = FunctionType{
        .params = &error_switch_params,
        .return_type = .{ .ir_type = .{ .int = 64 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const classifier_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 2, .opcode = "switch_br", .result_type = "noreturn", .data_kind = "switch_br", .operands = &.{} },
        .{ .index = 3, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 4, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 5, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 6, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const classifier_air = air_export.StructuredAirV2{ .instructions = @constCast(&classifier_instructions) };
    try std.testing.expectEqual(.classify, typedErrorClassifierSummary(classifier_type, classifier_air).?.kind);
    try std.testing.expect(typedErrorClassifierSummary(error_switch_type, classifier_air) == null);
}

test "typed AIR model recognizes error-union payload and maybe-error summaries" {
    var i32_param = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const payload_type = FunctionType{
        .params = &i32_param,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var payload_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "call", .result_type = "error_union", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 2, .opcode = "is_non_err", .result_type = "i1", .data_kind = "un_op", .operands = &.{} },
        .{ .index = 3, .opcode = "unwrap_errunion_payload", .result_type = "i32", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 4, .opcode = "unwrap_errunion_err", .result_type = "i16", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 5, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 6, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 7, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 8, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 9, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const payload_air = air_export.StructuredAirV2{ .instructions = &payload_instructions };
    try std.testing.expectEqual(.payload, typedErrorUnionPayloadSummary(payload_type, payload_air).?.kind);

    payload_instructions[5].opcode = "switch_br";
    try std.testing.expect(typedErrorUnionPayloadSummary(payload_type, payload_air) == null);

    const maybe_type = FunctionType{
        .params = &i32_param,
        .return_type = .{ .ir_type = .{ .int = 64 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var maybe_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 2, .opcode = "cmp_neq", .result_type = "i1", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 3, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 4, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 5, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
        .{ .index = 6, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const maybe_air = air_export.StructuredAirV2{ .instructions = &maybe_instructions };
    try std.testing.expectEqual(.maybe_error, typedMaybeErrorSummary(maybe_type, maybe_air).?.kind);

    maybe_instructions[1].opcode = "call";
    try std.testing.expect(typedMaybeErrorSummary(maybe_type, maybe_air) == null);
}

test "typed AIR model recognizes optional payload summary" {
    var params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var fallback_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "0", .type_text = "0" },
        .{ .kind = "const", .value = "fallback", .type_text = "i32" },
    };
    var fallback_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, -21>" },
    };
    var instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "arg"),
        testTypedInstruction(2, "block"),
        testTypedInstruction(3, "block"),
        testTypedInstruction(4, "cmp_neq"),
        testTypedInstruction(5, "wrap_optional"),
        testTypedInstruction(6, "is_non_null"),
        testTypedInstruction(7, "optional_payload"),
        testTypedInstruction(8, "br"),
        testTypedInstruction(9, "br"),
        testTypedInstruction(10, "br"),
        .{ .index = 11, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&fallback_operands), .details = @constCast(&fallback_details) },
        testTypedInstruction(12, "cond_br"),
        testTypedInstruction(13, "cond_br"),
        testTypedInstruction(14, "ret"),
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    try std.testing.expectEqual(@as(i32, -21), typedOptionalPayloadSummary(function_type, structured_air_v2).?.fallback);

    instructions[11].operands = &.{};
    try std.testing.expect(typedOptionalPayloadSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model recognizes optional pointer summary" {
    var pointer_param = [_]ZigType{
        .{ .ir_type = .ptr },
    };
    const function_type = FunctionType{
        .params = &pointer_param,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var add_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "5", .type_text = "i32" },
        .{ .kind = "const", .value = "imm", .type_text = "i32" },
    };
    var add_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 7>" },
    };
    var ret_payload_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "6", .type_text = "i32" },
    };
    var ret_fallback_operands = [_]air_export.TypedOperand{
        .{ .kind = "const", .value = "fallback", .type_text = "i32" },
    };
    var ret_fallback_details = [_]air_export.TypedDetail{
        .{ .key = "operand0_text", .value = "<i32, -9>" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "is_non_null", .result_type = "i1", .data_kind = "un_op", .operands = &.{} },
        .{ .index = 2, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 3, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &.{} },
        .{ .index = 4, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &.{} },
        .{ .index = 5, .opcode = "optional_payload", .result_type = "*i32", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 6, .opcode = "load", .result_type = "i32", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 7, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_operands), .details = @constCast(&add_details) },
        .{ .index = 8, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = @constCast(&ret_payload_operands) },
        .{ .index = 9, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = @constCast(&ret_fallback_operands), .details = @constCast(&ret_fallback_details) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    const summary = typedOptionalPointerSummary(function_type, structured_air_v2).?;
    try std.testing.expectEqual(@as(i32, 7), summary.add_imm);
    try std.testing.expectEqual(@as(i32, -9), summary.fallback);
    try std.testing.expect(!summary.checked_unwrap);

    instructions[9].operands = &.{};
    try std.testing.expect(typedOptionalPointerSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model recognizes packed field summaries" {
    var one_i8_param = [_]ZigType{
        .{ .ir_type = .{ .int = 8 } },
    };
    const read_type = FunctionType{
        .params = &one_i8_param,
        .return_type = .{ .ir_type = .{ .int = 1 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    const read_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "alloc", .result_type = "*Packed", .data_kind = "ty", .operands = &.{} },
        .{ .index = 2, .opcode = "bitcast", .result_type = "*i8", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 3, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 4, .opcode = "struct_field_ptr_index_2", .result_type = "*u1", .data_kind = "field_ptr", .operands = &.{} },
        .{ .index = 5, .opcode = "load", .result_type = "i1", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 6, .opcode = "bitcast", .result_type = "i1", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 7, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const read_air = air_export.StructuredAirV2{ .instructions = @constCast(&read_instructions) };
    try std.testing.expectEqual(.read_flag, typedPackedReadFlagSummary(read_type, read_air).?.kind);

    var two_i8_params = [_]ZigType{
        .{ .ir_type = .{ .int = 8 } },
        .{ .ir_type = .{ .int = 8 } },
    };
    const replace_type = FunctionType{
        .params = &two_i8_params,
        .return_type = .{ .ir_type = .{ .int = 8 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var replace_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i8", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "alloc", .result_type = "*Packed", .data_kind = "ty", .operands = &.{} },
        .{ .index = 3, .opcode = "bitcast", .result_type = "*i8", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 5, .opcode = "struct_field_ptr_index_0", .result_type = "*u3", .data_kind = "field_ptr", .operands = &.{} },
        .{ .index = 6, .opcode = "trunc", .result_type = "i3", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 7, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = &.{} },
        .{ .index = 8, .opcode = "load", .result_type = "i8", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 9, .opcode = "bitcast", .result_type = "i8", .data_kind = "ty_op", .operands = &.{} },
        .{ .index = 10, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const replace_air = air_export.StructuredAirV2{ .instructions = &replace_instructions };
    try std.testing.expectEqual(.replace_low, typedPackedReplaceLowSummary(replace_type, replace_air).?.kind);

    replace_instructions[6].opcode = "intcast";
    try std.testing.expect(typedPackedReplaceLowSummary(replace_type, replace_air) == null);
}

fn testTypedInstruction(index: u32, opcode: []const u8) air_export.TypedInstruction {
    return .{
        .index = index,
        .opcode = opcode,
        .result_type = "-",
        .data_kind = "-",
        .operands = &.{},
    };
}

test "typed AIR model recognizes slice loop summaries" {
    var plain_params = [_]ZigType{
        .{ .ir_type = .ptr },
        .{ .ir_type = .{ .int = 64 } },
    };
    const plain_type = FunctionType{
        .params = &plain_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var plain_instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "arg"),
        testTypedInstruction(2, "ptr_add"),
        testTypedInstruction(3, "slice"),
        testTypedInstruction(4, "ptr_slice_len_ptr"),
        testTypedInstruction(5, "slice_elem_ptr"),
        testTypedInstruction(6, "loop"),
        testTypedInstruction(7, "repeat"),
        testTypedInstruction(8, "cond_br"),
        testTypedInstruction(9, "cmp_lt"),
        testTypedInstruction(10, "add"),
        testTypedInstruction(11, "add"),
        testTypedInstruction(12, "load"),
        testTypedInstruction(13, "load"),
        testTypedInstruction(14, "load"),
        testTypedInstruction(15, "load"),
        testTypedInstruction(16, "load"),
        testTypedInstruction(17, "load"),
        testTypedInstruction(18, "store"),
        testTypedInstruction(19, "store"),
        testTypedInstruction(20, "store"),
        testTypedInstruction(21, "store"),
        testTypedInstruction(22, "store"),
        testTypedInstruction(23, "ret"),
    };
    const plain_air = air_export.StructuredAirV2{ .instructions = &plain_instructions };
    try std.testing.expectEqual(.plain_sum, typedSliceSumSummary(plain_type, plain_air).?.kind);

    plain_instructions[5].opcode = "load";
    try std.testing.expect(typedSliceSumSummary(plain_type, plain_air) == null);

    var conditional_params = [_]ZigType{
        .{ .ir_type = .ptr },
        .{ .ir_type = .{ .int = 64 } },
        .{ .ir_type = .{ .int = 32 } },
    };
    const conditional_type = FunctionType{
        .params = &conditional_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var conditional_instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "arg"),
        testTypedInstruction(2, "arg"),
        testTypedInstruction(3, "alloc"),
        testTypedInstruction(4, "alloc"),
        testTypedInstruction(5, "alloc"),
        testTypedInstruction(6, "ptr_elem_ptr"),
        testTypedInstruction(7, "loop"),
        testTypedInstruction(8, "repeat"),
        testTypedInstruction(9, "block"),
        testTypedInstruction(10, "block"),
        testTypedInstruction(11, "block"),
        testTypedInstruction(12, "cond_br"),
        testTypedInstruction(13, "cond_br"),
        testTypedInstruction(14, "br"),
        testTypedInstruction(15, "br"),
        testTypedInstruction(16, "br"),
        testTypedInstruction(17, "br"),
        testTypedInstruction(18, "cmp_lt"),
        testTypedInstruction(19, "cmp_gt"),
        testTypedInstruction(20, "add"),
        testTypedInstruction(21, "add"),
        testTypedInstruction(22, "load"),
        testTypedInstruction(23, "load"),
        testTypedInstruction(24, "load"),
        testTypedInstruction(25, "load"),
        testTypedInstruction(26, "load"),
        testTypedInstruction(27, "load"),
        testTypedInstruction(28, "store"),
        testTypedInstruction(29, "store"),
        testTypedInstruction(30, "store"),
        testTypedInstruction(31, "store"),
        testTypedInstruction(32, "store"),
        testTypedInstruction(33, "ret"),
    };
    const conditional_air = air_export.StructuredAirV2{ .instructions = &conditional_instructions };
    try std.testing.expectEqual(.conditional_sum, typedConditionalSliceSumSummary(conditional_type, conditional_air).?.kind);

    conditional_instructions[19].opcode = "cmp_eq";
    try std.testing.expect(typedConditionalSliceSumSummary(conditional_type, conditional_air) == null);
}

test "typed AIR model recognizes scalar control summaries" {
    var loop_params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const loop_type = FunctionType{
        .params = &loop_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var loop_instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "alloc"),
        testTypedInstruction(2, "alloc"),
        testTypedInstruction(3, "loop"),
        testTypedInstruction(4, "repeat"),
        testTypedInstruction(5, "cond_br"),
        testTypedInstruction(6, "cmp_lt"),
        testTypedInstruction(7, "intcast"),
        testTypedInstruction(8, "add"),
        testTypedInstruction(9, "add"),
        testTypedInstruction(10, "load"),
        testTypedInstruction(11, "load"),
        testTypedInstruction(12, "load"),
        testTypedInstruction(13, "load"),
        testTypedInstruction(14, "store"),
        testTypedInstruction(15, "store"),
        testTypedInstruction(16, "store"),
        testTypedInstruction(17, "store"),
        testTypedInstruction(18, "ret"),
    };
    const loop_air = air_export.StructuredAirV2{ .instructions = &loop_instructions };
    try std.testing.expectEqual(.accumulator_loop, typedAccumulatorLoopSummary(loop_type, loop_air).?.kind);

    loop_instructions[7].opcode = "bitcast";
    try std.testing.expect(typedAccumulatorLoopSummary(loop_type, loop_air) == null);

    var slot_params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 32 } },
        .{ .ir_type = .{ .int = 1 } },
    };
    const slot_type = FunctionType{
        .params = &slot_params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var slot_instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "arg"),
        testTypedInstruction(2, "arg"),
        testTypedInstruction(3, "alloc"),
        testTypedInstruction(4, "block"),
        testTypedInstruction(5, "cond_br"),
        testTypedInstruction(6, "br"),
        testTypedInstruction(7, "br"),
        testTypedInstruction(8, "add"),
        testTypedInstruction(9, "sub"),
        testTypedInstruction(10, "load"),
        testTypedInstruction(11, "load"),
        testTypedInstruction(12, "load"),
        testTypedInstruction(13, "store"),
        testTypedInstruction(14, "store"),
        testTypedInstruction(15, "store"),
        testTypedInstruction(16, "store"),
        testTypedInstruction(17, "ret"),
    };
    const slot_air = air_export.StructuredAirV2{ .instructions = &slot_instructions };
    try std.testing.expectEqual(.conditional_slot_update, typedConditionalSlotUpdateSummary(slot_type, slot_air).?.kind);

    slot_instructions[9].opcode = "mul";
    try std.testing.expect(typedConditionalSlotUpdateSummary(slot_type, slot_air) == null);
}

test "typed AIR model recognizes inline asm barrier summary" {
    var params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "assembly"),
        testTypedInstruction(2, "ret"),
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    try std.testing.expect((typedInlineAsmBarrierSummary(function_type, structured_air_v2) orelse return error.TestUnexpectedResult).memory_barrier);

    instructions[1].opcode = "call";
    try std.testing.expect(typedInlineAsmBarrierSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model recognizes atomic add summary" {
    var params = [_]ZigType{
        .{ .ir_type = .{ .int = 32 } },
    };
    const function_type = FunctionType{
        .params = &params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var atomic_operands = [_]air_export.TypedOperand{
        .{ .kind = "const", .value = "ptr", .type_text = "*u32" },
    };
    var instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        .{
            .index = 1,
            .opcode = "atomic_rmw",
            .result_type = "u32",
            .data_kind = "pl_op",
            .operands = @constCast(&atomic_operands),
        },
        testTypedInstruction(2, "ret"),
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    try std.testing.expectEqual(@as(u32, 1), typedAtomicAddSummary(function_type, structured_air_v2).?.instruction.index);

    instructions[1].data_kind = "bin_op";
    try std.testing.expect(typedAtomicAddSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model recognizes dense integer switch summary" {
    var params = [_]ZigType{
        .{ .ir_type = .{ .int = 8 } },
    };
    const function_type = FunctionType{
        .params = &params,
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = true,
        .non_default_calling_convention = false,
    };
    var br0_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "0", .type_text = "0" },
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    var br1_operands = br0_operands;
    var br2_operands = br0_operands;
    var br3_operands = br0_operands;
    var br4_operands = br0_operands;
    var br0_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 10>" }};
    var br1_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 20>" }};
    var br2_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 30>" }};
    var br3_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 40>" }};
    var br4_details = [_]air_export.TypedDetail{.{ .key = "operand1_text", .value = "<i32, 50>" }};
    var instructions = [_]air_export.TypedInstruction{
        testTypedInstruction(0, "arg"),
        testTypedInstruction(1, "block"),
        testTypedInstruction(2, "switch_br"),
        .{ .index = 3, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&br0_operands), .details = @constCast(&br0_details) },
        .{ .index = 4, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&br1_operands), .details = @constCast(&br1_details) },
        .{ .index = 5, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&br2_operands), .details = @constCast(&br2_details) },
        .{ .index = 6, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&br3_operands), .details = @constCast(&br3_details) },
        .{ .index = 7, .opcode = "br", .result_type = "void", .data_kind = "br", .operands = @constCast(&br4_operands), .details = @constCast(&br4_details) },
        testTypedInstruction(8, "ret"),
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = &instructions };
    try std.testing.expectEqual([_]i32{ 10, 20, 30, 40, 50 }, typedDenseIntegerSwitchSummary(function_type, structured_air_v2).?.results);

    instructions[7].opcode = "ret";
    try std.testing.expect(typedDenseIntegerSwitchSummary(function_type, structured_air_v2) == null);
}

test "typed AIR model collects branch i32 constants" {
    const br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "0", .type_text = "0" },
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    const add_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "i32" },
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    var br_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 7>" },
    };
    var add_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 11>" },
    };
    const ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    var ret_details = [_]air_export.TypedDetail{
        .{ .key = "operand0_text", .value = "<i32, -49>" },
    };
    const instructions = [_]air_export.TypedInstruction{
        .{
            .index = 0,
            .opcode = "br",
            .result_type = "void",
            .data_kind = "br",
            .operands = @constCast(&br_operands),
            .details = &br_details,
        },
        .{
            .index = 1,
            .opcode = "add",
            .result_type = "i32",
            .data_kind = "bin_op",
            .operands = @constCast(&add_operands),
            .details = &add_details,
        },
        .{
            .index = 2,
            .opcode = "ret",
            .result_type = "void",
            .data_kind = "un_op",
            .operands = @constCast(&ret_operands),
            .details = &ret_details,
        },
    };
    const structured_air_v2 = air_export.StructuredAirV2{
        .instructions = @constCast(&instructions),
    };
    var values: [2]i32 = undefined;

    try std.testing.expectEqual(@as(i32, 7), typedBranchI32ConstValue(instructions[0]).?);
    try std.testing.expectEqual(@as(i32, 7), typedLastBranchI32ConstValue(structured_air_v2).?);
    try std.testing.expectEqual(@as(i32, -49), typedReturnI32ConstValue(instructions[2]).?);
    try std.testing.expectEqual(@as(i32, -49), typedLastBranchOrReturnI32ConstValue(structured_air_v2).?);
    try std.testing.expectEqual(@as(usize, 1), typedBranchI32ConstValues(structured_air_v2, &values).?);
    try std.testing.expectEqual(@as(i32, 7), values[0]);
    try std.testing.expectEqual(@as(i32, 11), typedFirstI32ConstOperandForOpcodes(structured_air_v2, &.{"add"}, 1).?);
    try std.testing.expect(typedFirstI32ConstOperandForOpcodes(structured_air_v2, &.{"sub"}, 1) == null);
}

test "typed AIR model parses direct and extern callees" {
    const direct = callee("function 'local_helper'").?;
    try std.testing.expectEqualStrings("local_helper", direct.name);
    try std.testing.expect(!direct.external);
    try std.testing.expectEqualStrings("local_helper", calleeName("function 'local_helper'").?);

    const external = callee("extern 'debug.defaultPanic'").?;
    try std.testing.expectEqualStrings("debug.defaultPanic", external.name);
    try std.testing.expect(external.external);
}

test "typed AIR model reports type and operand coverage" {
    const operand = air_export.TypedOperand{
        .kind = "ref",
        .value = "%0",
        .type_text = "i32",
    };
    const instructions = [_]air_export.TypedInstruction{
        .{
            .index = 0,
            .opcode = "arg",
            .result_type = "i32",
            .data_kind = "arg",
            .operands = &.{},
        },
        .{
            .index = 1,
            .opcode = "ret",
            .result_type = "void",
            .data_kind = "un_op",
            .operands = @constCast(&[_]air_export.TypedOperand{operand}),
        },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = @constCast(&instructions) };
    const function = air_export.Function{
        .name = "test.main",
        .type_text = "fn () void",
        .instruction_count = 2,
        .main_body_count = 2,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = &.{},
    };
    try std.testing.expect(typedResultCoverage(function, structured_air_v2));
    try std.testing.expect(typedOperandCoverage(structured_air_v2));

    const missing_result_instructions = [_]air_export.TypedInstruction{.{
        .index = 0,
        .opcode = "arg",
        .result_type = "-",
        .data_kind = "arg",
        .operands = &.{},
    }};
    try std.testing.expect(!typedResultCoverage(
        function,
        .{ .instructions = @constCast(&missing_result_instructions) },
    ));

    const missing_operand = air_export.TypedOperand{
        .kind = "ref",
        .value = "%0",
        .type_text = "-",
    };
    const missing_operand_instructions = [_]air_export.TypedInstruction{.{
        .index = 0,
        .opcode = "ret",
        .result_type = "void",
        .data_kind = "un_op",
        .operands = @constCast(&[_]air_export.TypedOperand{missing_operand}),
    }};
    try std.testing.expect(!typedOperandCoverage(.{
        .instructions = @constCast(&missing_operand_instructions),
    }));
}

test "typed AIR model summarizes pointer and slice address expressions" {
    const ptr_operand = air_export.TypedOperand{ .kind = "inst", .value = "%ptr", .type_text = "ptr" };
    const idx_operand = air_export.TypedOperand{ .kind = "inst", .value = "%idx", .type_text = "usize" };
    const const_operand = air_export.TypedOperand{ .kind = "int", .value = "2", .type_text = "usize" };
    const load_operand = air_export.TypedOperand{ .kind = "inst", .value = "%gep", .type_text = "ptr" };
    const instructions = [_]air_export.TypedInstruction{
        .{
            .index = 0,
            .opcode = "slice",
            .result_type = "{ ptr, i64 }",
            .data_kind = "ty_pl",
            .operands = @constCast(&[_]air_export.TypedOperand{ ptr_operand, idx_operand }),
        },
        .{
            .index = 1,
            .opcode = "slice_ptr",
            .result_type = "ptr",
            .data_kind = "ty_op",
            .operands = @constCast(&[_]air_export.TypedOperand{ptr_operand}),
        },
        .{
            .index = 2,
            .opcode = "ptr_add",
            .result_type = "ptr",
            .data_kind = "bin_ty_pl",
            .operands = @constCast(&[_]air_export.TypedOperand{ ptr_operand, const_operand }),
        },
        .{
            .index = 3,
            .opcode = "ptr_sub",
            .result_type = "ptr",
            .data_kind = "bin_ty_pl",
            .operands = @constCast(&[_]air_export.TypedOperand{ ptr_operand, const_operand }),
        },
        .{
            .index = 4,
            .opcode = "slice_elem_ptr",
            .result_type = "ptr",
            .data_kind = "ty_pl",
            .operands = @constCast(&[_]air_export.TypedOperand{ ptr_operand, idx_operand }),
        },
        .{
            .index = 5,
            .opcode = "load",
            .result_type = "i32",
            .data_kind = "ty_op",
            .operands = @constCast(&[_]air_export.TypedOperand{load_operand}),
        },
        .{
            .index = 6,
            .opcode = "store",
            .result_type = "void",
            .data_kind = "bin_op",
            .operands = @constCast(&[_]air_export.TypedOperand{ load_operand, .{ .kind = "inst", .value = "%value", .type_text = "i32" } }),
        },
        .{
            .index = 7,
            .opcode = "cond_br",
            .result_type = "void",
            .data_kind = "pl_op",
            .operands = @constCast(&[_]air_export.TypedOperand{idx_operand}),
        },
    };
    const structured_air = air_export.StructuredAir{
        .instructions = &.{},
        .bodies = &.{},
        .branches = &.{},
        .cond_branches = &.{},
        .repeats = &.{},
    };
    const function = air_export.Function{
        .name = "test.pointer_slice",
        .type_text = "fn ([*]i32, usize) i32",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = structured_air,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = @constCast(&instructions) },
        .instructions = &.{},
    };
    const summary = pointerSliceAddressSummary(function).?;

    try std.testing.expectEqual(@as(usize, 1), summary.ptr_add_count);
    try std.testing.expectEqual(@as(usize, 1), summary.ptr_sub_count);
    try std.testing.expectEqual(@as(usize, 1), summary.slice_count);
    try std.testing.expectEqual(@as(usize, 1), summary.slice_ptr_count);
    try std.testing.expectEqual(@as(usize, 1), summary.slice_elem_ptr_count);
    try std.testing.expectEqual(@as(usize, 1), summary.load_count);
    try std.testing.expectEqual(@as(usize, 1), summary.store_count);
    try std.testing.expect(summary.bounds_check_count != 0);
    try std.testing.expectEqualStrings("%ptr", summary.base_pointer_operand.?);
    try std.testing.expectEqualStrings("%idx", summary.dynamic_index_operand.?);
    try std.testing.expectEqual(@as(i128, 2), summary.constant_index.?);
    try std.testing.expectEqual(@as(u16, 32), summary.scalar_width_bits.?);
    try std.testing.expectEqual(@as(u32, 0), summary.slice_source_index.?);
}

test "AIR model reports legacy instruction opcode presence" {
    const instructions = [_]air_export.Instruction{
        .{
            .index = 0,
            .indent = 0,
            .unused = false,
            .opcode = "arg",
            .payload = "",
            .category = .argument,
        },
        .{
            .index = 1,
            .indent = 0,
            .unused = false,
            .opcode = "add_safe",
            .payload = "",
            .category = .arithmetic,
        },
    };
    const function = air_export.Function{
        .name = "test.main",
        .type_text = "fn (i32) i32",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&instructions),
    };

    try std.testing.expect(functionHasOpcode(function, "add_safe"));
    try std.testing.expect(!functionHasOpcode(function, "mul"));
}

test "AIR model reports semantic operation presence" {
    const instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "is_non_null", .payload = "", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "optional_payload", .payload = "", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "", .category = .other },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %0!", .category = .memory },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "slice", .payload = "", .category = .other },
        .{ .index = 6, .indent = 0, .unused = false, .opcode = "store_safe", .payload = "%0!, %1!", .category = .memory },
        .{ .index = 7, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_1", .payload = "", .category = .memory },
        .{ .index = 8, .indent = 0, .unused = false, .opcode = "ret_safe", .payload = "%1!", .category = .return_op },
        .{ .index = 9, .indent = 0, .unused = false, .opcode = "call", .payload = "", .category = .call },
        .{ .index = 10, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 11, .indent = 0, .unused = false, .opcode = "unreach", .payload = "", .category = .control_flow },
    };
    const function = air_export.Function{
        .name = "test.main",
        .type_text = "fn () void",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&instructions),
    };

    try std.testing.expect(functionHasOptionalOp(function, .is_non_null));
    try std.testing.expect(functionHasOptionalOp(function, .optional_payload));
    try std.testing.expect(!functionHasOptionalOp(function, .wrap_optional));
    try std.testing.expect(functionHasErrorUnionOp(function, .unwrap_payload));
    try std.testing.expect(functionHasErrorUnionOp(function, .is_non_err));
    try std.testing.expect(functionHasMemoryOp(function, .load));
    try std.testing.expect(functionHasPointerAggregateOp(function, .slice));
    try std.testing.expect(functionHasStoreOp(function));
    try std.testing.expect(functionHasFieldPtrIndex(function, 1));
    try std.testing.expect(!functionHasFieldPtrIndex(function, 0));
    try std.testing.expect(functionHasReturnOp(function));
    try std.testing.expect(functionHasCallOp(function));
    try std.testing.expect(functionHasCfgOp(function, .block));
    try std.testing.expect(functionHasCfgOp(function, .unreach));
    try std.testing.expect(!functionHasCfgOp(function, .cond_br));
}

test "AIR model recognizes selected integer switch admission structurally" {
    const switch_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "u8, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 2, .indent = 1, .unused = false, .opcode = "switch_br", .payload = "%0!", .category = .control_flow },
        .{ .index = 3, .indent = 2, .unused = false, .opcode = "br", .payload = "%1!, <i32, 10>", .category = .control_flow },
        .{ .index = 4, .indent = 2, .unused = false, .opcode = "br", .payload = "%1!, <i32, 20>", .category = .control_flow },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const switch_function = air_export.Function{
        .name = "not_named_integer_switch",
        .type_text = "fn (u8) i32",
        .instruction_count = switch_instructions.len,
        .main_body_count = switch_instructions.len,
        .has_liveness = true,
        .air_text = "switch_br %0\n  <u8, 0> => {\n    br(<i32, 10>)\n  }\n  <u8, 1>...<u8, 3> => {\n    br(<i32, 11>)\n  }\n  else => {\n    br(<i32, 20>)\n  }",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&switch_instructions),
    };
    const summary = integerSwitchSummary(switch_function).?;
    try std.testing.expectEqual(@as(u32, 2), summary.switch_br);
    try std.testing.expectEqual(@as(usize, 1), summary.block_count);
    try std.testing.expectEqual(@as(usize, 2), summary.branch_count);
    try std.testing.expect(summary.has_default_arm_text);
    try std.testing.expect(selectedIntegerSwitchShape(switch_function));
    const plan = (try integerSwitchPlan(std.testing.allocator, switch_function)).?;
    defer plan.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 2), plan.switch_br);
    try std.testing.expectEqual(@as(i32, 20), plan.default_result);
    try std.testing.expectEqual(@as(usize, 2), plan.arms.len);
    try std.testing.expectEqual(@as(u8, 0), plan.arms[0].first);
    try std.testing.expectEqual(@as(u8, 0), plan.arms[0].last);
    try std.testing.expectEqual(@as(i32, 10), plan.arms[0].result);
    try std.testing.expectEqual(@as(u8, 1), plan.arms[1].first);
    try std.testing.expectEqual(@as(u8, 3), plan.arms[1].last);
    try std.testing.expectEqual(@as(i32, 11), plan.arms[1].result);

    const missing_default = air_export.Function{
        .name = "not_named_integer_switch_without_default",
        .type_text = "fn (u8) i32",
        .instruction_count = switch_instructions.len,
        .main_body_count = switch_instructions.len,
        .has_liveness = true,
        .air_text = "switch_br %0\n  0 => {\n    br(<i32, 10>)\n  }",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&switch_instructions),
    };
    try std.testing.expect(integerSwitchSummary(missing_default) == null);
    try std.testing.expect((try integerSwitchPlan(std.testing.allocator, missing_default)) == null);
}

test "AIR model recognizes selected optional shapes structurally" {
    const optional_pointer_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "?*const i32, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_null", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "optional_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %2!", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%3!", .category = .return_op },
    };
    const optional_pointer = air_export.Function{
        .name = "not_named_optional_pointer",
        .type_text = "fn (?*const i32) i32",
        .instruction_count = optional_pointer_instructions.len,
        .main_body_count = optional_pointer_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&optional_pointer_instructions),
    };
    const pointer_summary = optionalPointerSummary(optional_pointer).?;
    try std.testing.expectEqual(.pointer_payload, pointer_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), pointer_summary.optional_value.?);
    try std.testing.expectEqual(@as(u32, 1), pointer_summary.condition);
    try std.testing.expectEqual(@as(u32, 2), pointer_summary.payload);
    try std.testing.expectEqual(@as(u32, 3), pointer_summary.load.?);
    try std.testing.expectEqual(@as(u32, 3), pointer_summary.return_value.?);
    try std.testing.expect(selectedOptionalPointerShape(optional_pointer));

    const bad_optional_pointer_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "?*const i32, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_null", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "optional_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const bad_optional_pointer = air_export.Function{
        .name = "not_named_bad_optional_pointer",
        .type_text = "fn (?*const i32) i32",
        .instruction_count = bad_optional_pointer_instructions.len,
        .main_body_count = bad_optional_pointer_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_optional_pointer_instructions),
    };
    try std.testing.expect(optionalPointerSummary(bad_optional_pointer) == null);

    const optional_payload_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "wrap_optional", .payload = "%arg1!", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_null", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "optional_payload", .payload = "%0!", .category = .other },
    };
    const optional_payload = air_export.Function{
        .name = "not_named_optional_payload",
        .type_text = "fn (i32, i32) i32",
        .instruction_count = optional_payload_instructions.len,
        .main_body_count = optional_payload_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&optional_payload_instructions),
    };
    const payload_summary = optionalPayloadSummary(optional_payload).?;
    try std.testing.expectEqual(.scalar_payload, payload_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), payload_summary.wrap.?);
    try std.testing.expectEqual(@as(u32, 1), payload_summary.condition);
    try std.testing.expectEqual(@as(u32, 2), payload_summary.payload);
    try std.testing.expect(selectedOptionalPayloadShape(optional_payload));

    const unrelated_optional_payload_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "wrap_optional", .payload = "%arg1!", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_null", .payload = "%99!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "optional_payload", .payload = "%0!", .category = .other },
    };
    const unrelated_optional_payload = air_export.Function{
        .name = "not_named_unrelated_optional_payload",
        .type_text = "fn (i32, i32) i32",
        .instruction_count = unrelated_optional_payload_instructions.len,
        .main_body_count = unrelated_optional_payload_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_optional_payload_instructions),
    };
    try std.testing.expect(optionalPayloadSummary(unrelated_optional_payload) == null);
}

test "AIR model recognizes selected aggregate shapes structurally" {
    const array_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "aggregate_init", .payload = "[3]i32, [%0!, %1!, %2!]", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "ptr_elem_ptr", .payload = "", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %1!", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "ptr_elem_ptr", .payload = "", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %3!", .category = .memory },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "add", .payload = "%2!, %4!", .category = .other },
        .{ .index = 6, .indent = 0, .unused = false, .opcode = "ptr_elem_ptr", .payload = "", .category = .memory },
        .{ .index = 7, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %6!", .category = .memory },
        .{ .index = 8, .indent = 0, .unused = false, .opcode = "add", .payload = "%5!, %7!", .category = .other },
    };
    const array_sum = air_export.Function{
        .name = "not_named_array_sum",
        .type_text = "fn () i32",
        .instruction_count = array_sum_instructions.len,
        .main_body_count = array_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&array_sum_instructions),
    };
    const array_summary = arraySumSummary(array_sum).?;
    try std.testing.expectEqual(@as(u32, 0), array_summary.aggregate_init);
    try std.testing.expectEqual(@as(usize, 3), array_summary.elem_ptr_count);
    try std.testing.expectEqual(@as(usize, 3), array_summary.load_count);
    try std.testing.expectEqual(@as(usize, 2), array_summary.add_count);
    try std.testing.expect(selectedArraySumShape(array_sum));

    const bad_array_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "aggregate_init", .payload = "[2]i32, [%0!, %1!]", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "ptr_elem_ptr", .payload = "", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %1!", .category = .memory },
    };
    const bad_array_sum = air_export.Function{
        .name = "not_named_bad_array_sum",
        .type_text = "fn () i32",
        .instruction_count = bad_array_sum_instructions.len,
        .main_body_count = bad_array_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_array_sum_instructions),
    };
    try std.testing.expect(arraySumSummary(bad_array_sum) == null);

    const struct_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_1", .payload = "%0!", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %2!", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "add", .payload = "%1!, %3!", .category = .other },
    };
    const struct_sum = air_export.Function{
        .name = "not_named_struct_sum",
        .type_text = "fn () i32",
        .instruction_count = struct_sum_instructions.len,
        .main_body_count = struct_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&struct_sum_instructions),
    };
    const struct_summary = structSumSummary(struct_sum).?;
    try std.testing.expectEqual(@as(u32, 0), struct_summary.field0_ptr);
    try std.testing.expectEqual(@as(u32, 2), struct_summary.field1_ptr);
    try std.testing.expectEqual(@as(usize, 2), struct_summary.load_count);
    try std.testing.expectEqual(@as(usize, 1), struct_summary.add_count);
    try std.testing.expect(selectedStructSumShape(struct_sum));

    const bad_struct_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "load", .payload = "i64, %0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_1", .payload = "%0!", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "load", .payload = "i64, %2!", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "add", .payload = "%1!, %3!", .category = .other },
    };
    const bad_struct_sum = air_export.Function{
        .name = "not_named_bad_struct_sum",
        .type_text = "fn () i64",
        .instruction_count = bad_struct_sum_instructions.len,
        .main_body_count = bad_struct_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_struct_sum_instructions),
    };
    try std.testing.expect(structSumSummary(bad_struct_sum) == null);

    const slice_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "slice", .payload = "%arg0!, %arg1!", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "ptr_slice_len_ptr", .payload = "%0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "loop", .payload = "", .category = .control_flow },
        .{ .index = 3, .indent = 1, .unused = false, .opcode = "slice_elem_ptr", .payload = "%0!, %idx!", .category = .memory },
    };
    const slice_sum = air_export.Function{
        .name = "not_named_slice_sum",
        .type_text = "fn ([*]const i32, usize) i32",
        .instruction_count = slice_sum_instructions.len,
        .main_body_count = slice_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&slice_sum_instructions),
    };
    const slice_summary = sliceSumSummary(slice_sum).?;
    try std.testing.expectEqual(@as(u32, 0), slice_summary.slice);
    try std.testing.expectEqual(@as(u32, 1), slice_summary.ptr_slice_len_ptr);
    try std.testing.expectEqual(@as(u32, 2), slice_summary.loop);
    try std.testing.expectEqual(@as(u32, 3), slice_summary.slice_elem_ptr);
    try std.testing.expect(selectedSliceSumShape(slice_sum));

    const bad_slice_sum_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "slice", .payload = "%arg0!, %arg1!", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "ptr_slice_len_ptr", .payload = "%0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "slice_elem_ptr", .payload = "%0!, %idx!", .category = .memory },
    };
    const bad_slice_sum = air_export.Function{
        .name = "not_named_bad_slice_sum",
        .type_text = "fn ([*]const i32, usize) i32",
        .instruction_count = bad_slice_sum_instructions.len,
        .main_body_count = bad_slice_sum_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_slice_sum_instructions),
    };
    try std.testing.expect(sliceSumSummary(bad_slice_sum) == null);

    const packed_read_flag_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_2", .payload = "%arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "load", .payload = "i8, %0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "bitcast", .payload = "i1, %1!", .category = .other },
    };
    const packed_read_flag = air_export.Function{
        .name = "not_named_packed_read_flag",
        .type_text = "fn () bool",
        .instruction_count = packed_read_flag_instructions.len,
        .main_body_count = packed_read_flag_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&packed_read_flag_instructions),
    };
    const packed_read_summary = packedReadFlagSummary(packed_read_flag).?;
    try std.testing.expectEqual(.read_flag, packed_read_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), packed_read_summary.field_ptr);
    try std.testing.expectEqual(@as(u32, 1), packed_read_summary.load.?);
    try std.testing.expectEqual(@as(u32, 2), packed_read_summary.bitcast.?);
    try std.testing.expect(selectedPackedReadFlagShape(packed_read_flag));

    const bad_packed_read_flag_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_2", .payload = "%arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "load", .payload = "i8, %0!", .category = .memory },
    };
    const bad_packed_read_flag = air_export.Function{
        .name = "not_named_bad_packed_read_flag",
        .type_text = "fn () bool",
        .instruction_count = bad_packed_read_flag_instructions.len,
        .main_body_count = bad_packed_read_flag_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_packed_read_flag_instructions),
    };
    try std.testing.expect(packedReadFlagSummary(bad_packed_read_flag) == null);

    const packed_replace_low_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "trunc", .payload = "i4, %arg1!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "store", .payload = "%0!, %1!", .category = .memory },
    };
    const packed_replace_low = air_export.Function{
        .name = "not_named_packed_replace_low",
        .type_text = "fn () u8",
        .instruction_count = packed_replace_low_instructions.len,
        .main_body_count = packed_replace_low_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&packed_replace_low_instructions),
    };
    const packed_replace_summary = packedReplaceLowSummary(packed_replace_low).?;
    try std.testing.expectEqual(.replace_low, packed_replace_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), packed_replace_summary.field_ptr);
    try std.testing.expectEqual(@as(u32, 1), packed_replace_summary.trunc.?);
    try std.testing.expectEqual(@as(u32, 2), packed_replace_summary.store.?);
    try std.testing.expect(selectedPackedReplaceLowShape(packed_replace_low));

    const bad_packed_replace_low_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "trunc", .payload = "i4, %arg1!", .category = .other },
    };
    const bad_packed_replace_low = air_export.Function{
        .name = "not_named_bad_packed_replace_low",
        .type_text = "fn () u8",
        .instruction_count = bad_packed_replace_low_instructions.len,
        .main_body_count = bad_packed_replace_low_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&bad_packed_replace_low_instructions),
    };
    try std.testing.expect(packedReplaceLowSummary(bad_packed_replace_low) == null);

    const pair_first_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "alloc", .payload = "*struct", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %1!", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const pair_first = air_export.Function{
        .name = "not_named_pair_first",
        .type_text = "fn () i32",
        .instruction_count = pair_first_instructions.len,
        .main_body_count = pair_first_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&pair_first_instructions),
    };
    const pair_first_summary = aggregatePairFirstSummary(pair_first).?;
    try std.testing.expectEqual(.first, pair_first_summary.kind);
    try std.testing.expectEqual(@as(u32, 1), pair_first_summary.field0_ptr);
    try std.testing.expect(selectedAggregatePairFirstShape(pair_first));
    try std.testing.expect(!selectedAggregateMakePairShape(pair_first));

    const make_pair_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "ret_ptr", .payload = "*struct", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "store", .payload = "%1!, <i32, 11>", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_1", .payload = "%0!", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "store", .payload = "%3!, <i32, 12>", .category = .memory },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "ret_load", .payload = "%0!", .category = .return_op },
    };
    const make_pair = air_export.Function{
        .name = "not_named_make_pair",
        .type_text = "fn (i32, i32) struct",
        .instruction_count = make_pair_instructions.len,
        .main_body_count = make_pair_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&make_pair_instructions),
    };
    const make_pair_summary = aggregateMakePairSummary(make_pair).?;
    try std.testing.expectEqual(.make, make_pair_summary.kind);
    try std.testing.expectEqual(@as(u32, 1), make_pair_summary.field0_ptr);
    try std.testing.expectEqual(@as(u32, 3), make_pair_summary.field1_ptr.?);
    try std.testing.expect(selectedAggregateMakePairShape(make_pair));
    try std.testing.expect(!selectedAggregatePairFirstShape(make_pair));
}

test "AIR model recognizes selected error and switch shapes structurally" {
    const payload_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "error_union, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const payload = air_export.Function{
        .name = "not_named_payload",
        .type_text = "fn () i32",
        .instruction_count = payload_instructions.len,
        .main_body_count = payload_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&payload_instructions),
    };
    const payload_summary = errorUnionPayloadSummary(payload).?;
    try std.testing.expectEqual(.payload, payload_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), payload_summary.error_union_value.?);
    try std.testing.expectEqual(@as(u32, 2), payload_summary.extracted_value.?);
    try std.testing.expect(selectedErrorUnionPayloadShape(payload));
    try std.testing.expect(!selectedErrorSwitchShape(payload));

    const switch_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%2!", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const err_switch = air_export.Function{
        .name = "not_named_error_switch",
        .type_text = "fn () i32",
        .instruction_count = switch_instructions.len,
        .main_body_count = switch_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&switch_instructions),
    };
    const err_switch_summary = errorSwitchSummary(err_switch).?;
    try std.testing.expectEqual(.switch_dispatch, err_switch_summary.kind);
    try std.testing.expectEqual(@as(u32, 2), err_switch_summary.extracted_value.?);
    try std.testing.expectEqual(@as(u32, 3), err_switch_summary.switch_br.?);
    try std.testing.expect(selectedErrorSwitchShape(err_switch));
    try std.testing.expect(!selectedErrorUnionPayloadShape(err_switch));
    try std.testing.expect(!selectedErrorClassifyShape(err_switch));

    const unrelated_switch_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%1!", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const unrelated_switch = air_export.Function{
        .name = "not_named_unrelated_error_switch",
        .type_text = "fn () i32",
        .instruction_count = unrelated_switch_instructions.len,
        .main_body_count = unrelated_switch_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_switch_instructions),
    };
    try std.testing.expect(errorSwitchSummary(unrelated_switch) == null);

    const unrelated_return_switch_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "%0!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%2!", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const unrelated_return_switch = air_export.Function{
        .name = "not_named_unrelated_return_error_switch",
        .type_text = "fn () i32",
        .instruction_count = unrelated_return_switch_instructions.len,
        .main_body_count = unrelated_return_switch_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_return_switch_instructions),
    };
    try std.testing.expect(errorSwitchSummary(unrelated_return_switch) == null);

    const classify_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "u16, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%0!", .category = .control_flow },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "ret", .payload = "%0!", .category = .return_op },
    };
    const classify = air_export.Function{
        .name = "not_named_classify",
        .type_text = "fn () i32",
        .instruction_count = classify_instructions.len,
        .main_body_count = classify_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&classify_instructions),
    };
    try std.testing.expect(selectedErrorClassifyShape(classify));
    try std.testing.expect(!selectedErrorSwitchShape(classify));

    const classify_no_return_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "u16, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%0!", .category = .control_flow },
    };
    const classify_no_return = air_export.Function{
        .name = "not_named_classify_no_return",
        .type_text = "fn () i32",
        .instruction_count = classify_no_return_instructions.len,
        .main_body_count = classify_no_return_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&classify_no_return_instructions),
    };
    try std.testing.expect(errorClassifySummary(classify_no_return) == null);

    const maybe_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "cmp_neq", .payload = "%arg0!, <i32, 0>", .category = .comparison },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%0!, then_body, else_body", .category = .control_flow },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "ret", .payload = "%0!", .category = .return_op },
    };
    const maybe = air_export.Function{
        .name = "not_named_maybe",
        .type_text = "fn () i32",
        .instruction_count = maybe_instructions.len,
        .main_body_count = maybe_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&maybe_instructions),
    };
    try std.testing.expect(selectedMaybeErrorShape(maybe));

    const maybe_no_return_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "cmp_neq", .payload = "%arg0!, <i32, 0>", .category = .comparison },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%0!, then_body, else_body", .category = .control_flow },
    };
    const maybe_no_return = air_export.Function{
        .name = "not_named_maybe_no_return",
        .type_text = "fn () i32",
        .instruction_count = maybe_no_return_instructions.len,
        .main_body_count = maybe_no_return_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&maybe_no_return_instructions),
    };
    try std.testing.expect(maybeErrorSummary(maybe_no_return) == null);
}

test "AIR model recognizes selected table lookup and runtime wrapper shapes structurally" {
    const table_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "u8, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "bit_and", .payload = "%0!, <i32, 63>", .category = .arithmetic },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "intcast", .payload = "usize, %1!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "array_elem_val", .payload = "@table, %2!", .category = .other },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%3!", .category = .return_op },
    };
    const table = air_export.Function{
        .name = "not_named_table_lookup",
        .type_text = "fn (u8) u8",
        .instruction_count = table_instructions.len,
        .main_body_count = table_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&table_instructions),
    };
    const table_summary = tableLookupSummary(table).?;
    try std.testing.expectEqual(@as(u32, 1), table_summary.mask_or_narrow);
    try std.testing.expectEqual(@as(u32, 2), table_summary.index_cast);
    try std.testing.expectEqual(@as(u32, 3), table_summary.table_access);
    try std.testing.expect(selectedBase64TableLookupShape(table));

    const unrelated_table_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "u8, 0", .category = .argument },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "bit_and", .payload = "%0!, <i32, 63>", .category = .arithmetic },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "intcast", .payload = "usize, %1!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "array_elem_val", .payload = "@table, %2!", .category = .other },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const unrelated_table = air_export.Function{
        .name = "not_named_unrelated_table_lookup",
        .type_text = "fn (u8) u8",
        .instruction_count = unrelated_table_instructions.len,
        .main_body_count = unrelated_table_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_table_instructions),
    };
    try std.testing.expect(tableLookupSummary(unrelated_table) == null);

    const optional_wrapper_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_eq", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%1!, then_body, else_body", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%0!", .category = .return_op },
    };
    const optional_wrapper = air_export.Function{
        .name = "not_named_optional_wrapper",
        .type_text = "fn () i32",
        .instruction_count = optional_wrapper_instructions.len,
        .main_body_count = optional_wrapper_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&optional_wrapper_instructions),
    };
    const optional_wrapper_summary = runtimeOptionalPointerMainSummary(optional_wrapper).?;
    try std.testing.expectEqual(.optional_pointer_main, optional_wrapper_summary.kind);
    try std.testing.expectEqual(@as(u32, 0), optional_wrapper_summary.call);
    try std.testing.expectEqual(@as(u32, 1), optional_wrapper_summary.compare);
    try std.testing.expect(selectedRuntimeOptionalPointerMainShape(optional_wrapper));
    try std.testing.expect(!selectedRuntimePointerLoadStoreMainShape(optional_wrapper));

    const unrelated_wrapper_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_eq", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%0!, then_body, else_body", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%0!", .category = .return_op },
    };
    const unrelated_wrapper = air_export.Function{
        .name = "not_named_unrelated_wrapper",
        .type_text = "fn () i32",
        .instruction_count = unrelated_wrapper_instructions.len,
        .main_body_count = unrelated_wrapper_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_wrapper_instructions),
    };
    try std.testing.expect(runtimeOptionalPointerMainSummary(unrelated_wrapper) == null);

    const unrelated_block_return_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_eq", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%1!, then_body, else_body", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const unrelated_block_return = air_export.Function{
        .name = "not_named_unrelated_block_return",
        .type_text = "fn () i32",
        .instruction_count = unrelated_block_return_instructions.len,
        .main_body_count = unrelated_block_return_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&unrelated_block_return_instructions),
    };
    try std.testing.expect(runtimeOptionalPointerMainSummary(unrelated_block_return) == null);

    const load_store_wrapper_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "call", .payload = "helper", .category = .call },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "cmp_eq", .payload = "%1!, <i32, 0>", .category = .comparison },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%2!, then_body, else_body", .category = .control_flow },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const load_store_wrapper = air_export.Function{
        .name = "not_named_pointer_wrapper",
        .type_text = "fn () i32",
        .instruction_count = load_store_wrapper_instructions.len,
        .main_body_count = load_store_wrapper_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&load_store_wrapper_instructions),
    };
    const load_store_wrapper_summary = runtimePointerLoadStoreMainSummary(load_store_wrapper).?;
    try std.testing.expectEqual(.pointer_load_store_main, load_store_wrapper_summary.kind);
    try std.testing.expectEqual(@as(u32, 1), load_store_wrapper_summary.load.?);
    try std.testing.expect(selectedRuntimePointerLoadStoreMainShape(load_store_wrapper));
    try std.testing.expect(!selectedRuntimeOptionalPointerMainShape(load_store_wrapper));

    const panic_edge_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_lt", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%1!, then_body, else_body", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "call", .payload = "debug.defaultPanic", .category = .call },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "unreach", .payload = "", .category = .control_flow },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "add_safe", .payload = "%0!, %1!", .category = .arithmetic },
        .{ .index = 6, .indent = 0, .unused = false, .opcode = "ret", .payload = "%5!", .category = .return_op },
    };
    const panic_edge = air_export.Function{
        .name = "not_named_add_may_panic",
        .type_text = "fn () i32",
        .instruction_count = panic_edge_instructions.len,
        .main_body_count = panic_edge_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&panic_edge_instructions),
    };
    const panic_summary = panicEdgeSummary(panic_edge).?;
    try std.testing.expectEqual(@as(u32, 1), panic_summary.predicate);
    try std.testing.expectEqual(@as(u32, 3), panic_summary.panic_call);
    try std.testing.expectEqual(@as(u32, 5), panic_summary.add);
    try std.testing.expect(selectedMixCAddMayPanicShape(panic_edge));

    const panic_edge_no_cold_unreach_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_lt", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%1!, then_body, else_body", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "unreach", .payload = "", .category = .control_flow },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "call", .payload = "debug.defaultPanic", .category = .call },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "add_safe", .payload = "%0!, %1!", .category = .arithmetic },
        .{ .index = 6, .indent = 0, .unused = false, .opcode = "ret", .payload = "%5!", .category = .return_op },
    };
    const panic_edge_no_cold_unreach = air_export.Function{
        .name = "not_named_add_may_panic_without_cold_unreach",
        .type_text = "fn () i32",
        .instruction_count = panic_edge_no_cold_unreach_instructions.len,
        .main_body_count = panic_edge_no_cold_unreach_instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&panic_edge_no_cold_unreach_instructions),
    };
    try std.testing.expect(panicEdgeSummary(panic_edge_no_cold_unreach) == null);
}

test "AIR model parses untyped AIR value query shapes" {
    const arg = air_export.Instruction{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "i32, 0", .category = .argument };
    const alloc = air_export.Instruction{ .index = 1, .indent = 0, .unused = false, .opcode = "alloc", .payload = "*i32", .category = .memory };
    const store_const = air_export.Instruction{ .index = 2, .indent = 0, .unused = false, .opcode = "store", .payload = "%1!, <i32, 7>", .category = .memory };
    const load = air_export.Instruction{ .index = 3, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %1!", .category = .memory };
    const add = air_export.Instruction{ .index = 4, .indent = 0, .unused = false, .opcode = "add", .payload = "%3!, <i32, 1>", .category = .arithmetic };
    const cond = air_export.Instruction{ .index = 5, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%4!, then_body, else_body", .category = .control_flow };
    const ret = air_export.Instruction{ .index = 6, .indent = 0, .unused = false, .opcode = "ret", .payload = "%4!", .category = .return_op };
    const cmp = air_export.Instruction{ .index = 7, .indent = 0, .unused = false, .opcode = "cmp_lt", .payload = "%3!, %0!", .category = .comparison };
    const cast = air_export.Instruction{ .index = 8, .indent = 0, .unused = false, .opcode = "intcast", .payload = "i32, %3!", .category = .other };
    const add_refs = air_export.Instruction{ .index = 9, .indent = 0, .unused = false, .opcode = "add", .payload = "%3!, %0!", .category = .arithmetic };
    const nav = air_export.Instruction{ .index = 10, .indent = 0, .unused = false, .opcode = "runtime_nav_ptr", .payload = "ptr, 'runtime.symbol'", .category = .other };
    const instructions = [_]air_export.Instruction{ arg, alloc, store_const, load, add, cond, ret, cmp, cast, add_refs, nav };
    const function = air_export.Function{
        .name = "test.value_queries",
        .type_text = "fn () i32",
        .instruction_count = instructions.len,
        .main_body_count = instructions.len,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = @constCast(&instructions),
    };

    try std.testing.expect(untypedArgIndexOfType(arg, "i32", "0"));
    try std.testing.expectEqualStrings("*i32", untypedAllocType(alloc).?);

    const store = untypedStore(store_const).?;
    try std.testing.expectEqual(@as(u32, 1), store.slot);
    try std.testing.expectEqual(@as(i128, 7), store.value.int);

    try std.testing.expectEqual(@as(u32, 1), untypedLoadSourceSlot(load).?);
    const binary = untypedBinaryRefAndInt(add).?;
    try std.testing.expectEqual(@as(u32, 3), binary.lhs);
    try std.testing.expectEqual(@as(i128, 1), binary.value);
    try std.testing.expectEqual(@as(u32, 4), untypedBranchConditionRef(cond).?);
    try std.testing.expectEqual(@as(u32, 4), untypedReturnRef(ret).?);
    try std.testing.expectEqual(@as(u32, 7), untypedFindCompareAgainstArg(function, 1, 0).?);
    try std.testing.expectEqual(@as(u32, 3), untypedFindAnyLoadFromSlot(function, 1).?);
    try std.testing.expectEqual(@as(u32, 3), untypedFindLastLoadFromSlot(function, 1).?);
    try std.testing.expectEqual(@as(u32, 8), untypedFindCastOf(function, "intcast", 3).?);
    try std.testing.expectEqual(@as(u32, 8), untypedFindCastFromSlot(function, "intcast", 1).?);
    try std.testing.expectEqual(@as(u32, 9), untypedFindBinaryUsing(function, "add", 3, 0).?);
    try std.testing.expectEqual(@as(u32, 4), untypedFindBinaryUsingConstant(function, "add", 3, 1).?);
    try std.testing.expectEqual(@as(u32, 4), untypedFindBinaryFromSlotUsingConstant(function, "add", 1, 1).?);
    try std.testing.expectEqual(@as(u32, 9), untypedFindSlotBinaryUpdate(function, "add", 1, 0).?);
    try std.testing.expect(untypedReturnUses(function, 4));
    try std.testing.expectEqualStrings("runtime.symbol", runtimeNavSymbol(function).?);
}
