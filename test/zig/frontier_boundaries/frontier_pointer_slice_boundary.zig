export fn frontier_checked_slice_store_boundary(values: [*]i32, len: usize, index: usize, value: i32) i32 {
    @setRuntimeSafety(true);
    const slice = values[0..len];
    slice[index] = value;
    return slice[index];
}
