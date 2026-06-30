pub const ErrorSwitchSummary = struct {
    kind: enum { payload, maybe_error, switch_dispatch, classify },
    condition: ?u32 = null,
    error_union_value: ?u32 = null,
    extracted_value: ?u32 = null,
    switch_br: ?u32 = null,
    return_value: ?u32 = null,
};

pub const TypedErrorSwitchSummary = struct {
    kind: enum { switch_dispatch, classify },
};

pub const TypedErrorUnionSummary = struct {
    kind: enum { payload, maybe_error },
};

pub const TypedErrorUnionPayloadKind = enum {
    local,
    call_produced,
    unsupported,
};

pub const TypedErrorUnionFlowDiagnostic = enum {
    missing_operand,
    missing_call_result_type,
    missing_branch_target,
    missing_payload_owner,
    missing_error_owner,
    cross_function_fact_required,
    unsupported_payload_owner,
    unsupported_shape,
};

pub const TypedErrorUnionFlow = struct {
    source_instruction: u32,
    success_payload_owner: u32,
    error_owner: u32,
    call_result_owner: ?u32,
    post_success_branch_target: ?u32,
    post_catch_branch_target: ?u32,
    catch_value_i32: ?i32,
    payload_kind: TypedErrorUnionPayloadKind,
};

pub const TypedErrorUnionFlowResult = union(enum) {
    flow: TypedErrorUnionFlow,
    diagnostic: TypedErrorUnionFlowDiagnostic,
};

pub const TypedLoopTrySummary = struct {
    callee_name: []const u8,
    callee_external: bool,
    call_signature: []const u8,
    error_return: i32,
    post_branch: ?TypedLoopTryPostBranchSummary = null,
    post_switch: ?TypedLoopTryPostSwitchSummary = null,
};

pub const TypedLoopTryPostBranchSummary = struct {
    threshold_param_index: usize,
    true_addend: i32,
    false_addend: i32,
};

pub const TypedLoopTryPostSwitchSummary = struct {
    mask: i32,
    case0_addend: i32,
    case1_addend: i32,
    default_addend: i32,
};
