export fn frontier_mixed_float(left: f32, right: f32) f32 {
    return left + right;
}

export fn frontier_double_roundtrip(value: f64, divisor: f64) f64 {
    return value / divisor;
}

export fn frontier_i32_to_f32_add(value: i32, addend: f32) f32 {
    return @as(f32, @floatFromInt(value)) + addend;
}

export fn frontier_i32_to_f32_mul_add(value: i32, scale: f32, addend: f32) f32 {
    return @as(f32, @floatFromInt(value)) * scale + addend;
}

export fn frontier_i32_to_f64_mul_add(value: i32, scale: f64, addend: f64) f64 {
    return @as(f64, @floatFromInt(value)) * scale + addend;
}

export fn frontier_byte_swap_u16(value: u16) u16 {
    return @byteSwap(value);
}

export fn frontier_byte_swap_u32(value: u32) u32 {
    return @byteSwap(value);
}

export fn frontier_byte_swap_u64(value: u64) u64 {
    return @byteSwap(value);
}

export fn frontier_max_i32(left: i32, right: i32) i32 {
    return @max(left, right);
}
