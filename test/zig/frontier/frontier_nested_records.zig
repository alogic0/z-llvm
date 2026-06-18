export fn frontier_record_sum(a: i32, b: i32) i32 {
    return a + b;
}

export fn frontier_record_update(flag: i32, value: i32) i32 {
    return if (flag != 0) value + 1 else value + 2;
}
