const std = @import("std");
const air_export = @import("zig_air_export.zig");
const ir = @import("ir.zig");
const air_capabilities = @import("zig_air_capabilities.zig");
const air_model = @import("zig_air_model.zig");
const air_semantics = @import("zig_air_semantics.zig");
const air_text = @import("zig_air_text.zig");
const air_types = @import("zig_air_types.zig");
const air_values = @import("zig_air_values.zig");
const typed_v2_fallbacks = @import("zig_air_lowering_typed_v2_fallbacks.zig");
const typed_dispatch = @import("zig_air_lowering_context_typed_dispatch.zig");
const typed_error_union = @import("zig_air_lowering_context_typed_error_union.zig");
const typed_memory = @import("zig_air_lowering_context_typed_memory.zig");
const typed_optional = @import("zig_air_lowering_context_typed_optional.zig");
const typed_union_tag = @import("zig_air_lowering_context_typed_union_tag.zig");
const typed_pointer_aggregate = @import("zig_air_lowering_context_typed_pointer_aggregate.zig");
const typed_aggregate = @import("zig_air_lowering_context_typed_aggregate.zig");
const typed_scalar = @import("zig_air_lowering_context_typed_scalar.zig");
const typed_vector = @import("zig_air_lowering_context_typed_vector.zig");
const typed_cfg = @import("zig_air_lowering_context_typed_cfg.zig");
const typed_call = @import("zig_air_lowering_context_typed_call.zig");

const ZigType = air_model.ZigType;
const FunctionType = air_model.FunctionType;
const TypedValue = air_model.TypedValue;
const LowerError = air_model.LowerError;
const TypedBranchMergeResult = air_model.TypedBranchMergeResult;
const parseFunctionType = air_types.parseFunctionType;
const functionReturnTypeText = air_types.functionReturnTypeText;
const parseZigType = air_types.parseZigType;
const isOpaqueNominalTypeSurface = air_types.isOpaqueNominalTypeSurface;
const pointerLoadResultType = air_types.pointerLoadResultType;
const isErrorUnionTypeText = air_types.isErrorUnionTypeText;
const errorUnionPayloadType = air_types.errorUnionPayloadType;
const parseConstant = air_values.parseConstant;
const parseSymbolPointer = air_values.parseSymbolPointer;
const cStringLiteralByteLen = air_values.cStringLiteralByteLen;
const parseInstructionRef = air_text.instructionRef;
const isSimpleSelectBlock = air_model.simpleSelectBlock;
const instructionPosition = air_model.instructionRecordPosition;
const typedBlockTarget = air_model.blockTarget;
const irCallingConvention = air_model.irCallingConvention;
const isShiftOpcode = air_capabilities.isShiftOpcode;
const isPlainFieldPointerChild = air_model.plainFieldPointerChild;
const isSupportedTypedGepElementType = air_model.supportedTypedGepElementType;
const aggregateFieldByteOffset = air_model.aggregateFieldByteOffset;
const genericTypedGepIndex = air_model.genericTypedGepIndex;
const binaryOp = air_semantics.binaryOp;
const intPredicate = air_semantics.intPredicate;
const fpPredicate = air_semantics.fpPredicate;
const castOp = air_semantics.castOp;
const isFpType = air_semantics.isFpType;
const intBits = air_semantics.intBits;
const isPointerType = air_types.isPointerType;
const pointerChildText = air_types.pointerChildText;
const ownPrint = air_model.ownPrint;
const findMatching = air_text.findMatching;
const splitTopLevel = air_text.splitTopLevel;
const ensureBase64LookupGlobal = typed_v2_fallbacks.ensureBase64LookupGlobal;

pub const TypedV2Fallback = struct {
    function: []const u8,
    opcode: []const u8,
    data_kind: []const u8,
    reason: []const u8,
};

pub const LoweringContext = struct {
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
    synthetic_pointer_payloads: []?TypedValue,
    synthetic_error_union_slots: []?TypedValue,
    synthetic_union_tag_slots: []?TypedValue,
    synthetic_union_field_ptrs: []?air_model.SyntheticUnionFieldPointer,
    synthetic_vector_slots: []?TypedValue,
    synthetic_vector_element_ptrs: []?air_model.SyntheticVectorElementPointer,
    next_arg_index: usize = 0,

    // Typed lowering dispatch and domain-specific lowering operations.
    pub const lowerTypedInstruction = typed_dispatch.lowerTypedInstruction;
    pub const lowerTypedInstructionImpl = typed_dispatch.lowerTypedInstructionImpl;
    pub const lowerTypedSemanticInstruction = typed_dispatch.lowerTypedSemanticInstruction;
    pub const lowerTypedBackendRuntimeInstruction = typed_dispatch.lowerTypedBackendRuntimeInstruction;
    pub const recordTypedV2Fallback = typed_dispatch.recordTypedV2Fallback;
    pub const typedInstructionCapability = typed_dispatch.typedInstructionCapability;

    pub const lowerTypedCfgInstruction = typed_cfg.lowerTypedCfgInstruction;
    pub const lowerTypedBlock = typed_cfg.lowerTypedBlock;
    pub const lowerTypedSwitchValueBlock = typed_cfg.lowerTypedSwitchValueBlock;
    pub const collectBlockValueBranches = typed_cfg.collectBlockValueBranches;
    pub const lowerTypedSwitchBranchValue = typed_cfg.lowerTypedSwitchBranchValue;
    pub const lowerTypedNestedBlockSwitchBranchValue = typed_cfg.lowerTypedNestedBlockSwitchBranchValue;
    pub const lowerTypedValueDependency = typed_cfg.lowerTypedValueDependency;
    pub const lowerTypedCondBrReturn = typed_cfg.lowerTypedCondBrReturn;
    pub const lowerTypedCondBodiesReturn = typed_cfg.lowerTypedCondBodiesReturn;
    pub const lowerTypedBodyToTerminalBlock = typed_cfg.lowerTypedBodyToTerminalBlock;
    pub const lowerTypedBranchReturnContinueBlock = typed_cfg.lowerTypedBranchReturnContinueBlock;
    pub const lowerTypedBranchReturnContinueValueBlock = typed_cfg.lowerTypedBranchReturnContinueValueBlock;
    pub const lowerTypedVoidGuard = typed_cfg.lowerTypedVoidGuard;
    pub const typedBlockBranchValue = typed_cfg.typedBlockBranchValue;
    pub const lowerTypedBranchMergeBlock = typed_cfg.lowerTypedBranchMergeBlock;
    pub const mergeSyntheticErrorUnionSlots = typed_cfg.mergeSyntheticErrorUnionSlots;
    pub const mergeSyntheticUnionTagSlots = typed_cfg.mergeSyntheticUnionTagSlots;
    pub const typedBlockResultType = typed_cfg.typedBlockResultType;
    pub const lowerTypedBranchBodyToMerge = typed_cfg.lowerTypedBranchBodyToMerge;
    pub const lowerTypedBranchBodyToOpenContinuation = typed_cfg.lowerTypedBranchBodyToOpenContinuation;
    pub const coerceTypedBranchValueToMerge = typed_cfg.coerceTypedBranchValueToMerge;
    pub const resolveTypedBranchOperand = typed_cfg.resolveTypedBranchOperand;
    pub const lowerTypedBlockBodyUntilCond = typed_cfg.lowerTypedBlockBodyUntilCond;
    pub const lowerTypedReturn = typed_cfg.lowerTypedReturn;

    pub const lowerTypedErrorUnionSemanticInstruction = typed_error_union.lowerTypedErrorUnionSemanticInstruction;
    pub const lowerTypedErrorName = typed_error_union.lowerTypedErrorName;
    pub const lowerTypedErrorSetHasValue = typed_error_union.lowerTypedErrorSetHasValue;
    pub const lowerTypedCmpLteErrorsLen = typed_error_union.lowerTypedCmpLteErrorsLen;
    pub const lowerTypedIsNonErr = typed_error_union.lowerTypedIsNonErr;
    pub const lowerTypedWrapErrorUnionPayload = typed_error_union.lowerTypedWrapErrorUnionPayload;
    pub const lowerTypedWrapErrorUnionErr = typed_error_union.lowerTypedWrapErrorUnionErr;
    pub const lowerTypedUnwrapErrorUnionPayload = typed_error_union.lowerTypedUnwrapErrorUnionPayload;
    pub const lowerTypedUnwrapErrorUnionErr = typed_error_union.lowerTypedUnwrapErrorUnionErr;
    pub const lowerTypedUnwrapErrorUnionErrPtr = typed_error_union.lowerTypedUnwrapErrorUnionErrPtr;
    pub const lowerTypedUnwrapErrorUnionPayloadPtr = typed_error_union.lowerTypedUnwrapErrorUnionPayloadPtr;
    pub const lowerTypedTry = typed_error_union.lowerTypedTry;
    pub const lowerTypedTryPtr = typed_error_union.lowerTypedTryPtr;
    pub const loadErrorUnionPointerValue = typed_error_union.loadErrorUnionPointerValue;
    pub const syntheticErrorUnionPointerValueName = typed_error_union.syntheticErrorUnionPointerValueName;
    pub const materializeErrorUnionPayloadPointer = typed_error_union.materializeErrorUnionPayloadPointer;
    pub const allocateErrorUnionPayloadPointer = typed_error_union.allocateErrorUnionPayloadPointer;
    pub const storeErrorUnionPayloadIntoPointer = typed_error_union.storeErrorUnionPayloadIntoPointer;
    pub const emitErrorUnionErrorBits = typed_error_union.emitErrorUnionErrorBits;
    pub const encodeErrorUnionPayload = typed_error_union.encodeErrorUnionPayload;
    pub const encodeErrorUnionPayloadWithPrefix = typed_error_union.encodeErrorUnionPayloadWithPrefix;
    pub const decodeErrorUnionPayload = typed_error_union.decodeErrorUnionPayload;
    pub const decodeErrorUnionPayloadWithPrefix = typed_error_union.decodeErrorUnionPayloadWithPrefix;

    pub const lowerTypedMemorySemanticInstruction = typed_memory.lowerTypedMemorySemanticInstruction;
    pub const lowerTypedAlloca = typed_memory.lowerTypedAlloca;
    pub const lowerTypedLoad = typed_memory.lowerTypedLoad;
    pub const lowerTypedLoadFromSyntheticPointerPayload = typed_memory.lowerTypedLoadFromSyntheticPointerPayload;
    pub const lowerTypedLoadFromSyntheticErrorUnionSlot = typed_memory.lowerTypedLoadFromSyntheticErrorUnionSlot;
    pub const lowerTypedLoadFromSyntheticUnionTagSlot = typed_memory.lowerTypedLoadFromSyntheticUnionTagSlot;
    pub const lowerTypedLoadFromSyntheticVectorSlot = typed_memory.lowerTypedLoadFromSyntheticVectorSlot;
    pub const lowerTypedLoadFromSyntheticVectorElement = typed_memory.lowerTypedLoadFromSyntheticVectorElement;
    pub const lowerTypedLoadFromSliceLenPtr = typed_memory.lowerTypedLoadFromSliceLenPtr;
    pub const lowerTypedLoadFromSlicePtrPtr = typed_memory.lowerTypedLoadFromSlicePtrPtr;
    pub const lowerTypedStore = typed_memory.lowerTypedStore;
    pub const lowerTypedAtomicStoreMonotonic = typed_memory.lowerTypedAtomicStoreMonotonic;
    pub const lowerTypedStoreToSyntheticErrorUnionSlot = typed_memory.lowerTypedStoreToSyntheticErrorUnionSlot;
    pub const lowerTypedStoreToSyntheticVectorSlot = typed_memory.lowerTypedStoreToSyntheticVectorSlot;
    pub const lowerTypedStoreToSyntheticVectorElement = typed_memory.lowerTypedStoreToSyntheticVectorElement;
    pub const lowerTypedStoreToSyntheticUnionField = typed_memory.lowerTypedStoreToSyntheticUnionField;

    pub const lowerTypedOptionalSemanticInstruction = typed_optional.lowerTypedOptionalSemanticInstruction;
    pub const lowerTypedIsNonNull = typed_optional.lowerTypedIsNonNull;
    pub const lowerTypedWrapOptional = typed_optional.lowerTypedWrapOptional;
    pub const lowerTypedOptionalPayload = typed_optional.lowerTypedOptionalPayload;

    pub const lowerTypedUnionTagSemanticInstruction = typed_union_tag.lowerTypedUnionTagSemanticInstruction;
    pub const lowerTypedUnionInit = typed_union_tag.lowerTypedUnionInit;
    pub const lowerTypedSetUnionTag = typed_union_tag.lowerTypedSetUnionTag;
    pub const lowerTypedGetUnionTag = typed_union_tag.lowerTypedGetUnionTag;

    pub const lowerTypedPointerAggregateSemanticInstruction =
        typed_pointer_aggregate.lowerTypedPointerAggregateSemanticInstruction;
    pub const lowerTypedSlice = typed_pointer_aggregate.lowerTypedSlice;
    pub const lowerTypedArrayToSlice = typed_pointer_aggregate.lowerTypedArrayToSlice;
    pub const lowerTypedSliceLenPtr = typed_pointer_aggregate.lowerTypedSliceLenPtr;
    pub const lowerTypedSlicePtr = typed_pointer_aggregate.lowerTypedSlicePtr;
    pub const lowerTypedSliceLen = typed_pointer_aggregate.lowerTypedSliceLen;
    pub const lowerTypedSlicePtrPtr = typed_pointer_aggregate.lowerTypedSlicePtrPtr;
    pub const lowerTypedSliceElemPtr = typed_pointer_aggregate.lowerTypedSliceElemPtr;
    pub const materializeSliceAggregate = typed_pointer_aggregate.materializeSliceAggregate;
    pub const materializeSliceAggregateForLen = typed_pointer_aggregate.materializeSliceAggregateForLen;
    pub const lowerTypedPtrGep = typed_pointer_aggregate.lowerTypedPtrGep;
    pub const lowerTypedRuntimeNavPtr = typed_pointer_aggregate.lowerTypedRuntimeNavPtr;
    pub const lowerTypedArrayElemVal = typed_pointer_aggregate.lowerTypedArrayElemVal;
    pub const lowerTypedFieldPtr = typed_pointer_aggregate.lowerTypedFieldPtr;
    pub const lowerTypedSyntheticUnionFieldPtr = typed_pointer_aggregate.lowerTypedSyntheticUnionFieldPtr;
    pub const lowerTypedSyntheticVectorElemPtr = typed_pointer_aggregate.lowerTypedSyntheticVectorElemPtr;

    pub const lowerTypedAggregateSemanticInstruction = typed_aggregate.lowerTypedAggregateSemanticInstruction;
    pub const lowerTypedAggregateInit = typed_aggregate.lowerTypedAggregateInit;
    pub const lowerTypedStructFieldVal = typed_aggregate.lowerTypedStructFieldVal;

    pub const lowerTypedScalarSemanticInstruction = typed_scalar.lowerTypedScalarSemanticInstruction;
    pub const lowerTypedArg = typed_scalar.lowerTypedArg;
    pub const lowerTypedBinary = typed_scalar.lowerTypedBinary;
    pub const lowerTypedArithmeticWithOverflow = typed_scalar.lowerTypedArithmeticWithOverflow;
    pub const lowerTypedCompare = typed_scalar.lowerTypedCompare;
    pub const lowerTypedCast = typed_scalar.lowerTypedCast;
    pub const lowerTypedByteSwap = typed_scalar.lowerTypedByteSwap;
    pub const lowerTypedMax = typed_scalar.lowerTypedMax;
    pub const lowerTypedMin = typed_scalar.lowerTypedMin;
    pub const lowerTypedAbs = typed_scalar.lowerTypedAbs;
    pub const lowerTypedNeg = typed_scalar.lowerTypedNeg;
    pub const lowerTypedShlSat = typed_scalar.lowerTypedShlSat;
    pub const lowerTypedClz = typed_scalar.lowerTypedClz;
    pub const lowerTypedCtz = typed_scalar.lowerTypedCtz;
    pub const lowerTypedZeroCount = typed_scalar.lowerTypedZeroCount;
    pub const lowerTypedPopcount = typed_scalar.lowerTypedPopcount;
    pub const lowerTypedBitCount = typed_scalar.lowerTypedBitCount;
    pub const lowerTypedBitReverse = typed_scalar.lowerTypedBitReverse;

    pub const lowerTypedVectorSemanticInstruction = typed_vector.lowerTypedVectorSemanticInstruction;
    pub const lowerTypedReduce = typed_vector.lowerTypedReduce;
    pub const lowerTypedSplat = typed_vector.lowerTypedSplat;
    pub const lowerTypedShuffleOne = typed_vector.lowerTypedShuffleOne;

    pub const lowerTypedCall = typed_call.lowerTypedCall;

    pub fn lowerLegacySemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.Instruction,
    ) !bool {
        const lowered = switch (air_capabilities.semanticDomainForOpcode(instruction.opcode)) {
            .scalar => try self.lowerLegacyScalarSemanticInstruction(instruction),
            .memory => try self.lowerLegacyMemorySemanticInstruction(instruction),
            .pointer_aggregate => try self.lowerLegacyPointerAggregateSemanticInstruction(instruction),
            .optional, .error_union, .union_tag, .aggregate, .vector, .none => false,
        };
        return lowered;
    }

    fn lowerLegacyScalarSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.Instruction,
    ) !bool {
        switch (air_capabilities.scalarSemanticOpForOpcode(instruction.opcode)) {
            .arg => try self.lowerArg(instruction),
            .binary => try self.lowerBinary(instruction),
            .compare => try self.lowerCompare(instruction),
            .cast => try self.lowerCast(instruction),
            .add_with_overflow, .sub_with_overflow, .mul_with_overflow, .shl_with_overflow, .byte_swap, .max, .min, .abs, .neg, .shl_sat, .clz, .ctz, .popcount, .bit_reverse, .none => return false,
        }
        return true;
    }

    fn lowerLegacyMemorySemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.Instruction,
    ) !bool {
        switch (air_capabilities.memorySemanticOpForOpcode(instruction.opcode)) {
            .alloc => try self.lowerAlloca(instruction),
            .load => try self.lowerLoad(instruction),
            .store => try self.lowerStore(instruction),
            .none => return false,
        }
        return true;
    }

    fn lowerLegacyPointerAggregateSemanticInstruction(
        self: *LoweringContext,
        instruction: air_export.Instruction,
    ) !bool {
        switch (air_capabilities.pointerAggregateSemanticOpForOpcode(instruction.opcode)) {
            .runtime_nav_ptr => try self.lowerRuntimeNavPtr(instruction),
            .array_elem_val => try self.lowerArrayElemVal(instruction),
            .slice, .array_to_slice, .slice_ptr, .slice_ptr_ptr, .slice_elem_ptr, .slice_len, .slice_len_ptr, .ptr_gep, .field_ptr, .none => return false,
        }
        return true;
    }

    fn lowerArg(self: *LoweringContext, instruction: air_export.Instruction) !void {
        var fields = splitTopLevel(instruction.payload, ',');
        const type_text = fields.next() orelse return error.UnsupportedAir;
        const index_text = fields.next() orelse return error.UnsupportedAir;
        if (fields.next() != null) return error.UnsupportedAir;
        const param_index = std.fmt.parseInt(usize, std.mem.trim(u8, index_text, " "), 10) catch
            return error.UnsupportedAir;
        if (param_index >= self.function_type.params.len) return error.UnsupportedAir;
        const trimmed_type = std.mem.trim(u8, type_text, " ");
        const parsed_type = parseZigType(trimmed_type) orelse
            (self.unusedOpaqueNominalArgType(instruction.index, trimmed_type, param_index) orelse
                return error.UnsupportedAir);
        if (!parsed_type.ir_type.eql(self.function_type.params[param_index].ir_type)) {
            return error.UnsupportedAir;
        }
        self.values[instruction.index] = .{
            .ty = parsed_type,
            .value = .{ .named = self.blockParamName(param_index) },
        };
    }

    pub fn unusedOpaqueNominalArgType(
        self: *LoweringContext,
        instruction_index: u32,
        type_text: []const u8,
        param_index: usize,
    ) ?ZigType {
        if (!isOpaqueNominalTypeSurface(type_text)) return null;
        if (param_index >= self.function_type.params.len) return null;
        if (!self.function_type.params[param_index].ir_type.eql(ir.Type.ptr)) return null;
        if (self.instructionValueUsed(instruction_index)) return null;
        return .{ .ir_type = .ptr };
    }

    pub fn unionTagOnlyOpaqueNominalArgType(
        self: *LoweringContext,
        instruction_index: u32,
        type_text: []const u8,
        param_index: usize,
    ) ?ZigType {
        if (!isOpaqueNominalTypeSurface(type_text)) return null;
        if (param_index >= self.function_type.params.len) return null;
        const param_ty = self.function_type.params[param_index].ir_type;
        if (param_ty != .int) return null;
        const bit_width = self.unionTagOnlyArgBitWidth(instruction_index) orelse return null;
        if (param_ty.int != bit_width) return null;
        return .{ .ir_type = .{ .int = bit_width } };
    }

    pub fn opaqueBitcastNominalArgType(
        self: *LoweringContext,
        instruction_index: u32,
        type_text: []const u8,
        param_index: usize,
    ) ?ZigType {
        if (!isOpaqueNominalTypeSurface(type_text)) return null;
        if (param_index >= self.function_type.params.len) return null;
        const param_ty = self.function_type.params[param_index];
        if (!isScalarBitcastIrType(param_ty.ir_type)) return null;
        const structured_air_v2 = self.structured_air_v2 orelse return null;
        var matched = false;
        for (structured_air_v2.instructions) |instruction| {
            if (!air_capabilities.isBitcastOpcode(instruction.opcode) or instruction.operands.len != 1) continue;
            const operand_index = air_model.typedInstOperandIndex(instruction.operands[0]) orelse continue;
            if (operand_index != instruction_index) continue;
            const result_type = parseZigType(instruction.result_type) orelse continue;
            if (!result_type.ir_type.eql(param_ty.ir_type) or result_type.signed != param_ty.signed) return null;
            matched = true;
        }
        return if (matched) param_ty else null;
    }

    fn isScalarBitcastIrType(ty: ir.Type) bool {
        return switch (ty) {
            .int, .ptr, .float, .double => true,
            .void, .half, .x86_fp80, .fp128, .metadata, .aggregate, .vector => false,
        };
    }

    fn unionTagOnlyArgBitWidth(self: *LoweringContext, instruction_index: u32) ?u16 {
        const structured_air_v2 = self.structured_air_v2 orelse return null;
        var bit_width: ?u16 = null;
        for (structured_air_v2.instructions) |instruction| {
            for (instruction.operands) |operand| {
                const operand_index = air_model.typedInstOperandIndex(operand) orelse continue;
                if (operand_index != instruction_index) continue;
                if (!std.mem.eql(u8, instruction.opcode, "get_union_tag")) return null;
                const summary = air_model.typedUnionTagGetSummary(instruction) orelse return null;
                if (summary.operand_index != instruction_index) return null;
                if (bit_width) |existing| {
                    if (existing != summary.bit_width) return null;
                } else {
                    bit_width = summary.bit_width;
                }
            }
        }
        return bit_width;
    }

    pub fn instructionValueUsed(self: *LoweringContext, instruction_index: u32) bool {
        for (self.air_function.instructions) |instruction| {
            if (instruction.index != instruction_index) continue;
            if (!instruction.unused) return true;
            break;
        }
        if (self.structured_air_v2) |structured_air_v2| {
            for (structured_air_v2.instructions) |instruction| {
                for (instruction.operands) |operand| {
                    const index = air_model.typedInstOperandIndex(operand) orelse continue;
                    if (index == instruction_index) return true;
                }
            }
        }
        return false;
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

    pub fn extendShiftCount(
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

    pub fn lowerCall(self: *LoweringContext, instruction: air_export.Instruction) !void {
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

    pub fn lowerAtomicRmw(self: *LoweringContext, instruction: air_export.Instruction) !void {
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

    pub fn lowerAssembly(self: *LoweringContext, instruction: air_export.Instruction) !void {
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

    pub fn lowerReturn(self: *LoweringContext, instruction: air_export.Instruction) !void {
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
                if (air_capabilities.isBlockOpcode(instruction.opcode) and
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

    pub fn resolveTypedOperand(
        self: *LoweringContext,
        instruction: air_export.TypedInstruction,
        operand_index: usize,
    ) LowerError!TypedValue {
        if (operand_index >= instruction.operands.len) return error.UnsupportedAir;
        const operand = instruction.operands[operand_index];
        if (air_model.typedInstOperandIndex(operand)) |index| {
            if (index >= self.values.len) return error.UnsupportedAir;
            return self.values[index] orelse error.UnsupportedAir;
        }
        if (air_model.typedConstOperandText(instruction, operand_index)) |literal| {
            if (parseSymbolPointer(literal)) |symbol_pointer| {
                return .{
                    .ty = symbol_pointer.ty,
                    .value = .{ .named = try ownPrint(self.module, "@{s}", .{symbol_pointer.symbol}) },
                };
            }
            if (try self.resolveStringLiteralPointer(literal)) |string_pointer| return string_pointer;
            if (try self.resolveStringLiteralSlice(instruction, operand_index, literal)) |string_slice| return string_slice;
            if (parseConstant(literal)) |constant| return constant;
            if (resolveTypedNumericConstOperand(operand)) |constant| return constant;
            return error.UnsupportedAir;
        }
        if (air_model.isTypedNoneOperand(operand)) return error.UnsupportedAir;
        return error.UnsupportedAir;
    }

    fn resolveTypedNumericConstOperand(operand: air_export.TypedOperand) ?TypedValue {
        if (!air_model.isTypedConstOperand(operand)) return null;
        const ty = parseZigType(operand.type_text) orelse return null;
        if (ty.ir_type != .int) return null;
        const value = std.fmt.parseInt(i128, operand.value, 10) catch return null;
        return .{ .ty = ty, .value = .{ .int = value } };
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

    pub fn ensureStringLiteralGlobal(self: *LoweringContext, body: []const u8, byte_len: usize) ![]const u8 {
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
            if (air_capabilities.isCondBrOpcode(instruction.opcode)) {
                var fields = splitTopLevel(instruction.payload, ',');
                condition = try self.resolveValue(fields.next() orelse return error.UnsupportedAir);
            } else if (air_capabilities.isBrOpcode(instruction.opcode)) {
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

    pub fn resultName(self: *LoweringContext, index: u32) ![]const u8 {
        return ownPrint(self.module, "air{}", .{index});
    }

    pub fn blockParamName(self: LoweringContext, index: usize) []const u8 {
        return self.function.params.items[index].name;
    }

    pub fn qualifiedCalleeName(self: *LoweringContext, callee: []const u8) ![]const u8 {
        if (std.mem.indexOfScalar(u8, callee, '.') != null) return callee;
        const dot = std.mem.lastIndexOfScalar(u8, self.air_function.name, '.') orelse return callee;
        return ownPrint(self.module, "{s}.{s}", .{ self.air_function.name[0..dot], callee });
    }
};

fn errorUnionPointerOperandText(type_text: []const u8) bool {
    const child_text = pointerChildText(std.mem.trim(u8, type_text, " ")) orelse return false;
    return isErrorUnionTypeText(child_text);
}

fn typedTryPtrPayloadPointerType(instruction: air_export.TypedInstruction) ?ZigType {
    if (parseZigType(instruction.result_type)) |ty| return ty;
    const detail = air_model.detail(instruction, "payload_ptr_type") orelse return null;
    const trimmed = std.mem.trim(u8, detail, " ");
    if (!std.mem.startsWith(u8, trimmed, "<type,") or !std.mem.endsWith(u8, trimmed, ">")) return null;
    const type_text = std.mem.trim(u8, trimmed["<type,".len .. trimmed.len - 1], " ");
    return parseZigType(type_text);
}

fn switchInputIndexFromAirText(function_air_text: []const u8, switch_index: u32) ?u32 {
    const line = switchLine(function_air_text, switch_index) orelse return null;
    const open = std.mem.indexOfScalar(u8, line, '(') orelse return null;
    const close = std.mem.indexOfScalarPos(u8, line, open + 1, ',') orelse
        std.mem.indexOfScalarPos(u8, line, open + 1, ')') orelse return null;
    return parseInstructionRef(std.mem.trim(u8, line[open + 1 .. close], " !"));
}

fn blockResultTypeFromAirText(function_air_text: []const u8, block_index: u32) ?ZigType {
    const line = blockLine(function_air_text, block_index) orelse return null;
    const block_start = std.mem.indexOf(u8, line, "block(") orelse return null;
    const type_start = block_start + "block(".len;
    var fields = splitTopLevel(line[type_start..], ',');
    const type_text = fields.next() orelse return null;
    return parseZigType(std.mem.trim(u8, type_text, " "));
}

fn collectSwitchCaseValues(
    allocator: std.mem.Allocator,
    values: *std.ArrayList(TypedValue),
    function_air_text: []const u8,
    switch_index: u32,
) !void {
    const text = switchText(function_air_text, switch_index) orelse return error.UnsupportedAir;
    var offset: usize = 0;
    while (std.mem.indexOfPos(u8, text, offset, "[<")) |start| {
        const value_start = start + 1;
        const value_end = std.mem.indexOfPos(u8, text, value_start, "] =>") orelse return error.UnsupportedAir;
        const value = parseConstant(std.mem.trim(u8, text[value_start..value_end], " ")) orelse
            return error.UnsupportedAir;
        try values.append(allocator, value);
        offset = value_end + "] =>".len;
    }
}

fn switchHasElseArm(function_air_text: []const u8, switch_index: u32) bool {
    const text = switchText(function_air_text, switch_index) orelse return false;
    return std.mem.indexOf(u8, text, "else =>") != null;
}

fn switchLine(function_air_text: []const u8, switch_index: u32) ?[]const u8 {
    var needle_buffer: [32]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buffer, "%{}", .{switch_index}) catch return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, function_air_text, start, needle)) |needle_pos| {
        const line_start = std.mem.lastIndexOfScalar(u8, function_air_text[0..needle_pos], '\n') orelse 0;
        const adjusted_start = if (line_start == 0) 0 else line_start + 1;
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, needle_pos, '\n') orelse function_air_text.len;
        const line = function_air_text[adjusted_start..line_end];
        if (std.mem.indexOf(u8, line, "switch_br(") != null) return line;
        start = needle_pos + needle.len;
    }
    return null;
}

fn blockLine(function_air_text: []const u8, block_index: u32) ?[]const u8 {
    var needle_buffer: [32]u8 = undefined;
    const needle = std.fmt.bufPrint(&needle_buffer, "%{}", .{block_index}) catch return null;
    var start: usize = 0;
    while (std.mem.indexOfPos(u8, function_air_text, start, needle)) |needle_pos| {
        const line_start = std.mem.lastIndexOfScalar(u8, function_air_text[0..needle_pos], '\n') orelse 0;
        const adjusted_start = if (line_start == 0) 0 else line_start + 1;
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, needle_pos, '\n') orelse function_air_text.len;
        const line = function_air_text[adjusted_start..line_end];
        if (std.mem.indexOf(u8, line, "block(") != null) return line;
        start = needle_pos + needle.len;
    }
    return null;
}

fn switchText(function_air_text: []const u8, switch_index: u32) ?[]const u8 {
    const line = switchLine(function_air_text, switch_index) orelse return null;
    const start = @intFromPtr(line.ptr) - @intFromPtr(function_air_text.ptr);
    var pos = start;
    while (pos < function_air_text.len) {
        const line_end = std.mem.indexOfScalarPos(u8, function_air_text, pos, '\n') orelse function_air_text.len;
        const candidate = function_air_text[pos..line_end];
        if (std.mem.eql(u8, std.mem.trim(u8, candidate, " \t"), ")")) {
            return function_air_text[start..line_end];
        }
        if (line_end == function_air_text.len) break;
        pos = line_end + 1;
    }
    return null;
}

test "typed switch case parsing supports typed constants and exhaustive switches" {
    const text =
        \\  %10!= switch_br(%0!, [<error{BadTag,WorseTag}, error.BadTag>] => {
        \\      %7!= br(%3, <i32, -44>)
        \\    }, [<error{BadTag,WorseTag}, error.WorseTag>] => {
        \\      %9!= br(%3, <i32, -45>)
        \\    }
        \\    )
    ;
    var values: std.ArrayList(TypedValue) = .empty;
    defer values.deinit(std.testing.allocator);

    try collectSwitchCaseValues(std.testing.allocator, &values, text, 10);

    try std.testing.expectEqual(@as(usize, 2), values.items.len);
    try std.testing.expect(values.items[0].ty.ir_type.eql(.{ .int = 16 }));
    try std.testing.expect(values.items[1].ty.ir_type.eql(.{ .int = 16 }));
    try std.testing.expectEqual(@as(i128, 1), values.items[0].value.int);
    try std.testing.expectEqual(@as(i128, 2), values.items[1].value.int);
    try std.testing.expect(!switchHasElseArm(text, 10));
}

test "typed switch case parsing preserves i32 else cases" {
    const text =
        \\  %26!= switch_br(%11!, [<i32, 0>] => {
        \\      %17!= br(%13, %16!)
        \\    }, [<i32, 1>] => {
        \\      %21!= br(%13, %20!)
        \\    }, else => {
        \\      %25!= br(%13, %24!)
        \\    }
        \\    )
    ;
    var values: std.ArrayList(TypedValue) = .empty;
    defer values.deinit(std.testing.allocator);

    try collectSwitchCaseValues(std.testing.allocator, &values, text, 26);

    try std.testing.expectEqual(@as(usize, 2), values.items.len);
    try std.testing.expect(values.items[0].ty.ir_type.eql(.{ .int = 32 }));
    try std.testing.expect(values.items[1].ty.ir_type.eql(.{ .int = 32 }));
    try std.testing.expectEqual(@as(i128, 0), values.items[0].value.int);
    try std.testing.expectEqual(@as(i128, 1), values.items[1].value.int);
    try std.testing.expect(switchHasElseArm(text, 26));
}

test "typed block result parser preserves error-set commas" {
    const error_union_text =
        \\  %3 = block(error{BadTag,WorseTag}!i32, {
        \\  } %0!)
    ;
    const error_union_ty = blockResultTypeFromAirText(error_union_text, 3) orelse return error.TestExpectedEqual;
    try std.testing.expect(error_union_ty.ir_type.eql(.{ .int = 64 }));

    const scalar_text =
        \\  %17 = block(i32, {
        \\  } %14!)
    ;
    const scalar_ty = blockResultTypeFromAirText(scalar_text, 17) orelse return error.TestExpectedEqual;
    try std.testing.expect(scalar_ty.ir_type.eql(.{ .int = 32 }));
}

test "typed switch text parser handles nested switch indentation" {
    const text =
        \\    %17 = block(i32, {
        \\      %20!= switch_br(%14!, [<error{BadTag,WorseTag}, error.BadTag>] => {
        \\          %18!= br(%17, <i32, -44>)
        \\        }, [<error{BadTag,WorseTag}, error.WorseTag>] => {
        \\          %19!= br(%17, <i32, -45>)
        \\        }
        \\      )
        \\    } %14!)
    ;
    const extracted = switchText(text, 20) orelse return error.TestExpectedEqual;
    try std.testing.expect(std.mem.indexOf(u8, extracted, "error.WorseTag") != null);

    var values: std.ArrayList(TypedValue) = .empty;
    defer values.deinit(std.testing.allocator);
    try collectSwitchCaseValues(std.testing.allocator, &values, text, 20);
    try std.testing.expectEqual(@as(usize, 2), values.items.len);
    try std.testing.expect(values.items[0].ty.ir_type.eql(.{ .int = 16 }));
    try std.testing.expect(values.items[1].ty.ir_type.eql(.{ .int = 16 }));
}
