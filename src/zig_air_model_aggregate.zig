pub const TableLookupSummary = struct {
    index_source: u32,
    mask_or_narrow: u32,
    index_cast: u32,
    table_access: u32,
    return_value: u32,
};

pub const AggregatePairSummary = struct {
    kind: enum { first, make },
    base_ptr: u32,
    field0_ptr: u32,
    field1_ptr: ?u32 = null,
    field0_value: ?u32 = null,
    field1_value: ?u32 = null,
    return_value: u32,
};

pub const ArraySumSummary = struct {
    aggregate_init: u32,
    elem_ptr_count: usize,
    load_count: usize,
    add_count: usize,
};

pub const StructSumSummary = struct {
    field0_ptr: u32,
    field1_ptr: u32,
    load_count: usize,
    add_count: usize,
};

pub const PackedFieldSummary = struct {
    kind: enum { read_flag, replace_low },
    field_ptr: u32,
    load: ?u32 = null,
    bitcast: ?u32 = null,
    trunc: ?u32 = null,
    store: ?u32 = null,
};

pub const TypedPackedFieldSummary = struct {
    kind: enum { read_flag, replace_low },
};
