var global_counter: i32 = 3;

const scale = blk: {
    break :blk 5;
};

export fn read_global() i32 {
    return global_counter;
}

export fn update_global(value: i32) i32 {
    global_counter += value;
    return global_counter;
}

export fn comptime_const(value: i32) i32 {
    return value * scale;
}
