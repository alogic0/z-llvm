const std = @import("std");
const core = @import("zig_air_model_base.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const air_text = @import("zig_air_text.zig");

const UntypedStore = core.UntypedStore;
const TypedFunctionView = core.TypedFunctionView;
const FunctionType = core.FunctionType;
const typedOpcodeCount = core.typedOpcodeCount;
const typedHasReturnOpcode = core.typedHasReturnOpcode;
const typedStoreOpcodeCount = core.typedStoreOpcodeCount;
const typedFirstI32ConstOperandForOpcodes = core.typedFirstI32ConstOperandForOpcodes;
const untypedFindAnyLoadFromSlot = core.untypedFindAnyLoadFromSlot;
const untypedFindStoreToSlot = core.untypedFindStoreToSlot;
const untypedBinaryRefAndInt = core.untypedBinaryRefAndInt;
const untypedFindCastOf = core.untypedFindCastOf;
const untypedReturnRef = core.untypedReturnRef;
const untypedStore = core.untypedStore;
const untypedInstructionByIndex = core.untypedInstructionByIndex;
const untypedConstOperandText = core.typedConstOperandText;
const untypedFindLastLoadFromSlot = core.untypedFindLastLoadFromSlot;

pub const TableLookupSummary = core.TableLookupSummary;
pub const AggregatePairSummary = core.AggregatePairSummary;
pub const ArraySumSummary = core.ArraySumSummary;
pub const StructSumSummary = core.StructSumSummary;
pub const PackedFieldSummary = core.PackedFieldSummary;
pub const TypedPackedFieldSummary = core.TypedPackedFieldSummary;
pub const typedAggregatePointerPath = core.typedAggregatePointerPath;
pub const aggregateIndexPathText = core.aggregateIndexPathText;
pub const plainFieldPointerChild = core.plainFieldPointerChild;
pub const aggregateFieldByteOffset = core.aggregateFieldByteOffset;

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
            .field0_value = null,
            .field1_ptr = null,
            .field1_value = null,
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

pub fn selectedStructSumShape(function: air_export.Function) bool {
    return structSumSummary(function) != null;
}

pub fn packedReadFlagSummary(function: air_export.Function) ?PackedFieldSummary {
    const field2 = functionFieldPtrIndex(function, 2) orelse return null;
    const load = untypedFindAnyLoadFromSlot(function, field2) orelse return null;
    const bitcast = untypedFindCastOf(function, "bitcast", load) orelse null;
    return .{
        .kind = .read_flag,
        .field_ptr = field2,
        .load = load,
        .bitcast = bitcast,
        .trunc = null,
        .store = null,
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
        .load = null,
        .bitcast = null,
        .trunc = trunc,
        .store = store,
    };
}

pub fn selectedPackedReplaceLowShape(function: air_export.Function) bool {
    return packedReplaceLowSummary(function) != null;
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
                if (untypedArrayElemIndex(table_access) == cast.index) {
                    return .{
                        .index_source = masked.lhs,
                        .mask_or_narrow = mask.index,
                        .index_cast = cast.index,
                        .table_access = table_access.index,
                        .return_value = untypedValueFeedsReturn(function, table_access.index) orelse return null,
                    };
                }
            }
        }
    }
    return null;
}

pub fn selectedBase64TableLookupShape(function: air_export.Function) bool {
    return tableLookupSummary(function) != null;
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

fn untypedFieldPtrIndex(instruction: air_export.Instruction) ?usize {
    const prefix = "struct_field_ptr_index_";
    if (!std.mem.startsWith(u8, instruction.opcode, prefix)) return null;
    return std.fmt.parseInt(usize, instruction.opcode[prefix.len..], 10) catch null;
}

fn untypedFieldPtrBase(instruction: air_export.Instruction, field_index: usize) ?u32 {
    if (untypedFieldPtrIndex(instruction) != field_index) return null;
    return untypedFirstRefOperand(instruction);
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

fn functionFieldPtrIndex(function: air_export.Function, expected_index: usize) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedFieldPtrIndex(instruction) == expected_index) return instruction.index;
    }
    return null;
}

fn untypedFindFieldPtrFromBase(function: air_export.Function, base: u32, field_index: usize) ?u32 {
    for (function.instructions) |instruction| {
        if (untypedFieldPtrBase(instruction, field_index) == base) return instruction.index;
    }
    return null;
}

fn untypedFirstRefOperandForStore(store: air_export.TypedInstruction) ?u32 {
    _ = store;
    return null;
}

fn untypedLoadResultType(instruction: air_export.Instruction) ?[]const u8 {
    if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) != .load) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    return std.mem.trim(u8, fields.next() orelse return null, " ");
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
    if (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode) != .cast) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    return air_text.instructionRef(fields.next() orelse return null);
}

fn untypedArrayElemIndex(instruction: air_export.Instruction) ?u32 {
    if (!std.mem.eql(u8, instruction.opcode, "array_elem_val")) return null;
    var fields = air_text.splitTopLevel(instruction.payload, ',');
    _ = fields.next() orelse return null;
    return air_text.instructionRef(fields.next() orelse return null);
}
