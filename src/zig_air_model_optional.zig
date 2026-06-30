pub const OptionalShapeSummary = struct {
    kind: enum { pointer_payload, scalar_payload },
    optional_value: ?u32 = null,
    condition: u32,
    payload: u32,
    wrap: ?u32 = null,
    load: ?u32 = null,
    return_value: ?u32 = null,
};

pub const TypedOptionalPayloadBranchSummary = struct {
    threshold: i32,
    fallback: i32,
};

pub const TypedOptionalPayloadSummary = struct {
    fallback: i32,
};

pub const TypedOptionalPointerSummary = struct {
    add_imm: i32,
    fallback: i32,
    checked_unwrap: bool,
};
