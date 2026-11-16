const std = @import("std");
const builtin = @import("builtin");
const ir = @import("../../../../ir.zig");
const x86_64_machine = @import("../../machine.zig");
const x86_64_types = @import("../../types.zig");
const selector_types = @import("../selector_types.zig");
const state_data = @import("../composed_selector_state_data.zig");
const selector_state = @import("../composed_selector_state.zig");
const stage2_planning = @import("../stage2_planning.zig");
const address_dependencies = @import("../composed_selector_address_dependencies.zig");
const eflags = @import("../composed_selector_eflags.zig");
const constant_table = @import("../../constant_table.zig");
const aggregate_object = @import("../aggregate_object.zig");
const composed_helpers = @import("../composed_helpers.zig");
const Diagnostic = @import("../inspection.zig").Diagnostic;

const ArgReg = x86_64_types.ArgReg;
const FrameIndex = x86_64_types.FrameIndex;
const RegPair = selector_types.RegPair;
const ValueBinding = selector_types.ValueBinding;
const ValueLoc = selector_types.ValueLoc;
const VirtualReg = selector_types.VirtualReg;
const VirtualRegClass = selector_types.VirtualRegClass;
const ComposedBlockSelector = state_data.ComposedBlockSelector;
const AddressDependencyDomain = address_dependencies.AddressDependencyDomain;
const AccumulatorDefinition = selector_state.AccumulatorDefinition;
const AccumulatorDefinitionSession = selector_state.AccumulatorDefinitionSession;
const AccumulatorDisplacementPolicy = selector_state.AccumulatorDisplacementPolicy;
const AccumulatorPreparationEffect = selector_state.AccumulatorPreparationEffect;

fn optionalPreparedActionEql(
    lhs: ?PreparedAction,
    rhs: ?PreparedAction,
) bool {
    if ((lhs == null) != (rhs == null)) return false;
    return if (lhs) |action| action.eql(rhs.?) else true;
}

pub const max_requests = 16;
// Original compiler control labels reach 406 bytes. Keep a bounded, owned
// identity with enough headroom for generated suffixes and no truncation.
pub const max_identity_bytes = 512;
pub const address_domain_snapshot_copies: usize = 1;
pub const address_domain_copies_per_request: usize = 0;
pub const address_domain_snapshot_bytes: usize = @sizeOf(AddressDependencyDomain);
pub const Expected = struct {
    ty: ir.Type,
    register_class: VirtualRegClass,
    pointer_address_space: ?u32 = null,

    pub fn eql(expected: Expected, other: Expected) bool {
        return expected.ty.eql(other.ty) and
            expected.register_class == other.register_class and
            expected.pointer_address_space == other.pointer_address_space;
    }
};

pub const UseForm = enum {
    gpr32,
    gpr64,
    pointer,
    /// Action-only bounded descriptor view. It is accepted exclusively by
    /// form_byte_address and is never a generic pointer materialization.
    stack_f32_pair_byte_address,
    stack_object_address,
    pair_low_high,
    pair_high_low,
    /// Exact legacy branch-condition homes only. This is intentionally
    /// narrower than the generic semantic low32 relation.
    branch_condition,
    /// Exact legacy compare-chain switch homes, including the read-only
    /// low limb of an existing pair and an action-owned immediate.
    switch_condition,
    /// Exact legacy inline-memcpy pointer homes. This action-specific form
    /// deliberately excludes generic stack/table/null pointer capability.
    memcpy_pointer,
    /// Exact legacy inline-memcpy i64 length homes.
    memcpy_length,
    /// Action-only load address. Compatibility is derived from the
    /// closed load action and canonical binding/home; consumers neither
    /// discover nor choose a physical source representation.
    load_address,
    /// Action-only scalar/pointer compare operand. The closed compare
    /// action derives the accepted low view and fixed scratch assignment;
    /// this form grants no generic materialization capability.
    scratch_compare_operand,
    /// Action-only generic integer eq-zero current-home test. The action
    /// classifies the canonical post-preamble home internally and grants
    /// no generic scalar materialization or prepared-location access.
    current_home_eq_zero_operand,
    /// Action-only named operand for the closed setcc-producing EAX
    /// compare family. The action owns canonical post-preamble
    /// re-resolution and never exposes the current home.
    setcc_eax_compare_operand,
    /// Action-only i32/i64 sign-bit extraction operand. The action derives
    /// the accumulator width, current-home preservation, and logical
    /// shift internally without exposing a physical source view.
    current_home_sign_bit_operand,
    /// Action-only read-only i128 source. The closed pair-wrapper actions
    /// admit only existing arg128, scratch128, and stack128-value homes;
    /// notably, this is not the broader generic pair/spill capability.
    i128_icmp_pair_operand,
    /// Action-only read-only i128 source for extracting the low scalar limb.
    /// The action owns scratch selection and grants no pair-result capability.
    pair_low_scalar_cast_operand,
    /// Action-only scalar source for the closed accumulator-producing cast
    /// family. Named and typed-immediate sources are validated internally.
    accumulator_scalar_cast_operand,
    /// Action-only i32 source for the exact sessionless sign-extension cast.
    /// Only canonical G32/S32 homes are admitted by the action.
    sign_extend_scratch_operand,
    /// Action-only named lhs for a closed scalar operation with an inline
    /// typed rhs literal. The action owns all physical staging decisions.
    immediate_rhs_scalar_operand,
    /// Action-only named rhs for a closed scalar operation with an inline
    /// typed lhs literal. The action owns all physical staging decisions.
    immediate_lhs_scalar_operand,
    /// Action-only named operand for the closed named-scalar and exact-i52
    /// families. The action owns canonical resolution and all staging.
    named_scalar_operand,
    stack_argument,
    new_pair_ownership,
};

pub const Destination = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    eax,
    rax,
    pair: RegPair,
    prepared_source,
    prepared_view,
    stack_argument: u32,
    new_pair,

    pub fn eql(destination: Destination, other: Destination) bool {
        if (std.meta.activeTag(destination) != std.meta.activeTag(other)) return false;
        return switch (destination) {
            .gpr32 => |reg| reg == other.gpr32,
            .gpr64 => |reg| reg == other.gpr64,
            .pair => |pair| pair.eql(other.pair),
            .stack_argument => |slot| slot == other.stack_argument,
            .eax, .rax, .prepared_source, .prepared_view, .new_pair => true,
        };
    }
};

/// Opaque transaction-local identity. It contains no resolved location and
/// is invalid outside the authority that returned it.
pub const RequestHandle = struct {
    authority: usize,
    index: u8,
    generation: u32,
};

/// Opaque identity for the snapshot-free accumulator state-transition
/// session owned by this instruction authority.
pub const AccumulatorSessionHandle = struct {
    authority: usize,
    generation: u32,
};

/// Phase-bound capability for executing one sealed prepared action. It
/// contains no source location or representation.
pub const PreparedViewLease = struct {
    request: RequestHandle,
    view_generation: u32,
};

/// Inline-owned semantic identity for a sealed action. Callers provide a
/// name, never storage discovered from selector state.
pub const ActionIdentity = struct {
    bytes: [max_identity_bytes]u8 = @splat(0),
    len: u16 = 0,

    pub fn init(name: []const u8) !ActionIdentity {
        if (name.len == 0) return error.ValueUseEmptyIdentity;
        if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
        var identity: ActionIdentity = .{};
        @memcpy(identity.bytes[0..name.len], name);
        identity.len = @intCast(name.len);
        return identity;
    }

    pub fn slice(identity: *const ActionIdentity) []const u8 {
        return identity.bytes[0..identity.len];
    }

    pub fn validate(identity: *const ActionIdentity) !void {
        if (identity.len == 0) return error.ValueUseEmptyIdentity;
        if (identity.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
    }
};

pub const AddressOffset = union(enum) {
    constant: i32,
    request: RequestHandle,
};

/// Closed source-view contracts used by validation actions. Every field is
/// caller-supplied intent; the authority never returns discovered storage.
pub const PreparedShape = union(enum) {
    register_gpr32: ArgReg,
    register_gpr64: ArgReg,
    register_eax,
    register_rax,
    scalar_spill: FrameIndex,
    stack_scalar: u32,
    stack_integer128: u32,
    stack_i32_array: selector_types.StackArrayLoc,
    address_descriptor: struct { has_index: bool, has_addend: bool },
    table_register: ArgReg,
    table_spill: FrameIndex,
    pair_register: RegPair,
    pair_spill: selector_types.PairSpillLoc,
};

pub const ByteAddressAction = struct {
    result: ActionIdentity,
    offset: AddressOffset,
};

pub const ScaledAddressAction = struct {
    result: ActionIdentity,
    index: AddressOffset,
    scale: u8,
    expected_stack_array_len: ?u32 = null,
};

pub const ReadOnlyTableAddressAction = struct {
    result: ActionIdentity,
    symbol: ActionIdentity,
    shape: constant_table.Description,
    scale: u8,
};

/// Store a named i1/i32 value. The action is owned by the value request;
/// the pointer is the semantic secondary operand, preserving the accepted
/// value-before-address staging order.
pub const StoreScalarAction = struct {
    pointer: RequestHandle,
    bits: u8,
};

/// Store an inline scalar value through 64 bits. The immediate is semantic
/// intent rather than a discovered home and precedes pointer staging.
pub const StoreImmediateAction = struct {
    value: i64,
    bits: u8,
};

/// Store a named i64 or runtime pointer value. The destination request owns
/// the action; a typed frame slot denotes storage, never its stored value.
/// Register/spilled destinations retain pointer-before-value staging.
pub const StoreI64Action = struct {
    value: RequestHandle,
};

/// Store the address of one stack object into another stack object. Both
/// operands are semantic requests; no stack descriptor escapes.
pub const StoreStackPointerAction = struct {
    destination: RequestHandle,
};

/// Complete inline-memcpy semantic intent. The action is owned by the
/// destination-pointer request; source and length are already-registered
/// operands. No discovered home, call result, or general-call detail is
/// supplied by the consumer.
pub const MemcpyAction = struct {
    source: RequestHandle,
    length: ?RequestHandle = null,
    length_immediate: u64 = 0,
    may_overlap: bool = false,
};

/// Byte fill with named operands or typed immediate values. The destination
/// request owns the action; physical staging stays inside the authority.
pub const MemsetAction = struct {
    fill: ?RequestHandle = null,
    fill_immediate: u8 = 0,
    length: ?RequestHandle = null,
    length_immediate: u64 = 0,
};

pub const MemcpyTestFailure = enum {
    after_preservation,
    after_destination,
    after_source,
    after_length,
    after_call_append,
};

/// Complete semantic intent for the admitted ordinary direct-call envelope.
/// Handles and declared types are copied into fixed transaction-owned storage;
/// no discovered home, ABI destination, or staging order crosses this boundary.
pub const DirectCallAction = struct {
    symbol: ActionIdentity,
    result: ?ActionIdentity,
    return_type: ir.Type,
    arguments: [max_requests]RequestHandle = undefined,
    argument_types: [max_requests]ir.Type = undefined,
    argument_count: u8 = 0,

    pub fn init(
        symbol: []const u8,
        result: ?[]const u8,
        return_type: ir.Type,
        arguments: []const RequestHandle,
        argument_types: []const ir.Type,
    ) !DirectCallAction {
        if (arguments.len != argument_types.len or arguments.len > max_requests)
            return error.ValueUseCallArgumentCountUnsupported;
        var action: DirectCallAction = .{
            .symbol = try ActionIdentity.init(symbol),
            .result = if (result) |name| try ActionIdentity.init(name) else null,
            .return_type = return_type,
        };
        @memcpy(action.arguments[0..arguments.len], arguments);
        @memcpy(action.argument_types[0..argument_types.len], argument_types);
        action.argument_count = @intCast(arguments.len);
        return action;
    }
};

/// Closed semantic intent for `zig.target.intByteSize`.
pub const IntByteSizeCallAction = struct {
    symbol: ActionIdentity,
    result: ActionIdentity,
    argument: RequestHandle,

    pub fn init(symbol: []const u8, result: []const u8, argument: RequestHandle) !IntByteSizeCallAction {
        return .{
            .symbol = try ActionIdentity.init(symbol),
            .result = try ActionIdentity.init(result),
            .argument = argument,
        };
    }
};

/// Request-attributable call failures expose only the frozen semantic class.
pub const CallRequestError = error{
    ValueUseCallArgumentNotNamed,
    ValueUseCallArgumentTypeUnsupported,
    ValueUseCallArgumentWidthUnsupported,
    ValueUseCallArgumentLocationUnsupported,
    ValueUseCallPointerLocationUnsupported,
    ValueUseCallStackDisplacementUnsupported,
};

pub const ScalarLoadKind = enum {
    ordinary,
    readonly_pointer,
};

/// A genuine EAX/RAX integer load. Result ownership remains with the
/// subordinate accumulator session; this action owns only the complete
/// source-home-dependent load sequence.
pub const ScalarLoadAction = struct {
    kind: ScalarLoadKind,
    bits: u16,
    is_ptr: bool = false,
};

/// Existing readonly-pointer i96/i128 result semantics. The planner
/// freezes the pair selected by the pre-existing pair authority; the
/// action neither allocates a new pair kind nor changes result ownership.
pub const ReadOnlyPairLoadAction = struct {
    result: ActionIdentity,
    bits: u16,
};

/// Alias-only i128 load from an existing stack object.
pub const StackI128AliasLoadAction = struct {
    result: ActionIdentity,
};

/// Non-accumulator i16 table load into the accepted R8 scratch result.
pub const ReadOnlyTableI16LoadAction = struct {
    result: ActionIdentity,
};

/// Closed, semantic load-request failures. These variants disclose only
/// the accepted diagnostic class; no source home, binding, register, spill
/// slot, or retry capability crosses the transaction boundary.
pub const LoadRequestError = error{
    ValueUseLoadOrdinaryStackWidth,
    ValueUseLoadOrdinaryStackArrayWidth,
    ValueUseLoadOrdinaryPointerWidth,
    ValueUseLoadOrdinaryPointerRejected,
    ValueUseLoadReadonlyPointerProvenance,
    ValueUseLoadReadonlyPointerSpill,
    ValueUseLoadReadonlyPointerAlias,
    ValueUseLoadReadonlyWidth,
    ValueUseLoadReadonlyPairUnavailable,
    ValueUseLoadReadonlyTableOffset,
    ValueUseLoadReadonlyTableType,
    ValueUseLoadReadonlyTableSpill,
};

pub const LoadTestFailure = enum {
    after_pointer_staging,
    after_preservation,
    after_first_partial_load,
};

pub const ScratchCompareRhs = union(enum) {
    immediate: i128,
    null_pointer,
    named: RequestHandle,
};

/// Complete fixed-scratch scalar/pointer compare intent. No physical
/// register, source home, or staging order crosses this public boundary.
pub const ScratchCompareAction = struct {
    result: ActionIdentity,
    operand_ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    rhs: ScratchCompareRhs,
};

pub const ScratchCompareTestFailure = enum {
    after_first_accumulator_preservation,
    after_canonical_view_refresh,
    after_lhs_staging,
    after_rhs_staging,
    after_immediate_staging,
    after_lhs_normalize_shl,
    after_lhs_normalize_sar,
    after_rhs_normalize_shl,
    after_rhs_normalize_sar,
    after_accumulator_preparation,
    after_flags_definition,
    after_setcc,
    after_result_identity_ownership,
    after_result_definition,
    after_result_finalization,
};

/// Generic integer eq-zero current-home intent. No predicate, physical
/// home, register, staging choice, or displacement policy is supplied by
/// the consumer.
pub const CurrentHomeEqZeroAction = struct {
    result: ActionIdentity,
    operand_ty: ir.Type,
};

/// Closed request-attributable diagnostic classes for the I13 action.
/// Resolution retains ValueUseUnresolvedSource; these two variants
/// distinguish the accepted width and location diagnostics without
/// exposing the underlying home or binding.
pub const CurrentHomeEqZeroRequestError = error{
    ValueUseCurrentHomeEqZeroWidthUnsupported,
    ValueUseCurrentHomeEqZeroLocationUnsupported,
};

pub const CurrentHomeEqZeroTestFailure = enum {
    after_test_definition,
    after_accumulator_preparation,
};

pub const SetccEaxCompareStructure = enum {
    ordinary,
    exact_ei,
};

/// Closed semantic intent for setcc-producing EAX comparisons. Immediate
/// values remain semantic; no physical home, register, displacement, or
/// sequencing choice crosses this boundary.
pub const SetccEaxCompareAction = struct {
    result: ActionIdentity,
    operand_ty: ir.Type,
    predicate: ir.IcmpPredicate,
    samesign: bool,
    immediate: i128,
    structure: SetccEaxCompareStructure,
};

pub const SetccEaxCompareRequestError = error{
    ValueUseSetccEaxCompareWidthUnsupported,
    ValueUseSetccEaxCompareLocationUnsupported,
};

pub const SetccEaxCompareTestFailure = enum {
    after_preamble,
    after_materialization,
    after_normalization_or_mask,
    after_eflags_definition,
    after_accumulator_preparation,
    after_setcc,
    after_result_definition,
    after_finalization,
};

/// Closed semantic intent for i32/i64 sign-bit extraction or its complement.
/// The operand type determines EAX/RAX and the logical shift count.
pub const CurrentHomeSignBitAction = struct {
    result: ActionIdentity,
    operand_ty: ir.Type,
    invert: bool = false,
};

/// Pure future-dispatch classifier. It observes only the ICMP semantic
/// form and admits `slt/sge i32/i64 <named>, 0`.
pub const CurrentHomeSignBitRequestError = error{
    ValueUseCurrentHomeSignBitWidthUnsupported,
    ValueUseCurrentHomeSignBitLocationUnsupported,
};

pub const CurrentHomeSignBitTestFailure = enum {
    after_global_preamble,
    after_current_home_preservation,
    after_materialization,
    after_accumulator_preparation,
    after_shift,
    after_result_definition,
    after_finalization,
};

/// Closed result identity for the exact `eq i128 lhs, minInt(i128)`
/// wrapper. Predicate, constant, pair choice, and physical homes remain
/// internal to the action and its future pure semantic dispatcher.
pub const I128EqMinAction = struct {
    result: ActionIdentity,
};

/// Closed result identity for the exact `slt i128 lhs, 0` high-limb
/// wrapper. The action owns the logical SHR and exposes no pair state.
pub const I128SignBitAction = struct {
    result: ActionIdentity,
};

pub const I128PairRequestError = error{
    ValueUseI128PairWidthUnsupported,
    ValueUseI128PairLocationUnsupported,
};

pub const I128EqMinTestFailure = enum {
    after_preamble,
    after_canonical_refresh,
    after_pair_selection,
    after_pair_materialization,
    after_accumulator_preparation,
    after_temp_clobber,
    after_high_to_rax,
    after_min_int,
    after_xor,
    after_or,
    after_temp_copy,
    after_cmp,
    after_sete,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const I128SignBitTestFailure = enum {
    after_preamble,
    after_canonical_refresh,
    after_high_limb_load,
    after_accumulator_preparation,
    after_shift,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const PairLowScalarCastAction = struct {
    result: ActionIdentity,
    op: ir.CastOp,
    from_bits: u16,
    to_bits: u16,
};

pub const AccumulatorScalarCastAction = struct {
    result: ActionIdentity,
    op: ir.CastOp,
    from_bits: u16,
    to_bits: u16,
    immediate: ?i128 = null,
    exact_ei: bool = false,
};

pub const SignExtendScratchAction = struct {
    result: ActionIdentity,
};

pub const ScalarCastRequestError = error{
    ValueUseScalarCastFormUnsupported,
    ValueUseScalarCastWidthUnsupported,
    ValueUseScalarCastLocationUnsupported,
    ValueUseScalarCastImmediateMismatch,
    ValueUseScalarCastScratchUnavailable,
};

pub const ScalarCastTestFailure = enum {
    after_scratch_selection,
    after_pair_staging,
    after_accumulator_preparation,
    after_accumulator_materialization,
    after_mask_materialization,
    after_mask,
    after_sign_extend,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const ImmediateRhsScalarAction = struct {
    result: ActionIdentity,
    operation: ir.BinaryOp,
    integer_ty: ir.Type,
    literal: i128,
};

pub const ImmediateLhsScalarAction = struct {
    result: ActionIdentity,
    operation: ir.BinaryOp,
    integer_ty: ir.Type,
    literal: i128,
};

pub const ImmediateScalarRequestError = error{
    ValueUseImmediateScalarFormUnsupported,
    ValueUseImmediateScalarWidthUnsupported,
    ValueUseImmediateScalarLocationUnsupported,
    ValueUseImmediateScalarLiteralOutOfRange,
    ValueUseImmediateScalarScratchUnavailable,
};

pub const ImmediateScalarTestFailure = enum {
    after_preservation,
    after_canonical_refresh,
    after_scratch_selection,
    after_rcx_staging,
    after_accumulator_preparation,
    after_eax_staging,
    after_rax_staging,
    after_first_instruction,
    after_second_instruction,
    after_third_instruction,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const NamedScalarBinaryAction = struct {
    result: ActionIdentity,
    operation: ir.BinaryOp,
    integer_ty: ir.Type,
    exact_ei: bool,
    rhs: RequestHandle,
};

pub const ExactI52BinaryAction = struct {
    result: ActionIdentity,
    rhs: RequestHandle,
};

pub const NamedScalarRequestError = error{
    ValueUseNamedScalarFormUnsupported,
    ValueUseNamedScalarWidthUnsupported,
    ValueUseNamedScalarLocationUnsupported,
    ValueUseNamedScalarScratchUnavailable,
    ValueUseNamedScalarExactEiUnsupported,
    ValueUseNamedScalarI52EnvelopeUnsupported,
};

pub const NamedScalarTestFailure = enum {
    after_preamble,
    after_canonical_refresh,
    after_first_operand_staging,
    after_accumulator_preparation,
    after_second_operand_staging,
    after_first_arithmetic_write,
    after_second_arithmetic_write,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const ScalarMultiplyAction = struct {
    result: ActionIdentity,
    integer_ty: ir.Type,
    rhs: RequestHandle,
};

pub const ScalarMultiplyRequestError = error{
    ValueUseScalarMultiplyFormUnsupported,
    ValueUseScalarMultiplyWidthUnsupported,
    ValueUseScalarMultiplyLocationUnsupported,
    ValueUseScalarMultiplyDestinationUnavailable,
};

pub const ScalarMultiplyTestFailure = enum {
    after_destination_selection,
    after_lhs_preservation,
    after_canonical_refresh,
    after_lhs_staging,
    after_rhs_resolution,
    after_rhs_staging,
    after_accumulator_preparation,
    after_lhs_accumulator_reload,
    after_multiply,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

pub const UnsignedQuotientAction = struct {
    result: ActionIdentity,
    integer_ty: ir.Type,
    rhs: RequestHandle,
};

pub const UnsignedQuotientRequestError = error{
    ValueUseUnsignedQuotientFormUnsupported,
    ValueUseUnsignedQuotientWidthUnsupported,
    ValueUseUnsignedQuotientLocationUnsupported,
};

pub const UnsignedQuotientTestFailure = enum {
    after_rhs_classification,
    after_rhs_accumulator_staging,
    after_accumulator_preparation,
    after_lhs_materialization,
    after_rhs_non_accumulator_staging,
    after_rdx_preservation,
    after_zero_high_dividend,
    after_divide,
    after_result_identity_ownership,
    after_result_definition,
    after_finalization,
};

/// Pure future-dispatch classifier for the exact pair equality form.
pub const max_switch_cases = 8;

pub const SwitchCaseIntent = struct {
    value: i32,
    target: []const u8,
};

/// Fixed-owned compare-chain semantics. Input target slices are copied by
/// init; no borrowed case/target storage survives registration.
pub const SwitchCompareChainAction = struct {
    bits: u8,
    case_count: u8,
    case_values: [max_switch_cases]i32 = @splat(0),
    case_targets: [max_switch_cases]ActionIdentity = @splat(.{}),
    default_target: ActionIdentity,
    exhaustive_case: ?u8 = null,

    pub fn init(
        bits: u8,
        cases: []const SwitchCaseIntent,
        default_target: []const u8,
        exhaustive_case: ?u8,
    ) !SwitchCompareChainAction {
        if (bits == 0 or bits > 32) return error.ValueUseSwitchWidthUnsupported;
        if (cases.len == 0 or cases.len > max_switch_cases)
            return error.ValueUseSwitchCaseCountUnsupported;
        var result = SwitchCompareChainAction{
            .bits = bits,
            .case_count = @intCast(cases.len),
            .default_target = try ActionIdentity.init(default_target),
            .exhaustive_case = exhaustive_case,
        };
        for (cases, 0..) |case, index| {
            for (result.case_values[0..index]) |previous| {
                if (previous == case.value) return error.ValueUseSwitchDuplicateCase;
            }
            result.case_values[index] = case.value;
            result.case_targets[index] = try ActionIdentity.init(case.target);
        }
        if (exhaustive_case) |index| {
            if (index >= cases.len) return error.ValueUseSwitchExhaustiveCaseOutOfRange;
        }
        return result;
    }

    pub fn validate(action: *const SwitchCompareChainAction) !void {
        if (action.bits == 0 or action.bits > 32) return error.ValueUseSwitchWidthUnsupported;
        if (action.case_count == 0 or action.case_count > max_switch_cases)
            return error.ValueUseSwitchCaseCountUnsupported;
        try action.default_target.validate();
        for (0..action.case_count) |index| {
            try action.case_targets[index].validate();
            for (action.case_values[0..index]) |previous| {
                if (previous == action.case_values[index])
                    return error.ValueUseSwitchDuplicateCase;
            }
        }
        if (action.exhaustive_case) |index| {
            if (index >= action.case_count) return error.ValueUseSwitchExhaustiveCaseOutOfRange;
        }
    }
};

/// A complete, typed operation over a prepared source. This descriptor is
/// registered before seal, so every physical destination participates in
/// conflict, preservation, and cycle planning. No variant exposes source
/// storage to its caller.
pub const PreparedAction = union(enum) {
    validate_shape: PreparedShape,
    emit_copy_to: CopyDestination,
    form_byte_address: ByteAddressAction,
    form_scaled_address: ScaledAddressAction,
    form_readonly_table_address: ReadOnlyTableAddressAction,
    store_scalar: StoreScalarAction,
    store_immediate: StoreImmediateAction,
    store_i64: StoreI64Action,
    store_stack_pointer: StoreStackPointerAction,
    branch_condition,
    switch_compare_chain: SwitchCompareChainAction,
    inline_memcpy: MemcpyAction,
    inline_memset: MemsetAction,
    load_scalar: ScalarLoadAction,
    load_readonly_pair: ReadOnlyPairLoadAction,
    load_stack_i128_alias: StackI128AliasLoadAction,
    load_readonly_table_i16: ReadOnlyTableI16LoadAction,
    scratch_compare: ScratchCompareAction,
    current_home_eq_zero: CurrentHomeEqZeroAction,
    setcc_eax_compare: SetccEaxCompareAction,
    current_home_sign_bit: CurrentHomeSignBitAction,
    i128_eq_min: I128EqMinAction,
    i128_sign_bit: I128SignBitAction,
    pair_low_scalar_cast: PairLowScalarCastAction,
    accumulator_scalar_cast: AccumulatorScalarCastAction,
    sign_extend_scratch: SignExtendScratchAction,
    immediate_rhs_scalar: ImmediateRhsScalarAction,
    immediate_lhs_scalar: ImmediateLhsScalarAction,
    named_scalar_binary: NamedScalarBinaryAction,
    exact_i52_binary: ExactI52BinaryAction,
    scalar_multiply: ScalarMultiplyAction,
    unsigned_quotient: UnsignedQuotientAction,
    direct_call: DirectCallAction,
    int_byte_size_call: IntByteSizeCallAction,

    pub fn eql(action: PreparedAction, other: PreparedAction) bool {
        return std.meta.eql(action, other);
    }
};

pub const CopyDestination = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    eax,
    rax,

    pub fn asDestination(copy_destination: CopyDestination) Destination {
        return switch (copy_destination) {
            .gpr32 => |reg| .{ .gpr32 = reg },
            .gpr64 => |reg| .{ .gpr64 = reg },
            .eax => .eax,
            .rax => .rax,
        };
    }
};

pub const PreparedIdentity = struct {
    bytes: [max_identity_bytes]u8 = undefined,
    len: u16 = 0,

    pub fn init(name: []const u8) !PreparedIdentity {
        if (name.len == 0) return error.ValueUseEmptyIdentity;
        if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
        var identity: PreparedIdentity = .{};
        @memcpy(identity.bytes[0..name.len], name);
        identity.len = @intCast(name.len);
        return identity;
    }

    pub fn slice(identity: *const PreparedIdentity) []const u8 {
        return identity.bytes[0..identity.len];
    }

    pub fn eql(identity: *const PreparedIdentity, other: *const PreparedIdentity) bool {
        return std.mem.eql(u8, identity.slice(), other.slice());
    }
};

pub const PreparedRegister = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    eax,
    rax,
};

pub const PreparedScalarHome = union(enum) {
    register: PreparedRegister,
    spill: FrameIndex,
};

pub const PreparedStackObject = union(enum) {
    scalar: selector_types.StackScalarLoc,
    integer128: u32,
    integer32_array: selector_types.StackArrayLoc,
};

pub const PreparedAddressComponent = struct {
    identity: PreparedIdentity,
    role: AddressDependencyDomain.Role,
    home: PreparedScalarHome,
    vreg: VirtualReg,
};

pub const PreparedAddressDescriptor = struct {
    disp: u32,
    index: ?PreparedAddressComponent = null,
    addend: ?PreparedAddressComponent = null,
};

pub const PreparedStackF32PairAddress = struct {
    object_base_disp: u32,
    disp: u32,
};

pub const PreparedTablePointer = struct {
    storage: union(enum) { register: ArgReg, spill: FrameIndex },
    symbol: PreparedIdentity,
    shape: constant_table.Description,
    offset: u8,
};

pub const PreparedPairLimb = union(enum) {
    register: ArgReg,
    spill: FrameIndex,
};

pub const PreparedReadOnlyPair = struct {
    first: PreparedPairLimb,
    second: PreparedPairLimb,
};

pub const PreparedCondition = union(enum) {
    eax,
    rax_low32,
    register32: ArgReg,
    register64_low32: ArgReg,
    pair_low32: ArgReg,
    spill_low32: FrameIndex,
    immediate: i32,
};

/// Restricted source-derived representation. No raw ValueLoc, binding, or
/// borrowed identity escapes the instruction-level authority.
pub const PreparedView = union(enum) {
    register: struct { register: PreparedRegister, bits: u16 },
    spill: struct { frame_index: FrameIndex, bits: u16 },
    stack_object: PreparedStackObject,
    address_descriptor: PreparedAddressDescriptor,
    stack_f32_pair_address: PreparedStackF32PairAddress,
    table_pointer: PreparedTablePointer,
    read_only_pair: PreparedReadOnlyPair,
    condition: PreparedCondition,
    current_home_eq_zero: struct { bits: u16 },
    setcc_eax_compare: struct { bits: u16 },
    current_home_sign_bit: struct { bits: u16 },
    i128_icmp_pair: void,
    pair_low_scalar_cast: void,
    accumulator_scalar_cast: void,
    sign_extend_scratch: void,
    immediate_rhs_scalar: void,
    immediate_lhs_scalar: void,
};

pub const PreparedRecord = struct {
    view: PreparedView,
    source_vreg: VirtualReg,
    canonical_source_loc: ValueLoc,
};

pub const EarlyPlan = struct {
    destination: ?ArgReg = null,
};

pub const OperandPhase = enum {
    no_op,
    safe_early,
    ordinary,
};

pub const OrderedOperand = struct {
    request_index: u8,
    role: SemanticRole,
    phase: OperandPhase,
};

pub const SemanticRole = enum(u8) {
    primary,
    secondary,
    tertiary,
};

pub const EarlyPreparedHome = struct {
    loc: ValueLoc,
    source_vreg: VirtualReg,
};

pub const Request = struct {
    source: ir.Value,
    expected: Expected,
    form: UseForm,
    destination: Destination,
    prepared_action: ?PreparedAction = null,
};

pub const RequestPhase = enum {
    registering,
    sealed,
    prepared,
    materializing,
    materialized,
    views_exposed,
    committed,
};

pub const Lifecycle = enum { active, committed, rolled_back };

pub const Identity = struct {
    bytes: [max_identity_bytes]u8 = undefined,
    len: u16 = 0,

    pub fn init(name: []const u8) !Identity {
        if (name.len == 0) return error.ValueUseEmptyIdentity;
        if (name.len > max_identity_bytes) return error.ValueUseIdentityTooLong;
        var identity: Identity = .{};
        @memcpy(identity.bytes[0..name.len], name);
        identity.len = @intCast(name.len);
        return identity;
    }

    pub fn slice(identity: *const Identity) []const u8 {
        return identity.bytes[0..identity.len];
    }

    pub fn eql(identity: *const Identity, other: *const Identity) bool {
        return std.mem.eql(u8, identity.slice(), other.slice());
    }
};

pub const max_forward_dependency_owners = 4;

pub const ForwardAssignmentSnapshot = union(enum) {
    gpr32: ArgReg,
    gpr64: ArgReg,
    spill: usize,

    pub fn eql(
        assignment: ForwardAssignmentSnapshot,
        other: ForwardAssignmentSnapshot,
    ) bool {
        if (std.meta.activeTag(assignment) != std.meta.activeTag(other))
            return false;
        return switch (assignment) {
            .gpr32 => |reg| reg == other.gpr32,
            .gpr64 => |reg| reg == other.gpr64,
            .spill => |index| index == other.spill,
        };
    }
};

pub const ForwardDependencyBindingSnapshot = struct {
    vreg: VirtualReg,
    address_index: ?Identity = null,
    address_addend: ?Identity = null,
    is_stack_i32_ptr: bool = false,

    pub fn eql(
        binding: *const ForwardDependencyBindingSnapshot,
        other: *const ForwardDependencyBindingSnapshot,
    ) bool {
        return std.meta.eql(binding.vreg, other.vreg) and
            binding.is_stack_i32_ptr == other.is_stack_i32_ptr and
            optionalIdentityEql(binding.address_index, other.address_index) and
            optionalIdentityEql(binding.address_addend, other.address_addend);
    }
};

pub const ForwardDependencyEdgeSnapshot = struct {
    identity: Identity,
    identity_type: AddressDependencyDomain.IdentityType,
    role: AddressDependencyDomain.Role,
    interval_end: ?usize,
    binding: ?ForwardDependencyBindingSnapshot,

    pub fn eql(
        edge: *const ForwardDependencyEdgeSnapshot,
        other: *const ForwardDependencyEdgeSnapshot,
    ) bool {
        return edge.identity.eql(&other.identity) and
            edge.identity_type == other.identity_type and
            edge.role == other.role and
            edge.interval_end == other.interval_end and
            optionalForwardDependencyBindingEql(edge.binding, other.binding);
    }
};

pub const ForwardDependencyOwnerSnapshot = struct {
    identity: Identity,
    identity_type: AddressDependencyDomain.IdentityType,
    interval_end: usize,
    binding: ?ForwardDependencyBindingSnapshot,
    dependencies: [AddressDependencyDomain.max_dependencies_per_owner]ForwardDependencyEdgeSnapshot = undefined,
    dependency_count: u8 = 0,

    pub fn eql(
        owner: *const ForwardDependencyOwnerSnapshot,
        other: *const ForwardDependencyOwnerSnapshot,
    ) bool {
        if (!owner.identity.eql(&other.identity) or
            owner.identity_type != other.identity_type or
            owner.interval_end != other.interval_end or
            !optionalForwardDependencyBindingEql(owner.binding, other.binding) or
            owner.dependency_count != other.dependency_count)
        {
            return false;
        }
        for (
            owner.dependencies[0..owner.dependency_count],
            other.dependencies[0..other.dependency_count],
        ) |*edge, *other_edge| {
            if (!edge.eql(other_edge)) return false;
        }
        return true;
    }
};

pub const ForwardDependencySnapshot = struct {
    owners: [max_forward_dependency_owners]ForwardDependencyOwnerSnapshot = undefined,
    owner_count: u8 = 0,

    pub fn eql(
        dependencies: *const ForwardDependencySnapshot,
        other: *const ForwardDependencySnapshot,
    ) bool {
        if (dependencies.owner_count != other.owner_count) return false;
        for (
            dependencies.owners[0..dependencies.owner_count],
            other.owners[0..other.owner_count],
        ) |*owner, *other_owner| {
            if (!owner.eql(other_owner)) return false;
        }
        return true;
    }
};

/// Exact transaction-owned structural proof for a plan-backed forward use.
/// It stores no ValueLoc and no slice or pointer into mutable plan entries.
pub const ForwardAdmissionSnapshot = struct {
    plan_identity: usize,
    identity: Identity,
    admission_position: usize,
    definition_position: usize,
    interval_end: usize,
    virtual_class: VirtualRegClass,
    defined_width: u16,
    assignment: ForwardAssignmentSnapshot,
    assignment_frame_bytes: ?usize,
    dependencies: ForwardDependencySnapshot,

    pub fn eql(
        snapshot: *const ForwardAdmissionSnapshot,
        other: *const ForwardAdmissionSnapshot,
    ) bool {
        return snapshot.plan_identity == other.plan_identity and
            snapshot.identity.eql(&other.identity) and
            snapshot.admission_position == other.admission_position and
            snapshot.definition_position == other.definition_position and
            snapshot.interval_end == other.interval_end and
            snapshot.virtual_class == other.virtual_class and
            snapshot.defined_width == other.defined_width and
            snapshot.assignment.eql(other.assignment) and
            snapshot.assignment_frame_bytes == other.assignment_frame_bytes and
            snapshot.dependencies.eql(&other.dependencies);
    }

    pub fn virtualReg(snapshot: ForwardAdmissionSnapshot) VirtualReg {
        return .{
            .index = std.math.maxInt(usize),
            .class = snapshot.virtual_class,
            .bits = snapshot.defined_width,
        };
    }
};

fn optionalIdentityEql(lhs: ?Identity, rhs: ?Identity) bool {
    if ((lhs == null) != (rhs == null)) return false;
    return if (lhs) |identity| identity.eql(&rhs.?) else true;
}

fn optionalForwardDependencyBindingEql(
    lhs: ?ForwardDependencyBindingSnapshot,
    rhs: ?ForwardDependencyBindingSnapshot,
) bool {
    if ((lhs == null) != (rhs == null)) return false;
    return if (lhs) |binding| binding.eql(&rhs.?) else true;
}

pub const Source = union(enum) {
    named: Identity,
    int: i128,
    null_value,
    unsupported,

    pub fn from(input: ir.Value) !Source {
        return switch (input) {
            .named => |name| .{ .named = try Identity.init(name) },
            .int => |integer| .{ .int = integer },
            .null_value => .null_value,
            .fp, .undef, .poison, .zero_initializer, .vector, .constant_expr => .unsupported,
        };
    }

    pub fn eql(source: *const Source, other: *const Source) bool {
        if (std.meta.activeTag(source.*) != std.meta.activeTag(other.*)) return false;
        return switch (source.*) {
            .named => |*name| name.eql(&other.named),
            .int => |integer| integer == other.int,
            .null_value, .unsupported => true,
        };
    }

    fn value(source: *const Source) ir.Value {
        return switch (source.*) {
            .named => |*name| .{ .named = name.slice() },
            .int => |integer| .{ .int = integer },
            .null_value => .null_value,
            .unsupported => .undef,
        };
    }
};

pub const StoredRequest = struct {
    source: Source,
    expected: Expected,
    form: UseForm,
    destination: Destination,
    prepared_action: ?PreparedAction,

    pub fn eql(request: *const StoredRequest, other: *const StoredRequest) bool {
        return request.source.eql(&other.source) and
            request.expected.eql(other.expected) and
            request.form == other.form and
            request.destination.eql(other.destination) and
            optionalPreparedActionEql(request.prepared_action, other.prepared_action);
    }
};

/// Transaction-private lifetime pin. It retains only semantic identity and
/// virtual-register generation; current physical locations are always
/// re-resolved from canonical selector state.
const CallFinalUsePin = struct {
    plan_identity: usize,
    admission_position: usize,
    interval_end: usize,
};

const LifetimePin = struct {
    identity: Identity,
    generation: usize,
    call_final_use: ?CallFinalUsePin = null,
};

const LifetimeContext = struct {
    pins: [max_requests]?LifetimePin = @splat(null),
    forward_snapshots: [max_requests]?ForwardAdmissionSnapshot =
        @splat(null),
};

pub const PhysicalNode = enum(u8) {
    rdi,
    rsi,
    rdx,
    rcx,
    r8,
    r9,
    accumulator,

    pub fn fromArgReg(reg: ArgReg) PhysicalNode {
        return switch (reg) {
            .rdi => .rdi,
            .rsi => .rsi,
            .rdx => .rdx,
            .rcx => .rcx,
            .r8 => .r8,
            .r9 => .r9,
        };
    }

    pub fn argReg(node: PhysicalNode) ?ArgReg {
        return switch (node) {
            .rdi => .rdi,
            .rsi => .rsi,
            .rdx => .rdx,
            .rcx => .rcx,
            .r8 => .r8,
            .r9 => .r9,
            .accumulator => null,
        };
    }

    pub fn scalarSource(loc: ValueLoc) ?PhysicalNode {
        return switch (loc) {
            .arg32, .arg64, .scratch32, .scratch64 => |reg| fromArgReg(reg),
            .arg128, .scratch128 => |pair| fromArgReg(pair.lo),
            .eax, .rax => .accumulator,
            .readonly_table_ptr => |ptr| switch (ptr.storage) {
                .reg => |reg| fromArgReg(reg),
                .spill => null,
            },
            else => null,
        };
    }

    pub fn pairSources(loc: ValueLoc) [2]?PhysicalNode {
        return switch (loc) {
            .arg128, .scratch128 => |pair| .{ fromArgReg(pair.lo), fromArgReg(pair.hi) },
            .spill128 => .{ null, null },
            else => .{ null, null },
        };
    }
};
pub const physical_node_count = @typeInfo(PhysicalNode).@"enum".field_names.len;
pub const max_mappings = max_requests * 3;

const Model = @This();

pub fn Transaction(comptime Impl: type) type {
    return struct {
        const Self = @This();
        pub const max_requests = Model.max_requests;
        pub const max_identity_bytes = Model.max_identity_bytes;
        pub const address_domain_snapshot_copies = Model.address_domain_snapshot_copies;
        pub const address_domain_copies_per_request = Model.address_domain_copies_per_request;
        pub const address_domain_snapshot_bytes = Model.address_domain_snapshot_bytes;
        pub const Expected = Model.Expected;
        pub const UseForm = Model.UseForm;
        pub const Destination = Model.Destination;
        pub const RequestHandle = Model.RequestHandle;
        pub const AccumulatorSessionHandle = Model.AccumulatorSessionHandle;
        pub const PreparedViewLease = Model.PreparedViewLease;
        pub const ActionIdentity = Model.ActionIdentity;
        pub const AddressOffset = Model.AddressOffset;
        pub const PreparedShape = Model.PreparedShape;
        pub const ByteAddressAction = Model.ByteAddressAction;
        pub const ScaledAddressAction = Model.ScaledAddressAction;
        pub const ReadOnlyTableAddressAction = Model.ReadOnlyTableAddressAction;
        pub const StoreScalarAction = Model.StoreScalarAction;
        pub const StoreImmediateAction = Model.StoreImmediateAction;
        pub const StoreI64Action = Model.StoreI64Action;
        pub const StoreStackPointerAction = Model.StoreStackPointerAction;
        pub const MemcpyAction = Model.MemcpyAction;
        pub const MemcpyTestFailure = Model.MemcpyTestFailure;
        pub const DirectCallAction = Model.DirectCallAction;
        pub const IntByteSizeCallAction = Model.IntByteSizeCallAction;
        pub const CallRequestError = Model.CallRequestError;
        pub const ScalarLoadKind = Model.ScalarLoadKind;
        pub const ScalarLoadAction = Model.ScalarLoadAction;
        pub const ReadOnlyPairLoadAction = Model.ReadOnlyPairLoadAction;
        pub const StackI128AliasLoadAction = Model.StackI128AliasLoadAction;
        pub const ReadOnlyTableI16LoadAction = Model.ReadOnlyTableI16LoadAction;
        pub const LoadRequestError = Model.LoadRequestError;
        pub const LoadTestFailure = Model.LoadTestFailure;
        pub const ScratchCompareRhs = Model.ScratchCompareRhs;
        pub const ScratchCompareAction = Model.ScratchCompareAction;
        pub const ScratchCompareTestFailure = Model.ScratchCompareTestFailure;
        pub const CurrentHomeEqZeroAction = Model.CurrentHomeEqZeroAction;
        pub const CurrentHomeEqZeroRequestError = Model.CurrentHomeEqZeroRequestError;
        pub const CurrentHomeEqZeroTestFailure = Model.CurrentHomeEqZeroTestFailure;
        pub const SetccEaxCompareStructure = Model.SetccEaxCompareStructure;
        pub const SetccEaxCompareAction = Model.SetccEaxCompareAction;
        pub const SetccEaxCompareRequestError = Model.SetccEaxCompareRequestError;
        pub const SetccEaxCompareTestFailure = Model.SetccEaxCompareTestFailure;
        pub const CurrentHomeSignBitAction = Model.CurrentHomeSignBitAction;
        pub const CurrentHomeSignBitRequestError = Model.CurrentHomeSignBitRequestError;
        pub const CurrentHomeSignBitTestFailure = Model.CurrentHomeSignBitTestFailure;
        pub const I128EqMinAction = Model.I128EqMinAction;
        pub const I128SignBitAction = Model.I128SignBitAction;
        pub const I128PairRequestError = Model.I128PairRequestError;
        pub const I128EqMinTestFailure = Model.I128EqMinTestFailure;
        pub const I128SignBitTestFailure = Model.I128SignBitTestFailure;
        pub const PairLowScalarCastAction = Model.PairLowScalarCastAction;
        pub const AccumulatorScalarCastAction = Model.AccumulatorScalarCastAction;
        pub const SignExtendScratchAction = Model.SignExtendScratchAction;
        pub const ScalarCastRequestError = Model.ScalarCastRequestError;
        pub const ScalarCastTestFailure = Model.ScalarCastTestFailure;
        pub const ImmediateRhsScalarAction = Model.ImmediateRhsScalarAction;
        pub const ImmediateLhsScalarAction = Model.ImmediateLhsScalarAction;
        pub const ImmediateScalarRequestError = Model.ImmediateScalarRequestError;
        pub const ImmediateScalarTestFailure = Model.ImmediateScalarTestFailure;
        pub const NamedScalarBinaryAction = Model.NamedScalarBinaryAction;
        pub const ExactI52BinaryAction = Model.ExactI52BinaryAction;
        pub const NamedScalarRequestError = Model.NamedScalarRequestError;
        pub const NamedScalarTestFailure = Model.NamedScalarTestFailure;
        pub const ScalarMultiplyAction = Model.ScalarMultiplyAction;
        pub const ScalarMultiplyRequestError = Model.ScalarMultiplyRequestError;
        pub const ScalarMultiplyTestFailure = Model.ScalarMultiplyTestFailure;
        pub const UnsignedQuotientAction = Model.UnsignedQuotientAction;
        pub const UnsignedQuotientRequestError = Model.UnsignedQuotientRequestError;
        pub const UnsignedQuotientTestFailure = Model.UnsignedQuotientTestFailure;
        pub const max_switch_cases = Model.max_switch_cases;
        pub const SwitchCaseIntent = Model.SwitchCaseIntent;
        pub const SwitchCompareChainAction = Model.SwitchCompareChainAction;
        pub const PreparedAction = Model.PreparedAction;
        pub const CopyDestination = Model.CopyDestination;
        const PreparedIdentity = Model.PreparedIdentity;
        const PreparedRegister = Model.PreparedRegister;
        const PreparedScalarHome = Model.PreparedScalarHome;
        const PreparedStackObject = Model.PreparedStackObject;
        const PreparedAddressComponent = Model.PreparedAddressComponent;
        const PreparedAddressDescriptor = Model.PreparedAddressDescriptor;
        const PreparedStackF32PairAddress = Model.PreparedStackF32PairAddress;
        const PreparedTablePointer = Model.PreparedTablePointer;
        const PreparedPairLimb = Model.PreparedPairLimb;
        const PreparedReadOnlyPair = Model.PreparedReadOnlyPair;
        const PreparedCondition = Model.PreparedCondition;
        const PreparedView = Model.PreparedView;
        const PreparedRecord = Model.PreparedRecord;
        const EarlyPlan = Model.EarlyPlan;
        const OperandPhase = Model.OperandPhase;
        const OrderedOperand = Model.OrderedOperand;
        const SemanticRole = Model.SemanticRole;
        const EarlyPreparedHome = Model.EarlyPreparedHome;
        pub const Request = Model.Request;
        pub const RequestPhase = Model.RequestPhase;
        const Lifecycle = Model.Lifecycle;
        const Identity = Model.Identity;
        const Source = Model.Source;
        const StoredRequest = Model.StoredRequest;
        const LifetimeContext = Model.LifetimeContext;
        const ForwardAdmissionSnapshot = Model.ForwardAdmissionSnapshot;
        const PhysicalNode = Model.PhysicalNode;
        const physical_node_count = Model.physical_node_count;
        const max_mappings = Model.max_mappings;

        selector: *ComposedBlockSelector,
        snapshot: Impl.Snapshot,
        requests: [Self.max_requests]Self.StoredRequest = undefined,
        request_count: u8 = 0,
        request_phase: Self.RequestPhase = .registering,
        lifecycle: Self.Lifecycle = .active,
        write_nodes: [Self.physical_node_count]bool = @splat(false),
        // Parallel source snapshots precede every destination write, including
        // action-owned writes. Scratch homes must avoid the entire transfer.
        parallel_sources: [Self.physical_node_count]bool = @splat(false),
        transfer_nodes: [Self.physical_node_count]bool = @splat(false),
        // Chosen by sealing; action intent never carries discovered homes.
        store_address_registers: [Self.max_requests]?ArgReg = @splat(null),
        early_plans: [Self.max_requests]Self.EarlyPlan = @splat(.{}),
        semantic_order_edges: [Self.max_requests][Self.max_requests]bool =
            @splat(@splat(false)),
        ordered_operands: [Self.max_requests]Self.OrderedOperand = undefined,
        ordered_operand_count: u8 = 0,
        early_homes: [Self.max_requests]Self.EarlyPreparedHome = undefined,
        early_home_valid: [Self.max_requests]bool = @splat(false),
        prepared_views: [Self.max_requests]Self.PreparedRecord = undefined,
        prepared_view_valid: [Self.max_requests]bool = @splat(false),
        switch_boundary_applied: [Self.max_requests]bool = @splat(false),
        view_generation: u32 = 1,
        action_diagnostic: ?Diagnostic = null,
        lifetime_context: Self.LifetimeContext = .{},
        /// First request to which a transaction failure can be attributed. This
        /// diagnostic-only identity deliberately survives automatic rollback.
        failed_request: ?Self.RequestHandle = null,
        accumulator_session: ?AccumulatorDefinitionSession = null,
        call_action: ?Self.PreparedAction = null,
        call_action_executed: bool = false,
        call_test_failure: if (builtin.is_test) ?u8 else void = if (builtin.is_test) null else {},
        call_test_argument_index: if (builtin.is_test) u8 else void = if (builtin.is_test) 0 else {},
        memcpy_test_failure: if (builtin.is_test) ?Self.MemcpyTestFailure else void = if (builtin.is_test) null else {},
        load_test_failure: if (builtin.is_test) ?Self.LoadTestFailure else void = if (builtin.is_test) null else {},
        scratch_compare_test_failure: if (builtin.is_test) ?Self.ScratchCompareTestFailure else void = if (builtin.is_test) null else {},
        current_home_eq_zero_test_failure: if (builtin.is_test) ?Self.CurrentHomeEqZeroTestFailure else void = if (builtin.is_test) null else {},
        setcc_eax_compare_test_failure: if (builtin.is_test) ?Self.SetccEaxCompareTestFailure else void = if (builtin.is_test) null else {},
        current_home_sign_bit_test_failure: if (builtin.is_test) ?Self.CurrentHomeSignBitTestFailure else void = if (builtin.is_test) null else {},
        i128_eq_min_test_failure: if (builtin.is_test) ?Self.I128EqMinTestFailure else void = if (builtin.is_test) null else {},
        i128_sign_bit_test_failure: if (builtin.is_test) ?Self.I128SignBitTestFailure else void = if (builtin.is_test) null else {},
        scalar_cast_test_failure: if (builtin.is_test) ?Self.ScalarCastTestFailure else void = if (builtin.is_test) null else {},
        immediate_scalar_test_failure: if (builtin.is_test) ?Self.ImmediateScalarTestFailure else void = if (builtin.is_test) null else {},
        named_scalar_test_failure: if (builtin.is_test) ?Self.NamedScalarTestFailure else void = if (builtin.is_test) null else {},
        scalar_multiply_test_failure: if (builtin.is_test) ?Self.ScalarMultiplyTestFailure else void = if (builtin.is_test) null else {},
        unsigned_quotient_test_failure: if (builtin.is_test) ?Self.UnsignedQuotientTestFailure else void = if (builtin.is_test) null else {},

        pub fn begin(selector: *ComposedBlockSelector) !Self {
            return Impl.begin(Self, selector);
        }

        pub fn deinit(transaction: *Self) void {
            return Impl.deinit(Impl, transaction);
        }

        pub fn register(transaction: *Self, request: Self.Request) !Self.RequestHandle {
            return Impl.register(Impl, transaction, request);
        }

        pub fn attachScratchCompareAction(
            transaction: *Self,
            lhs: Self.RequestHandle,
            action: Self.ScratchCompareAction,
        ) !void {
            return Impl.attachScratchCompareAction(Impl, transaction, lhs, action);
        }

        pub fn attachNamedScalarBinaryAction(
            transaction: *Self,
            lhs: Self.RequestHandle,
            action: Self.NamedScalarBinaryAction,
        ) !void {
            return Impl.attachNamedScalarBinaryAction(Impl, transaction, lhs, action);
        }

        pub fn attachExactI52BinaryAction(
            transaction: *Self,
            lhs: Self.RequestHandle,
            action: Self.ExactI52BinaryAction,
        ) !void {
            return Impl.attachExactI52BinaryAction(Impl, transaction, lhs, action);
        }

        pub fn attachScalarMultiplyAction(
            transaction: *Self,
            lhs: Self.RequestHandle,
            action: Self.ScalarMultiplyAction,
        ) !void {
            return Impl.attachScalarMultiplyAction(Impl, transaction, lhs, action);
        }

        pub fn attachUnsignedQuotientAction(
            transaction: *Self,
            lhs: Self.RequestHandle,
            action: Self.UnsignedQuotientAction,
        ) !void {
            return Impl.attachUnsignedQuotientAction(Impl, transaction, lhs, action);
        }

        pub fn attachCallAction(transaction: *Self, action: Self.PreparedAction) !void {
            return Impl.attachCallAction(Impl, transaction, action);
        }

        pub fn seal(transaction: *Self) !void {
            return Impl.planning.seal(Impl, transaction);
        }

        pub fn prepare(transaction: *Self) !void {
            return Impl.materialization.prepare(Impl, transaction);
        }

        pub fn applySwitchBoundary(
            transaction: *Self,
            handle: Self.RequestHandle,
        ) !void {
            return Impl.applySwitchBoundary(Impl, transaction, handle);
        }

        pub fn materializeAll(transaction: *Self) !void {
            return Impl.materialization.materializeAll(Impl, transaction);
        }

        pub fn preparedView(transaction: *Self, handle: Self.RequestHandle) !Self.PreparedViewLease {
            return Impl.preparedView(Impl, transaction, handle);
        }

        pub fn beginAccumulatorSession(
            transaction: *Self,
        ) !Self.AccumulatorSessionHandle {
            return Impl.composition.beginAccumulatorSession(Impl, transaction);
        }

        pub fn prepareAccumulator(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
            effect: AccumulatorPreparationEffect,
            displacement: AccumulatorDisplacementPolicy,
        ) !?Diagnostic {
            return Impl.composition.prepareAccumulator(Impl, transaction, handle, effect, displacement);
        }

        pub fn prepareAccumulatorCallBeforeArguments(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
            effect: AccumulatorPreparationEffect,
        ) !?Diagnostic {
            return Impl.composition.prepareAccumulatorCallBeforeArguments(Impl, transaction, handle, effect);
        }

        pub fn finishAccumulatorCallPreparationAfterArguments(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
        ) !void {
            return Impl.composition.finishAccumulatorCallPreparationAfterArguments(Impl, transaction, handle);
        }

        pub fn materializeAccumulator(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
            source: ir.Value,
            definition: AccumulatorDefinition,
        ) !void {
            return Impl.composition.materializeAccumulator(Impl, transaction, handle, source, definition);
        }

        pub fn spillAccumulatorValue(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
            name: []const u8,
        ) !void {
            return Impl.composition.spillAccumulatorValue(Impl, transaction, handle, name);
        }

        pub fn defineAccumulatorResult(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
            name: []const u8,
            definition: AccumulatorDefinition,
        ) !void {
            return Impl.composition.defineAccumulatorResult(Impl, transaction, handle, name, definition);
        }

        pub fn finalizeAccumulatorResult(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
        ) !void {
            return Impl.composition.finalizeAccumulatorResult(Impl, transaction, handle);
        }

        pub fn commitAccumulatorSession(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
        ) !void {
            return Impl.composition.commitAccumulatorSession(Impl, transaction, handle);
        }

        pub fn executePreparedAction(transaction: *Self, lease: Self.PreparedViewLease) !void {
            return Impl.executePreparedAction(Impl, transaction, lease);
        }

        pub fn commit(transaction: *Self) !void {
            return Impl.commit(Impl, transaction);
        }

        pub fn rollback(transaction: *Self) !void {
            return Impl.rollback(Impl, transaction);
        }

        pub fn requestCount(transaction: *const Self) usize {
            return Impl.requestCount(Impl, transaction);
        }

        pub fn phase(transaction: *const Self) Self.RequestPhase {
            return Impl.phase(Impl, transaction);
        }

        pub fn actionDiagnostic(transaction: *const Self) ?Diagnostic {
            return Impl.actionDiagnostic(Impl, transaction);
        }

        pub fn failedRequestIs(
            transaction: *const Self,
            handle: Self.RequestHandle,
        ) bool {
            return Impl.failedRequestIs(Impl, transaction, handle);
        }

        pub fn setMemcpyTestFailure(
            transaction: *Self,
            failure: ?Self.MemcpyTestFailure,
        ) !void {
            return Impl.setMemcpyTestFailure(Impl, transaction, failure);
        }

        pub fn setLoadTestFailure(
            transaction: *Self,
            failure: ?Self.LoadTestFailure,
        ) !void {
            return Impl.setLoadTestFailure(Impl, transaction, failure);
        }

        pub fn setScratchCompareTestFailure(
            transaction: *Self,
            failure: ?Self.ScratchCompareTestFailure,
        ) !void {
            return Impl.setScratchCompareTestFailure(Impl, transaction, failure);
        }

        pub fn setCurrentHomeEqZeroTestFailure(
            transaction: *Self,
            failure: ?Self.CurrentHomeEqZeroTestFailure,
        ) !void {
            return Impl.setCurrentHomeEqZeroTestFailure(Impl, transaction, failure);
        }

        pub fn setSetccEaxCompareTestFailure(
            transaction: *Self,
            failure: ?Self.SetccEaxCompareTestFailure,
        ) !void {
            return Impl.setSetccEaxCompareTestFailure(Impl, transaction, failure);
        }

        pub fn setCurrentHomeSignBitTestFailure(
            transaction: *Self,
            failure: ?Self.CurrentHomeSignBitTestFailure,
        ) !void {
            return Impl.setCurrentHomeSignBitTestFailure(Impl, transaction, failure);
        }

        pub fn setI128EqMinTestFailure(
            transaction: *Self,
            failure: ?Self.I128EqMinTestFailure,
        ) !void {
            return Impl.setI128EqMinTestFailure(Impl, transaction, failure);
        }

        pub fn setI128SignBitTestFailure(
            transaction: *Self,
            failure: ?Self.I128SignBitTestFailure,
        ) !void {
            return Impl.setI128SignBitTestFailure(Impl, transaction, failure);
        }

        pub fn setScalarCastTestFailure(
            transaction: *Self,
            failure: ?Self.ScalarCastTestFailure,
        ) !void {
            return Impl.setScalarCastTestFailure(Impl, transaction, failure);
        }

        pub fn setImmediateScalarTestFailure(
            transaction: *Self,
            failure: ?Self.ImmediateScalarTestFailure,
        ) !void {
            return Impl.setImmediateScalarTestFailure(Impl, transaction, failure);
        }

        fn requireActive(transaction: *const Self) !void {
            return Impl.requireActive(Impl, transaction);
        }

        fn rollbackInternal(transaction: *Self) void {
            return Impl.rollbackInternal(Impl, transaction);
        }

        fn validateAccumulatorSession(
            transaction: *Self,
            handle: Self.AccumulatorSessionHandle,
        ) !*AccumulatorDefinitionSession {
            return Impl.composition.validateAccumulatorSession(Impl, transaction, handle);
        }

        fn handleFor(transaction: *Self, index: u8) Self.RequestHandle {
            return Impl.handleFor(Impl, transaction, index);
        }

        fn validateHandle(transaction: *Self, handle: Self.RequestHandle) !u8 {
            return Impl.validateHandle(Impl, transaction, handle);
        }

        fn recordRequestFailure(transaction: *Self, index: u8) void {
            return Impl.recordRequestFailure(Impl, transaction, index);
        }

        fn noteRequestBoundaryError(
            transaction: *Self,
            index: u8,
            err: anyerror,
        ) void {
            return Impl.noteRequestBoundaryError(Impl, transaction, index, err);
        }

        fn validateRequestAt(transaction: *Self, index: u8) !?ValueLoc {
            return Impl.planning.validateRequestAt(Impl, transaction, index);
        }

        fn validateActionRegistration(transaction: *Self, action: Self.PreparedAction) !void {
            return Impl.validateActionRegistration(Impl, transaction, action);
        }

        fn validateRegisteredOperandHandle(transaction: *Self, handle: Self.RequestHandle) !u8 {
            return Impl.validateRegisteredOperandHandle(Impl, transaction, handle);
        }

        fn noteRegisteredOperandBoundaryError(
            transaction: *Self,
            handle: Self.RequestHandle,
            err: anyerror,
        ) void {
            return Impl.noteRegisteredOperandBoundaryError(Impl, transaction, handle, err);
        }

        fn registeredOperandCurrent(transaction: *Self, handle: Self.RequestHandle) !ValueLoc {
            return Impl.registeredOperandCurrent(Impl, transaction, handle);
        }

        fn registeredOperandView(
            transaction: *Self,
            handle: Self.RequestHandle,
        ) !*const Self.PreparedView {
            return Impl.registeredOperandView(Impl, transaction, handle);
        }

        fn validateActionDependenciesCanonical(transaction: *Self, action: Self.PreparedAction) !void {
            return Impl.validateActionDependenciesCanonical(Impl, transaction, action);
        }

        fn validateConsumedActionAfter(
            transaction: *Self,
            owner_index: u8,
            action: Self.PreparedAction,
        ) !void {
            return Impl.validateConsumedActionAfter(Impl, transaction, owner_index, action);
        }

        fn validateConsumedOperandAfter(transaction: *Self, index: u8) !void {
            return Impl.validateConsumedOperandAfter(Impl, transaction, index);
        }

        fn validateConsumedOperandAfterUnchecked(transaction: *Self, index: u8) !void {
            return Impl.validateConsumedOperandAfterUnchecked(Impl, transaction, index);
        }

        fn validateOperandCanonical(transaction: *Self, handle: Self.RequestHandle) !void {
            return Impl.validateOperandCanonical(Impl, transaction, handle);
        }

        fn validateRequest(
            transaction: *Self,
            index: u8,
            request: *const Self.StoredRequest,
        ) !?ValueLoc {
            return Impl.planning.validateRequest(Impl, transaction, index, request);
        }

        fn materializeEarlyPlans(transaction: *Self) !void {
            return Impl.materialization.materializeEarlyPlans(Impl, transaction);
        }

        fn materializeEarlyPlan(transaction: *Self, index: u8) !void {
            return Impl.materialization.materializeEarlyPlan(Impl, transaction, index);
        }

        fn validateEarlyHome(transaction: *Self, index: u8) !void {
            return Impl.planning.validateEarlyHome(Impl, transaction, index);
        }

        fn validateEarlyHomeUnchecked(transaction: *Self, index: u8) !void {
            return Impl.planning.validateEarlyHomeUnchecked(Impl, transaction, index);
        }

        fn materializeRequest(
            transaction: *Self,
            index: u8,
            request: *const Self.StoredRequest,
        ) !void {
            return Impl.materialization.materializeRequest(Impl, transaction, index, request);
        }

        fn materializeRequestUnchecked(transaction: *Self, request: *const Self.StoredRequest) !void {
            return Impl.materialization.materializeRequestUnchecked(Impl, transaction, request);
        }

        fn materializeRequestFromLoc(
            transaction: *Self,
            request: *const Self.StoredRequest,
            current: ValueLoc,
            destination: Self.Destination,
        ) !void {
            return Impl.materialization.materializeRequestFromLoc(Impl, transaction, request, current, destination);
        }

        fn resolveNamedCurrent(transaction: *Self, name: []const u8) !ValueLoc {
            return Impl.materialization.resolveNamedCurrent(Impl, transaction, name);
        }

        fn buildPreparedRecord(transaction: *Self, index: u8) !Self.PreparedRecord {
            return Impl.materialization.buildPreparedRecord(Impl, transaction, index);
        }

        fn buildPreparedRecordUnchecked(transaction: *Self, index: u8) !Self.PreparedRecord {
            return Impl.materialization.buildPreparedRecordUnchecked(Impl, transaction, index);
        }

        pub fn isCurrentHomeSignBitIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isCurrentHomeSignBitIcmp(icmp);
        }

        pub fn isI128EqMinIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isI128EqMinIcmp(icmp);
        }

        pub fn isI128SignBitIcmp(icmp: ir.IcmpInst) bool {
            return Impl.control_compare.isI128SignBitIcmp(icmp);
        }

        pub fn isPairLowScalarCast(cast: ir.CastInst) bool {
            return Impl.scalar_arithmetic.isPairLowScalarCast(cast);
        }

        pub fn isAccumulatorScalarCast(cast: ir.CastInst, exact_ei: bool) bool {
            return Impl.scalar_arithmetic.isAccumulatorScalarCast(cast, exact_ei);
        }

        pub fn isSignExtendScratchCast(cast: ir.CastInst) bool {
            return Impl.scalar_arithmetic.isSignExtendScratchCast(cast);
        }

        pub fn isImmediateRhsScalar(binary: ir.BinaryInst) bool {
            return Impl.scalar_arithmetic.isImmediateRhsScalar(binary);
        }

        pub fn isImmediateLhsScalar(binary: ir.BinaryInst) bool {
            return Impl.scalar_arithmetic.isImmediateLhsScalar(binary);
        }

        pub fn isUnsignedQuotient(binary: ir.BinaryInst) bool {
            return Impl.scalar_arithmetic.isUnsignedQuotient(binary);
        }
    };
}
