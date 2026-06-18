export fn frontier_flat_window_sum(a: i32, b: i32) i32 {
    return a + b;
}

export fn frontier_window_threshold(flag: i32, value: i32) i32 {
    return if (flag != 0) value else 0;
}

export fn frontier_nested_memory_sum(values: [*]const i32, len: usize, limit: i32) i32 {
    var index: usize = 0;
    var sum: i32 = 0;
    while (index < len) : (index += 1) {
        const value = values[index];
        if (value > limit) {
            sum += value;
        }
    }
    return sum;
}
