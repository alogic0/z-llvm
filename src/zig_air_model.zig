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

    pub fn genericCfgBranchBody(
        self: TypedFunctionView,
        target_block: u32,
        structured_body: air_export.StructuredBody,
    ) bool {
        if (self.returnBody(structured_body)) return true;
        if (self.bodyEndsInReturn(structured_body)) return true;
        if (self.noreturnBody(structured_body)) return true;
        var saw_branch = false;
        for (structured_body.instructions) |instruction_index| {
            const typed_instruction = self.instruction(instruction_index) orelse return false;
            const typed_capability = self.capability(typed_instruction);
            if (typed_capability.status == .ignored_metadata) continue;
            if (air_capabilities.isBrOpcode(typed_instruction.opcode)) {
                if (saw_branch or typed_instruction.operands.len != 2) return false;
                const target = blockTarget(typed_instruction.operands[0]) orelse return false;
                if (target != target_block) return false;
                saw_branch = true;
                continue;
            }
            if (saw_branch) return false;
            if (air_capabilities.isBlockOpcode(typed_instruction.opcode)) {
                if (!self.genericCfgBlock(typed_instruction.index) and
                    !self.voidGuardBlockByIndex(typed_instruction.index))
                {
                    return false;
                }
                continue;
            }
            if (!air_capabilities.typedV2CanLower(typed_capability) or
                air_capabilities.isReturnOpcode(typed_instruction.opcode) or
                air_capabilities.isUnreachOpcode(typed_instruction.opcode))
            {
                return false;
            }
        }
        return saw_branch;
    }

    pub fn containsGenericCfgBlockInstruction(self: TypedFunctionView, instruction_index: u32) bool {
        for (self.function.instructions) |instruction_record| {
            if (!air_capabilities.isBlockOpcode(instruction_record.opcode)) continue;
            if (!self.genericCfgBlock(instruction_record.index)) continue;
            const block_body = self.body(.block, instruction_record.index) orelse return false;
            if (self.containsInstruction(block_body, instruction_index)) return true;
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

pub fn selectedAggregatePairFirstShape(function: air_export.Function) bool {
    return functionHasMemoryOp(function, .alloc) and
        functionHasFieldPtrIndex(function, 0) and
        functionHasMemoryOp(function, .load) and
        functionHasReturnOp(function);
}

pub fn selectedAggregateMakePairShape(function: air_export.Function) bool {
    return functionHasRetPtrOp(function) and
        functionHasFieldPtrIndex(function, 0) and
        functionHasFieldPtrIndex(function, 1) and
        functionHasStoreOp(function) and
        functionHasOpcode(function, "ret_load");
}

pub fn selectedErrorUnionPayloadShape(function: air_export.Function) bool {
    return functionHasErrorUnionOp(function, .unwrap_payload) and
        functionHasErrorUnionOp(function, .is_non_err) and
        !functionHasCallOp(function) and
        !functionHasOpcode(function, "switch_br");
}

pub fn selectedMaybeErrorShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "cmp_neq") and
        functionHasCfgOp(function, .cond_br) and
        functionHasReturnOp(function) and
        !functionHasOpcode(function, "switch_br");
}

pub fn selectedErrorSwitchShape(function: air_export.Function) bool {
    return functionHasCallOp(function) and
        functionHasErrorUnionOp(function, .is_non_err) and
        functionHasErrorUnionOp(function, .unwrap_payload) and
        functionHasOpcode(function, "switch_br");
}

pub fn selectedErrorClassifyShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "switch_br") and
        functionHasReturnOp(function) and
        !functionHasCallOp(function) and
        !functionHasErrorUnionOp(function, .is_non_err) and
        !functionHasErrorUnionOp(function, .unwrap_payload);
}

pub fn selectedBase64TableLookupShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "bit_and") and
        (functionHasOpcode(function, "intcast") or functionHasOpcode(function, "intcast_safe")) and
        functionHasOpcode(function, "array_elem_val") and
        functionHasReturnOp(function);
}

pub fn selectedRuntimeOptionalPointerMainShape(function: air_export.Function) bool {
    return functionHasCallOp(function) and
        functionHasOpcode(function, "cmp_eq") and
        functionHasCfgOp(function, .block) and
        functionHasCfgOp(function, .cond_br) and
        functionHasReturnOp(function) and
        !functionHasMemoryOp(function, .load);
}

pub fn selectedRuntimePointerLoadStoreMainShape(function: air_export.Function) bool {
    return functionHasCallOp(function) and
        functionHasMemoryOp(function, .load) and
        functionHasOpcode(function, "cmp_eq") and
        functionHasCfgOp(function, .block) and
        functionHasCfgOp(function, .cond_br) and
        functionHasReturnOp(function);
}

pub fn selectedMixCAddMayPanicShape(function: air_export.Function) bool {
    return functionHasOpcode(function, "cmp_lt") and
        functionHasCfgOp(function, .cond_br) and
        functionHasCallOp(function) and
        functionHasCfgOp(function, .unreach) and
        functionHasMemoryOp(function, .load) and
        (functionHasOpcode(function, "add") or functionHasOpcode(function, "add_safe")) and
        functionHasReturnOp(function);
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

pub fn typedLastBranchI32ConstValue(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    var result: ?i32 = null;
    for (structured_air_v2.instructions) |instruction_record| {
        if (typedBranchI32ConstValue(instruction_record)) |value| result = value;
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
        .int => |bits| bits == 8 or bits == 32 or bits == 64,
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

test "typed AIR model parses instruction details and block operands" {
    const instruction = air_export.TypedInstruction{
        .index = 4,
        .opcode = "br",
        .result_type = "void",
        .data_kind = "br",
        .operands = &.{},
        .details = &.{
            .{ .key = "callee_text", .value = "function 'helper'" },
            .{ .key = "operand1", .value = "@.void_value" },
        },
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

test "typed AIR model collects branch i32 constants" {
    const br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "0", .type_text = "0" },
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    const add_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "i32" },
        .{ .kind = "const", .value = "value", .type_text = "i32" },
    };
    const instructions = [_]air_export.TypedInstruction{
        .{
            .index = 0,
            .opcode = "br",
            .result_type = "void",
            .data_kind = "br",
            .operands = @constCast(&br_operands),
            .details = &.{.{ .key = "operand1_text", .value = "<i32, 7>" }},
        },
        .{
            .index = 1,
            .opcode = "add",
            .result_type = "i32",
            .data_kind = "bin_op",
            .operands = @constCast(&add_operands),
            .details = &.{.{ .key = "operand1_text", .value = "<i32, 11>" }},
        },
        .{
            .index = 2,
            .opcode = "ret",
            .result_type = "void",
            .data_kind = "un_op",
            .operands = &.{},
        },
    };
    const structured_air_v2 = air_export.StructuredAirV2{
        .version = "structured_air-v2",
        .instructions = @constCast(&instructions),
    };
    var values: [2]i32 = undefined;

    try std.testing.expectEqual(@as(i32, 7), typedBranchI32ConstValue(instructions[0]).?);
    try std.testing.expectEqual(@as(i32, 7), typedLastBranchI32ConstValue(structured_air_v2).?);
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

test "AIR model recognizes selected aggregate shapes structurally" {
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
    try std.testing.expect(selectedAggregatePairFirstShape(pair_first));
    try std.testing.expect(!selectedAggregateMakePairShape(pair_first));

    const make_pair_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "ret_ptr", .payload = "*struct", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_0", .payload = "%0!", .category = .memory },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "store", .payload = "%1!, %arg0!", .category = .memory },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "struct_field_ptr_index_1", .payload = "%0!", .category = .memory },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "store", .payload = "%3!, %arg1!", .category = .memory },
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
    try std.testing.expect(selectedAggregateMakePairShape(make_pair));
    try std.testing.expect(!selectedAggregatePairFirstShape(make_pair));
}

test "AIR model recognizes selected error and switch shapes structurally" {
    const payload_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "is_non_err", .payload = "%arg0!", .category = .other },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "unwrap_errunion_payload", .payload = "%arg0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "ret", .payload = "%1!", .category = .return_op },
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
    try std.testing.expect(selectedErrorSwitchShape(err_switch));
    try std.testing.expect(!selectedErrorUnionPayloadShape(err_switch));
    try std.testing.expect(!selectedErrorClassifyShape(err_switch));

    const classify_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "switch_br", .payload = "%arg0!", .category = .control_flow },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "ret", .payload = "%arg0!", .category = .return_op },
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

    const maybe_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "cmp_neq", .payload = "%arg0!, <i32, 0>", .category = .comparison },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%0!, then_body, else_body", .category = .control_flow },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "ret", .payload = "%arg0!", .category = .return_op },
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
}

test "AIR model recognizes selected table lookup and runtime wrapper shapes structurally" {
    const table_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "bit_and", .payload = "%arg0!, <i32, 63>", .category = .arithmetic },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "intcast", .payload = "%0!", .category = .other },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "array_elem_val", .payload = "@table, %1!", .category = .other },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "ret", .payload = "%2!", .category = .return_op },
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
    try std.testing.expect(selectedBase64TableLookupShape(table));

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
    try std.testing.expect(selectedRuntimeOptionalPointerMainShape(optional_wrapper));
    try std.testing.expect(!selectedRuntimePointerLoadStoreMainShape(optional_wrapper));

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
    try std.testing.expect(selectedRuntimePointerLoadStoreMainShape(load_store_wrapper));
    try std.testing.expect(!selectedRuntimeOptionalPointerMainShape(load_store_wrapper));

    const panic_edge_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %arg0!", .category = .memory },
        .{ .index = 1, .indent = 0, .unused = false, .opcode = "cmp_lt", .payload = "%0!, <i32, 0>", .category = .comparison },
        .{ .index = 2, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%1!, then_body, else_body", .category = .control_flow },
        .{ .index = 3, .indent = 0, .unused = false, .opcode = "call", .payload = "debug.defaultPanic", .category = .call },
        .{ .index = 4, .indent = 0, .unused = false, .opcode = "unreach", .payload = "", .category = .control_flow },
        .{ .index = 5, .indent = 0, .unused = false, .opcode = "add_safe", .payload = "%0!, %arg1!", .category = .arithmetic },
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
    try std.testing.expect(selectedMixCAddMayPanicShape(panic_edge));
}

test "AIR model parses untyped AIR value query shapes" {
    const arg = air_export.Instruction{ .index = 0, .indent = 0, .unused = false, .opcode = "arg", .payload = "i32, 0", .category = .argument };
    const alloc = air_export.Instruction{ .index = 1, .indent = 0, .unused = false, .opcode = "alloc", .payload = "*i32", .category = .memory };
    const store_const = air_export.Instruction{ .index = 2, .indent = 0, .unused = false, .opcode = "store", .payload = "%1!, <i32, 7>", .category = .memory };
    const load = air_export.Instruction{ .index = 3, .indent = 0, .unused = false, .opcode = "load", .payload = "i32, %1!", .category = .memory };
    const add = air_export.Instruction{ .index = 4, .indent = 0, .unused = false, .opcode = "add", .payload = "%3!, <i32, 1>", .category = .arithmetic };
    const cond = air_export.Instruction{ .index = 5, .indent = 0, .unused = false, .opcode = "cond_br", .payload = "%4!, then_body, else_body", .category = .control_flow };
    const ret = air_export.Instruction{ .index = 6, .indent = 0, .unused = false, .opcode = "ret", .payload = "%4!", .category = .return_op };

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
}
