const std = @import("std");
const core = @import("zig_air_model_base.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");

const ZigType = core.ZigType;
const FunctionType = core.FunctionType;
const irCallingConvention = core.irCallingConvention;
const TypedValue = core.TypedValue;
const TypedBranchMergeResult = core.TypedBranchMergeResult;
const LowerError = core.LowerError;
const TypedFunctionView = core.TypedFunctionView;
const TypedCallee = core.TypedCallee;
const TypedCallDetails = core.TypedCallDetails;
const callDetails = core.callDetails;
const runtimeNavFqn = core.runtimeNavFqn;
const fieldIndex = core.fieldIndex;
const fieldIndexUsize = core.fieldIndexUsize;
const arrayElemTableText = core.arrayElemTableText;
const calleeName = core.calleeName;
const callee = core.callee;
const calleeWithMarker = core.calleeWithMarker;
const shortFunctionName = core.shortFunctionName;
const instructionRecordPosition = core.instructionRecordPosition;
const simpleSelectBlock = core.simpleSelectBlock;
const belongsToSimpleSelectBlock = core.belongsToSimpleSelectBlock;
const ownPrint = core.ownPrint;
const detail = core.detail;
const operandTextDetail = core.operandTextDetail;
const instructionMissingRequiredDetail = core.instructionMissingRequiredDetail;
const typedOpcodeCount = core.typedOpcodeCount;
const functionHasOpcode = core.functionHasOpcode;
const functionHasScalarOp = core.functionHasScalarOp;
const functionHasMemoryOp = core.functionHasMemoryOp;
const functionHasOptionalOp = core.functionHasOptionalOp;
const functionHasErrorUnionOp = core.functionHasErrorUnionOp;
const functionHasPointerAggregateOp = core.functionHasPointerAggregateOp;
const functionHasCallOp = core.functionHasCallOp;
const functionHasCfgOp = core.functionHasCfgOp;
const functionHasReturnOp = core.functionHasReturnOp;
const functionHasStoreOp = core.functionHasStoreOp;
const functionHasFieldPtrIndex = core.functionHasFieldPtrIndex;
const functionHasRetPtrOp = core.functionHasRetPtrOp;
const TableLookupSummary = core.TableLookupSummary;
const ErrorSwitchSummary = core.ErrorSwitchSummary;
const RuntimeWrapperSummary = core.RuntimeWrapperSummary;
const PanicEdgeSummary = core.PanicEdgeSummary;
const AggregatePairSummary = core.AggregatePairSummary;
const ArraySumSummary = core.ArraySumSummary;
const StructSumSummary = core.StructSumSummary;
const PackedFieldSummary = core.PackedFieldSummary;
const SliceSumSummary = core.SliceSumSummary;
const OptionalShapeSummary = core.OptionalShapeSummary;
const IntegerSwitchSummary = core.IntegerSwitchSummary;
const IntegerSwitchArm = core.IntegerSwitchArm;
const IntegerSwitchPlan = core.IntegerSwitchPlan;
const PointerSliceAddressSummary = core.PointerSliceAddressSummary;
const TypedUnionTagPayloadSwitchSummary = core.TypedUnionTagPayloadSwitchSummary;
const TypedOptionalPayloadBranchSummary = core.TypedOptionalPayloadBranchSummary;
const TypedOptionalPayloadSummary = core.TypedOptionalPayloadSummary;
const TypedOptionalPointerSummary = core.TypedOptionalPointerSummary;
const TypedCheckedIntFromFloatSummary = core.TypedCheckedIntFromFloatSummary;
const TypedMixCAddMayPanicSummary = core.TypedMixCAddMayPanicSummary;
const TypedRuntimeWrapperSummary = core.TypedRuntimeWrapperSummary;
const TypedPackedFieldSummary = core.TypedPackedFieldSummary;
const TypedSliceLoopSummary = core.TypedSliceLoopSummary;
const TypedScalarControlSummary = core.TypedScalarControlSummary;
const TypedLoopTrySummary = core.TypedLoopTrySummary;
const TypedLoopTryPostBranchSummary = core.TypedLoopTryPostBranchSummary;
const TypedLoopTryPostSwitchSummary = core.TypedLoopTryPostSwitchSummary;
const TypedInlineAsmSummary = core.TypedInlineAsmSummary;
const TypedAtomicRmwSummary = core.TypedAtomicRmwSummary;
const TypedDenseIntegerSwitchSummary = core.TypedDenseIntegerSwitchSummary;
const TypedErrorSwitchSummary = core.TypedErrorSwitchSummary;
const TypedErrorUnionSummary = core.TypedErrorUnionSummary;
const TypedErrorUnionPayloadKind = core.TypedErrorUnionPayloadKind;
const TypedErrorUnionFlowDiagnostic = core.TypedErrorUnionFlowDiagnostic;
const TypedErrorUnionFlow = core.TypedErrorUnionFlow;
const TypedErrorUnionFlowResult = core.TypedErrorUnionFlowResult;
const pointerSliceAddressSummary = core.pointerSliceAddressSummary;
const aggregatePairFirstSummary = core.aggregatePairFirstSummary;
const arraySumSummary = core.arraySumSummary;
const selectedArraySumShape = core.selectedArraySumShape;
const structSumSummary = core.structSumSummary;
const selectedStructSumShape = core.selectedStructSumShape;
const packedReadFlagSummary = core.packedReadFlagSummary;
const selectedPackedReadFlagShape = core.selectedPackedReadFlagShape;
const packedReplaceLowSummary = core.packedReplaceLowSummary;
const selectedPackedReplaceLowShape = core.selectedPackedReplaceLowShape;
const sliceSumSummary = core.sliceSumSummary;
const selectedSliceSumShape = core.selectedSliceSumShape;
const optionalPointerSummary = core.optionalPointerSummary;
const selectedOptionalPointerShape = core.selectedOptionalPointerShape;
const optionalPayloadSummary = core.optionalPayloadSummary;
const selectedOptionalPayloadShape = core.selectedOptionalPayloadShape;
const integerSwitchSummary = core.integerSwitchSummary;
const selectedIntegerSwitchShape = core.selectedIntegerSwitchShape;
const integerSwitchPlan = core.integerSwitchPlan;
const aggregateMakePairSummary = core.aggregateMakePairSummary;
const selectedAggregatePairFirstShape = core.selectedAggregatePairFirstShape;
const selectedAggregateMakePairShape = core.selectedAggregateMakePairShape;
const tableLookupSummary = core.tableLookupSummary;
const selectedBase64TableLookupShape = core.selectedBase64TableLookupShape;
const errorUnionPayloadSummary = core.errorUnionPayloadSummary;
const selectedErrorUnionPayloadShape = core.selectedErrorUnionPayloadShape;
const maybeErrorSummary = core.maybeErrorSummary;
const selectedMaybeErrorShape = core.selectedMaybeErrorShape;
const errorSwitchSummary = core.errorSwitchSummary;
const selectedErrorSwitchShape = core.selectedErrorSwitchShape;
const errorClassifySummary = core.errorClassifySummary;
const selectedErrorClassifyShape = core.selectedErrorClassifyShape;
const runtimeOptionalPointerMainSummary = core.runtimeOptionalPointerMainSummary;
const selectedRuntimeOptionalPointerMainShape = core.selectedRuntimeOptionalPointerMainShape;
const runtimePointerLoadStoreMainSummary = core.runtimePointerLoadStoreMainSummary;
const selectedRuntimePointerLoadStoreMainShape = core.selectedRuntimePointerLoadStoreMainShape;
const panicEdgeSummary = core.panicEdgeSummary;
const selectedMixCAddMayPanicShape = core.selectedMixCAddMayPanicShape;
const UntypedValueSource = core.UntypedValueSource;
const UntypedStore = core.UntypedStore;
const UntypedBinaryRefs = core.UntypedBinaryRefs;
const untypedArgIndexOfType = core.untypedArgIndexOfType;
const untypedAllocType = core.untypedAllocType;
const untypedLoadSourceSlot = core.untypedLoadSourceSlot;
const untypedStore = core.untypedStore;
const untypedBinaryRefs = core.untypedBinaryRefs;
const untypedBinaryRefAndInt = core.untypedBinaryRefAndInt;
const untypedReturnRef = core.untypedReturnRef;
const untypedBranchConditionRef = core.untypedBranchConditionRef;
const untypedInstructionByIndex = core.untypedInstructionByIndex;
const untypedLoadReferencesSlot = core.untypedLoadReferencesSlot;
const untypedFindCompareAgainstArg = core.untypedFindCompareAgainstArg;
const untypedFindAnyLoadFromSlot = core.untypedFindAnyLoadFromSlot;
const untypedFindLastLoadFromSlot = core.untypedFindLastLoadFromSlot;
const untypedFindCastOf = core.untypedFindCastOf;
const untypedFindCastFromSlot = core.untypedFindCastFromSlot;
const untypedFindBinaryUsing = core.untypedFindBinaryUsing;
const untypedFindBinaryUsingConstant = core.untypedFindBinaryUsingConstant;
const untypedFindBinaryFromSlotUsingConstant = core.untypedFindBinaryFromSlotUsingConstant;
const untypedFindSlotBinaryUpdate = core.untypedFindSlotBinaryUpdate;
const untypedReturnUses = core.untypedReturnUses;
const runtimeNavSymbol = core.runtimeNavSymbol;
const typedFieldPtrIndexCount = core.typedFieldPtrIndexCount;
const typedCalleeNameCount = core.typedCalleeNameCount;
const typedStoreOpcodeCount = core.typedStoreOpcodeCount;
const typedReturnOpcodeCount = core.typedReturnOpcodeCount;
const typedHasReturnOpcode = core.typedHasReturnOpcode;
const typedRetPtrIndex = core.typedRetPtrIndex;
const typedConstUsizeOperand = core.typedConstUsizeOperand;
const typedConstI32Operand = core.typedConstI32Operand;
const isTypedI32ConstOperand = core.isTypedI32ConstOperand;
const isTypedPtrU32ConstOperand = core.isTypedPtrU32ConstOperand;
const typedVoidConstOperand = core.typedVoidConstOperand;
const typedInstOperandIndex = core.typedInstOperandIndex;
const typedI32InstOperandIndex = core.typedI32InstOperandIndex;
const isTypedConstOperand = core.isTypedConstOperand;
const typedConstOperandText = core.typedConstOperandText;
const typedConstantOperandValueText = core.typedConstantOperandValueText;
const typedAngleConstantValue = core.typedAngleConstantValue;
const isTypedNoneOperand = core.isTypedNoneOperand;
const hasKnownTypedText = core.hasKnownTypedText;
const isTypedBlockOperand = core.isTypedBlockOperand;
const isTypedFieldPtrDataKind = core.isTypedFieldPtrDataKind;
const isTypedPayloadOpDataKind = core.isTypedPayloadOpDataKind;
const typedBranchI32ConstValue = core.typedBranchI32ConstValue;
const typedReturnI32ConstValue = core.typedReturnI32ConstValue;
const typedLastBranchI32ConstValue = core.typedLastBranchI32ConstValue;
const typedLastBranchOrReturnI32ConstValue = core.typedLastBranchOrReturnI32ConstValue;
const typedBranchI32ConstValues = core.typedBranchI32ConstValues;
const typedFirstI32ConstOperandForOpcodes = core.typedFirstI32ConstOperandForOpcodes;
const typedAggregatePointerPath = core.typedAggregatePointerPath;
const aggregateIndexPathText = core.aggregateIndexPathText;
const plainFieldPointerChild = core.plainFieldPointerChild;
const supportedTypedGepElementType = core.supportedTypedGepElementType;
const aggregateFieldByteOffset = core.aggregateFieldByteOffset;
const genericTypedGepIndex = core.genericTypedGepIndex;
const blockTarget = core.blockTarget;
const typedResultCoverage = core.typedResultCoverage;
const typedOperandCoverage = core.typedOperandCoverage;
const instructionByIndex = core.instructionByIndex;
const singleInstructionByOpcode = core.singleInstructionByOpcode;
pub fn typedUnionTagPayloadSwitchSummary(
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedUnionTagPayloadSwitchSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    const cond_br = singleInstructionByOpcode(structured_air_v2, "cond_br") orelse return null;
    const branch_tags = typedUnionBranchTagIndexes(structured_air, structured_air_v2, cond_br.index) orelse return null;

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
    if (!typedConditionIsFirstArgEqZero(structured_air_v2, cond_br)) return null;

    const alloc = singleInstructionByOpcode(structured_air_v2, "alloc") orelse return null;
    if (!std.mem.startsWith(u8, alloc.result_type, "*")) return null;

    const field_ptr0 = typedUnionFieldPtr(structured_air_v2, 0) orelse return null;
    const field_ptr1 = typedUnionFieldPtr(structured_air_v2, 1) orelse return null;
    if (field_ptr0.operands.len != 1 or field_ptr1.operands.len != 1) return null;
    if (typedInstOperandIndex(field_ptr0.operands[0]) != alloc.index) return null;
    if (typedInstOperandIndex(field_ptr1.operands[0]) != alloc.index) return null;

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
    if (get_tag.operands.len != 1) return null;
    const switch_br = singleInstructionByOpcode(structured_air_v2, "switch_br") orelse return null;
    if (switch_br.operands.len != 1 or typedInstOperandIndex(switch_br.operands[0]) != get_tag.index) return null;
    if ((typedDetailU32(switch_br, "cases_len") orelse return null) != 2) return null;
    const switch_tag0 = typedDetailU32(switch_br, "case0_item0_tag_index") orelse return null;
    const switch_tag1 = typedDetailU32(switch_br, "case1_item0_tag_index") orelse return null;
    if (!((switch_tag0 == 0 and switch_tag1 == 1) or (switch_tag0 == 1 and switch_tag1 == 0))) return null;

    const field0 = typedUnionFieldVal(structured_air_v2, 0) orelse return null;
    const field1 = typedUnionFieldVal(structured_air_v2, 1) orelse return null;
    if (field0.operands.len != 1 or field1.operands.len != 1) return null;
    const union_value_index0 = typedInstOperandIndex(field0.operands[0]) orelse return null;
    const union_value_index1 = typedInstOperandIndex(field1.operands[0]) orelse return null;
    if (union_value_index0 != union_value_index1) return null;
    if (typedInstOperandIndex(get_tag.operands[0]) != union_value_index0) return null;
    if (!typedUnionValueLoadedFromAlloc(structured_air_v2, union_value_index0, alloc.index)) return null;

    const tag0_store = typedStoreToPointer(structured_air_v2, field_ptr0.index) orelse return null;
    const tag1_store = typedStoreToPointer(structured_air_v2, field_ptr1.index) orelse return null;
    if (tag0_store.operands.len != 2 or tag1_store.operands.len != 2) return null;
    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;

    const tag0_return_add = typedAddConstUsing(structured_air_v2, field0.index) orelse return null;
    const tag1_return_add = typedAddConstUsing(structured_air_v2, field1.index) orelse return null;
    const tag0_store_add = typedConstAddFromBaseValue(structured_air_v2, tag0_store.operands[1], arg1) orelse return null;
    const tag1_store_add = typedConstAddFromBaseValue(structured_air_v2, tag1_store.operands[1], arg1) orelse return null;
    if (tag0_return_add == 0 or tag1_return_add == 0) return null;
    if (tag0_store_add == 0 and tag1_store_add == 0) return null;
    return .{
        .true_tag_index = branch_tags.true_tag_index,
        .false_tag_index = branch_tags.false_tag_index,
        .tag0_store_add = tag0_store_add,
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
    const has_post_branch = switch (function_type.params.len) {
        2 => false,
        3 => true,
        else => return null,
    };
    const has_post_switch = !has_post_branch and
        typedOpcodeCount(structured_air_v2, "switch_br") == 1 and
        typedOpcodeCount(structured_air_v2, "bit_and") == 1;
    const expected_cond_br_count: usize = if (has_post_branch) 4 else 3;
    const expected_return_count: usize = if (has_post_branch) 3 else 2;
    if (!function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        (has_post_branch and !function_type.params[2].ir_type.eql(.{ .int = 32 })) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != function_type.params.len or
        typedOpcodeCount(structured_air_v2, "alloc") != 2 or
        typedOpcodeCount(structured_air_v2, "loop") != 1 or
        typedOpcodeCount(structured_air_v2, "repeat") != 1 or
        typedOpcodeCount(structured_air_v2, "call") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_lt") != 1 or
        typedOpcodeCount(structured_air_v2, "cmp_eq") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != expected_cond_br_count or
        typedReturnOpcodeCount(structured_air_v2) != expected_return_count)
    {
        return null;
    }
    if (has_post_branch) {
        const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
        const sub_count = typedOpcodeCount(structured_air_v2, "sub") + typedOpcodeCount(structured_air_v2, "sub_safe");
        if (typedOpcodeCount(structured_air_v2, "cmp_gt") != 1 or add_count != 3 or sub_count != 1) return null;
    } else if (typedOpcodeCount(structured_air_v2, "cmp_gt") != 0 or typedOpcodeCount(structured_air_v2, "sub") != 0 or typedOpcodeCount(structured_air_v2, "sub_safe") != 0) {
        return null;
    }
    const post_switch = if (has_post_switch)
        typedLoopTryPostSwitchSummary(structured_air_v2) orelse return null
    else
        null;
    if (has_post_switch) {
        const add_count = typedOpcodeCount(structured_air_v2, "add") + typedOpcodeCount(structured_air_v2, "add_safe");
        if (add_count != 5) return null;
    } else if (!has_post_branch and (typedOpcodeCount(structured_air_v2, "switch_br") != 0 or typedOpcodeCount(structured_air_v2, "bit_and") != 0)) {
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
        .post_branch = if (has_post_branch)
            typedLoopTryPostBranchSummary(structured_air_v2) orelse return null
        else
            null,
        .post_switch = post_switch,
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
    const flow = switch (typedErrorUnionFlow(function_type, structured_air_v2)) {
        .flow => |flow| flow,
        .diagnostic => return null,
    };
    if (flow.payload_kind != .call_produced) return null;
    return .{ .kind = .payload };
}

pub fn typedErrorUnionFlow(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) TypedErrorUnionFlowResult {
    if (function_type.params.len != 1 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "is_non_err") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_payload") != 1 or
        typedOpcodeCount(structured_air_v2, "unwrap_errunion_err") != 1 or
        typedOpcodeCount(structured_air_v2, "cond_br") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return .{ .diagnostic = .unsupported_shape };
    }

    const is_non_err = singleInstructionByOpcode(structured_air_v2, "is_non_err") orelse
        return .{ .diagnostic = .missing_payload_owner };
    if (is_non_err.operands.len != 1) return .{ .diagnostic = .missing_operand };
    const source_index = typedInstOperandIndex(is_non_err.operands[0]) orelse
        return .{ .diagnostic = .missing_operand };

    const payload = singleInstructionByOpcode(structured_air_v2, "unwrap_errunion_payload") orelse
        return .{ .diagnostic = .missing_payload_owner };
    if (payload.operands.len != 1 or typedInstOperandIndex(payload.operands[0]) != source_index) {
        return .{ .diagnostic = .missing_payload_owner };
    }

    const err = singleInstructionByOpcode(structured_air_v2, "unwrap_errunion_err") orelse
        return .{ .diagnostic = .missing_error_owner };
    if (err.operands.len != 1 or typedInstOperandIndex(err.operands[0]) != source_index) {
        return .{ .diagnostic = .missing_error_owner };
    }

    if (!typedCondBrUsesInstruction(structured_air_v2, is_non_err.index)) {
        return .{ .diagnostic = .missing_branch_target };
    }

    const source = instructionByIndex(structured_air_v2, source_index) orelse
        return .{ .diagnostic = .missing_payload_owner };
    const payload_kind: TypedErrorUnionPayloadKind = if (std.mem.eql(u8, source.opcode, "call")) kind: {
        const call = callDetails(source) orelse return .{ .diagnostic = .missing_call_result_type };
        if (std.mem.indexOfScalar(u8, call.signature_text, '!') == null) {
            return .{ .diagnostic = .missing_call_result_type };
        }
        break :kind .call_produced;
    } else if (std.mem.eql(u8, source.opcode, "block")) .local else .unsupported;
    if (payload_kind == .unsupported) return .{ .diagnostic = .unsupported_payload_owner };

    return .{ .flow = .{
        .source_instruction = source_index,
        .success_payload_owner = payload.index,
        .error_owner = err.index,
        .call_result_owner = if (payload_kind == .call_produced) source_index else null,
        .post_success_branch_target = typedBranchTargetForValue(structured_air_v2, payload.index),
        .post_catch_branch_target = typedCatchBranchTarget(structured_air_v2, err.index),
        .catch_value_i32 = typedCatchBranchI32Value(structured_air_v2, err.index),
        .payload_kind = payload_kind,
    } };
}

pub fn typedErrorUnionFlowDiagnosticName(diagnostic: TypedErrorUnionFlowDiagnostic) []const u8 {
    return @tagName(diagnostic);
}

fn typedCondBrUsesInstruction(structured_air_v2: air_export.StructuredAirV2, instruction_index: u32) bool {
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isCondBrOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 1) return false;
        if (typedInstOperandIndex(instruction.operands[0]) == instruction_index) return true;
    }
    return false;
}

fn typedBranchTargetForValue(structured_air_v2: air_export.StructuredAirV2, value_index: u32) ?u32 {
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isBrOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[1]) != value_index) continue;
        return typedBranchTargetIndex(instruction);
    }
    return null;
}

fn typedCatchBranchTarget(structured_air_v2: air_export.StructuredAirV2, error_owner: u32) ?u32 {
    if (typedBranchTargetForValue(structured_air_v2, error_owner)) |target| return target;
    var found_target: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isBrOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (!isTypedI32ConstOperand(instruction.operands[1])) continue;
        const target = typedBranchTargetIndex(instruction) orelse continue;
        if (found_target != null) return null;
        found_target = target;
    }
    return found_target;
}

fn typedCatchBranchI32Value(structured_air_v2: air_export.StructuredAirV2, error_owner: u32) ?i32 {
    if (typedBranchTargetForValue(structured_air_v2, error_owner) != null) return null;
    var found_value: ?i32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isBrOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if (!isTypedI32ConstOperand(instruction.operands[1])) continue;
        if (found_value != null) return null;
        found_value = typedConstI32Operand(instruction, 1) orelse return null;
    }
    return found_value;
}

fn typedBlockOperandTargetText(operand: air_export.TypedOperand) ?[]const u8 {
    if (!isTypedBlockOperand(operand)) return null;
    return if (std.mem.eql(u8, operand.value, "block"))
        operand.type_text
    else
        operand.value;
}

fn typedBranchTargetIndex(instruction: air_export.TypedInstruction) ?u32 {
    if (!air_capabilities.isBrOpcode(instruction.opcode)) return null;
    if (instruction.operands.len == 0) return null;
    const target_text = typedBlockOperandTargetText(instruction.operands[0]) orelse return null;
    return std.fmt.parseInt(u32, target_text, 10) catch null;
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

fn typedUnionFieldPtr(structured_air_v2: air_export.StructuredAirV2, field_index: usize) ?air_export.TypedInstruction {
    var opcode_buffer: [64]u8 = undefined;
    const opcode = std.fmt.bufPrint(&opcode_buffer, "struct_field_ptr_index_{}", .{field_index}) catch return null;
    return singleInstructionByOpcode(structured_air_v2, opcode);
}

fn typedStoreToPointer(structured_air_v2: air_export.StructuredAirV2, pointer_index: u32) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (air_capabilities.memorySemanticOpForOpcode(instruction.opcode) != .store) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != pointer_index) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
}

fn typedUnionValueLoadedFromAlloc(
    structured_air_v2: air_export.StructuredAirV2,
    value_index: u32,
    alloc_index: u32,
) bool {
    const load = instructionByIndex(structured_air_v2, value_index) orelse return false;
    if (!std.mem.eql(u8, load.opcode, "load") or load.operands.len != 1) return false;
    const load_pointer_index = typedInstOperandIndex(load.operands[0]) orelse return false;
    const load_pointer = instructionByIndex(structured_air_v2, load_pointer_index) orelse return false;
    if (std.mem.eql(u8, load_pointer.opcode, "bitcast")) {
        return load_pointer.operands.len == 1 and typedInstOperandIndex(load_pointer.operands[0]) == alloc_index;
    }
    return load_pointer_index == alloc_index;
}

const TypedConstAddResult = struct {
    index: u32,
    addend: i32,
};

const TypedUnionBranchTags = struct {
    true_tag_index: u32,
    false_tag_index: u32,
};

fn typedUnionBranchTagIndexes(
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
    cond_br_index: u32,
) ?TypedUnionBranchTags {
    const then_body = structured_air.body(.then_body, cond_br_index) orelse return null;
    const else_body = structured_air.body(.else_body, cond_br_index) orelse return null;
    const true_tag_index = typedUnionSingleSetTagInBody(structured_air_v2, then_body) orelse return null;
    const false_tag_index = typedUnionSingleSetTagInBody(structured_air_v2, else_body) orelse return null;
    if (true_tag_index == false_tag_index) return null;
    if (!((true_tag_index == 0 and false_tag_index == 1) or (true_tag_index == 1 and false_tag_index == 0))) return null;
    return .{ .true_tag_index = true_tag_index, .false_tag_index = false_tag_index };
}

fn typedUnionSingleSetTagInBody(
    structured_air_v2: air_export.StructuredAirV2,
    body: air_export.StructuredBody,
) ?u32 {
    var found: ?u32 = null;
    for (body.instructions) |instruction_index| {
        const instruction = instructionByIndex(structured_air_v2, instruction_index) orelse continue;
        if (!std.mem.eql(u8, instruction.opcode, "set_union_tag")) continue;
        const tag_index = typedDetailU32(instruction, "tag_index") orelse return null;
        if (found != null) return null;
        found = tag_index;
    }
    return found;
}

fn typedConditionIsFirstArgEqZero(
    structured_air_v2: air_export.StructuredAirV2,
    cond_br: air_export.TypedInstruction,
) bool {
    if (cond_br.operands.len != 1) return false;
    const condition_index = typedInstOperandIndex(cond_br.operands[0]) orelse return false;
    const condition = instructionByIndex(structured_air_v2, condition_index) orelse return false;
    if (!std.mem.eql(u8, condition.opcode, "cmp_eq")) return false;
    if (condition.operands.len != 2) return false;
    const arg0 = typedNthI32ArgIndex(structured_air_v2, 0) orelse return false;
    return typedInstOperandIndex(condition.operands[0]) == arg0 and
        (typedConstI32Operand(condition, 1) orelse return false) == 0;
}

fn typedAddConstInstructionUsing(structured_air_v2: air_export.StructuredAirV2, operand_index: u32) ?TypedConstAddResult {
    var found: ?TypedConstAddResult = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.startsWith(u8, instruction.opcode, "add")) continue;
        if (instruction.operands.len != 2) continue;
        const lhs_index = typedInstOperandIndex(instruction.operands[0]) orelse continue;
        if (lhs_index != operand_index) continue;
        const addend = typedConstI32Operand(instruction, 1) orelse continue;
        if (found != null) return null;
        found = .{ .index = instruction.index, .addend = addend };
    }
    return found;
}

fn typedConstAddFromBaseValue(
    structured_air_v2: air_export.StructuredAirV2,
    value_operand: air_export.TypedOperand,
    base_index: u32,
) ?i32 {
    const value_index = typedInstOperandIndex(value_operand) orelse return null;
    if (value_index == base_index) return 0;
    const value_instruction = instructionByIndex(structured_air_v2, value_index) orelse return null;
    if (!std.mem.startsWith(u8, value_instruction.opcode, "add")) return null;
    if (value_instruction.operands.len != 2) return null;
    if (typedInstOperandIndex(value_instruction.operands[0]) != base_index) return null;
    return typedConstI32Operand(value_instruction, 1);
}

fn typedAddConstUsing(structured_air_v2: air_export.StructuredAirV2, operand_index: u32) ?i32 {
    return (typedAddConstInstructionUsing(structured_air_v2, operand_index) orelse return null).addend;
}

fn typedAddConstUsingSecondI32Arg(structured_air_v2: air_export.StructuredAirV2) ?i32 {
    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;
    return typedAddConstUsing(structured_air_v2, arg1);
}

fn typedLoopTryPostBranchSummary(structured_air_v2: air_export.StructuredAirV2) ?TypedLoopTryPostBranchSummary {
    const cmp = singleInstructionByOpcode(structured_air_v2, "cmp_gt") orelse return null;
    if (cmp.operands.len != 2) return null;
    const total_load_index = typedInstOperandIndex(cmp.operands[0]) orelse return null;
    const total_load = instructionByIndex(structured_air_v2, total_load_index) orelse return null;
    if (!std.mem.eql(u8, total_load.opcode, "load") or total_load.operands.len != 1) return null;
    const total_ptr_index = typedInstOperandIndex(total_load.operands[0]) orelse return null;
    const threshold_index = typedI32InstOperandIndex(cmp.operands[1]) orelse return null;
    const threshold_param_index = typedI32ArgOrdinalByIndex(structured_air_v2, threshold_index) orelse return null;

    const true_addend = typedReturnedAccumulatorConstAddend(structured_air_v2, &.{ "add", "add_safe" }, total_ptr_index, 1) orelse return null;
    const false_addend = typedReturnedAccumulatorConstAddend(structured_air_v2, &.{ "sub", "sub_safe" }, total_ptr_index, -1) orelse return null;
    return .{
        .threshold_param_index = threshold_param_index,
        .true_addend = true_addend,
        .false_addend = false_addend,
    };
}

fn typedReturnedAccumulatorConstAddend(
    structured_air_v2: air_export.StructuredAirV2,
    opcode_prefixes: []const []const u8,
    total_ptr_index: u32,
    sign: i32,
) ?i32 {
    var found: ?i32 = null;
    for (structured_air_v2.instructions) |ret| {
        if (!air_capabilities.isReturnOpcode(ret.opcode)) continue;
        if (ret.operands.len != 1) continue;
        const binary_index = typedInstOperandIndex(ret.operands[0]) orelse continue;
        const binary = instructionByIndex(structured_air_v2, binary_index) orelse continue;
        var opcode_matches = false;
        for (opcode_prefixes) |prefix| {
            if (std.mem.startsWith(u8, binary.opcode, prefix)) {
                opcode_matches = true;
                break;
            }
        }
        if (!opcode_matches or binary.operands.len != 2) continue;
        const load_index = typedInstOperandIndex(binary.operands[0]) orelse return null;
        const load = instructionByIndex(structured_air_v2, load_index) orelse return null;
        if (!std.mem.eql(u8, load.opcode, "load") or load.operands.len != 1) return null;
        if (typedInstOperandIndex(load.operands[0]) != total_ptr_index) return null;
        const constant = typedConstI32Operand(binary, 1) orelse return null;
        if (found != null) return null;
        found = constant * sign;
    }
    return found;
}

fn typedLoopTryPostSwitchSummary(structured_air_v2: air_export.StructuredAirV2) ?TypedLoopTryPostSwitchSummary {
    const bit_and = singleInstructionByOpcode(structured_air_v2, "bit_and") orelse return null;
    if (bit_and.operands.len != 2) return null;
    const mask = typedConstI32Operand(bit_and, 1) orelse return null;
    const total_load_index = typedInstOperandIndex(bit_and.operands[0]) orelse return null;
    const total_load = instructionByIndex(structured_air_v2, total_load_index) orelse return null;
    if (!std.mem.eql(u8, total_load.opcode, "load") or total_load.operands.len != 1) return null;
    const total_ptr_index = typedInstOperandIndex(total_load.operands[0]) orelse return null;

    const result_block_index = typedLoopTryPostSwitchResultBlockIndex(structured_air_v2) orelse return null;
    const switch_br = singleInstructionByOpcode(structured_air_v2, "switch_br") orelse return null;
    if (switch_br.operands.len != 1 or typedInstOperandIndex(switch_br.operands[0]) != bit_and.index) return null;
    if ((typedDetailU32(switch_br, "cases_len") orelse return null) != 2) return null;

    var addends: [3]i32 = undefined;
    var addend_count: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isBrOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 2) continue;
        if ((blockTarget(instruction.operands[0]) orelse continue) != result_block_index) continue;
        const add_index = typedInstOperandIndex(instruction.operands[1]) orelse return null;
        if (addend_count >= addends.len) return null;
        addends[addend_count] = typedLoopTryPostSwitchAddend(structured_air_v2, add_index, total_ptr_index) orelse return null;
        addend_count += 1;
    }
    if (addend_count != addends.len) return null;
    return .{
        .mask = mask,
        .case0_addend = addends[0],
        .case1_addend = addends[1],
        .default_addend = addends[2],
    };
}

fn typedLoopTryPostSwitchResultBlockIndex(structured_air_v2: air_export.StructuredAirV2) ?u32 {
    var result: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!air_capabilities.isReturnOpcode(instruction.opcode)) continue;
        if (instruction.operands.len != 1) continue;
        const block_index = typedInstOperandIndex(instruction.operands[0]) orelse continue;
        const block = instructionByIndex(structured_air_v2, block_index) orelse continue;
        if (!std.mem.eql(u8, block.opcode, "block")) continue;
        if (result != null) return null;
        result = block_index;
    }
    return result;
}

fn typedLoopTryPostSwitchAddend(structured_air_v2: air_export.StructuredAirV2, add_index: u32, total_ptr_index: u32) ?i32 {
    const add = instructionByIndex(structured_air_v2, add_index) orelse return null;
    if (!std.mem.startsWith(u8, add.opcode, "add") or add.operands.len != 2) return null;
    const load_index = typedInstOperandIndex(add.operands[0]) orelse return null;
    const load = instructionByIndex(structured_air_v2, load_index) orelse return null;
    if (!std.mem.eql(u8, load.opcode, "load") or load.operands.len != 1) return null;
    if (typedInstOperandIndex(load.operands[0]) != total_ptr_index) return null;
    return typedConstI32Operand(add, 1);
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

fn typedI32ArgOrdinalByIndex(structured_air_v2: air_export.StructuredAirV2, target_index: u32) ?usize {
    var seen: usize = 0;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "arg")) continue;
        if (!std.mem.eql(u8, instruction.result_type, "i32")) continue;
        if (instruction.index == target_index) return seen;
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
    var field_ptr0_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*TaggedValue" },
    };
    var field_ptr1_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*TaggedValue" },
    };
    var store0_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "16", .type_text = "*i32" },
        .{ .kind = "inst", .value = "1", .type_text = "i32" },
    };
    var store1_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "17", .type_text = "*i32" },
        .{ .kind = "inst", .value = "3", .type_text = "i32" },
    };
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*TaggedValue" },
    };
    var load_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "18", .type_text = "*const TaggedValue" },
    };
    var cmp_eq_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "i32" },
        .{ .kind = "const", .value = "zero", .type_text = "i32" },
    };
    var cmp_eq_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, 0>" },
    };
    var cond_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "20", .type_text = "bool" },
    };
    var instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "alloc", .result_type = "*TaggedValue", .data_kind = "ty", .operands = &.{} },
        .{ .index = 3, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_store_operands), .details = @constCast(&add_store_details) },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store0_operands) },
        .{ .index = 5, .opcode = "store", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&store1_operands) },
        .{ .index = 6, .opcode = "set_union_tag", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&set_tag0_operands), .details = @constCast(&set_tag0_details) },
        .{ .index = 7, .opcode = "get_union_tag", .result_type = "TaggedValue.Tag", .data_kind = "ty_op", .operands = @constCast(&get_tag_operands) },
        .{ .index = 8, .opcode = "switch_br", .result_type = "noreturn", .data_kind = "switch_br", .operands = @constCast(&switch_operands), .details = @constCast(&switch_details) },
        .{ .index = 9, .opcode = "struct_field_val", .result_type = "i32", .data_kind = "ty_pl", .operands = @constCast(&field0_operands), .details = @constCast(&field0_details) },
        .{ .index = 10, .opcode = "struct_field_val", .result_type = "i32", .data_kind = "ty_pl", .operands = @constCast(&field1_operands), .details = @constCast(&field1_details) },
        .{ .index = 11, .opcode = "set_union_tag", .result_type = "void", .data_kind = "bin_op", .operands = @constCast(&set_tag1_operands), .details = @constCast(&set_tag1_details) },
        .{ .index = 12, .opcode = "load", .result_type = "TaggedValue", .data_kind = "ty_op", .operands = @constCast(&load_operands) },
        .{ .index = 13, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_tag0_operands), .details = @constCast(&add_tag0_details) },
        .{ .index = 14, .opcode = "add", .result_type = "i32", .data_kind = "bin_op", .operands = @constCast(&add_tag1_operands), .details = @constCast(&add_tag1_details) },
        .{ .index = 15, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = @constCast(&ret_operands) },
        .{ .index = 16, .opcode = "struct_field_ptr_index_0", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field_ptr0_operands) },
        .{ .index = 17, .opcode = "struct_field_ptr_index_1", .result_type = "*i32", .data_kind = "field_ptr", .operands = @constCast(&field_ptr1_operands) },
        .{ .index = 18, .opcode = "bitcast", .result_type = "*const TaggedValue", .data_kind = "ty_op", .operands = @constCast(&bitcast_operands) },
        .{ .index = 19, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "cond_br", .operands = @constCast(&cond_br_operands) },
        .{ .index = 20, .opcode = "cmp_eq", .result_type = "bool", .data_kind = "bin_op", .operands = @constCast(&cmp_eq_operands), .details = @constCast(&cmp_eq_details) },
    };
    const structured_air_v2 = air_export.StructuredAirV2{ .instructions = @constCast(&instructions) };
    var main_body_instructions = [_]u32{ 0, 1, 2, 20, 19, 3, 4, 5, 6, 11, 12, 7, 8, 9, 10, 13, 14, 15, 16, 17, 18 };
    var then_body_instructions = [_]u32{ 6, 16, 4 };
    var else_body_instructions = [_]u32{ 11, 17, 5 };
    var structured_bodies = [_]air_export.StructuredBody{
        .{ .kind = .main, .owner = null, .instructions = @constCast(&main_body_instructions) },
        .{ .kind = .then_body, .owner = 19, .instructions = @constCast(&then_body_instructions) },
        .{ .kind = .else_body, .owner = 19, .instructions = @constCast(&else_body_instructions) },
    };
    const structured_air = air_export.StructuredAir{
        .instructions = &.{},
        .bodies = @constCast(&structured_bodies),
        .branches = &.{},
        .cond_branches = &.{},
        .repeats = &.{},
    };

    const summary = typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2).?;
    try std.testing.expectEqual(@as(u32, 0), summary.true_tag_index);
    try std.testing.expectEqual(@as(u32, 1), summary.false_tag_index);
    try std.testing.expectEqual(@as(i32, 0), summary.tag0_store_add);
    try std.testing.expectEqual(@as(i32, 7), summary.tag0_return_add);
    try std.testing.expectEqual(@as(i32, 5), summary.tag1_store_add);
    try std.testing.expectEqual(@as(i32, 11), summary.tag1_return_add);

    store0_operands[1].value = "3";
    store1_operands[1].value = "1";
    const swapped_payload_summary = typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2).?;
    try std.testing.expectEqual(@as(i32, 5), swapped_payload_summary.tag0_store_add);
    try std.testing.expectEqual(@as(i32, 0), swapped_payload_summary.tag1_store_add);
    store0_operands[1].value = "1";
    store1_operands[1].value = "3";

    then_body_instructions[0] = 11;
    else_body_instructions[0] = 6;
    const swapped_branch_summary = typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2).?;
    try std.testing.expectEqual(@as(u32, 1), swapped_branch_summary.true_tag_index);
    try std.testing.expectEqual(@as(u32, 0), swapped_branch_summary.false_tag_index);
    then_body_instructions[0] = 6;
    else_body_instructions[0] = 11;

    switch_details[1].value = "1";
    switch_details[2].value = "0";
    try std.testing.expect(typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) != null);
    switch_details[1].value = "0";
    switch_details[2].value = "1";

    switch_operands[0].value = "0";
    try std.testing.expect(typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) == null);
    switch_operands[0].value = "7";

    load_operands[0].value = "0";
    try std.testing.expect(typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) == null);
    load_operands[0].value = "18";

    store1_operands[1].value = "0";
    try std.testing.expect(typedUnionTagPayloadSwitchSummary(function_type, structured_air, structured_air_v2) == null);
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
    var is_non_err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var payload_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var err_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "error{Bad}!i32" },
    };
    var success_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "inst", .value = "3", .type_text = "i32" },
    };
    var catch_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "block", .value = "5", .type_text = "block" },
        .{ .kind = "const", .value = "-", .type_text = "i32" },
    };
    var catch_br_details = [_]air_export.TypedDetail{
        .{ .key = "operand1_text", .value = "<i32, -1>" },
    };
    var cond_br_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "bool" },
    };
    var call_details = [_]air_export.TypedDetail{
        .{ .key = "call_signature", .value = "fn (i32) error{Bad}!i32" },
        .{ .key = "callee_text", .value = "(function 'maybeError')" },
    };
    var payload_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "i32", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "call", .result_type = "error{Bad}!i32", .data_kind = "pl_op", .operands = &.{}, .details = &call_details },
        .{ .index = 2, .opcode = "is_non_err", .result_type = "i1", .data_kind = "un_op", .operands = &is_non_err_operands },
        .{ .index = 3, .opcode = "unwrap_errunion_payload", .result_type = "i32", .data_kind = "ty_op", .operands = &payload_operands },
        .{ .index = 4, .opcode = "unwrap_errunion_err", .result_type = "i16", .data_kind = "ty_op", .operands = &err_operands },
        .{ .index = 5, .opcode = "block", .result_type = "void", .data_kind = "ty_pl", .operands = &.{} },
        .{ .index = 6, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &success_br_operands },
        .{ .index = 7, .opcode = "br", .result_type = "noreturn", .data_kind = "br", .operands = &catch_br_operands, .details = &catch_br_details },
        .{ .index = 8, .opcode = "cond_br", .result_type = "noreturn", .data_kind = "pl_op", .operands = &cond_br_operands },
        .{ .index = 9, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = &.{} },
    };
    const payload_air = air_export.StructuredAirV2{ .instructions = &payload_instructions };
    try std.testing.expectEqual(.payload, typedErrorUnionPayloadSummary(payload_type, payload_air).?.kind);
    const payload_flow = switch (typedErrorUnionFlow(payload_type, payload_air)) {
        .flow => |flow| flow,
        .diagnostic => return error.TestExpectedEqual,
    };
    try std.testing.expectEqual(TypedErrorUnionPayloadKind.call_produced, payload_flow.payload_kind);
    try std.testing.expectEqual(@as(u32, 1), payload_flow.call_result_owner.?);
    try std.testing.expectEqual(@as(u32, 5), payload_flow.post_success_branch_target.?);
    try std.testing.expectEqual(@as(u32, 5), payload_flow.post_catch_branch_target.?);
    try std.testing.expectEqual(@as(i32, -1), payload_flow.catch_value_i32.?);

    payload_instructions[2].operands = &.{};
    try std.testing.expect(typedErrorUnionPayloadSummary(payload_type, payload_air) == null);
    try std.testing.expectEqual(
        TypedErrorUnionFlowDiagnostic.missing_operand,
        switch (typedErrorUnionFlow(payload_type, payload_air)) {
            .flow => return error.TestExpectedEqual,
            .diagnostic => |diagnostic| diagnostic,
        },
    );
    payload_instructions[2].operands = &is_non_err_operands;

    var local_flow_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "5", .type_text = "error{Bad}!i32" },
    };
    payload_instructions[1].opcode = "block";
    payload_instructions[1].details = &.{};
    payload_instructions[2].operands = &local_flow_operands;
    payload_instructions[3].operands = &local_flow_operands;
    payload_instructions[4].operands = &local_flow_operands;
    try std.testing.expect(typedErrorUnionPayloadSummary(payload_type, payload_air) == null);
    const local_flow = switch (typedErrorUnionFlow(payload_type, payload_air)) {
        .flow => |flow| flow,
        .diagnostic => return error.TestExpectedEqual,
    };
    try std.testing.expectEqual(TypedErrorUnionPayloadKind.local, local_flow.payload_kind);

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
