const std = @import("std");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_text = @import("zig_air_text.zig");
const core = @import("zig_air_model_base.zig");

const ErrorSwitchSummary = core.ErrorSwitchSummary;
const functionHasCallOp = core.functionHasCallOp;
const functionHasOpcode = core.functionHasOpcode;
const functionHasErrorUnionOp = core.functionHasErrorUnionOp;
const untypedReturnRef = core.untypedReturnRef;
const untypedBranchConditionRef = core.untypedBranchConditionRef;

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

fn errorUnionSource(instruction: air_export.Instruction) ?u32 {
    if (air_capabilities.errorUnionSemanticOpForOpcode(instruction.opcode) == .none) return null;
    return untypedFirstRefOperand(instruction);
}

fn untypedFirstRefOperand(instruction: air_export.Instruction) ?u32 {
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return air_text.instructionRef(fields.next() orelse return null);
}

fn untypedSwitchInput(instruction: air_export.Instruction) ?u32 {
    if (!air_capabilities.isSwitchBrOpcode(instruction.opcode)) return null;
    return untypedFirstRefOperand(instruction);
}

fn untypedCondBrInput(instruction: air_export.Instruction) ?u32 {
    return untypedBranchConditionRef(instruction);
}

fn untypedValueFeedsReturn(function: air_export.Function, value: u32) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedReturnRef(instruction)) |returned| {
            if (returned == value) return returned;
            const returned_instruction = core.untypedInstructionByIndex(function, returned) orelse continue;
            if (untypedCastSource(returned_instruction) == value) return returned;
        }
    }
    return null;
}

fn untypedCastSource(instruction: air_export.Instruction) ?u32 {
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    return air_text.instructionRef(fields.next() orelse return null);
}
