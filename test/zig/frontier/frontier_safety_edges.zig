const frontier_runtime_panic_message = "frontier runtime panic message with variable length";
var frontier_runtime_panic_len: usize = 23;

export fn frontier_checked_add(value: i32) i32 {
    return value + 11;
}

export fn frontier_checked_uadd(value: u32) u32 {
    return value + 19;
}

export fn frontier_explicit_sadd_overflow(value: i32) i32 {
    const checked = @addWithOverflow(value, 11);
    if (checked[1] != 0) @panic("frontier signed add overflow");
    return checked[0];
}

export fn frontier_explicit_uadd_overflow(value: u32) u32 {
    const checked = @addWithOverflow(value, 19);
    if (checked[1] != 0) @panic("frontier unsigned add overflow");
    return checked[0];
}

export fn frontier_bounds_guard(value: *const i32, len: usize, index: usize) i32 {
    _ = len;
    _ = index;
    return value.*;
}

export fn frontier_bounds_direct(values: [*]const i32, index: usize) i32 {
    return values[index];
}

export fn frontier_bounds_panic(values: [*]const i32, len: usize, index: usize) i32 {
    if (index >= len) @panic("frontier bounds panic");
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

export fn frontier_panic_param_len(ok: bool, len: usize) i32 {
    if (ok) return 91;
    @panic(frontier_runtime_panic_message[0..len]);
}

export fn frontier_panic_computed_len(ok: bool, base_len: usize) i32 {
    if (ok) return 92;
    const len = base_len + 7;
    @panic(frontier_runtime_panic_message[0..len]);
}

export fn frontier_panic_loaded_len(ok: bool) i32 {
    if (ok) return 93;
    @panic(frontier_runtime_panic_message[0..frontier_runtime_panic_len]);
}
