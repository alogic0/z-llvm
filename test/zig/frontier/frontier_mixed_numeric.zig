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

export fn frontier_max_u32(left: u32, right: u32) u32 {
    return @max(left, right);
}

export fn frontier_min_i32(left: i32, right: i32) i32 {
    return @min(left, right);
}

export fn frontier_min_u32(left: u32, right: u32) u32 {
    return @min(left, right);
}

export fn frontier_abs_i32(value: i32) u32 {
    return @abs(value);
}

export fn frontier_abs_i64(value: i64) u64 {
    return @abs(value);
}

export fn frontier_clz_u32(value: u32) u32 {
    return @clz(value);
}

export fn frontier_ctz_u32(value: u32) u32 {
    return @ctz(value);
}

export fn frontier_popcount_u32(value: u32) u32 {
    return @popCount(value);
}

export fn frontier_bit_reverse_u32(value: u32) u32 {
    return @bitReverse(value);
}

export fn frontier_shr_exact_u32(value: u32) u32 {
    return @shrExact(value & 0xffff_fffe, 1);
}

export fn frontier_neg_f32(value: f32) f32 {
    return -value;
}

export fn frontier_neg_f64(value: f64) f64 {
    return -value;
}
