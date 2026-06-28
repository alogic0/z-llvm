export fn frontier_slice_stride_sum(value: *const i32) i32 {
    return value.*;
}

export fn frontier_pointer_offset_load(value: *const i32) i32 {
    return value.*;
}

export fn frontier_dynamic_ptr_add(values: [*]const i32, index: usize) i32 {
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_dynamic_ptr_pair_sum(values: [*]const i32, index: usize) i32 {
    const ptr = values + index;
    return ptr[0] + ptr[1];
}

export fn frontier_comptime_ptr_add(values: [*]const i32) i32 {
    const ptr = values + 2;
    return ptr[0];
}

export fn frontier_chained_ptr_add(values: [*]const i32, index: usize) i32 {
    const ptr = values + index;
    const next = ptr + 2;
    return next[0];
}

export fn frontier_ptr_add_store(values: [*]i32, index: usize, value: i32) i32 {
    const ptr = values + index;
    ptr[0] = value;
    return ptr[0];
}

export fn frontier_ptr_add_load_u8(values: [*]const u8, index: usize) u8 {
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_ptr_add_load_u16(values: [*]const u16, index: usize) u16 {
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_ptr_add_load_u64(values: [*]const u64, index: usize) u64 {
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_ptr_add_load_index_rcx(values: [*]const u32, skip_a: usize, skip_b: usize, index: usize) u32 {
    _ = skip_a;
    _ = skip_b;
    const ptr = values + index;
    return ptr[0];
}

export fn frontier_ptr_add_store_u8(values: [*]u8, index: usize, value: u8) u8 {
    const ptr = values + index;
    ptr[0] = value;
    return ptr[0];
}

export fn frontier_ptr_add_store_u16(values: [*]u16, index: usize, value: u16) u16 {
    const ptr = values + index;
    ptr[0] = value;
    return ptr[0];
}

export fn frontier_ptr_add_store_u64(values: [*]u64, index: usize, value: u64) u64 {
    const ptr = values + index;
    ptr[0] = value;
    return ptr[0];
}

export fn frontier_slice_len_from_ptr(values: [*]const i32, len: usize) usize {
    const slice = values[0..len];
    return slice.len;
}

export fn frontier_slice_ptr_load(values: [*]const i32, len: usize, index: usize) i32 {
    const slice = values[0..len];
    const ptr = slice.ptr + index;
    return ptr[0];
}

export fn frontier_slice_elem_ptr_load(values: [*]const i32, len: usize, index: usize) i32 {
    @setRuntimeSafety(false);
    const slice = values[0..len];
    return slice[index];
}

export fn frontier_slice_elem_ptr_store(values: [*]i32, len: usize, index: usize, value: i32) i32 {
    @setRuntimeSafety(false);
    const slice = values[0..len];
    slice[index] = value;
    return slice[index];
}
