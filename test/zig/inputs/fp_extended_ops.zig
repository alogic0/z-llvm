export fn float_sub(a: f32, b: f32) f32 {
    return a - b;
}

export fn double_div(a: f64, b: f64) f64 {
    return a / b;
}

export fn float_rem(a: f32, b: f32) f32 {
    return @rem(a, b);
}
