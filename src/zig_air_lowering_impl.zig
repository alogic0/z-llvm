const std = @import("std");
const air_export = @import("zig_air_export.zig");
const exported_aggregate_layout_facts = @import("zig_air_exported_aggregate_layout_facts.zig");
const aggregate_layout_facts = @import("zig_air_aggregate_layout_facts.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const target_mod = @import("target.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_calls = @import("zig_air_calls.zig");
const air_model = @import("zig_air_model.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const air_roots = @import("zig_air_roots.zig");
const lowering_context = @import("zig_air_lowering_context.zig");
const mem2reg = @import("passes/mem2reg.zig");
const pass_manager = @import("pass_manager.zig");

pub const UnsupportedReason = enum {
    function_type,
    instruction_type,
    opcode,
    control_flow_shape,
    call_shape,
    value,
};

pub const Diagnostic = struct {
    function: []const u8,
    opcode: []const u8,
    reason: UnsupportedReason,
};

pub const Result = struct {
    module: ir.Module,
    accepted_functions: usize,
    structured_air_v1_functions: usize,
    structured_air_v2_functions: usize,
    typed_air_type_functions: usize,
    typed_air_operand_functions: usize,
    legacy_air_text_lowering_functions: usize,
    generic_lowering_functions: usize,
    shape_recognizer_functions: usize,
    unsupported: []Diagnostic,
    typed_v2_fallbacks: []TypedV2Fallback,

    pub fn deinit(self: *Result) void {
        const allocator = self.module.allocator;
        self.module.deinit();
        allocator.free(self.unsupported);
        allocator.free(self.typed_v2_fallbacks);
        self.* = undefined;
    }
};

pub const TypedV2Fallback = lowering_context.TypedV2Fallback;
const LoweringContext = lowering_context.LoweringContext;

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const TypedValue = air_model.TypedValue;
const LowerError = air_model.LowerError;
const TypedBranchMergeResult = air_model.TypedBranchMergeResult;
const parseFunctionType = air_types.parseFunctionType;
const stripFunctionTypeQualifiers = air_types.stripFunctionTypeQualifiers;
const functionReturnTypeText = air_types.functionReturnTypeText;
const parseZigType = air_types.parseZigType;
const isOpaqueNominalTypeSurface = air_types.isOpaqueNominalTypeSurface;
const pointerLoadResultType = air_types.pointerLoadResultType;
const isErrorUnionTypeText = air_types.isErrorUnionTypeText;
const errorUnionPayloadType = air_types.errorUnionPayloadType;
const parseConstant = air_values.parseConstant;
const parseSymbolPointer = air_values.parseSymbolPointer;
const materializedGlobalInitializer = air_values.materializedGlobalInitializer;
const cStringLiteralByteLen = air_values.cStringLiteralByteLen;
const isRootSourceFunction = air_roots.isRootSourceFunction;
const rootFunctionCount = air_roots.rootFunctionCount;
const addMissingCallDeclarations = air_calls.addMissingCallDeclarations;
const parseInstructionRef = air_text.instructionRef;
const isSimpleSelectBlock = air_model.simpleSelectBlock;
const belongsToSimpleSelectBlock = air_model.belongsToSimpleSelectBlock;
const instructionPosition = air_model.instructionRecordPosition;
const typedBlockTarget = air_model.blockTarget;
const irCallingConvention = air_model.irCallingConvention;
const isIgnoredOpcode = air_capabilities.isIgnoredOpcode;
const isStraightLineOpcode = air_capabilities.isStraightLineOpcode;
const isShiftOpcode = air_capabilities.isShiftOpcode;
const isCallOpcode = air_capabilities.isCallOpcode;
const isPlainFieldPointerChild = air_model.plainFieldPointerChild;
const isSupportedTypedGepElementType = air_model.supportedTypedGepElementType;
const aggregateFieldByteOffset = air_model.aggregateFieldByteOffset;
const genericTypedGepIndex = air_model.genericTypedGepIndex;
const typedV2InstructionMissingRequiredDetail = air_model.instructionMissingRequiredDetail;
const binaryOp = air_semantics.binaryOp;
const intPredicate = air_semantics.intPredicate;
const fpPredicate = air_semantics.fpPredicate;
const castOp = air_semantics.castOp;
const isFpType = air_semantics.isFpType;
const intBits = air_semantics.intBits;
const shortFunctionName = air_model.shortFunctionName;
const isPointerType = air_types.isPointerType;
const pointerChildText = air_types.pointerChildText;
const ownPrint = air_model.ownPrint;
const findMatching = air_text.findMatching;
const splitTopLevel = air_text.splitTopLevel;
const typed_v2 = @import("zig_air_lowering_typed_v2.zig");
const typed_v2_fallbacks = @import("zig_air_lowering_typed_v2_fallbacks.zig");
const legacy = @import("zig_air_lowering_legacy.zig");

const runtimeNavSymbol = legacy.runtimeNavSymbol;
const ensureBase64LookupGlobal = typed_v2_fallbacks.ensureBase64LookupGlobal;

const typedV2RegisterAggregateRecords = typed_v2.typedV2RegisterAggregateRecords;
const typedV2ConstantZeroAggregateRecords = typed_v2.typedV2ConstantZeroAggregateRecords;
const typedV2SretIntegerAggregateRecords = typed_v2.typedV2SretIntegerAggregateRecords;
const typedV2SretIntegerAggregateCopyRecords = typed_v2.typedV2SretIntegerAggregateCopyRecords;
const typedV2SretIntegerAggregateFieldWrapperRecords = typed_v2.typedV2SretIntegerAggregateFieldWrapperRecords;
const typedV2SretIntegerAggregateCallWrapperRecords = typed_v2.typedV2SretIntegerAggregateCallWrapperRecords;
const typedV2ErrorUnionPayloadRecords = typed_v2.typedV2ErrorUnionPayloadRecords;
const typedV2MaybeErrorRecords = typed_v2.typedV2MaybeErrorRecords;
const typedV2OptionalPayloadRecords = typed_v2.typedV2OptionalPayloadRecords;
const typedV2OptionalPayloadBranchRecords = typed_v2.typedV2OptionalPayloadBranchRecords;
const typedV2OptionalPointerRecords = typed_v2.typedV2OptionalPointerRecords;
const typedV2PackedReadFlagRecords = typed_v2.typedV2PackedReadFlagRecords;
const typedV2PackedReplaceLowRecords = typed_v2.typedV2PackedReplaceLowRecords;
const typedV2SliceSumRecords = typed_v2.typedV2SliceSumRecords;
const typedV2ConditionalSliceSumRecords = typed_v2.typedV2ConditionalSliceSumRecords;
const typedV2AccumulatorLoopRecords = typed_v2.typedV2AccumulatorLoopRecords;
const typedV2ConditionalSlotUpdateRecords = typed_v2.typedV2ConditionalSlotUpdateRecords;
const typedV2LoopTryRecords = typed_v2.typedV2LoopTryRecords;
const typedV2DenseIntegerSwitchResults = typed_v2.typedV2DenseIntegerSwitchResults;
const typedV2ErrorSwitchRecords = typed_v2.typedV2ErrorSwitchRecords;
const typedV2ErrorClassifierRecords = typed_v2.typedV2ErrorClassifierRecords;
const typedV2RuntimeOptionalPointerMainRecords = typed_v2.typedV2RuntimeOptionalPointerMainRecords;
const typedV2RuntimePointerLoadStoreMainRecords = typed_v2.typedV2RuntimePointerLoadStoreMainRecords;
const typedV2MixCAddMayPanicRecords = typed_v2.typedV2MixCAddMayPanicRecords;
const typedV2CheckedIntFromFloatRecords = typed_v2.typedV2CheckedIntFromFloatRecords;
const typedV2UnionTagPayloadSwitchRecords = typed_v2.typedV2UnionTagPayloadSwitchRecords;
const typedV2UnionTagPayloadBranchRecords = typed_v2.typedV2UnionTagPayloadBranchRecords;
const typedV2AsciiPredicateRecords = typed_v2.typedV2AsciiPredicateRecords;
const lowerTypedV2ArraySum = legacy.lowerTypedV2ArraySum;
const lowerTypedV2AggregatePairAbi = legacy.lowerTypedV2AggregatePairAbi;
const lowerTypedV2SmallIntegerAggregateAbi = typed_v2.lowerTypedV2SmallIntegerAggregateAbi;
const lowerTypedV2SretIntegerAggregateAbi = typed_v2.lowerTypedV2SretIntegerAggregateAbi;
const lowerTypedV2ErrorUnionPayload = typed_v2.lowerTypedV2ErrorUnionPayload;
const lowerTypedV2MaybeError = typed_v2.lowerTypedV2MaybeError;
const lowerTypedV2OptionalPayload = typed_v2.lowerTypedV2OptionalPayload;
const lowerTypedV2OptionalPayloadBranch = typed_v2.lowerTypedV2OptionalPayloadBranch;
const lowerTypedV2OptionalPointer = typed_v2.lowerTypedV2OptionalPointer;
const typedV2VoidRetPtrRecords = typed_v2.typedV2VoidRetPtrRecords;
const lowerTypedV2VoidRetPtr = typed_v2.lowerTypedV2VoidRetPtr;
const typedV2SingleFieldWrapperRecords = typed_v2.typedV2SingleFieldWrapperRecords;
const typedV2SingleFieldWrapperArgType = typed_v2.typedV2SingleFieldWrapperArgType;
const lowerTypedV2SingleFieldWrapper = typed_v2.lowerTypedV2SingleFieldWrapper;
const classifyWrapperAbiTier = typed_v2.classifyWrapperAbiTier;
const lowerTypedV2PackedBits = typed_v2.lowerTypedV2PackedBits;
const lowerTypedV2ConditionalSliceSum = typed_v2.lowerTypedV2ConditionalSliceSum;
const lowerTypedV2SliceSum = typed_v2.lowerTypedV2SliceSum;
const lowerTypedV2InlineAsmBarrier = typed_v2.lowerTypedV2InlineAsmBarrier;
const lowerTypedV2AtomicAdd = typed_v2.lowerTypedV2AtomicAdd;
const lowerTypedV2AtomicTryLock = typed_v2.lowerTypedV2AtomicTryLock;
const lowerTypedV2AccumulatorLoop = typed_v2.lowerTypedV2AccumulatorLoop;
const lowerTypedV2ConditionalSlotUpdate = typed_v2.lowerTypedV2ConditionalSlotUpdate;
const lowerTypedV2LoopTry = typed_v2.lowerTypedV2LoopTry;
const lowerTypedV2DenseIntegerSwitch = typed_v2.lowerTypedV2DenseIntegerSwitch;
const lowerTypedV2ErrorSwitch = typed_v2.lowerTypedV2ErrorSwitch;
const lowerTypedV2ErrorClassifier = typed_v2.lowerTypedV2ErrorClassifier;
const lowerTypedV2RuntimeOptionalPointerMain = typed_v2.lowerTypedV2RuntimeOptionalPointerMain;
const lowerTypedV2RuntimePointerLoadStoreMain = typed_v2.lowerTypedV2RuntimePointerLoadStoreMain;
const lowerTypedV2MixCAddMayPanic = typed_v2.lowerTypedV2MixCAddMayPanic;
const lowerTypedV2CheckedIntFromFloat = typed_v2.lowerTypedV2CheckedIntFromFloat;
const lowerTypedV2UnionTagPayloadSwitch = typed_v2.lowerTypedV2UnionTagPayloadSwitch;
const lowerTypedV2UnionTagPayloadBranch = typed_v2.lowerTypedV2UnionTagPayloadBranch;
const lowerTypedV2AsciiPredicate = typed_v2.lowerTypedV2AsciiPredicate;
const lowerTypedV2SingleRangePredicate = typed_v2.lowerTypedV2SingleRangePredicate;
const lowerTypedV2SupportsThreads = typed_v2.lowerTypedV2SupportsThreads;
const typedV2SupportsThreadsRecords = typed_v2.typedV2SupportsThreadsRecords;
const lowerTypedV2Utf8ValidCodepoint = typed_v2.lowerTypedV2Utf8ValidCodepoint;
const typedV2Utf8ValidCodepointRecords = typed_v2.typedV2Utf8ValidCodepointRecords;

const lowerErrorClassify = typed_v2_fallbacks.lowerErrorClassify;
const lowerErrorSwitch = typed_v2_fallbacks.lowerErrorSwitch;
const lowerMixCAddMayPanic = typed_v2_fallbacks.lowerMixCAddMayPanic;

const accumulatorLoopShape = legacy.accumulatorLoopShape;
const conditionalSlotUpdateShape = legacy.conditionalSlotUpdateShape;
const errorClassifyShape = legacy.errorClassifyShape;
const arraySumShape = legacy.arraySumShape;
const base64TableLookupShape = legacy.base64TableLookupShape;
const isIntegerSwitchBlock = legacy.isIntegerSwitchBlock;
const structSumShape = legacy.structSumShape;
const errorSwitchShape = legacy.errorSwitchShape;
const runtimeOptionalPointerMainShape = legacy.runtimeOptionalPointerMainShape;
const runtimePointerLoadStoreMainShape = legacy.runtimePointerLoadStoreMainShape;
const mixCAddMayPanicShape = legacy.mixCAddMayPanicShape;
const lowerAccumulatorLoop = legacy.lowerAccumulatorLoop;
const lowerConditionalSlotUpdate = legacy.lowerConditionalSlotUpdate;
const lowerRuntimeOptionalPointerMain = legacy.lowerRuntimeOptionalPointerMain;
const lowerRuntimePointerLoadStoreMain = legacy.lowerRuntimePointerLoadStoreMain;
const lowerIntegerSwitch = legacy.lowerIntegerSwitch;
const lowerArraySum = legacy.lowerArraySum;
const lowerStructSum = legacy.lowerStructSum;
const lowerBase64TableLookup = legacy.lowerBase64TableLookup;
const typedV2AggregatePairFirstRecords = legacy.typedV2AggregatePairFirstRecords;
const typedV2AggregateMakePairRecords = legacy.typedV2AggregateMakePairRecords;

pub fn lowerCompatible(
    allocator: std.mem.Allocator,
    air_module: air_export.Module,
) !Result {
    const previous_module_aggregate_facts = exported_aggregate_layout_facts.active_provider;
    const use_module_aggregate_facts = previous_module_aggregate_facts.facts.len == 0 and air_module.aggregate_layout_facts != null;
    if (use_module_aggregate_facts) {
        exported_aggregate_layout_facts.setActiveProvider(air_module.aggregate_layout_facts.?);
    }
    defer if (use_module_aggregate_facts) {
        exported_aggregate_layout_facts.setActiveProvider(previous_module_aggregate_facts);
    };

    var module: ir.Module = .{
        .allocator = allocator,
        .source = try allocator.dupe(u8, ""),
        .owned_strings = .empty,
        .source_filename = air_module.root_source,
        .target_triple = air_module.target,
        .target_datalayout = null,
        .module_asm = .empty,
        .named_types = .empty,
        .globals = .empty,
        .aliases = .empty,
        .comdats = .empty,
        .declarations = .empty,
        .functions = .empty,
        .attribute_groups = .empty,
        .metadata = .empty,
    };
    errdefer module.deinit();

    var unsupported: std.ArrayList(Diagnostic) = .empty;
    errdefer unsupported.deinit(allocator);
    var typed_v2_fallback_list: std.ArrayList(TypedV2Fallback) = .empty;
    errdefer typed_v2_fallback_list.deinit(allocator);

    for (air_module.globals) |air_global| {
        if (air_global.is_constant) continue;
        const global_type = parseZigType(air_global.type_text) orelse continue;
        if (global_type.ir_type != .int and global_type.ir_type != .float and
            global_type.ir_type != .double and global_type.ir_type != .ptr)
        {
            continue;
        }
        const address_attrs = if (!std.mem.eql(u8, air_global.thread_local, "default"))
            try ownPrint(&module, "thread_local({s})", .{air_global.thread_local})
        else
            null;
        try module.globals.append(allocator, .{
            .name = air_global.name,
            .linkage = .default,
            .address_attrs = address_attrs,
            .kind = .global,
            .ty = global_type.ir_type,
            .initializer = materializedGlobalInitializer(global_type.ir_type, air_global.initializer_text),
        });
    }

    var accepted_functions: usize = 0;
    var structured_air_v1_functions: usize = 0;
    var structured_air_v2_functions: usize = 0;
    var typed_air_type_functions: usize = 0;
    var typed_air_operand_functions: usize = 0;
    var legacy_air_text_lowering_functions: usize = 0;
    var generic_lowering_functions: usize = 0;
    const shape_recognizer_functions: usize = 0;
    const root_stem = std.fs.path.stem(air_module.root_source);
    const matched_root_functions = rootFunctionCount(air_module.functions, root_stem);
    for (air_module.functions) |air_function| {
        if (matched_root_functions != 0 and !isRootSourceFunction(root_stem, air_function.name)) continue;
        var scoped_aggregate_facts = try scopedAggregateLayoutFactsForFunction(allocator, air_function);
        defer scoped_aggregate_facts.deinit(allocator);
        const previous_aggregate_facts = exported_aggregate_layout_facts.active_provider;
        if (scoped_aggregate_facts.active) {
            exported_aggregate_layout_facts.setActiveProvider(scoped_aggregate_facts.provider);
        }
        defer if (scoped_aggregate_facts.active) {
            exported_aggregate_layout_facts.setActiveProvider(previous_aggregate_facts);
        };
        if (firstUnsupported(allocator, air_function)) |diagnostic| {
            try unsupported.append(allocator, diagnostic);
            continue;
        }
        var lowered_from_typed_v2 = true;
        var typed_v2_fallback: ?TypedV2Fallback = null;
        var function = function: {
            break :function lowerFunctionTypedV2(allocator, &module, air_module, air_function, &typed_v2_fallback) catch |typed_err| switch (typed_err) {
                error.UnsupportedAir => {
                    lowered_from_typed_v2 = false;
                    try typed_v2_fallback_list.append(allocator, typed_v2_fallback orelse firstTypedV2Fallback(air_function));
                    break :function lowerFunction(allocator, &module, air_function) catch |legacy_err| switch (legacy_err) {
                        error.UnsupportedAir => {
                            try unsupported.append(allocator, .{
                                .function = air_function.name,
                                .opcode = "lowering",
                                .reason = .instruction_type,
                            });
                            continue;
                        },
                        else => return legacy_err,
                    };
                },
                else => return typed_err,
            };
        };
        errdefer function.deinit(allocator);
        try module.functions.append(allocator, function);
        accepted_functions += 1;
        if (air_function.structured_air != null) structured_air_v1_functions += 1;
        if (air_function.structured_air_v2) |structured_air_v2| {
            structured_air_v2_functions += 1;
            if (air_model.typedResultCoverage(air_function, structured_air_v2)) typed_air_type_functions += 1;
            if (air_model.typedOperandCoverage(structured_air_v2)) typed_air_operand_functions += 1;
        }
        if (!lowered_from_typed_v2) legacy_air_text_lowering_functions += 1;
        generic_lowering_functions += 1;
    }

    try addMissingCallDeclarations(allocator, &module);
    var mem2reg_context: pass_manager.Context = .{
        .allocator = allocator,
        .io = undefined,
    };
    _ = try mem2reg.pass.run(&module, &mem2reg_context);
    try module.verify();
    return .{
        .module = module,
        .accepted_functions = accepted_functions,
        .structured_air_v1_functions = structured_air_v1_functions,
        .structured_air_v2_functions = structured_air_v2_functions,
        .typed_air_type_functions = typed_air_type_functions,
        .typed_air_operand_functions = typed_air_operand_functions,
        .legacy_air_text_lowering_functions = legacy_air_text_lowering_functions,
        .generic_lowering_functions = generic_lowering_functions,
        .shape_recognizer_functions = shape_recognizer_functions,
        .unsupported = try unsupported.toOwnedSlice(allocator),
        .typed_v2_fallbacks = try typed_v2_fallback_list.toOwnedSlice(allocator),
    };
}

pub fn firstUnsupported(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) ?Diagnostic {
    const typed_view = air_model.TypedFunctionView.init(function);
    const function_type = parseFunctionTypeForLowering(allocator, function) catch {
        return .{ .function = function.name, .opcode = "function-type", .reason = .function_type };
    };
    defer function_type.deinit(allocator);
    const typed_aggregate_pair =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2AggregatePairFirstRecords(function_type, structured_air_v2) or
                typedV2AggregateMakePairRecords(function_type, structured_air_v2)
        else
            false;
    const typed_register_aggregate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RegisterAggregateRecords(function_type, structured_air_v2) or
                typedV2ConstantZeroAggregateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_sret_integer_aggregate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SretIntegerAggregateRecords(function_type, structured_air_v2) or
                typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2) or
                typedV2SretIntegerAggregateFieldWrapperRecords(function_type, structured_air_v2) != null or
                typedV2SretIntegerAggregateCallWrapperRecords(function_type, structured_air_v2)
        else
            false;
    const typed_error_union_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorUnionPayloadRecords(function_type, structured_air_v2)
        else
            false;
    const typed_maybe_error =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2MaybeErrorRecords(function_type, structured_air_v2)
        else
            false;
    const typed_optional_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2OptionalPayloadRecords(function_type, structured_air_v2) or
                typedV2OptionalPayloadBranchRecords(function_type, structured_air_v2)
        else
            false;
    const typed_optional_pointer =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2OptionalPointerRecords(function_type, structured_air_v2)
        else
            false;
    const typed_packed_bits =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2PackedReadFlagRecords(function_type, structured_air_v2) or
                typedV2PackedReplaceLowRecords(function_type, structured_air_v2)
        else
            false;
    const typed_slice_sum =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SliceSumRecords(function_type, structured_air_v2) or
                typedV2ConditionalSliceSumRecords(function_type, structured_air_v2)
        else
            false;
    const typed_accumulator_loop =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2AccumulatorLoopRecords(function_type, structured_air_v2)
        else
            false;
    const typed_conditional_slot_update =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ConditionalSlotUpdateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_loop_try =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2LoopTryRecords(function_type, structured_air_v2)
        else
            false;
    const typed_integer_switch =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2DenseIntegerSwitchResults(function_type, structured_air_v2) != null
        else
            false;
    const typed_error_switch =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorSwitchRecords(function_type, structured_air_v2)
        else
            false;
    const typed_error_classifier =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorClassifierRecords(function_type, structured_air_v2)
        else
            false;
    const typed_runtime_optional_pointer_main =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RuntimeOptionalPointerMainRecords(function_type, structured_air_v2)
        else
            false;
    const typed_runtime_pointer_load_store_main =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2RuntimePointerLoadStoreMainRecords(function_type, structured_air_v2)
        else
            false;
    const typed_mix_c_add_may_panic =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2MixCAddMayPanicRecords(function_type, structured_air_v2)
        else
            false;
    const typed_checked_int_from_float =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2CheckedIntFromFloatRecords(function_type, structured_air_v2)
        else
            false;
    const typed_union_tag_payload_switch =
        if (function.structured_air) |structured_air|
            if (function.structured_air_v2) |structured_air_v2|
                typedV2UnionTagPayloadSwitchRecords(function_type, structured_air, structured_air_v2)
            else
                false
        else
            false;
    const typed_union_tag_payload_branch =
        if (function.structured_air) |structured_air|
            if (function.structured_air_v2) |structured_air_v2|
                typedV2UnionTagPayloadBranchRecords(function_type, structured_air, structured_air_v2)
            else
                false
        else
            false;
    const typed_atomic_try_lock =
        if (function.structured_air_v2) |structured_air_v2|
            air_model.typedAtomicTryLockSummary(function_type, structured_air_v2) != null
        else
            false;
    const typed_void_ret_ptr =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2VoidRetPtrRecords(function_type, structured_air_v2)
        else
            false;
    const typed_single_field_wrapper =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SingleFieldWrapperRecords(structured_air_v2)
        else
            false;
    const typed_field_extractor =
        if (function.structured_air_v2) |structured_air_v2|
            typed_v2.typedV2FieldExtractorArgType(structured_air_v2) != null
        else
            false;
    const typed_ascii_predicate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2AsciiPredicateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_supports_threads =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SupportsThreadsRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_utf8_valid_codepoint =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2Utf8ValidCodepointRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_atomic_load_field0 =
        if (function.structured_air_v2) |structured_air_v2|
            typed_v2.typedV2AtomicLoadField0Records(function_type, structured_air_v2)
        else
            false;
    const typed_duration_from_seconds =
        if (function.structured_air_v2) |structured_air_v2|
            typed_v2.typedV2DurationFromSecondsRecords(function_type, structured_air_v2)
        else
            false;
    const typed_compilation_path_fmt =
        if (function.structured_air_v2) |structured_air_v2|
            typed_v2.typedV2CompilationPathFmtRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_io_limit_to_int = typed_v2.typedV2IoLimitToIntRecords(function, function_type);
    const typed_sema_block_is_comptime = typed_v2.typedV2SemaBlockIsComptimeRecords(function, function_type);

    if (typed_accumulator_loop or
        accumulatorLoopShape(function) != null or
        typed_error_classifier or
        errorClassifyShape(function) or
        typed_integer_switch or
        isIntegerSwitchBlock(function) or
        typed_conditional_slot_update or
        conditionalSlotUpdateShape(function) or
        typed_loop_try or
        typed_runtime_optional_pointer_main or
        runtimeOptionalPointerMainShape(function) or
        typed_optional_pointer or
        typed_runtime_pointer_load_store_main or
        runtimePointerLoadStoreMainShape(function) or
        typed_optional_payload or
        typed_error_switch or
        errorSwitchShape(function) or
        errorClassifyShape(function) or
        typed_error_union_payload or
        typed_slice_sum or
        typed_packed_bits or
        typed_aggregate_pair or
        typed_register_aggregate or
        typed_sret_integer_aggregate or
        typed_mix_c_add_may_panic or
        mixCAddMayPanicShape(function) or
        typed_checked_int_from_float or
        typed_union_tag_payload_switch or
        typed_union_tag_payload_branch or
        typed_atomic_try_lock or
        typed_void_ret_ptr or
        typed_single_field_wrapper or
        typed_field_extractor or
        typed_ascii_predicate or
        typed_supports_threads or
        typed_utf8_valid_codepoint or
        typed_atomic_load_field0 or
        typed_duration_from_seconds or
        typed_compilation_path_fmt or
        typed_io_limit_to_int or
        typed_sema_block_is_comptime or
        typed_maybe_error)
    {
        return null;
    }

    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or isStraightLineOpcode(instruction.opcode)) continue;
        if (air_capabilities.isBlockOpcode(instruction.opcode)) {
            if (isSimpleSelectBlock(function, instruction.index)) continue;
            if (typed_view != null and typed_view.?.orphanStructuredBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.voidGuardBlockByIndex(instruction.index)) continue;
            if (typed_view != null and typed_view.?.errorUnionVoidReturnContinueBlockByIndex(instruction.index)) continue;
            if (typed_view != null and typed_view.?.genericCfgBlock(instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsGenericCfgBlockInstruction(instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        if (air_capabilities.isCondBrOpcode(instruction.opcode) or
            air_capabilities.isBrOpcode(instruction.opcode) or
            air_capabilities.isSwitchBrOpcode(instruction.opcode))
        {
            if (belongsToSimpleSelectBlock(function, instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsVoidGuardBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsErrorUnionVoidReturnContinueBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsGenericCfgBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.terminalErrorUnionCondBr(instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        return .{ .function = function.name, .opcode = instruction.opcode, .reason = .opcode };
    }
    return null;
}

const ScopedAggregateLayoutFacts = struct {
    provider: exported_aggregate_layout_facts.Provider = .{},
    owned_start: usize = 0,
    active: bool = false,

    fn deinit(self: ScopedAggregateLayoutFacts, allocator: std.mem.Allocator) void {
        if (!self.active) return;
        for (self.provider.facts[self.owned_start..]) |fact| {
            allocator.free(fact.nominal_type_name);
            allocator.free(fact.aggregate_text);
        }
        allocator.free(self.provider.facts);
    }
};

fn scopedAggregateLayoutFactsForFunction(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) !ScopedAggregateLayoutFacts {
    const structured_air_v2 = function.structured_air_v2 orelse return .{};
    var facts: std.ArrayList(exported_aggregate_layout_facts.Fact) = .empty;
    try facts.appendSlice(allocator, exported_aggregate_layout_facts.active_provider.facts);
    const owned_start = facts.items.len;
    errdefer {
        for (facts.items[owned_start..]) |fact| {
            allocator.free(fact.nominal_type_name);
            allocator.free(fact.aggregate_text);
        }
        facts.deinit(allocator);
    }

    for (structured_air_v2.instructions) |instruction| {
        if (!air_model.isTypedFieldPtrDataKind(instruction.data_kind)) continue;
        const field_index = air_model.fieldIndex(instruction) orelse continue;
        if (field_index != 0) continue;
        if (instruction.operands.len != 1) continue;
        const source_child = pointerChildText(instruction.operands[0].type_text) orelse continue;
        if (!isOpaqueNominalTypeSurface(source_child)) continue;
        if (exported_aggregate_layout_facts.active_provider.lookup(source_child) != null or
            aggregate_layout_facts.lookup(source_child) != null) continue;
        const field_child = pointerChildText(instruction.result_type) orelse continue;
        const field_type = parseZigType(field_child) orelse continue;
        const field_text = irTypeTextForAggregateFact(allocator, field_type.ir_type) catch continue;
        defer allocator.free(field_text);
        const aggregate_text = try ownPrintText(allocator, "{{ {s} }}", .{field_text});
        errdefer allocator.free(aggregate_text);
        const nominal_type_name = try allocator.dupe(u8, source_child);
        errdefer allocator.free(nominal_type_name);
        try facts.append(allocator, .{
            .nominal_type_name = nominal_type_name,
            .aggregate_text = aggregate_text,
            .evidence = .{ .construction = false, .store = true, .load = true },
        });
    }
    if (facts.items.len == owned_start) {
        facts.deinit(allocator);
        return .{};
    }
    return .{
        .provider = .{ .facts = try facts.toOwnedSlice(allocator) },
        .owned_start = owned_start,
        .active = true,
    };
}

fn irTypeTextForAggregateFact(allocator: std.mem.Allocator, ty: ir.Type) ![]const u8 {
    return switch (ty) {
        .int => |bits| try ownPrintText(allocator, "i{}", .{bits}),
        .float => try allocator.dupe(u8, "float"),
        .double => try allocator.dupe(u8, "double"),
        .ptr => try allocator.dupe(u8, "ptr"),
        else => error.UnsupportedAir,
    };
}

fn ownPrintText(allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) ![]const u8 {
    return try std.fmt.allocPrint(allocator, format, args);
}

fn parseFunctionTypeForLowering(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    return parseFunctionType(allocator, air_function.type_text) catch |err| switch (err) {
        error.UnsupportedAir => parseFunctionTypeWithFieldExtractor(allocator, air_function) catch |field_extractor_err| switch (field_extractor_err) {
            error.UnsupportedAir => parseFunctionTypeWithSingleFieldWrapper(allocator, air_function) catch |single_wrapper_err| switch (single_wrapper_err) {
                error.UnsupportedAir => parseFunctionTypeWithUnusedOpaqueParams(allocator, air_function) catch |fallback_err| switch (fallback_err) {
                    error.UnsupportedAir => parseFunctionTypeWithUnionTagOnlyOpaqueSignature(allocator, air_function) catch |tag_err| switch (tag_err) {
                        error.UnsupportedAir => parseFunctionTypeWithOpaqueBitcasts(allocator, air_function),
                        else => return tag_err,
                    },
                    else => return fallback_err,
                },
                else => return single_wrapper_err,
            },
            else => return field_extractor_err,
        },
        else => return err,
    };
}

fn parseFunctionTypeWithFieldExtractor(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const arg_ty_text = typed_v2.typedV2FieldExtractorArgType(structured_air_v2) orelse return error.UnsupportedAir;
    const tier = classifyWrapperAbiTier(arg_ty_text) orelse return error.UnsupportedAir;

    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, air_function.type_text, " "));
    const suffix = if (std.mem.indexOfScalar(u8, trimmed, ')')) |close|
        std.mem.trim(u8, trimmed[close + 1 ..], " ")
    else
        "";
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);

    const param_ty: ZigType = switch (tier) {
        .int32 => .{ .ir_type = .{ .int = 32 } },
        .int64 => .{ .ir_type = .{ .int = 64 } },
        else => return error.UnsupportedAir,
    };
    try params.append(allocator, param_ty);

    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = .{ .ir_type = .{ .int = 32 } },
        .c_calling_convention = c_calling_convention,
        .non_default_calling_convention = non_default_calling_convention,
    };
}

fn parseFunctionTypeWithSingleFieldWrapper(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const arg_ty_text = typedV2SingleFieldWrapperArgType(structured_air_v2) orelse return error.UnsupportedAir;
    const tier = classifyWrapperAbiTier(arg_ty_text) orelse return error.UnsupportedAir;

    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, air_function.type_text, " "));
    const suffix = if (std.mem.indexOfScalar(u8, trimmed, ')')) |close|
        std.mem.trim(u8, trimmed[close + 1 ..], " ")
    else
        "";
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);

    const return_type: ZigType = switch (tier) {
        .int32 => blk: {
            try params.append(allocator, .{ .ir_type = .{ .int = 32 } });
            break :blk .{ .ir_type = .{ .int = 32 } };
        },
        .int64 => blk: {
            try params.append(allocator, .{ .ir_type = .{ .int = 64 } });
            break :blk .{ .ir_type = .{ .int = 64 } };
        },
        .int128 => blk: {
            try params.append(allocator, .{ .ir_type = .{ .int = 128 } });
            break :blk .{ .ir_type = .{ .int = 128 } };
        },
        .memory_sret => blk: {
            try params.append(allocator, .{ .ir_type = .ptr });
            try params.append(allocator, .{ .ir_type = .ptr });
            break :blk .{ .ir_type = .void };
        },
    };

    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
        .non_default_calling_convention = non_default_calling_convention,
    };
}

fn parseFunctionTypeWithUnusedOpaqueParams(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, air_function.type_text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;
    const return_text = functionReturnTypeText(air_function.type_text) orelse return error.UnsupportedAir;
    const return_type = parseZigType(return_text) orelse return error.UnsupportedAir;

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = splitTopLevel(params_text, ',');
    var param_index: usize = 0;
    while (fields.next()) |field| {
        const param_text = std.mem.trim(u8, field, " ");
        if (param_text.len == 0) continue;
        const param_type = parseZigType(param_text) orelse blk: {
            if (!functionParamValueUsed(air_function, param_index) and isOpaqueNominalTypeSurface(param_text)) {
                break :blk ZigType{ .ir_type = .ptr };
            }
            return error.UnsupportedAir;
        };
        param_index += 1;
        if (param_type.ir_type == .void) continue;
        try params.append(allocator, param_type);
    }
    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
        .non_default_calling_convention = non_default_calling_convention,
    };
}

fn parseFunctionTypeWithUnionTagOnlyOpaqueSignature(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    const bit_width = unionTagOnlyReturnBitWidth(air_function) orelse return error.UnsupportedAir;
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, air_function.type_text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    var fields = splitTopLevel(params_text, ',');
    const param_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
    if (param_text.len == 0 or fields.next() != null or !isOpaqueNominalTypeSurface(param_text)) {
        return error.UnsupportedAir;
    }
    const return_text = functionReturnTypeText(air_function.type_text) orelse return error.UnsupportedAir;
    if (!isOpaqueNominalTypeSurface(return_text)) return error.UnsupportedAir;

    var params = try allocator.alloc(ZigType, 1);
    errdefer allocator.free(params);
    params[0] = .{ .ir_type = .{ .int = bit_width } };
    return .{
        .params = params,
        .return_type = .{ .ir_type = .{ .int = bit_width } },
        .c_calling_convention = false,
        .non_default_calling_convention = false,
    };
}

fn parseFunctionTypeWithOpaqueBitcasts(
    allocator: std.mem.Allocator,
    air_function: air_export.Function,
) !FunctionType {
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const trimmed = stripFunctionTypeQualifiers(std.mem.trim(u8, air_function.type_text, " "));
    if (!std.mem.startsWith(u8, trimmed, "fn (")) return error.UnsupportedAir;
    const params_end = findMatching(trimmed, 3, '(', ')') orelse return error.UnsupportedAir;
    const params_text = trimmed[4..params_end];
    const suffix = std.mem.trim(u8, trimmed[params_end + 1 ..], " ");
    const c_calling_convention = std.mem.startsWith(u8, suffix, "callconv(.c)");
    const non_default_calling_convention = std.mem.startsWith(u8, suffix, "callconv(") and !c_calling_convention;
    const return_text = functionReturnTypeText(air_function.type_text) orelse return error.UnsupportedAir;
    const return_type = parseZigType(return_text) orelse try inferredOpaqueBitcastType(structured_air_v2, return_text);

    var params: std.ArrayList(ZigType) = .empty;
    errdefer params.deinit(allocator);
    var fields = splitTopLevel(params_text, ',');
    while (fields.next()) |field| {
        const param_text = std.mem.trim(u8, field, " ");
        if (param_text.len == 0) continue;
        const param_type = parseZigType(param_text) orelse try inferredOpaqueBitcastType(structured_air_v2, param_text);
        if (param_type.ir_type == .void) continue;
        try params.append(allocator, param_type);
    }
    return .{
        .params = try params.toOwnedSlice(allocator),
        .return_type = return_type,
        .c_calling_convention = c_calling_convention,
        .non_default_calling_convention = non_default_calling_convention,
    };
}

fn inferredOpaqueBitcastType(structured_air_v2: air_export.StructuredAirV2, text: []const u8) !ZigType {
    if (!isOpaqueNominalTypeSurface(text)) return error.UnsupportedAir;
    var inferred: ?ZigType = null;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.opcode, "bitcast") or
            std.mem.eql(u8, instruction.opcode, "bit_cast") or
            std.mem.eql(u8, instruction.opcode, "bit_cast_safe") or
            std.mem.eql(u8, instruction.opcode, "bitcast_safe") or
            std.mem.eql(u8, instruction.opcode, "intcast") or
            std.mem.eql(u8, instruction.opcode, "intcast_safe") or
            std.mem.eql(u8, instruction.opcode, "int_cast") or
            std.mem.eql(u8, instruction.opcode, "int_cast_safe"))
        {
            if (std.mem.eql(u8, instruction.result_type, text)) {
                const operand_type = singleOperandType(instruction) orelse continue;
                const concrete = parseScalarBitcastType(operand_type) orelse continue;
                try mergeInferredOpaqueBitcastType(&inferred, concrete);
            }
            if (std.mem.eql(u8, singleOperandType(instruction) orelse "", text)) {
                const concrete = parseScalarBitcastType(instruction.result_type) orelse continue;
                try mergeInferredOpaqueBitcastType(&inferred, concrete);
            }
        }
    }
    return inferred orelse error.UnsupportedAir;
}

fn singleOperandType(instruction: air_export.TypedInstruction) ?[]const u8 {
    if (instruction.operands.len != 1) return null;
    return instruction.operands[0].type_text;
}

fn parseScalarBitcastType(text: []const u8) ?ZigType {
    const parsed = parseZigType(text) orelse return null;
    return switch (parsed.ir_type) {
        .int, .ptr, .float, .double => parsed,
        .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => null,
    };
}

fn mergeInferredOpaqueBitcastType(inferred: *?ZigType, concrete: ZigType) !void {
    if (inferred.*) |existing| {
        if (!existing.ir_type.eql(concrete.ir_type) or existing.signed != concrete.signed) {
            return error.UnsupportedAir;
        }
        return;
    }
    inferred.* = concrete;
}

fn unionTagOnlyReturnBitWidth(air_function: air_export.Function) ?u16 {
    const structured_air = air_function.structured_air orelse return null;
    const structured_air_v2 = air_function.structured_air_v2 orelse return null;
    const main_body = structured_air.body(.main, null) orelse return null;
    if (main_body.instructions.len != air_function.main_body_count) return null;

    var arg_index: ?u32 = null;
    var get_tag_index: ?u32 = null;
    var bit_width: ?u16 = null;
    var ret_seen = false;
    var semantic_count: usize = 0;

    for (main_body.instructions) |instruction_index| {
        const instruction = typedInstructionByIndex(structured_air_v2, instruction_index) orelse return null;
        if (std.mem.eql(u8, instruction.opcode, "dbg_stmt")) continue;
        semantic_count += 1;
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            if (arg_index != null or instruction.operands.len != 0) return null;
            arg_index = instruction.index;
        } else if (std.mem.eql(u8, instruction.opcode, "get_union_tag")) {
            if (get_tag_index != null) return null;
            const arg = arg_index orelse return null;
            const summary = air_model.typedUnionTagGetSummary(instruction) orelse return null;
            if (summary.operand_index != arg) return null;
            get_tag_index = instruction.index;
            bit_width = summary.bit_width;
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or std.mem.eql(u8, instruction.opcode, "ret_safe")) {
            if (ret_seen or instruction.operands.len != 1) return null;
            const get_tag = get_tag_index orelse return null;
            if (air_model.typedInstOperandIndex(instruction.operands[0]) != get_tag) return null;
            ret_seen = true;
        } else {
            return null;
        }
    }

    if (semantic_count != 3 or !ret_seen) return null;
    return bit_width;
}

fn typedInstructionByIndex(structured_air_v2: air_export.StructuredAirV2, index: u32) ?air_export.TypedInstruction {
    for (structured_air_v2.instructions) |instruction| {
        if (instruction.index == index) return instruction;
    }
    return null;
}

fn functionParamValueUsed(function: air_export.Function, param_index: usize) bool {
    for (function.instructions) |instruction| {
        if (!std.mem.eql(u8, instruction.opcode, "arg")) continue;
        const arg_index = legacyArgParamIndex(instruction.payload) orelse return true;
        if (arg_index == param_index and legacyInstructionValueUsed(function, instruction)) return true;
    }
    if (function.structured_air_v2) |structured_air_v2| {
        var arg_index: usize = 0;
        for (structured_air_v2.instructions) |instruction| {
            if (!std.mem.eql(u8, instruction.opcode, "arg")) continue;
            if (arg_index == param_index and typedInstructionValueUsed(structured_air_v2, instruction.index)) {
                return true;
            }
            arg_index += 1;
        }
    }
    return false;
}

fn legacyArgParamIndex(payload: []const u8) ?usize {
    var fields = splitTopLevel(payload, ',');
    _ = fields.next() orelse return null;
    const index_text = std.mem.trim(u8, fields.next() orelse return null, " ");
    if (fields.next() != null) return null;
    return std.fmt.parseInt(usize, index_text, 10) catch null;
}

fn legacyInstructionValueUsed(function: air_export.Function, instruction: air_export.Instruction) bool {
    if (!instruction.unused) return true;
    if (function.structured_air_v2) |structured_air_v2| {
        if (typedInstructionValueUsed(structured_air_v2, instruction.index)) return true;
    }
    return false;
}

fn typedInstructionValueUsed(structured_air_v2: air_export.StructuredAirV2, instruction_index: u32) bool {
    for (structured_air_v2.instructions) |instruction| {
        for (instruction.operands) |operand| {
            const index = air_model.typedInstOperandIndex(operand) orelse continue;
            if (index == instruction_index) return true;
        }
    }
    return false;
}

fn firstTypedV2Fallback(function: air_export.Function) TypedV2Fallback {
    _ = function.structured_air orelse return .{
        .function = function.name,
        .opcode = "structured_air-v1",
        .data_kind = "-",
        .reason = "missing",
    };
    _ = function.structured_air_v2 orelse return .{
        .function = function.name,
        .opcode = "structured_air-v2",
        .data_kind = "-",
        .reason = "missing",
    };
    const view = air_model.TypedFunctionView.init(function).?;
    const main_body = view.body(.main, null) orelse return .{
        .function = function.name,
        .opcode = "main_body",
        .data_kind = "-",
        .reason = "missing",
    };
    for (main_body.instructions) |instruction_index| {
        const instruction = view.instruction(instruction_index) orelse return .{
            .function = function.name,
            .opcode = "typed_inst",
            .data_kind = "-",
            .reason = "missing_index",
        };
        const capability = view.capability(instruction);
        if (capability.status == .ignored_metadata) continue;
        if (!air_capabilities.typedV2CanLower(capability)) {
            return .{
                .function = function.name,
                .opcode = instruction.opcode,
                .data_kind = instruction.data_kind,
                .reason = air_capabilities.typedV2FallbackReason(capability),
            };
        }
        if (typedV2InstructionMissingRequiredDetail(instruction)) |detail| {
            return .{
                .function = function.name,
                .opcode = instruction.opcode,
                .data_kind = instruction.data_kind,
                .reason = detail,
            };
        }
    }
    return .{
        .function = function.name,
        .opcode = "typed_v2",
        .data_kind = "-",
        .reason = "lowering_validation",
    };
}

fn lowerFunction(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
) !ir.Function {
    if (accumulatorLoopShape(air_function)) |shape| {
        return lowerAccumulatorLoop(allocator, module, air_function, shape);
    }
    if (errorClassifyShape(air_function)) return lowerErrorClassify(allocator, air_function);
    if (isIntegerSwitchBlock(air_function)) {
        return lowerIntegerSwitch(allocator, module, air_function);
    }
    if (conditionalSlotUpdateShape(air_function)) {
        return lowerConditionalSlotUpdate(allocator, air_function);
    }
    if (arraySumShape(air_function)) return lowerArraySum(allocator, air_function);
    if (structSumShape(air_function)) return lowerStructSum(allocator, air_function);
    if (base64TableLookupShape(air_function)) return lowerBase64TableLookup(allocator, module, air_function);
    if (runtimeOptionalPointerMainShape(air_function)) return lowerRuntimeOptionalPointerMain(allocator, air_function);
    if (runtimePointerLoadStoreMainShape(air_function)) return lowerRuntimePointerLoadStoreMain(allocator, air_function);
    if (errorSwitchShape(air_function)) return lowerErrorSwitch(allocator, air_function);
    if (mixCAddMayPanicShape(air_function)) return lowerMixCAddMayPanic(allocator, module, air_function);

    const function_type = try parseFunctionTypeForLowering(allocator, air_function);
    defer function_type.deinit(allocator);

    var function = ir.Function.init(shortFunctionName(air_function.name), function_type.return_type.ir_type);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    if (runtimeNavSymbol(air_function)) |tls_symbol| {
        function.attrs = try ownPrint(module, "\"zllvm-tls-symbol\"=\"{s}\"", .{tls_symbol});
    }

    for (function_type.params, 0..) |param_type, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        try function.params.append(allocator, .{
            .ty = param_type.ir_type,
            .name = name,
        });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const values = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(values);
    @memset(values, null);
    const synthetic_pointer_payloads = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_pointer_payloads);
    @memset(synthetic_pointer_payloads, null);
    const synthetic_error_union_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_error_union_slots);
    @memset(synthetic_error_union_slots, null);
    const synthetic_union_tag_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_union_tag_slots);
    @memset(synthetic_union_tag_slots, null);
    const synthetic_union_field_ptrs = try allocator.alloc(?air_model.SyntheticUnionFieldPointer, air_function.instruction_count);
    defer allocator.free(synthetic_union_field_ptrs);
    @memset(synthetic_union_field_ptrs, null);
    const synthetic_vector_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_vector_slots);
    @memset(synthetic_vector_slots, null);
    const synthetic_vector_element_ptrs = try allocator.alloc(?air_model.SyntheticVectorElementPointer, air_function.instruction_count);
    defer allocator.free(synthetic_vector_element_ptrs);
    @memset(synthetic_vector_element_ptrs, null);

    var context: LoweringContext = .{
        .allocator = allocator,
        .module = module,
        .air_function = air_function,
        .function_type = function_type,
        .function = &function,
        .block = &block,
        .values = values,
        .structured_air = null,
        .structured_air_v2 = null,
        .synthetic_pointer_payloads = synthetic_pointer_payloads,
        .synthetic_error_union_slots = synthetic_error_union_slots,
        .synthetic_union_tag_slots = synthetic_union_tag_slots,
        .synthetic_union_field_ptrs = synthetic_union_field_ptrs,
        .synthetic_vector_slots = synthetic_vector_slots,
        .synthetic_vector_element_ptrs = synthetic_vector_element_ptrs,
    };

    for (air_function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (try context.lowerLegacySemanticInstruction(instruction)) {
            continue;
        } else if (isCallOpcode(instruction.opcode)) {
            try context.lowerCall(instruction);
        } else if (air_capabilities.isAtomicRmwOpcode(instruction.opcode)) {
            try context.lowerAtomicRmw(instruction);
        } else if (air_capabilities.isAssemblyOpcode(instruction.opcode)) {
            try context.lowerAssembly(instruction);
        } else if (air_capabilities.isReturnOpcode(instruction.opcode)) {
            try context.lowerReturn(instruction);
        } else if (air_capabilities.isUnreachOpcode(instruction.opcode)) {
            block.terminator = .{ .@"unreachable" = {} };
        } else if (air_capabilities.isBlockOpcode(instruction.opcode) or
            air_capabilities.isCondBrOpcode(instruction.opcode) or
            air_capabilities.isBrOpcode(instruction.opcode))
        {
            continue;
        } else {
            return error.UnsupportedAir;
        }
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
}

fn lowerFunctionTypedV2(
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_module: air_export.Module,
    air_function: air_export.Function,
    typed_v2_fallback: ?*?TypedV2Fallback,
) LowerError!ir.Function {
    const structured_air = air_function.structured_air orelse return error.UnsupportedAir;
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const main_body = structured_air.body(.main, null) orelse return error.UnsupportedAir;

    const function_type = try parseFunctionTypeForLowering(allocator, air_function);
    defer function_type.deinit(allocator);
    if (try lowerTypedV2SingleFieldWrapper(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2FieldExtractor(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AsciiPredicate(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SingleRangePredicate(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SupportsThreads(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2Utf8ValidCodepoint(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2AtomicLoadField0(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2DurationFromSeconds(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2CompilationPathFmt(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2IoLimitToInt(allocator, air_function, function_type)) |function| {
        return function;
    }
    if (try typed_v2.lowerTypedV2SemaBlockIsComptime(allocator, air_function, function_type)) |function| {
        return function;
    }
    if (try lowerTypedV2VoidRetPtr(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPayload(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ArraySum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AggregatePairAbi(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SmallIntegerAggregateAbi(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SretIntegerAggregateAbi(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    var error_union_call_fact_reason: ?[]const u8 = null;
    if (lowerTypedV2ErrorUnionPayload(
        allocator,
        module,
        air_function,
        function_type,
        structured_air_v2,
        air_module.error_union_call_facts,
        &error_union_call_fact_reason,
    ) catch |err| switch (err) {
        error.UnsupportedAir => {
            if (error_union_call_fact_reason) |reason| {
                setTypedV2Fallback(typed_v2_fallback, air_function, "error_union_call_fact", "-", reason);
            }
            return err;
        },
        else => return err,
    }) |function| {
        return function;
    }
    if (try lowerTypedV2MaybeError(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPayloadBranch(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPointer(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2PackedBits(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ConditionalSliceSum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SliceSum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2InlineAsmBarrier(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AtomicAdd(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AtomicTryLock(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AccumulatorLoop(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ConditionalSlotUpdate(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2LoopTry(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2DenseIntegerSwitch(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorSwitch(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorClassifier(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2RuntimeOptionalPointerMain(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2RuntimePointerLoadStoreMain(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2MixCAddMayPanic(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2CheckedIntFromFloat(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2UnionTagPayloadSwitch(allocator, air_function, function_type, structured_air, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2UnionTagPayloadBranch(allocator, air_function, function_type, structured_air, structured_air_v2)) |function| {
        return function;
    }

    var function = ir.Function.init(shortFunctionName(air_function.name), function_type.return_type.ir_type);
    errdefer function.deinit(allocator);
    function.linkage = if (function_type.c_calling_convention) .default else .internal;
    function.calling_conv = irCallingConvention(function_type);
    if (runtimeNavSymbol(air_function)) |tls_symbol| {
        function.attrs = try ownPrint(module, "\"zllvm-tls-symbol\"=\"{s}\"", .{tls_symbol});
    }

    for (function_type.params, 0..) |param_type, param_index| {
        const name = try ownPrint(module, "arg{}", .{param_index});
        const attrs: ?[]const u8 = if (param_type.ir_type.eql(.{ .int = 8 }) and !param_type.signed)
            "zeroext"
        else
            null;
        try function.params.append(allocator, .{
            .ty = param_type.ir_type,
            .attrs = attrs,
            .name = name,
        });
    }

    var block = ir.BasicBlock.init("entry");
    errdefer block.deinit(allocator);
    const values = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(values);
    @memset(values, null);
    const synthetic_pointer_payloads = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_pointer_payloads);
    @memset(synthetic_pointer_payloads, null);
    const synthetic_error_union_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_error_union_slots);
    @memset(synthetic_error_union_slots, null);
    const synthetic_union_tag_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_union_tag_slots);
    @memset(synthetic_union_tag_slots, null);
    const synthetic_union_field_ptrs = try allocator.alloc(?air_model.SyntheticUnionFieldPointer, air_function.instruction_count);
    defer allocator.free(synthetic_union_field_ptrs);
    @memset(synthetic_union_field_ptrs, null);
    const synthetic_vector_slots = try allocator.alloc(?TypedValue, air_function.instruction_count);
    defer allocator.free(synthetic_vector_slots);
    @memset(synthetic_vector_slots, null);
    const synthetic_vector_element_ptrs = try allocator.alloc(?air_model.SyntheticVectorElementPointer, air_function.instruction_count);
    defer allocator.free(synthetic_vector_element_ptrs);
    @memset(synthetic_vector_element_ptrs, null);
    const typed_view = air_model.TypedFunctionView.init(air_function) orelse return error.UnsupportedAir;

    var context: LoweringContext = .{
        .allocator = allocator,
        .module = module,
        .air_function = air_function,
        .function_type = function_type,
        .function = &function,
        .block = &block,
        .values = values,
        .structured_air = structured_air,
        .structured_air_v2 = structured_air_v2,
        .typed_view = typed_view,
        .typed_v2_fallback = typed_v2_fallback,
        .synthetic_pointer_payloads = synthetic_pointer_payloads,
        .synthetic_error_union_slots = synthetic_error_union_slots,
        .synthetic_union_tag_slots = synthetic_union_tag_slots,
        .synthetic_union_field_ptrs = synthetic_union_field_ptrs,
        .synthetic_vector_slots = synthetic_vector_slots,
        .synthetic_vector_element_ptrs = synthetic_vector_element_ptrs,
    };

    for (main_body.instructions) |instruction_index| {
        const instruction = typed_view.instruction(instruction_index) orelse return error.UnsupportedAir;
        try context.lowerTypedInstruction(instruction);
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
}

fn setTypedV2Fallback(
    typed_v2_fallback: ?*?TypedV2Fallback,
    air_function: air_export.Function,
    opcode: []const u8,
    data_kind: []const u8,
    reason: []const u8,
) void {
    const slot = typed_v2_fallback orelse return;
    if (slot.* != null) return;
    slot.* = .{
        .function = air_function.name,
        .opcode = opcode,
        .data_kind = data_kind,
        .reason = reason,
    };
}

test "lowering parser admits unused opaque nominal parameters" {
    var ret_inst = [_]air_export.Instruction{.{
        .index = 0,
        .indent = 2,
        .unused = true,
        .opcode = "ret",
        .payload = "<u32, 12>",
        .category = .control_flow,
    }};
    const air_function: air_export.Function = .{
        .name = "pkg.f",
        .type_text = "fn (pkg.Opaque) u32",
        .instruction_count = 1,
        .main_body_count = 1,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = ret_inst[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type.ptr, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 32 }, function_type.return_type.ir_type);
}

test "lowering parser admits materialized opaque nominal parameters when their values are unused" {
    var arg_inst = [_]air_export.Instruction{.{
        .index = 0,
        .indent = 2,
        .unused = true,
        .opcode = "arg",
        .payload = "pkg.Opaque, 0",
        .category = .other,
    }};
    const air_function: air_export.Function = .{
        .name = "pkg.f",
        .type_text = "fn (pkg.Opaque) u32",
        .instruction_count = 1,
        .main_body_count = 1,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = arg_inst[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type.ptr, function_type.params[0].ir_type);
}

test "lowering parser rejects used opaque nominal parameters" {
    var arg_inst = [_]air_export.Instruction{.{
        .index = 0,
        .indent = 2,
        .unused = false,
        .opcode = "arg",
        .payload = "pkg.Opaque, 0",
        .category = .other,
    }};
    const air_function: air_export.Function = .{
        .name = "pkg.f",
        .type_text = "fn (pkg.Opaque) u32",
        .instruction_count = 1,
        .main_body_count = 1,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = null,
        .instructions = arg_inst[0..],
    };

    try std.testing.expectError(
        error.UnsupportedAir,
        parseFunctionTypeForLowering(std.testing.allocator, air_function),
    );
}

test "lowering parser infers opaque nominal parameter from typed bitcast" {
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Packed" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "u64" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "pkg.Packed", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "bitcast", .result_type = "u64", .data_kind = "ty_op", .operands = bitcast_operands[0..] },
        .{ .index = 2, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = "pkg.Packed, 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = false, .opcode = "bitcast", .payload = "u64, %0!", .category = .cast },
        .{ .index = 2, .indent = 2, .unused = true, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.get",
        .type_text = "fn (pkg.Packed) u64",
        .instruction_count = 3,
        .main_body_count = 3,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.return_type.ir_type);
}

test "lowering parser infers opaque generic pointer nominal parameter from typed bitcast" {
    const metadata_type = "hash_map.HashMapUnmanaged(*Zcu.Namespace,void,hash_map.AutoContext(*Zcu.Namespace),80).Metadata";
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = metadata_type },
    };
    var cmp_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "u8" },
        .{ .kind = "const", .value = "0", .type_text = "u8" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "bool" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = metadata_type, .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "bitcast", .result_type = "u8", .data_kind = "ty_op", .operands = bitcast_operands[0..] },
        .{ .index = 2, .opcode = "cmp_eq", .result_type = "bool", .data_kind = "bin_op", .operands = cmp_operands[0..] },
        .{ .index = 3, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = metadata_type ++ ", 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = false, .opcode = "bitcast", .payload = "u8, %0!", .category = .cast },
        .{ .index = 2, .indent = 2, .unused = false, .opcode = "cmp_eq", .payload = "%1!, @.zero_u8", .category = .other },
        .{ .index = 3, .indent = 2, .unused = true, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.isFree",
        .type_text = "fn (" ++ metadata_type ++ ") bool",
        .instruction_count = 4,
        .main_body_count = 4,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 8 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 1 }, function_type.return_type.ir_type);
}

test "lowering parser infers opaque nominal return from typed bitcast" {
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "u64" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "pkg.Packed" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "u64", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "bitcast", .result_type = "pkg.Packed", .data_kind = "ty_op", .operands = bitcast_operands[0..] },
        .{ .index = 2, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = "u64, 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = false, .opcode = "bitcast", .payload = "pkg.Packed, %0!", .category = .cast },
        .{ .index = 2, .indent = 2, .unused = true, .opcode = "ret", .payload = "%1!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.init",
        .type_text = "fn (u64) pkg.Packed",
        .instruction_count = 3,
        .main_body_count = 3,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.return_type.ir_type);
}

test "lowering parser infers opaque nominal return from typed intcast" {
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Source" },
    };
    var intcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "u6" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "pkg.Target" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "pkg.Source", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "bitcast", .result_type = "u6", .data_kind = "ty_op", .operands = bitcast_operands[0..] },
        .{ .index = 2, .opcode = "intcast", .result_type = "pkg.Target", .data_kind = "ty_op", .operands = intcast_operands[0..] },
        .{ .index = 3, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = "pkg.Source, 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = false, .opcode = "bitcast", .payload = "u6, %0!", .category = .cast },
        .{ .index = 2, .indent = 2, .unused = false, .opcode = "intcast", .payload = "pkg.Target, %1!", .category = .cast },
        .{ .index = 3, .indent = 2, .unused = true, .opcode = "ret", .payload = "%2!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.convert",
        .type_text = "fn (pkg.Source) pkg.Target",
        .instruction_count = 4,
        .main_body_count = 4,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 6 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 6 }, function_type.return_type.ir_type);
}

test "lowering parser infers opaque nominal return from typed safe intcast" {
    var intcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "usize" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "1", .type_text = "pkg.Target" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "usize", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "intcast_safe", .result_type = "pkg.Target", .data_kind = "ty_op", .operands = intcast_operands[0..] },
        .{ .index = 2, .opcode = "ret_safe", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = "usize, 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = false, .opcode = "intcast_safe", .payload = "pkg.Target, %0!", .category = .cast },
        .{ .index = 2, .indent = 2, .unused = true, .opcode = "ret_safe", .payload = "%1!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.convertSafe",
        .type_text = "fn (usize) pkg.Target",
        .instruction_count = 3,
        .main_body_count = 3,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 64 }, function_type.return_type.ir_type);
}

test "lowering accepts opaque nominal bitcast intcast return wrapper" {
    var bitcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Source" },
    };
    var intcast_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "u6" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "4", .type_text = "pkg.Target" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "pkg.Source", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 2, .opcode = "bitcast", .result_type = "u6", .data_kind = "ty_op", .operands = bitcast_operands[0..] },
        .{ .index = 3, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 4, .opcode = "intcast", .result_type = "pkg.Target", .data_kind = "ty_op", .operands = intcast_operands[0..] },
        .{ .index = 5, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 6, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var main_body_instructions = [_]u32{ 0, 1, 2, 3, 4, 5, 6 };
    var bodies = [_]air_export.StructuredBody{.{
        .kind = .main,
        .owner = null,
        .instructions = main_body_instructions[0..],
    }};
    var functions = [_]air_export.Function{.{
        .name = "pkg.convert",
        .type_text = "fn (pkg.Source) pkg.Target",
        .instruction_count = 7,
        .main_body_count = 7,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{
            .instructions = &.{},
            .bodies = bodies[0..],
            .branches = &.{},
            .cond_branches = &.{},
            .repeats = &.{},
        },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = &.{},
    }};
    const air_module: air_export.Module = .{
        .allocator = std.testing.allocator,
        .storage = "",
        .producer = "test",
        .root_source = "module.zig",
        .wrapper = "compiler-core-module",
        .mode = "ReleaseFast",
        .target = "x86_64-linux-gnu",
        .globals = &.{},
        .aggregate_layout_facts = null,
        .functions = functions[0..],
    };

    var result = try lowerCompatible(std.testing.allocator, air_module);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), result.unsupported.len);
    try std.testing.expectEqual(@as(usize, 1), result.module.functions.items.len);
    try std.testing.expect(result.module.functions.items[0].ret_ty.eql(.{ .int = 6 }));
}

test "lowering parser rejects conflicting opaque bitcast inference" {
    var wide_operand = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Packed" },
    };
    var narrow_operand = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Packed" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "pkg.Packed", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "bitcast", .result_type = "u64", .data_kind = "ty_op", .operands = wide_operand[0..] },
        .{ .index = 2, .opcode = "bitcast", .result_type = "u32", .data_kind = "ty_op", .operands = narrow_operand[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{.{
        .index = 0,
        .indent = 2,
        .unused = false,
        .opcode = "arg",
        .payload = "pkg.Packed, 0",
        .category = .argument,
    }};
    const air_function: air_export.Function = .{
        .name = "pkg.bad",
        .type_text = "fn (pkg.Packed) u64",
        .instruction_count = 3,
        .main_body_count = 3,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = null,
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    try std.testing.expectError(
        error.UnsupportedAir,
        parseFunctionTypeForLowering(std.testing.allocator, air_function),
    );
}

test "lowering parser admits union tag-only opaque nominal signatures" {
    var main_body_instructions = [_]u32{ 0, 1, 2, 3 };
    var bodies = [_]air_export.StructuredBody{.{
        .kind = .main,
        .owner = null,
        .instructions = main_body_instructions[0..],
    }};
    var structured_instructions = [_]air_export.StructuredInstruction{
        .{ .index = 0, .opcode = "arg", .type_text = "pkg.Payload" },
        .{ .index = 1, .opcode = "dbg_stmt", .type_text = "void" },
        .{ .index = 2, .opcode = "get_union_tag", .type_text = "pkg.Tag" },
        .{ .index = 3, .opcode = "ret_safe", .type_text = "noreturn" },
    };
    var get_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "pkg.Payload" },
    };
    var get_details = [_]air_export.TypedDetail{
        .{ .key = "union_tag_contract", .value = "zllvm-union-tag-facts-v1" },
        .{ .key = "bit_width", .value = "2" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "pkg.Tag" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "pkg.Payload", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 2, .opcode = "get_union_tag", .result_type = "pkg.Tag", .data_kind = "ty_op", .operands = get_operands[0..], .details = get_details[0..] },
        .{ .index = 3, .opcode = "ret_safe", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = false, .opcode = "arg", .payload = "pkg.Payload, 0", .category = .argument },
        .{ .index = 1, .indent = 2, .unused = true, .opcode = "dbg_stmt", .payload = "2:13", .category = .debug },
        .{ .index = 2, .indent = 2, .unused = false, .opcode = "get_union_tag", .payload = "pkg.Tag, %0!", .category = .other },
        .{ .index = 3, .indent = 2, .unused = true, .opcode = "ret_safe", .payload = "%2!", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "pkg.container",
        .type_text = "fn (pkg.Payload) pkg.Tag",
        .instruction_count = 4,
        .main_body_count = 4,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{
            .instructions = structured_instructions[0..],
            .bodies = bodies[0..],
            .branches = &.{},
            .cond_branches = &.{},
            .repeats = &.{},
        },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    const function_type = try parseFunctionTypeForLowering(std.testing.allocator, air_function);
    defer function_type.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), function_type.params.len);
    try std.testing.expectEqual(ir.Type{ .int = 2 }, function_type.params[0].ir_type);
    try std.testing.expectEqual(ir.Type{ .int = 2 }, function_type.return_type.ir_type);
}

test "lowering installs module aggregate facts for direct aggregate init returns" {
    const facts = [_]exported_aggregate_layout_facts.Fact{
        .{ .nominal_type_name = "sort.block.Range", .aggregate_text = "{ i64, i64 }" },
    };
    var init_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "0", .type_text = "usize" },
        .{ .kind = "inst", .value = "1", .type_text = "usize" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "3", .type_text = "sort.block.Range" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "usize", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "arg", .result_type = "usize", .data_kind = "arg", .operands = &.{} },
        .{ .index = 2, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 3, .opcode = "aggregate_init", .result_type = "sort.block.Range", .data_kind = "aggregate_init", .operands = init_operands[0..] },
        .{ .index = 4, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 5, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..] },
    };
    var main_body_instructions = [_]u32{ 0, 1, 2, 3, 4, 5 };
    var bodies = [_]air_export.StructuredBody{.{
        .kind = .main,
        .owner = null,
        .instructions = main_body_instructions[0..],
    }};
    var functions = [_]air_export.Function{.{
        .name = "sort.block.Range.init",
        .type_text = "fn (usize, usize) sort.block.Range",
        .instruction_count = 6,
        .main_body_count = 6,
        .has_liveness = false,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{
            .instructions = &.{},
            .bodies = bodies[0..],
            .branches = &.{},
            .cond_branches = &.{},
            .repeats = &.{},
        },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = &.{},
    }};
    const air_module: air_export.Module = .{
        .allocator = std.testing.allocator,
        .storage = "",
        .producer = "test",
        .root_source = "module.zig",
        .wrapper = "compiler-core-module",
        .mode = "ReleaseFast",
        .target = "x86_64-linux-gnu",
        .globals = &.{},
        .aggregate_layout_facts = .{ .facts = facts[0..] },
        .functions = functions[0..],
    };

    var result = try lowerCompatible(std.testing.allocator, air_module);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), result.unsupported.len);
    try std.testing.expectEqual(@as(usize, 1), result.module.functions.items.len);
}

test "lowering constructs pointer register aggregate from ret pointer store" {
    const facts = [_]exported_aggregate_layout_facts.Fact{
        .{ .nominal_type_name = "Air.Liveness.FmtInstSet", .aggregate_text = "{ ptr }" },
    };
    var field_details = [_]air_export.TypedDetail{.{ .key = "field_index", .value = "0" }};
    var field_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "2", .type_text = "*Air.Liveness.FmtInstSet" },
    };
    var store_operands = [_]air_export.TypedOperand{
        .{ .kind = "inst", .value = "3", .type_text = "**const hash_map.HashMapUnmanaged(Air.Inst.Index,void,hash_map.AutoContext(Air.Inst.Index),80)" },
        .{ .kind = "inst", .value = "0", .type_text = "*const hash_map.HashMapUnmanaged(Air.Inst.Index,void,hash_map.AutoContext(Air.Inst.Index),80)" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "arg", .result_type = "*const hash_map.HashMapUnmanaged(Air.Inst.Index,void,hash_map.AutoContext(Air.Inst.Index),80)", .data_kind = "arg", .operands = &.{} },
        .{ .index = 1, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 2, .opcode = "ret_ptr", .result_type = "*Air.Liveness.FmtInstSet", .data_kind = "ret_ptr", .operands = &.{} },
        .{ .index = 3, .opcode = "struct_field_ptr_index_0", .result_type = "**const hash_map.HashMapUnmanaged(Air.Inst.Index,void,hash_map.AutoContext(Air.Inst.Index),80)", .data_kind = "field_ptr", .operands = field_operands[0..], .details = field_details[0..] },
        .{ .index = 4, .opcode = "store", .result_type = "void", .data_kind = "store", .operands = store_operands[0..] },
        .{ .index = 5, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 6, .opcode = "ret_load", .result_type = "noreturn", .data_kind = "ret_load", .operands = &.{} },
    };
    var main_body_instructions = [_]u32{ 0, 1, 2, 3, 4, 5, 6 };
    var bodies = [_]air_export.StructuredBody{.{
        .kind = .main,
        .owner = null,
        .instructions = main_body_instructions[0..],
    }};
    var functions = [_]air_export.Function{.{
        .name = "Air.Liveness.fmtInstSet",
        .type_text = "fn (*const hash_map.HashMapUnmanaged(Air.Inst.Index,void,hash_map.AutoContext(Air.Inst.Index),80)) Air.Liveness.FmtInstSet",
        .instruction_count = 7,
        .main_body_count = 7,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{
            .instructions = &.{},
            .bodies = bodies[0..],
            .branches = &.{},
            .cond_branches = &.{},
            .repeats = &.{},
        },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = &.{},
    }};
    const air_module: air_export.Module = .{
        .allocator = std.testing.allocator,
        .storage = "",
        .producer = "test",
        .root_source = "main.zig",
        .wrapper = "compiler-core-module",
        .mode = "ReleaseFast",
        .target = "x86_64-linux-gnu",
        .globals = &.{},
        .aggregate_layout_facts = .{ .facts = facts[0..] },
        .functions = functions[0..],
    };

    var result = try lowerCompatible(std.testing.allocator, air_module);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), result.unsupported.len);
    try std.testing.expectEqual(@as(usize, 1), result.module.functions.items.len);
    try std.testing.expect(result.module.functions.items[0].ret_ty.eql(.{ .aggregate = "{ ptr }" }));
}

test "first unsupported ignores orphan structured block outside main body" {
    var main_body_instructions = [_]u32{ 0, 2, 3 };
    var bodies = [_]air_export.StructuredBody{.{
        .kind = .main,
        .owner = null,
        .instructions = main_body_instructions[0..],
    }};
    var structured_instructions = [_]air_export.StructuredInstruction{
        .{ .index = 0, .opcode = "dbg_stmt", .type_text = "void" },
        .{ .index = 1, .opcode = "block", .type_text = "block-result" },
        .{ .index = 2, .opcode = "dbg_stmt", .type_text = "void" },
        .{ .index = 3, .opcode = "ret", .type_text = "noreturn" },
    };
    var ret_operands = [_]air_export.TypedOperand{
        .{ .kind = "const", .value = "3", .type_text = "void" },
    };
    var ret_details = [_]air_export.TypedDetail{
        .{ .key = "operand0_text", .value = "@.void_value" },
    };
    var typed_instructions = [_]air_export.TypedInstruction{
        .{ .index = 0, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 1, .opcode = "block", .result_type = "block-result", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 2, .opcode = "dbg_stmt", .result_type = "void", .data_kind = "opaque", .operands = &.{} },
        .{ .index = 3, .opcode = "ret", .result_type = "noreturn", .data_kind = "un_op", .operands = ret_operands[0..], .details = ret_details[0..] },
    };
    var legacy_instructions = [_]air_export.Instruction{
        .{ .index = 0, .indent = 2, .unused = true, .opcode = "dbg_stmt", .payload = "2:17", .category = .debug },
        .{ .index = 1, .indent = 2, .unused = true, .opcode = "block", .payload = "", .category = .control_flow },
        .{ .index = 2, .indent = 2, .unused = true, .opcode = "dbg_stmt", .payload = "2:27", .category = .debug },
        .{ .index = 3, .indent = 2, .unused = true, .opcode = "ret", .payload = "@.void_value", .category = .return_op },
    };
    const air_function: air_export.Function = .{
        .name = "debug.ConfigurableTrace(2,4,false).dump",
        .type_text = "fn (debug.ConfigurableTrace(2,4,false)) void",
        .instruction_count = 4,
        .main_body_count = 3,
        .has_liveness = true,
        .air_text = "",
        .structured_air_text = null,
        .structured_air = .{
            .instructions = structured_instructions[0..],
            .bodies = bodies[0..],
            .branches = &.{},
            .cond_branches = &.{},
            .repeats = &.{},
        },
        .structured_air_v2_text = null,
        .structured_air_v2 = .{ .instructions = typed_instructions[0..] },
        .instructions = legacy_instructions[0..],
    };

    try std.testing.expectEqual(@as(?Diagnostic, null), firstUnsupported(std.testing.allocator, air_function));

    var air_functions = [_]air_export.Function{air_function};
    const air_module: air_export.Module = .{
        .allocator = std.testing.allocator,
        .storage = "",
        .producer = "test",
        .root_source = "main.zig",
        .wrapper = "main.zig",
        .mode = "ReleaseFast",
        .target = "x86_64-unknown-linux-gnu",
        .globals = &.{},
        .functions = air_functions[0..],
    };
    var result = try lowerCompatible(std.testing.allocator, air_module);
    defer result.deinit();
    try std.testing.expectEqual(@as(usize, 1), result.accepted_functions);
    try std.testing.expectEqual(@as(usize, 0), result.unsupported.len);
}
