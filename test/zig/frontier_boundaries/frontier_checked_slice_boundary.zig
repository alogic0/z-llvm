export fn frontier_checked_slice_elem_ptr_load(values: [*]const i32, len: usize, index: usize) i32 {
    @setRuntimeSafety(true);
    const slice = values[0..len];
    return slice[index];
}
