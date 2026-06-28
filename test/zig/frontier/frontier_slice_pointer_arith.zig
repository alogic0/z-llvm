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
