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
    true_tag_index: u32,
    false_tag_index: u32,
    tag0_store_add: i32,
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
    post_branch: ?TypedLoopTryPostBranchSummary = null,
    post_switch: ?TypedLoopTryPostSwitchSummary = null,
};

pub const TypedLoopTryPostBranchSummary = struct {
    threshold_param_index: usize,
    true_addend: i32,
    false_addend: i32,
};

pub const TypedLoopTryPostSwitchSummary = struct {
    mask: i32,
    case0_addend: i32,
    case1_addend: i32,
    default_addend: i32,
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

pub const TypedErrorUnionPayloadKind = enum {
    local,
    call_produced,
    unsupported,
};

pub const TypedErrorUnionFlowDiagnostic = enum {
    missing_operand,
    missing_call_result_type,
    missing_branch_target,
    missing_payload_owner,
    missing_error_owner,
    cross_function_fact_required,
    unsupported_payload_owner,
    unsupported_shape,
};

pub const TypedErrorUnionFlow = struct {
    source_instruction: u32,
    success_payload_owner: u32,
    error_owner: u32,
    call_result_owner: ?u32,
    post_success_branch_target: ?u32,
    post_catch_branch_target: ?u32,
    catch_value_i32: ?i32,
    payload_kind: TypedErrorUnionPayloadKind,
};

pub const TypedErrorUnionFlowResult = union(enum) {
    flow: TypedErrorUnionFlow,
    diagnostic: TypedErrorUnionFlowDiagnostic,
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
