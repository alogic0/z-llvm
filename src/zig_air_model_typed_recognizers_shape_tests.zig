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
