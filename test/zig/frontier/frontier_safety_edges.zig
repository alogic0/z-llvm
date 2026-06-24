export fn frontier_checked_add(value: i32) i32 {
    return value + 11;
}

export fn frontier_bounds_guard(value: *const i32, len: usize, index: usize) i32 {
    _ = len;
    _ = index;
    return value.*;
}

export fn frontier_guard_return_else(values: [*]const i32, len: usize, index: usize) i32 {
    if (index >= len) return -1;
    return values[index];
}
