noinline fn scaleStackWide(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32, h: i32, i: i32) i32 {
    _ = a;
    _ = b;
    _ = c;
    _ = d;
    _ = e;
    _ = f;
    return g + h + i;
}

noinline fn scaleMixedWide(a: i32, b: f32, c: i64, d: f64, e: i32, f: i32, g: i32, h: i32, i: i32) f64 {
    _ = a;
    _ = b;
    _ = c;
    _ = e;
    _ = f;
    _ = g;
    _ = h;
    _ = i;
    return d;
}

noinline fn scaleI64Echo(tag: i32, value: i64) i64 {
    _ = tag;
    return value;
}

export fn scale_stack_wide_call() i32 {
    return scaleStackWide(1, 2, 3, 4, 5, 6, 7, 8, 9);
}

export fn scale_mixed_wide_call() f64 {
    return scaleMixedWide(1, 2, 3, 4, 5, 6, 7, 8, 9);
}

export fn scale_i64_echo_call() i64 {
    return scaleI64Echo(9, 987654321);
}
