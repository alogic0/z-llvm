const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");
const memory_location = @import("analysis/memory_location.zig");
const sib = @import("structured_ir_builder.zig");
const target_mod = @import("target.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");

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

pub const TypedV2Fallback = struct {
    function: []const u8,
    opcode: []const u8,
    data_kind: []const u8,
    reason: []const u8,
};

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const TypedValue = air_model.TypedValue;
const LowerError = air_model.LowerError;
const TypedBranchMergeResult = air_model.TypedBranchMergeResult;
const parseFunctionType = air_types.parseFunctionType;
const functionReturnTypeText = air_types.functionReturnTypeText;
const parseZigType = air_types.parseZigType;
const pointerLoadResultType = air_types.pointerLoadResultType;
const parseConstant = air_values.parseConstant;
const parseSymbolPointer = air_values.parseSymbolPointer;
const parseInstructionRef = air_text.instructionRef;
const isSimpleSelectBlock = air_model.simpleSelectBlock;
const belongsToSimpleSelectBlock = air_model.belongsToSimpleSelectBlock;
const instructionPosition = air_model.instructionRecordPosition;
const typedBlockTarget = air_model.blockTarget;
const typedDetail = air_model.detail;
const typedOperandTextDetail = air_model.operandTextDetail;
const typedCalleeName = air_model.calleeName;
const typedCallee = air_model.callee;
const irCallingConvention = air_model.irCallingConvention;
const isIgnoredOpcode = air_capabilities.isIgnoredOpcode;
const isStraightLineOpcode = air_capabilities.isStraightLineOpcode;
const isArithmeticOpcode = air_capabilities.isArithmeticOpcode;
const isShiftOpcode = air_capabilities.isShiftOpcode;
const isCastOpcode = air_capabilities.isCastOpcode;
const isFieldPtrOpcode = air_capabilities.isFieldPtrOpcode;
const isCallOpcode = air_capabilities.isCallOpcode;
const isPlainFieldPointerChild = air_model.plainFieldPointerChild;
const isSupportedTypedGepElementType = air_model.supportedTypedGepElementType;
const selectedFieldByteOffset = air_model.selectedFieldByteOffset;
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
const typedV2SretIntegerAggregateRecords = typed_v2.typedV2SretIntegerAggregateRecords;
const typedV2SretIntegerAggregateCopyRecords = typed_v2.typedV2SretIntegerAggregateCopyRecords;
const typedV2ErrorUnionPayloadRecords = typed_v2.typedV2ErrorUnionPayloadRecords;
const typedV2MaybeErrorRecords = typed_v2.typedV2MaybeErrorRecords;
const typedV2OptionalPayloadRecords = typed_v2.typedV2OptionalPayloadRecords;
const typedV2OptionalPointerRecords = typed_v2.typedV2OptionalPointerRecords;
const typedV2PackedReadFlagRecords = typed_v2.typedV2PackedReadFlagRecords;
const typedV2PackedReplaceLowRecords = typed_v2.typedV2PackedReplaceLowRecords;
const typedV2SliceSumRecords = typed_v2.typedV2SliceSumRecords;
const typedV2ConditionalSliceSumRecords = typed_v2.typedV2ConditionalSliceSumRecords;
const typedV2AccumulatorLoopRecords = typed_v2.typedV2AccumulatorLoopRecords;
const typedV2ConditionalSlotUpdateRecords = typed_v2.typedV2ConditionalSlotUpdateRecords;
const typedV2DenseIntegerSwitchResults = typed_v2.typedV2DenseIntegerSwitchResults;
const typedV2ErrorSwitchRecords = typed_v2.typedV2ErrorSwitchRecords;
const typedV2ErrorClassifierRecords = typed_v2.typedV2ErrorClassifierRecords;
const typedV2RuntimeOptionalPointerMainRecords = typed_v2.typedV2RuntimeOptionalPointerMainRecords;
const typedV2RuntimePointerLoadStoreMainRecords = typed_v2.typedV2RuntimePointerLoadStoreMainRecords;
const typedV2MixCAddMayPanicRecords = typed_v2.typedV2MixCAddMayPanicRecords;
const typedV2CheckedIntFromFloatRecords = typed_v2.typedV2CheckedIntFromFloatRecords;
const lowerTypedV2ArraySum = legacy.lowerTypedV2ArraySum;
const lowerTypedV2AggregatePairAbi = legacy.lowerTypedV2AggregatePairAbi;
const lowerTypedV2SmallIntegerAggregateAbi = typed_v2.lowerTypedV2SmallIntegerAggregateAbi;
const lowerTypedV2SretIntegerAggregateAbi = typed_v2.lowerTypedV2SretIntegerAggregateAbi;
const lowerTypedV2ErrorUnionPayload = typed_v2.lowerTypedV2ErrorUnionPayload;
const lowerTypedV2MaybeError = typed_v2.lowerTypedV2MaybeError;
const lowerTypedV2OptionalPayload = typed_v2.lowerTypedV2OptionalPayload;
const lowerTypedV2OptionalPointer = typed_v2.lowerTypedV2OptionalPointer;
const lowerTypedV2PackedBits = typed_v2.lowerTypedV2PackedBits;
const lowerTypedV2ConditionalSliceSum = typed_v2.lowerTypedV2ConditionalSliceSum;
const lowerTypedV2SliceSum = typed_v2.lowerTypedV2SliceSum;
const lowerTypedV2InlineAsmBarrier = typed_v2.lowerTypedV2InlineAsmBarrier;
const lowerTypedV2AtomicAdd = typed_v2.lowerTypedV2AtomicAdd;
const lowerTypedV2AccumulatorLoop = typed_v2.lowerTypedV2AccumulatorLoop;
const lowerTypedV2ConditionalSlotUpdate = typed_v2.lowerTypedV2ConditionalSlotUpdate;
const lowerTypedV2DenseIntegerSwitch = typed_v2.lowerTypedV2DenseIntegerSwitch;
const lowerTypedV2ErrorSwitch = typed_v2.lowerTypedV2ErrorSwitch;
const lowerTypedV2ErrorClassifier = typed_v2.lowerTypedV2ErrorClassifier;
const lowerTypedV2RuntimeOptionalPointerMain = typed_v2.lowerTypedV2RuntimeOptionalPointerMain;
const lowerTypedV2RuntimePointerLoadStoreMain = typed_v2.lowerTypedV2RuntimePointerLoadStoreMain;
const lowerTypedV2MixCAddMayPanic = typed_v2.lowerTypedV2MixCAddMayPanic;
const lowerTypedV2CheckedIntFromFloat = typed_v2.lowerTypedV2CheckedIntFromFloat;

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
    var shape_recognizer_functions: usize = 0;
    const root_stem = std.fs.path.stem(air_module.root_source);
    const matched_root_functions = rootFunctionCount(air_module.functions, root_stem);
    for (air_module.functions) |air_function| {
        if (matched_root_functions != 0 and !isRootSourceFunction(root_stem, air_function.name)) continue;
        if (firstUnsupported(allocator, air_function)) |diagnostic| {
            try unsupported.append(allocator, diagnostic);
            continue;
        }
        var lowered_from_typed_v2 = true;
        var typed_v2_fallback: ?TypedV2Fallback = null;
        var function = function: {
            break :function lowerFunctionTypedV2(allocator, &module, air_function, &typed_v2_fallback) catch |typed_err| switch (typed_err) {
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
            if (typedResultCoverage(air_function, structured_air_v2)) typed_air_type_functions += 1;
            if (typedOperandCoverage(structured_air_v2)) typed_air_operand_functions += 1;
        }
        if (!lowered_from_typed_v2) legacy_air_text_lowering_functions += 1;
        switch (loweringPath(air_function)) {
            .generic_instruction_path => generic_lowering_functions += 1,
            .shape_recognizer => shape_recognizer_functions += 1,
        }
    }

    try addMissingCallDeclarations(allocator, &module);
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

fn typedResultCoverage(function: air_export.Function, structured_air_v2: air_export.StructuredAirV2) bool {
    if (structured_air_v2.instructions.len != function.instruction_count) return false;
    for (structured_air_v2.instructions) |instruction| {
        if (std.mem.eql(u8, instruction.result_type, "-")) return false;
    }
    return true;
}

fn typedOperandCoverage(structured_air_v2: air_export.StructuredAirV2) bool {
    for (structured_air_v2.instructions) |instruction| {
        for (instruction.operands) |operand| {
            if (std.mem.eql(u8, operand.type_text, "-")) return false;
        }
    }
    return true;
}

fn materializedGlobalInitializer(ty: ir.Type, initializer_text: ?[]const u8) ir.GlobalInitializer {
    if (initializer_text) |text| {
        const trimmed = std.mem.trim(u8, text, " \t");
        if (!std.mem.eql(u8, trimmed, "-")) {
            const parsed = sib.parseGlobalInitializer(ty, trimmed);
            if (parsed != .@"opaque") return parsed;
        }
    }
    return switch (ty) {
        .int => .{ .scalar = .{ .int = 0 } },
        .ptr => .{ .scalar = .null_value },
        .float, .double, .x86_fp80, .fp128 => .{ .scalar = .{ .fp = "0.0" } },
        .void, .metadata, .aggregate, .vector => .none,
    };
}

fn cStringLiteralByteLen(body: []const u8) ?usize {
    var index: usize = 0;
    var len: usize = 0;
    while (index < body.len) {
        if (body[index] != '\\') {
            len += 1;
            index += 1;
            continue;
        }
        index += 1;
        if (index >= body.len) return null;
        switch (body[index]) {
            '\\', '"' => {
                len += 1;
                index += 1;
            },
            'n', 'r', 't', '0' => {
                len += 1;
                index += 1;
            },
            'x' => {
                if (index + 2 >= body.len) return null;
                _ = std.fmt.parseInt(u8, body[index + 1 .. index + 3], 16) catch return null;
                len += 1;
                index += 3;
            },
            else => return null,
        }
    }
    return len;
}

pub fn isRootSourceFunction(root_stem: []const u8, function_name: []const u8) bool {
    return std.mem.eql(u8, function_name, root_stem) or
        (std.mem.startsWith(u8, function_name, root_stem) and
            function_name.len > root_stem.len and function_name[root_stem.len] == '.');
}

fn rootFunctionCount(functions: []const air_export.Function, root_stem: []const u8) usize {
    var count: usize = 0;
    for (functions) |function| {
        if (isRootSourceFunction(root_stem, function.name)) count += 1;
    }
    return count;
}

fn addMissingCallDeclarations(allocator: std.mem.Allocator, module: *ir.Module) !void {
    for (module.functions.items) |function| {
        for (function.blocks.items) |block| {
            for (block.instructions.items) |instruction| {
                const call = switch (instruction.kind) {
                    .call => |call| call,
                    else => continue,
                };
                if (call.callee_value != null or call.inline_asm != null) continue;
                if (moduleHasFunctionOrDeclaration(module.*, call.callee)) continue;
                var decl = ir.FunctionDecl.init(call.callee, call.ret_ty);
                errdefer decl.deinit(allocator);
                decl.calling_conv = call.calling_conv;
                for (call.args.items) |arg| {
                    try decl.params.append(allocator, .{
                        .ty = arg.ty,
                        .attrs = arg.attrs,
                    });
                }
                try module.declarations.append(allocator, decl);
            }
        }
    }
}

fn moduleHasFunctionOrDeclaration(module: ir.Module, name: []const u8) bool {
    for (module.functions.items) |function| {
        if (std.mem.eql(u8, function.name, name)) return true;
    }
    for (module.declarations.items) |decl| {
        if (std.mem.eql(u8, decl.name, name)) return true;
    }
    return false;
}

pub fn firstUnsupported(
    allocator: std.mem.Allocator,
    function: air_export.Function,
) ?Diagnostic {
    const typed_view = air_model.TypedFunctionView.init(function);
    const function_type = parseFunctionType(allocator, function.type_text) catch {
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
            typedV2RegisterAggregateRecords(function_type, structured_air_v2)
        else
            false;
    const typed_sret_integer_aggregate =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2SretIntegerAggregateRecords(function_type, structured_air_v2) or
                typedV2SretIntegerAggregateCopyRecords(function_type, structured_air_v2)
        else
            false;
    const typed_error_union_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2ErrorUnionPayloadRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_maybe_error =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2MaybeErrorRecords(function, function_type, structured_air_v2)
        else
            false;
    const typed_optional_payload =
        if (function.structured_air_v2) |structured_air_v2|
            typedV2OptionalPayloadRecords(function_type, structured_air_v2)
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

    if (typed_accumulator_loop or
        accumulatorLoopShape(function) != null or
        typed_error_classifier or
        errorClassifyShape(function) or
        typed_integer_switch or
        isIntegerSwitchBlock(function) or
        typed_conditional_slot_update or
        conditionalSlotUpdateShape(function) or
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
        typed_maybe_error)
    {
        return null;
    }

    for (function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode) or isStraightLineOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            if (isSimpleSelectBlock(function, instruction.index)) continue;
            if (typed_view != null and typed_view.?.voidGuardBlockByIndex(instruction.index)) continue;
            if (typed_view != null and typed_view.?.genericCfgBlock(instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        if (std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
        {
            if (belongsToSimpleSelectBlock(function, instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsVoidGuardBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.containsGenericCfgBlockInstruction(instruction.index)) continue;
            if (typed_view != null and typed_view.?.terminalErrorUnionCondBr(instruction.index)) continue;
            return .{ .function = function.name, .opcode = instruction.opcode, .reason = .control_flow_shape };
        }
        return .{ .function = function.name, .opcode = instruction.opcode, .reason = .opcode };
    }
    return null;
}

const LoweringPath = enum {
    generic_instruction_path,
    shape_recognizer,
};

fn firstTypedV2Fallback(function: air_export.Function) TypedV2Fallback {
    if (shapeRecognizerName(function)) |name| {
        return .{
            .function = function.name,
            .opcode = name,
            .data_kind = "-",
            .reason = "shape_recognizer",
        };
    }
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

fn shapeRecognizerName(function: air_export.Function) ?[]const u8 {
    _ = function;
    return null;
}

fn loweringPath(function: air_export.Function) LoweringPath {
    if (shapeRecognizerName(function) != null) return .shape_recognizer;
    return .generic_instruction_path;
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

    const function_type = try parseFunctionType(allocator, air_function.type_text);
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
    };

    for (air_function.instructions) |instruction| {
        if (isIgnoredOpcode(instruction.opcode)) continue;
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            try context.lowerArg(instruction);
        } else if (isArithmeticOpcode(instruction.opcode)) {
            try context.lowerBinary(instruction);
        } else if (std.mem.startsWith(u8, instruction.opcode, "cmp_")) {
            try context.lowerCompare(instruction);
        } else if (isCastOpcode(instruction.opcode)) {
            try context.lowerCast(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            try context.lowerAlloca(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            try context.lowerLoad(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "store") or
            std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            try context.lowerStore(instruction);
        } else if (isCallOpcode(instruction.opcode)) {
            try context.lowerCall(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) {
            try context.lowerRuntimeNavPtr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "atomic_rmw")) {
            try context.lowerAtomicRmw(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "array_elem_val")) {
            try context.lowerArrayElemVal(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "assembly")) {
            try context.lowerAssembly(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            try context.lowerReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unreach")) {
            block.terminator = .{ .@"unreachable" = {} };
        } else if (std.mem.eql(u8, instruction.opcode, "block") or
            std.mem.eql(u8, instruction.opcode, "cond_br") or
            std.mem.eql(u8, instruction.opcode, "br"))
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
    air_function: air_export.Function,
    typed_v2_fallback: ?*?TypedV2Fallback,
) LowerError!ir.Function {
    if (loweringPath(air_function) == .shape_recognizer) return error.UnsupportedAir;
    const structured_air = air_function.structured_air orelse return error.UnsupportedAir;
    const structured_air_v2 = air_function.structured_air_v2 orelse return error.UnsupportedAir;
    const main_body = structured_air.body(.main, null) orelse return error.UnsupportedAir;

    const function_type = try parseFunctionType(allocator, air_function.type_text);
    defer function_type.deinit(allocator);
    if (try lowerTypedV2ArraySum(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2AggregatePairAbi(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SmallIntegerAggregateAbi(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2SretIntegerAggregateAbi(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ErrorUnionPayload(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2MaybeError(allocator, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2OptionalPayload(allocator, air_function, function_type, structured_air_v2)) |function| {
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
    if (try lowerTypedV2AccumulatorLoop(allocator, module, air_function, function_type, structured_air_v2)) |function| {
        return function;
    }
    if (try lowerTypedV2ConditionalSlotUpdate(allocator, air_function, function_type, structured_air_v2)) |function| {
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
    };

    for (main_body.instructions) |instruction_index| {
        const instruction = typed_view.instruction(instruction_index) orelse return error.UnsupportedAir;
        try context.lowerTypedInstruction(instruction);
    }
    if (block.terminator == null) return error.UnsupportedAir;
    try function.blocks.append(allocator, block);
    return function;
}

fn tailKindForCallOpcode(opcode: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, opcode, "call_always_tail")) return "tail";
    if (std.mem.eql(u8, opcode, "call_never_tail")) return "notail";
    if (std.mem.eql(u8, opcode, "call_never_inline")) return "neverinline";
    return null;
}

fn isErrorUnionTypeText(text: []const u8) bool {
    const trimmed = std.mem.trim(u8, text, " ");
    return std.mem.startsWith(u8, trimmed, "error{") and std.mem.indexOf(u8, trimmed, "}!") != null;
}

fn errorUnionPayloadType(text: []const u8) ?ZigType {
    const trimmed = std.mem.trim(u8, text, " ");
    const marker = std.mem.indexOf(u8, trimmed, "}!") orelse return null;
    return parseZigType(trimmed[marker + 2 ..]);
}

const LoweringContext = struct {
    allocator: std.mem.Allocator,
    module: *ir.Module,
    air_function: air_export.Function,
    function_type: FunctionType,
    function: *ir.Function,
    block: *ir.BasicBlock,
    values: []?TypedValue,
    structured_air: ?air_export.StructuredAir,
    structured_air_v2: ?air_export.StructuredAirV2,
    typed_view: ?air_model.TypedFunctionView = null,
    typed_v2_fallback: ?*?TypedV2Fallback = null,
    next_arg_index: usize = 0,

    fn lowerTypedInstruction(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        self.lowerTypedInstructionImpl(instruction) catch |err| switch (err) {
            error.UnsupportedAir => {
                self.recordTypedV2Fallback(instruction);
                return err;
            },
            else => return err,
        };
    }

    fn lowerTypedInstructionImpl(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        const capability = self.typedInstructionCapability(instruction);
        if (capability.status == .ignored_metadata) return;
        if (!air_capabilities.typedV2CanLower(capability)) return error.UnsupportedAir;
        switch (capability.lowerer) {
            .typed_v2_cfg => try self.lowerTypedCfgInstruction(instruction),
            .typed_v2_semantic => try self.lowerTypedSemanticInstruction(instruction),
            .call_abi => try self.lowerTypedCall(instruction),
            .backend_runtime => try self.lowerTypedBackendRuntimeInstruction(instruction),
            .none, .ignore, .boundary => return error.UnsupportedAir,
        }
    }

    fn lowerTypedCfgInstruction(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (std.mem.eql(u8, instruction.opcode, "block")) {
            try self.lowerTypedBlock(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
            const view = self.typed_view orelse return error.UnsupportedAir;
            if (!view.terminalErrorUnionCondBr(instruction.index)) return error.UnsupportedAir;
            try self.lowerTypedCondBrReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ret") or
            std.mem.eql(u8, instruction.opcode, "ret_safe"))
        {
            try self.lowerTypedReturn(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unreach")) {
            self.block.terminator = .{ .@"unreachable" = {} };
        } else {
            return error.UnsupportedAir;
        }
    }

    fn lowerTypedSemanticInstruction(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        const lowered = switch (air_capabilities.semanticDomainForOpcode(instruction.opcode)) {
            .scalar => try self.lowerTypedScalarSemanticInstruction(instruction),
            .memory => try self.lowerTypedMemorySemanticInstruction(instruction),
            .optional => try self.lowerTypedOptionalSemanticInstruction(instruction),
            .error_union => try self.lowerTypedErrorUnionSemanticInstruction(instruction),
            .pointer_aggregate => try self.lowerTypedPointerAggregateSemanticInstruction(instruction),
            .none => false,
        };
        if (!lowered) return error.UnsupportedAir;
    }

    fn lowerTypedScalarSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
    ) !bool {
        if (std.mem.eql(u8, instruction.opcode, "arg")) {
            try self.lowerTypedArg(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "add_with_overflow")) {
            try self.lowerTypedAddWithOverflow(instruction);
        } else if (isArithmeticOpcode(instruction.opcode)) {
            try self.lowerTypedBinary(instruction);
        } else if (std.mem.startsWith(u8, instruction.opcode, "cmp_")) {
            try self.lowerTypedCompare(instruction);
        } else if (isCastOpcode(instruction.opcode)) {
            try self.lowerTypedCast(instruction);
        } else {
            return false;
        }
        return true;
    }

    fn lowerTypedMemorySemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
    ) !bool {
        if (std.mem.eql(u8, instruction.opcode, "alloc")) {
            try self.lowerTypedAlloca(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "load")) {
            try self.lowerTypedLoad(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "store") or
            std.mem.eql(u8, instruction.opcode, "store_safe"))
        {
            try self.lowerTypedStore(instruction);
        } else {
            return false;
        }
        return true;
    }

    fn lowerTypedOptionalSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
    ) !bool {
        switch (air_capabilities.optionalSemanticOpForOpcode(instruction.opcode)) {
            .is_non_null => try self.lowerTypedIsNonNull(instruction),
            .wrap_optional => try self.lowerTypedWrapOptional(instruction),
            .optional_payload => try self.lowerTypedOptionalPayload(instruction),
            .none => return false,
        }
        return true;
    }

    fn lowerTypedErrorUnionSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
    ) !bool {
        if (std.mem.eql(u8, instruction.opcode, "is_non_err")) {
            try self.lowerTypedIsNonErr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "wrap_errunion_payload")) {
            try self.lowerTypedWrapErrorUnionPayload(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "wrap_errunion_err")) {
            try self.lowerTypedWrapErrorUnionErr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unwrap_errunion_payload")) {
            try self.lowerTypedUnwrapErrorUnionPayload(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "unwrap_errunion_err")) {
            try self.lowerTypedUnwrapErrorUnionErr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "try")) {
            try self.lowerTypedTry(instruction);
        } else {
            return false;
        }
        return true;
    }

    fn lowerTypedPointerAggregateSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
    ) !bool {
        if (std.mem.eql(u8, instruction.opcode, "slice")) {
            try self.lowerTypedSlice(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_add")) {
            try self.lowerTypedPtrGep(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "ptr_elem_ptr")) {
            try self.lowerTypedPtrGep(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "runtime_nav_ptr")) {
            try self.lowerTypedRuntimeNavPtr(instruction);
        } else if (std.mem.eql(u8, instruction.opcode, "array_elem_val")) {
            try self.lowerTypedArrayElemVal(instruction);
        } else if (isFieldPtrOpcode(instruction.opcode)) {
            try self.lowerTypedFieldPtr(instruction);
        } else {
            return false;
        }
        return true;
    }

    fn lowerTypedBackendRuntimeInstruction(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        _ = self;
        _ = instruction;
        return error.UnsupportedAir;
    }

    fn recordTypedV2Fallback(self: *LoweringContext, instruction: air_export.TypedInstruction) void {
        const slot = self.typed_v2_fallback orelse return;
        if (slot.* != null) return;
        const capability = self.typedInstructionCapability(instruction);
        slot.* = .{
            .function = self.air_function.name,
            .opcode = instruction.opcode,
            .data_kind = instruction.data_kind,
            .reason = if (air_capabilities.typedV2CanLower(capability))
                "lowering_validation"
            else
                air_capabilities.typedV2FallbackReason(capability),
        };
    }

    fn typedInstructionCapability(
        self: LoweringContext,
        instruction: air_export.TypedInstruction,
    ) air_capabilities.OpcodeCapability {
        if (self.typed_view) |view| return view.capability(instruction);
        return air_capabilities.opcodeCapability(instruction.opcode);
    }

    fn lowerTypedArg(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const param_index = self.next_arg_index;
        self.next_arg_index += 1;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const parsed_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) return error.UnsupportedAir;
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    fn lowerTypedBinary(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const lhs = try self.resolveTypedOperand(instruction, 0);
        var rhs = try self.resolveTypedOperand(instruction, 1);
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
            if (!isShiftOpcode(instruction.opcode)) return error.UnsupportedAir;
            rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
        }
        const op = binaryOp(instruction.opcode, lhs.ty) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = op,
                .ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = lhs.ty,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedAddWithOverflow(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const lhs = try self.resolveTypedOperand(instruction, 0);
        const rhs = try self.resolveTypedOperand(instruction, 1);
        if (!lhs.ty.ir_type.eql(.{ .int = 32 }) or !rhs.ty.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!result_type.ir_type.eql(.{ .aggregate = "{ i32, i1 }" })) return error.UnsupportedAir;

        const result_name = try self.resultName(instruction.index);
        var call: ir.CallInst = .{
            .ret_ty = result_type.ir_type,
            .callee = if (lhs.ty.signed) "llvm.sadd.with.overflow.i32" else "llvm.uadd.with.overflow.i32",
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try call.args.append(self.allocator, .{ .ty = lhs.ty.ir_type, .value = lhs.value });
        try call.args.append(self.allocator, .{ .ty = rhs.ty.ir_type, .value = rhs.value });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCompare(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const lhs = try self.resolveTypedOperand(instruction, 0);
        const rhs = try self.resolveTypedOperand(instruction, 1);
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        if (isFpType(lhs.ty.ir_type)) {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .fcmp = .{
                    .predicate = fpPredicate(instruction.opcode) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        } else {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .icmp = .{
                    .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        }
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCast(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const source = try self.resolveTypedOperand(instruction, 0);
        const target_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (std.mem.eql(u8, instruction.opcode, "bitcast") and
            source.ty.ir_type == .ptr and target_type.ir_type == .ptr)
        {
            self.values[instruction.index] = .{
                .ty = target_type,
                .value = source.value,
            };
            return;
        }
        const op = castOp(instruction.opcode, source.ty, target_type) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = source.ty.ir_type,
                .value = source.value,
                .to_ty = target_type.ir_type,
            } },
        });
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedAlloca(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const pointer_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        const allocated_type = pointer_type.pointer_child orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
        });
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedLoad(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse blk: {
            const typed_child = pointerLoadResultType(instruction.operands[0].type_text);
            if (typed_child) |child| break :blk child;
            const child = pointer.ty.pointer_child orelse return error.UnsupportedAir;
            break :blk ZigType{ .ir_type = child };
        };
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{
                .ty = result_type.ir_type,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedStore(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        const value = try self.resolveTypedOperand(instruction, 1);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = value.ty.ir_type,
                .value = value.value,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
    }

    fn lowerTypedBlock(self: *LoweringContext, instruction: air_export.TypedInstruction) LowerError!void {
        const view = self.typed_view orelse return error.UnsupportedAir;
        const block_body = view.body(.block, instruction.index) orelse return error.UnsupportedAir;
        const cond_instruction = try self.lowerTypedBlockBodyUntilCond(block_body);
        if (!std.mem.eql(u8, cond_instruction.opcode, "cond_br") or cond_instruction.operands.len != 1) {
            return error.UnsupportedAir;
        }
        const cond = try self.resolveTypedOperand(cond_instruction, 0);
        if (!cond.ty.ir_type.eql(.{ .int = 1 })) return error.UnsupportedAir;

        const then_body = view.body(.then_body, cond_instruction.index) orelse return error.UnsupportedAir;
        const else_body = view.body(.else_body, cond_instruction.index) orelse return error.UnsupportedAir;
        if (view.voidGuardBlock(instruction.index, then_body, else_body)) {
            const panic_body = if (view.noreturnBody(then_body)) then_body else else_body;
            const panic_is_then = view.noreturnBody(then_body);
            try self.lowerTypedVoidGuard(instruction, cond, panic_body, panic_is_then);
            return;
        }
        if (view.bodyHasReturn(then_body) and view.bodyHasReturn(else_body)) {
            try self.lowerTypedCondBodiesReturn(cond, cond_instruction.index, then_body, else_body);
            return;
        }
        if (try self.lowerTypedBranchReturnContinueBlock(instruction, cond, then_body, else_body)) {
            return;
        }
        if (self.typedBlockBranchValue(instruction.index, then_body)) |true_value| {
            if (self.typedBlockBranchValue(instruction.index, else_body)) |false_value| {
                if (true_value.ty.ir_type.eql(false_value.ty.ir_type)) {
                    const result_name = try self.resultName(instruction.index);
                    try self.block.instructions.append(self.allocator, .{
                        .result = result_name,
                        .kind = .{ .select = .{
                            .cond_ty = cond.ty.ir_type,
                            .cond = cond.value,
                            .ty = true_value.ty.ir_type,
                            .true_value = true_value.value,
                            .false_value = false_value.value,
                        } },
                    });
                    self.values[instruction.index] = .{
                        .ty = true_value.ty,
                        .value = .{ .named = result_name },
                    };
                    return;
                }
            } else |_| {}
        } else |_| {}

        try self.lowerTypedBranchMergeBlock(instruction, cond, then_body, else_body);
    }

    fn lowerTypedCondBrReturn(self: *LoweringContext, instruction: air_export.TypedInstruction) LowerError!void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const view = self.typed_view orelse return error.UnsupportedAir;
        const cond = try self.resolveTypedOperand(instruction, 0);
        if (!cond.ty.ir_type.eql(.{ .int = 1 })) return error.UnsupportedAir;
        const then_body = view.body(.then_body, instruction.index) orelse return error.UnsupportedAir;
        const else_body = view.body(.else_body, instruction.index) orelse return error.UnsupportedAir;
        if (!view.bodyHasReturn(then_body) or !view.bodyHasReturn(else_body)) {
            return error.UnsupportedAir;
        }

        try self.lowerTypedCondBodiesReturn(cond, instruction.index, then_body, else_body);
    }

    fn lowerTypedCondBodiesReturn(
        self: *LoweringContext,
        cond: TypedValue,
        instruction_index: u32,
        then_body: air_export.StructuredBody,
        else_body: air_export.StructuredBody,
    ) LowerError!void {
        const then_label = try ownPrint(self.module, "cond{}_then", .{instruction_index});
        const else_label = try ownPrint(self.module, "cond{}_else", .{instruction_index});
        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = then_label,
            .else_target = else_label,
        } };
        self.block.* = ir.BasicBlock.init(then_label);
        try self.function.blocks.append(self.allocator, finished);

        try self.lowerTypedBodyToTerminalBlock(then_label, then_body);
        try self.lowerTypedBodyToTerminalBlock(else_label, else_body);

        self.block.* = ir.BasicBlock.init(try ownPrint(self.module, "cond{}_after_unreachable", .{instruction_index}));
        self.block.terminator = .{ .@"unreachable" = {} };
    }

    fn lowerTypedBodyToTerminalBlock(
        self: *LoweringContext,
        label: []const u8,
        body: air_export.StructuredBody,
    ) LowerError!void {
        const view = self.typed_view orelse return error.UnsupportedAir;
        self.block.* = ir.BasicBlock.init(label);
        for (body.instructions) |instruction_index| {
            const child = view.instruction(instruction_index) orelse return error.UnsupportedAir;
            if (view.capability(child).status == .ignored_metadata) continue;
            if (self.block.terminator != null) return error.UnsupportedAir;
            try self.lowerTypedInstruction(child);
        }
        if (self.block.terminator == null) return error.UnsupportedAir;
        const terminal = self.block.*;
        try self.function.blocks.append(self.allocator, terminal);
    }

    fn lowerTypedBranchReturnContinueBlock(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        cond: TypedValue,
        then_body: air_export.StructuredBody,
        else_body: air_export.StructuredBody,
    ) LowerError!bool {
        const view = self.typed_view orelse return error.UnsupportedAir;
        const then_returns = view.bodyHasReturn(then_body);
        const else_returns = view.bodyHasReturn(else_body);
        if (then_returns == else_returns) return false;

        const continue_body = if (then_returns) else_body else then_body;
        if (!view.voidBranchBody(continue_body, instruction.index)) return false;

        const return_body = if (then_returns) then_body else else_body;
        const return_label = try ownPrint(self.module, "block{}_return", .{instruction.index});
        const cont_label = try ownPrint(self.module, "block{}_cont", .{instruction.index});

        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = if (then_returns) return_label else cont_label,
            .else_target = if (then_returns) cont_label else return_label,
        } };
        self.block.* = ir.BasicBlock.init(return_label);
        try self.function.blocks.append(self.allocator, finished);

        for (return_body.instructions) |return_index| {
            const child = view.instruction(return_index) orelse return error.UnsupportedAir;
            if (view.capability(child).status == .ignored_metadata) continue;
            try self.lowerTypedInstruction(child);
            if (self.block.terminator != null and !std.mem.eql(u8, child.opcode, "ret") and !std.mem.eql(u8, child.opcode, "ret_safe")) {
                return error.UnsupportedAir;
            }
        }
        if (self.block.terminator == null) return error.UnsupportedAir;
        const return_block = self.block.*;
        self.block.* = ir.BasicBlock.init(cont_label);
        try self.function.blocks.append(self.allocator, return_block);
        return true;
    }

    // Lowers a ReleaseSafe void guard block into real control flow: the
    // current block ends with the guard branch, the cold noreturn panic call
    // gets its own block, and lowering continues in a fresh continuation
    // block. The guard is preserved, never elided.
    fn lowerTypedVoidGuard(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        cond: TypedValue,
        panic_body: air_export.StructuredBody,
        panic_is_then: bool,
    ) LowerError!void {
        const view = self.typed_view orelse return error.UnsupportedAir;
        const panic_label = try ownPrint(self.module, "guard{}_panic", .{instruction.index});
        const cont_label = try ownPrint(self.module, "guard{}_cont", .{instruction.index});

        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = if (panic_is_then) panic_label else cont_label,
            .else_target = if (panic_is_then) cont_label else panic_label,
        } };
        self.block.* = ir.BasicBlock.init(panic_label);
        try self.function.blocks.append(self.allocator, finished);

        for (panic_body.instructions) |panic_index| {
            const child = view.instruction(panic_index) orelse return error.UnsupportedAir;
            if (view.capability(child).status == .ignored_metadata) continue;
            if (std.mem.eql(u8, child.opcode, "unreach")) continue;
            try self.lowerTypedInstruction(child);
        }
        var panic_block = self.block.*;
        panic_block.terminator = .{ .@"unreachable" = {} };
        self.block.* = ir.BasicBlock.init(cont_label);
        try self.function.blocks.append(self.allocator, panic_block);
    }

    fn typedBlockBranchValue(
        self: *LoweringContext,
        target_block: u32,
        body: air_export.StructuredBody,
    ) LowerError!TypedValue {
        const view = self.typed_view orelse return error.UnsupportedAir;
        const branch_index = view.singleSemanticInstruction(body) orelse return error.UnsupportedAir;
        const branch_instruction = view.instruction(branch_index) orelse return error.UnsupportedAir;
        if (!std.mem.eql(u8, branch_instruction.opcode, "br") or branch_instruction.operands.len != 2) {
            return error.UnsupportedAir;
        }
        const target_operand = branch_instruction.operands[0];
        const target = typedBlockTarget(target_operand) orelse return error.UnsupportedAir;
        if (target != target_block) return error.UnsupportedAir;
        return self.resolveTypedOperand(branch_instruction, 1);
    }

    fn lowerTypedBranchMergeBlock(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        cond: TypedValue,
        then_body: air_export.StructuredBody,
        else_body: air_export.StructuredBody,
    ) LowerError!void {
        const then_label = try ownPrint(self.module, "block{}_then", .{instruction.index});
        const else_label = try ownPrint(self.module, "block{}_else", .{instruction.index});
        const merge_label = try ownPrint(self.module, "block{}_merge", .{instruction.index});
        const merge_type_or_null: ?ZigType = if (parseZigType(instruction.result_type)) |merge_type|
            if (merge_type.ir_type == .void) null else merge_type
        else blk: {
            const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse break :blk null;
            if (isErrorUnionTypeText(return_type_text) and self.function_type.return_type.ir_type.eql(.{ .int = 64 })) {
                break :blk self.function_type.return_type;
            }
            break :blk null;
        };

        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = cond.value,
            .then_target = then_label,
            .else_target = else_label,
        } };
        self.block.* = ir.BasicBlock.init(then_label);
        try self.function.blocks.append(self.allocator, finished);

        const true_result = try self.lowerTypedBranchBodyToMerge(instruction.index, then_body, then_label, merge_label, merge_type_or_null);
        const false_result = try self.lowerTypedBranchBodyToMerge(instruction.index, else_body, else_label, merge_label, merge_type_or_null);

        self.block.* = ir.BasicBlock.init(merge_label);
        if (true_result.value) |true_branch| {
            const false_branch = false_result.value orelse return error.UnsupportedAir;
            if (!true_branch.ty.ir_type.eql(false_branch.ty.ir_type)) return error.UnsupportedAir;
            const result_name = try self.resultName(instruction.index);
            var phi: ir.PhiInst = .{ .ty = true_branch.ty.ir_type, .incoming = .empty };
            errdefer phi.deinit(self.allocator);
            try phi.incoming.append(self.allocator, .{ .value = true_branch.value, .block = true_result.predecessor_label });
            try phi.incoming.append(self.allocator, .{ .value = false_branch.value, .block = false_result.predecessor_label });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .phi = phi },
            });
            self.values[instruction.index] = .{
                .ty = true_branch.ty,
                .value = .{ .named = result_name },
            };
        } else if (false_result.value != null) {
            return error.UnsupportedAir;
        }
    }

    fn lowerTypedBranchBodyToMerge(
        self: *LoweringContext,
        target_block: u32,
        body: air_export.StructuredBody,
        label: []const u8,
        merge_label: []const u8,
        merge_type: ?ZigType,
    ) LowerError!TypedBranchMergeResult {
        const view = self.typed_view orelse return error.UnsupportedAir;
        self.block.* = ir.BasicBlock.init(label);
        var branch_value: ?TypedValue = null;
        var saw_branch = false;
        for (body.instructions) |instruction_index| {
            const child = view.instruction(instruction_index) orelse return error.UnsupportedAir;
            if (view.capability(child).status == .ignored_metadata) continue;
            if (std.mem.eql(u8, child.opcode, "br")) {
                if (child.operands.len != 2) return error.UnsupportedAir;
                const target = typedBlockTarget(child.operands[0]) orelse return error.UnsupportedAir;
                if (target != target_block) return error.UnsupportedAir;
                branch_value = try self.resolveTypedBranchOperand(child, 1);
                saw_branch = true;
                continue;
            }
            if (saw_branch) return error.UnsupportedAir;
            try self.lowerTypedInstruction(child);
        }
        if (!saw_branch) return error.UnsupportedAir;
        if (branch_value) |value| {
            if (merge_type) |target_type| {
                branch_value = try self.coerceTypedBranchValueToMerge(target_block, label, value, target_type);
            }
        }
        var branch_block = self.block.*;
        branch_block.terminator = .{ .br = .{ .target = merge_label } };
        const predecessor_label = branch_block.name;
        self.block.* = ir.BasicBlock.init(merge_label);
        try self.function.blocks.append(self.allocator, branch_block);
        return .{
            .value = branch_value,
            .predecessor_label = predecessor_label,
        };
    }

    fn coerceTypedBranchValueToMerge(
        self: *LoweringContext,
        target_block: u32,
        label: []const u8,
        value: TypedValue,
        target_type: ZigType,
    ) LowerError!TypedValue {
        if (value.ty.ir_type.eql(target_type.ir_type)) return value;
        if (!target_type.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse return error.UnsupportedAir;
        if (!isErrorUnionTypeText(return_type_text)) return error.UnsupportedAir;
        const payload_type = errorUnionPayloadType(return_type_text) orelse return error.UnsupportedAir;
        const prefix = try ownPrint(self.module, "air{}_{s}", .{ target_block, label });
        if (value.ty.ir_type.eql(payload_type.ir_type)) {
            const wrapped_name = try self.encodeErrorUnionPayloadWithPrefix(prefix, value.value);
            return .{ .ty = target_type, .value = .{ .named = wrapped_name } };
        }
        if (value.ty.ir_type.eql(.{ .int = 16 })) {
            try self.block.instructions.append(self.allocator, .{
                .result = prefix,
                .kind = .{ .cast = .{
                    .op = .zext,
                    .from_ty = .{ .int = 16 },
                    .value = value.value,
                    .to_ty = .{ .int = 64 },
                } },
            });
            return .{ .ty = target_type, .value = .{ .named = prefix } };
        }
        return error.UnsupportedAir;
    }

    fn resolveTypedBranchOperand(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
    ) LowerError!?TypedValue {
        if (operand_index >= instruction.operands.len) return error.UnsupportedAir;
        const operand = instruction.operands[operand_index];
        if (std.mem.eql(u8, operand.kind, "const") and
            std.mem.eql(u8, operand.type_text, "void") and
            std.mem.eql(u8, typedOperandTextDetail(instruction, operand_index) orelse return error.UnsupportedAir, "@.void_value"))
        {
            return null;
        }
        return try self.resolveTypedOperand(instruction, operand_index);
    }

    fn lowerTypedBlockBodyUntilCond(
        self: *LoweringContext,
        body: air_export.StructuredBody,
    ) LowerError!air_export.TypedInstruction {
        const view = self.typed_view orelse return error.UnsupportedAir;
        var cond_instruction: ?air_export.TypedInstruction = null;
        for (body.instructions) |instruction_index| {
            const child = view.instruction(instruction_index) orelse return error.UnsupportedAir;
            if (view.capability(child).status == .ignored_metadata) continue;
            if (std.mem.eql(u8, child.opcode, "cond_br")) {
                if (cond_instruction != null) return error.UnsupportedAir;
                cond_instruction = child;
                continue;
            }
            if (cond_instruction != null) return error.UnsupportedAir;
            try self.lowerTypedInstruction(child);
        }
        return cond_instruction orelse error.UnsupportedAir;
    }

    fn lowerTypedRuntimeNavPtr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 0) return error.UnsupportedAir;
        const pointer_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (pointer_type.ir_type != .ptr) return error.UnsupportedAir;
        const nav_fqn = typedDetail(instruction, "nav_fqn") orelse return error.UnsupportedAir;
        const symbol = try ownPrint(self.module, "@{s}", .{nav_fqn});
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = symbol },
        };
    }

    fn lowerTypedIsNonNull(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const pointer = try self.resolveTypedOperand(instruction, 0);
        if (pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .icmp = .{
                .predicate = .ne,
                .operand_ty = .ptr,
                .lhs = pointer.value,
                .rhs = .null_value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedWrapOptional(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        if (!std.mem.startsWith(u8, instruction.result_type, "?")) return error.UnsupportedAir;
        const optional_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        const payload = try self.resolveTypedOperand(instruction, 0);
        if (!payload.ty.ir_type.eql(optional_type.ir_type)) return error.UnsupportedAir;
        self.values[instruction.index] = .{
            .ty = optional_type,
            .value = payload.value,
        };
    }

    fn lowerTypedOptionalPayload(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const payload_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        const optional = try self.resolveTypedOperand(instruction, 0);
        if (!std.mem.startsWith(u8, instruction.operands[0].type_text, "?")) return error.UnsupportedAir;
        if (payload_type.ir_type == .ptr) {
            if (optional.ty.ir_type != .ptr) return error.UnsupportedAir;
        } else {
            if (!optional.ty.ir_type.eql(payload_type.ir_type)) return error.UnsupportedAir;
        }
        self.values[instruction.index] = .{
            .ty = payload_type,
            .value = optional.value,
        };
    }

    fn lowerTypedIsNonErr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const err_union = try self.resolveTypedOperand(instruction, 0);
        if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
            return error.UnsupportedAir;
        }
        const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "errbits");
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .icmp = .{
                .predicate = .eq,
                .operand_ty = .{ .int = 64 },
                .lhs = .{ .named = error_bits },
                .rhs = .{ .int = 0 },
            } },
        });
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedWrapErrorUnionPayload(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!isErrorUnionTypeText(instruction.result_type) or !result_type.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const payload = try self.resolveTypedOperand(instruction, 0);
        if (!payload.ty.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;
        const result_name = try self.encodeErrorUnionPayload(instruction.index, payload.value);
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedWrapErrorUnionErr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!isErrorUnionTypeText(instruction.result_type) or !result_type.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const err = try self.resolveTypedOperand(instruction, 0);
        if (!err.ty.ir_type.eql(.{ .int = 16 })) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = .{ .int = 16 },
                .value = err.value,
                .to_ty = .{ .int = 64 },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedUnwrapErrorUnionPayload(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const payload_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!payload_type.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;
        const err_union = try self.resolveTypedOperand(instruction, 0);
        if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
            return error.UnsupportedAir;
        }
        const result_name = try self.decodeErrorUnionPayload(instruction.index, err_union.value);
        self.values[instruction.index] = .{
            .ty = payload_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedUnwrapErrorUnionErr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const err_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!err_type.ir_type.eql(.{ .int = 16 })) return error.UnsupportedAir;
        const err_union = try self.resolveTypedOperand(instruction, 0);
        if (!isErrorUnionTypeText(instruction.operands[0].type_text) or !err_union.ty.ir_type.eql(.{ .int = 64 })) {
            return error.UnsupportedAir;
        }
        const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "errbits");
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = .{ .int = 64 },
                .value = .{ .named = error_bits },
                .to_ty = .{ .int = 16 },
            } },
        });
        self.values[instruction.index] = .{
            .ty = err_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedTry(self: *LoweringContext, instruction: air_export.TypedInstruction) LowerError!void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const err_union = try self.resolveTypedOperand(instruction, 0);
        if (!isErrorUnionTypeText(instruction.operands[0].type_text) or
            !err_union.ty.ir_type.eql(.{ .int = 64 }) or
            !self.function_type.return_type.ir_type.eql(err_union.ty.ir_type))
        {
            return error.UnsupportedAir;
        }
        const payload_type = errorUnionPayloadType(instruction.operands[0].type_text) orelse return error.UnsupportedAir;
        if (!payload_type.ir_type.eql(.{ .int = 32 })) return error.UnsupportedAir;

        const error_bits = try self.emitErrorUnionErrorBits(instruction.index, err_union.value, "try_errbits");
        const ok_name = try ownPrint(self.module, "air{}_try_ok", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = ok_name,
            .kind = .{ .icmp = .{
                .predicate = .eq,
                .operand_ty = .{ .int = 64 },
                .lhs = .{ .named = error_bits },
                .rhs = .{ .int = 0 },
            } },
        });

        const err_label = try ownPrint(self.module, "try{}_err", .{instruction.index});
        const cont_label = try ownPrint(self.module, "try{}_cont", .{instruction.index});
        var finished = self.block.*;
        finished.terminator = .{ .condbr = .{
            .cond_ty = .{ .int = 1 },
            .cond = .{ .named = ok_name },
            .then_target = cont_label,
            .else_target = err_label,
        } };
        self.block.* = ir.BasicBlock.init(err_label);
        try self.function.blocks.append(self.allocator, finished);

        var err_block = self.block.*;
        err_block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = err_union.value,
        } };
        self.block.* = ir.BasicBlock.init(cont_label);
        try self.function.blocks.append(self.allocator, err_block);

        const payload_name = try self.decodeErrorUnionPayload(instruction.index, err_union.value);
        self.values[instruction.index] = .{
            .ty = payload_type,
            .value = .{ .named = payload_name },
        };
    }

    fn emitErrorUnionErrorBits(
        self: *LoweringContext,
        instruction_index: u32,
        value: ir.Value,
        suffix: []const u8,
    ) ![]const u8 {
        const result_name = try ownPrint(self.module, "air{}_{s}", .{ instruction_index, suffix });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = .@"and",
                .ty = .{ .int = 64 },
                .lhs = value,
                .rhs = .{ .int = 0xffff },
            } },
        });
        return result_name;
    }

    fn encodeErrorUnionPayload(self: *LoweringContext, instruction_index: u32, payload: ir.Value) ![]const u8 {
        const prefix = try self.resultName(instruction_index);
        return try self.encodeErrorUnionPayloadWithPrefix(prefix, payload);
    }

    fn encodeErrorUnionPayloadWithPrefix(self: *LoweringContext, prefix: []const u8, payload: ir.Value) ![]const u8 {
        const wide_name = try ownPrint(self.module, "{s}_payload64", .{prefix});
        try self.block.instructions.append(self.allocator, .{
            .result = wide_name,
            .kind = .{ .cast = .{
                .op = .zext,
                .from_ty = .{ .int = 32 },
                .value = payload,
                .to_ty = .{ .int = 64 },
            } },
        });
        try self.block.instructions.append(self.allocator, .{
            .result = prefix,
            .kind = .{ .binary = .{
                .op = .shl,
                .ty = .{ .int = 64 },
                .lhs = .{ .named = wide_name },
                .rhs = .{ .int = 16 },
            } },
        });
        return prefix;
    }

    fn decodeErrorUnionPayload(self: *LoweringContext, instruction_index: u32, value: ir.Value) ![]const u8 {
        const shifted_name = try ownPrint(self.module, "air{}_payload_shift", .{instruction_index});
        try self.block.instructions.append(self.allocator, .{
            .result = shifted_name,
            .kind = .{ .binary = .{
                .op = .lshr,
                .ty = .{ .int = 64 },
                .lhs = value,
                .rhs = .{ .int = 16 },
            } },
        });
        const result_name = try self.resultName(instruction_index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = .trunc,
                .from_ty = .{ .int = 64 },
                .value = .{ .named = shifted_name },
                .to_ty = .{ .int = 32 },
            } },
        });
        return result_name;
    }

    fn lowerTypedSlice(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const ptr = try self.resolveTypedOperand(instruction, 0);
        const len = try self.resolveTypedOperand(instruction, 1);
        if (ptr.ty.ir_type != .ptr or !len.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!result_type.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return error.UnsupportedAir;

        const ptr_name = try ownPrint(self.module, "air{}_slice_ptr", .{instruction.index});
        try self.block.instructions.append(self.allocator, .{
            .result = ptr_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = result_type.ir_type,
                .aggregate = .undef,
                .value_ty = .ptr,
                .value = ptr.value,
                .indices = "0",
            } },
        });
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = result_type.ir_type,
                .aggregate = .{ .named = ptr_name },
                .value_ty = .{ .int = 64 },
                .value = len.value,
                .indices = "1",
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedPtrGep(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const base = try self.resolveTypedOperand(instruction, 0);
        const index = try self.resolveTypedOperand(instruction, 1);
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (base.ty.ir_type != .ptr or result_type.ir_type != .ptr) return error.UnsupportedAir;
        if (!index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        const element_type = result_type.pointer_child orelse base.ty.pointer_child orelse return error.UnsupportedAir;
        if (!isSupportedTypedGepElementType(element_type)) return error.UnsupportedAir;
        if (!genericTypedGepIndex(index.value)) return error.UnsupportedAir;

        if (typedGepIndexIsZero(index.value)) {
            self.values[instruction.index] = .{
                .ty = result_type,
                .value = base.value,
            };
            return;
        }

        const result_name = try self.resultName(instruction.index);
        var gep: ir.GepInst = .{
            .source_ty = element_type,
            .ptr = base.value,
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .gep = gep },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn typedGepIndexIsZero(value: ir.Value) bool {
        return switch (value) {
            .int => |int| int == 0,
            .named, .fp, .undef, .poison, .null_value, .zero_initializer, .vector, .constant_expr => false,
        };
    }

    fn lowerTypedArrayElemVal(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 2) return error.UnsupportedAir;
        const table_text = typedOperandTextDetail(instruction, 0) orelse return error.UnsupportedAir;
        const index = try self.resolveTypedOperand(instruction, 1);
        if (!index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        if (!std.mem.eql(u8, table_text, "<[4]u8, \"\\x00\\x04\\x08\\x0c\".*>")) return error.UnsupportedAir;
        try ensureBase64LookupGlobal(self.allocator, self.module);

        const gep_name = try ownPrint(self.module, "air{}_ptr", .{instruction.index});
        var gep: ir.GepInst = .{
            .source_ty = .{ .aggregate = "[4 x i8]" },
            .ptr = .{ .named = "@__anon_base64_table" },
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{ .result = gep_name, .kind = .{ .gep = gep } });

        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (!result_type.ir_type.eql(.{ .int = 8 })) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = gep_name } } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedFieldPtr(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        const aggregate_ptr = try self.resolveTypedOperand(instruction, 0);
        if (aggregate_ptr.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_type = parseZigType(instruction.result_type) orelse return error.UnsupportedAir;
        if (result_type.ir_type != .ptr) return error.UnsupportedAir;
        const field_child = result_type.pointer_child orelse return error.UnsupportedAir;
        const field_index_text = typedDetail(instruction, "field_index") orelse return error.UnsupportedAir;
        const field_index = std.fmt.parseInt(i128, field_index_text, 10) catch return error.UnsupportedAir;
        const source_ty = aggregate_ptr.ty.pointer_child orelse return error.UnsupportedAir;
        if (selectedFieldByteOffset(source_ty, field_child, field_index)) |offset| {
            if (offset == 0) {
                self.values[instruction.index] = .{
                    .ty = result_type,
                    .value = aggregate_ptr.value,
                };
                return;
            }
            const result_name = try self.resultName(instruction.index);
            var gep: ir.GepInst = .{
                .source_ty = .{ .int = 8 },
                .ptr = aggregate_ptr.value,
                .indices = .empty,
            };
            errdefer gep.deinit(self.allocator);
            try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = offset } });
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .gep = gep },
            });
            self.values[instruction.index] = .{
                .ty = result_type,
                .value = .{ .named = result_name },
            };
            return;
        }

        if (!isPlainFieldPointerChild(field_child)) return error.UnsupportedAir;

        const result_name = try self.resultName(instruction.index);
        var gep: ir.GepInst = .{
            .source_ty = source_ty,
            .ptr = aggregate_ptr.value,
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 32 }, .value = .{ .int = field_index } });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .gep = gep },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerTypedCall(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (instruction.operands.len == 0) return error.UnsupportedAir;
        const signature_text = typedDetail(instruction, "call_signature") orelse return error.UnsupportedAir;
        const callee_text = typedDetail(instruction, "callee_text") orelse return error.UnsupportedAir;
        const call_type = try parseFunctionType(self.allocator, signature_text);
        defer call_type.deinit(self.allocator);
        if (instruction.operands.len != call_type.params.len + 1) return error.UnsupportedAir;
        const parsed_callee = typedCallee(callee_text);
        const callee = if (parsed_callee) |direct|
            if (direct.external)
                direct.name
            else
                try self.qualifiedCalleeName(direct.name)
        else
            "";
        const callee_name = typedCalleeName(callee_text);
        const callee_value: ?ir.Value = if (parsed_callee == null) blk: {
            const callee_operand = try self.resolveTypedOperand(instruction, 0);
            if (callee_operand.ty.ir_type != .ptr) return error.UnsupportedAir;
            break :blk callee_operand.value;
        } else null;

        const is_default_panic = callee_name != null and std.mem.eql(u8, callee_name.?, "defaultPanic");
        var call: ir.CallInst = .{
            .ret_ty = call_type.return_type.ir_type,
            .callee = if (is_default_panic) "debug.defaultPanic" else callee,
            .callee_value = callee_value,
            .calling_conv = irCallingConvention(call_type),
            .tail_kind = tailKindForCallOpcode(instruction.opcode),
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        if (is_default_panic and (call_type.params.len == 1 or call_type.params.len == 2) and
            call_type.params[0].ir_type.eql(.{ .aggregate = "{ ptr, i64 }" }))
        {
            const slice_arg = try self.resolveTypedOperand(instruction, 1);
            if (!slice_arg.ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return error.UnsupportedAir;
            if (call_type.params.len == 2 and !call_type.params[1].ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
            const ptr_name = try ownPrint(self.module, "air{}_panic_ptr", .{instruction.index});
            const len_name = try ownPrint(self.module, "air{}_panic_len", .{instruction.index});
            try self.block.instructions.append(self.allocator, .{
                .result = ptr_name,
                .kind = .{ .extractvalue = .{
                    .aggregate_ty = slice_arg.ty.ir_type,
                    .aggregate = slice_arg.value,
                    .indices = "0",
                    .result_ty = .ptr,
                } },
            });
            try self.block.instructions.append(self.allocator, .{
                .result = len_name,
                .kind = .{ .extractvalue = .{
                    .aggregate_ty = slice_arg.ty.ir_type,
                    .aggregate = slice_arg.value,
                    .indices = "1",
                    .result_ty = .{ .int = 64 },
                } },
            });
            try call.args.append(self.allocator, .{ .ty = .ptr, .value = .{ .named = ptr_name } });
            try call.args.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .named = len_name } });
            try self.block.instructions.append(self.allocator, .{
                .result = null,
                .kind = .{ .call = call },
            });
            return;
        }
        for (call_type.params, 0..) |param_type, arg_index| {
            const arg = try self.resolveTypedOperand(instruction, arg_index + 1);
            if (!arg.ty.ir_type.eql(param_type.ir_type)) return error.UnsupportedAir;
            try call.args.append(self.allocator, .{
                .ty = arg.ty.ir_type,
                .value = arg.value,
            });
        }

        const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        if (result_name) |name| {
            self.values[instruction.index] = .{
                .ty = call_type.return_type,
                .value = .{ .named = name },
            };
        }
    }

    fn lowerTypedReturn(self: *LoweringContext, instruction: air_export.TypedInstruction) !void {
        if (self.function_type.return_type.ir_type == .void) {
            self.block.terminator = .{ .ret = .{ .ty = .void } };
            return;
        }
        if (instruction.operands.len != 1) return error.UnsupportedAir;
        var value = try self.resolveTypedOperand(instruction, 0);
        if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) {
            const return_type_text = functionReturnTypeText(self.air_function.type_text) orelse return error.UnsupportedAir;
            if (!isErrorUnionTypeText(return_type_text) or
                !self.function_type.return_type.ir_type.eql(.{ .int = 64 }))
            {
                return error.UnsupportedAir;
            }
            const payload_type = errorUnionPayloadType(return_type_text) orelse return error.UnsupportedAir;
            if (value.ty.ir_type.eql(payload_type.ir_type)) {
                const wrapped_name = try self.encodeErrorUnionPayload(instruction.index, value.value);
                value = .{ .ty = self.function_type.return_type, .value = .{ .named = wrapped_name } };
            } else if (value.ty.ir_type.eql(.{ .int = 16 })) {
                const wrapped_name = try self.resultName(instruction.index);
                try self.block.instructions.append(self.allocator, .{
                    .result = wrapped_name,
                    .kind = .{ .cast = .{
                        .op = .zext,
                        .from_ty = .{ .int = 16 },
                        .value = value.value,
                        .to_ty = .{ .int = 64 },
                    } },
                });
                value = .{ .ty = self.function_type.return_type, .value = .{ .named = wrapped_name } };
            } else {
                return error.UnsupportedAir;
            }
        }
        self.block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = value.value,
        } };
    }

    fn lowerArg(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const type_text = fields.next() orelse return error.UnsupportedAir;
        const index_text = fields.next() orelse return error.UnsupportedAir;
        if (fields.next() != null) return error.UnsupportedAir;
        const param_index = std.fmt.parseInt(usize, std.mem.trim(u8, index_text, " "), 10) catch
            return error.UnsupportedAir;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const parsed_type = parseZigType(std.mem.trim(u8, type_text, " ")) orelse
            return error.UnsupportedAir;
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) {
            return error.UnsupportedAir;
        }
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    fn lowerBinary(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        var rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        if (!lhs.ty.ir_type.eql(rhs.ty.ir_type)) {
            if (!isShiftOpcode(instruction.opcode)) return error.UnsupportedAir;
            rhs = try self.extendShiftCount(instruction.index, lhs.ty, rhs);
        }
        const op = binaryOp(instruction.opcode, lhs.ty) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .binary = .{
                .op = op,
                .ty = lhs.ty.ir_type,
                .lhs = lhs.value,
                .rhs = rhs.value,
            } },
        });
        self.values[instruction.index] = .{
            .ty = lhs.ty,
            .value = .{ .named = result_name },
        };
    }

    fn extendShiftCount(
        self: *LoweringContext,
        instruction_index: u32,
        lhs_type: ZigType,
        rhs: TypedValue,
    ) !TypedValue {
        const lhs_bits = intBits(lhs_type.ir_type) orelse return error.UnsupportedAir;
        const rhs_bits = intBits(rhs.ty.ir_type) orelse return error.UnsupportedAir;
        const op: ir.CastOp = if (rhs_bits < lhs_bits)
            .zext
        else if (rhs_bits > lhs_bits)
            .trunc
        else
            return rhs;
        const result_name = try ownPrint(self.module, "air{}_shift_count", .{instruction_index});
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = rhs.ty.ir_type,
                .value = rhs.value,
                .to_ty = lhs_type.ir_type,
            } },
        });
        return .{
            .ty = .{ .ir_type = lhs_type.ir_type },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCompare(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const lhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const rhs = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or !lhs.ty.ir_type.eql(rhs.ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        if (isFpType(lhs.ty.ir_type)) {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .fcmp = .{
                    .predicate = fpPredicate(instruction.opcode) orelse return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        } else {
            try self.block.instructions.append(self.allocator, .{
                .result = result_name,
                .kind = .{ .icmp = .{
                    .predicate = intPredicate(instruction.opcode, lhs.ty.signed) orelse
                        return error.UnsupportedAir,
                    .operand_ty = lhs.ty.ir_type,
                    .lhs = lhs.value,
                    .rhs = rhs.value,
                } },
            });
        }
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 1 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerCast(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const target_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const source = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null) return error.UnsupportedAir;
        const target_type = parseZigType(target_text) orelse return error.UnsupportedAir;
        const op = castOp(instruction.opcode, source.ty, target_type) orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .cast = .{
                .op = op,
                .from_ty = source.ty.ir_type,
                .value = source.value,
                .to_ty = target_type.ir_type,
            } },
        });
        self.values[instruction.index] = .{
            .ty = target_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerAlloca(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const pointer_type = parseZigType(std.mem.trim(u8, instruction.payload, " ")) orelse
            return error.UnsupportedAir;
        const allocated_type = pointer_type.pointer_child orelse return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .alloca = .{ .allocated_ty = allocated_type } },
        });
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerLoad(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const result_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{
                .ty = result_type.ir_type,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
        self.values[instruction.index] = .{
            .ty = result_type,
            .value = .{ .named = result_name },
        };
    }

    fn lowerStore(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or pointer.ty.ir_type != .ptr) return error.UnsupportedAir;
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .store = .{
                .ty = value.ty.ir_type,
                .value = value.value,
                .ptr = pointer.value,
                .attrs = .{ .is_volatile = pointer.ty.is_volatile_pointer },
            } },
        });
    }

    fn lowerCall(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const function_marker = std.mem.indexOf(u8, instruction.payload, "(function '") orelse
            return error.UnsupportedAir;
        const signature_start = std.mem.indexOfScalar(u8, instruction.payload, '<') orelse
            return error.UnsupportedAir;
        const signature_end = std.mem.lastIndexOfScalar(u8, instruction.payload[signature_start..function_marker], ',') orelse
            return error.UnsupportedAir;
        const signature_text = std.mem.trim(
            u8,
            instruction.payload[signature_start + 1 .. signature_start + signature_end],
            " ",
        );
        const call_type = try parseFunctionType(self.allocator, signature_text);
        defer call_type.deinit(self.allocator);
        const callee_start = function_marker + "(function '".len;
        const callee_relative_end = std.mem.indexOf(u8, instruction.payload[callee_start..], "')") orelse
            return error.UnsupportedAir;
        const callee = try self.qualifiedCalleeName(instruction.payload[callee_start .. callee_start + callee_relative_end]);
        const args_start = std.mem.indexOfScalarPos(u8, instruction.payload, callee_start + callee_relative_end, '[') orelse
            return error.UnsupportedAir;
        const args_end = std.mem.lastIndexOfScalar(u8, instruction.payload, ']') orelse
            return error.UnsupportedAir;
        if (args_end < args_start) return error.UnsupportedAir;

        var call: ir.CallInst = .{
            .ret_ty = call_type.return_type.ir_type,
            .callee = callee,
            .calling_conv = irCallingConvention(call_type),
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        var arg_index: usize = 0;
        var args = splitTopLevel(instruction.payload[args_start + 1 .. args_end], ',');
        while (args.next()) |arg_text| {
            if (std.mem.trim(u8, arg_text, " ").len == 0) continue;
            if (arg_index >= call_type.params.len) return error.UnsupportedAir;
            const arg = try self.resolveValue(arg_text);
            if (!arg.ty.ir_type.eql(call_type.params[arg_index].ir_type)) return error.UnsupportedAir;
            try call.args.append(self.allocator, .{
                .ty = arg.ty.ir_type,
                .value = arg.value,
            });
            arg_index += 1;
        }
        if (arg_index != call_type.params.len) return error.UnsupportedAir;

        const result_name = if (call.ret_ty == .void) null else try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .call = call },
        });
        if (result_name) |name| {
            self.values[instruction.index] = .{
                .ty = call_type.return_type,
                .value = .{ .named = name },
            };
        }
    }

    fn lowerRuntimeNavPtr(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer_type = parseZigType(std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ")) orelse
            return error.UnsupportedAir;
        const symbol_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer_type.ir_type != .ptr or symbol_text.len < 3 or
            symbol_text[0] != '\'' or symbol_text[symbol_text.len - 1] != '\'')
        {
            return error.UnsupportedAir;
        }
        const symbol = try ownPrint(self.module, "@{s}", .{symbol_text[1 .. symbol_text.len - 1]});
        self.values[instruction.index] = .{
            .ty = pointer_type,
            .value = .{ .named = symbol },
        };
    }

    fn lowerAtomicRmw(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const pointer = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const value = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        const operation = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const ordering = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        if (fields.next() != null or pointer.ty.ir_type != .ptr or
            !std.mem.eql(u8, operation, "Add") or
            !std.mem.eql(u8, ordering, "monotonic"))
        {
            return error.UnsupportedAir;
        }
        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .atomicrmw = .{
                .op = "add",
                .ty = value.ty.ir_type,
                .ptr = pointer.value,
                .value = value.value,
                .ordering = ordering,
            } },
        });
        self.values[instruction.index] = .{
            .ty = value.ty,
            .value = .{ .named = result_name },
        };
    }

    fn lowerArrayElemVal(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const table_text = std.mem.trim(u8, fields.next() orelse return error.UnsupportedAir, " ");
        const index = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
        if (fields.next() != null or !index.ty.ir_type.eql(.{ .int = 64 })) return error.UnsupportedAir;
        if (!std.mem.eql(u8, table_text, "<[4]u8, \"\\x00\\x04\\x08\\x0c\".*>")) return error.UnsupportedAir;
        try ensureBase64LookupGlobal(self.allocator, self.module);

        const gep_name = try ownPrint(self.module, "air{}_ptr", .{instruction.index});
        var gep: ir.GepInst = .{
            .source_ty = .{ .aggregate = "[4 x i8]" },
            .ptr = .{ .named = "@__anon_base64_table" },
            .indices = .empty,
        };
        errdefer gep.deinit(self.allocator);
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = .{ .int = 0 } });
        try gep.indices.append(self.allocator, .{ .ty = .{ .int = 64 }, .value = index.value });
        try self.block.instructions.append(self.allocator, .{ .result = gep_name, .kind = .{ .gep = gep } });

        const result_name = try self.resultName(instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .load = .{ .ty = .{ .int = 8 }, .ptr = .{ .named = gep_name } } },
        });
        self.values[instruction.index] = .{
            .ty = .{ .ir_type = .{ .int = 8 } },
            .value = .{ .named = result_name },
        };
    }

    fn lowerAssembly(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const payload = std.mem.trim(u8, instruction.payload, " ");
        if (!std.mem.eql(u8, payload, "void, volatile, ~{memory}, \"\"")) return error.UnsupportedAir;
        var call: ir.CallInst = .{
            .ret_ty = .void,
            .callee = "",
            .inline_asm = .{
                .template = "",
                .constraints = "~{memory}",
                .sideeffect = true,
                .has_memory_clobber = true,
            },
            .args = .empty,
        };
        errdefer call.deinit(self.allocator);
        try self.block.instructions.append(self.allocator, .{
            .result = null,
            .kind = .{ .call = call },
        });
    }

    fn lowerReturn(self: *LoweringContext, instruction: air_export.Instruction) !void {
        const payload = std.mem.trim(u8, instruction.payload, " ");
        if (self.function_type.return_type.ir_type == .void) {
            self.block.terminator = .{ .ret = .{ .ty = .void } };
            return;
        }
        const value = try self.resolveValue(payload);
        if (!value.ty.ir_type.eql(self.function_type.return_type.ir_type)) return error.UnsupportedAir;
        self.block.terminator = .{ .ret = .{
            .ty = self.function_type.return_type.ir_type,
            .value = value.value,
        } };
    }

    fn resolveValue(self: *LoweringContext, text: []const u8) LowerError!TypedValue {
        const trimmed = std.mem.trim(u8, text, " ");
        if (parseInstructionRef(trimmed)) |index| {
            if (index >= self.values.len) return error.UnsupportedAir;
            if (self.values[index]) |value| return value;
            if (self.findInstruction(index)) |instruction| {
                if (std.mem.eql(u8, instruction.opcode, "block") and
                    isSimpleSelectBlock(self.air_function, index))
                {
                    try self.materializeSelectBlock(instruction);
                    return self.values[index] orelse error.UnsupportedAir;
                }
            }
            return error.UnsupportedAir;
        }
        if (parseSymbolPointer(trimmed)) |symbol_pointer| {
            return .{
                .ty = symbol_pointer.ty,
                .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
            };
        }
        return parseConstant(trimmed) orelse error.UnsupportedAir;
    }

    fn resolveTypedOperand(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
    ) LowerError!TypedValue {
        if (operand_index >= instruction.operands.len) return error.UnsupportedAir;
        const operand = instruction.operands[operand_index];
        if (std.mem.eql(u8, operand.kind, "inst")) {
            const index = std.fmt.parseInt(u32, operand.value, 10) catch return error.UnsupportedAir;
            if (index >= self.values.len) return error.UnsupportedAir;
            return self.values[index] orelse error.UnsupportedAir;
        }
        if (std.mem.eql(u8, operand.kind, "const")) {
            const literal = typedOperandTextDetail(instruction, operand_index) orelse
                return error.UnsupportedAir;
            if (parseSymbolPointer(literal)) |symbol_pointer| {
                return .{
                    .ty = symbol_pointer.ty,
                    .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
                };
            }
            if (try self.resolveStringLiteralPointer(literal)) |string_pointer| return string_pointer;
            if (try self.resolveStringLiteralSlice(instruction, operand_index, literal)) |string_slice| return string_slice;
            return parseConstant(literal) orelse error.UnsupportedAir;
        }
        if (std.mem.eql(u8, operand.kind, "none")) return error.UnsupportedAir;
        return error.UnsupportedAir;
    }

    fn resolveStringLiteralPointer(self: *LoweringContext, literal: []const u8) !?TypedValue {
        if (!std.mem.startsWith(u8, literal, "<") or !std.mem.endsWith(u8, literal, ">")) return null;
        var fields = splitTopLevel(literal[1 .. literal.len - 1], ',');
        const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(type_text) orelse return null;
        if (ty.ir_type != .ptr) return null;
        if (value_text.len < 2 or value_text[0] != '"' or value_text[value_text.len - 1] != '"') return null;
        const body = value_text[1 .. value_text.len - 1];
        const byte_len = cStringLiteralByteLen(body) orelse return null;
        const symbol = try self.ensureStringLiteralGlobal(body, byte_len);
        return .{
            .ty = ty,
            .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol}) },
        };
    }

    fn resolveStringLiteralSlice(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
        literal: []const u8,
    ) !?TypedValue {
        if (!std.mem.startsWith(u8, literal, "<") or !std.mem.endsWith(u8, literal, ">")) return null;
        var fields = splitTopLevel(literal[1 .. literal.len - 1], ',');
        const type_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        const value_text = std.mem.trim(u8, fields.next() orelse return null, " ");
        if (fields.next() != null) return null;
        const ty = parseZigType(type_text) orelse return null;
        if (!ty.ir_type.eql(.{ .aggregate = "{ ptr, i64 }" })) return null;

        const slice = parseStringSliceLiteral(value_text) orelse return null;
        const global_len = cStringLiteralByteLen(slice.body) orelse return null;
        const symbol = try self.ensureStringLiteralGlobal(slice.body, global_len);

        const ptr_name = try ownPrint(self.module, "air{}_op{}_slice_ptr", .{ instruction.index, operand_index });
        try self.block.instructions.append(self.allocator, .{
            .result = ptr_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = ty.ir_type,
                .aggregate = .undef,
                .value_ty = .ptr,
                .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol}) },
                .indices = "0",
            } },
        });

        const result_name = try ownPrint(self.module, "air{}_op{}_slice", .{ instruction.index, operand_index });
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .insertvalue = .{
                .aggregate_ty = ty.ir_type,
                .aggregate = .{ .named = ptr_name },
                .value_ty = .{ .int = 64 },
                .value = .{ .int = slice.len },
                .indices = "1",
            } },
        });
        return .{
            .ty = ty,
            .value = .{ .named = result_name },
        };
    }

    const StringSliceLiteral = struct {
        body: []const u8,
        len: i128,
    };

    fn parseStringSliceLiteral(text: []const u8) ?StringSliceLiteral {
        if (text.len < 2 or text[0] != '"') return null;
        const quote_end = std.mem.lastIndexOfScalar(u8, text, '"') orelse return null;
        if (quote_end == 0) return null;
        const body = text[1..quote_end];
        const suffix = text[quote_end + 1 ..];
        const range_prefix = "[0..";
        if (!std.mem.startsWith(u8, suffix, range_prefix) or !std.mem.endsWith(u8, suffix, "]")) return null;
        const len = std.fmt.parseInt(i128, suffix[range_prefix.len .. suffix.len - 1], 10) catch return null;
        if (len < 0) return null;
        return .{ .body = body, .len = len };
    }

    fn ensureStringLiteralGlobal(self: *LoweringContext, body: []const u8, byte_len: usize) ![]const u8 {
        const hash = std.hash.Wyhash.hash(0, body);
        const symbol = try ownPrint(self.module, "__zllvm_string_{x}", .{hash});
        for (self.module.globals.items) |global| {
            if (std.mem.eql(u8, global.name, symbol)) return symbol;
        }
        try self.module.globals.append(self.allocator, .{
            .name = symbol,
            .linkage = .private,
            .address_attrs = "unnamed_addr",
            .kind = .constant,
            .ty = .{ .aggregate = try ownPrint(self.module, "[{} x i8]", .{byte_len}) },
            .initializer = .{ .c_string = try ownPrint(self.module, "c\"{s}\"", .{body}) },
        });
        return symbol;
    }

    fn materializeSelectBlock(
        self: *LoweringContext,
        block_instruction: air_export.Instruction,
    ) LowerError!void {
        var condition: ?TypedValue = null;
        var incoming: [2]TypedValue = undefined;
        var incoming_count: usize = 0;
        const block_position = instructionPosition(self.air_function, block_instruction.index) orelse
            return error.UnsupportedAir;
        for (self.air_function.instructions[block_position + 1 ..]) |instruction| {
            if (instruction.indent <= block_instruction.indent) break;
            if (std.mem.eql(u8, instruction.opcode, "cond_br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                condition = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
            } else if (std.mem.eql(u8, instruction.opcode, "br")) {
                var fields = splitTopLevel(instruction.payload, ',');
                const target_text = fields.next() orelse return error.UnsupportedAir;
                if (parseInstructionRef(target_text) != block_instruction.index) continue;
                if (incoming_count >= incoming.len) return error.UnsupportedAir;
                incoming[incoming_count] = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
                incoming_count += 1;
            }
        }
        const cond = condition orelse return error.UnsupportedAir;
        if (cond.ty.ir_type != .int or cond.ty.ir_type.int != 1 or incoming_count != 2) {
            return error.UnsupportedAir;
        }
        if (!incoming[0].ty.ir_type.eql(incoming[1].ty.ir_type)) return error.UnsupportedAir;
        const result_name = try self.resultName(block_instruction.index);
        try self.block.instructions.append(self.allocator, .{
            .result = result_name,
            .kind = .{ .select = .{
                .cond_ty = cond.ty.ir_type,
                .cond = cond.value,
                .ty = incoming[0].ty.ir_type,
                .true_value = incoming[0].value,
                .false_value = incoming[1].value,
            } },
        });
        self.values[block_instruction.index] = .{
            .ty = incoming[0].ty,
            .value = .{ .named = result_name },
        };
    }

    fn findInstruction(self: LoweringContext, index: u32) ?air_export.Instruction {
        for (self.air_function.instructions) |instruction| {
            if (instruction.index == index) return instruction;
        }
        return null;
    }

    fn resultName(self: *LoweringContext, index: u32) ![]const u8 {
        return ownPrint(self.module, "air{}", .{index});
    }

    fn blockParamName(self: LoweringContext, index: usize) []const u8 {
        return self.function.params.items[index].name;
    }

    fn qualifiedCalleeName(self: *LoweringContext, callee: []const u8) ![]const u8 {
        if (std.mem.indexOfScalar(u8, callee, '.') != null) return callee;
        const dot = std.mem.lastIndexOfScalar(u8, self.air_function.name, '.') orelse return callee;
        return ownPrint(self.module, "{s}.{s}", .{ self.air_function.name[0..dot], callee });
    }
};
