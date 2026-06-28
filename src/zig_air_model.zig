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

pub fn pointerSliceAddressSummary(function: air_export.Function) ?PointerSliceAddressSummary {
    const view = TypedFunctionView.init(function) orelse return null;
    if (!view.operandCoverage()) return null;
    var summary: PointerSliceAddressSummary = .{};
    for (view.structured_air_v2.instructions) |instruction| {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .ptr_gep => {
                summary.ptr_add_count += 1;
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
        if (std.mem.eql(u8, instruction.opcode, "ptr_sub")) {
            summary.ptr_sub_count += 1;
            updatePointerSliceAddressOperands(&summary, instruction);
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
    if (std.mem.indexOf(u8, text, "i8") != null or std.mem.indexOf(u8, text, "u8") != null) return 8;
    if (std.mem.indexOf(u8, text, "i16") != null or std.mem.indexOf(u8, text, "u16") != null) return 16;
    if (std.mem.indexOf(u8, text, "i32") != null or std.mem.indexOf(u8, text, "u32") != null) return 32;
    if (std.mem.indexOf(u8, text, "i64") != null or std.mem.indexOf(u8, text, "u64") != null or std.mem.indexOf(u8, text, "usize") != null) return 64;
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
            .opcode = "slice_elem_ptr",
            .result_type = "ptr",
            .data_kind = "ty_pl",
            .operands = @constCast(&[_]air_export.TypedOperand{ ptr_operand, idx_operand }),
        },
        .{
            .index = 4,
            .opcode = "load",
            .result_type = "i32",
            .data_kind = "ty_op",
            .operands = @constCast(&[_]air_export.TypedOperand{load_operand}),
        },
        .{
            .index = 5,
            .opcode = "store",
            .result_type = "void",
            .data_kind = "bin_op",
            .operands = @constCast(&[_]air_export.TypedOperand{ load_operand, .{ .kind = "inst", .value = "%value", .type_text = "i32" } }),
        },
        .{
            .index = 6,
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
