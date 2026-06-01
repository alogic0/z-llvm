var atomic_counter: u32 = 0;

export fn main() c_int {
    return 0;
}

fn atomicAdd(value: u32) u32 {
    return @atomicRmw(u32, &atomic_counter, .Add, value, .monotonic);
}
