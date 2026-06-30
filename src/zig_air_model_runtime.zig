const std = @import("std");
const core = @import("zig_air_model_base.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_text = @import("zig_air_text.zig");

const functionHasMemoryOp = core.functionHasMemoryOp;
const untypedFindAnyLoadFromSlot = core.untypedFindAnyLoadFromSlot;
const untypedReturnRef = core.untypedReturnRef;
const untypedInstructionByIndex = core.untypedInstructionByIndex;
const untypedBinaryRefs = core.untypedBinaryRefs;
const untypedBranchConditionRef = core.untypedBranchConditionRef;

pub const RuntimeWrapperSummary = core.RuntimeWrapperSummary;
pub const PanicEdgeSummary = core.PanicEdgeSummary;

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

fn untypedFirstRefOperand(instruction: air_export.Instruction) ?u32 {
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return air_text.instructionRef(fields.next() orelse return null);
}

fn findCmpEqUsingValue(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cmp_eq")) continue;
        if (untypedFirstRefOperand(instruction) == value) {
            return instruction.index;
        }
        var fields = air_text.splitTopLevel(instruction.payload, ',');
        const rhs_text = std.mem.trim(u8, fields.next() orelse continue, " ");
        if (air_text.instructionRef(rhs_text) == value) {
            return instruction.index;
        }
    }
    return null;
}

fn findCondBrUsingValue(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedCondBrInput(instruction) == value) return instruction.index;
    }
    return null;
}

fn untypedCondBrInput(instruction: air_export.Instruction) ?u32 {
    return untypedBranchConditionRef(instruction);
}

fn findBlockBefore(function: air_export.Function, instruction_index: u32) ?u32 {
    var result: ?u32 = null;
    for (function.instructions) |instruction| {
        if (instruction.index >= instruction_index) continue;
        if (air_capabilities.isBlockOpcode(instruction.opcode)) result = instruction.index;
    }
    return result;
}

fn findUnreachAfter(function: air_export.Function, instruction_index: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (instruction.index <= instruction_index) continue;
        if (air_capabilities.isUnreachOpcode(instruction.opcode)) return instruction.index;
    }
    return null;
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

fn untypedCastSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) != .cast) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    return air_text.instructionRef(fields.next() orelse return null);
}
