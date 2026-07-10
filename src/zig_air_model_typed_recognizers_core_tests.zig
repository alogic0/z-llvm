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
const typed_recognizers_impl = @import("zig_air_model_typed_recognizers_impl.zig");

pub const typedUnionTagPayloadSwitchSummary = typed_recognizers_impl.typedUnionTagPayloadSwitchSummary;
pub const typedUnionTagPayloadBranchSummary = typed_recognizers_impl.typedUnionTagPayloadBranchSummary;
pub const typedOptionalPayloadBranchSummary = typed_recognizers_impl.typedOptionalPayloadBranchSummary;
pub const typedOptionalPayloadSummary = typed_recognizers_impl.typedOptionalPayloadSummary;
pub const typedOptionalPointerSummary = typed_recognizers_impl.typedOptionalPointerSummary;
pub const typedCheckedIntFromFloatSummary = typed_recognizers_impl.typedCheckedIntFromFloatSummary;
pub const typedMixCAddMayPanicSummary = typed_recognizers_impl.typedMixCAddMayPanicSummary;
pub const typedRuntimeOptionalPointerMainSummary = typed_recognizers_impl.typedRuntimeOptionalPointerMainSummary;
pub const typedRuntimePointerLoadStoreMainSummary = typed_recognizers_impl.typedRuntimePointerLoadStoreMainSummary;
pub const typedPackedReadFlagSummary = typed_recognizers_impl.typedPackedReadFlagSummary;
pub const typedPackedReplaceLowSummary = typed_recognizers_impl.typedPackedReplaceLowSummary;
pub const typedSliceSumSummary = typed_recognizers_impl.typedSliceSumSummary;
pub const typedConditionalSliceSumSummary = typed_recognizers_impl.typedConditionalSliceSumSummary;
pub const typedAccumulatorLoopSummary = typed_recognizers_impl.typedAccumulatorLoopSummary;
pub const typedConditionalSlotUpdateSummary = typed_recognizers_impl.typedConditionalSlotUpdateSummary;
pub const typedLoopTrySummary = typed_recognizers_impl.typedLoopTrySummary;
pub const typedInlineAsmBarrierSummary = typed_recognizers_impl.typedInlineAsmBarrierSummary;
pub const typedAtomicAddSummary = typed_recognizers_impl.typedAtomicAddSummary;
pub const typedDenseIntegerSwitchSummary = typed_recognizers_impl.typedDenseIntegerSwitchSummary;
pub const typedErrorSwitchSummary = typed_recognizers_impl.typedErrorSwitchSummary;
pub const typedErrorClassifierSummary = typed_recognizers_impl.typedErrorClassifierSummary;
pub const typedErrorUnionPayloadSummary = typed_recognizers_impl.typedErrorUnionPayloadSummary;
pub const typedErrorUnionFlow = typed_recognizers_impl.typedErrorUnionFlow;
pub const typedErrorUnionFlowDiagnosticName = typed_recognizers_impl.typedErrorUnionFlowDiagnosticName;
pub const typedMaybeErrorSummary = typed_recognizers_impl.typedMaybeErrorSummary;

fn testTypedInstruction(index: u32, opcode: []const u8) air_export.TypedInstruction {
    return .{
        .index = index,
        .opcode = opcode,
        .result_type = "-",
        .data_kind = "-",
        .operands = &.{},
    };
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
