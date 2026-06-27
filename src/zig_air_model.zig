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
        if (!std.mem.eql(u8, cond_br.opcode, "cond_br") or cond_br.operands.len != 1) return false;
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
                std.mem.eql(u8, typed_instruction.opcode, "block"))
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
            if (!saw_unreach and std.mem.eql(u8, typed_instruction.opcode, "unreach")) {
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
        if (!std.mem.eql(u8, branch.opcode, "br") or branch.operands.len != 2) return false;
        const target = blockTarget(branch.operands[0]) orelse return false;
        if (target != target_block) return false;
        if (!std.mem.eql(u8, branch.operands[1].kind, "const")) return false;
        return std.mem.eql(u8, branch.operands[1].type_text, "void") and
            std.mem.eql(u8, operandTextDetail(branch, 1) orelse return false, "@.void_value");
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
        if (!std.mem.eql(u8, cond.opcode, "cond_br")) return false;
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
            if (std.mem.eql(u8, typed_instruction.opcode, "cond_br")) {
                if (cond_index != null or typed_instruction.operands.len != 1) return false;
                cond_index = instruction_index;
                continue;
            }
            if (cond_index != null) return false;
            if (!air_capabilities.typedV2CanLower(typed_capability) or std.mem.eql(u8, typed_instruction.opcode, "block")) return false;
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
            if (std.mem.eql(u8, typed_instruction.opcode, "br")) {
                if (saw_branch or typed_instruction.operands.len != 2) return false;
                const target = blockTarget(typed_instruction.operands[0]) orelse return false;
                if (target != target_block) return false;
                saw_branch = true;
                continue;
            }
            if (saw_branch) return false;
            if (std.mem.eql(u8, typed_instruction.opcode, "block")) {
                if (!self.genericCfgBlock(typed_instruction.index) and
                    !self.voidGuardBlockByIndex(typed_instruction.index))
                {
                    return false;
                }
                continue;
            }
            if (!air_capabilities.typedV2CanLower(typed_capability) or
                air_capabilities.isReturnOpcode(typed_instruction.opcode) or
                std.mem.eql(u8, typed_instruction.opcode, "unreach"))
            {
                return false;
            }
        }
        return saw_branch;
    }

    pub fn containsGenericCfgBlockInstruction(self: TypedFunctionView, instruction_index: u32) bool {
        for (self.function.instructions) |instruction_record| {
            if (!std.mem.eql(u8, instruction_record.opcode, "block")) continue;
            if (!self.genericCfgBlock(instruction_record.index)) continue;
            const block_body = self.body(.block, instruction_record.index) orelse return false;
            if (self.containsInstruction(block_body, instruction_index)) return true;
            for (block_body.instructions) |child_index| {
                const child = self.instruction(child_index) orelse return false;
                if (!std.mem.eql(u8, child.opcode, "cond_br")) continue;
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
            if (!std.mem.eql(u8, typed_instruction.opcode, "block")) continue;
            if (self.voidGuardBlockByIndex(typed_instruction.index)) {
                const nested_body = self.body(.block, typed_instruction.index) orelse return false;
                if (self.containsInstruction(nested_body, instruction_index)) return true;
                for (nested_body.instructions) |nested_candidate| {
                    const nested_instruction = self.instruction(nested_candidate) orelse return false;
                    if (!std.mem.eql(u8, nested_instruction.opcode, "cond_br")) continue;
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
                if (!std.mem.eql(u8, nested_instruction.opcode, "cond_br")) continue;
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
        if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            cond_count += 1;
            after_cond = true;
            continue;
        }
        if (!after_cond or air_capabilities.isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "br")) {
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
        if (std.mem.eql(u8, candidate.opcode, "block")) {
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
        if (std.mem.eql(u8, operand.kind, "const") and operandTextDetail(instruction, operand_index) == null) {
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

pub fn typedFieldPtrIndexCount(structured_air_v2: air_export.StructuredAirV2, expected_index: usize) usize {
    var count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.data_kind, "field_ptr")) continue;
        const field_index_text = detail(instruction, "field_index") orelse continue;
        const field_index = std.fmt.parseInt(usize, field_index_text, 10) catch continue;
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
        if (std.mem.eql(u8, instruction.opcode, "ret_ptr")) return instruction.index;
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

pub fn typedBranchI32ConstValue(instruction: air_export.TypedInstruction) ?i32 {
    if (!std.mem.eql(u8, instruction.opcode, "br")) return null;
    if (instruction.operands.len != 2) return null;
    if (!std.mem.eql(u8, instruction.operands[1].kind, "const") or
        !std.mem.eql(u8, instruction.operands[1].type_text, "i32")) return null;
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
    if (typed_instruction.index == ret_ptr_index and std.mem.eql(u8, typed_instruction.opcode, "ret_ptr")) return 0;
    if (std.mem.eql(u8, typed_instruction.data_kind, "field_ptr")) {
        if (typed_instruction.operands.len != 1 or !std.mem.eql(u8, typed_instruction.operands[0].kind, "inst")) return null;
        const base_index = std.fmt.parseInt(u32, typed_instruction.operands[0].value, 10) catch return null;
        const len = typedAggregatePointerPath(structured_air_v2, base_index, ret_ptr_index, path) orelse return null;
        if (len >= path.len) return null;
        const field_index_text = detail(typed_instruction, "field_index") orelse return null;
        path[len] = std.fmt.parseInt(usize, field_index_text, 10) catch return null;
        return len + 1;
    }
    if (std.mem.eql(u8, typed_instruction.opcode, "ptr_elem_ptr")) {
        if (typed_instruction.operands.len != 2 or !std.mem.eql(u8, typed_instruction.operands[0].kind, "inst")) return null;
        const base_index = std.fmt.parseInt(u32, typed_instruction.operands[0].value, 10) catch return null;
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
    if (!std.mem.eql(u8, operand.kind, "block")) return null;
    if (!std.mem.eql(u8, operand.value, "block")) {
        return std.fmt.parseInt(u32, operand.value, 10) catch null;
    }
    return std.fmt.parseInt(u32, operand.type_text, 10) catch null;
}

pub fn typedResultCoverage(
    function: air_export.Function,
    structured_air_v2: air_export.StructuredAirV2,
) bool {
    if (structured_air_v2.instructions.len != function.instruction_count) return false;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.result_type, "-")) return false;
    }
    return true;
}

pub fn typedOperandCoverage(structured_air_v2: air_export.StructuredAirV2) bool {
    for (structured_air_v2.instructions) |instruction| {
        for (instruction.operands) |operand| {
            if (std.mem.eql(u8, operand.type_text, "-")) return false;
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
