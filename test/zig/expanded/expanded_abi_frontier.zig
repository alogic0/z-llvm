export fn expanded_stack_param_sum(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32) i32 {
    return a + b + c + d + e + f + g;
}

noinline fn stackCallee(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32, g: i32) i32 {
    return a + b + c + d + e + f + g;
}

export fn expanded_stack_arg_call() i32 {
    return stackCallee(1, 2, 3, 4, 5, 6, 7);
}

noinline fn floatCallee(a: f32, b: f32) f32 {
    return a + b;
}

noinline fn doubleCallee(a: f64, b: f64) f64 {
    return a / b;
}

noinline fn mixedCallee(tag: i32, value: f64) f64 {
    _ = tag;
    return value;
}

export fn expanded_float_call() f32 {
    return floatCallee(1.5, 2);
}

export fn expanded_double_call() f64 {
    return doubleCallee(6, 2);
}

export fn expanded_mixed_int_float_call() f64 {
    return mixedCallee(7, 6);
}
