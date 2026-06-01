export fn main() c_int {
    return 0;
}

fn inlineAsmBarrier(value: i32) i32 {
    asm volatile ("" ::: .{ .memory = true });
    return value;
}
