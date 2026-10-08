const std = @import("std");
const core = @import("zig_air_model_base.zig");
const aggregate_model = @import("zig_air_model_aggregate.zig");
const error_union_untyped = @import("zig_air_model_error_union_untyped.zig");
const optional_model = @import("zig_air_model_optional.zig");
const pointer_slice_model = @import("zig_air_model_pointer_slice.zig");
const runtime_model = @import("zig_air_model_runtime.zig");
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
const TypedUnionTagPayloadBranchSummary = core.TypedUnionTagPayloadBranchSummary;
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
const TypedAtomicTryLockSummary = core.TypedAtomicTryLockSummary;
const TypedDenseIntegerSwitchSummary = core.TypedDenseIntegerSwitchSummary;
const TypedErrorSwitchSummary = core.TypedErrorSwitchSummary;
const TypedErrorUnionSummary = core.TypedErrorUnionSummary;
const TypedErrorUnionPayloadKind = core.TypedErrorUnionPayloadKind;
const TypedErrorUnionFlowDiagnostic = core.TypedErrorUnionFlowDiagnostic;
const TypedErrorUnionFlow = core.TypedErrorUnionFlow;
const TypedErrorUnionFlowResult = core.TypedErrorUnionFlowResult;
const pointerSliceAddressSummary = pointer_slice_model.pointerSliceAddressSummary;
const aggregatePairFirstSummary = aggregate_model.aggregatePairFirstSummary;
const arraySumSummary = aggregate_model.arraySumSummary;
const selectedArraySumShape = aggregate_model.selectedArraySumShape;
const structSumSummary = aggregate_model.structSumSummary;
const selectedStructSumShape = aggregate_model.selectedStructSumShape;
const packedReadFlagSummary = aggregate_model.packedReadFlagSummary;
const selectedPackedReadFlagShape = aggregate_model.selectedPackedReadFlagShape;
const packedReplaceLowSummary = aggregate_model.packedReplaceLowSummary;
const selectedPackedReplaceLowShape = aggregate_model.selectedPackedReplaceLowShape;
const sliceSumSummary = pointer_slice_model.sliceSumSummary;
const selectedSliceSumShape = pointer_slice_model.selectedSliceSumShape;
const optionalPointerSummary = optional_model.optionalPointerSummary;
const selectedOptionalPointerShape = optional_model.selectedOptionalPointerShape;
const optionalPayloadSummary = optional_model.optionalPayloadSummary;
const selectedOptionalPayloadShape = optional_model.selectedOptionalPayloadShape;
const integerSwitchSummary = core.integerSwitchSummary;
const selectedIntegerSwitchShape = core.selectedIntegerSwitchShape;
const integerSwitchPlan = core.integerSwitchPlan;
const aggregateMakePairSummary = aggregate_model.aggregateMakePairSummary;
const selectedAggregatePairFirstShape = aggregate_model.selectedAggregatePairFirstShape;
const selectedAggregateMakePairShape = aggregate_model.selectedAggregateMakePairShape;
const tableLookupSummary = aggregate_model.tableLookupSummary;
const selectedBase64TableLookupShape = aggregate_model.selectedBase64TableLookupShape;
const errorUnionPayloadSummary = error_union_untyped.errorUnionPayloadSummary;
const selectedErrorUnionPayloadShape = error_union_untyped.selectedErrorUnionPayloadShape;
const maybeErrorSummary = error_union_untyped.maybeErrorSummary;
const selectedMaybeErrorShape = error_union_untyped.selectedMaybeErrorShape;
const errorSwitchSummary = error_union_untyped.errorSwitchSummary;
const selectedErrorSwitchShape = error_union_untyped.selectedErrorSwitchShape;
const errorClassifySummary = error_union_untyped.errorClassifySummary;
const selectedErrorClassifyShape = error_union_untyped.selectedErrorClassifyShape;
const runtimeOptionalPointerMainSummary = runtime_model.runtimeOptionalPointerMainSummary;
const selectedRuntimeOptionalPointerMainShape = runtime_model.selectedRuntimeOptionalPointerMainShape;
const runtimePointerLoadStoreMainSummary = runtime_model.runtimePointerLoadStoreMainSummary;
const selectedRuntimePointerLoadStoreMainShape = runtime_model.selectedRuntimePointerLoadStoreMainShape;
const panicEdgeSummary = runtime_model.panicEdgeSummary;
const selectedMixCAddMayPanicShape = runtime_model.selectedMixCAddMayPanicShape;
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

pub fn typedUnionTagPayloadBranchSummary(
    function_type: FunctionType,
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedUnionTagPayloadBranchSummary {
    if (function_type.params.len != 2 or
        !function_type.params[0].ir_type.eql(.{ .int = 32 }) or
        !function_type.params[1].ir_type.eql(.{ .int = 32 }) or
        !function_type.return_type.ir_type.eql(.{ .int = 32 }))
    {
        return null;
    }
    if (typedOpcodeCount(structured_air_v2, "set_union_tag") != 2 or
        typedOpcodeCount(structured_air_v2, "switch_br") != 0 or
        typedOpcodeCount(structured_air_v2, "struct_field_val") != 0 or
        typedStoreOpcodeCount(structured_air_v2) != 2 or
        typedReturnOpcodeCount(structured_air_v2) != 2)
    {
        return null;
    }

    const construction_cond = typedConstructionCondBr(structured_air_v2) orelse return null;
    const branch_tags = typedUnionBranchTagIndexes(structured_air, structured_air_v2, construction_cond.index) orelse return null;

    const alloc = typedUnionSetTagAlloc(structured_air_v2) orelse return null;
    if (!std.mem.startsWith(u8, alloc.result_type, "*")) return null;

    const field_ptr0 = typedUnionFieldPtrFromBase(structured_air_v2, 0, alloc.index) orelse return null;
    const field_ptr1 = typedUnionFieldPtrFromBase(structured_air_v2, 1, alloc.index) orelse return null;
    const tag0_store = typedStoreToPointer(structured_air_v2, field_ptr0.index) orelse return null;
    const tag1_store = typedStoreToPointer(structured_air_v2, field_ptr1.index) orelse return null;
    if (tag0_store.operands.len != 2 or tag1_store.operands.len != 2) return null;

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

    const branch_source = typedUnionTagPayloadBranchSource(structured_air, structured_air_v2, alloc.index) orelse return null;
    const tag_branch = branch_source.branch;
    if (tag_branch.true_tag_index != 0 and tag_branch.true_tag_index != 1) return null;

    const arg1 = typedNthI32ArgIndex(structured_air_v2, 1) orelse return null;
    const tag0_store_add = typedConstAddFromBaseValue(structured_air_v2, tag0_store.operands[1], arg1) orelse return null;
    const tag1_store_add = typedConstAddFromBaseValue(structured_air_v2, tag1_store.operands[1], arg1) orelse return null;
    if (tag0_store_add == 0 and tag1_store_add == 0) return null;

    const tag0_return_add = typedLoadedUnionFieldReturnAdd(structured_air_v2, branch_source.union_pointer_index, 0) orelse return null;
    const tag1_return_add = typedLoadedUnionFieldReturnAdd(structured_air_v2, branch_source.union_pointer_index, 1) orelse return null;
    if (tag0_return_add == 0 or tag1_return_add == 0) return null;

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
    const bitcast_count = typedOpcodeCount(structured_air_v2, "bitcast") + typedOpcodeCount(structured_air_v2, "bit_cast");
    if (typedOpcodeCount(structured_air_v2, "arg") != 1 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        bitcast_count != 2 or
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
    const replace_bitcast_count = typedOpcodeCount(structured_air_v2, "bitcast") + typedOpcodeCount(structured_air_v2, "bit_cast");
    if (typedOpcodeCount(structured_air_v2, "arg") != 2 or
        typedOpcodeCount(structured_air_v2, "alloc") != 1 or
        replace_bitcast_count != 2 or
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
    const intcast_count = typedOpcodeCount(structured_air_v2, "intcast") +
        typedOpcodeCount(structured_air_v2, "intcast_safe") +
        typedOpcodeCount(structured_air_v2, "int_cast") +
        typedOpcodeCount(structured_air_v2, "int_cast_safe");
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

pub fn typedAtomicTryLockSummary(
    function_type: FunctionType,
    structured_air_v2: air_export.StructuredAirV2,
) ?TypedAtomicTryLockSummary {
    if (function_type.params.len != 1 or
        function_type.params[0].ir_type != .ptr or
        !function_type.return_type.ir_type.eql(.{ .int = 1 }) or
        typedOpcodeCount(structured_air_v2, "arg") != 1 or
        (typedOpcodeCount(structured_air_v2, "cmpxchg_strong") != 1 and
         typedOpcodeCount(structured_air_v2, "cmpxchg") != 1) or
        typedOpcodeCount(structured_air_v2, "is_null") != 1 or
        !typedHasReturnOpcode(structured_air_v2))
    {
        return null;
    }
    return .{};
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

fn typedUnionFieldPtrFromBase(
    structured_air_v2: air_export.StructuredAirV2,
    field_index: usize,
    base_index: u32,
) ?air_export.TypedInstruction {
    var opcode_buffer: [64]u8 = undefined;
    const opcode = std.fmt.bufPrint(&opcode_buffer, "struct_field_ptr_index_{}", .{field_index}) catch return null;
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, opcode)) continue;
        if (instruction.operands.len != 1) return null;
        if (typedInstOperandIndex(instruction.operands[0]) != base_index) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
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

fn typedUnionSetTagAlloc(structured_air_v2: air_export.StructuredAirV2) ?air_export.TypedInstruction {
    var alloc_index: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "set_union_tag")) continue;
        if (instruction.operands.len != 2) return null;
        const pointer_index = typedInstOperandIndex(instruction.operands[0]) orelse return null;
        if (alloc_index != null and alloc_index.? != pointer_index) return null;
        alloc_index = pointer_index;
    }
    const index = alloc_index orelse return null;
    const alloc = instructionByIndex(structured_air_v2, index) orelse return null;
    if (!std.mem.eql(u8, alloc.opcode, "alloc")) return null;
    return alloc;
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
    if (std.mem.eql(u8, load_pointer.opcode, "bitcast") or std.mem.eql(u8, load_pointer.opcode, "bit_cast")) {
        return load_pointer.operands.len == 1 and typedInstOperandIndex(load_pointer.operands[0]) == alloc_index;
    }
    return load_pointer_index == alloc_index;
}

fn typedUnionLoadedPointerFromAlloc(
    structured_air_v2: air_export.StructuredAirV2,
    value_index: u32,
    alloc_index: u32,
) ?u32 {
    const load = instructionByIndex(structured_air_v2, value_index) orelse return null;
    if (!std.mem.eql(u8, load.opcode, "load") or load.operands.len != 1) return null;
    const load_pointer_index = typedInstOperandIndex(load.operands[0]) orelse return null;
    const load_pointer = instructionByIndex(structured_air_v2, load_pointer_index) orelse return null;
    if (std.mem.eql(u8, load_pointer.opcode, "bitcast") or std.mem.eql(u8, load_pointer.opcode, "bit_cast")) {
        if (load_pointer.operands.len != 1 or typedInstOperandIndex(load_pointer.operands[0]) != alloc_index) return null;
        return load_pointer.index;
    }
    if (load_pointer_index == alloc_index) return alloc_index;
    return null;
}

const TypedUnionTagCompareBranch = struct {
    true_tag_index: u32,
    cond_br_index: u32,
};

const TypedUnionTagPayloadBranchSource = struct {
    union_pointer_index: u32,
    branch: TypedUnionTagCompareBranch,
};

fn typedUnionTagPayloadBranchSource(
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
    alloc_index: u32,
) ?TypedUnionTagPayloadBranchSource {
    var found: ?TypedUnionTagPayloadBranchSource = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "get_union_tag")) continue;
        if (instruction.operands.len != 1) return null;
        const union_value_index = typedInstOperandIndex(instruction.operands[0]) orelse return null;
        const union_pointer_index = typedUnionLoadedPointerFromAlloc(structured_air_v2, union_value_index, alloc_index) orelse continue;
        const branch = typedUnionTagCompareBranch(structured_air, structured_air_v2, instruction.index) orelse continue;
        if (found != null) return null;
        found = .{ .union_pointer_index = union_pointer_index, .branch = branch };
    }
    return found;
}

fn typedUnionTagCompareBranch(
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
    get_tag_index: u32,
) ?TypedUnionTagCompareBranch {
    var found: ?TypedUnionTagCompareBranch = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cmp_eq")) continue;
        if (instruction.operands.len != 2) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != get_tag_index) continue;
        const cond_br_index = typedCondBrUsingCondition(structured_air_v2, instruction.index) orelse return null;
        if (!typedCondBrHasReturnBody(structured_air, structured_air_v2, cond_br_index)) continue;
        const rhs_text = operandTextDetail(instruction, 1) orelse return null;
        const tag_index = typedUnionTagIndexForConstText(structured_air_v2, rhs_text) orelse return null;
        if (found != null) return null;
        found = .{ .true_tag_index = tag_index, .cond_br_index = cond_br_index };
    }
    return found;
}

fn typedCondBrUsingCondition(
    structured_air_v2: air_export.StructuredAirV2,
    condition_index: u32,
) ?u32 {
    var found: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        if (instruction.operands.len != 1) return null;
        if (typedInstOperandIndex(instruction.operands[0]) != condition_index) continue;
        if (found != null) return null;
        found = instruction.index;
    }
    return found;
}

fn typedCondBrHasReturnBody(
    structured_air: air_export.StructuredAir,
    structured_air_v2: air_export.StructuredAirV2,
    cond_br_index: u32,
) bool {
    const then_body = structured_air.body(.then_body, cond_br_index) orelse return false;
    if (typedBodyHasReturn(structured_air_v2, then_body)) return true;
    const else_body = structured_air.body(.else_body, cond_br_index) orelse return false;
    return typedBodyHasReturn(structured_air_v2, else_body);
}

fn typedBodyHasReturn(
    structured_air_v2: air_export.StructuredAirV2,
    body: air_export.StructuredBody,
) bool {
    for (body.instructions) |instruction_index| {
        const instruction = instructionByIndex(structured_air_v2, instruction_index) orelse continue;
        if (std.mem.eql(u8, instruction.opcode, "ret") or std.mem.eql(u8, instruction.opcode, "ret_safe")) return true;
    }
    return false;
}

fn typedUnionTagIndexForConstText(
    structured_air_v2: air_export.StructuredAirV2,
    text: []const u8,
) ?u32 {
    var found: ?u32 = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "set_union_tag")) continue;
        if (instruction.operands.len != 2) return null;
        const tag_text = operandTextDetail(instruction, 1) orelse return null;
        if (!std.mem.eql(u8, tag_text, text)) continue;
        const tag_index = typedDetailU32(instruction, "tag_index") orelse return null;
        if (found != null and found.? != tag_index) return null;
        found = tag_index;
    }
    return found;
}

fn typedLoadedUnionFieldReturnAdd(
    structured_air_v2: air_export.StructuredAirV2,
    union_pointer_index: u32,
    field_index: usize,
) ?i32 {
    const field_ptr = typedUnionFieldPtrFromBase(structured_air_v2, field_index, union_pointer_index) orelse return null;
    const load = typedLoadFromPointer(structured_air_v2, field_ptr.index) orelse return null;
    const add = typedAddConstInstructionUsing(structured_air_v2, load.index) orelse return null;
    if (!typedReturnUsesValue(structured_air_v2, add.index)) return null;
    return add.addend;
}

fn typedLoadFromPointer(
    structured_air_v2: air_export.StructuredAirV2,
    pointer_index: u32,
) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "load")) continue;
        if (instruction.operands.len != 1) continue;
        if (typedInstOperandIndex(instruction.operands[0]) != pointer_index) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
}

fn typedReturnUsesValue(structured_air_v2: air_export.StructuredAirV2, value_index: u32) bool {
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "ret") and !std.mem.eql(u8, instruction.opcode, "ret_safe")) continue;
        if (instruction.operands.len != 1) continue;
        if (typedInstOperandIndex(instruction.operands[0]) == value_index) return true;
    }
    return false;
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

fn typedConstructionCondBr(structured_air_v2: air_export.StructuredAirV2) ?air_export.TypedInstruction {
    var found: ?air_export.TypedInstruction = null;
    for (structured_air_v2.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "cond_br")) continue;
        if (!typedConditionIsFirstArgEqZero(structured_air_v2, instruction)) continue;
        if (found != null) return null;
        found = instruction;
    }
    return found;
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
