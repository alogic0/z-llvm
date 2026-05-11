export fn add_wrap(a: i32, b: i32) i32 {
    return a +% b;
}

export fn shift_mix(a: u32, b: u32) u32 {
    const sh: u5 = @truncate(b);
    return (a << sh) ^ (a >> sh);
}

export fn cmp_select(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
