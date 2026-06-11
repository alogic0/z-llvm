export fn expanded_float_pipeline(a: f32, b: f32, take_a: bool) f32 {
    _ = take_a;
    return a + b;
}

export fn expanded_double_pipeline(a: f64, b: f64) f64 {
    return a / b;
}
