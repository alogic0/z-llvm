export fn frontier_checked_add(value: i32) i32 {
    return value + 11;
}

export fn frontier_checked_uadd(value: u32) u32 {
    return value + 19;
}

export fn frontier_bounds_guard(value: *const i32, len: usize, index: usize) i32 {
    _ = len;
    _ = index;
    return value.*;
}

export fn frontier_bounds_direct(values: [*]const i32, index: usize) i32 {
    return values[index];
}

export fn frontier_guard_return_else(values: [*]const i32, len: usize, index: usize) i32 {
    if (index >= len) return -1;
    return values[index];
}

export fn frontier_optional_unwrap(flag: bool, value: *const i32) i32 {
    const maybe_value: ?*const i32 = if (flag) value else null;
    return maybe_value.?.*;
}

export fn frontier_int_from_float_checked(value: f32) i32 {
    return @intFromFloat(value);
}
