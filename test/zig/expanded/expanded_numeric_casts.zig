export fn expanded_float_from_int(value: i32) f32 {
    return @floatFromInt(value);
}

export fn expanded_double_from_unsigned(value: u32) f64 {
    return @floatFromInt(value);
}

export fn expanded_int_from_float(value: f32) i32 {
    return @intFromFloat(value);
}

export fn expanded_float_narrow(value: f64) f32 {
    return @floatCast(value);
}

export fn expanded_double_widen(value: f32) f64 {
    return value;
}
