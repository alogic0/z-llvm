pub const SliceSumSummary = struct {
    slice: u32,
    slice_elem_ptr: u32,
    ptr_slice_len_ptr: u32,
    loop: u32,
};

pub const PointerSliceAddressSummary = struct {
    ptr_add_count: usize = 0,
    ptr_sub_count: usize = 0,
    slice_count: usize = 0,
    slice_ptr_count: usize = 0,
    slice_len_count: usize = 0,
    slice_elem_ptr_count: usize = 0,
    ptr_slice_len_ptr_count: usize = 0,
    ptr_slice_ptr_ptr_count: usize = 0,
    load_count: usize = 0,
    store_count: usize = 0,
    bounds_check_count: usize = 0,
    base_pointer_operand: ?[]const u8 = null,
    dynamic_index_operand: ?[]const u8 = null,
    constant_index: ?i128 = null,
    scalar_width_bits: ?u16 = null,
    slice_source_index: ?u32 = null,

    pub fn hasPointerOrSliceAddress(self: PointerSliceAddressSummary) bool {
        return self.ptr_add_count != 0 or
            self.ptr_sub_count != 0 or
            self.slice_count != 0 or
            self.slice_ptr_count != 0 or
            self.slice_len_count != 0 or
            self.slice_elem_ptr_count != 0 or
            self.ptr_slice_len_ptr_count != 0 or
            self.ptr_slice_ptr_ptr_count != 0;
    }
};

pub const TypedSliceLoopSummary = struct {
    kind: enum { plain_sum, conditional_sum },
};
