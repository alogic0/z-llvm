export fn frontier_comptime_mix(value: i32) i32 {
    return value + 21;
}

export fn frontier_static_choice(flag: i32) i32 {
    _ = flag;
    return 8;
}
