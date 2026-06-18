export fn frontier_flat_window_sum(a: i32, b: i32) i32 {
    return a + b;
}

export fn frontier_window_threshold(flag: i32, value: i32) i32 {
    return if (flag != 0) value else 0;
}
