//! Frozen INBOX-60 differential-execution cohort.
//!
//! Every exported function is a deterministic leaf.  The only permitted
//! write is the one u32 store documented on abi_pointer_load_store.

export fn abi_neg_u64(value: u64) callconv(.c) u64 {
    return 0 -% value;
}

export fn abi_select_i32(a: i32, b: i32, take_b: u8) callconv(.c) i32 {
    return if (take_b == 0) a else b;
}

export fn abi_identity_u8(value: u8) callconv(.c) u8 {
    return value;
}

export fn abi_identity_i16(value: i16) callconv(.c) i16 {
    return value;
}

/// Reads exactly src.* and writes exactly dst.*.
export fn abi_pointer_load_store(src: *const u32, dst: *u32) callconv(.c) u32 {
    const value = src.* +% 7;
    dst.* = value;
    return value;
}

/// Reads exactly base.* and performs no writes.
export fn abi_load_u32(base: *const u32) callconv(.c) u32 {
    return base.*;
}

/// Performs no memory access; the returned address is normalized by the harness.
export fn abi_identity_ptr(base: *const u8) callconv(.c) *const u8 {
    return base;
}

export fn abi_neg_u128(value: u128) callconv(.c) u128 {
    return 0 -% value;
}

export fn abi_mul_f64(a: f64, b: f64) callconv(.c) f64 {
    return a * b;
}

export fn abi_add_f32(a: f32, b: f32) callconv(.c) f32 {
    return a + b;
}
