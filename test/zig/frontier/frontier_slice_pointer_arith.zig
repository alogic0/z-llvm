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

export fn frontier_slice_len_from_ptr(values: [*]const i32, len: usize) usize {
    const slice = values[0..len];
    return slice.len;
}
