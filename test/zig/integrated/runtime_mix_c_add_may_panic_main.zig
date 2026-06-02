var zig_k: i32 = 1;

export fn main() c_int {
    return add_may_panic(4);
}

fn add_may_panic(value: i32) i32 {
    if (value < 0) @panic("negative int");
    return zig_k + value;
}
