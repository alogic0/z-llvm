export fn float_add(a: f32, b: f32) f32 {
    return a + b;
}

export fn float_select(a: f64, b: f64, flag: bool) f64 {
    return if (flag) a else b;
}
