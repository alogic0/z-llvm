var atomic_counter: u32 = 0;

export fn atomic_add(value: u32) u32 {
    return @atomicRmw(u32, &atomic_counter, .Add, value, .monotonic);
}

export fn inline_asm_barrier(value: i32) i32 {
    asm volatile ("" ::: .{ .memory = true });
    return value;
}

export fn debug_location(value: i32) i32 {
    const local = value + 1;
    return local;
}
